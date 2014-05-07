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
#include <ColoredTrend/ColoredTrendNE.mqh>
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
input bool show_top = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   PrintFormat("%s Init", MakeFunctionPrefix(__FUNCTION__));
   symbol = Symbol();
   current_timeframe = Period();
   if(Bars(symbol, current_timeframe) < depth) depth = Bars(symbol, current_timeframe);
   PrintFormat("Глубина поиска равна: %d", depth);
   NewBarCurrent.SetPeriod(current_timeframe);
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), depth, percentage_ATR, difToTrend);
   trend    = new CColoredTrend(symbol,                  current_timeframe, depth, percentage_ATR, difToTrend);
//--- indicator buffers mapping
   SetIndexBuffer(0, ColorCandlesBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ColorCandlesBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ColorCandlesBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ColorCandlesBuffer4, INDICATOR_DATA);
   SetIndexBuffer(4,  ColorCandlesColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,    ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6,  ExtDownArrowBuffer, INDICATOR_DATA);

   ArrayInitialize(   ExtUpArrowBuffer, 0);
   ArrayInitialize( ExtDownArrowBuffer, 0); 
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   
   ArraySetAsSeries(ColorCandlesBuffer1, false);
   ArraySetAsSeries(ColorCandlesBuffer2, false);
   ArraySetAsSeries(ColorCandlesBuffer3, false);
   ArraySetAsSeries(ColorCandlesBuffer4, false);
   ArraySetAsSeries( ColorCandlesColors, false);   

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
   static int start_index = 0;
   static int start_iteration = 0;
   static int buffer_index = 0;
   static int top_buffer_index = 0;
   SExtremum extr_cur = {0, -1};
   SExtremum extr_top = {0, -1};
   bool error = true;

   if(prev_calculated == 0) 
   {
    PrintFormat("%s Первый расчет индикатора", MakeFunctionPrefix(__FUNCTION__));
    start_index = rates_total - depth;
    start_iteration = rates_total - depth;
    buffer_index = 0;
    top_buffer_index = 0;
    trend.Zeros();
    topTrend.Zeros();
    ArrayInitialize(ColorCandlesBuffer1, 0);
    ArrayInitialize(ColorCandlesBuffer2, 0);
    ArrayInitialize(ColorCandlesBuffer3, 0);
    ArrayInitialize(ColorCandlesBuffer4, 0);
    ArrayInitialize(ColorCandlesColors , 0);
    ArrayInitialize(ExtUpArrowBuffer   , 0);
    ArrayInitialize(ExtDownArrowBuffer , 0);
   }
   else 
   {
    //PrintFormat("%s Предварительный Расчет индикатора закончен. Размер буфера = %d", MakeFunctionPrefix(__FUNCTION__), ArraySize(ColorCandlesColors));
    start_iteration = start_index + buffer_index;
   }
 
   for(int i = start_iteration; i < rates_total;  i++)    
   {
    error = topTrend.CountMoveType(top_buffer_index, time[i], extr_top);
    //PrintFormat("i = %d; top_buffer_index = %d; start_pos_top = %d; move type top = %s", i, top_buffer_index, start_pos_top, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
    if(!error)
    {
     Print("YOU NEED TO WAIT FOR THE NEXT BAR ON TOP TIMEFRAME");
     return(0);
    }
    
    error = trend.CountMoveType(buffer_index, time[i], extr_cur, topTrend.GetMoveType(top_buffer_index));
    //PrintFormat("i = %d; buffer_index = %d; start_pos_cur = %d; move type = %s", i, buffer_index, start_pos_cur, MoveTypeToString(trend.GetMoveType(buffer_index)));
    if(!error) 
    {
     Print("YOU NEED TO WAIT FOR THE NEXT BAR ON CURRENT TIMEFRAME");
     return(0);
    }
      
    ColorCandlesBuffer1[i] = open[i];
    ColorCandlesBuffer2[i] = high[i];
    ColorCandlesBuffer3[i] = low[i];
    ColorCandlesBuffer4[i] = close[i]; 
    
    //PrintFormat("%s current:%d %s; top: %d %s", TimeToString(time[i]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
    if(!show_top)
    { 
     ColorCandlesColors[i] = trend.GetMoveType(buffer_index);
    }
    else
    {
     ColorCandlesColors[i] = topTrend.GetMoveType(top_buffer_index);
    }
    
    if (extr_cur.direction > 0)
    {
     ExtUpArrowBuffer[i] = extr_cur.price;// + 50*_Point;
     extr_cur.direction = 0;
    }
    else if (extr_cur.direction < 0)
    {
     ExtDownArrowBuffer[i] = extr_cur.price;// - 50*_Point;
     extr_cur.direction = 0;
    }
    
    if(buffer_index < depth)
    {
     if(    NewBarTop.isNewBar(time[i])) top_buffer_index++;                    //для того что бы считать на истории
     if(NewBarCurrent.isNewBar(time[i])) buffer_index++;   //для того что бы считать на истории
    }
   }
   
   if(NewBarTop.isNewBar()  && prev_calculated != 0)
   {
    top_buffer_index++;
   }
   if(NewBarCurrent.isNewBar() && prev_calculated != 0)
   {
    buffer_index++;
   }
  
   return(rates_total);
  }
