//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBar.mqh>    //для проверки формирования нового бара
#include <CDivergence\CDivergenceMACD.mqh>   // подключаем библиотеку для поиска схождений и расхождений MACD
//+------------------------------------------------------------------+
//| Индикатор расхождений MACD                                       |
//+------------------------------------------------------------------+

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

input short               bars=100;                  // начальное количество баров истории
input short               tale=15;                   // малый хвост для поиска экстремума
input int                 fast_ema_period=9;         // период быстрой средней
input int                 slow_ema_period=12;        // период медленной средней
input int                 signal_period=6;           // период усреднения разности
input ENUM_APPLIED_PRICE  applied_price=PRICE_HIGH;  // тип цены или handle
input uint                priceDifference=0;         // разница цен для поиска экстремума   

//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

int handleMACD;                       // хэндл MACD
string symbol = _Symbol;              // текущий символ
ENUM_TIMEFRAMES timeFrame = _Period;  // текущий таймфрейм

double tg;                            // тангенс угла наклона линии

double line_buffer[];                 // буфер линии вверх 

// структура хранения точек 
struct Vertex
  {
   uint   n_bar;             //номер бара 
   double price;             //ценовое положение точки
  };

Vertex pn1,pn2;   // две точки, соединяющиеся между собой линией (pn1 - левая точка, pn2 - правая точка)
bool   first_calculate = true;   // флаг первого вызова OnCalculate


//+------------------------------------------------------------------+
//| Рассчетные функции индикатора                                    |          
//+------------------------------------------------------------------+

double   GetTan()
//вычисляет значение тангенса наклона линии
 {
   return ( pn2.price - pn1.price ) / ( pn2.n_bar - pn1.n_bar );   
 } 

double   GetLineY (uint n_bar)
//возвращает значение Y точки текущей линии
 {
   return (pn1.price + (n_bar-pn1.n_bar)*tg);
 }

//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(symbol, timeFrame, fast_ema_period,slow_ema_period,signal_period,applied_price);
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
   // вызываем функцию рассчета схождений\расхождений
   int retCode;  // тип, возвращаемый функцией поиска схождений\расхождений
   int index;    // счетчки прохода по циклу 
   // если первый запуск OnCalculate
   if ( first_calculate )
    {
     // меняем флаг на противоложный
     first_calculate = false; 
     // проходим по всех барам и обнуляем буфер индикатора
     for (index=rates_total-1;index>=0;index--)
      {
       line_buffer[index] = 0;
      }
     // сохраняем в retCode
     retCode = divergenceMACD(handleMACD,symbol,timeFrame,0);
     retCode = 1;
     if (retCode == 1)  // если найдено расхождение
      {
       // Alert("НАШЛИ РАСХОЖДЕНИЕ - Левая точка = ");
       // сохранение координат точек
       //pn1.n_bar = index_Price_global_max; 
       pn1.n_bar = rates_total-11;
       pn1.price = high[rates_total-11];
       pn2.n_bar = rates_total-1;
       pn2.price = high[rates_total-1];
       // вычисление тангенса
       tg = GetTan();
       Alert("ТАНГЕНС = ",tg);
       //вычисление точек линии
       for (index=pn1.n_bar;index<pn2.n_bar;index++)
        {
         line_buffer[index] = GetLineY(index);

        }
       //return(rates_total);
      }
     if (retCode == -1) // если найдено схождение 
      {  
       // Alert("НАШЛИ СХОЖДЕНИЕ - Правая точка = ");
       // сохранение координат точек
              
       // вычисление тангенса
       tg = GetTan();       
      }
     
     
    }
    return(rates_total);
  }
