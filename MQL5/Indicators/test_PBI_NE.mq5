//+------------------------------------------------------------------+
//|                                           DRAW_COLOR_CANDLES.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   5
//--- plot ColorCandles
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow

#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW

//----------------------------------------------------------------
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include <ColoredTrend/ColoredTrendNE.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input int      depth = 1000;         // сколько свечей показывать
input double   percentage_ATR = 0.5;
input bool     show_top = false;
//--- индикаторные буферы
double         ColorCandlesBuffer1[];
double         ColorCandlesBuffer2[];
double         ColorCandlesBuffer3[];
double         ColorCandlesBuffer4[];
double         ColorCandlesColors[];
double         ExtUpArrowBuffer[];
double         ExtDownArrowBuffer[];
double         ExtTopUpArrowBuffer[];
double         ExtTopDownArrowBuffer[];


CisNewBar NewBarBottom,
          NewBarCurrent, 
          NewBarTop;

CColoredTrend *trend, 
              *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//int buffer_index = 0;
//int top_buffer_index = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init");
   symbol = Symbol();
   current_timeframe = Period();
   NewBarBottom.SetPeriod(GetBottomTimeframe(current_timeframe));
   NewBarCurrent.SetLastBarTime(current_timeframe);
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   PrintFormat("TOP = %s, BOTTOM = %s", EnumToString((ENUM_TIMEFRAMES)NewBarTop.GetPeriod()), EnumToString((ENUM_TIMEFRAMES)NewBarBottom.GetPeriod()));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), depth, percentage_ATR);
   trend    = new CColoredTrend(symbol,                  current_timeframe, depth, percentage_ATR);
//--- indicator buffers mapping
   SetIndexBuffer(0,ColorCandlesBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ColorCandlesBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ColorCandlesBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ColorCandlesBuffer4,INDICATOR_DATA);
   SetIndexBuffer(4,ColorCandlesColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(7, ExtTopUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(8, ExtTopDownArrowBuffer, INDICATOR_DATA);
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   PlotIndexSetInteger(3, PLOT_ARROW, 201);
   PlotIndexSetInteger(4, PLOT_ARROW, 200);
   
   ArraySetAsSeries(ColorCandlesBuffer1, false);
   ArraySetAsSeries(ColorCandlesBuffer2, false);
   ArraySetAsSeries(ColorCandlesBuffer3, false);
   ArraySetAsSeries(ColorCandlesBuffer4, false);

   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   //Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayInitialize(ExtUpArrowBuffer, 0);
   ArrayInitialize(ExtDownArrowBuffer, 0);
   ArrayInitialize(ExtTopUpArrowBuffer, 0);
   ArrayInitialize(ExtTopDownArrowBuffer, 0);
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
   topTrend.Zeros();
   trend.Zeros();
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   static int start_index = 0;
   static int start_iteration = 0;
   static datetime start_time;
   static int buffer_index = 0;
   static int top_buffer_index = 0;
   
   int seconds_current = PeriodSeconds(current_timeframe);
   int seconds_top = PeriodSeconds(GetTopTimeframe(current_timeframe));

   if(prev_calculated == 0) 
   {
    Print("Первый расчет индикатора");
    buffer_index = 0;
    top_buffer_index = 0;
    start_index = rates_total - depth;
    start_time = TimeCurrent() - depth*seconds_current;
    start_iteration = rates_total - depth;
    topTrend.Zeros();
    trend.Zeros();
    ArrayInitialize(ColorCandlesBuffer1, 0);
    ArrayInitialize(ColorCandlesBuffer2, 0);
    ArrayInitialize(ColorCandlesBuffer3, 0);
    ArrayInitialize(ColorCandlesBuffer4, 0);
   }
   else 
   { 
    //buffer_index = prev_calculated - start_index;
    start_iteration = start_index + buffer_index - 1;//prev_calculated-1;
   }
   
   bool error = true;
    for(int i =  start_iteration; i < rates_total;  i++)    
    {
     int start_pos_top = GetNumberOfTopBarsInCurrentBars(current_timeframe, depth) - top_buffer_index;
     if(start_pos_top < 0) start_pos_top = 0;
     
     error = topTrend.CountMoveType(top_buffer_index, start_pos_top);
     if(!error)
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE TOP. Error = ", error);
      return(0);
     }
     error = trend.CountMoveType(buffer_index, (rates_total-1) - i, topTrend.GetMoveType(top_buffer_index));
     if(!error) 
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE CURRENT. Error = ", error);
      return(0);
     } 
      
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i]; 
     
     if(!show_top) 
      ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
     else
     {
      ColorCandlesColors [i] = topTrend.GetMoveType(top_buffer_index);
     }
     
     if(buffer_index < depth)
     {
      buffer_index++;
      top_buffer_index = (start_time + seconds_current*buffer_index)/seconds_top - start_time/seconds_top;
     }
    }
   
   if(NewBarCurrent.isNewBar() > 0 && prev_calculated != 0)
   {
    buffer_index++;
   }
   
   if(NewBarTop.isNewBar() > 0 && prev_calculated != 0)
   {
    top_buffer_index++;
   }
   
   return(rates_total);
  }
  
  
  int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe, int current_bars)
  {
   return ((current_bars*PeriodSeconds(timeframe))/PeriodSeconds(GetTopTimeframe(timeframe)));
  }
