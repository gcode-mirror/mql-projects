//+------------------------------------------------------------------+
//|                                                       CSanya.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "CBrothers.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>
#include "TradeLines.mqh"
//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _high;
 double _low;
 double _averageMin;
 double _averageMax;
 int _countSteps;
 
 MqlTick tick;
 
 CTradeLine startLine;
 CTradeLine lowLine;
 CTradeLine highLine;
 CTradeLine averageMinLine;
 CTradeLine averageMaxLine;

public:
//--- Конструкторы
 //void CSanya();
 void CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, int countSteps
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // Конструктор CSanya
             
 void InitDayTrade();
 void InitMonthTrade();
 double RecountVolume();
 void RecountDelta();
};

//+------------------------------------------------------------------+
//| Конструктор CDinya.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, int countSteps,
                     ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod)
  {
   _deltaFastBase=deltaFast;
   _deltaSlowBase=deltaSlow;
   _fastDeltaStep=fastDeltaStep;
   _slowDeltaStep=slowDeltaStep;
   _dayStep=dayStep;
   _monthStep=monthStep;
   _countSteps=countSteps;
   _fastPeriod=fastPeriod;
   _slowPeriod=slowPeriod;
   _type=type;
   _volume=volume;
   _factor=factor;
   _percentage=percentage;
  
   m_last_day_number = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   m_last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   m_comment = "";        // Комментарий выполнения
   
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика

   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;

   _deltaFast = _deltaFastBase;
   _averageMin = 0;
   _averageMax = 0;
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
   _high = SymbolInfoDouble(_symbol, SYMBOL_BID);
   _low = SymbolInfoDouble(_symbol, SYMBOL_BID);
   _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
   _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
   
   startLine.Create(_startDayPrice, "startLine", clrBlue);
   lowLine.Create(_low, "lowLine");
   highLine.Create(_high, "highLine");
   averageMinLine.Create(_averageMin, "aveMinLine", clrRed);
   averageMaxLine.Create(_averageMax, "aveMaxLine", clrRed);
  }

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого дня              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::InitDayTrade()
{
 if (timeToUpdateFastDelta()) // Если случился новый день
 {
  PrintFormat("%s Новый день %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  _deltaFast = _deltaFastBase;
  _isDayInit = true;
  _averageMin = 0;
  _averageMax = 0;
  _high = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _low = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
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
void CSanya::InitMonthTrade()
{
 if(isNewMonth())
 {
  PrintFormat("%s Новый месяц %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));

  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
  _high = SymbolInfoDouble(_symbol, SYMBOL_BID);
  _low = SymbolInfoDouble(_symbol, SYMBOL_BID);
  _averageMax = 0;
  _averageMin = 0;
  _prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
  
  _deltaFast = _deltaFastBase;
  _deltaSlow = _deltaSlowBase;
  _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
   
  startLine.Price(0, _startDayPrice);
  lowLine.Price(0, _low);
  highLine.Price(0, _high);
  _isMonthInit = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений дельта                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountDelta()
{
// Текущая цена
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);

 double priceAB, priceHL, _average;
 SymbolInfoTick(_symbol, tick);

// Если цена пошла вверх...

 if (GreatDoubles (currentPrice, _high + 2*_dayStep*Point()) && _averageMax == 0) // Если текущая цена повысилась на шаг
 {
  Print("цена увеличилась на 2 шага, начинаем расчет среднего");

  _averageMax = currentPrice - (currentPrice - _startDayPrice)/2;   // вычислим среднее значение между текущей ценой и ценой начала работы
  _high = currentPrice;                                          // запомним это

  highLine.Price(0, _high);
  averageMaxLine.Price(0, _averageMax);
 }

 if (GreatDoubles(currentPrice, _high) && _averageMax != 0)
 {
  _averageMax = currentPrice - (currentPrice - _startDayPrice)/2;   // вычислим среднее значение между текущей ценой и ценой начала работы
  _high = currentPrice;
                                            // запомним это
  highLine.Price(0, _high);
  averageMaxLine.Price(0, _averageMax);
 }
 
 if (GreatDoubles(_high, _startDayPrice + _countSteps*_dayStep*Point())) // Если цена выросла слишком сильно
 {
  PrintFormat("цена ушла вверх на %d шагов, переносим цену старта расчетов. average=%.06f, start=%.06f", _countSteps, _averageMax, _startDayPrice);
  _startDayPrice = _averageMax;
  _low = _startDayPrice - _dayStep*Point();
  
  startLine.Price(0, _startDayPrice);
  lowLine.Price(0, _low);
  if (_type == ORDER_TYPE_SELL) // цена растет, а основное направление - вниз, пора "засейвиться"
  {
   Print("цена растет, а основное направление - вниз, пора \"засейвиться\". Увеличиваем мл. дельта");
   _deltaFast = _deltaFast + _fastDeltaStep;    // увеличим младшую дельта
  }
 }
 
// Если цена пошла вниз...
 if (LessDoubles(currentPrice, _low - 2*_dayStep*Point()) && _averageMin == 0) // Если текущая цена понизилась на шаг
 {
  Print("цена уменьшилась на шаг");
  _averageMin = currentPrice + (_startDayPrice - currentPrice)/2;   // вычислим среднее значение между текущей ценой и ценой начала работы
  _low = currentPrice;                                           // запомним это
  
  lowLine.Price(0, _low);
  averageMinLine.Price(0, _averageMin);
 }
 if (LessDoubles(currentPrice, _low) && _averageMin != 0)
 {
  _averageMin = currentPrice + (_startDayPrice - currentPrice)/2;   // вычислим среднее значение между текущей ценой и ценой начала работы
  _low = currentPrice;                                           // запомним это
  
  lowLine.Price(0, _low);
  averageMinLine.Price(0, _averageMin);
 }

 if (LessDoubles(_low, _startDayPrice - _countSteps*_dayStep*Point()) && _averageMin != 0) // Если цена упала слишком сильно
 {
  PrintFormat("цена ушла вниз на %d шагов , переносим цену старта расчетов.", _countSteps);
  _startDayPrice = _averageMin;
  _high = _startDayPrice + _dayStep*Point();
  
  startLine.Price(0, _startDayPrice);
  highLine.Price(0, _high);
  if (_type == ORDER_TYPE_BUY) // цена падает, а основное направление - вверх, пора "засейвиться"
  {
   Print("цена падает, а основное направление - вверх, пора \"засейвиться\". Увеличиваем мл. дельта");
   _deltaFast = _deltaFast + _fastDeltaStep;    // увеличим младшую дельта
  }
 }
 
 priceAB = (_direction == 1) ? tick.ask : tick.bid;
 _average = (_direction == 1) ? _averageMax : _averageMin;
 if ( _average > 0 &&
      _direction*(_average - _startDayPrice) > 0 && // Если среднее уже вычислено на уровне выше(ниже) стартовой
      _direction*(priceAB - _average) < 0 &&        // цена прошла через среднее вниз(вверх)
      _deltaFast < 100)                             // мы еще не "засейвилсь"
 {
  PrintFormat("Цена ушла в нашу сторону, развернулась и прошла через среднее - Увеличиваем мл. дельта");
  _deltaFast = _deltaFast + _fastDeltaStep;   // увеличим младшую дельта (цена идет против выбранного направления - сейвимся)
 }

 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 _average = (_direction == 1) ? _averageMin : _averageMax;
 if (_direction*(_average - _startDayPrice) < 0 &&  // Если среднее уже вычислено на уровне ниже(выше) стартовой
     _direction*(priceAB - _average) > 0 &&         // цена прошла через среднее вверх(вниз)
     _deltaFast > 0)                                // мы засейвлены
 {
  PrintFormat("Мы сейвились, цена ушла против нас, развернулась и прошла среднее - Уменьшаем мл. дельта.");
  _deltaFast = _deltaFast - _fastDeltaStep;   // уменьшим младшую дельта (цена пошла в нашу сторону - прекращаем сейв)
 }
 
 priceHL = (_direction == 1) ? _high : _low;               // Если стоим на покупку - выберем High, если на продажу - Low 
 priceAB = (_direction == 1) ? tick.bid : tick.ask;        // Если стоим на покупку - выберем bid, если на продажу - ask
 if (_deltaFast > 0 && _direction*(priceAB - priceHL) > 0) // Покупка: Bid>High , Продажа: Ask<Low
 {
  PrintFormat("Мы сейвились, но цена снова пошла в нашу сторону - Уменьшаем мл. дельта");
  _deltaFast = _deltaFast - _fastDeltaStep;   // уменьшим младшую дельта (цена пошла в нашу сторону - прекращаем сейв)
 }
 
 // Вычисляем старшую дельта
 if (_direction*(_deltaSlow - 50) < 50 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
   _prevMonthPrice = currentPrice;

  if (_direction < 0 && _deltaSlow < _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow + _direction*_slowDeltaStep;
  }
  //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if ((_direction*_deltaSlow + 50) > (_direction*50) && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_direction > 0 && _deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _direction*_slowDeltaStep;
   //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
  }
 }
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CSanya::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s большой объем %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  _slowVol, _deltaSlow);
 //PrintFormat("%s малый объем %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), _fastVol, _deltaFast);
 return (_slowVol - _fastVol); 
}
