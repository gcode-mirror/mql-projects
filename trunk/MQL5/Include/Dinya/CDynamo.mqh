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
      
 uint m_retcode;          // Код результата определения нового дня 
 string m_comment;        // Комментарий выполнения
 
 const int _volume;      // Полный объем торгов   
 const double _factor;   // множитель для вычисления текущего объема торгов от дельты
 const int _percentage;  // сколько процентов объем дневной торговли может перекрывать от месячной
 const int _slowPeriod;  // Период инициализации старшей дельта
 const int _deltaStep;   // Величина шага изменения дельты
 
 int _deltaFast;     // дельта для расчета объема "дневной" торговли
 int _deltaFastBase; // начальное значение "дневной" дельта
 int _deltaSlow;     // дельта для расчета объема "месячной" торговли
 int _deltaSlowBase; // начальное значение "месячной" дельта
 double fastVol;   // объем для дневной торговли
 double slowVol;   // объем для месячной торговли
 
 const int _dayStep;          // шаг границы цены в пунктах для дневной торговли
 const int _monthStep;        // шаг границы цены в пунктах для месячной торговли
 double prevDayPrice;   // текущий уровень цены дня
 double prevMonthPrice; // текущий уровень цены месяца
 
 bool isMonthInit; // ключ инициализации массива цен месяца
 bool isDayInit;   // ключ инициализации массива цен дня
public:
//--- Конструкторы
 void CDynamo(int deltaFast, int deltaSlow, int deltaStep, int dayStep, int monthStep, int volume, double factor, int percentage, int slowPeriod);      // Конструктор CDynamo
 
//--- Методы доступа к защищенным данным:
 uint GetRetCode() const {return(m_retcode);}    // Код результата определения нового бара 
 datetime GetLastDay() const {return(m_last_day_number);}   // 18:00 последнего дня
 datetime GetLastMonth() const {return(m_last_month_number);}  // Дата и время определния последнего месяца
 string GetComment() const {return(m_comment);}    // Комментарий выполнения
 string GetSymbol() const {return(_symbol);}     // Имя инструмента
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}     // Период графика
 bool isInit() const {return(isMonthInit && isDayInit);}  // Инициализация завершна
//--- Методы инициализации защищенных данных:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = (period==PERIOD_CURRENT) ? Period() : period; }

//--- Рабочие методы класса
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
void CDynamo::CDynamo(int deltaFast, int deltaSlow, int deltaStep, int dayStep, int monthStep, int volume, double factor, int percentage, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow),
                      _deltaStep(deltaStep), _dayStep(dayStep), _monthStep(monthStep),
                      _volume(volume), _factor(factor), _percentage(percentage), _slowPeriod(slowPeriod)
  {
   m_retcode = 0;         // Код результата определения нового бара 
   m_last_day_number = TimeCurrent();       // Инициализируем день текущим днем
   m_last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // Инициализируем месяц текущим месяцем
   m_comment = "";        // Комментарий выполнения
   isDayInit = false;
   isMonthInit = false;
   _symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   _period = Period();   // Период графика, по умолчанию период текущего графика
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
 
 if(GetHours(current_time) < 18)
 {
  m_last_day_number = current_time;
  return(-1);
 }
  
 if (GetHours(m_last_day_number) < 18 && GetHours(current_time) >= 18) 
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
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // прошло 30 дней
 {
  if (GetHours(current_time) >= 18) // Новый месяц начинается в 18 часов
  { 
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
 if (isNewDay() > 0) // Если случился новый день
 {
  //PrintFormat("%s Новый день %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  _deltaFast = _deltaFastBase;
  prevDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  fastVol = NormalizeDouble(slowVol * _deltaFast * _factor * _percentage * _factor, 2);
  isDayInit = true;
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
  //PrintFormat("%s Новый месяц %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));
  _deltaSlow = _deltaSlowBase;
  prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  isMonthInit = true;
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
 if (_deltaFast < 100 && GreatDoubles(currentPrice, prevDayPrice + _dayStep*Point()))
 {
  prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _deltaStep;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if (_deltaFast > 0 && LessDoubles(currentPrice, prevDayPrice - _dayStep*Point()))
 {
  prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _deltaStep;
  //PrintFormat("%s Новая дневная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 
 if (_deltaSlow < 100 && GreatDoubles(currentPrice, prevMonthPrice + _monthStep*Point()))
 {
  _deltaSlow = _deltaSlow + _deltaStep;
  prevMonthPrice = currentPrice;
  //PrintFormat("%s Новая месячная дельта %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if (_deltaSlow > 0 && LessDoubles(currentPrice, prevMonthPrice - _monthStep*Point()))
 {
  prevMonthPrice = currentPrice;
  
  if (_deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _deltaStep;
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
 slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 fastVol = NormalizeDouble(slowVol * _deltaFast * _factor, 2);
 //PrintFormat("%s большой объем %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  slowVol, _deltaSlow);
 //PrintFormat("%s малый объем %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), fastVol, _deltaFast);
 return (slowVol - fastVol); 
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
  type = ORDER_TYPE_BUY;
  price = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 }
 else
 {
  type = ORDER_TYPE_SELL;
  price = SymbolInfoDouble(_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = _symbol;
 request.volume = MathAbs(volume);
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
