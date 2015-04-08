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
#include <StringUtilities.mqh>
#include <CLog.mqh>                                       // для лога
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
   void  SEventData:: SEventData(const SEventData &_src_data)
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

class CEventBase : public CObject
  {
// защищенные поля класса
protected:
   ENUM_EVENT_TYPE   m_type;
   ushort            start_id;   // изначальный код 
   ushort            m_id;
   ushort            id_array[]; // массив id событий
   string            id_name[];  // массив имен событий
   int               id_count;   // количество id событий
   string            _symbol;    // символ
   ENUM_TIMEFRAMES   _period;    // таймфрейм      
   SEventData        m_data;

private:
// приватные методы класса
   int  GetEventIndByName(string eventName); // возвращает  индекс ID события в массиве по имени события
   int  GetSymbolCode(string symbol);   // возвращает код символа по символу
   long GenerateIsNewBarEventID (string symbol,ENUM_TIMEFRAMES period);  // метод формирует код ID события 

public:
   void              CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this.m_id=0;
      this.m_type=EVENT_TYPE_NULL;
      this.start_id=start_id;
      this.id_count = 0; 
      this._symbol = symbol;
      this._period = period;
     };
   void             ~CEventBase(void){};
   //--
   bool AddNewEvent(string eventName);   // метод добавляет новое событие по заданному символу и ТФ с заданным именем   
   
   bool              Generate(long _chart_id, int _id_ind, SEventData &_data,
                              const bool _is_custom=true);                       // генератор событий по индексу
   bool              Generate(long _chart_id,string id_nam,SEventData &_data, 
                              const bool _is_custom=true);                       // генераторв событий по имени события 
  
   void              Generate(string id_nam, SEventData &_data, 
                              const bool _is_custom = true);                     // генератор событий, проходящий по всем графикам
                              
   ushort            GetId(void) {return this.m_id;};                            // возвращает ID события
   
   string            GenUniqEventName (string eventName);                        // генерирует уникальное имя события 
                                               
   void  PrintAllNames();                                            
   
private:
   virtual bool      Validate(void) {return true;};
  };  
  
// возвращает индекс ID события в массиве по имени события
int CEventBase::GetEventIndByName(string eventName)
 {
  for (int ind=0;ind<id_count;ind++)
   {
    if (id_name[ind] == eventName)
     return (ind);
   }
  return (-1); 
 }  
  
// функция возвращает код по символу
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

// функция, возвращающая код ID события
long CEventBase::GenerateIsNewBarEventID (string symbol,ENUM_TIMEFRAMES period)
 {
  int scode = GetSymbolCode(symbol);
  if (scode == 0)
   return (0);    // нет кода ID
  return (start_id + 100*int(period)+10*scode+id_count);   // возвращаем код ID события
 }   
  
// добавляет новое событие
bool CEventBase::AddNewEvent(string eventName)
 {
  long tmp_id;
  int ind;  // счетчик прохода по циклам
  string generatedName = GenUniqEventName(eventName);
  // если имя не пустое, значит оно задано => нужно проверить его уникальность
  if (generatedName != "")
   {
    for (ind=0;ind<id_count;ind++)
     {
      if (id_name[ind] == generatedName)
       {
        Print("Не удалось добавить новое id события, поскольку задано не уникальное имя");
        return (false);
       }
     }
   }   
  tmp_id = GenerateIsNewBarEventID(_symbol, _period);
  if (tmp_id == 0)
   {
    Print("Не удалось добавить новое id события, поскольку не удалось его сгенерить");
    return (false);
   } 
  // проходим по буферу id для проверки уникальности id
  for (ind=0;ind<id_count;ind++)
   {
    // если уже был подобный id
    if (id_array[ind]==tmp_id)
     {
      Print("Не удалось добавить новое id события, поскольку такой id уже существует Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",eventName );
      return (false);
     }
   }
  // добавляем новое id в буфер
  
  ArrayResize(id_array,id_count+1);
  ArrayResize(id_name,id_count+1);
  id_array[id_count] = tmp_id;
  id_name[id_count]  = generatedName;
  id_count++;
  
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
   if (_id_ind < 0 || _id_ind >= id_count)
    {
     Print("Не верно задан индекс ID события");
     return (false);
    }
   // заполняем поля 
   this.m_id = (ushort)(CHARTEVENT_CUSTOM+id_array[_id_ind]);
   this.m_data = _data;
   this.m_data.sparam = id_name[_id_ind]; // сохраняем имя события
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id,id_array[_id_ind],this.m_data.lparam,
                                    this.m_data.dparam,this.m_data.sparam);
      if(!is_generated && _LastError!=4104)
         Print("Error while generating a custom event: ",_LastError);
     }
   if(is_generated)
     {
      is_generated = this.Validate();
      if(!is_generated)
         this.m_id = 0;
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| метод генератора событий по имени                                |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id,string id_nam,SEventData &_data,const bool _is_custom=true)
 {
  int ind_id = GetEventIndByName(id_nam);   // получаем индекс ID события в массиве по имени события
  // если не найден индекс
  if ( ind_id == -1)
   {
    Print("Не удалось найти индекс события по имени ",id_nam);
    return (false);
   }
  Generate(_chart_id,ind_id,_data,_is_custom);
  return (true);
 }

//+------------------------------------------------------------------+
//| метод генератора событий на все графики                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // проходим по всем открытым графикам с текущим символом и ТФ и генерируем для них события
 long z = ChartFirst();
 int ind;
 string eventName = GenUniqEventName(id_nam);
 _data.sparam = eventName;
 // ищем это событие по имении в буфере
 for (ind=0;ind<id_count;ind++)
  {
   // если нашли событие по имени
   if (id_name[ind] == eventName)
    {     
      // проходим по всем графикам и генерим события
      while (z >= 0)
       {
        // генерим событие для текущего графика
        Generate(z,id_name[ind],_data,_is_custom);
        z = ChartNext(z);      
       }  
      return;
    }
  }
} 

//+------------------------------------------------------------------+
//| метод генерирует уникальное имя события                          |
//+------------------------------------------------------------------+
string CEventBase::GenUniqEventName(string eventName)
 {
  return ( eventName + "_" + _symbol + "_" + PeriodToString(_period) );
 } 
 
void CEventBase::PrintAllNames(void)
 {
  for(int i=0;i<ArraySize(id_name);i++)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%i имя = %s",i,id_name[i]) );  
   }
 }