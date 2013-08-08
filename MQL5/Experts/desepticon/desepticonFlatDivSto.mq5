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

int    handleTrend;
int    handleEMA;
double bufferTrend[];
double bufferEMA[];

datetime history_start;

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;

int OnInit()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Иниализация.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
 handleTrend =  iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 handleEMA = iMA(NULL, 0, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend || handleEMA). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
  
 ArraySetAsSeries(bufferTrend, true);
 ArraySetAsSeries(bufferEMA, true);;
 ArrayResize(bufferTrend, 1, 3);
 ArrayResize(bufferEMA, 2, 6);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend); 
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
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 for (int i = 0; i < totalPositions; i++)    //цикл по всем позициям
 {
  if (PositionGetSymbol(i) == _Symbol)       //если есть позиция на текущем символе
  {
   positionType = (int)PositionGetInteger(POSITION_TYPE);
   switch (positionType)         //проверяем на достижимость minProfit и выходим по младшим EMA
   {
    case POSITION_TYPE_BUY:
    {
     if (!isProfit && ask - PositionGetDouble(POSITION_PRICE_OPEN) >= minProfit*point)
     {
      isProfit = true;
     }
     if (useJrEMAExit)
     {
      // выход по младшему ЕМА
     }
     break;
    }
    case POSITION_TYPE_SELL:
    {
     if (!isProfit && PositionGetDouble(POSITION_PRICE_OPEN) - bid >= minProfit*point)
     {
      isProfit = true;
     }
     if (useJrEMAExit)
     {
      // выход по младшему ЕМА
     }
     break;
    }    
   }
  }
 }
   
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
   
  if (bufferTrend[0] == 7)               //Если направление тренда FLAT  
  {   
   for (int i = 0; i < waitAfterDiv; i++)
   {
    if (1) //проверка на рассхождение
    {

    }     
    if (1) //проверка на схождение
    {

    }
   }
  } // close bufferTrend[0] == 7
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

/*
     if (ask < (bufferEMA[0] - deltaPriceToEMA*point))
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
     
          if (bid > (bufferEMA[0] + deltaPriceToEMA*point))
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

*/