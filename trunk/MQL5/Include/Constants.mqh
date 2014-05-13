//+------------------------------------------------------------------+
//|                                                    Constants.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Файл с константами и прочими значениями                          |
//+------------------------------------------------------------------+

// универсальные значения 

// константы сигналов
#define BUY   1    
#define SELL -1

// размеры лота для разных валют
double lotsArray[6] =
 {
  100000,
  100000,
  100000,
  100000,
  100000,
  100000
 };
// массив символов
string symArray[6] = 
 {
  "EURUSD",
  "GBPUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };
 
// перечисление режимов торговли эксперта
enum  TRADE_MODE 
 {
  TM_NO_DEALS     = 0,
  TM_DEAL_DONE    = 1,
  TM_CANNOT_TRADE = 2
 };
 
// функция перевода TRADE_MODE в int
int  TradeModeToInt (TRADE_MODE tm)
 {
  switch (tm)
   {
    case TM_NO_DEALS:
     return 0;
    break;
    case TM_DEAL_DONE:
     return 1;
    break;
    case TM_CANNOT_TRADE:
     return 2;
    break;
   }
  return -1;
 }  

// функция поиска строки в массиве
int ArraySearchString (string  &strArray[],string str)
 {
  int index;
  int length = ArraySize(strArray); // длина массива
  for (index=0;index<length;index++)
   {
    // если нашли элемент строкового массива
    if (strArray[index] == str)
     {
      // возвращаем индекс этого элемента
      return index;
     }
   }
  return -1; // не найден элемент массива
 }
 
// возвращает лот по символу
double GetLotBySymbol (string symbol)
 {
   return lotsArray[ArraySearchString(symArray,symbol)];
 } 