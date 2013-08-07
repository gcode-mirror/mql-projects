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

input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

input ENUM_MA_METHOD methodMASto = MODE_SMA; // Метод сглаживания

//параметры divSto indicator
input int    kPeriod = 5;          // К-период
input int    dPeriod = 3;          // D-период
input int    slow  = 3;            // Сглаживание графика. Возможные значения от 1 до 3.
input int    deep = 12;            // обрабатываемый период, количество баров.
input int    delta = 2;            // разнца в барах между правыми экстремумами цены и стохастика
input double highLine = 80;        // верхняя значимая граница стохастика
input double lowLine = 20;         // нижняя значимая граница стохастика
input int    firstBarsCount = 3;   // количество первых баров на которых должен находиться максимум или минимум цены
//параметры сделок
input double orderVolume = 0.1;    // Объём сделки
input double slOrder = 100;        // Stop Loss
input double tpOrder = 100;        // Take Profit
input int    trStop = 100;         // Trailing Stop
input int    trStep = 100;         // Trailing Step
input int    prDifference = 10;    // Price Difference

input bool   useTrailing = false;
input bool   useJrEMAExit = false; // будем ли выходить по ЕМА
input int    minProfit = 100;      // минимальная прибыль
input int    posLifeTime = 10;     // время ожидания сделки в барах
input int    deltaPriceToEMA = 7;  // разница между ценой и EMA
input int    periodEMA = 3;        // период усреднения EMA
input int    waitAfterDiv = 2;     // ожидание сделки после расхождения (в барах)
//параметры PriceBased indicator
input int    historyDepth = 40;    // глубина истории для расчета
input int    bars=30;              // сколько свечей показывать

int    trendHandle;
int    divStoHandle;
int    emaHandle;

datetime history_start;

double divStoBuffer[];             // массив основной линии стохастика.
double trendBuffer[];
double emaBuffer[];


bool   isProfit = false;           // флаг совершения сделки с минимальной прибылью

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;

int OnInit()
{
 trendHandle = iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 divStoHandle = iCustom(NULL, 0, "div", methodMASto, kPeriod, dPeriod, slow, deep, delta, highLine, lowLine, firstBarsCount);
 emaHandle = iMA(NULL, 0, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (trendHandle == INVALID_HANDLE || divStoHandle == INVALID_HANDLE || emaHandle == INVALID_HANDLE)
 {
  Print("Error: INVALID_HANDLE (trendHandle || divStoHandle || emaHandle)", GetLastError());
  return(INIT_FAILED);
 }
  
 ArraySetAsSeries(divStoBuffer, true);
 ArraySetAsSeries(trendBuffer, true);
 ArraySetAsSeries(emaBuffer, true);
 ArrayResize(divStoBuffer, waitAfterDiv, waitAfterDiv*3);
 ArrayResize(trendBuffer, 1, 3);
 ArrayResize(emaBuffer, 2, 6);
  
 history_start = TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(trendHandle); 
 IndicatorRelease(divStoHandle);
 IndicatorRelease(emaHandle);
 ArrayFree(divStoBuffer);
 ArrayFree(trendBuffer);
 ArrayFree(emaBuffer);
 Print("Хэндлы (указатели) и массивы очищены");
}

void OnTick()
{
 int totalPositions = PositionsTotal();
 int positionType = -1;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 for (int i = 0; i < totalPositions; i++)
 {
  if (PositionGetSymbol(i) == _Symbol)
  {
   positionType = (int)PositionGetInteger(POSITION_TYPE);
   if (positionType == POSITION_TYPE_BUY)
   {
    if (!isProfit && ask - PositionGetDouble(POSITION_PRICE_OPEN) >= minProfit*point)
    {
     isProfit = true;
    }
    if (useJrEMAExit)
    {
     // выход по младшему ЕМА
    }
   }
   if (positionType == POSITION_TYPE_SELL)
   {
    if (!isProfit && PositionGetDouble(POSITION_PRICE_OPEN) - bid >= minProfit*point)
    {
     isProfit = true;
    }
    if (useJrEMAExit)
    {
     // выход по младшему ЕМА
    }
   }
  }
 }
   
 if (eldNewBar.isNewBar() > 0)
 {
  if (!isProfit)
  {
   if ((positionType > -1) && (TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF)))
   {
    //close position
   }
  }
  
  if ((CopyBuffer(divStoHandle, 1, 1, waitAfterDiv, divStoBuffer) < 0))
  {
   log_file.Write(LOG_DEBUG, "Ошибка заполнения массива divStoBuffer");
   return;
  }
  if (CopyBuffer(trendHandle, 4, 1, 1, trendBuffer) < 0)
  {
   log_file.Write(LOG_DEBUG, "Ошибка заполнения массива trendHandle");
   return;
  }
  if (CopyBuffer(emaHandle, 0, 0, 2, emaBuffer) < 0)
  {
   log_file.Write(LOG_DEBUG, "Ошибка заполнения массива emaHandle");
   return;
  }
   
  if (trendBuffer[0] == 7)
  {   
   for (int i = 0; i < waitAfterDiv; i++)
   {
    if (divStoBuffer[i] == 1)
    {
     if (ask < (emaBuffer[0] - deltaPriceToEMA*point))
     {
      log_file.Write(LOG_DEBUG, "Вошли в покупку");
      if (tradeManager.OpenPosition(_Symbol, OP_BUY, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, prDifference))
      {
       isProfit = false;
      }
      else
      {
       log_file.Write(LOG_DEBUG, "Открыть позицию не удалось");
      }
     }
    }     
    if (divStoBuffer[i] == 0)
    {
     if (bid > (emaBuffer[0] + deltaPriceToEMA*point))
     {
      log_file.Write(LOG_DEBUG, "Вошли в продажу");
      if (tradeManager.OpenPosition(_Symbol, OP_SELL, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, prDifference))
      {
       isProfit = false;
      }
      else
      {
       log_file.Write(LOG_DEBUG, "Открыть позицию не удалось");
      }
     }
    }
   }
  } // close trendBuffer[0] == 7
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