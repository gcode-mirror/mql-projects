//+------------------------------------------------------------------+
//|                                                      STRUCTS.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| библиотека структур данных для получения сигналов                |
//+------------------------------------------------------------------+

// структура EMA

// структура сделок
struct DEAL_PARAMS
 {
  double orderVolume = 0.1;         // Объём сделки
  int    slOrder = 100;             // Stop Loss
  int    tpOrder = 100;             // Take Profit
  int    trStop = 100;              // Trailing Stop
  int    trStep = 100;              // Trailing Step
  int    minProfit = 250;           // Minimal Profit 
  bool   useLimitOrders = false;    // Использовать Limit ордера
  int    limitPriceDifference = 50; // Разнциа для Limit ордеров
  bool   useStopOrders = false;     // Использовать Stop ордера
  int    stopPriceDifference = 50;  // Разнциа для Stop ордеров 
 };