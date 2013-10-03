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
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>

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

CColoredTrend *trend, *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
int startBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init Started");
//---- инициализация глобальных переменных  
  symbol = Symbol();
  current_timeframe = Period();
  digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  trend = new CColoredTrend(symbol, current_timeframe, bars, historyDepth);
  topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), bars, historyDepth);
  
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
/*
   //--- инициализируем буферы пустыми значениями
   ArrayInitialize(ExtOpenBuffer, 0.0);
   ArrayInitialize(ExtHighBuffer, 0.0);
   ArrayInitialize(ExtLowBuffer, 0.0);
   ArrayInitialize(ExtCloseBuffer, 0.0);
   ArrayInitialize(ExtUpArrowBuffer, 0.0);
   ArrayInitialize(ExtDownArrowBuffer, 0.0);
   ArrayInitialize(ExtColorsBuffer, clrNONE);
*/  
   Print("Init succesful");
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
   
//---- объявление целочисленных переменных
   int first, bar;
   if(prev_calculated > rates_total || prev_calculated <= 0) // проверка на первый старт расчета индикатора
   {
    first = rates_total - bars - historyDepth;           // стартовый номер для расчета всех баров
    startBars =  rates_total - 1;
   }
   else first = prev_calculated - 1;        // стартовый номер для расчета новых баров
   
//---- проверка на начало нового бара
   if(isNewBar.isNewBar(symbol, GetBottomTimeframe(current_timeframe)))
   {
  //  Print("init trend, rates_total = ", rates_total);
    
    //--- копируем цены в буферы
    for(int bar = first; bar < rates_total - 1  && !IsStopped(); bar++) // заполняем ценами заданное количество баров, кроме формирующегося
    {
   //--- вычислим соответствующий индекс для графических буферов
     PrintFormat("bar=%d, startBars=%d",bar,startBars);
     int buffer_index = bar - startBars + bars + historyDepth + 1;
     topTrend.CountMoveType(buffer_index);
     //trend.CountMoveType(bars, historyDepth, topTrend.GetMoveType(topTFBarsDepth - 1));
     trend.CountMoveType(buffer_index, topTrend.GetMoveType(buffer_index));
     
     //--- записываем цены в буферы
     ExtOpenBuffer[bar] = open[bar];
     ExtHighBuffer[bar] = high[bar];
     ExtLowBuffer[bar] = low[bar];
     ExtCloseBuffer[bar] = close[bar];
     
   //--- зададим цвет свечи
     ExtColorsBuffer[bar] = trend.GetMoveType(buffer_index); 
     //PrintFormat("bar = %d, buf_index = %d, MoveType = %s", bar, buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)));
     //PrintFormat("open_buf = %.05f, high_buf = %.05f, low_buf = %.05f, close_buf = %.05f, open = %.05f, high = %.05f, low = %.05f, close = %.05f"
     //           , ExtOpenBuffer[bar], ExtHighBuffer[bar], ExtLowBuffer[bar], ExtCloseBuffer[bar]
     //           , open[bar], high[bar], low[bar], close[bar]);
           
   //--- зададим код символа из шрифта Wingdings для отрисовки в PLOT_ARROW
     if (trend.GetExtremumDirection(buffer_index) > 0)
     {
      ExtUpArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      //Print("Максимум");
     }
     else
     {
      ExtUpArrowBuffer[bar] = 0;
     }
     if (trend.GetExtremumDirection(buffer_index) < 0)
     {
      ExtDownArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      //Print("Минимум");
     }
     else
     {
      ExtDownArrowBuffer[bar] = 0;
     }
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+



