//+------------------------------------------------------------------+
//|                                         desepticonFlatDivSto.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
#include <divergenceMACD.mqh>

input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;
//параметры MACD
input int fast_EMA_period = 12;    //быстрый период EMA для MACD
input int slow_EMA_period = 26;    //медленный период EMA для MACD
input int signal_period = 9;       //период сигнальной линии для MACD

//параметры сделок  
input double orderVolume = 0.1;         // Объём сделки
input int    slOrder = 100;             // Stop Loss
input int    tpOrder = 100;             // Take Profit
input int    trStop = 100;              // Trailing Stop
input int    trStep = 100;              // Trailing Step
input int    minProfit = 250;           // Minimal Profit 
input bool   useLimitOrders = false;    // Использовать Limit ордера
input int    limitPriceDifference = 50; // Разнциа для Limit ордеров
input bool   useStopOrders = false;     // Использовать Stop ордера
input int    stopPriceDifference = 50;  // Разнциа для Stop ордеров

input bool   useTrailing = false;  // Использовать трейлинг
input bool   useJrEMAExit = false; // будем ли выходить по ЕМА
input int    posLifeTime = 10;     // время ожидания сделки в барах
input int    deltaPriceToEMA = 7;  // разница между ценой и EMA
input int    periodEMA = 3;        // период усреднения EMA
input int    waitAfterDiv = 4;     // ожидание сделки после расхождения (в барах)
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать

int    handleTrend;
int    handleEMA;
int    handleMACD;
double bufferTrend[];
double bufferEMA[];

datetime history_start;
ENUM_TM_POSITION_TYPE opBuy, opSell;
int priceDifference = 10;    // Price Difference

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;

int OnInit()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
 handleTrend =  iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 handleMACD = iMACD(NULL, eldTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleEMA = iMA(NULL, eldTF, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend || handleEMA). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)
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
 ArraySetAsSeries(bufferEMA, true);
 ArrayResize(bufferTrend, 1, 3);
 ArrayResize(bufferEMA, 2, 6);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleMACD); 
 IndicatorRelease(handleEMA);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA);
 log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));
}

void OnTick()
{
 int totalPositions = PositionsTotal();
 int positionType = -1;
 static bool isProfit = false;
 static int  wait = 0;
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 isProfit = tradeManager.isMinProfit(_Symbol);
 //TO DO: выход по EMA
   
 if (eldNewBar.isNewBar() > 0)   //на каждом новом баре старшего TF
 {
  if (!isProfit && positionType > -1 && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //если не достигли minProfit за данное время
     //close position 
  }
  
  if ((CopyBuffer( handleTrend, 4, 1, 1,  bufferTrend) < 0) ||
      (CopyBuffer(   handleEMA, 0, 0, 2,    bufferEMA) < 0) )   //Копируем данные индикаторов
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера. (divStoBuffer || bufferTrend || bufferEMA).Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
  
  wait++; 
  if (order_direction != 0)
  {
   if (wait > waitAfterDiv)
   {
    wait = 0;
    order_direction = 0;
   }
  }
  
  order_direction = divergenceMACD(handleMACD, Symbol(), eldTF); 
  
  if (bufferTrend[0] == 7)               //Если направление тренда FLAT  
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ФЛЭТ", MakeFunctionPrefix(__FUNCTION__)));   
   if (order_direction == 1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD 1", MakeFunctionPrefix(__FUNCTION__)));
    if(bid < bufferEMA[0] + deltaPriceToEMA*point)
    {
     tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     wait = 0;
    }
   }
   if (order_direction == -1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD -1", MakeFunctionPrefix(__FUNCTION__)));
    if(ask > bufferEMA[0] - deltaPriceToEMA*point)
    {
     tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     wait = 0;
    }
   }
  } // close trend == FLAT
 } // close newBar
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
} // close OnTick

void OnTrade()
{
 tradeManager.OnTrade(history_start);
}