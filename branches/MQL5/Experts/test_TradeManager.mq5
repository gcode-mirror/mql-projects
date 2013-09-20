//+------------------------------------------------------------------+
//|                                            test_TradeManager.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh> //подключаем библиотеку для совершения торговых операций
#include <Trade\PositionInfo.mqh> //подключаем библиотеку для получения информации о позициях
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 1122;
input int SL = 150;
input int TP = 500;
input double _lot = 1;
input int historyDepth = 40;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;

string my_symbol;                               //переменная для хранения символа
ENUM_TIMEFRAMES my_timeframe;                   //переменная для хранения таймфрейма
datetime history_start;

bool first, second;

CTradeManager order(_magic);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   first = true;
   second = false;
   
   my_symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if (first)
   {
    order.OpenPosition(my_symbol, POSITION_TYPE_BUY, _lot, SL, TP, minProfit, trailingStop, trailingStep);
    first = false;
    second = true;
    Sleep(50000);
   }
   if (second)
   {
    order.OpenPosition(my_symbol, POSITION_TYPE_SELL, _lot, SL, TP, minProfit, trailingStop, trailingStep);
    second = false;
   }
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   order.OnTrade(history_start);
  }
