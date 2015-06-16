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
#include <CLog.mqh>                                       // для лога
#include <Strings\String.mqh>
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
// защищенные поля класса
protected:
   ushort            start_id;   // изначальный код 
   
   ushort            _counter;        // [0-9] временно, ToDo создать уникальный номер события
   string            _symbolmass[10]; // удалить убожество вместе с _counter

   CArrayObj         *aEvents;
   //ushort            id_array[];    // массив id событий
   //string            name_array[];  // массив имен событий
   string            _symbol;       // символ
   ENUM_TIMEFRAMES   _period;       // таймфрейм      
   SEventData        _data;

private:
// приватные методы класса
   int  GetEventIndByName(string event_name);                     // возвращает  индекс ID события в массиве по имени события
   long GenerateEventID (string event_name);  // метод формирует код ID события 

public:
   void CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this.start_id=startid;
      this._symbol = symbol;
      this._period = period;
      this._counter = 0;
      aEvents = new CArrayObj();
      log_file.Write(LOG_DEBUG, StringFormat("Был создан объект CEventBase с параметрами start_id = %i symbol  = %s period = %s", startid, symbol, PeriodToString(period)));
     };
   void ~CEventBase(void) // Добавила 16.06.2015 до этого работало неплохо, может помочь с 4001
   {
    aEvents.Clear();
    delete aEvents;
   };
   //--
   bool AddNewEvent(string event_name);   // метод добавляет новое событие по заданному символу и ТФ с заданным именем   
   
   bool Generate(long _chart_id, int _id_ind, SEventData &_data,
                 const bool _is_custom=true);                       // генератор событий по индексу 
   void Generate(string event_name, SEventData &_data, 
                 const bool _is_custom = true);                     // генератор событий, проходящий по всем графикам
                              
   string GenUniqEventName (string event_name);                      // генерирует уникальное имя события 
  };  
  
// возвращает индекс ID события в массиве по имени события
int CEventBase::GetEventIndByName(string event_name)
 {
  for(int i = 0; i < aEvents.Total(); i++)
   {
    CEvent *event = aEvents.At(i);
    if (event.name == event_name)
     return (i);
   }
  return (-1); 
 }  

// функция, возвращающая код ID события
long CEventBase::GenerateEventID (string event_name)
 {
  ulong ulHash = 5381;
  for(int i = StringLen(event_name) - 1; i >= 0; i--)
  {
   ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(event_name,i);
  }
  return MathAbs((long)ulHash);
 }   
  
// добавляет новое событие
bool CEventBase::AddNewEvent(string event_name)
 {
  long tmp_id;
  int ind;  // счетчик прохода по циклам
  string generatedName = GenUniqEventName(event_name);
  // если имя не пустое, значит оно задано => нужно проверить его уникальность
  if (generatedName != "")
   {
    for (ind=0; ind<aEvents.Total(); ind++)
     {
      CEvent *event = aEvents.At(ind);
      if (event.name == generatedName)
       {
        PrintFormat("%s Не удалось добавить новое id события, поскольку задано не уникальное имя", MakeFunctionPrefix(__FUNCTION__));
        return (false);
       }
     }
   }   
  tmp_id = GenerateEventID(generatedName);
  if (tmp_id == 0)
   {
    PrintFormat("%s Не удалось добавить новое id события, поскольку не удалось его сгенерить", MakeFunctionPrefix(__FUNCTION__));
    return (false);
   } 
  // проходим по буферу id для проверки уникальности id
  for (ind=0; ind<aEvents.Total(); ind++)
   {
    CEvent *event = aEvents.At(ind);
    // если уже был подобный id
    if (event.id == tmp_id)
     {
      Print("Не удалось добавить новое id события, поскольку такой id уже существует Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",event_name );
      return (false);
     }
   }
  // добавляем новое событие в буфер
  CEvent *event = new CEvent(tmp_id, generatedName);
  aEvents.Add(event);
  return (true);
 }  
  
//+------------------------------------------------------------------+
//| метод генератора событий                                         |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id, int _id_ind, SEventData &_data,
                          const bool _is_custom=true)
  {
   bool is_generated = true;
   // если индекс id события в массиве не верен
   if (_id_ind < 0 || _id_ind >= aEvents.Total())
    {
     Print("Не верно задан индекс ID события");
     return (false);
    }
   // заполняем поля 
   CEvent *event = aEvents.At(_id_ind);
   this._data = _data;
   this._data.sparam = event.name; // сохраняем имя события
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id, event.id, this._data.lparam,
                                      this._data.dparam, this._data.sparam);
      if(!is_generated && _LastError != 4104)
         {
          Print("is_generated = ", BoolToString(is_generated));
          PrintFormat("%s Error while generating a custom event: %d", __FUNCTION__,_LastError);
          Print( ChartSymbol(_chart_id)," ",PeriodToString(ChartPeriod(_chart_id)), "Ошибка! _chart_id =", _chart_id, " event.id = ", event.id, " data.dparam = " ,this._data.dparam, " data.sparam = ", this._data.sparam);
          log_file.Write(LOG_DEBUG, StringFormat("time = %s", TimeToString(TimeCurrent())));
          log_file.Write(LOG_DEBUG, StringFormat("is_generated = %s", BoolToString(is_generated)));
          log_file.Write(LOG_DEBUG, StringFormat("%s Error while generating a custom event: %d", __FUNCTION__,_LastError));
          log_file.Write(LOG_DEBUG, StringFormat("chart_id = %s , ChartPeriod = %s  Ошибка! event.id = %d data.dparam = %f data.sparam = %s", ChartSymbol(_chart_id),PeriodToString(ChartPeriod(_chart_id)), event.id, this._data.dparam,  this._data.sparam));
         }
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| метод генератора событий на все графики                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string event_name, SEventData &_data, const bool _is_custom = true)
{
 // проходим по всем открытым графикам с текущим символом и ТФ и генерируем для них события
 long chart_id = ChartFirst();
 _data.sparam = GenUniqEventName(event_name);
 
 // ищем это событие по имении в буфере
 for (int ind=0; ind < aEvents.Total(); ind++)
  {
   // если нашли событие по имени
   CEvent *event = aEvents.At(ind);
   if (event.name == _data.sparam)
    {     
      // проходим по всем графикам и генерим события
      while (chart_id >= 0)
       {
        // генерим событие для текущего графика
        int ind_id = GetEventIndByName(event.name);
        Generate(chart_id, ind_id, _data, _is_custom);
        chart_id = ChartNext(chart_id);      
       }  
      return;
    }
  }
} 

//+------------------------------------------------------------------+
//| метод генерирует уникальное имя события                          |
//+------------------------------------------------------------------+
string CEventBase::GenUniqEventName(string event_name)
 {
  return (event_name + "_" + _symbol + "_" + PeriodToString(_period));
 } 
 