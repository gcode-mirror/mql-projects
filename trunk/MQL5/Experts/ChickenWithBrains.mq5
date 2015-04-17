//+------------------------------------------------------------------+
//|                                                         TEST.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <DrawExtremums\CExtrContainer.mqh>
#include <TradeManager\TradeManager.mqh>             // торговая библиотека
#include <Chicken\ChickensBrain.mqh>                 // объект по вычислению сигналов для торговли
#include <SystemLib/IndicatorManager.mqh>            // библиотека по работе с индикаторами


// ОШИБЕА: Получает сигнал, открывает позиции но сразу пишет [auto trading disabled by client]
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double volume = 0.1;
input int    spread = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input bool use_tp = false;
input double tp_ko = 2;

int handleTrailing;
int chickenSignal;
CTradeManager ctm;       //торговый класс
SPositionInfo pos_info;
STrailing trailing;
CChickensBrain *chicken;

int OnInit()
{
 if(trailingType == TRAILING_TYPE_PBI)
 {
   handleTrailing = iCustom(_Symbol, _Period, "PriceBasedIndicator");
   if (handleTrailing == INVALID_HANDLE)
   {
    Print(__FUNCTION__,"Не удалось создать хэндл индикатора PriceBasedIndicator");
    return (INIT_FAILED);
   }
 }   
 if(trailingType == TRAILING_TYPE_EXTREMUMS)
 {
  handleTrailing = iCustom(_Symbol, _Period, "DrawExtremums");
  if (handleTrailing == INVALID_HANDLE)
  {
   Print(__FUNCTION__,"Не удалось создать хэндл индикатора DrawExtremums");
   return (INIT_FAILED);
  }
 }
 chicken = new CChickensBrain(_Symbol,_Period);
 pos_info.volume = volume;
 pos_info.expiration = 0;
 trailing.trailingType = trailingType;
 trailing.handleForTrailing = handleTrailing;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete chicken;
 IndicatorRelease(handleTrailing);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();
 ctm.DoTrailing();
 //MqlDateTime timeCurrent;
 int tp;
 double slPrice;
 double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 chickenSignal = chicken.GetSignal(); // получаем сигнал с ChickensBrain
 if(chickenSignal == SELL || chickenSignal == BUY)
 {
  if(chickenSignal == SELL)
  {
   Print("Получили сигнал на продажу SELL");
   pos_info.type = OP_SELLSTOP; 
   pos_info.sl = chicken.GetDiffHigh();
   trailing.minProfit = 2*chicken.GetDiffHigh();
   trailing.trailingStop = chicken.GetDiffHigh();
  }
  if(chickenSignal == BUY)
  {
   Print("Получили сигнал на покупку BUY");
   pos_info.type = OP_BUYSTOP;
   pos_info.sl   = chicken.GetDiffLow();
   trailing.minProfit = 2 * chicken.GetDiffLow();
   trailing.trailingStop = chicken.GetDiffLow();
  }
  //stoplevel = MathMax(chicken.sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
  tp = (use_tp) ? (int)MathCeil((chicken.GetHighBorder() - chicken.GetLowBorder())*0.75/Point()) : 0; 
  pos_info.tp = tp;
  pos_info.priceDifference = chicken.GetPriceDifference();
  pos_info.expiration = MathMax(DEPTH - chicken.GetIndexMax(), DEPTH - chicken.GetIndexMin());
  trailing.trailingStep = 5;
  if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko)
  {
   PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
  }
 }
 
 if(chickenSignal == NO_POSITION)
 {
  Print("Получили сигнал на  NO_POSITION");
  ctm.ClosePendingPosition(_Symbol);
 }
 else if(ctm.GetPositionCount() != 0)
 {
  ENUM_TM_POSITION_TYPE type = ctm.GetPositionType(_Symbol);
  if(type == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol) < curAsk) 
  {
   slPrice = curAsk;
   ctm.ModifyPosition(_Symbol, slPrice, 0);  
  }
  if(type == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol) > curBid) 
  {
   slPrice = curBid;
   ctm.ModifyPosition(_Symbol, slPrice, 0); 
  }
  if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp >0 && pos_info.tp <= pos_info.sl*tp_ko))
  {
   ctm.ClosePendingPosition(_Symbol);
  } 
 } 
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

}
//+------------------------------------------------------------------+
