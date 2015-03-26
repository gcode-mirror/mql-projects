//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // будем задействовать побочное окно индикатора

//+------------------------------------------------------------------+
//| Индикатор, показывающий расхождения BlauMtm                      |
//| 1) рисует линии BlauMtm                                          |
//| 2) рисует линиями расхождения на BlauMtm и на графике цены       |
//| 3) рисует стрелочками момент возникновения сигнала               |
//| 4) хранит значения расхождений и экстремумов на цене             |
//+------------------------------------------------------------------+

// константы сигналов
#define BUY   1    
#define SELL -1

// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                          // для проверки формирования нового бара
#include <Divergence/divergenceBlauMtm.mqh>           // подключаем библиотеку для поиска расхождений BlauMtm
#include <ChartObjects/ChartObjectsLines.mqh>         // для рисования линий расхождения
#include <CompareDoubles.mqh>                         // для проверки соотношения  цен
#include <CLog.mqh>

// входные пользовательские параметры индикатора
sinput string              blau_params   = "";        // ПАРАМЕТРЫ ИНДИКАТОРА 
input int                  q=2;                       // q - период, по которому вычисляется моментум
input int                  r=20;                      // r - период 1-й EMA, применительно к моментуму
input int                  s=5;                       // s - период 2-й EMA, применительно к результату первого сглаживания
input int                  u=3;                       // u - период 3-й EMA, применительно к результату второго сглаживания

// параметры индикаторных буферов 
#property indicator_buffers 4                         // задействовано 4 индикаторных буфера
#property indicator_plots   1                         // 1 буфер отображаются на графиках

// параметры буферов

// буфер индикатора Blau
#property indicator_type1 DRAW_LINE                   // линии
#property indicator_color1  clrWhite                  // цвет линий
#property indicator_width1  1                         // толщина линий
#property indicator_style1 STYLE_SOLID                // стиль линий
#property indicator_label1  "BLAU"                    // наименование буфера

// глобальные переменные индикатора
int                handleBlau;                        // хэндл Blau
int                lastBarIndex;                      // индекс последнего бара 
int                retCode;                           // для записи результата вычисления  расхождения  
long               countDiv;                          // счетчик тренд линий (для рисования линий расхождений) 

PointDivBlau       divergencePoints;                  // точки расхождения Blau на ценовом графике и на графике Blau
CChartObjectTrend  trendLine;                         // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                          // объект класса вертикальной линии
CisNewBar          isNewBar;                          // для проверки формирования нового бара
 
// буферы индикатора 
double bufferBlau[];                                  // буфер уровней Blau
double bufferDiv[];                                   // буфер моментов расхождения
double bufferExtrLeft[];                              // буфер времени левых  экстремумов
double bufferExtrRight[];                             // буфер времени правых экстремумов

// точки для хранения времени экстремумов цены   

datetime onePointBuy  = 0;  
datetime twoPointBuy  = 0;
datetime onePointSell = 0;
datetime twoPointSell = 0;

// дополнительные функции работы индикатора
void    DrawIndicator (datetime vertLineTime);     // отображает линии индикатора. В функцию передается время вертикальной линии
   
// инициализация индикатора
int OnInit()
  {  
   ArraySetAsSeries(bufferDiv,true);
   ArraySetAsSeries(bufferExtrLeft,true);
   ArraySetAsSeries(bufferExtrRight,true);   
   // загружаем хэндл индикатора Blau
   handleBlau = iCustom(_Symbol,_Period,"Blau_Mtm",q,r,s,u);
   if ( handleBlau == INVALID_HANDLE)  // если не удалось загрузить хэндл Стохастика
    {
     return(INIT_FAILED);  // то инициализация завершилась не успенно
    }  
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // связываем индикаторы с буферами 
   SetIndexBuffer(0,bufferBlau,INDICATOR_DATA);              // буфер Blau
   SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS);      // буфер расхождений (моментов возникновения сигналов)
   SetIndexBuffer(2,bufferExtrLeft,INDICATOR_CALCULATIONS);  // буфер времени левых экстремумов
   SetIndexBuffer(3,bufferExtrRight,INDICATOR_CALCULATIONS); // буфер времени правых экструмумов
   // инициализация глобальных  переменных
   countDiv = 0;                                             // выставляем начальное количество расхождений
   return(INIT_SUCCEEDED);                                   // успешное завершение инициализации индикатора
  }

// деинициализация индикатора
void OnDeinit(const int reason)
 {
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // очищаем индикаторные буферы
   ArrayFree(bufferBlau);
   ArrayFree(bufferDiv);
   ArrayFree(bufferExtrLeft);
   ArrayFree(bufferExtrRight);
   // освобождаем хэндл Стохастика
   IndicatorRelease(handleBlau);
 }

// базовая функция расчета индикатора
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if (prev_calculated == 0) // если на пред. вызове было обработано 0 баров, значит этот вызов первый
    {
      // загрузим буфер Стохастика
      if ( CopyBuffer(handleBlau,0,0,rates_total,bufferBlau) < 0 )
           {
             // если не удалось загрузить буфера Blau
             Print("Ошибка индикатора smydBLAU. Не удалось загрузить буфер индикатора Blau");
             return (0); 
           }                
      // положим индексацию нужных массивов как в таймсерии
      if ( !ArraySetAsSeries (time,true) || 
           !ArraySetAsSeries (open,true) || 
           !ArraySetAsSeries (high,true) ||
           !ArraySetAsSeries (low,true)  || 
           !ArraySetAsSeries (close,true) )
          {
            // если не удалось установаить индексацию как в таймсерии для всех массивов цен и времени
            Print("Ошибка индикатора smydBLAU. Не удалось установить индексацию массивов как в таймсерии");
            return (0);
          }
       // проходим по всем барам истории и ищем расхождения Стохастика
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          // обнуляем буфер сигналов расхождений Стохастика
          bufferDiv[lastBarIndex] = 0;
          // обнуляем буферы экстремумов
          bufferExtrLeft[lastBarIndex]  = 0;
          bufferExtrRight[lastBarIndex] = 0;
          retCode = divergenceBlau(handleBlau, _Symbol, _Period,/* top_level, bottom_level,*/ divergencePoints, 0,lastBarIndex);
          // если не удалось загрузить буферы Стохастика
          if (retCode == -2)
           {
             Print("Ошибка индикатора smydBlau. Не удалось загрузить буферы Blau");
             return (0);
           }
          // если BUY и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == BUY && datetime(divergencePoints.timeExtrPrice1) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice1) != twoPointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
             bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение  
             bufferExtrLeft[lastBarIndex]  = double(divergencePoints.timeExtrPrice2);  // сохраним время левого  экстремума
             bufferExtrRight[lastBarIndex] = double(divergencePoints.timeExtrPrice1);  // сохраним время правого экстремума    
             // сохраняем время экстремумов цен
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // если SELL и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == SELL && datetime(divergencePoints.timeExtrPrice1) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice2) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice1) != twoPointSell
                            && datetime(divergencePoints.timeExtrPrice2) != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
             bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение 
             bufferExtrLeft[lastBarIndex]  = double(divergencePoints.timeExtrPrice2); // сохраним время левого  экстремума
             bufferExtrRight[lastBarIndex] = double(divergencePoints.timeExtrPrice1); // сохраним время правого экстремума      
      
             // сохраняем время экстремумов цен
             onePointSell =  divergencePoints.timeExtrPrice1;
             twoPointSell =  divergencePoints.timeExtrPrice2;
           }           
        }
    }
    else    // если это не первый вызов индикатора 
     {
       // если сформировался новый бар
       if (isNewBar.isNewBar() > 0 )
        {
              // положим индексацию нужных массивов как в таймсерии
          if ( !ArraySetAsSeries (time,true) || 
               !ArraySetAsSeries (open,true) || 
               !ArraySetAsSeries (high,true) ||
               !ArraySetAsSeries (low,true)  || 
               !ArraySetAsSeries (close,true) )
              {
               // если не удалось установаить индексацию как в таймсерии для всех массивов цен и времени
               Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось установить индексацию массивов как в таймсерии");
               return (rates_total);
              }
          // обнуляем буфер сигнала расхождений
          bufferDiv[0] = 0;
         // обнуляем буферы экстремумов
          bufferExtrLeft[0]  = 0;
          bufferExtrRight[0] = 0;          
          if ( CopyBuffer(handleBlau,0,0,rates_total,bufferBlau)    < 0  )
           {
             // если не удалось загрузить буфера Blau
             Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы STOC");
             return (rates_total);
           }   
          //Print(); 
      //    Print("Время из OnCalculate = ",TimeToString(time[0]) );
           
           retCode = divergenceBlau(handleBlau, _Symbol, _Period,/* top_level, bottom_level, */divergencePoints,time[0], 0);  // получаем сигнал на расхождение
           //log_file.Write(LOG_DEBUG, StringFormat("Время из OnCalculate = %s retCode = %i",TimeToString(time[0]),retCode) );
          // если не удалось загрузить буферы Blau
          if (retCode == -2)
           {
             Print("Ошибка индикатора smyBlau. Не удалось загрузить буферы Blau");
             return (0);
           }

          // если BUY и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == BUY && datetime(divergencePoints.timeExtrPrice1) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice1) != twoPointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[0]);   // отображаем графические элементы индикатора     
             bufferDiv[0] = retCode;                               // сохраняем в буфер значение    
             bufferExtrLeft[0]  = double(divergencePoints.timeExtrPrice2); // сохраним время левого  экстремума
             bufferExtrRight[0] = double(divergencePoints.timeExtrPrice1); // сохраним время правого экстремума  
      
             // сохраняем время экстремумов цен
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // если SELL и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == SELL && datetime(divergencePoints.timeExtrPrice1) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice2) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice1) != twoPointSell
                            && datetime(divergencePoints.timeExtrPrice2) != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[0]);   // отображаем графические элементы индикатора     
             bufferDiv[0] = retCode;    // сохраняем в буфер значение
             bufferExtrLeft[0]  = double(divergencePoints.timeExtrPrice2); // сохраним время левого  экстремума
             bufferExtrRight[0] = double(divergencePoints.timeExtrPrice1); // сохраним время правого экстремума      
       //lastBarIndex
             // сохраняем время экстремумов цен
             onePointSell =  divergencePoints.timeExtrPrice1;
             twoPointSell =  divergencePoints.timeExtrPrice2;
         
           }           
                      
            
        }
     }
   return(rates_total);
  }
  
// функция отображения графических элементов индикатора
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // создаем линию схождения\расхождения                    
   trendLine.Create(0,"STOCPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // создаем линию схождения\расхождения на Стохастике
   trendLine.Create(0,"STOCLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrBlau1,divergencePoints.valueExtrBlau1,divergencePoints.timeExtrBlau2,divergencePoints.valueExtrBlau2);            
   vertLine.Color(clrRed);
   // создаем вертикальную линию, показывающий момент появления расхождения Стохастика
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // увеличиваем количество отображаемых схождений
 }