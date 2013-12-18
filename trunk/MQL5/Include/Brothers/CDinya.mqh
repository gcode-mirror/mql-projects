//+------------------------------------------------------------------+
//|                                                       CDinya.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "CBrothers.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CDinya: public CBrothers
{
private:
public:
//--- Конструкторы
 //void CDinya();
 void CDinya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // Конструктор CDinya
             
 void InitDayTrade();
 void InitWeekTrade();
 void InitMonthTrade();
 double RecountVolume();
 void RecountFastDelta();
 void RecountSlowDelta();
};

//+------------------------------------------------------------------+
//| Конструктор CDinya.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::CDinya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
                     ,ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod)
  {
   _deltaFastBase=deltaFast;
   _deltaSlowBase=deltaSlow;
   _fastDeltaStep=fastDeltaStep;
   _slowDeltaStep=slowDeltaStep;
   _dayStep=dayStep;
   _monthStep=monthStep;
   _fastPeriod=fastPeriod;
   _slowPeriod=slowPeriod;
   _type=type;
   _volume=volume;
   _factor=factor;
   _percentage=percentage;
  
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   _last_day_of_week = TimeCurrent() - 24*60*60;
   _last_day_of_year = TimeCurrent() - 24*60*60;
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   
   _comment = "";        // Комментарий выполнения
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);

   _isDayInit = false;
   _isMonthInit = false;
  }

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого дня              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::InitDayTrade()
{
 if (timeToUpdateFastDelta()) // Если случился новый день
 {
  PrintFormat("%s Новый день %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_last_time));
  if (_direction * _startDayPrice > _direction * SymbolInfoDouble(_symbol, SYMBOL_LAST))
  {
   _deltaFast = 0;
   _isDayInit = false;
   _fastDeltaChanged = true;
  }
  else
  {
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   _deltaFast = _deltaFastBase;
   _isDayInit = true;
   _fastDeltaChanged = true;
  } 
  
  _prevDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 }
}

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого месяца           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::InitWeekTrade()
{
 if(isNewMonth())
 {
  PrintFormat("%s Новая неделя %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_last_month_number));
  _deltaSlow = _deltaSlowBase;
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  _isMonthInit = true;
  _slowDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого месяца           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::InitMonthTrade()
{
 if(isNewMonth())
 {
  PrintFormat("%s Новый месяц %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_last_month_number));
  _deltaSlow = _deltaSlowBase;
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  _isMonthInit = true;
  _slowDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений дневной дельта                                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::RecountFastDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (_direction*(_deltaFast - 50) < 50 && GreatDoubles(currentPrice, _prevDayPrice + _dayStep*Point())) // _dir = 1 : delta < 100; _dir = -1 : delta > 0
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _direction*_fastDeltaStep;
  _fastDeltaChanged = true;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if ((_direction*_deltaFast + 50) > (_direction*50) && LessDoubles(currentPrice, _prevDayPrice - _dayStep*Point())) // _dir = 1 : delta > 0; _dir = -1 : delta < 100
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _direction*_fastDeltaStep;
  _fastDeltaChanged = true;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
} 
//+------------------------------------------------------------------+
//| Пересчет значений месячной дельта                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::RecountSlowDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);

 if (_direction*(_deltaSlow - 50) < 50 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
   _prevMonthPrice = currentPrice;

  if (_direction < 0 && _deltaSlow < _deltaSlowBase) // Если дельта ушла в нашем направлении и начинается откат 
  {
   _deltaSlow = _deltaSlowBase;                      // - фиксируем часть прибыли
  }
  else
  {
   _deltaSlow = _deltaSlow + _direction*_slowDeltaStep;
  }
  _slowDeltaChanged = true;
  //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 
 if ((_direction*_deltaSlow + 50) > (_direction*50) && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_direction > 0 && _deltaSlow > _deltaSlowBase) // Если дельта ушла в нашем направлении и начинается откат 
  {
   _deltaSlow = _deltaSlowBase;                      // - фиксируем часть прибыли
  }
  else
  {
   _deltaSlow = _deltaSlow - _direction*_slowDeltaStep;
  }
  //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
  _slowDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CDinya::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 _slowDeltaChanged = false;
 _fastDeltaChanged = false;
 return (_slowVol - _fastVol); 
}
