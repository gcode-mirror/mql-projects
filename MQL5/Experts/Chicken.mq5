//+------------------------------------------------------------------+
//|                                                      Chicken.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>

#define DEPTH 20
#define ALLOW_INTERVAL 16
#define DEFAULT_VOLUME 1
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;

CTradeManager ctm;       //торговый класс
CisNewBar *isNewBar;

int handle_pbi;
double buffer_pbi[1];
double buffer_high[];
double buffer_low[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 isNewBar = new CisNewBar(_Symbol, _Period);
 handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handle_pbi);
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();
 int sl;
 static int index_max = -1;
 static int index_min = -1;
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 int stoplevel_points = MathMax(50, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));
 double stoplevel = stoplevel_points*Point();
 CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi);
 if(isNewBar.isNewBar())
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyHigh(_Symbol, _Period, 0, DEPTH, buffer_high) < DEPTH ||
      CopyLow(_Symbol, _Period, 0, DEPTH, buffer_low)  < DEPTH)
  {
   index_max = -1;
   index_min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
  }
  
  index_max = ArrayMaximum(buffer_high);
  index_min = ArrayMinimum(buffer_low);
 }
 
 if(buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
 {
  if(ctm.GetPositionCount() == 0)
  {
   if(index_max <= ALLOW_INTERVAL && bid > buffer_high[index_max] + stoplevel)
   {
    sl = (bid - buffer_high[index_max])/Point();
    ctm.OpenUniquePosition(_Symbol, _Period, OP_SELLSTOP, DEFAULT_VOLUME, sl, 0, TRAILING_TYPE_PBI, minProfit, trailingStop, trailingStep, handle_pbi, stoplevel_points);
    PrintFormat("SELLSTOP: sl = %d; bid = %f max = %f; point = %f", sl, bid, buffer_high[index_max], Point());
   }
   
   if(index_min <= ALLOW_INTERVAL && ask < buffer_low[index_min] - stoplevel)
   {
    sl = (buffer_low[index_min] - ask)/Point();
    ctm.OpenUniquePosition(_Symbol, _Period, OP_BUYSTOP, DEFAULT_VOLUME, sl, 0, TRAILING_TYPE_PBI, minProfit, trailingStop, trailingStep, handle_pbi, stoplevel_points);
    PrintFormat("BUYSTOP: sl = %d; min = %f ask = %f; point = %f", sl, buffer_low[index_min], ask, Point());
   }
  }
  else
  {
   if(ctm.GetPositionType(_Symbol) == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol) < ask) 
   {
    sl = ask;
    ctm.ModifyPosition(_Symbol, sl, 0); 
   }
   if(ctm.GetPositionType(_Symbol) == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol) > bid) 
   {
    sl = bid;
    ctm.ModifyPosition(_Symbol, sl, 0); 
   }
  }
 }
 else
 {
  ctm.ClosePendingPosition(_Symbol);
 }
}
//+------------------------------------------------------------------+
