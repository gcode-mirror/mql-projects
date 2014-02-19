//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBar.mqh>                  // для проверки формирования нового бара
#include <divergenceMACD.mqh>                 // подключаем библиотеку для поиска схождений и расхождений MACD
#include <ChartObjects\ChartObjectsLines.mqh> 

//+------------------------------------------------------------------+
//| Параметры индикатора                                             |
//+------------------------------------------------------------------+

#property indicator_buffers 1
//---- использовано 1 графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы отрезки
#property indicator_type1 DRAW_SECTION
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "Divergence MACD"

//+------------------------------------------------------------------+
//| Вводимые параметры индикатора                                    |
//+------------------------------------------------------------------+

input short               bars=2000;                  // начальное количество баров истории
input int                 fast_ema_period=9;         // период быстрой средней
input int                 slow_ema_period=12;        // период медленной средней
input int                 signal_period=6;           // период усреднения разности
input uint                priceDifference=0;         // разница цен для поиска экстремума   

//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

int             handleMACD;            // хэндл MACD
//string          symbol = _Symbol;          // текущий символ
//ENUM_TIMEFRAMES timeFrame = _Period;       // текущий таймфрейм

double          line_buffer[];             // буфер линии вверх 

bool            first_calculate = true;    // флаг первого вызова OnCalculate

PointDiv        divergencePoints;          // схождения и расхождения MACD

int             lastBarIndex;              // индекс последнего бара    

CChartObjectTrend  trendLine;            // объект класса трендовой линии

//int countTrend = 0;                        // количество тренд линий 

//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // назначаем буфер линий
   SetIndexBuffer(0,line_buffer,    INDICATOR_DATA);     
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   return(INIT_SUCCEEDED);
  }


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
    int indexBar; // индекс прохода по циклу 
    int retCode;  // результат вычисления схождения и расхождения
    // если это первый запуск фунции пересчета индикатора
    if (first_calculate)
     {
       if (bars > (rates_total-1) )
        {
         lastBarIndex = 0;
        }
       else
        {
         lastBarIndex = rates_total - bars - 1;
        }
       for (indexBar=lastBarIndex;indexBar < (rates_total-100-1); indexBar++)
        {
        //  Alert("indexBar = ",indexBar," ");
          // сканируем историю по хэндлу на наличие расхождений\схождений 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,indexBar,divergencePoints);
          // если схождение\расхождение обнаружено
          if (retCode)
           {
           // Alert("ДАТА = ",time[indexBar]);

        //    ArrayResize(trendLine,ArraySize(trendLine)+1);
            
            divergencePoints.extrMACD1 = time[indexBar];
            divergencePoints.valuePrice1 = high[indexBar];
            divergencePoints.extrPrice2 = time[indexBar-2];
            divergencePoints.valuePrice2 = high[indexBar-2];
            trendLine.Create(0,"TrendLine_"+indexBar,0,divergencePoints.extrMACD1,divergencePoints.valuePrice1,divergencePoints.extrPrice2,divergencePoints.valuePrice2);
        //    first_calculate = false;
          //  return(rates_total);
           }
        }
       first_calculate = false;
     }
    
    return(rates_total);
  }
