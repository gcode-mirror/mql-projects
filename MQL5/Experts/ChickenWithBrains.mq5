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

int handle_pbi;
bool closePosition;
CTradeManager ctm;       //торговый класс
CisNewBar *newBar;
SPositionInfo pos_info;
STrailing trailing;
CChickensBrain *chicken;
double buffer_high[];
double buffer_low[];
double closePrice[];

int OnInit()
{
 newBar = new CisNewBar();
 newBar.isNewBar();
 handle_pbi = DoesIndicatorExist(_Symbol,_Period,"PriceBasedIndicator");
 if (handle_pbi == INVALID_HANDLE)
 {
  handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
  if (handle_pbi == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
   return (INIT_FAILED);
  }
  SetIndicatorByHandle(_Symbol,_Period,handle_pbi);
 }  
 chicken = new CChickensBrain(_Symbol,_Period,handle_pbi);
 pos_info.volume = volume;
 pos_info.expiration = 0;
 trailing.trailingType = trailingType;
 trailing.handleForTrailing = handle_pbi;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete chicken;
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
 MqlDateTime timeCurrent;
 int diff_high, diff_low, sl_min, tp;
 double highBorder, lowBorder;
 double slPrice;
 double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 static int index_max = -1;
 static int index_min = -1;
 ArraySetAsSeries(buffer_high, false);
 ArraySetAsSeries(buffer_low, false);
 closePosition = true;
 if(newBar.isNewBar())
 {
  if(CopyClose(_Symbol, _Period, 1, 1, closePrice)     < 1 ||      // цена закрытия последнего сформированного бара
     CopyHigh(_Symbol, _Period, 1, DEPTH, buffer_high) < DEPTH ||  // буфер максимальных цен всех сформированных баров на заданую глубину
     CopyLow(_Symbol, _Period, 1, DEPTH, buffer_low)   < DEPTH)    // буфер минимальных цен всех сформированных баров на заданую глубину
     //CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // последнее полученное движение
  {
   index_max = -1;
   index_min = -1;
   PrintFormat("%s, Не удалось скопировать буферы цены", MakeFunctionPrefix(__FUNCTION__));
  }
  index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  highBorder = buffer_high[index_max];
  lowBorder = buffer_low[index_min];
  diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
  diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
  pos_info.tp = 0; //???
 }
 switch(chicken.GetSignal())
 {
  case SELL:
   sl_min = MathMax((int)MathCeil((highBorder - lowBorder)*0.10/Point()), 50);
   tp = (use_tp) ? (int)MathCeil((highBorder - lowBorder)*0.75/Point()) : 0;
   pos_info.type = OP_SELLSTOP;
   pos_info.sl = diff_high;
   pos_info.tp = tp;
   pos_info.priceDifference = (closePrice[0] - highBorder)/Point();
   pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
   trailing.minProfit = 2 * diff_high;
   trailing.trailingStop = diff_high;
   trailing.trailingStep = 5;
   if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko)
   {
    PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
   Print("Получили сигнал на продажу SELL");
  break;
  case BUY:
   pos_info.type = OP_BUYSTOP;
   pos_info.sl = diff_low;
   pos_info.tp = tp;
   pos_info.priceDifference = (lowBorder - closePrice[0])/Point();
   pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
   trailing.minProfit = 2 * diff_low;
   trailing.trailingStop = diff_low;
   trailing.trailingStep = 5;
   if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko)
   {
    PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
   Print("Получили сигнал на покупку BUY");
  break;
  case NO_POSITION:
   ctm.ClosePendingPosition(_Symbol);
   closePosition = false;
   Print("Получили сигнал NO_POSITION");
  break;
  case NO_ENTER:
   closePosition = false;
  break;
 }
 
 if(closePosition && ctm.GetPositionCount() != 0)
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
