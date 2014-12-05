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
protected:
   ENUM_EVENT_TYPE   m_type;
   ushort            m_id;
   SEventData        m_data;

public:
   void              CEventBase(void)
     {
      this.m_id=0;
      this.m_type=EVENT_TYPE_NULL;
     };
   void             ~CEventBase(void){};
   //--
   bool              Generate(long _chart_id,ushort _event_id, SEventData &_data,
                              const bool _is_custom=true);                       // генератор событий
   ushort            GetId(void) {return this.m_id;};                            // возвращает ID события

private:
   virtual bool      Validate(void) {return true;};
  };
//+------------------------------------------------------------------+
//| метод генератора событий                                         |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id, ushort _event_id, SEventData &_data,
                          const bool _is_custom=true)
  {
   bool is_generated=true;
   this.m_id=(ushort)(CHARTEVENT_CUSTOM+_event_id);
   this.m_data=_data;
   if(_is_custom)
     {
      ResetLastError();
      is_generated=EventChartCustom(_chart_id,_event_id,this.m_data.lparam,
                                    this.m_data.dparam,this.m_data.sparam);
      if(!is_generated && _LastError!=4104)
         Print("Error while generating a custom event: ",_LastError);
     }
   if(is_generated)
     {
      is_generated=this.Validate();
      if(!is_generated)
         this.m_id=0;
     }
   return is_generated;
  }