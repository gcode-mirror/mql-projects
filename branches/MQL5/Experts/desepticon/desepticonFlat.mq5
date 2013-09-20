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
input bool   useTrailing = false;       // Использовать трейлинг
input bool   useJrEMAExit = false;      // будем ли выходить по ЕМА
input int    posLifeTime = 10;          // время ожидания сделки в барах
input int    waitAfterBreakdown = 4;    // ожидание сделки после пробоя (в барах)
input int    deltaPriceToEMA = 7;       // допустимая разница между ценой и EMA для пересечения
input int    deltaEMAtoEMA = 5;         // необходимая разница для разворота EMA
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать
//------------------GLOBAL--------------------------------------
int handleTrend;            // хэндл PriceBased indicator
int handleEMA3Eld;             // хэндл EMA 3 дневного TF
int handleEMAfastJr;        // хэндл EMA fast старшего таймфрейма
int handleEMAslowJr;        // хэндл EMA fast младшего таймфрейма
int handleSTOCEld;          // хэндл Stochastic старшего таймфрейма
double bufferTrend[];       // буфер для PriceBased indicator  
double bufferEMA3Eld[];     // буфер для EMA 3 старшего таймфрейма
double bufferEMAfastJr[];   // буфер для EMA fast младшего таймфрейма
double bufferEMAslowJr[];   // буфер для EMA slow младшего таймфрейма
double bufferSTOCEld[];     // буфер для Stochastic старшего таймфрейма

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
 handleSTOCEld = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
 handleEMAfastJr = iMA(Symbol(),  jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr = iMA(Symbol(),  jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMA3Eld   = iMA(Symbol(), eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

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
  
 ArraySetAsSeries(    bufferTrend, true);
 ArraySetAsSeries(  bufferEMA3Eld, true);
 ArraySetAsSeries(bufferEMAfastJr, true);
 ArraySetAsSeries(bufferEMAslowJr, true);
 ArraySetAsSeries(  bufferSTOCEld, true);
 ArrayResize(    bufferTrend, 1);
 ArrayResize(  bufferEMA3Eld, 1);
 ArrayResize(bufferEMAfastJr, 2);
 ArrayResize(bufferEMAslowJr, 2);
 ArrayResize(  bufferSTOCEld, 1);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 tradeManager.Deinitialization();
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleEMA3Eld);
 IndicatorRelease(handleEMAfastJr);
 IndicatorRelease(handleEMAslowJr);
 IndicatorRelease(handleSTOCEld);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA3Eld);
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
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 int copiedTrend     = -1;
 int copiedSTOCEld   = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1;
 int copiedEMA3Eld   = -1;
 
 if (eldNewBar.isNewBar() > 0)                          //на каждом новом баре старшего TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend     < 0
                                       && copiedSTOCEld   < 0
                                       && copiedEMAfastJr < 0
                                       && copiedEMAslowJr < 0
                                       && copiedEMA3Eld   < 0; attempts++) //Копируем данные индикаторов
  {
   copiedTrend =     CopyBuffer(    handleTrend, 4, 1, 1, bufferTrend);
   copiedSTOCEld =   CopyBuffer(  handleSTOCEld, 0, 1, 2, bufferSTOCEld);
   copiedEMAfastJr = CopyBuffer(handleEMAfastJr, 0, 1, 2, bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer(handleEMAslowJr, 0, 1, 2, bufferEMAslowJr);
   copiedEMA3Eld =   CopyBuffer(  handleEMA3Eld, 0, 0, 1, bufferEMA3Eld);
  }
  
  if (    copiedTrend != 1 ||   copiedSTOCEld != 2 ||  copiedEMA3Eld != 1 ||
      copiedEMAfastJr != 2 || copiedEMAslowJr != 2 )   //Копируем данные индикаторов
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
  }//end useJrEMAExit
  
  wait++; 
  if (order_direction != 0)   // если есть сигнал о направлении ордера 
  {
   if (wait > waitAfterBreakdown)   // проверяем на допустимое время ожидания после расхождения
   {
    wait = 0;                 // если не дождались обнуляем счетчик ожидания и направления сделки
    order_direction = 0;
   }
  }
 }//end isNewBar
 
 if(bufferTrend[0] == 7)   //Если направление тренда FLAT
 {
  if(bufferSTOCEld[1] > top_level && bufferSTOCEld[0] < top_level)
  {
   if(GreatDoubles(bufferEMAfastJr[1], bufferEMAslowJr[1]) && GreatDoubles(bufferEMAslowJr[0], bufferEMAfastJr[0]))
   {
    if(GreatDoubles(ask, bufferEMA3Eld[0] - deltaPriceToEMA*point))
    {
     //продажа
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
     tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
    }
   }
  }
  if(bufferSTOCEld[1] < bottom_level && bufferSTOCEld[0] > bottom_level)
  {
   if(GreatDoubles(bufferEMAslowJr[1], bufferEMAfastJr[1]) && GreatDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0]))
   {
    if(LessDoubles(bid, bufferEMA3Eld[0] + deltaPriceToEMA*point))
    {
     //покупка
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
     tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
    }
   }
  }
 }//end FLAT

 
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
}
//+------------------------------------------------------------------+
