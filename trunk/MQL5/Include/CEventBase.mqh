//+------------------------------------------------------------------+
//|                                                        Event.mqh |
//|                                           Copyright 2014, denkir |
//|                           https://login.mql5.com/ru/users/denkir |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, denkir"
#property link      "https://login.mql5.com/ru/users/denkir"
#property version   "1.00"

//+------------------------------------------------------------------+
//| подключение библиотек                                            |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>                                       // дл€ лога
//+------------------------------------------------------------------+
//| A custom event type enumeration                                  |
//+------------------------------------------------------------------+
enum ENUM_EVENT_TYPE
  {
   EVENT_TYPE_NULL=0,      // no event
   EVENT_TYPE_EXTREMUMS=1  // extremums event
  };
//+------------------------------------------------------------------+
//| A custom event data                                              |
//+------------------------------------------------------------------+
struct SEventData
  {
   long              lparam;
   double            dparam;
   string            sparam;
   //--- default constructor
   void SEventData::SEventData(void)
     {
      lparam=0;
      dparam=0.0;
      sparam=NULL;
     }
   //--- copy constructor
   void SEventData::SEventData(const SEventData &_src_data)
     {
      lparam=_src_data.lparam;
      dparam=_src_data.dparam;
      sparam=_src_data.sparam;
     }
   //--- assignment operator
   void operator=(const SEventData &_src_data)
     {
      lparam=_src_data.lparam;
      dparam=_src_data.dparam;
      sparam=_src_data.sparam;
     }
  };
  
class CEvent : public CObject
{
 public:
  ushort id;
  string name;
  
  void CEvent(ushort _id, string _name): id(_id), name(_name){};
};

class CEventBase : public CObject
  {
// защищенные пол€ класса
protected:
   ushort            start_id;   // изначальный код 
   ushort            _id;
   CArrayObj         *aEvents;
   //ushort            id_array[];    // массив id событий
   //string            name_array[];  // массив имен событий
   string            _symbol;       // символ
   ENUM_TIMEFRAMES   _period;       // таймфрейм      
   SEventData        _data;

private:
// приватные методы класса
   int  GetEventIndByName(string eventName);                     // возвращает  индекс ID событи€ в массиве по имени событи€
   int  GetSymbolCode(string symbol);                            // возвращает код символа по символу
   long GenerateEventID (string symbol,ENUM_TIMEFRAMES period);  // метод формирует код ID событи€ 

public:
   void CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this._id=0;
      this.start_id=startid;
      this._symbol = symbol;
      this._period = period;
      aEvents = new CArrayObj();
     };
   void ~CEventBase(void){};
   //--
   bool AddNewEvent(string eventName);   // метод добавл€ет новое событие по заданному символу и “‘ с заданным именем   
   
   bool Generate(long _chart_id, int _id_ind, SEventData &_data,
                 const bool _is_custom=true);                       // генератор событий по индексу 
   void Generate(string id_nam, SEventData &_data, 
                 const bool _is_custom = true);                     // генератор событий, проход€щий по всем графикам
                              
   string GenUniqEventName (string eventName);                      // генерирует уникальное им€ событи€ 
  };  
  
// возвращает индекс ID событи€ в массиве по имени событи€
int CEventBase::GetEventIndByName(string eventName)
 {
  for(int i = 0; i < aEvents.Total(); i++)
   {
    CEvent *event = aEvents.At(i);
    if (event.name == eventName)
     return (i);
   }
  return (-1); 
 }  
  
// функци€ возвращает код по символу
int CEventBase::GetSymbolCode (string symbol)
 {
    if (symbol == "EURUSD")
     return (1);
    if (symbol == "GBPUSD")
     return (2);
    if (symbol == "USDCHF")
     return (3);
    if (symbol == "USDJPY")
     return (4);
    if (symbol == "USDCAD")
     return (5);
    if (symbol == "AUDUSD")
     return (6);
  return (0); 
 }

// функци€, возвращающа€ код ID событи€
long CEventBase::GenerateEventID (string symbol,ENUM_TIMEFRAMES period)
 {
  int scode = GetSymbolCode(symbol);
  if (scode == 0)
   return (0);    // нет кода ID
  return (start_id + 100*int(period)+10*scode+aEvents.Total());   // возвращаем код ID событи€
 }   
  
// добавл€ет новое событие
bool CEventBase::AddNewEvent(string eventName)
 {
  long tmp_id;
  int ind;  // счетчик прохода по циклам
  string generatedName = GenUniqEventName(eventName);
  // если им€ не пустое, значит оно задано => нужно проверить его уникальность
  if (generatedName != "")
   {
    for (ind=0; ind<aEvents.Total(); ind++)
     {
      CEvent *event = aEvents.At(ind);
      if (event.name == generatedName)
       {
        Print("Ќе удалось добавить новое id событи€, поскольку задано не уникальное им€");
        return (false);
       }
     }
   }   
  tmp_id = GenerateEventID(_symbol, _period);
  if (tmp_id == 0)
   {
    Print("Ќе удалось добавить новое id событи€, поскольку не удалось его сгенерить");
    return (false);
   } 
  // проходим по буферу id дл€ проверки уникальности id
  for (ind=0; ind<aEvents.Total(); ind++)
   {
    CEvent *event = aEvents.At(ind);
    // если уже был подобный id
    if (event.id == tmp_id)
     {
      Print("Ќе удалось добавить новое id событи€, поскольку такой id уже существует Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",eventName );
      return (false);
     }
   }
  // добавл€ем новое id в буфер
  CEvent *event = new CEvent(tmp_id, generatedName);
  
  return (true);
 }  
  
//+------------------------------------------------------------------+
//| метод генератора событий                                         |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id, int _id_ind, SEventData &_data,
                          const bool _is_custom=true)
  {
   bool is_generated = true;
   // если индекс id событи€ в массиве не верен
   if (_id_ind < 0 || _id_ind >= aEvents.Total())
    {
     Print("Ќе верно задан индекс ID событи€");
     return (false);
    }
   // заполн€ем пол€ 
   CEvent *event = aEvents.At(_id_ind);
   this._id = (ushort)(CHARTEVENT_CUSTOM+event.id);
   this._data = _data;
   this._data.sparam = event.name; // сохран€ем им€ событи€
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id, event.id, this._data.lparam,
                                      this._data.dparam, this._data.sparam);
      if(!is_generated && _LastError!=4104)
         Print("Error while generating a custom event: ",_LastError);
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| метод генератора событий на все графики                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // проходим по всем открытым графикам с текущим символом и “‘ и генерируем дл€ них событи€
 long chart_id = ChartFirst();
 int ind;
 string eventName = GenUniqEventName(id_nam);
 _data.sparam = eventName;
 // ищем это событие по имении в буфере
 for (ind=0; ind<aEvents.Total(); ind++)
  {
   // если нашли событие по имени
   CEvent *event = aEvents.At(ind);
   if (event.name == eventName)
    {     
      // проходим по всем графикам и генерим событи€
      while (chart_id >= 0)
       {
        // генерим событие дл€ текущего графика
        int ind_id = GetEventIndByName(event.name);
        Generate(chart_id, ind_id, _data, _is_custom);
        chart_id = ChartNext(chart_id);      
       }  
      return;
    }
  }
} 

//+------------------------------------------------------------------+
//| метод генерирует уникальное им€ событи€                          |
//+------------------------------------------------------------------+
string CEventBase::GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _symbol + "_" + PeriodToString(_period));
 } 
 