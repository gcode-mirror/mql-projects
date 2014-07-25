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
#define MIN_DEPTH 4
#define DEFAULT_VOLUME 1
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
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
 static int max = -1;
 static int min = -1;
 static ENUM_TM_POSITION_TYPE order_type = OP_UNKNOWN;
 CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi);
 if(isNewBar.isNewBar())
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyHigh(_Symbol, _Period, 0, DEPTH, buffer_high) < DEPTH &&
      CopyLow(_Symbol, _Period, 0, DEPTH, buffer_low)  < DEPTH)
  {
   max = -1;
   min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
  }
  
  max = ArrayMaximum(buffer_high);
  min = ArrayMinimum(buffer_low);
 }
 
 if(buffer_pbi[0] == MOVE_TYPE_FLAT && max != -1 && min != -1)
 {
  //Кто ты
  if(max <= (DEPTH - 1 - MIN_DEPTH) && SymbolInfoDouble(_Symbol, SYMBOL_BID) > buffer_high[max] + SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*Point())
  {
   ctm.OpenUniquePosition(_Symbol, _Period, OP_SELLSTOP, DEFAULT_VOLUME);
  }
  if(min <= (DEPTH - 1 - MIN_DEPTH) && SymbolInfoDouble(_Symbol, SYMBOL_ASK) < buffer_low[min] - SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*Point())
  {
   ctm.OpenUniquePosition(_Symbol, _Period, OP_BUYSTOP, DEFAULT_VOLUME);
  }
  
  //ChangeStopLoss
  //ctm.ModifyPosition(_Symbol, 
 }
 else
 {
  max = -1;
  min = -1;
  order_type = OP_UNKNOWN;
  ctm.ClosePosition(_Symbol);
 }
}
//+------------------------------------------------------------------+
