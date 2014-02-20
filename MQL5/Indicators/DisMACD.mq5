//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//#property indicator_chart_window
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                  // для проверки формирования нового бара
#include <divergenceMACD.mqh>                 // подключаем библиотеку для поиска схождений и расхождений MACD
#include <ChartObjects\ChartObjectsLines.mqh> // для рисования линий схождения\расхождения

//+------------------------------------------------------------------+
//| Свойства индикатора                                              |
//+------------------------------------------------------------------+

//---- всего задействовано 2 буфера
#property indicator_buffers 2
//---- использовано 1 графическое пос троение
#property indicator_plots   2

//---- в качестве индикатора использованы линии
#property indicator_type1 DRAW_LINE
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "MACD"

//---- в качестве индикатора использованы линии
#property indicator_type2 DRAW_LINE
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "Signal"

//+------------------------------------------------------------------+
//| Вводимые параметры индикатора                                    |
//+------------------------------------------------------------------+

input short               bars=20000;                // начальное количество баров истории
input int                 fast_ema_period=12;        // период быстрой средней MACD
input int                 slow_ema_period=26;        // период медленной средней MACD
input int                 signal_period=9;           // период усреднения разности MACD

//+------------------------------------------------------------------+
//| Буферы индикатора                                                |
//+------------------------------------------------------------------+

double bufferMACD[];   // основной буфер MACD
double signalMACD[];   // буфер сигнальной линии MACD

//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // флаг первого вызова OnCalculate
int                handleMACD;             // хэндл MACD
int                lastBarIndex;           // индекс последнего бара   
long               countTrend;             // счетчик тренд линий

PointDiv           divergencePoints;       // схождения и расхождения MACD
CChartObjectTrend  trendLine;              // объект класса трендовой линии
CisNewBar          isNewBar;               // для проверки формирования нового бара
 
//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);  
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);       
   // инициализация глобальных  переменных
   first_calculate = true;
   countTrend = 0;
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   //IndicatorAdd(1,handleMACD);
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
    int retCode;  // результат вычисления схождения и расхождения
    // если это первый запуск фунции пересчета индикатора
    if (first_calculate)
     {
       if (bars < 100)
        {
         lastBarIndex = 1;
        }
       else if (bars > rates_total)
        {
         lastBarIndex = rates_total-101;
        }
       else
        {
         lastBarIndex = bars-101;
        }
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          bufferMACD[lastBarIndex] = 0; 
          signalMACD[lastBarIndex] = 1;
          // сканируем историю по хэндлу на наличие расхождений\схождений 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,lastBarIndex,divergencePoints);
          // если схождение\расхождение обнаружено
          if (retCode)
           {    
            //создаем линию схождения\расхождения                    
            trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);
            
            trendLine.Create(1,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,0.5,divergencePoints.timeExtrMACD2,0.5);            
            //увеличиваем количество тренд линий
            countTrend++;
           }
        }
       first_calculate = false;
     }
    else  // если запуска не первый
     {
       // если сформирован новый бар
       if (isNewBar.isNewBar() > 0)
        {
         bufferMACD[lastBarIndex] = 0;
         signalMACD[lastBarIndex] = 1;
         // распознаем схождение\расхождение
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,1,divergencePoints);
         // если схождение\расхождение обнаружено
         if (retCode)
          {          
           // создаем линию схождения\расхождения              
           trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);
           // создаем линию между экстремумами MACD
           
           // увеличиваем количество тренд линий
           countTrend++;
          }        
        }
     } 
    
    return(rates_total);
  }
