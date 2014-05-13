//+------------------------------------------------------------------+
//|                                                   TestNewBar.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Lib CisNewBar.mqh>              // для формирования нового бара
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

    static CisNewBar isNewBar(_Symbol, _Period);   // для проверки формирования нового бара
  int countBars=0;

int OnInit()
  {
//---
   
//---
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
    if(isNewBar.isNewBar() > 0)
     {       
       countBars++;
       Print("Количество баров = ",countBars," время закрытия последнего = ",TimeToString(TimeCurrent()));
     }
   
  }
//+------------------------------------------------------------------+
