//+------------------------------------------------------------------+
//|                                                        Sanya.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <Brothers\CSanya.mqh>
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
input DELTA_STEP slowDeltaStep = TEN;  // Шаг изменения СТАРШЕЙ дельты
input int dayStep = 100;     // шаг границы цены в пунктах для дневной торговли
input int monthStep = 400;  // шаг границы цены в пунктах для месячной торговл 
input int stepsFromStartToExtremum = 4;    // максимальное количество шагов от точки старта до экстремума
input int stepsFromStartToExit = 2;        // через сколько шагов закроемся после прохода старта не в нашу сторону
input int stepsFromExtremumToExtremum = 2; // сколько шагов между экстремумами

string symbol;
datetime startTime;
double openPrice;
double currentVolume;

int fastDelta = 0;   // Младшая дельта
DELTA_STEP fastDeltaStep = HUNDRED;  // Шаг изменения МЛАДШЕЙ дельты

CSanya san(fastDelta, slowDelta, fastDeltaStep, slowDeltaStep, dayStep, monthStep, stepsFromStartToExtremum, stepsFromStartToExit, stepsFromExtremumToExtremum, type, volume, factor, percentage, fastPeriod, slowPeriod);
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
   if (slowDelta % slowDeltaStep != 0)
   {
    PrintFormat("%s Старшая дельта должна делиться на шаг");
    return(INIT_FAILED);
   }
   
   symbol = Symbol();
   startTime = TimeCurrent();
   san.SetSymbol(symbol);
   san.SetPeriod(Period());
   san.SetStartHour(startTime);
   
   currentVolume = 0;
   san.InitMonthTrade();
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
  san.InitMonthTrade();
  if (san.isMonthInit()) san.RecountFastDelta();
  
  if(san.isFastDeltaChanged() || san.isSlowDeltaChanged())
  {
   double vol = san.RecountVolume();
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    if (san.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  }
 }
//+------------------------------------------------------------------+
