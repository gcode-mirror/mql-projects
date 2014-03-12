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
input int    deltaPriceToEMA = 7;  // допустимая разница между ценой и EMA для пересечения
input int    deltaEMAtoEMA = 5;    // необходимая разница между EMA для пересечения
input int    waitAfterDiv = 4;     // ожидание сделки после расхождения (в барах)
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать
//------------------GLOBAL--------------------------------------
int    handleTrend;
int    handleEMA3Eld;
int    handleEMAfastJr;
int    handleEMAslowJr;
int    handleMACD;
double bufferTrend[];
double bufferEMA3Eld[];
double bufferEMAfastJr[];
double bufferEMAslowJr[];

datetime history_start;
ENUM_TM_POSITION_TYPE opBuy,       // переменные для определения типа сделки Order / Limit / Stop
                      opSell;      // переменные для определения типа сделки Order / Limit / Stop
int priceDifference = 10;          // разница цен для Limit / Stop ордеров

CisNewBar eldNewBar(eldTF);        // переменная для определения нового бара на eldTF
CTradeManager tradeManager;        // Мэнеджер ордеров

int OnInit()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();        // запомним время запуска эксперта для получения торговой истории
 handleTrend = iCustom(Symbol(), eldTF, "PriceBasedIndicator", historyDepth, bars);
 handleMACD = iMACD(Symbol(), eldTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleEMA3Eld = iMA(Symbol(), eldTF, 3, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA3Eld == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE. Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)                   // выбор типа сделок Order / Limit / Stop
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
  
 ArraySetAsSeries(    bufferTrend, true);
 ArraySetAsSeries(  bufferEMA3Eld, true);
 ArraySetAsSeries(bufferEMAfastJr, true);
 ArraySetAsSeries(bufferEMAslowJr, true);
 ArrayResize(    bufferTrend, 1);
 ArrayResize(  bufferEMA3Eld, 1);
 ArrayResize(bufferEMAfastJr, 1);
 ArrayResize(bufferEMAslowJr, 1);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleMACD); 
 IndicatorRelease(handleEMA3Eld);
 IndicatorRelease(handleEMAfastJr);
 IndicatorRelease(handleEMAslowJr);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA3Eld);
 ArrayFree(bufferEMAfastJr);
 ArrayFree(bufferEMAslowJr);
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
 
 int copiedTrend     = -1;
 int copiedEMA3Eld   = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1; 
   
 if (eldNewBar.isNewBar() > 0)                       //на каждом новом баре старшего TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend     < 0
                                       && copiedEMA3Eld   < 0
                                       && copiedEMAfastJr < 0
                                       && copiedEMAslowJr < 0; attempts++) //Копируем данные индикаторов
  {
   copiedTrend     = CopyBuffer(    handleTrend, 4, 1, 1,     bufferTrend);
   copiedEMA3Eld   = CopyBuffer(  handleEMA3Eld, 0, 1, 1,   bufferEMA3Eld);
   copiedEMAfastJr = CopyBuffer(handleEMAfastJr, 0, 1, 1, bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer(handleEMAslowJr, 0, 1, 1, bufferEMAslowJr);
  }
  if (copiedTrend != 1 || copiedEMA3Eld != 1 || copiedEMAfastJr != 1 || copiedEMAslowJr != 1)   
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
 
  isProfit = tradeManager.isMinProfit(Symbol());     // проверяем не достигла ли позиция на данном символе минимального профита
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //если не достигли minProfit за определенное время
   log_file.Write(LOG_DEBUG, StringFormat("%s Истекло время ожидания минпрофита.Закрываем позицию.", MakeFunctionPrefix(__FUNCTION__))); 
   tradeManager.ClosePosition(Symbol()); 
  }

  if (useJrEMAExit && isProfit)  //выход по младшим EMA при достижении MinProfit
  {
   switch(tradeManager.GetPositionType(Symbol()))
   {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
    {
     if (GreatDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0] + deltaEMAtoEMA*point))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Позиция достигла минимального профита. Выход по младшим EMA.", MakeFunctionPrefix(__FUNCTION__)));
      tradeManager.ClosePosition(Symbol());
     }
     break;
    }
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
    {
     if (LessDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0] - deltaEMAtoEMA*point))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Позиция достигла минимального профита. Выход по младшим EMA.", MakeFunctionPrefix(__FUNCTION__)));
      tradeManager.ClosePosition(Symbol());
     }
     break;
    }
    case OP_UNKNOWN:
    break;
   }
  }//end useJrEMAExit
   
  wait++; 
  if (order_direction != 0)   // если есть сигнал о направлении ордера 
  {
   if (wait > waitAfterDiv)   // проверяем на допустимое время ожидания после расхождения
   {
    wait = 0;                 // если не дождались обнуляем счетчик ожидания и направления сделки
    order_direction = 0;
   }
  }
  //order_direction = divergenceMACD(handleMACD, Symbol(), eldTF); 
 } // end newBar 
  order_direction = divergenceMACD(handleMACD, Symbol(), eldTF, 0, null); 
 if (bufferTrend[0] == 7)               //Если направление тренда FLAT  
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ФЛЭТ", MakeFunctionPrefix(__FUNCTION__)));   
  if (order_direction == 1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD 1", MakeFunctionPrefix(__FUNCTION__)));
   if(LessDoubles(bid, bufferEMA3Eld[0] + deltaPriceToEMA*point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
    tradeManager.OpenUniquePosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
    wait = 0;
   }
  }
  if (order_direction == -1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD -1", MakeFunctionPrefix(__FUNCTION__)));
   if(GreatDoubles(ask, bufferEMA3Eld[0] - deltaPriceToEMA*point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
    tradeManager.OpenUniquePosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
    wait = 0;
   }
  }
 } // end trend == FLAT
 
 if (useTrailing)
 {
  //tradeManager.DoTrailing();
 }
} // close OnTick

void OnTrade()
{
 tradeManager.OnTrade(history_start);
}