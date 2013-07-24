//+------------------------------------------------------------------+
//|                                                      CDynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "config_Dynamo.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CDynamo
{
protected:
 MqlDateTime m_day_time;          // Время
 MqlDateTime m_last_day_number;   // Номер последнего определенного дня
 MqlDateTime m_last_month_number;   // Номер последнего определенного месяца
 
 string m_symbol;           // Имя инструмента
 ENUM_TIMEFRAMES m_period;           // Период графика
      
 uint m_retcode;        // Код результата определения нового дня 
 int m_new_day_number;  // Номер нового дня (0-6)
 int m_new_month_number;  // Номер нового дня (0-6)
 string m_comment;        // Комментарий выполнения
 
 int deltaFast;  // дельта для расчета объема "дневной" торговли
 int deltaSlow;  // дельта для расчета объема "месячной" торговли
 double fastVol;  // объем для дневной торговли
 double slowVol;  // объем для месячной торговли
 
 int currentLevelDay; // текущий уровень цены дня
 int currentLevelMonth; // текущий уровень цены месяца
 
 // массив вычисленных дневных граничных цен от цены старта торгов дня
 double currentDaily[21];
 // массив вычисленных месячных граничных цен от цены старта торгов месяца
 double currentMonth[21];

public:
//--- Конструкторы
 void CDynamo();      // Конструктор CDynamo
 void CDynamo(string symbol);      // Конструктор CDynamo с параметрами
 void CDynamo(ENUM_TIMEFRAMES period);      // Конструктор CDynamo с параметрами
 void CDynamo(string symbol, ENUM_TIMEFRAMES period);      // Конструктор CDynamo с параметрами
 
//--- Методы доступа к защищенным данным:
 uint GetRetCode() const {return(m_retcode);}    // Код результата определения нового бара 
 MqlDateTime GetLastTime() const {return(m_day_time);}
 MqlDateTime GetLastDay() const {return(m_last_day_number);}  // Номер последнего определенного дня
 int GetNewDay() const {return(m_new_day_number);}    // Номер нового дня
 MqlDateTime GetLastMonth() const {return(m_last_month_number);}  // Номер последнего определенного дня
 int GetNewMonth() const {return(m_new_month_number);}    // Номер нового дня
 string GetComment() const {return(m_comment);}    // Комментарий выполнения
 string GetSymbol() const {return(m_symbol);}     // Имя инструмента
 ENUM_TIMEFRAMES GetPeriod() const {return(m_period);}     // Период графика
 
//--- Методы инициализации защищенных данных:  
 void SetSymbol(string symbol) {m_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {m_period = (period==PERIOD_CURRENT) ? Period() : period; }

//--- Рабочие методы класса
 bool isNewDay();
 bool isNewMonth();
 int MonWenFriEighteen();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(double &dstArray[], int &srcArray[]);
 double RecountVolume();
 void RecountDelta();
 bool CorrectOrder(double volume);
};

//+------------------------------------------------------------------+
//| Конструктор CDynamo.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo()
  {
   m_retcode = 0;         // Код результата определения нового бара 
   ZeroMemory(m_last_day_number);    // Время открытия последнего бара
   m_new_day_number = 0;        // Количество новых баров
   ZeroMemory(m_last_month_number);    // Время открытия последнего бара
   m_new_month_number = 0;        // Количество новых баров
   m_comment = "";        // Комментарий выполнения
   m_symbol = Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   m_period = Period();   // Период графика, по умолчанию период текущего графика
  }
  
//+------------------------------------------------------------------+
//| Конструктор CDynamo с параметрами                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(string symbol)
  {
   m_retcode = 0;         // Код результата определения нового бара 
   ZeroMemory(m_last_day_number);    // Время открытия последнего бара
   m_new_day_number = 0;        // Количество новых баров
   ZeroMemory(m_last_month_number);    // Время открытия последнего бара
   m_new_month_number = 0;        // Количество новых баров
   m_comment = "";        // Комментарий выполнения
   m_symbol=symbol;   // Имя инструмента, по умолчанию символ текущего графика
   m_period=Period();   // Период графика, по умолчанию период текущего графика    
  }
//+------------------------------------------------------------------+
//| Конструктор CDynamo с параметрами                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(ENUM_TIMEFRAMES period)
  {
   m_retcode = 0;         // Код результата определения нового бара 
   ZeroMemory(m_last_day_number);    // Время открытия последнего бара
   m_new_day_number = 0;        // Количество новых баров
   ZeroMemory(m_last_month_number);    // Время открытия последнего бара
   m_new_month_number = 0;        // Количество новых баров
   m_comment = "";        // Комментарий выполнения
   m_symbol=Symbol();   // Имя инструмента, по умолчанию символ текущего графика
   m_period=period;   // Период графика, по умолчанию период текущего графика    
  }

//+------------------------------------------------------------------+
//| Конструктор CDynamo с параметрами                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(string symbol, ENUM_TIMEFRAMES period)
  {
   m_retcode = 0;         // Код результата определения нового бара 
   ZeroMemory(m_last_day_number);    // Время открытия последнего бара
   m_new_day_number = 0;        // Количество новых баров
   ZeroMemory(m_last_month_number);    // Время открытия последнего бара
   m_new_month_number = 0;        // Количество новых баров
   m_comment = "";        // Комментарий выполнения
   m_symbol=symbol;   // Имя инструмента, по умолчанию символ текущего графика
   m_period=period;   // Период графика, по умолчанию период текущего графика    
  }

//+------------------------------------------------------------------+
//| Запрос на появление нового дня.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если новый день                                 |
//|         false  - если не новый день или получили ошибку          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::isNewDay()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
      
   //--- если это первый вызов 
   if(m_last_day_number.year == 0)
     {  
      log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "Первый вызов");
      m_last_day_number = current_time; //--- запомним текущий день и выйдем
      log_file.Write(LOG_DEBUG, StringFormat("%s Инициализация m_last_day_number=%s", MakeFunctionPrefix(__FUNCTION__), TimeToString(StructToTime(m_last_day_number))));
      return(false);
     }  
     
   //--- Проверяем появление нового дня: 
   if(m_last_day_number.year < current_time.year || (m_last_day_number.year == current_time.year && m_last_day_number.day_of_year < current_time.day_of_year))
     { 
      m_last_day_number = current_time; // запоминаем текущий день
      //log_file.Write(LOG_DEBUG, StringFormat("%s Проверка появления нового дня завершилась успешно", MakeFunctionPrefix(__FUNCTION__)));
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
bool CDynamo::isNewMonth()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
   
   //--- если это первый вызов 
   if(m_last_month_number.year == 0)
     {  
      log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "Первый вызов");
      m_last_month_number = current_time; //--- запомним текущий месяц и выйдем
      log_file.Write(LOG_DEBUG, StringFormat("%s Инициализация m_last_month_number=%s", MakeFunctionPrefix(__FUNCTION__), TimeToString(StructToTime(m_last_month_number))));
      return(false);
     }  
     
   //--- Проверяем появление нового месяца: 
   if((m_last_month_number.year < current_time.year && m_last_month_number.day == current_time.day)
    ||(m_last_month_number.year == current_time.year && m_last_month_number.mon < current_time.mon && m_last_month_number.day == current_time.day))
     { 
      m_last_month_number = current_time; // запоминаем текущий день
      //log_file.Write(LOG_DEBUG, StringFormat("%s Проверка появления нового месяца завершилась успешно", MakeFunctionPrefix(__FUNCTION__)));
      return(true);
     }
  
   //--- дошли до этого места - значит месяц не новый
   return(false);
  }

//+------------------------------------------------------------------+
//| Запрос на 18:00 понедельника, среды или пятницы.                 |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CDynamo::MonWenFriEighteen()
{
 MqlDateTime current_time;
 TimeToStruct(TimeCurrent(), current_time);
 
   //--- если это первый вызов 
 if(m_day_time.year == 0)
 {  
  log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "Первый вызов");
  m_day_time = current_time; //--- запомним последний месяц и выйдем
  log_file.Write(LOG_DEBUG, StringFormat("%s Инициализация m_day_time=%s", MakeFunctionPrefix(__FUNCTION__), TimeToString(StructToTime(m_day_time))));
  return(false);
 }  
 
 if (current_time.hour < 18)
 {
  m_day_time = current_time;
  return(-1);
 }
 if (m_day_time.hour < 18 && current_time.hour >= 18) 
 {
  m_day_time = current_time;
  return(m_day_time.day_of_week);
 }

 //--- дошли до этого места - значит день не новый
 return(-1);
}

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого дня              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitDayTrade()
{
 if (MonWenFriEighteen() > 0)
 {
  if (m_day_time.day_of_week == 1 || m_day_time.day_of_week == 3 || m_day_time.day_of_week == 5)
  {
   deltaFast = FAST_DELTA;
   currentLevelDay = 10;
   slowVol = NormalizeDouble(VOLUME * FACTOR * deltaSlow, 2);
   fastVol = NormalizeDouble(slowVol * deltaFast * FACTOR, 2);
   FillArrayWithPrices(currentDaily, firstDay);
   log_file.Write(LOG_DEBUG, StringFormat("%s %s : %02d:%02d", MakeFunctionPrefix(__FUNCTION__), DayOfWeekToString(m_day_time.day_of_week), GetLastTime().hour, GetLastTime().min));
  }
  if (m_day_time.day_of_week == 0 || m_day_time.day_of_week == 2 || m_day_time.day_of_week == 4 || m_day_time.day_of_week == 6)
  {
   FillArrayWithPrices(currentDaily, secondDay);
   log_file.Write(LOG_DEBUG, StringFormat("%s %s : %02d:%02d", MakeFunctionPrefix(__FUNCTION__), DayOfWeekToString(m_day_time.day_of_week), GetLastTime().hour, GetLastTime().min));
  }
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
  deltaSlow = 0;
  currentLevelMonth = 0;
  slowVol = NormalizeDouble(VOLUME * deltaSlow * FACTOR, 2);
  FillArrayWithPrices(currentMonth, firstMonth);
  InitDayTrade();
  log_file.Write(LOG_DEBUG, StringFormat("%s %02d.%02d : %02d:%02d", MakeFunctionPrefix(__FUNCTION__), GetLastTime().mon, GetLastTime().day, GetLastTime().hour, GetLastTime().min));
 }
}

//+------------------------------------------------------------------+
//| Заполнение массива граничных цен от текущей цены                 |
//| INPUT:  dstArray - массив для значений цен                       |
//|         srcArray - массив со значениями границ в пунктах         |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::FillArrayWithPrices(double &dstArray[], int &srcArray[])
{
 double openPrice = SymbolInfoDouble(m_symbol, SYMBOL_LAST);
 for (int i = 0; i < 21; ++i)
 {
  dstArray[i] = openPrice + srcArray[i]*Point();
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
 double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_LAST);
 if (currentLevelDay < 20)
  if (currentPrice > currentDaily[currentLevelDay + 1])
  {
   deltaFast = deltaFast + 5;
   currentLevelDay++;
  }
 if (currentLevelDay > 0)
  if (currentPrice < currentDaily[currentLevelDay - 1])
  {
   deltaFast = deltaFast - 5;
   currentLevelDay--;
  }
 if (currentLevelMonth < 20) 
  if (currentPrice > currentMonth[currentLevelMonth + 1])
  {
   deltaSlow = deltaSlow + 5;
   currentLevelMonth++;
  }
 if (currentLevelMonth > 0)
  if (currentPrice < currentMonth[currentLevelMonth - 1])
  {
   deltaSlow = deltaSlow - 5;
   currentLevelMonth--;
  }
}

double CDynamo::RecountVolume()
{
 slowVol = NormalizeDouble(VOLUME * FACTOR * deltaSlow, 2);
 fastVol = NormalizeDouble(slowVol * deltaFast * FACTOR, 2);
 return (slowVol - fastVol); 
}

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
  price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
 }
 else
 {
  type = ORDER_TYPE_SELL;
  price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = m_symbol;
 request.volume = MathAbs(volume);
 request.price = price;
 request.sl = 0;
 request.tp = 0;
 request.deviation = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD); 
 request.type = type;
 request.type_filling = ORDER_FILLING_FOK;
 return (OrderSend(request, result));
}
