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
input int    spread = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input double tp_ko = 1;
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

double highPrice[], lowPrice[], closePrice[];
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
 MqlDateTime timeCurrent;
 int diff_high, diff_low, sl_min, tp;
 double slPrice;
 double highBorder, lowBorder;
 double stoplevel;
 static int index_max = -1;
 static int index_min = -1;
 double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 if(isNewBar.isNewBar() || recountInterval)
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_Symbol, _Period, 1, 1, closePrice)     < 1 ||      // цена закрытия последнего сформированного бара
     CopyHigh(_Symbol, _Period, 1, DEPTH, buffer_high) < DEPTH ||  // буфер максимальных цен всех сформированных баров на заданую глубину
     CopyLow(_Symbol, _Period, 1, DEPTH, buffer_low)   < DEPTH ||  // буфер минимальных цен всех сформированных баров на заданую глубину
     CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // последнее полученное движение
  {
   index_max = -1;
   index_min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
   recountInterval = true;
  }
  index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
  {
   highBorder = buffer_high[index_max];
   lowBorder = buffer_low[index_min];
   sl_min = MathMax((int)MathCeil((highBorder - lowBorder)*0.10/Point()), 50);
   tp = (int)MathCeil((highBorder - lowBorder)*0.75/Point());
   diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
   diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
   stoplevel = MathMax(sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
 
   pos_info.tp = 0;
   
   if(index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], highBorder) && diff_high > sl_min)
   { 
    PrintFormat("Цена закрытия пробила цену максимум = %s, Время = %s, цена = %.05f, sl_min = %d, diff_high = %d",
          DoubleToString(highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_high);
    pos_info.type = OP_SELLSTOP;
    pos_info.sl = diff_high;
    pos_info.tp = tp;
    pos_info.priceDifference = (closePrice[0] - highBorder)/Point();
    pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
    trailing.minProfit = 2*diff_high;
    trailing.trailingStop = diff_high;
    trailing.trailingStep = 5;
    if ((pos_info.tp > pos_info.sl*tp_ko))
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
    
   if(index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], lowBorder) && diff_low > sl_min)
   {
    PrintFormat("Цена закрытия пробила цену минимум = %s, Время = %s, цена = %.05f, sl_min = %d, diff_low = %d",
          DoubleToString(lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_low);
             
    pos_info.type = OP_BUYSTOP;
    pos_info.sl = diff_low;
    pos_info.tp = tp;
    pos_info.priceDifference = (lowBorder - closePrice[0])/Point();
    pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
    trailing.minProfit = 2*diff_low;
    trailing.trailingStop = diff_low;
    trailing.trailingStep = 5;
    
    TimeCurrent(timeCurrent);
    if ((pos_info.tp > pos_info.sl*tp_ko))
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
}
//+------------------------------------------------------------------+