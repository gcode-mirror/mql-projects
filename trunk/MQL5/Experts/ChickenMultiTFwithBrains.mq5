//+------------------------------------------------------------------+
//|                                     ChickenMultiTFwithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>
#include <Chicken\ChickensBrain.mqh>                 // объект по вычислению сигналов для торговли
#include <SystemLib/IndicatorManager.mqh>            // библиотека по работе с индикаторами

//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double  volume  = 0.1;
input int     spread  = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input bool    use_tp  = false;
input double   tp_ko  = 2;
input bool tradeTFM5  = true;
input bool tradeTFM15 = true;
input bool tradeTFH1  = true;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/
struct STradeTF
{
 bool used;
 ENUM_TIMEFRAMES period;
 STrailing trailing;
 CTradeManager *ctm;
 CChickensBrain *chicken;
};

CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
CisNewBar *isNewBarH1;
SPositionInfo pos_info;
STrailing trailing;
STradeTF  tradeTF[3];

STradeTF    tradeM5;
STradeTF    tradeM15;
STradeTF    tradeH1;
double      buffer_pbi[];
double      buffer_high[];
double      buffer_low[];


double highPrice[], lowPrice[], closePrice[];
bool   closePosition;
int    tmpLastBar;
int    handle;
            
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
if(!tradeTFM5 && !tradeTFM15 && !tradeTFH1)
 {
  PrintFormat("tradeTFM5 = %b, tradeTFM15 = %b, tradeTFH1 = %b", tradeTFM5, tradeTFM15, tradeTFH1);
  return(INIT_FAILED);
 }
 tradeM5.used    = tradeTFM5;
 tradeM5.period  = PERIOD_M5;
 tradeM15.used   = tradeTFM15;
 tradeM15.period = PERIOD_M15;
 tradeH1.used    = tradeTFH1;
 tradeH1.period  = PERIOD_H1;
 tradeTF[0] = tradeM5;  // 0 - индекс таймфрейма М5
 tradeTF[1] = tradeM15; // 1 - индекс таймфрейма М15
 tradeTF[2] = tradeH1;  // 2 - индекс таймфрейма H1

 for(int i = 0; i < 3; i++)
 {
  if(tradeTF[i].used == true)
  {
   tradeTF[i].ctm = new CTradeManager();
   if(trailingType == TRAILING_TYPE_PBI)
   {
    handle = DoesIndicatorExist(_Symbol, tradeTF[i].period, "PriceBasedIndicator");
    if (handle == INVALID_HANDLE)
    {
     handle = iCustom(_Symbol, tradeTF[i].period, "PriceBasedIndicator");
     if (handle == INVALID_HANDLE)
     {
      Print(__FUNCTION__,"Не удалось создать хэндл индикатора PriceBasedIndicator");
      return (INIT_FAILED);
     }
    }
    SetIndicatorByHandle(_Symbol,tradeTF[i].period,handle);
   }   
   if(trailingType == TRAILING_TYPE_EXTREMUMS)
   {
    handle = iCustom(_Symbol, tradeTF[i].period, "DrawExtremums");
    if (handle == INVALID_HANDLE)
    {
     Print(__FUNCTION__,"Не удалось создать хэндл индикатора DrawExtremums");
     return (INIT_FAILED);
    }
   }
   tradeTF[i].trailing.trailingType = trailingType;
   tradeTF[i].trailing.handleForTrailing = handle;
   /*
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trailingStop;
   trailing.trailingStep = trailingStep;
   */
   tradeTF[i].chicken = new CChickensBrain(_Symbol, tradeTF[i].period);
  } 
 }
 //recountInterval = false;
 pos_info.volume = volume;
 pos_info.expiration = 0;

 return(INIT_SUCCEEDED);
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int chickenSignal;
 //MqlDateTime timeCurrent;
 int tp;
 double slPrice;
 double curAsk;
 double curBid;
 for(int i = 0; i < 3; i++)
 { 
  if(tradeTF[i].used == true)
  {
   tradeTF[i].ctm.OnTick();
   tradeTF[i].ctm.DoTrailing();
  }
 }
 for(int i = 0; i < 3; i++)
 { 
  // если i-ый таймфрейм используется
  if(tradeTF[i].used == true)
  {
   curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   chickenSignal = tradeTF[i].chicken.GetSignal(); // получаем сигнал с ChickensBrain
   if(chickenSignal == SELL || chickenSignal == BUY)
   {
    if(chickenSignal == SELL)
    {
     Print("Получили сигнал на продажу SELL");
     pos_info.type = OP_SELLSTOP; 
     pos_info.sl = tradeTF[i].chicken.GetDiffHigh();
     tradeTF[i].trailing.minProfit = 2*tradeTF[i].chicken.GetDiffHigh();
     tradeTF[i].trailing.trailingStop = tradeTF[i].chicken.GetDiffHigh();
    }
    if(chickenSignal == BUY)
    {
     Print("Получили сигнал на покупку BUY");
     pos_info.type = OP_BUYSTOP;
     pos_info.sl   = tradeTF[i].chicken.GetDiffLow();
     tradeTF[i].trailing.minProfit = 2 * tradeTF[i].chicken.GetDiffLow();
     tradeTF[i].trailing.trailingStop = tradeTF[i].chicken.GetDiffLow();
    }
    //stoplevel = MathMax(chicken.sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
    tp = (use_tp) ? (int)MathCeil((tradeTF[i].chicken.GetHighBorder() - tradeTF[i].chicken.GetLowBorder())*0.75/Point()) : 0; 
    pos_info.tp = tp;
    pos_info.priceDifference = tradeTF[i].chicken.GetPriceDifference();
    pos_info.expiration = MathMax(DEPTH - tradeTF[i].chicken.GetIndexMax(), DEPTH - tradeTF[i].chicken.GetIndexMin());
    tradeTF[i].trailing.trailingStep = 5;
    if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko)
    {
     PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
     tradeTF[i].ctm.OpenUniquePosition(_Symbol, _Period, pos_info, tradeTF[i].trailing, spread);
    }
   }
 
   if(chickenSignal == NO_POSITION)
   {
    Print("Получили сигнал на  NO_POSITION");
    tradeTF[i].ctm.ClosePendingPosition(_Symbol);
   }
   else if(tradeTF[i].ctm.GetPositionCount() != 0)
   {
    ENUM_TM_POSITION_TYPE type = tradeTF[i].ctm.GetPositionType(_Symbol);
    if(type == OP_SELLSTOP && tradeTF[i].ctm.GetPositionStopLoss(_Symbol) < curAsk) 
    {
     slPrice = curAsk;
     tradeTF[i].ctm.ModifyPosition(_Symbol, slPrice, 0);  
    }
    if(type == OP_BUYSTOP  && tradeTF[i].ctm.GetPositionStopLoss(_Symbol) > curBid) 
    {
     slPrice = curBid;
     tradeTF[i].ctm.ModifyPosition(_Symbol, slPrice, 0); 
    }
    if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp >0 && pos_info.tp <= pos_info.sl*tp_ko))
    {
     tradeTF[i].ctm.ClosePendingPosition(_Symbol);
    } 
   }
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
//---
   
  }
//+------------------------------------------------------------------+
