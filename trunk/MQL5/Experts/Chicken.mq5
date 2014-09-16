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
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double volume = 0.1;
input int    spread   = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;

CTradeManager ctm;       //торговый класс
CisNewBar *isNewBar;
SPositionInfo pos_info;
STrailing trailing;

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
 
 pos_info.volume = volume;
 pos_info.expiration = 0;
 
 trailing.trailingType = trailingType;
 trailing.minProfit    = minProfit;
 trailing.trailingStop = trailingStop;
 trailing.trailingStep = trailingStep;
 trailing.handlePBI    = handle_pbi;
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
 ctm.DoTrailing();
 int diff;
 double slPrice;
 static int index_max = -1;
 static int index_min = -1;
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 double stoplevel = MathMax(50, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
 CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi);

 if(isNewBar.isNewBar())
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyHigh(_Symbol, _Period, 0, DEPTH, buffer_high) < DEPTH ||
      CopyLow(_Symbol, _Period, 0, DEPTH, buffer_low)  < DEPTH )
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
   pos_info.tp = 0;
   if(index_max < ALLOW_INTERVAL && bid > buffer_high[index_max] + stoplevel)
   {
    diff = (bid - buffer_high[index_max])/Point();
    pos_info.type = OP_SELLSTOP;
    pos_info.sl = diff;
    pos_info.priceDifference = diff;
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
   
   if(index_min < ALLOW_INTERVAL && ask < buffer_low[index_min] - stoplevel)
   {
    diff = ( buffer_low[index_min] - ask)/Point();
    pos_info.type = OP_BUYSTOP;
    pos_info.sl = diff;
    pos_info.priceDifference = diff;
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
  }
  else
  {
   if(ctm.GetPositionType(_Symbol) == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol) < ask) 
   {
    //log_file.Write(LOG_DEBUG, StringFormat("ask %.05f ",ask));
    slPrice = ask;
    ctm.ModifyPosition(_Symbol, slPrice, 0); 
   }
   if(ctm.GetPositionType(_Symbol) == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol) > bid) 
   {
    //log_file.Write(LOG_DEBUG, StringFormat("bid %.05f",bid));
    slPrice = bid;
    ctm.ModifyPosition(_Symbol, slPrice, 0); 
   }
  }
 }
 else
 {
  ctm.ClosePendingPosition(_Symbol);
 }
}
//+------------------------------------------------------------------+
