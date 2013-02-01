//+------------------------------------------------------------------+
//|                                               Example1NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar current_chart; // экземпляр класса CisNewBar: текущий график

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(current_chart.isNewBar()>0)
     {     
      PrintFormat("Новый бар: %s",TimeToString(TimeCurrent(),TIME_SECONDS));
     }
  }
