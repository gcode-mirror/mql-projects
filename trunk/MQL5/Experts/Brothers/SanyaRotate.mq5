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
#include <Brothers\CSanyaRotate.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // Основное направление торговли
input int fastDelta = 12;    //  Начальная младшая дельта
input int dayStep = 100;     // шаг границы цены в пунктах для дневной торговли
input int minStepsFromStartToExtremum = 2;    // минимальное количество шагов от точки старта до экстремума
input int maxStepsFromStartToExtremum = 4;    // максимальное количество шагов от точки старта до экстремума
input int stepsFromStartToExit = 2;           // через сколько шагов закроемся после прохода старта не в нашу сторону

input int firstAdd = 20;    //  Процент первой доливки
input int secondAdd = 28;   //  Процент второй доливки
input int thirdAdd = 40;    //  Процент третьей доливки

input int volume = 10;      // Полный объем торгов
input int slowDelta = 60;   // Старшая дельта

input int percentage = 100;  // сколько процентов объем дневной торговли может перекрывать от месячно

string symbol;
datetime startTime;
double openPrice;
double currentVolume;
ENUM_ORDER_TYPE currentType;

double factor = 0.01; // множитель для вычисления текущего объема торгов от дельты
int fastPeriod = 24;  // Период обновления младшей дельта в часах
int slowPeriod = 30;  // Период обновления старшей дельта в днях

int monthStep = 400;   // шаг границы цены в пунктах для месячной торговл 
   
DELTA_STEP fastDeltaStep = FIFTY;  // Шаг изменения МЛАДШЕЙ дельты
DELTA_STEP slowDeltaStep = TEN;  // Шаг изменения СТАРШЕЙ дельты

CSanyaRotate san(fastDelta, slowDelta, dayStep, monthStep, minStepsFromStartToExtremum, maxStepsFromStartToExtremum, stepsFromStartToExit
                , type, volume, firstAdd, secondAdd, thirdAdd, fastDeltaStep, slowDeltaStep, percentage
                , fastPeriod, slowPeriod);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (fastDelta + firstAdd + secondAdd + thirdAdd != 100)
   {
    Print("Сумма доливок и начального входа долдна быть равна 100");
    return(INIT_FAILED);
   }
   if (type != ORDER_TYPE_BUY && type != ORDER_TYPE_SELL)
   {
    Print("Основное направлени торговли должно быть ORDER_TYPE_BUY или ORDER_TYPE_SELL");
    return(INIT_FAILED);
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    Print("Старшая дельта должна делиться на шаг");
    return(INIT_FAILED);
   }
   if (minStepsFromStartToExtremum > maxStepsFromStartToExtremum)
   {
    Print("Минимальное количество шагов не должно быть больше максимального");
    return(INIT_FAILED);
   }
   symbol = Symbol();
   startTime = TimeCurrent();
   san.SetSymbol(symbol);
   san.SetPeriod(Period());
   san.SetStartHour(startTime);
   
   currentVolume = 0;
   currentType = type;
   //san.InitMonthTrade();
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
  san.RecountFastDelta();
  
  if(san.isFastDeltaChanged() || san.isSlowDeltaChanged())
  {
   double vol = san.RecountVolume();
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    if (san.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
     PrintFormat ("%s currentVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume);
    }
   }
  }
  
  if (currentType != san.GetType())
  {
   double vol = san.RecountVolume();
   PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
   if (san.CorrectOrder(vol + currentVolume))
   {
    currentVolume = vol;
    currentType = san.GetType();
   }
  }
 }
//+------------------------------------------------------------------+
