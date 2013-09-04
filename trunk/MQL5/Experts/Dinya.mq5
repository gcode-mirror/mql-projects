//+------------------------------------------------------------------+
//|                                                        Dinya.mq5 |
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
#include <Brothers\CDinya.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // Основное направление торговли
input int volume = 10;  // Полный объем торгов
input double factor = 0.01; // множитель для вычисления текущего объема торгов от дельты
input int percentage = 70;  // сколько процентов объем дневной торговли может перекрывать от месячно
input int slowPeriod = 30;  // Период обновления старшей дельта в днях
input int fastPeriod = 24;  // Период обновления младшей дельта в часах
input int slowDelta = 30;   // Старшая дельта
input int fastDelta = 50;   // Младшая дельта
input DELTA_STEP slowDeltaStep = TEN;  // Шаг изменения СТАРШЕЙ дельты
input DELTA_STEP fastDeltaStep = TEN;  // Шаг изменения МЛАДШЕЙ дельты
input int dayStep = 40;     // шаг границы цены в пунктах для дневной торговли
input int monthStep = 400;  // шаг границы цены в пунктах для месячной торговл 

string symbol;
datetime startTime;
double openPrice;
double currentVolume;

CDinya dyn(fastDelta, slowDelta, fastDeltaStep, slowDeltaStep, dayStep, monthStep, type, volume, factor, percentage, fastPeriod, slowPeriod);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (type != ORDER_TYPE_BUY && type != ORDER_TYPE_SELL)
   {
    PrintFormat("%s Основное направлени торговли должно быть ORDER_TYPE_BUY или ORDER_TYPE_SELL");
    return(INIT_FAILED);
   }
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
    log_file.Write(LOG_DEBUG, StringFormat("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol));
    if (dyn.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  } 
 }
//+------------------------------------------------------------------+

