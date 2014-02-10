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
  "GPBUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };

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