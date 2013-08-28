//+------------------------------------------------------------------+
//|                                         desepticonFlatDivSto.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#include <Lib CisNewBar.mqh>
#include <divergenceStochastic.mqh>
#include <TradeManager/TradeManager.mqh>

input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

//параметры Stochastic 
input int    kPeriod = 5;          // К-период стохастика
input int    dPeriod = 3;          // D-период стохастика
input int    slow  = 3;            // Сглаживание стохастика. Возможные значения от 1 до 3.
input int    top_level = 80;       // Top-level стохастка
input int    bottom_level = 20;    // Bottom-level стохастика

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
input int    deltaPriceToEMA = 7;  // допустимая разница между ценой и EMA для пересечения
input int    periodEMA = 3;        // период EMA
input int    waitAfterDiv = 4;     // ожидание сделки после расхождения (в барах)
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать

int    handleTrend;
int    handleEMA;
int    handleSTO;
double bufferTrend[];
double bufferEMA[];

datetime history_start;
ENUM_TM_POSITION_TYPE opBuy,       // переменные для определения типа сделки Order / Limit / Stop
                      opSell;      // переменные для определения типа сделки Order / Limit / Stop 
int priceDifference = 10;          // разница цен для Limit / Stop ордеров

CisNewBar eldNewBar(eldTF);        // переменная для определения нового бара на eldTF
CTradeManager tradeManager;        // Мэнеджер ордеров

int OnInit()
{
 tradeManager.Initialization();
 log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();     // запомним время запуска эксперта для получения торговой истории
 handleTrend =  iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 handleSTO = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE); 
 handleEMA = iMA(NULL, eldTF, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE. Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)                        // выбор типа сделок Order / Limit / Stop
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
 ArraySetAsSeries(bufferEMA, true);;
 ArrayResize(bufferTrend, 1);
 ArrayResize(bufferEMA, 2);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 tradeManager.Deinitialization();
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleSTO); 
 IndicatorRelease(handleEMA);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA);
 log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));
}

void OnTick()
{
 static bool isProfit = false;
 static int  wait = 0;
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
 double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
 
 int copiedTrend = -1;
 int copiedEMA   = -1;
 
 //TO DO: выход по EMA
   
 if (eldNewBar.isNewBar() > 0)                       //на каждом новом баре старшего TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend < 0
                                       && copiedEMA   < 0; attempts++) //Копируем данные индикаторов
  {
   copiedTrend = CopyBuffer( handleTrend, 4, 1, 1,  bufferTrend) < 0;
   copiedEMA   = CopyBuffer(   handleEMA, 0, 0, 2,    bufferEMA) < 0;
  }
  if (copiedTrend != 1 || copiedEMA != 2)   
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
  
  isProfit = tradeManager.isMinProfit(Symbol());      // проверяем не достигла ли позиция на данном символе минимального профита
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //если не достигли minProfit за данное время
   log_file.Write(LOG_DEBUG, StringFormat("%s Истекло время ожидания минпрофита.Закрываем позицию.", MakeFunctionPrefix(__FUNCTION__))); 
   //close position 
  }
    
  wait++; 
  if (order_direction != 0)   // если есть сигнал о направлении ордера 
  {
   if (wait > waitAfterDiv)   // проверяем на допустимое время ожидания после расхождения
   {
    wait = 0;                 // если не дождались обнуляем счетчик ожидания и направления сделки
    order_direction = 0;
   }
  }
  
  order_direction = divergenceSTOC(handleSTO, Symbol(), eldTF, top_level, bottom_level);
  
  if (bufferTrend[0] == 7)               //Если направление тренда FLAT  
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ФЛЭТ", MakeFunctionPrefix(__FUNCTION__)));   
   if (order_direction == 1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD 1", MakeFunctionPrefix(__FUNCTION__)));
    if(LessDoubles(bid, bufferEMA[0] + deltaPriceToEMA*point))
    {
     tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
     wait = 0;
    }
   }
   if (order_direction == -1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD -1", MakeFunctionPrefix(__FUNCTION__)));
    if(GreatDoubles(ask, bufferEMA[0] - deltaPriceToEMA*point))
    {
     tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
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