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
//---- для расчета и отрисовки индикатора использовано пять буферов
#property indicator_buffers 5
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы цветные свечи
#property indicator_type1   DRAW_COLOR_CANDLES
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

CColoredTrend trend(Symbol(), bars, historyDepth);
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
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer, INDICATOR_DATA);
   //SetIndexBuffer(3, ExtCloseBuffer, INDICATOR_DATA);
   
   Print("Индикаторный буфер является таймсерией = ",ArrayGetAsSeries(ExtCloseBuffer));
   SetIndexBuffer(0,ExtCloseBuffer,INDICATOR_DATA);
   Print("Индикаторный буфер после SetIndexBuffer() является таймсерией = ",
         ArrayGetAsSeries(ExtCloseBuffer));
   
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, bars + 1);
//--- установка количества цветов 11 для цветового буфера
// PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,11);
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
                const double &open[],      // массивы НЕ таймсерии
                const double &high[],
                const double &low[],
                const double &close[],     // close[rates_total - 2] - последний фиксированный close
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {//--- скопируем значения скользящей средней в буфер MABuffer
   
   Print("Индикаторный буфер является таймсерией = ",ArrayGetAsSeries(close));
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
