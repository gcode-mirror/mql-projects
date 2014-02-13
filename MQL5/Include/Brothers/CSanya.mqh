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

enum ENUM_LEVELS
{
 LEVEL_MINIMUM,
 LEVEL_AVEMIN,
 LEVEL_START,
 LEVEL_AVEMAX,
 LEVEL_MAXIMUM
};

string LevelToString(ENUM_LEVELS level)
{
 string res;
 switch (level)
 {
  case LEVEL_MAXIMUM:
   res = "level maximum";
   break;
  case LEVEL_MINIMUM:
   res = "level minimum";
   break;
  case LEVEL_AVEMAX:
   res = "level ave_max";
   break;
  case LEVEL_AVEMIN:
   res = "level ave_min";
   break;
  case LEVEL_START:
   res = "level start";
   break;
 }
 return res;
}
//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _trailingDeltaStep; // величина отступа от уровня, чтобы он стал действующим
 
 double _average;      // выбирается из _averageMax и _averageMin смотрит с какой стороны от старта текущая цена
 double _averageMax;   // среднее между максимумом и стартом
 double _averageMin;   // среднее между минимумом и стартом
 double _averageRight; // среднее между первым и вторым экстремумом
 double _averageLeft;  // среднее между первым и нулевым экстремумом
 int _stepsFromStartToExtremum;
 int _stepsFromStartToExit;
 int _stepsFromExtremumToExtremum;
 double currentPrice, priceAB, priceHL;
 ENUM_LEVELS _currentEnterLevel; // Текущий уровень входа
 ENUM_LEVELS _currentExitLevel;  // Текущий уровень выхода
 
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
 void CSanya(int deltaFast, int deltaSlow, int dayStep, int monthStep
                    , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
                    , ENUM_ORDER_TYPE type ,int volume, int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30, int trailingDeltaStep = 30);  // Конструктор Саня
             
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
                    , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
                    , ENUM_ORDER_TYPE type ,int volume, int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30, int trailingDeltaStep = 30)  // Конструктор Саня
  {
   _factor = 0.01;
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _trailingDeltaStep = trailingDeltaStep*_factor;
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _stepsFromStartToExtremum = stepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _stepsFromExtremumToExtremum = stepsFromExtremumToExtremum;
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

   num0.direction = 0;
   num0.price = currentPrice;
   //Print("num0.price=",num0.price);
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
  _fastDeltaChanged = true;
  _deltaSlow = _deltaSlowBase;
  _slowDeltaChanged = true;
  
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
    //_currentEnterLevel = LEVEL_START;
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
      PrintFormat("Цена пробила уровень выхода %s, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentExitPrice = _average;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_MAXIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentExitPrice = _average;
     //PrintFormat("Текущий уровень выхода %s, цена выхода=%.05f, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_START : LEVEL_MINIMUM;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentExitPrice = (num0.direction > 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("Цена пробила уровень выхода %s, цена=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  
  if (flag)
  {
   Print("Увеличиваем младшую дельта - сейвимся");
   _deltaFast = _deltaFast + _fastDeltaStep;   // увеличим младшую дельта (цена идет против выбранного направления - сейвимся)
   _fastDeltaChanged = true;
  }
 }
 
 //------------------------------
 // Система входов
 //------------------------------ 
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_deltaFast > 0)  // мы засейвлены
 {
  bool flag = false;
  if (num0.direction == 0 && GreatDoubles(priceAB, _startDayPrice, 5))
  { 
   Print("Цена со старта ушла против нас, затем развернулась и прошла старт");
   flag = true;
   _currentExitLevel = (_type == ORDER_TYPE_BUY) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
  }
  
  double currentEnterPrice;
  switch (_currentEnterLevel)
  {
   case LEVEL_MAXIMUM:
    currentEnterPrice = (num0.direction > 0) ? num0.price : num1.price;
    if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
    {
     PrintFormat("Цена пробила уровень входа %s, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
     _currentExitLevel = LEVEL_AVEMAX;
     flag = true;
    }
    break;
   case LEVEL_AVEMAX:
    currentEnterPrice = _average;
    if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
    {
     PrintFormat("Цена пробила уровень входа %s, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
     _currentExitLevel = (_direction == 1) ? LEVEL_START : LEVEL_MAXIMUM;
     flag = true;
    }
    break;
   case LEVEL_START:
    currentEnterPrice = _startDayPrice;
    if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
    {
     PrintFormat("Цена пробила уровень входа %s, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
     _currentExitLevel = (_direction == 1) ? LEVEL_AVEMIN : LEVEL_AVEMAX;
     flag = true;
    }
    break;
   case LEVEL_AVEMIN:
    currentEnterPrice = _average;
    if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
    {
     PrintFormat("Цена пробила уровень входа %s, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
     _currentExitLevel = (_direction == 1) ? LEVEL_MINIMUM : LEVEL_START;
     flag = true;
    }
    break;
   case LEVEL_MINIMUM:
    currentEnterPrice = (num0.direction < 0) ? num0.price : num1.price;
    if (_direction*(priceAB - currentEnterPrice) >= 0) // Цена пробила уровень входа
    {
     PrintFormat("Цена пробила уровень входа %s, цена=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
     _currentExitLevel = LEVEL_AVEMIN;
     flag = true;
    }
    break;
  }
  
  if (flag)
  {
   Print("Уменьшаем младшую дельта - прекращаем сейвиться");
   _deltaFast = _deltaFast - _fastDeltaStep;   // уменьшим младшую дельта (цена пошла в нашу сторону - прекращаем сейв)
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
   PrintFormat("Сдвигаем экстремумы num0={%d, %.05f}, num1={%d, %.05f}, num2={%d, %.05f}, num3={%d, %.05f}",
                                                                                           num0.direction, num0.price,
                                                                                           num1.direction, num1.price,
                                                                                           num2.direction, num2.price,
                                                                                           num3.direction, num3.price);
  }
  
 //-------------------------------------------------
 // Выставляем точку старта
 //-------------------------------------------------
 
  // Если экстремум отошел от точки старта больше чем на _countStepsToExtremum шагов, то тащим точку старта
  if (num0.direction*(num0.price - (_startDayPrice + num0.direction*_stepsFromStartToExtremum*_dayStep)) > 0)
  {
   _startDayPrice = num0.price - num0.direction*_stepsFromStartToExtremum*_dayStep;
   startLine.Price(0, _startDayPrice);
   //Print("Экстремум очень далеко - переносим старт StartPrice=",_startDayPrice);
  }
  
  // Вычисляем среднее между первым и вторым экстремумами
  if (num1.direction != 0)
  {
   _averageRight = NormalizeDouble((num0.price + num1.price)/2, 5);
   averageRightLine.Price(0, _averageRight);
  }
  
  // Вычисляем среднее между вторым и третьим экстремумами
  if (num2.direction != 0)
  {
   _averageLeft = NormalizeDouble((num1.price + num2.price)/2, 5);
   averageLeftLine.Price(0, _averageLeft);
  }
  
  // Если есть оба средних, вычисляем точку старта между ними
  if (_averageLeft > 0 && _averageRight > 0)
  {
   double _newStartDayPrice = NormalizeDouble((_averageLeft + _averageRight)/2, 5);
   // Если новый старт получился дальше _countStepsToExtremum шагов от экстремума, то ставим его на расстоянии _countStepsToExtremum
   if (GreatDoubles(num0.direction*(num0.price - _newStartDayPrice), _stepsFromStartToExtremum*_dayStep, 5))
   {
    _startDayPrice = num0.price - num0.direction*_stepsFromStartToExtremum*_dayStep;
    startLine.Price(0, _startDayPrice);
   }
   // если расстояние меньше, то смотрим разницу; переносим только если разница больше шага
   else
   {
    double dif = MathAbs(_newStartDayPrice - _startDayPrice);
    if (dif > _dayStep)
    {
     _startDayPrice = _newStartDayPrice;
     startLine.Price(0, _startDayPrice);
     //Print("вычислены обе средние - переносим старт StartPrice=",_startDayPrice);
    }
   }
  }
 //-------------------------------------------------
 //-------------------------------------------------
 
 //-------------------------------------------------
 // Вычисляем средние значения
 //-------------------------------------------------
  if (extr.direction > 0)
  {
   _averageMax = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   if (LessDoubles (_averageMax, _startDayPrice + _dayStep, 5)) _averageMax = 0; 
  }
  if (extr.direction < 0)
  {
   _averageMin = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // вычислим среднее значение между текущей ценой и ценой начала работы
   if (GreatDoubles (_averageMin, _startDayPrice - _dayStep, 5)) _averageMin = 0; 
   //PrintFormat("Новый экстремум вниз = %.05f, пересчитали уровень aveMin=%.05f", extr.price, _averageMin);
  }
 }
 
 if (_averageMax > 0)
 {
  _average = _averageMax;
  averageMaxLine.Price(0, _averageMax);
  //PrintFormat("Новый уровень aveMax=%.05f", _averageMax);
  _averageMin = 0; _averageMax = 0;
  averageMinLine.Price(0, _averageMin);
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
 else if (_averageMin > 0)
      {
       _average = _averageMin;
       averageMinLine.Price(0, _averageMin);
       //PrintFormat("Новый уровень aveMin=%.05f", _average);
       _averageMin = 0; _averageMax = 0;
       averageMaxLine.Price(0, _averageMax);
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
      //else _average = 0;
 //-------------------------------------------------
 //-------------------------------------------------
      
 //-------------------------------------------------
 // Вычисляем уровни входа
 //-------------------------------------------------
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 switch (_currentEnterLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) среднего на 1/3 шага
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   //Print("Уровень входа ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_startDayPrice, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) старта на 1/3 шага
   {
    _currentEnterLevel = LEVEL_START;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   //Print("Уровень входа ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) среднего на 1/3 шага
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _average)) 
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   //Print("Уровень входа ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _startDayPrice)) // цена прошла ниже(выше) старта на 1/3 шага
   {
    _currentEnterLevel = LEVEL_START;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _average))  // цена прошла ниже(выше) старта на 1/3 шага
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    //Print("Новый уровень входа ", LevelToString(_currentEnterLevel));
   }
   //Print("Уровень входа ", LevelToString(_currentEnterLevel));
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
   if (_type == ORDER_TYPE_SELL && 
       GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) среднего на 1/3 шага
   {
    _currentExitLevel = LEVEL_AVEMAX;
    _currentEnterLevel = LEVEL_START;
    //Print("Новый уровень вЫхода ", LevelToString(_currentExitLevel));
   }
   //Print("Уровень вЫхода ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_startDayPrice, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) старта на 1/3 шага
   {
    _currentExitLevel = LEVEL_START;
    _currentEnterLevel = LEVEL_AVEMIN;
    //Print("Новый уровень вЫхода ", LevelToString(_currentExitLevel));
   }
   //Print("Уровень вЫхода ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // цена прошла ниже(выше) среднего на 1/3 шага
   {
    _currentExitLevel = LEVEL_AVEMIN;
    _currentEnterLevel = LEVEL_MINIMUM;
    //Print("Новый уровень вЫхода ", LevelToString(_currentExitLevel));
   }
   if (_type == ORDER_TYPE_BUY && LessDoubles(_average + _trailingDeltaStep*_dayStep, priceAB, 5)) 
   {
    _currentExitLevel = LEVEL_AVEMAX;
    _currentEnterLevel = LEVEL_MAXIMUM;
    //Print("Новый уровень вЫхода ", LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_BUY && LessDoubles(_startDayPrice + _trailingDeltaStep*_dayStep, priceAB, 5))  // цена прошла ниже(выше) старта на 1/3 шага
   {
    _currentExitLevel = LEVEL_START;
    _currentEnterLevel = LEVEL_AVEMAX;
    //Print("Новый уровень вЫхода ", LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_BUY && 
       GreatDoubles(priceAB, _average + _trailingDeltaStep*_dayStep, 5))  // цена прошла выше нижнего среднего на 1/3 шага
   {
    _currentExitLevel = LEVEL_AVEMIN;
    _currentEnterLevel = LEVEL_START;
    //PrintFormat("цена (%.05f) прошла выше нижнего среднего(%.05f) на 1/3 шага(%.05f) Новый уровень вЫхода %s", priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   //PrintFormat("Уровень вЫхода %s _averageMin=%.05f, priceAB=%.05f, ", LevelToString(_currentExitLevel), _averageMin + _trailingDeltaStep*_dayStep, priceAB);
  break;
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
 || (num0.direction < 0 && (GreatDoubles(bid, num0.price + _stepsFromExtremumToExtremum*_dayStep, 5))))
 {
  result.direction = 1;
  result.price = bid;
 }
 
 if (((num0.direction == 0) && (LessDoubles(ask, _startDayPrice - 2*_dayStep, 5))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
 || (num0.direction < 0 && (LessDoubles(ask, num0.price, 5)))
 || (num0.direction > 0 && (LessDoubles(ask, num0.price - _stepsFromExtremumToExtremum*_dayStep, 5))))
 {
  result.direction = -1;
  result.price = ask;
 }

 return(result);
}