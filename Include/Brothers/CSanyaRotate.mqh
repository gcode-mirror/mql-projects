//+------------------------------------------------------------------+
//|                                                       CSanya.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "CSanya.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>
#include "TradeLines.mqh"

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CSanyaRotate: public CSanya
{
private:
 int hand_control;
 bool _beep;
 double _ko;              // коэффициент соотношения между максимальное количеством шагов до экстремума и минимальным количеством шагов 
 double secondAddPrice;   // уровень второй доливки
 double thirdAddPrice;    // уровень третьей доливки

public:
//--- Конструкторы
 void CSanyaRotate(int deltaFast, int deltaSlow, int dayStep, int monthStep
             , int minStepsFromStartToExtremum, int maxStepsFromStartToExtremum, int stepsFromStartToExit
             , ENUM_ORDER_TYPE type ,int volume
             , int firstAdd, int secondAdd, int thirdAdd
             , int fastDeltaStep = 100, int slowDeltaStep = 10
             , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30);  // Конструктор Саня
 
 bool getBeep() {return(_beep);};
 void SetHandControl(int value) {hand_control = value;};            
 void RecountFastDelta();
 void RecountLevels(SExtremum &extr);
};

//+------------------------------------------------------------------+
//| Конструктор CSanyaRotate.                                        |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanyaRotate::CSanyaRotate(int deltaFast, int deltaSlow,  int dayStep, int monthStep
                    , int minStepsFromStartToExtremum, int maxStepsFromStartToExtremum, int stepsFromStartToExit
                    , ENUM_ORDER_TYPE type ,int volume
                    , int firstAdd, int secondAdd, int thirdAdd
                    , int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30)  // Конструктор Саня
  {
   _factor = 0.01;
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   
   _deltaFast = 100 - _deltaFastBase;
   hand_control = _deltaFast;
   _deltaSlow = _deltaSlowBase;
   _slowDeltaChanged = true;

   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _firstAdd = firstAdd; _secondAdd = secondAdd; _thirdAdd = thirdAdd;
   
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _ko = 1;
   _minStepsFromStartToExtremum = minStepsFromStartToExtremum;
   _maxStepsFromStartToExtremum = maxStepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _fastPeriod = fastPeriod;
   _slowPeriod = slowPeriod;
   _type = type;
   _volume = volume;
   _percentage = percentage;
  
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   _comment = "";        // Комментарий выполнения
   
   _beep = false;
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
   currentPrice = (_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_symbol, SYMBOL_ASK) : SymbolInfoDouble(_symbol, SYMBOL_BID);
   
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
   addCount = 0;
      
   _startDayPrice = currentPrice; 
   _average = 0;
   _averageMax = _startDayPrice + _dayStep;
   _averageMin = _startDayPrice - _dayStep;
   
   num0.direction = 0;
   num0.price = currentPrice;
   num1.direction = 0;
   num1.price = currentPrice;
   num2.direction = 0;
   num2.price = currentPrice;
   num3.direction = 0;
   num3.price = currentPrice;
   
   _dealStartPrice = _startDayPrice;
   
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_START;
    _currentExitLevel = LEVEL_MINIMUM;
   }
   else
   {
    _currentEnterLevel = LEVEL_START;
    _currentExitLevel = LEVEL_MAXIMUM;
   }
   startLine.Create(_startDayPrice, "startLine", clrBlue);
   averageMaxLine.Create(_averageMax, "aveMaxLine", clrAqua);
   averageMinLine.Create(_averageMin, "aveMinLine", clrAqua);
  }

//+------------------------------------------------------------------+
//| Пересчет значений дельта                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanyaRotate::RecountFastDelta()
{
 SymbolInfoTick(_symbol, tick);
 SExtremum extr = isExtremum();
 RecountLevels(extr);
 //------------------------------
 // Система выходов
 //------------------------------
 priceAB = (_direction == 1) ? tick.ask : tick.bid; 
 if (_deltaFast != 100) // мы еще не "засейвилсь"
 {
  bool flag = false;
  if (num0.direction == 0)
  {
   if (LessDoubles(_direction*currentPrice, _direction*_startDayPrice - _stepsFromStartToExit*_dayStep)) // Есои цена сделала против нас _stepsFromStartToExit шагов
   {
    PrintFormat("тип сделки %s, цена идет против нас от старта и прошла %d шагов", OrderTypeToString(_type), _stepsFromStartToExit);
    flag = true;
   }
  }
  if (num0.direction != 0)
  {
   double currentExitPrice;
   switch (_currentExitLevel)
   {
    case LEVEL_MAXIMUM:
     currentExitPrice = (num0.direction < 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentExitPrice = _averageMax;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_MAXIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentExitPrice = _averageMin;
     //PrintFormat("Текущий уровень выхода %s, цена выхода=%.05f, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_START : LEVEL_MINIMUM;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentExitPrice = (num0.direction > 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  
  if (flag || hand_control == 100)
  {
   PrintFormat("%s Переворачиваем направление основного движения", MakeFunctionPrefix(__FUNCTION__));
   _type = (ENUM_ORDER_TYPE)(_type + MathPow (-1, _type)); // меняем тип _type = 1 -> 1 + -1^1 = 0; _type = 0 -> 0 + -1^0 = 1
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;        // запоминаем новое направление
   _dealStartPrice = priceAB;                              // запоминаем цену открытия сделки 
   _deltaFast = 100 - _deltaFastBase;   // увеличим младшую дельта (цена идет против выбранного направления - сейвимся)
   _fastDeltaChanged = true;
   addCount = 0;
   _ko = 1; 
   _beep = false;
  }
 }
 
 //-------------------------
 // Проверим на доливки
 //-------------------------
 if (_deltaFast > 0 && _deltaFast < 100)
 { 
  // один шаг от цены открытия
  if (LessDoubles(_direction*_dealStartPrice + _minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && addCount == 0)
  {
   PrintFormat("Первая доливка"); 
   _deltaFast = _deltaFast - _firstAdd;
   addCount++;
   _fastDeltaChanged = true;
   _ko = 1;
  }
  // два шага от цены открытия
  if (LessDoubles(_direction*_dealStartPrice + 2*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && addCount == 1)
  {
   PrintFormat("Вторая доливка");
   _deltaFast = _deltaFast - _secondAdd;
   addCount++;
   _fastDeltaChanged = true;
   secondAddPrice = _dealStartPrice + _direction*2*_minStepsFromStartToExtremum*_dayStep;  // уровень второй доливки
   thirdAddPrice = _dealStartPrice + _direction*4*_minStepsFromStartToExtremum*_dayStep;   // уровень третьей доливки
  }
  // четыре шага от цены открытия
  if (LessDoubles(_direction*_dealStartPrice + 4*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && addCount == 2)
  {
   PrintFormat("Третья доливка");
   _deltaFast = _deltaFast - _thirdAdd;
   addCount++;
   _fastDeltaChanged = true;
   _beep = true;
   _ko = 0;
  }
 }
 
 hand_control = _deltaFast;
}


//+------------------------------------------------------------------+
//| Пересчет цены начала отсчета                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanyaRotate::RecountLevels(SExtremum &extr)
{
 // Проверяем наличие экстремума 
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (extr.direction != 0)
 {
  if (extr.direction == num0.direction) // если новый экстремум в том же напрвлении, что старый
  {
   //Print("num0.price",num0.price);
   num0.price = extr.price;
  }
  else
  {
   num3 = num2;
   num2 = num1;
   num1 = num0;
   num0 = extr;
   Print("Новый экстремум");
   if (num1.direction == 0)
   {
    num1.direction = -num0.direction;
    num1.price = _startDayPrice + num1.direction*_minStepsFromStartToExtremum*_dayStep;
   }
  }
  
 //-------------------------------------------------
 // Выставляем точку старта
 //-------------------------------------------------
  // Если сделано 2 доливки начинаем подтаскивать линию старта к линии экстремума
  if ((addCount == 2) && GreatDoubles(_direction*(priceAB - _startDayPrice), _minStepsFromStartToExtremum*_dayStep, 5))
  {
   _ko = MathAbs(thirdAddPrice - priceAB)/MathAbs(thirdAddPrice - secondAddPrice);                        // коэффициент удаления экстремума от старта
  }
  // Если экстремум отошел от точки старта больше чем на _maxStepsFromStartToExtremum шагов, то тащим точку старта
  double stepsCount = (_ko*_maxStepsFromStartToExtremum + (1 - _ko)*_minStepsFromStartToExtremum);
  if (num0.direction*(num0.price - (_startDayPrice + num0.direction*stepsCount*_dayStep)) > 0)
  {
   _startDayPrice = num0.price - num0.direction*stepsCount*_dayStep;
   startLine.Price(0, _startDayPrice);
  }
 
 //-------------------------------------------------
 // Вычисляем средние значения
 //-------------------------------------------------
  if (num0.direction > 0)
  {
   _average = NormalizeDouble((num0.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   _averageMax = MathMax(_average, _startDayPrice + _dayStep); 
   averageMaxLine.Price(0, _averageMax);
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_MAXIMUM;
    _currentExitLevel = LEVEL_AVEMAX;
    //PrintFormat("Новый уровень входа %s и выхода %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
   else
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    _currentExitLevel = LEVEL_MAXIMUM;
    //PrintFormat("Новый уровень входа %s и выхода %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
  }
  if (num0.direction < 0)
  {
   _average = NormalizeDouble((num0.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   _averageMin = MathMin(_average, _startDayPrice - _dayStep); 
   averageMinLine.Price(0, _averageMin);
   
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    _currentExitLevel = LEVEL_MINIMUM;
    //PrintFormat("Новый уровень входа %s и выхода %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
   else
   {
    _currentEnterLevel = LEVEL_MINIMUM;
    _currentExitLevel = LEVEL_AVEMIN;
    //PrintFormat("Новый уровень входа %s и выхода %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   } 
  }  
 }
 //-------------------------------------------------
 //-------------------------------------------------
 
 if(num0.direction != 0)
 {     
 //-------------------------------------------------
 // Вычисляем уровни входа
 //-------------------------------------------------
 //priceAB = (_direction == 1) ? tick.bid : tick.ask;
 switch (_currentEnterLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_startDayPrice, priceAB, 5))  // цена прошла ниже(выше) старта
   {
    PrintFormat("Тек. уровень входа %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("цена (%.05f) прошла ниже старта(%.05f) Новый уровень входа %s",priceAB, _startDayPrice, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_averageMin, priceAB, 5))  // цена прошла ниже(выше) нижнего среднего
   {
    PrintFormat("Тек. уровень входа %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("цена (%.05f) прошла ниже нижнего среднего(%.05f) Новый уровень входа %s",priceAB, _averageMin, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB, _averageMax)) // цена прошла ниже(выше) старта на 1/3 шага
   {
    PrintFormat("Тек. уровень входа %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("цена (%.05f) прошла выше верхнего среднего(%.05f) Новый уровень входа %s",priceAB, _averageMax, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB, _startDayPrice))  // цена прошла ниже(выше) старта на 1/3 шага
   {
    PrintFormat("Тек. уровень входа %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("цена (%.05f) прошла выше старта(%.05f) Новый уровень входа %s",priceAB, _startDayPrice, LevelToString(_currentEnterLevel));
   }
   break;
 }
 //-------------------------------------------------
 //-------------------------------------------------
 
 //-------------------------------------------------
 // Вычисляем уровни вЫхода
 //-------------------------------------------------
 switch (_currentExitLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_startDayPrice, priceAB, 5))  // цена прошла ниже старта
   {
    _currentExitLevel = LEVEL_AVEMAX;
    //_currentEnterLevel = LEVEL_START;
    PrintFormat("цена (%.05f) прошла ниже старта(%.05f) Новый уровень вЫхода %s", priceAB, _startDayPrice,  LevelToString(_currentExitLevel));
   }
   //Print("Уровень вЫхода ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_averageMin, priceAB, 5))  // цена прошла ниже нижнего среднего
   {
    _currentExitLevel = LEVEL_START;
    //_currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("цена (%.05f) прошла ниже нижнего среднего(%.05f) Новый уровень вЫхода %s", priceAB, _averageMin, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_BUY && LessDoubles(_averageMax, priceAB, 5))  // цена прошла выше верхнего среднего
   {
    _currentExitLevel = LEVEL_START;
    //_currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("цена (%.05f) прошла выше верхнего среднего(%.05f) Новый уровень вЫхода %s", priceAB, _averageMax, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(priceAB, _startDayPrice, 5))  // цена прошла выше старта
   {
    _currentExitLevel = LEVEL_AVEMIN;
    //_currentEnterLevel = LEVEL_START;
    PrintFormat("цена (%.05f) прошла выше линии старта(%.05f) Новый уровень вЫхода %s", priceAB, _startDayPrice, LevelToString(_currentExitLevel));
   }
   //PrintFormat("Уровень вЫхода %s _averageMin=%.05f, priceAB=%.05f, ", LevelToString(_currentExitLevel), _averageMin + _trailingDeltaStep*_dayStep, priceAB);
  break;
 }
 }
}