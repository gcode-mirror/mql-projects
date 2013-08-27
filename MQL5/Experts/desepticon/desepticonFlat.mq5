//+------------------------------------------------------------------+
//|                                               desepticonFlat.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>

//------------------INPUT---------------------------------------
//параметры desepticonFlat
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

//параметры для EMA
input int    periodEMAfastJr = 15;
input int    periodEMAslowJr = 9;

//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать
//------------------GLOBAL--------------------------------------
int handleTrend;            // хэндл PriceBased indicator
int handleEMA3;             // хэндл EMA 3 дневного TF
int handleEMAfastEld;       // хэндл EMA fast старшего таймфрейма
int handleEMAfastJr;        // хэндл EMA fast младшего таймфрейма
int handleSTOCEld;          // хэндл Stochastic старшего таймфрейма
double bufferTrend[];       // буфер для PriceBased indicator  
double bufferEldPrice[];    // буфер для цены старшего ТФ
double bufferEldTFPrice[];  // буфер для цены на старшем таймфрейме
double bufferEMA3[];        // буфер для EMA 3
double bufferEMAfastEld[];  // буфер для EMA fast старшего таймфрейма 
double bufferEMAfastJr[];   // буфер для EMA fast младшего таймфрейма
double bufferEMAslowJr[];   // буфер для EMA slow младшего таймфрейма


ENUM_TM_POSITION_TYPE opBuy, 
                      opSell;
int priceDifference = 10;    // Price Difference

CisNewBar eldNewBar(eldTF);        // переменная для определения нового бара на eldTF
CTradeManager tradeManager;        // Мэнеджер ордеров 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 handleTrend = iCustom(Symbol(), Period(), "PriceBasedIndicator", historyDepth, bars);
 handleEMAfastJr = iMA(Symbol(), jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr = iMA(Symbol(), jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (handleTrend == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE || handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)                           // выбор типа сделок Order / Limit / Stop
 {
  opBuy = OP_BUYLIMIT;
  opSell = OP_SELLLIMIT;
  priceDifference = limitPriceDifference;
 }
 else if (useStopOrders)
      {
       opBuy = OP_BUYSTOP;
       opSell = OP_SELLSTOP;
       priceDifference = stopPriceDifference;
      }
      else
      {
       opBuy = OP_BUY;
       opSell = OP_SELL;
       priceDifference = 0;
      }
  
 ArraySetAsSeries(bufferTrend, true);
 ArrayResize(bufferTrend, 1, 3);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend);
 ArrayFree(bufferTrend);
 log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__))); 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

}
//+------------------------------------------------------------------+
