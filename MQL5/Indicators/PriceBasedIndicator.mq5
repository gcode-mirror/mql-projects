//+------------------------------------------------------------------+
//|                                                    PBI_SHARP.mq5 |
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
#include <CompareDoubles.mqh>
#include <Lib CisNewBarDD.mqh>
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <CLog.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input int      history_depth = 1000; // сколько свечей показывать
input double   percentage_ATR = 1;   // процент АТР для появления нового экстремума
input double   difToTrend = 1.5;     // разница между экстремумами для появления тренда
//--- индикаторные буферы
double ColorCandlesBuffer1[];
double ColorCandlesBuffer2[];
double ColorCandlesBuffer3[];
double ColorCandlesBuffer4[];
double ColorCandlesColors[];
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];

CisNewBar NewBarCurrent, 
          NewBarTop;

CColoredTrend *trend, 
              *topTrend;
              
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int  digits;
int depth = history_depth;
bool series_order = true;
input bool show_top = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   PrintFormat("%s Init", MakeFunctionPrefix(__FUNCTION__));
   symbol = Symbol();
   current_timeframe = Period();
   if(Bars(symbol, current_timeframe) < depth) depth = Bars(symbol, current_timeframe)-1;
   PrintFormat("Глубина поиска равна: %d", depth);
   NewBarCurrent.SetPeriod(current_timeframe);
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), depth);
   trend    = new CColoredTrend(symbol,                  current_timeframe, depth);
//--- indicator buffers mapping
   SetIndexBuffer(0, ColorCandlesBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ColorCandlesBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ColorCandlesBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ColorCandlesBuffer4, INDICATOR_DATA);
   SetIndexBuffer(4,  ColorCandlesColors, INDICATOR_DATA);
   SetIndexBuffer(5,    ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6,  ExtDownArrowBuffer, INDICATOR_DATA);

   InitializeIndicatorBuffers();
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   
   ArraySetAsSeries(ColorCandlesBuffer1, series_order);
   ArraySetAsSeries(ColorCandlesBuffer2, series_order);
   ArraySetAsSeries(ColorCandlesBuffer3, series_order);
   ArraySetAsSeries(ColorCandlesBuffer4, series_order);
   ArraySetAsSeries( ColorCandlesColors, series_order);
   ArraySetAsSeries(   ExtUpArrowBuffer, series_order);   
   ArraySetAsSeries( ExtDownArrowBuffer, series_order);
   
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayFree(ExtUpArrowBuffer);
   ArrayFree(ExtDownArrowBuffer);
   ArrayFree(ColorCandlesBuffer1);
   ArrayFree(ColorCandlesBuffer2);
   ArrayFree(ColorCandlesBuffer3);
   ArrayFree(ColorCandlesBuffer4);
   ArrayFree(ColorCandlesColors);
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
   static int buffer_index = 0;
   static int top_buffer_index = 0;
   SExtremum extr_cur[2] = {{0, -1}, {0, -1}};
   SExtremum extr_top[2] = {{0, -1}, {0, -1}};
   
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);
   
   if(prev_calculated == 0) 
   {
    PrintFormat("%s Первый расчет индикатора", MakeFunctionPrefix(__FUNCTION__));

    buffer_index = 0;
    top_buffer_index = 0;
    trend.Zeros();
    topTrend.Zeros();
    InitializeIndicatorBuffers();
    //PrintFormat("%s %s depth = %d; history_depth = %d", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)current_timeframe), depth, history_depth);
    NewBarCurrent.isNewBar(time[depth]);
    NewBarTop.isNewBar(time[depth]);
    
    for(int i = depth-1; i >= 0;  i--)    
    {
     //PrintFormat("i= %d; buffer_index = %d; time = %s;", i, buffer_index, TimeToString(time[i]));   
     topTrend.CountMoveType(top_buffer_index, time[i], false, extr_top);    
        trend.CountMoveType(    buffer_index, time[i], false, extr_cur, topTrend.GetMoveType(top_buffer_index));
      
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i]; 
    
     if(!show_top) ColorCandlesColors[i] = trend.GetMoveType(buffer_index);
     else  ColorCandlesColors[i] = topTrend.GetMoveType(top_buffer_index);
    
     if (extr_cur[0].direction > 0)
     {
      ExtUpArrowBuffer[i] = extr_cur[0].price;// + 50*_Point;
      extr_cur[0].direction = 0;
     }
     if (extr_cur[1].direction < 0)
     {
      ExtDownArrowBuffer[i] = extr_cur[1].price;// - 50*_Point;
      extr_cur[1].direction = 0;
     }
    
     if(    NewBarTop.isNewBar(time[i])) top_buffer_index++; //для того что бы считать на истории
     if(NewBarCurrent.isNewBar(time[i])) 
     {
      //trend.PrintExtr();
      //PrintFormat("HISTORY %s %s current:%d %s; top: %d %s", EnumToString((ENUM_TIMEFRAMES)current_timeframe), TimeToString(time[i]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
      buffer_index++;     //для того что бы считать на истории
     }
    }
    PrintFormat("%s Первый расчет индикатора ОКОНЧЕН", MakeFunctionPrefix(__FUNCTION__));
   }
   
   topTrend.CountMoveType(top_buffer_index, time[0], true, extr_top);
   trend.CountMoveType(buffer_index, time[0], true, extr_cur, topTrend.GetMoveType(top_buffer_index));
   
   //PrintFormat("buffer_index = %d; time = %s;", buffer_index, TimeToString(time[0]));   
   ColorCandlesBuffer1[0] = open[0];
   ColorCandlesBuffer2[0] = high[0];
   ColorCandlesBuffer3[0] = low [0];
   ColorCandlesBuffer4[0] = close[0]; 
   if(!show_top) ColorCandlesColors[0] = trend.GetMoveType(buffer_index);
   else  ColorCandlesColors[0] = topTrend.GetMoveType(top_buffer_index);
   
   if (extr_cur[0].direction > 0)
   {
    ExtUpArrowBuffer[0] = extr_cur[0].price;// + 50*_Point;
    extr_cur[0].direction = 0;
   }
   if (extr_cur[1].direction < 0)
   {
    ExtDownArrowBuffer[0] = extr_cur[1].price;// - 50*_Point;
    extr_cur[1].direction = 0;
   }
   
      
   if(NewBarTop.isNewBar()  && prev_calculated != 0) top_buffer_index++;     
   if(NewBarCurrent.isNewBar() && prev_calculated != 0)
   {
    //trend.PrintExtr();
    //PrintFormat("REAL %s %s current:%d %s; top: %d %s", EnumToString((ENUM_TIMEFRAMES)current_timeframe), TimeToString(time[0]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
    buffer_index++; 
   }
   return(rates_total);
  }


void InitializeIndicatorBuffers()
{
 ArrayInitialize(ColorCandlesBuffer1, 0);
 ArrayInitialize(ColorCandlesBuffer2, 0);
 ArrayInitialize(ColorCandlesBuffer3, 0);
 ArrayInitialize(ColorCandlesBuffer4, 0);
 ArrayInitialize(ColorCandlesColors , 0);
 ArrayInitialize(ExtUpArrowBuffer   , 0);
 ArrayInitialize(ExtDownArrowBuffer , 0);
}