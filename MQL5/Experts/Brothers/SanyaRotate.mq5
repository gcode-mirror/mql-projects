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
input string sound = "AHOOGA.WAV";
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // Начальное направление торговли

input int volume = 10;      // Полный объем торгов
input int slowDelta = 60;   // Старшая дельта (процент от полного объема)
input double ko = 2;        // Коэффициент доливки

input int dayStep = 100;     // шаг границы цены в пунктах для дневной торговли
input int minStepsFromStartToExtremum = 2;    // минимальное количество шагов от точки старта до экстремума
input int maxStepsFromStartToExtremum = 4;    // максимальное количество шагов от точки старта до экстремума
input int stepsFromStartToExit = 2;           // через сколько шагов закроемся после прохода старта не в нашу сторону

input int maxSpread = 30;

string symbol;
datetime startTime;
double openPrice;
double currentVolume;
ENUM_ORDER_TYPE currentType;

int fastPeriod = 24;  // Период обновления младшей дельта в часах
int slowPeriod = 30;  // Период обновления старшей дельта в днях
int percentage = 100;  // сколько процентов объем дневной торговли может перекрывать от месячной
double factor = 0.01; // множитель для вычисления текущего объема торгов от дельты

int monthStep = 400;   // шаг границы цены в пунктах для месячной торговл 
   
DELTA_STEP fastDeltaStep = FIFTY;  // Шаг изменения МЛАДШЕЙ дельты
DELTA_STEP slowDeltaStep = TEN;  // Шаг изменения СТАРШЕЙ дельты

CSanyaRotate *san;
Button *close_button;
double vol = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   close_button = new Button ("close_button", "KILL", 10, 10, 40, 40, 0, 0, CORNER_LEFT_UPPER, 0);
   int fastDelta, firstAdd, secondAdd, thirdAdd;
   
   fastDelta = 100 / (1 + ko + ko*ko + ko*ko*ko);
   firstAdd = fastDelta * ko;
   secondAdd = firstAdd * ko;
   thirdAdd = 100 - secondAdd - firstAdd - fastDelta;
   
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
   
   san = new CSanyaRotate(fastDelta, slowDelta, dayStep, monthStep, minStepsFromStartToExtremum, maxStepsFromStartToExtremum, stepsFromStartToExit
                , type, volume, firstAdd, secondAdd, thirdAdd, fastDeltaStep, slowDeltaStep, percentage
                , fastPeriod, slowPeriod);
                
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
   delete san;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  if (san.getBeep())
  {
   PlaySound(sound);
   //Print("");
  }
  san.RecountFastDelta();
  
  int spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
  
  if(san.isFastDeltaChanged() || san.isSlowDeltaChanged())
  {
   vol = san.RecountVolume();
  }
  
  if (spread < maxSpread)
  {
   if (currentType != san.GetType())
   {
    if (san.CorrectOrder(-vol - currentVolume))
    {
     currentVolume = vol;
     currentType = san.GetType();
     PrintFormat("%s currentType = %s, san.GetType() = %s", MakeFunctionPrefix(__FUNCTION__), OrderTypeToString(currentType), OrderTypeToString(san.GetType()));
    }
   }
   
   if (currentVolume != vol)
   {
    if (san.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
     PrintFormat ("%s currentVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume);
    }
   }
  } 
 }
//+------------------------------------------------------------------+


void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string
                 )
{
 if(id == CHARTEVENT_OBJECT_CLICK)
 {
  if (sparam == "close_button")     // кнопка "Кнопка закрытия позиции вручную"
  {
   san.SetHandControl(100);
   ObjectSetInteger(0, "close_button", OBJPROP_STATE, false);  
  }
 }
}
