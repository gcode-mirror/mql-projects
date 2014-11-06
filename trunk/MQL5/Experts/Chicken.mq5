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
#define ALLOW_INTERVAL 18
#define SL_MIN 50
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double volume = 0.1;
input int    spread = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/

CTradeManager ctm;       //торговый класс
CisNewBar *isNewBar;
SPositionInfo pos_info;
STrailing trailing;

int handle_pbi;
double buffer_pbi[1];
double buffer_high[];
double buffer_low[];

double prevAsk, prevBid, curAsk, curBid;
bool recountInterval;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 isNewBar = new CisNewBar(_Symbol, _Period);
 handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if ( handle_pbi == INVALID_HANDLE )
 {
  Print("Ошибка при иниализации эксперта. Не удалось создать хэндл индикатора PriceBasedIndicator");
  return (INIT_FAILED);
 } 
 recountInterval = false;
 
 pos_info.volume = volume;
 pos_info.expiration = 0;
 
 trailing.trailingType = trailingType;
 /*
 trailing.minProfit    = minProfit;
 trailing.trailingStop = trailingStop;
 trailing.trailingStep = trailingStep;
 */
 trailing.handleForTrailing = handle_pbi;
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
 int diff, sl_min;
 double slPrice;
 double highBorder, lowBorder;
 double stoplevel;
 static int index_max = -1;
 static int index_min = -1;
 prevAsk = curAsk;
 prevBid = curBid;
 curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi);

 if(isNewBar.isNewBar() || recountInterval)
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
  recountInterval = false;
 }
 
 if (index_max != -1 && index_min != -1)
 {
  highBorder = buffer_high[index_max];
  lowBorder = buffer_low[index_min];
  sl_min = (int)MathCeil((highBorder - lowBorder)*0.15);
  stoplevel = MathMax(SL_MIN, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
 }
 else
 {
  return;
 }
 
 if(buffer_pbi[0] == MOVE_TYPE_FLAT)
 {
  pos_info.tp = 0;
  if(index_max < ALLOW_INTERVAL && curBid > highBorder + stoplevel && prevBid <= highBorder + stoplevel)
  { 
   Comment("Цена BID пробила цену максимум = ",DoubleToString(buffer_high[index_max]),
           "\nВремя = ",TimeToString(TimeCurrent()),
           "\nцена = ",DoubleToString(prevAsk)            
          );
   //PrintFormat("индекс = %d, значение = %.05f", index_max, buffer_high[index_max]);
   recountInterval = true;
   diff = (curBid - highBorder)/Point();
   pos_info.type = OP_SELLSTOP;
   pos_info.sl = diff;
   pos_info.priceDifference = diff;
   trailing.minProfit = diff;
   trailing.trailingStop = diff;
   trailing.trailingStep = 5;
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
  }
   
  if(index_min < ALLOW_INTERVAL && curAsk < lowBorder - stoplevel && prevAsk > lowBorder - stoplevel)
  {
   Comment("Цена ASK пробила цену минимум = ",DoubleToString(buffer_low[index_min]),
           "\nВремя = ",TimeToString(TimeCurrent()),
           "\nцена = ",DoubleToString(prevAsk)
          );   
   //PrintFormat("индекс = %d, значение = %.05f", index_min, buffer_low[index_min]);
   recountInterval = true;
   diff = (lowBorder - curAsk)/Point();
   pos_info.type = OP_BUYSTOP;
   pos_info.sl = diff;
   pos_info.priceDifference = diff;
   trailing.minProfit = diff;
   trailing.trailingStop = diff;
   trailing.trailingStep = 5;
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
  }
  
  if(ctm.GetPositionCount() != 0)
  {
   if(ctm.GetPositionType(_Symbol) == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol) < curAsk) 
   {
    slPrice = curAsk;
    ctm.ModifyPosition(_Symbol, slPrice, 0); 
   }
   if(ctm.GetPositionType(_Symbol) == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol) > curBid) 
   {
    slPrice = curBid;
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