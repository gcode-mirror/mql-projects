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

enum DELTA_STEP
{
 ONE = 1,
 TWO = 2,
 FOUR = 4,
 FIVE = 5,
 TEN = 10,
 TWENTY = 20,
 TWENTY_FIVE = 25,
 FIFTY = 50,
 HUNDRED = 100
};
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;
input int volume = 10;  // Полный объем торгов
input double factor = 0.01; // множитель для вычисления текущего объема торгов от дельты
input int percentage = 70;  // сколько процентов объем дневной торговли может перекрывать от месячно
input int slowPeriod = 30;  // Период обновления старшей дельта в днях
input int fastPeriod = 24;  // Период обновления младшей дельта в часах
input int slowDelta = 30;   // Старшая дельта
input int fastDelta = 50;   // Младшая дельта
input DELTA_STEP fastDeltaStep = TEN;  // Величина шага изменения дельты
input DELTA_STEP slowDeltaStep = TEN;  // Величина шага изменения дельты
input int dayStep = 40;     // шаг границы цены в пунктах для дневной торговли
input int monthStep = 400;  // шаг границы цены в пунктах для месячной торговл 


string symbol;
ENUM_TIMEFRAMES period;
datetime startTime;
double openPrice;
double currentVolume;

CDynamo dyn(fastDelta, slowDelta, fastDeltaStep, slowDeltaStep, dayStep, monthStep, volume, factor, percentage, fastPeriod, slowPeriod);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (fastDelta % fastDeltaStep != 0)
   {
    PrintFormat("%s Младшая дельта должна делиться на шаг");
    return(INIT_FAILED);
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    PrintFormat("%s Старшая дельта должна делиться на шаг");
    return(INIT_FAILED);
   }
   
   symbol = Symbol();
   period = Period();
   startTime = TimeCurrent();
   
   dyn.SetStartHour(startTime);
   
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

