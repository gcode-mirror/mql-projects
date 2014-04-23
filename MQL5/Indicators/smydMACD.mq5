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
//| Индикатор, показывающий расхождения MACD                         |
//| 1) рисует MACD                                                   |
//| 2) рисует линиями расхождения на MACD и на графике цены          |
//| 3) рисует стрелочками момент возникновения сигнала               |
//+------------------------------------------------------------------+

// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                       // для проверки формирования нового бара
#include <Divergence/divergenceMACD.mqh>           // подключаем библиотеку для поиска расхождений MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // для рисования линий расхождения
#include <CompareDoubles.mqh>                      // для проверки соотношения  цен

// входные пользовательские параметры индикатора
sinput string macd_params     = "";                // ПАРАМЕТРЫ ИНДИКАТОРА MACD
input  int    fast_ema_period = 12;                // период быстрой средней MACD
input  int    slow_ema_period = 26;                // период медленной средней MACD
input  int    signal_period   = 9;                 // период усреднения разности MACD
input  ENUM_APPLIED_PRICE priceType = PRICE_CLOSE; // тип цен, по которым вычисляется MACD

// параметры индикаторных буферов 
#property indicator_buffers 2                      // задействовано 2 индикаторных буфера
#property indicator_plots   1                      // 1 буфер отображаются на графиках

// параметры  буфера (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // гистограммы
#property indicator_color1  clrWhite               // цвет гистограммы
#property indicator_width1  1                      // толщина гистограммы
#property indicator_label1  "MACD"                 // наименование буфера

// глобальные переменные индикатора
int                handleMACD;                     // хэндл MACD
int                lastBarIndex;                   // индекс последнего бара 
int                retCode;                        // для записи результата вычисления  расхождения  
long               countDiv;                       // счетчик тренд линий (для рисования линий расхождений) 

PointDivMACD       divergencePoints;               // точки расхождения MACD на ценовом графике и на графике MACD
CChartObjectTrend  trendLine;                      // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                       // объект класса вертикальной линии
CisNewBar          isNewBar;                       // для проверки формирования нового бара

// буферы индикатора 
double bufferMACD[];                               // буфер уровней MACD
double bufferDiv[];                                // буфер сигналов расхождения

// переменные для хранения времени последних отрицательных и положительных значений MACD

datetime  lastMinusMACD    = 0;                    // время последнего отрицательного MACD
datetime  lastPlusMACD     = 0;                    // время последнего положительного MACD

// переменные для хранения времени перехода через ноль для расхождений MACD

datetime  divSellLastMinus = 0;                    // время последнего минуса расхождения на SELL
datetime  divBuyLastPlus   = 0;                    // время последнего плюса расхождения на BUY

// дополнительные функции работы индикатора
void    DrawIndicator (datetime vertLineTime);     // отображает линии индикатора. В функцию передается время вертикальной линии (сигнала расхождения)
   
// инициализация индикатора
int OnInit()
  {  
   // буфер сигналов расхождений устанавливаем как в таймсерии
   ArraySetAsSeries(bufferDiv,true);
   // буфер MACD устанавливаем как в таймсерии
   ArraySetAsSeries(bufferMACD,true);
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if ( handleMACD == INVALID_HANDLE)  // если не удалось загрузить хэндл MACD
    {
     return(INIT_FAILED);  // то инициализация завершилась не успенно
    }  
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // связываем индикаторы с буферами 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);         // буфер MACD
   SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS); // буфер расхождений (моментов возникновения сигналов)
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
   ArrayFree(bufferMACD);
   ArrayFree(bufferDiv);
   // освобождаем хэндл MACD
   IndicatorRelease(handleMACD);
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
      // загрузим буфер MACD
      if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
           {
             // если не удалось загрузить буфера MACD
             Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
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
            Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось установить индексацию массивов как в таймсерии");
            return (0);
          }
       // проходим по всем барам истории и ищем расхождения MACD
       for (lastBarIndex = rates_total-2;lastBarIndex > 1; lastBarIndex--)
        {
          // обнуляем буфер сигналов расхождений MACD
          bufferDiv[lastBarIndex] = 0;        
          // сохраняем время последних 
          if (bufferMACD[lastBarIndex+1] > 0)  // если MACD положительный  
            {
              // то сохраняем время 
              lastPlusMACD = time[lastBarIndex+1];            
            }
          if (bufferMACD[lastBarIndex+1] < 0)  // если MACD отрицательный 
            {
              // то сохраняем время
              lastMinusMACD = time[lastBarIndex+1];        
            }
          // если мы дошли до бара, с которого можно начать вычислять расхождения
          if (lastBarIndex <= (rates_total-DEPTH_MACD-1) )
           {
            retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,lastBarIndex);  // получаем сигнал на расхождение
            // если не удалось загрузить буферы MACD
            if (retCode == -2)
              {
               Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
               return (0);
              }
            // если расхождение на SELL и время минуса MACD последнего расхождения отличается от времени последнего минуса
            if (retCode == _Sell && divSellLastMinus != lastMinusMACD)
              {                                          
               DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
               bufferDiv[lastBarIndex] = _Sell;    // сохраняем в буфер значение       
               divSellLastMinus = lastMinusMACD;     // сохраняем время последнего минуса MACD
              }
            // если расхождение на BUY и время плюса MACD последнего расхождения отличается от времени последнего плюса
            if (retCode == _Buy && divBuyLastPlus != lastPlusMACD)
              {                                          
               DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
               bufferDiv[lastBarIndex] = _Buy;    // сохраняем в буфер значение       
               divBuyLastPlus = lastPlusMACD;        // сохраняем время последнего плюса MACD
              }            
            }
        }
           
                             
    }
    else    // если это не первый вызов индикатора 
     {
       // если сформировался новый бар
       if (isNewBar.isNewBar() > 0 )
        {
              // положим индексацию нужных массивов как в таймсерии
          if ( !ArraySetAsSeries (time, true) || 
               !ArraySetAsSeries (open, true) || 
               !ArraySetAsSeries (high, true) ||
               !ArraySetAsSeries (low,  true) || 
               !ArraySetAsSeries (close,true) )
              {
               // если не удалось установаить индексацию как в таймсерии для всех массивов цен и времени
               Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось установить индексацию массивов как в таймсерии");
               return (rates_total);
              }
          // обнуляем буфер сигнала расхождений
          bufferDiv[0] = 0;
          if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
           {
             // если не удалось загрузить буфера MACD
             Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
             return (rates_total);
           }   
          // сохраняем последние времена MACD
          if (bufferMACD[2] > 0 ) // если текущий MACD больше нуля
            {
              // то сохраняем время
              lastPlusMACD = time[2];
            }           
          if (bufferMACD[2] < 0 ) // если текущий MACD меньше нуля
            {
              // то сохраняем время
              lastMinusMACD = time[2];
            }
          
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints, 0);  // получаем сигнал на расхождение
          // если не удалось загрузить буферы MACD
          if (retCode == -2)
           {
             Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
             return (0);
           }
          // если расхождение на SELL и время последнего минуса расхождения отличается от последнего минуса MACD
          if (retCode == _Sell && divSellLastMinus != lastMinusMACD)
           {                                        
             DrawIndicator (time[0]);          // отображаем графические элементы индикатора    
             bufferDiv[0] = _Sell;           // сохраняем текущий сигнал
             divSellLastMinus = lastMinusMACD; // сохраняем время последнего минуса
           }    
          // если расхождение на BUY и время последнего плюса расхождения отличается от последнего плюса MACD
          if (retCode == _Buy && divBuyLastPlus != lastPlusMACD)
           {                                        
             DrawIndicator (time[0]);          // отображаем графические элементы индикатора    
             bufferDiv[0] = _Buy;           // сохраняем текущий сигнал
             divBuyLastPlus = lastPlusMACD;    // сохраняем время последнего плюса
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
   trendLine.Create(0,"MacdPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // создаем линию схождения\расхождения на MACD
   trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
   vertLine.Color(clrRed);
   // создаем вертикальную линию, показывающий момент появления расхождения MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // увеличиваем количество отображаемых схождений
 }