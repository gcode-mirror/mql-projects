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
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input int      bars = 128;         // сколько свечей показывать
input double   percentage_ATR = 0.25;
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
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), bars, percentage_ATR);
   trend    = new CColoredTrend(symbol,                  current_timeframe, bars, percentage_ATR);
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
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayInitialize(ExtUpArrowBuffer, 0);
   ArrayInitialize(ExtDownArrowBuffer, 0);
   ArrayInitialize(ExtTopUpArrowBuffer, 0);
   ArrayInitialize(ExtTopDownArrowBuffer, 0);
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
   delete topTrend;
   delete trend;
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
    start_index = rates_total - bars;
    start_time = TimeCurrent() - bars*seconds_current;
    start_iteration = rates_total - bars;
   }
   else 
   { 
    //buffer_index = prev_calculated - start_index;
    start_iteration = prev_calculated-1;
   }
   
   if(NewBarCurrent.isNewBar() > 0 && prev_calculated != 0)
   {
    //PrintFormat("%s : сработал новый бар на текущем", TimeToString(TimeCurrent()));
    buffer_index++ ;//+= NewBarTop.isNewBar();
   }
   
   if(NewBarTop.isNewBar() > 0 && prev_calculated != 0)
   {
    //PrintFormat("%s : сработал новый бар на старшем", TimeToString(TimeCurrent()));
    top_buffer_index++ ;//+= NewBarTop.isNewBar();
   }
   
   if(NewBarBottom.isNewBar() > 0 || prev_calculated == 0) //isNewBar bottom_tf
   {
    PrintFormat("Prev_calc = %d; rates_total = %d", prev_calculated, rates_total);
    int error = 0;
    
    for (int i = start_iteration; i < rates_total; i++)
    {
     int start_pos_top = GetNumberOfTopBarsInCurrentBars(current_timeframe, bars) - top_buffer_index;
     if(start_pos_top < 0) start_pos_top = 0;
     
     error = topTrend.CountMoveType(top_buffer_index, start_pos_top);
     if(error != 0)
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE TOP. Error = ", error);
      return(prev_calculated);
     }

     error = trend.CountMoveType(buffer_index, (rates_total-1) - i, topTrend.GetMoveType(top_buffer_index));
     if(error != 0) 
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR BECAUSE CURRENT. Error = ", error);
      return(prev_calculated);
     }
     
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i];
     if(!show_top) ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
     else
     {
      //PrintFormat("TIME: %s : i = %d; bit = %d; move type = %s", TimeToString(TimeCurrent()), i, top_buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)));
      ColorCandlesColors [i] = topTrend.GetMoveType(top_buffer_index);
     }
     
     //PrintFormat("TIME: %s : buffer_index = %d; top_buffer_index = %d; current_move = %s; top_move = %s", TimeToString(start_time+buffer_index*seconds_current), buffer_index, top_buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));

     if (trend.GetExtremumDirection(buffer_index) > 0)
     {
      ExtUpArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      PrintFormat("Максимум %d __ %d", i, buffer_index);
     }
     else if (trend.GetExtremumDirection(buffer_index) < 0)
     {
      ExtDownArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      PrintFormat("Минимум %d __ %d", i, buffer_index);
     }
     
    /* if (topTrend.GetExtremumDirection(top_buffer_index) > 0)
     {
      ExtTopUpArrowBuffer[i-9] = topTrend.GetExtremum(top_buffer_index);
      //PrintFormat("Максимум %s : %d __ %d", TimeToString(start_time+seconds_current*buffer_index),  i, top_buffer_index);
     }
     else if (topTrend.GetExtremumDirection(top_buffer_index) < 0)
     {
      ExtTopDownArrowBuffer[i-9] = topTrend.GetExtremum(top_buffer_index);
      //PrintFormat("Минимум %s : %d __ %d", TimeToString(start_time+seconds_current*buffer_index), i, top_buffer_index);
     }*/

     //PrintFormat("%s : current = %d; %s; top = %d; %s; i = %d", TimeToString(start_time+buffer_index*seconds_current), buffer_index, EnumToString((ENUM_MOVE_TYPE)trend.GetMoveType(buffer_index)), top_buffer_index, EnumToString((ENUM_MOVE_TYPE)topTrend.GetMoveType(top_buffer_index)), i);       
     if(buffer_index < bars) 
     {
      buffer_index++;
      top_buffer_index = (start_time + seconds_current*buffer_index)/seconds_top - start_time/seconds_top;
     } 
    }
   }//END isNewBar bottom_tf     
   return(rates_total);
  }
  
  
  int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe, int current_bars)
  {
   return ((current_bars*PeriodSeconds(timeframe))/PeriodSeconds(GetTopTimeframe(timeframe)));
  }