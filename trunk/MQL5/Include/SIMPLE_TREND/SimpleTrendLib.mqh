//+------------------------------------------------------------------+
//|                                               SimpleTrendLib.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Библиотека для хранения данных робота Simple Trend               |
//+------------------------------------------------------------------+

// перечисления и константы
enum ENUM_TENDENTION
 {
  TENDENTION_NO = 0,     // нет тенденции
  TENDENTION_UP,         // тенденция вверх
  TENDENTION_DOWN        // тенденция вниз
 };
// константы сигналов
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0