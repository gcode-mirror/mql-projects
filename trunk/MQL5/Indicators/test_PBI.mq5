//+------------------------------------------------------------------+
//|                                           DRAW_COLOR_CANDLES.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   3
//--- plot ColorCandles
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow

#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW

//----------------------------------------------------------------
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input int      bars = 50;         // сколько свечей показывать
input double   percentage_ATR = 0.05;
input bool     show_extr = false;  //показывать экстремумы 
//--- индикаторные буферы
double         ColorCandlesBuffer1[];
double         ColorCandlesBuffer2[];
double         ColorCandlesBuffer3[];
double         ColorCandlesBuffer4[];
double         ColorCandlesColors[];
double         ExtUpArrowBuffer[];
double         ExtDownArrowBuffer[];

static CisNewBar NewBarBottom,
                 NewBarTop;

CColoredTrend *trend, 
              *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
int buffer_index = 0;
//int buffer_index_top = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init");
   symbol = Symbol();
   current_timeframe = Period();
   NewBarBottom.SetPeriod(GetBottomTimeframe(current_timeframe));
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   trend    = new CColoredTrend(symbol, current_timeframe, bars, percentage_ATR);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), bars, percentage_ATR);
//--- indicator buffers mapping
   SetIndexBuffer(0,ColorCandlesBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ColorCandlesBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ColorCandlesBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ColorCandlesBuffer4,INDICATOR_DATA);
   SetIndexBuffer(4,ColorCandlesColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   ArraySetAsSeries(ColorCandlesBuffer1, false);
   ArraySetAsSeries(ColorCandlesBuffer2, false);
   ArraySetAsSeries(ColorCandlesBuffer3, false);
   ArraySetAsSeries(ColorCandlesBuffer4, false);
  
 /*  int total_bars = Bars(symbol, current_timeframe);
   MqlRates rates[];
   CopyRates(symbol, current_timeframe, 0, bars, rates);
   for(int i = total_bars - bars + 1; i < total_bars; i++)
   {
    Print ("i = ", i, "total = ", total_bars,"buffer_index = ", buffer_index);
    //topTrend.CountMoveType(buffer_index_top, 0);
    //trend.CountMoveType(buffer_index, (total_bars-1) - i);//, topTrend.GetMoveType(buffer_index_top));
     
    Print("ind ", i , "= ", ColorCandlesBuffer1[]);
    //Print("ra ", buffer_index , "= ", rates[buffer_index].open); 
    //ColorCandlesBuffer1[i] = rates[buffer_index].open;
    //ColorCandlesBuffer2[i] = rates[buffer_index].high;
    //ColorCandlesBuffer3[i] = rates[buffer_index].low;
    //ColorCandlesBuffer4[i] = rates[buffer_index].close;
    //ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
    buffer_index++;
   }
   */
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayInitialize(ExtUpArrowBuffer, 0);
   ArrayInitialize(ExtDownArrowBuffer, 0);
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
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
   //Print("Begin onCalculate");
   static int start_index = 0;
   static int start_iteration = 0;
   static int buffer_index = 0;
   static int buffer_index_top = 0;

   if(prev_calculated == 0) 
   {
    start_index = rates_total - bars;
    start_iteration = rates_total - bars;
   }
   else 
   { 
    buffer_index = prev_calculated - start_index;
    start_iteration = prev_calculated-1;
   }
   
   if(NewBarTop.isNewBar() > 0)
   {
    buffer_index_top++ ;//+= NewBarTop.isNewBar();
   }
   
   if(NewBarBottom.isNewBar() > 0 || prev_calculated == 0) //isNewBar bottom_tf
   {
    for(int i = start_iteration; i < rates_total; i++)
    {
     //PrintFormat("buffer_index = %d; buffer_index_top = %d: from %d to %d/ top_bars %d", buffer_index, buffer_index_top, i, rates_total-1, Bars(symbol, GetTopTimeframe(current_timeframe)));
     if(topTrend.CountMoveType(buffer_index_top, 0) != 0)
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE TOP");
      return(prev_calculated);
     } 
     if(trend.CountMoveType(buffer_index, (rates_total-1) - i) != 0)//, topTrend.GetMoveType(buffer_index_top)) != 0);
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE CURRENT");
      return(prev_calculated);
     } 
     
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i];
     ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
     
     if (trend.GetExtremumDirection(buffer_index) > 0)
     {
      ExtUpArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      //PrintFormat("Максимум %d __ %d", i, buffer_index);
     }
     else if (trend.GetExtremumDirection(buffer_index) < 0)
     {
      ExtDownArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      //PrintFormat("Минимум %d __ %d", i, buffer_index);
     }
   
     if(buffer_index < bars) buffer_index++;
    }
   }//END isNewBar bottom_tf
        
   return(rates_total);
  }