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
 datetime m_last_day_number;   // Номер последнего определенного дня
 datetime m_last_month_number; // Номер последнего определенного месяца
 
 string _symbol;                 // Имя инструмента
 ENUM_TIMEFRAMES _period;        // Период графика
      
 string m_comment;        // Комментарий выполнения
 
 ENUM_ORDER_TYPE _type; // Основное направление торговли
 int _direction;         // Принимает значения 1 или -1 в зависмости от _type
 int _volume;      // Полный объем торгов   
 double _factor;   // множитель для вычисления текущего объема торгов от дельты
 int _percentage;  // сколько процентов объем дневной торговли может перекрывать от месячной
 int _startHour;   // час начала торговли
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
 
 int _dayStep;          // шаг границы цены в пунктах для дневной торговли
 int _monthStep;        // шаг границы цены в пунктах для месячной торговли
 double _startDayPrice;   // цена начала торгов текущего дня
 double _prevDayPrice;   // текущий уровень цены дня
 double _prevMonthPrice; // текущий уровень цены месяца
 
 bool _isMonthInit; // ключ инициализации массива цен месяца
 bool _isDayInit;   // ключ инициализации массива цен дня
public:
//--- Конструкторы
 void CBrothers(void);      // Конструктор CBrothers
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
/*
//+------------------------------------------------------------------+
//| Конструктор CBrothers.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CBrothers::CBrothers(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow),
                      _fastDeltaStep(fastDeltaStep), _slowDeltaStep(slowDeltaStep),
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
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
  }
*/
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
int CBrothers::isNewDay()
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
bool CBrothers::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- Проверяем появление нового месяца: 
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // прошло _slowPeriod дней
 {
  if (GetHours(current_time) >= _startHour) // Новый месяц начинается в _startHour часов
  { 
   m_last_month_number = current_time; // запоминаем текущий день
   return(true);
  }
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
