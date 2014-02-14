//+------------------------------------------------------------------+
//|                                                    CBrothers.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "BroUtilities.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CBrothers
{
protected:
 MqlTick tick;

 datetime _last_time;          // Последнее определенное время отсчета
 datetime _last_day_of_year;   // Время начала последнего определенного дня 
 datetime _last_day_of_week;   // Время начала последнего определенного дня недели
 datetime _last_month_number;  // Номер последнего определенного месяца
 
 string _symbol;                 // Имя инструмента
 ENUM_TIMEFRAMES _period;        // Период графика
      
 string _comment;        // Комментарий выполнения
 
 ENUM_ORDER_TYPE _type; // Основное направление торговли
 int _direction;         // Принимает значения 1 или -1 в зависмости от _type
 int _volume;      // Полный объем торгов   
 double _factor;   // множитель для вычисления текущего объема торгов от дельты
 int _percentage;  // сколько процентов объем дневной торговли может перекрывать от месячной
 int _startHour;   // час начала торговли
 int _startDayOfWeek; // день недели начала торговли 0 - воскресенье, 6 - суббота
 int _fastPeriod;  // Период инициализации младшей дельта в часах
 int _slowPeriod;  // Период инициализации старшей дельта в днях
 int _fastDeltaStep;   // Величина шага изменения дельты
 int _slowDeltaStep;   // Величина шага изменения дельты
 
 int _deltaFast;     // дельта для расчета объема "дневной" торговли
 int _deltaFastBase; // начальное значение "дневной" дельта
 int _deltaSlow;     // дельта для расчета объема "месячной" торговли
 int _deltaSlowBase; // начальное значение "месячной" дельта
 double _fastVol;   // объем для дневной торговли
 double _slowVol;   // объем для месячной торговли
 
 double _dayStep;          // шаг границы цены в пунктах для дневной торговли
 int _monthStep;        // шаг границы цены в пунктах для месячной торговли
 double _startDayPrice;   // цена начала торгов текущего дня
 double _prevDayPrice;   // текущий уровень цены дня
 double _prevMonthPrice; // текущий уровень цены месяца
 
 bool _isMonthInit; // ключ инициализации массива цен месяца
 bool _isDayInit;   // ключ инициализации массива цен дня
 
 bool _fastDeltaChanged;
 bool _slowDeltaChanged;
public:
//--- Конструкторы
 void CBrothers(void);      // Конструктор CBrothers
//--- Методы доступа к защищенным данным:
 //datetime GetLastDay() const {return(_last_day_number);}      // 18:00 последнего дня
 //datetime GetLastMonth() const {return(_last_month_number);}  // Дата и время определния последнего месяца
 string GetComment() const {return(_comment);}      // Комментарий выполнения
 string GetSymbol() const {return(_symbol);}         // Имя инструмента
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}          // Период графика
 
//--- Методы инициализации защищенных данных:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = period;}
 void SetStartHour(int startHour) {_startHour = startHour;}
 void SetStartHour(datetime startTime) {_startHour = (GetHours(startTime) + 1) % 24; Print("_startHour=",_startHour);}
 void SetStartDayOfWeek(datetime startTime) {_startDayOfWeek = GetDayOfWeek(startTime); Print("_startHour=",_startHour);}
//--- Рабочие методы класса
 bool isInit() {return(_isMonthInit && _isDayInit);}  // Инициализация завершна
 bool isMonthInit() {return(_isMonthInit);}
 bool isDayInit(){return(_isDayInit);}
 
 bool isFastDeltaChanged() {return _fastDeltaChanged;};
 bool isSlowDeltaChanged() {return _slowDeltaChanged;};

 bool timeToUpdateFastDelta();
 bool isNewMonth();
 bool isNewWeek();
 int isNewDay();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(ENUM_PERIOD period);
 double RecountVolume();
 bool CorrectOrder(double volume);
 int GetHours(datetime date);
 int GetDayOfWeek(datetime date);
 int GetDayOfYear(datetime date);
 int GetYear(datetime date);
 /*
 virtual double RecountVolume();
 virtual void RecountFastDelta();
 virtual void RecountSlowDelta();
 */
};

//+------------------------------------------------------------------+
//| Конструктор CBrothers.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CBrothers::CBrothers()
  {
   Print("Конструктор Бразерс");
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // Инициализируем день текущим днем
   _last_day_of_week = TimeCurrent();
   _last_day_of_year = TimeCurrent();
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   _comment = "";        // Комментарий выполнения
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
  }

//+------------------------------------------------------------------+
//| Проверка на время обновления младщей дельта                      |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::timeToUpdateFastDelta()
{
 datetime current_time = TimeCurrent();
 
 //--- Проверяем появление нового месяца: 
 if (_last_time < current_time - _fastPeriod*60*60)  // прошло _fastPeriod часов
 {
  _last_time = current_time; // запоминаем текущий день
  return(true);
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
int CBrothers::isNewDay()
{
 datetime current_time = TimeCurrent();
 
 if(GetHours(current_time) < _startHour)
 {
  _last_day_of_year = current_time;
  return(-1);
 }
  
 if (GetHours(_last_day_of_year) < _startHour && GetHours(current_time) >= _startHour) 
 {
  _last_day_of_year = current_time;
  return(GetDayOfWeek(_last_day_of_year));
 }

 //--- дошли до этого места - значит день не новый
 return(-1);
}

//+------------------------------------------------------------------+
//| Запрос на новый день недели.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::isNewWeek()
{
 datetime current_time = TimeCurrent();
  
 if (((GetDayOfYear(current_time) > GetDayOfYear(_last_day_of_week)) || (GetYear(current_time) > GetYear(_last_day_of_week)))
    && GetDayOfWeek(current_time) == _startDayOfWeek && GetHours(current_time) >= _startHour) 
 {
  _last_day_of_week = current_time;
  return(true);
 }

 //--- дошли до этого места - значит день не новый
 return(false);
}

//+------------------------------------------------------------------+
//| Запрос на появление нового месяца.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если новый месяц                                |
//|         false  - если не новый месяц или получили ошибку         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- Проверяем появление нового месяца: 
 if ((_last_month_number < current_time - _slowPeriod*24*60*60) && (GetHours(current_time) >= _startHour))  // прошло _slowPeriod дней
 {
  _last_month_number = current_time; // запоминаем текущий день
  return(true);
 }
 //--- дошли до этого места - значит месяц не новый
 return(false);
}

int CBrothers::GetHours(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.hour);
}

int CBrothers::GetDayOfWeek(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_week);
}

int CBrothers::GetDayOfYear(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_year);
}

int CBrothers::GetYear(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.year);
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CBrothers::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s _volume = %.05f, _factor = %.05f, _deltaSlow = %.05f", MakeFunctionPrefix(__FUNCTION__), _volume, _factor, _deltaSlow);
 //PrintFormat("%s slowVol = %.05f, fastVol = %.05f", MakeFunctionPrefix(__FUNCTION__), _slowVol, _fastVol);
 _slowDeltaChanged = false;
 _fastDeltaChanged = false;
 return (_slowVol - _fastVol); 
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  double volume.                                           |
//| OUTPUT: result of correction - true or false                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::CorrectOrder(double volume)
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