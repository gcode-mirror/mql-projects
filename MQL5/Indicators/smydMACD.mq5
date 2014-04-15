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
#property indicator_buffers 3                      // задействовано 3 индикаторных буфера
#property indicator_plots   2                      // 2 буфера отображаются на графиках

// параметры буферов

// параметры 1-го буфера (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // гистограммы
#property indicator_color1  clrWhite               // цвет гистограммы
#property indicator_width1  1                      // толщина гистограммы
#property indicator_label1  "MACD"                 // наименование буфера

// параметры 2-го буфера (сигнальная линия MACD)
#property indicator_type2 DRAW_LINE                // линии
#property indicator_color2  clrRed                 // цвет линии
#property indicator_width2  1                      // толщина линии
#property indicator_style2  STYLE_DASHDOT          // стиль линии
#property indicator_label2  "SIGNAL"               // наименование буфера

// глобальные переменные индикатора
int                handleMACD;                     // хэндл MACD
int                lastBarIndex;                   // индекс последнего бара 
int                retCode;                        // для записи результата вычисления  расхождения  
long               countDiv;                       // счетчик тренд линий (для рисования линий расхождений) 

PointDivMACD       divergencePoints;               // точки расхождения MACD на ценовом графике и на графике MACD
CChartObjectTrend  trendLine;                      // объект класса трендовой линии (для отображения расхождений)
CisNewBar          isNewBar;                       // для проверки формирования нового бара

// буферы индикатора 
double bufferMACD[];                               // буфер уровней MACD
double signalMACD[];                               // сигнальный буфер MACD
double bufferDiv[];                                // буфер моментов расхождения

   
// инициализация индикатора
int OnInit()
  {
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
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);         // буфер сигнальной линии
   SetIndexBuffer(2,bufferDiv ,INDICATOR_CALCULATIONS); // буфер расхождений (моментов возникновения сигналов)
   // инициализация глобальных  переменных
   countDiv = 0;                                        // выставляем начальное количество расхождений
   return(INIT_SUCCEEDED); // успешное завершение инициализации индикатора
  }

// деинициализация индикатора
void OnDeinit()
 {
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // очищаем индикаторные буферы
   ArrayFree(bufferMACD);
   ArrayFree(signalMACD);
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
      if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
           CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
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
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,lastBarIndex);  // получаем сигнал на расхождение
          // если не удалось загрузить буферы MACD
          if (retCode == -2)
           {
             Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
             return (0);
           }
          if (retCode)
           {                                          
            trendLine.Color(clrYellow);
            //создаем линию схождения\расхождения                    
            trendLine.Create(0,"MacdPriceLine_"+countDiv,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            trendLine.Color(clrYellow);         
            //создаем линию схождения\расхождения на MACD
            trendLine.Create(0,"MACDLine_"+countDiv,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
            countDiv++; // увеличиваем количество отображаемых схождений
           }
        }
          
      // Salnikova    
                             
    }
   return(rates_total);
  }