//+------------------------------------------------------------------+
//|                                                     OnNewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <OnNewBar.mqh> 

//+------------------------------------------------------------------+
//| Функция-обработчик события "новый бар"                           |
//+------------------------------------------------------------------+
void OnNewBar()
  {
   PrintFormat("Новый бар: %s",TimeToString(TimeCurrent(),TIME_SECONDS));
  }
