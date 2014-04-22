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
//| Индикатор, показывающий расхождения Стохастика                   |
//| 1) рисует линии Стохастика                                       |
//| 2) рисует линиями расхождения на Стохастике и на графике цены    |
//| 3) рисует стрелочками момент возникновения сигнала               |
//+------------------------------------------------------------------+

// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                          // для проверки формирования нового бара
#include <Divergence/divergenceStochastic.mqh>        // подключаем библиотеку для поиска расхождений MACD
#include <ChartObjects/ChartObjectsLines.mqh>         // для рисования линий расхождения
#include <CompareDoubles.mqh>                         // для проверки соотношения  цен

// входные пользовательские параметры индикатора
sinput string macd_params              = "";          // ПАРАМЕТРЫ ИНДИКАТОРА MACD
input ENUM_MA_METHOD      ma_method    = MODE_SMA;    // тип сглаживания
input ENUM_STO_PRICE      price_field  = STO_LOWHIGH; // способ расчета стохастика           
input int                 top_level    = 80;          // верхний уровень 
input int                 bottom_level = 20;          // нижний уровень 

// параметры индикаторных буферов 
#property indicator_buffers 3                         // задействовано 3 индикаторных буфера
#property indicator_plots   2                         // 2 буфера отображаются на графиках

// параметры буферов

// top level буфер
#property indicator_type1 DRAW_LINE                 // линии
#property indicator_color1  clrWhite                // цвет линий
#property indicator_width1  1                       // толщина линий
#property indicator_style1 STYLE_SOLID              // стиль линий
#property indicator_label1  "StochasticTopLevel"    // наименование буфера
// bottom level буфер
#property indicator_type2 DRAW_LINE                 // линии
#property indicator_color2  clrRed                  // цвет линий
#property indicator_width2  1                       // толщина линий
#property indicator_style2 STYLE_SOLID              // стиль линий
#property indicator_label2  "StochasticBottomLevel" // наименование буфера


// глобальные переменные индикатора
int                handleSTOC;                      // хэндл Стохастика
int                lastBarIndex;                    // индекс последнего бара 
int                retCode;                         // для записи результата вычисления  расхождения  
long               countDiv;                        // счетчик тренд линий (для рисования линий расхождений) 

PointDivSTOC       divergencePoints;                // точки расхождения Стохастика на ценовом графике и на графике Стохастика
CChartObjectTrend  trendLine;                       // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                        // объект класса вертикальной линии
CisNewBar          isNewBar;                        // для проверки формирования нового бара

// буферы индикатора 
double bufferTopLevel[];                            // буфер уровней top level
double bufferBottomLevel[];                         // буфер уровней bottom level
double bufferDiv[];                                 // буфер моментов расхождения

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
   // загружаем хэндл индикатора Стохастика
   handleSTOC = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   if ( handleSTOC == INVALID_HANDLE)  // если не удалось загрузить хэндл Стохастика
    {
     return(INIT_FAILED);  // то инициализация завершилась не успенно
    }  
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // связываем индикаторы с буферами 
   SetIndexBuffer(0,bufferTopLevel,INDICATOR_DATA);     // буфер top level Стохастика
   SetIndexBuffer(1,bufferBottomLevel,INDICATOR_DATA);  // буфер bottom level Стохастика
   SetIndexBuffer(2,bufferDiv ,INDICATOR_CALCULATIONS); // буфер расхождений (моментов возникновения сигналов)
   // инициализация глобальных  переменных
   countDiv = 0;                                        // выставляем начальное количество расхождений
   return(INIT_SUCCEEDED); // успешное завершение инициализации индикатора
  }

// деинициализация индикатора
void OnDeinit(const int reason)
 {
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // очищаем индикаторные буферы
   ArrayFree(bufferTopLevel);
   ArrayFree(bufferBottomLevel);
   ArrayFree(bufferDiv);
   // освобождаем хэндл Стохастика
   IndicatorRelease(handleSTOC);
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
      if ( CopyBuffer(handleSTOC,0,0,rates_total,bufferTopLevel)    < 0 ||
           CopyBuffer(handleSTOC,1,0,rates_total,bufferBottomLevel) < 0 )
           {
             // если не удалось загрузить буфера Стохастика
             Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы Стохастика");
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
            Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось установить индексацию массивов как в таймсерии");
            return (0);
          }
       // проходим по всем барам истории и ищем расхождения Стохастика
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          // обнуляем буфер сигналов расхождений Стохастика
          bufferDiv[lastBarIndex] = 0;
          retCode = divergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, divergencePoints, lastBarIndex);
          // если не удалось загрузить буферы Стохастика
          if (retCode == -2)
           {
             Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы Стохастика");
             return (0);
           }
          // если BUY и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == 1 && divergencePoints.timeExtrPrice1 != onePointBuy
                           && divergencePoints.timeExtrPrice2 != onePointBuy
                           && divergencePoints.timeExtrPrice1 != twoPointBuy
                           && divergencePoints.timeExtrPrice2 != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
             bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение      
             // сохраняем время экстремумов цен
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // если SELL и точки экстремумов цены не совпадают с предыдущим расхождением 
          if (retCode == -1 && divergencePoints.timeExtrPrice1 != onePointSell
                           && divergencePoints.timeExtrPrice2 != onePointSell
                           && divergencePoints.timeExtrPrice1 != twoPointSell
                           && divergencePoints.timeExtrPrice2 != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
             bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение      
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
          if ( CopyBuffer(handleSTOC,0,0,rates_total,bufferTopLevel)    < 0 ||
               CopyBuffer(handleSTOC,1,0,rates_total,bufferBottomLevel) < 0 )
           {
             // если не удалось загрузить буфера Стохастика
             Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы STOC");
             return (rates_total);
           }   
          retCode = divergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, divergencePoints, 0);  // получаем сигнал на расхождение
          // если не удалось загрузить буферы Стохастика
          if (retCode == -2)
           {
             Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы Стохастика");
             return (0);
           }
          if (retCode)
           {                                        
             DrawIndicator (time[0]);       // отображаем графические элементы индикатора    
             bufferDiv[0] = retCode;        // сохраняем текущий сигнал
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
   trendLine.Create(0,"STOCLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
   vertLine.Color(clrRed);
   // создаем вертикальную линию, показывающий момент появления расхождения Стохастика
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // увеличиваем количество отображаемых схождений
 }