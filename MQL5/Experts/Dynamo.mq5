//+------------------------------------------------------------------+
//|                                                       Dynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <Dinya\CDynamo.mqh>
#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;

string symbol;
ENUM_TIMEFRAMES period;
datetime startTime;
double openPrice;
double currentVolume;


CDynamo dyn;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   symbol = Symbol();
   period = Period();
   startTime = TimeCurrent();
   
   currentVolume = 0;
   dyn.InitMonthTrade();
   
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
//---
   dyn.InitDayTrade();
   dyn.InitMonthTrade();
   dyn.RecountDelta();
   
   double vol = dyn.RecountVolume();
   if (currentVolume != vol)
   {
    if (dyn.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
   
//---
  }
//+------------------------------------------------------------------+

