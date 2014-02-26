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
 double _average;      // выбирается из _averageMax и _averageMin смотрит с какой стороны от старта текущая цена
 double _averageMax;   // среднее между максимумом и стартом
 double _averageMin;   // среднее между минимумом и стартом
 int _minStepsFromStartToExtremum;
 int _maxStepsFromStartToExtremum;
 int _stepsFromStartToExit;
 double currentPrice, priceAB, priceHL;
 ENUM_LEVELS _currentEnterLevel; // Текущий уровень входа
 ENUM_LEVELS _currentExitLevel;  // Текущий уровень выхода
 
 SExtremum num0, num1, num2, num3;
 double dealStartPrice;
 
 bool first, second, third;
 int _firstAdd, _secondAdd, _thirdAdd;
 
 CTradeLine startLine;
 CTradeLine lowLine;
 CTradeLine highLine;
 CTradeLine averageMaxLine;
 CTradeLine averageMinLine;

 SExtremum isExtremum();
public:
//--- Конструкторы
 void CSanya(){};
 void CSanya(int deltaFast, int deltaSlow, int dayStep, int monthStep
             , int minStepsFromStartToExtremum, int maxStepsFromStartToExtremum, int stepsFromStartToExit
             , ENUM_ORDER_TYPE type ,int volume
             , int firstAdd, int secondAdd, int thirdAdd
             , int fastDeltaStep = 100, int slowDeltaStep = 10
             , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30);  // Конструктор Саня
             
 void InitMonthTrade();
 void RecountFastDelta();
 void RecountSlowDelta();
 void RecountLevels(SExtremum &extr);
};

//+------------------------------------------------------------------+
//| Конструктор CDinya.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::CSanya(int deltaFast, int deltaSlow,  int dayStep, int monthStep
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
   _deltaSlow = _deltaSlowBase;
   _slowDeltaChanged = true;

   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _firstAdd = firstAdd; _secondAdd = secondAdd; _thirdAdd = thirdAdd;
   
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
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
   
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
   currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
   
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
   first = true; second = true; third = true;
   
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
   
   dealStartPrice = _startDayPrice;
   
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
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
 SExtremum extr = isExtremum();
 RecountLevels(extr);
 
 //------------------------------
 // Система выходов
 //------------------------------
 priceAB = (_direction == 1) ? tick.ask : tick.bid; 
 if (_deltaFast < 100) // мы еще не "засейвилсь"
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
      _currentEnterLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentExitPrice = _averageMax;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_MAXIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentExitPrice = _averageMin;
     //PrintFormat("Текущий уровень выхода %s, цена выхода=%.05f, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_START : LEVEL_MINIMUM;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentExitPrice = (num0.direction > 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s(%.05f), цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  
  if (flag)
  {
   Print("Увеличиваем младшую дельта - сейвимся");
   _deltaFast = 100;   // увеличим младшую дельта (цена идет против выбранного направления - сейвимся)
   _fastDeltaChanged = true;
   first = true; second = true; third = true;
   
   //extremumStart = (num0.direction == _direction) ? num0 : num1;  ///ToDo проверить в чем проблема!!!
   //PrintFormat("direction =%d, price=%.05f",extremumStart.direction, extremumStart.price);
  }
 }
 
 //------------------------------
 // Система входов
 //------------------------------ 
 SymbolInfoTick(_symbol, tick);
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_deltaFast == 100)  // мы засейвлены
 {
  bool flag = false;
  if (num0.direction == 0 && GreatDoubles(priceAB, _startDayPrice, 5))
  { 
   Print("Цена со старта ушла против нас, затем развернулась и прошла старт");
   flag = true;
   _currentExitLevel = (_type == ORDER_TYPE_BUY) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
  }
  
  if (num0.direction != 0)
  {
   double currentEnterPrice;
   switch (_currentEnterLevel)
   {
    case LEVEL_MAXIMUM:
     currentEnterPrice = (num0.direction > 0) ? num0.price : num1.price;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
     {
      PrintFormat("Цена пробила уровень входа %s=%.05f, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentEnterPrice = _averageMax;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
     {
      PrintFormat("Цена пробила уровень входа %s=%.05f, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_START : LEVEL_MAXIMUM;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentEnterPrice = _startDayPrice;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
     {
      PrintFormat("Цена пробила уровень входа %s=%.05f, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_AVEMIN : LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentEnterPrice = _averageMin;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
     {
      PrintFormat("Цена пробила уровень входа %s=%.05f, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_MINIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentEnterPrice = (num0.direction < 0) ? num0.price : num1.price;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
     {
      PrintFormat("Цена пробила уровень входа %s=%.05f, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  if (flag)
  {
   Print("Уменьшаем младшую дельта - прекращаем сейвиться ");
   dealStartPrice = priceAB;
   _deltaFast = 100 - _deltaFastBase;   // уменьшим младшую дельта (цена пошла в нашу сторону - прекращаем сейв)
   _fastDeltaChanged = true;
  }
 }
 
  //-------------------------
  // Проверим на доливки
  //-------------------------
 if (_deltaFast > 0 && _deltaFast < 100)
 { 
  if (LessDoubles(_direction*dealStartPrice + _minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && first)
  {
   PrintFormat("Первая доливка");
   first = false;
   _deltaFast = _deltaFast - _firstAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*dealStartPrice + 2*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && second)
  {
   PrintFormat("Вторая доливка");
   second = false;
   _deltaFast = _deltaFast - _secondAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*dealStartPrice + 4*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && third)
  {
   PrintFormat("Третья доливка");
   third = false;
   _deltaFast = _deltaFast - _thirdAdd;
   _fastDeltaChanged = true;
  }
 }
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
  // Если экстремум отошел от точки старта больше чем на _minStepsFromStartToExtremum шагов, то тащим точку старта
  if (num0.direction*(num0.price - (_startDayPrice + num0.direction*_maxStepsFromStartToExtremum*_dayStep)) > 0)
  {
   _startDayPrice = num0.price - num0.direction*_maxStepsFromStartToExtremum*_dayStep;
   startLine.Price(0, _startDayPrice);
   //Print("Экстремум очень далеко - переносим старт StartPrice=",_startDayPrice);
  }
 
 //-------------------------------------------------
 // Вычисляем средние значения
 //-------------------------------------------------
  if (extr.direction > 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   if (GreatDoubles (_average, _startDayPrice + _dayStep, 5))
   {
    _averageMax = _average; 
    averageMaxLine.Price(0, _averageMax);
   }
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
  if (extr.direction < 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   if (LessDoubles (_average, _startDayPrice - _dayStep, 5))
   {
    _averageMin = _average; 
    averageMinLine.Price(0, _averageMin);
   }
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
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
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

//+--------------------------------------------------------------------+
//| Функция возвращает направление и значение экстремума в точке vol2  |
//+--------------------------------------------------------------------+
SExtremum CSanya::isExtremum()
{
 SExtremum result = {0,0};
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 SymbolInfoTick(_symbol, tick);
 double ask = tick.ask, bid = tick.bid;
 
 if (((num0.direction == 0) && (GreatDoubles(bid, _startDayPrice + 2*_dayStep, 5))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
 || (num0.direction > 0 && (GreatDoubles(bid, num0.price, 5)))
 || (num0.direction < 0 && (GreatDoubles(bid, _startDayPrice + _minStepsFromStartToExtremum*_dayStep, 5))))
 {
  result.direction = 1;
  result.price = bid;
 }
 
 if (((num0.direction == 0) && (LessDoubles(ask, _startDayPrice - 2*_dayStep, 5))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
 || (num0.direction < 0 && (LessDoubles(ask, num0.price, 5)))
 || (num0.direction > 0 && (LessDoubles(ask, _startDayPrice - _minStepsFromStartToExtremum*_dayStep, 5))))
 {
  result.direction = -1;
  result.price = ask;
 }

 return(result);
}