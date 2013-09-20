//+------------------------------------------------------------------+
//|                                                     Piercing.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <TradeManager/TradeManager.mqh>
#include <StringUtilities.mqh>
#include <Lib CisNewBar.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
//input ulong _magic = 1122;
input double volume = 1;      // Объем торгов
input int historyDepth = 20;  // Глубина истории
input int step = 50;          // Шаг превышения экстремума в пунктах
input ENUM_TIMEFRAMES timeframe = PERIOD_M1; // Период
input bool trailing = false;  // Включить трейлинг  
input int minProfit = 250;    // Уровень минимальной прибыли для включения трейла в пунктах
input int trailingStop = 150; // 
input int trailingStep = 5;   // Шаг трейла

CTradeManager trade;

string symbol;              // переменная для хранения символа
datetime history_start;     // время запуска эксперта

MqlTick tick;
MqlTradeRequest request;
MqlTradeResult result;

int indexMax;
int indexMin;
double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;

double high_buf[], low_buf[];
double sl, tp;
bool first;

int OrdersPrev = 0;        // Хранит количество ордеров на момент предыдущего вызова OnTrade()
int PositionsPrev = 0;     // Хранит количество позиций на момент предыдущего вызова OnTrade()
ulong LastOrderTicket = 0; // Переменная хранит тикет последнего поступившего в обработку ордера

int _GetLastError=0;       // Содержит код ошибки
long state=0;              // Для хранения статуса ордера
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();     //--- запомним время запуска эксперта для получения торговой истории
   
   waitForSell = false;
   waitForBuy = false;
   first = true;
   //устанавливаем индексацию для массивов ХХХ_buf
   ArraySetAsSeries(low_buf, true);
   ArraySetAsSeries(high_buf, true);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   trade.OnTick();
   static CisNewBar isNewBar();
   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   
   //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
   errLow=CopyLow(symbol, timeframe, 0, historyDepth, low_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
   errHigh=CopyHigh(symbol, timeframe, 0, historyDepth, high_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
             
   if(errLow < 0 || errHigh < 0)
   {
    Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
    return;                                                                  //и выходим из функции
   }
    
   indexMax = ArrayMaximum(high_buf, 1); // максимум на сформированных барах
   indexMin = ArrayMinimum(low_buf, 1);  // минимум на сформированных барах
   globalMax = high_buf[indexMax];       // Значение максимума
   globalMin = low_buf[indexMin];        // Значение минимума
   
   /*
   if (isNewBar.isNewBar())
   {
    PrintFormat("%s indexMax = %d, globalMax = %.05f, indexMin = %d, globalMin = %.05f", 
                MakeFunctionPrefix(__FUNCTION__), indexMax, globalMax, indexMin, globalMin);
   }*/
   
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return;
   }
   
   if (indexMax > 3 && tick.bid > globalMax)
   {
    first = waitForBuy;
    waitForSell = true;
    waitForBuy = false;
    if (first)
    {
     first = !first;
     //Print("waitForSell");
    }
   }
   
   if (indexMin > 3 && tick.ask < globalMin)
   {
    first = waitForSell;
    waitForSell = false;
    waitForBuy = true;
    if (first)
    {
     first = !first;
     //Print("waitForSell");
    }
   }
   
   if (waitForSell && tick.ask < globalMax)
   {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         high_buf[ArrayMaximum(high_buf, 0)] - tick.ask) / _Point, SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    tp = 0; 
    
    PrintFormat("%s ask+stopLvl= %.05f, high= %.05f, sl=%f", MakeFunctionPrefix(__FUNCTION__), tick.ask + SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point, high_buf[ArrayMaximum(high_buf, 0)], sl);
    if (trade.OpenPosition(symbol, OP_SELL, volume, sl, tp, 0.0, 0.0, 0.0))
    {
     PrintFormat("Открыли позицию СЕЛЛ");
     waitForSell = false;
    }
   }
   
   if (waitForBuy && tick.bid > globalMin)
   {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         tick.bid - low_buf[ArrayMinimum(low_buf, 0)]) / _Point, SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    tp = 0; 
    PrintFormat("%s bid+stopLvl= %.05f, low= %.05f, sl=%f", MakeFunctionPrefix(__FUNCTION__), tick.bid - SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point, low_buf[ArrayMinimum(low_buf, 0)], sl);
    if (trade.OpenPosition(symbol, OP_BUY, volume, sl, tp, 0.0, 0.0, 0.0))
    {
     PrintFormat("Открыли позицию БАЙ");
     waitForBuy = false;
    }
   }
   /*
   if (trailing)
   {
    trade.DoTrailing();
   } */
   return;  
  }
//+------------------------------------------------------------------+

void OnTrade()
{/*
//---
 //Alert("Поступило событие Trade");
 HistorySelect(history_start,TimeCurrent()); 
 
 if (OrdersPrev < OrdersTotal())
 {
  OrderGetTicket(OrdersTotal()-1);// Выбираем последний ордер для работы
  _GetLastError=GetLastError();
  Print("Error #",_GetLastError);ResetLastError();
  //--
  if (OrderGetInteger(ORDER_STATE) == ORDER_STATE_STARTED)
  {
   Alert(OrderGetTicket(OrdersTotal()-1),"Поступил ордер в обработку");
   LastOrderTicket = OrderGetTicket(OrdersTotal()-1);    // Сохраняем тикет ордера для дальнейшей работы
  }
 }
 else if(OrdersPrev > OrdersTotal())
 {
  state = HistoryOrderGetInteger(LastOrderTicket, ORDER_STATE);

  // Если ордер не найден выдаем ошибку
  _GetLastError=GetLastError();
  if (_GetLastError != 0){Alert("Ошибка №",_GetLastError," Ордер не найден!");LastOrderTicket = 0;}
  Print("Error #",_GetLastError," state: ",state);ResetLastError();

  // Если ордер выполнен полностью
  if (state == ORDER_STATE_FILLED)
  {
   double sl = MathMax(globalMax, high_buf[0]);
   trade.PositionModify(symbol, sl, 0.0);
  }
 }*/
}
