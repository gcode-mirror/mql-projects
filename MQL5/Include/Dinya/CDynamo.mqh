//+------------------------------------------------------------------+
//|                                                      CDynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

enum ENUM_PERIOD
{
 Day,
 Month
};
//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CDynamo
{
protected:
 datetime m_last_day_number;   // Номер последнего определенного дня
 datetime m_last_month_number; // Номер последнего определенного месяца
 
 string _symbol;                 // Имя инструмента
 ENUM_TIMEFRAMES _period;        // Период графика
      
 string m_comment;        // Комментарий выполнения
 
 const ENUM_ORDER_TYPE _type; // Основное направление торговли
 const int _direction;         // Принимает значения 1 или -1 в зависмости от _type
 const int _volume;      // Полный объем торгов   
 const double _factor;   // множитель для вычисления текущего объема торгов от дельты
 const int _percentage;  // сколько процентов объем дневной торговли может перекрывать от месячной
 int _startHour;   // час начала торговли
 const int _fastPeriod;  // Период инициализации младшей дельта в часах
 const int _slowPeriod;  // Период инициализации старшей дельта в днях
 const int _fastDeltaStep;   // Величина шага изменения дельты
 const int _slowDeltaStep;   // Величина шага изменения дельты
 
 int _deltaFast;     // дельта для расчета объема "дневной" торговли
 int _deltaFastBase; // начальное значение "дневной" дельта
 int _deltaSlow;     // дельта для расчета объема "месячной" торговли
 int _deltaSlowBase; // начальное значение "месячной" дельта
 double _fastVol;   // объем для дневной торговли
 double _slowVol;   // объем для месячной торговли
 
 const int _dayStep;          // шаг границы цены в пунктах для дневной торговли
 const int _monthStep;        // шаг границы цены в пунктах для месячной торговли
 double _startDayPrice;   // цена начала торгов текущего дня
 double _prevDayPrice;   // текущий уровень цены дня
 double _prevMonthPrice; // текущий уровень цены месяца
 
 bool _isMonthInit; // ключ инициализации массива цен месяца
 bool _isDayInit;   // ключ инициализации массива цен дня
public:
//--- Конструкторы
 void CDynamo(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // Конструктор CDynamo
 
//--- Методы доступа к защищенным данным:
 datetime GetLastDay() const {return(m_last_day_number);}      // 18:00 последнего дня
 datetime GetLastMonth() const {return(m_last_month_number);}  // Дата и время определния последнего месяца
 string GetComment() const {return(m_comment);}      // Комментарий выполнения
 string GetSymbol() const {return(_symbol);}         // Имя инструмента
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}          // Период графика
 
//--- Методы инициализации защищенных данных:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = (period==PERIOD_CURRENT) ? Period() : period; }
 void SetStartHour(int startHour) {_startHour = startHour;}
 void SetStartHour(datetime startHour) {_startHour = (GetHours(startHour) + 1) % 24; Print("_startHour=",_startHour);}
 
//--- Рабочие методы класса
 bool isInit() {return(_isMonthInit && _isDayInit);}  // Инициализация завершна
 bool timeToUpdateFastDelta();
 bool isNewMonth();
 int isNewDay();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(ENUM_PERIOD period);
 double RecountVolume();
 void RecountDelta();
 bool CorrectOrder(double volume);
 int GetHours(datetime date);
 int GetDayOfWeek(datetime date);
};

//+------------------------------------------------------------------+
//| Конструктор CDynamo.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow), _fastDeltaStep(fastDeltaStep), _slowDeltaStep(slowDeltaStep),
                       _dayStep(dayStep), _monthStep(monthStep), _fastPeriod(fastPeriod), _slowPeriod(slowPeriod),
                      _type(type), _volume(volume), _factor(factor), _percentage(percentage)
  {
   m_last_day_number = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   m_last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   m_comment = "";        // Комментарий выполнения
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  }

//+------------------------------------------------------------------+
//| Проверка на время обновления младщей дельта                      |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::timeToUpdateFastDelta()
{
 datetime current_time = TimeCurrent();
 
 //--- Проверяем появление нового месяца: 
 if (m_last_day_number < current_time - _fastPeriod*60*60)  // прошло _fastPeriod часов
 {
  if (GetHours(current_time) >= _startHour) // Новый месяц начинается в 18 часов
  { 
   m_last_day_number = current_time; // запоминаем текущий день
   return(true);
  }
 }

 //--- дошли до этого места - значит день не новый
 return(false);
}

//+------------------------------------------------------------------+
//| Запрос на 18:00 каждого дня.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CDynamo::isNewDay()
{
 datetime current_time = TimeCurrent();
 
 if(GetHours(current_time) < _startHour)
 {
  m_last_day_number = current_time;
  return(-1);
 }
  
 if (GetHours(m_last_day_number) < _startHour && GetHours(current_time) >= _startHour) 
 {
  m_last_day_number = current_time;
  return(GetDayOfWeek(m_last_day_number));
 }

 //--- дошли до этого места - значит день не новый
 return(-1);
}

//+------------------------------------------------------------------+
//| Запрос на появление нового месяца.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если новый месяц                                |
//|         false  - если не новый месяц или получили ошибку         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- Проверяем появление нового месяца: 
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // прошло _slowPeriod дней
 {
  if (GetHours(current_time) >= _startHour) // Новый месяц начинается в _startHour часов
  { 
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   m_last_month_number = current_time; // запоминаем текущий день
   return(true);
  }
 }
 //--- дошли до этого места - значит месяц не новый
 return(false);
}

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого дня              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitDayTrade()
{
 if (timeToUpdateFastDelta()) // Если случился новый день
 {
  PrintFormat("%s Новый день %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  if (_startDayPrice > SymbolInfoDouble(_symbol, SYMBOL_LAST))
  {
   _deltaFast = 0;
   _isDayInit = false;
  }
  else
  {
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   _deltaFast = _deltaFastBase;
   _isDayInit = true;
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
void CDynamo::InitMonthTrade()
{
 if(isNewMonth())
 {
  PrintFormat("%s Новый месяц %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));
  _deltaSlow = _deltaSlowBase;
  _prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  _isMonthInit = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений дельта                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::RecountDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (_deltaFast < 100 && GreatDoubles(currentPrice, _prevDayPrice + _dayStep*Point()))
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _fastDeltaStep;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if (_deltaFast > 0 && LessDoubles(currentPrice, _prevDayPrice - _dayStep*Point()))
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _fastDeltaStep;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 
 if (_deltaSlow < 100 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
  _deltaSlow = _deltaSlow + _slowDeltaStep;
  _prevMonthPrice = currentPrice;
  //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if (_deltaSlow > 0 && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _slowDeltaStep;
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
double CDynamo::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s большой объем %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  _slowVol, _deltaSlow);
 //PrintFormat("%s малый объем %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), _fastVol, _deltaFast);
 return (_slowVol - _fastVol); 
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::CorrectOrder(double volume)
{
 if (volume == 0) return(false);
 
 MqlTradeRequest request = {0};
 MqlTradeResult result = {0};
 
 ENUM_ORDER_TYPE type;
 double price;
 
 if (volume > 0)
 {
  type = _type;
  price = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 }
 else
 {
  type = (ENUM_ORDER_TYPE)(_type + MathPow(-1, _type)); // Если _type= 0, то type =1, если  _type= 1, то type =0
  price = SymbolInfoDouble(_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = _symbol;
 request.volume = MathAbs(volume);
 log_file.Write(LOG_DEBUG, StringFormat("%s operation=%s, volume=%f", MakeFunctionPrefix(__FUNCTION__), EnumToString(type), MathAbs(volume)));
 request.price = price;
 request.sl = 0;
 request.tp = 0;
 request.deviation = SymbolInfoInteger(_symbol, SYMBOL_SPREAD); 
 request.type = type;
 request.type_filling = ORDER_FILLING_FOK;
 return (OrderSend(request, result));
}

int CDynamo::GetHours(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.hour);
}

int CDynamo::GetDayOfWeek(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_week);
}
