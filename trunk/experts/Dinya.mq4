//+------------------------------------------------------------------+
//|                                                        Dinya.mq4 |
//|                                                              GIA |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "GIA"

//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
extern int _magic = 4577;
extern int useOrder = 0;
extern int volume = 10;  // Полный объем торгов
extern double factor = 0.01; // множитель для вычисления текущего объема торгов от дельты
extern int percentage = 70;  // сколько процентов объем дневной торговли может перекрывать от месячно
extern int slowPeriod = 30;  // Период обновления старшей дельта в днях
extern int fastPeriod = 24;  // Период обновления младшей дельта в часах
extern int slowDelta = 30;   // Старшая дельта
extern int fastDelta = 50;   // Младшая дельта
extern int slowDeltaStep = 10;  // Шаг изменения СТАРШЕЙ дельты
extern int fastDeltaStep = 10;  // Шаг изменения МЛАДШЕЙ дельты
extern int dayStep = 40;     // шаг границы цены в пунктах для дневной торговли
extern int monthStep = 400;  // шаг границы цены в пунктах для месячной торговл 

bool inited = true;

bool gbDisabled = false;
string symbol;
datetime startTime, startHour;
double openPrice;
double currentVolume;
bool isDayInit = false;
bool isMonthInit = false; // ключи инициализации массивов цен дня и месяца
bool dayDeltaChanged;
bool monthDeltaChanged;
static double prevDayPrice;
static double prevMonthPrice;
static datetime m_last_day_number;
static datetime m_last_month_number;

int direction;

#include <isNewBar.mqh>
#include <CDinya.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   if ((useOrder != 0) && (useOrder != 1))
   {
    Print("%s Должно быть выбрано основное направлени торговли 0 - на покупку, 1 - на продажу");
    inited = false;
   }
   if (fastDelta % fastDeltaStep != 0)
   {
    Print("%s Младшая дельта должна делиться на шаг");
    inited = false;
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    Print("%s Старшая дельта должна делиться на шаг");
    inited = false;
   }
   
   symbol = Symbol();
   startTime = TimeCurrent();
   startHour = TimeHour(TimeCurrent()) + 1; // Стартуем с началом нового часа
   Print("startHour=", startHour);
   direction = iif(useOrder == OP_BUY, 1, -1);
   m_last_day_number = TimeCurrent() - fastPeriod*60*60;
   m_last_month_number = TimeCurrent() - slowPeriod*24*60*60;   

   currentVolume = 0;
   InitDayTrade();
   InitMonthTrade();
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
 {
  if (!gbDisabled)
  {
   InitDayTrade();
   InitMonthTrade();
   if (isMonthInit)
   {
    RecountMonthDelta();
   }
   if (isDayInit)
   {
    RecountDayDelta();
   }
   if(dayDeltaChanged || monthDeltaChanged)
   {
    double vol = RecountVolume();
    Print("curVol=", currentVolume, " vol=", vol);
    if (currentVolume != vol)
    {
     if (CorrectOrder(vol - currentVolume))
     {
      Print(" currentVol=", currentVolume, " recountVol=",  vol);
      currentVolume = vol;
     }
    }
   }
  }  
  return(0);
 }
//+------------------------------------------------------------------+

