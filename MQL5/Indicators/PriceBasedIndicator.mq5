//+------------------------------------------------------------------+
//|                                          PriceBasedIndicator.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property description "ColoredTrend"
//---- номер версии индикатора
#property version   "1.00"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчета и отрисовки индикатора использовано семь буферов
#property indicator_buffers 7
//---- использовано три графических построения
#property indicator_plots   3
//---- в качестве индикатора использованы цветные свечи
#property indicator_type1   DRAW_COLOR_CANDLES
//---- в качестве индикатора использованы стрелки
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
//---- в качестве цветов свечей использован набор цветов
#property indicator_color1 clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow
//---- отображение метки линии индикатора
#property indicator_label1  "ColoredTrend"

//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <ColoredTrend.mqh>

//+----------------------------------------------------------------+
//|  объявление динамических массивов-индикаторных буферов         |
//+----------------------------------------------------------------+
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorsBuffer[];
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int historyDepth = 40;     // глубина истории для расчета
input int bars=30;         // сколько свечей показывать
input bool messages=false;   // вывод сообщений в лог "Эксперты"

//+----------------------------------------------+
//| Глобальные переменные индикатора             |
//+----------------------------------------------+
static CIsNewBar isNewBar;

CColoredTrend *trend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- инициализация глобальных переменных  
  symbol = Symbol();
  current_timeframe = Period();
  digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  trend = new CColoredTrend(symbol, current_timeframe, bars, historyDepth);
  
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(3, ExtCloseBuffer, INDICATOR_DATA);
   
   bool AsSeries = false;
   ArraySetAsSeries(ExtOpenBuffer, AsSeries);
   ArraySetAsSeries(ExtHighBuffer, AsSeries);
   ArraySetAsSeries(ExtLowBuffer, AsSeries);
   ArraySetAsSeries(ExtCloseBuffer, AsSeries);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, bars + 1);
//---- превращение динамического массива в индексный буфер   
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);
//---- для отрисовки максимумов используем стрелку вниз(218)
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
//---- для отрисовки минимумов используем стрелку вверх(217)
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
//---- установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---- имя для окон данных и метка для окон
   string short_name="ColoredTrend";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // количество истории в барах на текущем тике
                const int prev_calculated, // количество баров, обработанных на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],     // close[rates_total - 2] - последний фиксированный close
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total < bars + historyDepth) return(0);
/*   
//---- объявление целочисленных переменных
   int first, bar;
   if(prev_calculated > rates_total || prev_calculated <= 0) // проверка на первый старт расчета индикатора
      first = rates_total - bars;           // стартовый номер для расчета всех баров
   else first = prev_calculated - 1;        // стартовый номер для расчета новых баров
*/   
//---- проверка на начало нового бара
   if(isNewBar.isNewBar(symbol, current_timeframe))
   {
    Print("init trend, rates_total = ", rates_total);
    trend.CountMoveType(bars, historyDepth);
    
    //--- На новом баре производим вычисление и перезапись буферов
    //--- инициализируем буферы пустыми значениями
    ArrayInitialize(ExtOpenBuffer, 0.0);
    ArrayInitialize(ExtHighBuffer, 0.0);
    ArrayInitialize(ExtLowBuffer, 0.0);
    ArrayInitialize(ExtCloseBuffer, 0.0);
    ArrayInitialize(ExtUpArrowBuffer, 0.0);
    ArrayInitialize(ExtDownArrowBuffer, 0.0);
    
    //--- копируем цены в буферы
    for(int bar = rates_total - bars - historyDepth; bar < rates_total - 1  && !IsStopped(); bar++) // заполняем ценами заданное количество баров, кроме формирующегося
    {
     //--- записываем цены в буферы
     ExtOpenBuffer[bar] = open[bar];
     ExtHighBuffer[bar] = high[bar];
     ExtLowBuffer[bar] = low[bar];
     ExtCloseBuffer[bar] = close[bar];
     
   //--- вычислим соответствующий индекс для графических буферов
     int buffer_index = bar - rates_total + bars + historyDepth;
   //--- зададим цвет свечи
     ExtColorsBuffer[bar] = trend.GetMoveType(buffer_index); 
   //--- зададим код символа из шрифта Wingdings для отрисовки в PLOT_ARROW
     if (buffer_index > 0)
     {
      if (trend.GetExtremumDirection(buffer_index) > 0)
      {
       ExtUpArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      }
      else
      {
       ExtUpArrowBuffer[bar] = 0;
      }
      if (trend.GetExtremumDirection(buffer_index) < 0)
      {
       ExtDownArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      }
      else
      {
       ExtDownArrowBuffer[bar] = 0;
      }
     }
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+



