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

struct SExtremum
{
 int direction;
 double price;
};

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _average;      // выбирается из _averageMax и _averageMin смотрит с какой стороны от старта текущая цена
 double _averageMax;   // среднее между максимумом и стартом
 double _averageMin;   // среднее между минимумом и стартом
 double _averageRight; // среднее между первым и вторым экстремумом
 double _averageLeft;  // среднее между первым и нулевым экстремумом
 int _countSteps;
 double currentPrice, priceAB, priceHL;
 
 SExtremum num0, num1, num2, num3;
 
 CTradeLine startLine;
 CTradeLine lowLine;
 CTradeLine highLine;
 CTradeLine averageMaxLine;
 CTradeLine averageMinLine;
 CTradeLine averageRightLine;
 CTradeLine averageLeftLine;

 SExtremum isExtremum();
public:
//--- Конструкторы
 //void CSanya();
 void CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, int countSteps
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // Конструктор CSanya
             
 void InitMonthTrade();
 double RecountVolume();
 void RecountFastDelta();
 void RecountSlowDelta();
 void RecountLevels(SExtremum &extr);
 
 //SExtremum aExtremums[];
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
  
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   _comment = "";        // Комментарий выполнения
   
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
   currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
   
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;

   _deltaFast = _deltaFastBase;
   
   num0.direction = 0;
   num0.price = currentPrice;
   num1.direction = 0;
   num1.price = currentPrice;
   num2.direction = 0;
   num2.price = currentPrice;
   num3.direction = 0;
   num3.price = currentPrice;
   
   _averageLeft = 0;
   _averageRight = 0;
   _average = 0;
   _averageMax = 0;
   _averageMin = 0;
   _startDayPrice = 0;
   
   startLine.Create(_startDayPrice, "startLine", clrBlue);
   //lowLine.Create(_low, "lowLine");
   //highLine.Create(_high, "highLine");
   averageRightLine.Create(_averageRight, "aveRightLine", clrRed);
   averageLeftLine.Create(_averageLeft, "aveLeftLine", clrRed);
   averageMaxLine.Create(_averageMax, "aveMaxLine", clrAqua);
   averageMinLine.Create(_averageMin, "aveMinLine", clrAqua);
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
  PrintFormat("%s Новый месяц %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_last_month_number));
  currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
  
  _deltaFast = _deltaFastBase;
  _deltaSlow = _deltaSlowBase;
  _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
  
  // Цена начала отсчета
  if (_averageLeft > 0 && _averageRight > 0)
  {
   _startDayPrice = (_averageLeft + _averageRight)/2;
  }
  else
  {
   _startDayPrice = currentPrice; 
  }
  startLine.Price(0, _startDayPrice);
  //lowLine.Price(0, _low);
  //highLine.Price(0, _high);
  _isMonthInit = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений дельта                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountFastDelta()
{
 SymbolInfoTick(_symbol, tick);
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
 SExtremum extr = isExtremum();
//-----------------------------
// Если цена пошла вверх...
//-----------------------------
 if (extr.direction != 0)
 {
  RecountLevels(extr);
 }
 
 if (GreatDoubles(currentPrice, _startDayPrice + _countSteps*_dayStep*Point())) // Если цена выросла слишком сильно
 {
  if (_type == ORDER_TYPE_SELL && _deltaFast < 100) // цена растет, а основное направление - вниз, пора "засейвиться"
  {
   Print("цена растет, а основное направление - вниз, пора \"засейвиться\". Увеличиваем мл. дельта");
   _deltaFast = _deltaFast + _fastDeltaStep;    // увеличим младшую дельта
   _fastDeltaChanged = true;
  }
 }
 
//------------------------------
// Если цена пошла вниз...
//------------------------------
 if (LessDoubles(num0.price, _startDayPrice - _countSteps*_dayStep*Point()) && _average != 0) // Если цена упала слишком сильно
 {
  if (_type == ORDER_TYPE_BUY && _deltaFast < 100) // цена падает, а основное направление - вверх, пора "засейвиться"
  {
   Print("цена падает, а основное направление - вверх, пора \"засейвиться\". Увеличиваем мл. дельта");
   _deltaFast = _deltaFast + _fastDeltaStep;    // увеличим младшую дельта
   _fastDeltaChanged = true;
  }
 }
 
 priceAB = (_direction == 1) ? tick.ask : tick.bid; 
 if ( _average > 0 &&                               // Если среднее уже вычислено
      _direction*(_average - _startDayPrice) > 0 && // на уровне выше(ниже) стартовой
      _direction*(priceAB - _average) < 0 &&        // цена прошла через среднее вниз(вверх)
      _direction*(priceAB - _startDayPrice) > 0 &&  // цена выше(ниже) стартовой
      _deltaFast < 100)                             // мы еще не "засейвилсь"
 {
  Print("Цена ушла в нашу сторону, развернулась и прошла через среднее - Увеличиваем мл. дельта");
  _deltaFast = _deltaFast + _fastDeltaStep;   // увеличим младшую дельта (цена идет против выбранного направления - сейвимся)
  _fastDeltaChanged = true;
 }
   
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_direction*(_average - _startDayPrice) < 0 &&  // Если среднее уже вычислено на уровне ниже(выше) стартовой
     _direction*(priceAB - _average) > 0 &&         // цена прошла через среднее вверх(вниз)
     _direction*(priceAB - _startDayPrice) < 0 &&   // цена ниже стартовой
     _deltaFast > 0)                                // мы засейвлены
 {
  Print("Мы сейвились, цена ушла против нас, развернулась и прошла среднее - Уменьшаем мл. дельта.");
  PrintFormat("dir=%d, start=%.05f, ave=%.05f, price=%.05f", _direction, _startDayPrice, _average, priceAB);
  _deltaFast = _deltaFast - _fastDeltaStep;   // уменьшим младшую дельта (цена пошла в нашу сторону - прекращаем сейв)
  _fastDeltaChanged = true;
 }
}


//+------------------------------------------------------------------+
//| Пересчет значений месячной дельта                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountSlowDelta()
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
double CSanya::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 _slowDeltaChanged = false;
 _fastDeltaChanged = false;
 return (_slowVol - _fastVol); 
}

//+------------------------------------------------------------------+
//| Пересчет цены начала отсчета                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountLevels(SExtremum &extr)
{
 // Проверяем наличие экстремума 
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (extr.direction != 0)
 {
  if (extr.direction == num0.direction) // если новый экстремум в том же напрвлении, что старый
  {
   num0.price = extr.price;
  }
  else
  {
   num3 = num2;
   num2 = num1;
   num1 = num0;
   num0 = extr;
   PrintFormat("Сдвигаем экстремумы num0={%d, %.05f}, num1={%d, %.05f}, num2={%d, %.05f}, num3={%d, %.05f}",
                                                                                           num0.direction, num0.price,
                                                                                           num1.direction, num1.price,
                                                                                           num2.direction, num2.price,
                                                                                           num3.direction, num3.price);
   if (num2.direction != 0)
   {
    _averageRight = NormalizeDouble((num1.price + num2.price)/2, 5);
    averageRightLine.Price(0, _averageRight);
    //Print("вычислена правая средняя _averageRight=",_averageRight);
   }
   if (num3.direction != 0)
   {
    _averageLeft = NormalizeDouble((num2.price + num3.price)/2, 5);
    averageLeftLine.Price(0, _averageLeft);
    //Print("вычислена левая средняя _averageLeft=",_averageLeft);
   }
   if (_averageLeft > 0 && _averageRight > 0)
   {
    _startDayPrice = NormalizeDouble((_averageLeft + _averageRight)/2, 5);
    startLine.Price(0, _startDayPrice);
    Print("вычислены обе средние - переносим старт StartPrice=",_startDayPrice);
   }
  }
  
  if (extr.direction > 0 && GreatDoubles(extr.price, _startDayPrice))
  {
   _averageMax = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   _averageMin = 0;
   averageMaxLine.Price(0, _averageMax);
   averageMinLine.Price(0, _averageMin);
  }
  if (extr.direction < 0 && LessDoubles(extr.price, _startDayPrice))
  {
   _averageMin = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   _averageMax = 0;
   averageMaxLine.Price(0, _averageMax);
   averageMinLine.Price(0, _averageMin);
  }
 }
 
 if (_averageMax > 0)  _average = _averageMax;
 else if (_averageMin > 0)  _average = _averageMin;
      else _average = 0;
}

//+--------------------------------------------------------------------+
//| Функция возвращает направление и значение экстремума в точке vol2  |
//+--------------------------------------------------------------------+
SExtremum CSanya::isExtremum()
{
 SExtremum result = {0,0};
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 SymbolInfoTick(_symbol, tick);
 double ask = tick.ask, bid = tick.bid;
 
 if (((num0.direction == 0) && (GreatDoubles(bid, _startDayPrice + 2*_dayStep*Point(), 5))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
 || (num0.direction > 0 && (GreatDoubles(bid, num0.price, 5)))
 || (num0.direction < 0 && (GreatDoubles(bid, num0.price + _dayStep*Point(), 5))))
 {
  result.direction = 1;
  result.price = bid;
 }
 
 if (((num0.direction == 0) && (LessDoubles(ask, _startDayPrice - 2*_dayStep*Point(), 5))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
 || (num0.direction < 0 && (LessDoubles(ask, num0.price, 5)))
 || (num0.direction > 0 && (LessDoubles(ask, num0.price - _dayStep*Point(), 5))))
 {
  result.direction = -1;
  result.price = ask;
 }

 return(result);
}