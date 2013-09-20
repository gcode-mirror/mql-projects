//+------------------------------------------------------------------+
//|                                               desepticonCorr.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
#include <divergenceStochastic.mqh>
#include <divergenceMACD.mqh>
//------------------INPUT---------------------------------------
//параметры desepticonCorrection
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

//параметры для EMA
input int    periodEMAfastJr = 15;
input int    periodEMAslowJr = 9;
//параметры для MACD
input int    fast_EMA_period = 12;    //быстрый период EMA для MACD
input int    slow_EMA_period = 26;    //медленный период EMA для MACD
input int    signal_period = 9;       //период сигнальной линии для MACD
//параметры для Stochastic
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
input bool   useTrailing = false;       // Использовать трейлинг
input bool   useJrEMAExit = false;      // будем ли выходить по ЕМА
input int    posLifeTime = 10;          // время ожидания сделки в барах
input int    deltaEMAtoEMA = 5;         // необходимая разница для разворота EMA
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать

//------------------GLOBAL--------------------------------------
int handleTrend;            // хэндл PriceBased indicator
int handleMACDEld;          // хэндл MACD на старшем таймфрейме
int handleSTOCEld;          // хэндл Stochastic на старшем таймфрейме
int handleMACDJr;           // хэндл MACD на младшем таймфрейме
int handleSTOCJr;           // хэндл Stochastic на младшем таймфрейме
int handleEMAfastJr;        // хэндл быстрой EMA на младшем таймфрейме
int handleEMAslowJr;        // хэндл медленной EMA на младшем таймфрейме
double bufferTrend[];       // буфер для PriceBased indicator
double bufferSTOCEld[];     // буфер для Stohastic старшего таймфрейма
double bufferEMAfastJr[];   // буфер быстрой EMA на младшем таймфрейме
double bufferEMAslowJr[];   // буфер медленной EMA на младшем таймфрейме 

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
 tradeManager.Initialization();
 log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 handleTrend = iCustom(Symbol(), Period(), "PriceBasedIndicator", historyDepth, bars);
 handleMACDEld = iMACD(Symbol(), eldTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleMACDJr  = iMACD(Symbol(),  jrTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleSTOCEld = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
 handleSTOCJr  = iStochastic(NULL,  jrTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
 handleEMAfastJr = iMA(Symbol(), jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr = iMA(Symbol(), jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (    handleTrend == INVALID_HANDLE || handleMACDEld == INVALID_HANDLE ||    handleMACDJr == INVALID_HANDLE ||
       handleSTOCEld == INVALID_HANDLE ||  handleSTOCJr == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE ||
     handleEMAslowJr == INVALID_HANDLE )
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
  
 ArraySetAsSeries(    bufferTrend, true);
 ArraySetAsSeries(  bufferSTOCEld, true);
 ArraySetAsSeries(bufferEMAfastJr, true);
 ArraySetAsSeries(bufferEMAslowJr, true);
 ArrayResize(    bufferTrend, 1);
 ArrayResize(  bufferSTOCEld, 1);
 ArrayResize(bufferEMAfastJr, 2);
 ArrayResize(bufferEMAslowJr, 2);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 tradeManager.Deinitialization();
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleMACDEld);
 IndicatorRelease(handleMACDJr);
 IndicatorRelease(handleSTOCEld);
 IndicatorRelease(handleSTOCJr);
 IndicatorRelease(handleEMAfastJr);
 IndicatorRelease(handleEMAslowJr); 
 ArrayFree(bufferTrend);
 ArrayFree(bufferSTOCEld);
 ArrayFree(bufferEMAfastJr);
 ArrayFree(bufferEMAslowJr);
 log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 static bool isProfit = false;
 static int  wait = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 int copiedTrend = -1;
 
 if (eldNewBar.isNewBar() > 0)                          //на каждом новом баре старшего TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend < 0; attempts++) //Копируем данные индикаторов
  {
   copiedTrend = CopyBuffer(handleTrend, 4, 1, 1, bufferTrend);
  }
  
  if (copiedTrend != 1)   //Копируем данные индикаторов
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
  
  isProfit = tradeManager.isMinProfit(_Symbol);         // проверяем не достигла ли позиция на данном символе минимального профита
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //если не достигли minProfit за данное время
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
  } //end useJrEMAExit 
 } //end isNewBar  
 
 if (bufferTrend[0] == 5 || bufferTrend[0] == 6)   // направление тренда CORRECTION_UP или CORRECTION_DOWN
 {
  if (ConditionForBuy() > ConditionForSell())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
   tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
  }
  if (ConditionForSell() > ConditionForBuy())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
   tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
  }
 }

 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }  
}
//+------------------------------------------------------------------+
int ConditionForBuy()
{
 if(divergenceMACD(handleMACDEld, Symbol(), eldTF) == 1) return(100);
 if(divergenceMACD( handleMACDJr, Symbol(),  jrTF) == 1) return(50);
 if(divergenceSTOC(handleSTOCEld, Symbol(), eldTF, top_level, bottom_level) == 1) return(100);
 if(divergenceSTOC( handleSTOCJr, Symbol(),  jrTF, top_level, bottom_level) == 1) return(50);
 
 int copiedSTOC = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1;
 for (int attempts = 0; attempts < 25 && copiedSTOC      < 0
                                      && copiedEMAfastJr < 0
                                      && copiedEMAslowJr < 0; attempts++)
 {
  copiedSTOC = CopyBuffer(handleSTOCEld, 0, 1, 1, bufferSTOCEld);
  copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
  copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
 }
 if (copiedSTOC != 1 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(0);
 } 
 if(GreatDoubles(bufferEMAslowJr[1], bufferEMAfastJr[1]) && GreatDoubles (bufferEMAfastJr[0], bufferEMAslowJr[0]) 
    && bufferSTOCEld[0] < bottom_level) //стохастик внизу; пересечение младших EMA снизу вверх
    return(100); 
 return(0);
}
///
//
///
int ConditionForSell()
{
 if(divergenceMACD(handleMACDEld, Symbol(), eldTF) == -1) return(100);
 if(divergenceMACD( handleMACDJr, Symbol(),  jrTF) == -1) return(50);
 if(divergenceSTOC(handleSTOCEld, Symbol(), eldTF, top_level, bottom_level) == -1) return(100);
 if(divergenceSTOC( handleSTOCJr, Symbol(),  jrTF, top_level, bottom_level) == -1) return(50);
 
 int copiedSTOC = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1;
 for (int attempts = 0; attempts < 25 && copiedSTOC      < 0
                                      && copiedEMAfastJr < 0
                                      && copiedEMAslowJr < 0; attempts++)
 {
  copiedSTOC = CopyBuffer(handleSTOCEld, 0, 1, 1, bufferSTOCEld);
  copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
  copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
 }
 if (copiedSTOC != 1 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(0);
 } 
 if(GreatDoubles(bufferEMAfastJr[1], bufferEMAslowJr[1]) && GreatDoubles (bufferEMAslowJr[0], bufferEMAfastJr[0]) 
    && bufferSTOCEld[0] > top_level) //стохастик вверху; пересечение младших EMA сверху вниз
    return(100); 
 return(0);
}