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
input int volume = 10;
input double factor = 0.01;
input int slowDelta = 30;
input int fastDelta = 50;
input int dayStep = 40;
input int monthStep = 400;

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
   dyn.InitDayTrade();
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
  dyn.InitDayTrade();
  dyn.InitMonthTrade();
  if (dyn.isInit())
  {
   dyn.RecountDelta();
   
   double vol = dyn.RecountVolume();
   //PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
   
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    if (dyn.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  } 
 }
//+------------------------------------------------------------------+

