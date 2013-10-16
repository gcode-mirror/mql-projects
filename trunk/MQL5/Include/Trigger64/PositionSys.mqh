//+------------------------------------------------------------------+
//|                                                  PositionSys.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "PositionEnum.mqh"
#include <StringUtilities.mqh>
//библиотека функций по работе с позицией
//+------------------------------------------------------------------+
//| класс для работы с позициями                                     |
//+------------------------------------------------------------------+  
class  PositionSys   
 {
   public: 
   void ZeroPositionProperties();    //очищает свойства позиции
   uint CurrentPositionTotalDeals(); //возвращает количество сделок текущей позиции
   double CurrentPositionFirstDealPrice(); //Возвращает цену первой сделки текущей позиции    
   double CurrentPositionLastDealPrice();  //Возвращает цену последней сделки текущей позиции    
   double CurrentPositionInitialVolume();  //Возвращает начальный объем текущей позиции    
   ulong CurrentPositionDuration(ENUM_POSITION_DURATION mode); //      
   void GetPositionProperties(string mask); //извлекает свойство позиции
   PositionSys(); //конструктор класса
  ~PositionSys(); //деструктор класса
 };
//+------------------------------------------------------------------+
//| Возвращает количество сделок текущей позиции                     |
//+------------------------------------------------------------------+
uint PositionSys::CurrentPositionTotalDeals()
  {
   int    total       =0;  // Всего сделок в списке выбранной истории
   int    count       =0;  // Счетчик сделок по символу позиции
   string deal_symbol =""; // символ сделки
//--- Если история позиции получена
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- Получим количество сделок в полученном списке
      total=HistoryDealsTotal();
      //--- Пройдем по всем сделкам в полученном списке
      for(int i=0; i<total; i++)
        {
         //--- Получим символ сделки
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- Если символ сделки и текущий символ совпадают, увеличим счетчик
         if(deal_symbol==_Symbol)
            count++;
        }
     }
   return(count);
  }
//+------------------------------------------------------------------+
//| Возвращает цену первой сделки текущей позиции                    |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionFirstDealPrice()
  {
   int      total       =0;    // Всего сделок в списке выбранной истории
   string   deal_symbol ="";   // символ сделки
   double   deal_price  =0.0;  // Цена сделки
   datetime deal_time   =NULL; // Время сделки
//--- Если история позиции получена
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- Получим количество сделок в полученном списке
      total=HistoryDealsTotal();
      //--- Пройдем по всем сделкам в полученном списке
      for(int i=0; i<total; i++)
        {
         //--- Получим цену сделки
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);
         //--- Получим символ сделки
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- Получим время сделки
         deal_time=(datetime)HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TIME);
         //--- Если время сделки и время открытия позиции равны, 
         //    а также равны символ сделки и текущий символ, выйдем из цикла
         if(deal_time==pos.time && deal_symbol==_Symbol)
         break;
        }
     }
//---
   return(deal_price);
  }
//+------------------------------------------------------------------+
//| Возвращает цену последней сделки текущей позиции                 |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionLastDealPrice()
  {
   int    total       =0;   // Всего сделок в списке выбранной истории
   string deal_symbol ="";  // Символ сделки 
   double deal_price  =0.0; // Цена
//--- Если история позиции получена
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- Получим количество сделок в полученном списке
      total=HistoryDealsTotal();
      //--- Пройдем по всем сделкам в полученном списке от последней сделки в списке к первой
      for(int i=total-1; i>=0; i--)
        {
         //--- Получим цену сделки
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);
         //--- Получим символ сделки
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- Если символ сделки и текущий символ равны, остановим цикл
         if(deal_symbol==_Symbol)
            break;
        }
     }
//---
   return(deal_price);
  }
//+------------------------------------------------------------------+
//| Возвращает начальный объем текущей позиции                       |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionInitialVolume()
  {
   int             total       =0;           // Всего сделок в списке выбранной истории
   ulong           ticket      =0;           // Тикет сделки
   ENUM_DEAL_ENTRY deal_entry  =WRONG_VALUE; // Способ изменения позиции
   bool            inout       =false;       // Признак наличия разворота позиции
   double          sum_volume  =0.0;         // Счетчик совокупного объема всех сделок кроме первой
   double          deal_volume =0.0;         // Объем сделки
   string          deal_symbol ="";          // Символ сделки 
   datetime        deal_time   =NULL;        // Время совершения сделки
//--- Если история позиции получена
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- Получим количество сделок в полученном списке
      total=HistoryDealsTotal();
      //--- Пройдем по всем сделкам в полученном списке от последней сделки в списке к первой
      for(int i=total-1; i>=0; i--)
        {
         //--- Если тикет ордера по его позиции в списке получен, то...
         if((ticket=HistoryDealGetTicket(i))>0)
           {
            //--- Получим объем сделки
            deal_volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
            //--- Получим способ изменения позиции
            deal_entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
            //--- Получим время совершения сделки
            deal_time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- Получим символ сделки
            deal_symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            //--- Когда время совершения сделки будет меньше или равно времени открытия позиции, выйдем из цикла
            if(deal_time<=pos.time)
               break;
            //--- иначе считаем совокупный объем сделок по символу позиции, кроме первой
            if(deal_symbol==_Symbol)
               sum_volume+=deal_volume;
           }
        }
     }
//--- Если способ изменения позиции - разворот
   if(deal_entry==DEAL_ENTRY_INOUT)
     {
      //--- Если объём позиции увеличивался/уменьшался
      //    То есть, сделок больше одной
      if(fabs(sum_volume)>0)
        {
         //--- Текущий объем минус объем всех сделок кроме первой
         double result=pos.volume-sum_volume;
         //--- Если итог больше нуля, вернем итог, иначе вернем текущий объем позиции         
         deal_volume=result>0 ? result : pos.volume;
        }
      //--- Если сделок кроме входа больше не было,
      if(sum_volume==0)
         deal_volume=pos.volume; // вернём текущий объем позиции
     }
//--- Вернем начальный объем позиции
   return(NormalizeDouble(deal_volume,2));
  }
//+------------------------------------------------------------------+
//| Возвращает длительность текущей позиции                          |
//+------------------------------------------------------------------+
ulong PositionSys::CurrentPositionDuration(ENUM_POSITION_DURATION mode)
  {
   ulong     result=0;   // Итоговый результат
   ulong     seconds=0;  // Количество секунд
//--- Вычислим длительность позиции в секундах
   seconds=TimeCurrent()-pos.time;
//---
   switch(mode)
     {
      case DAYS      : result=seconds/(60*60*24);   break; // Посчитаем кол-во дней
      case HOURS     : result=seconds/(60*60);      break; // Посчитаем кол-во часов
      case MINUTES   : result=seconds/60;           break; // Посчитаем кол-во минут
      case SECONDS   : result=seconds;              break; // Без расчетов (кол-во секунд)
      //---
      default        :
         Print(__FUNCTION__,"(): Передан неизвестный режим длительности!");
         return(0);
     }
//--- Вернем результат
   return(result); 
  }
//+------------------------------------------------------------------+
//| Преобразует длительность позиции в строку                        |
//+------------------------------------------------------------------+
void PositionSys::ZeroPositionProperties()
  {
   pos.symbol ="";
   pos.comment="";
   pos.magic=0;
   pos.price=0.0;
   pos.current_price=0.0;
   pos.sl=0.0;
   pos.tp         =0.0;
   pos.type       =WRONG_VALUE;
   pos.volume     =0.0;
   pos.commission =0.0;
   pos.swap       =0.0;
   pos.profit     =0.0;
   pos.time       =NULL;
   pos.id         =0;
  }
//+------------------------------------------------------------------+
//| Преобразует тип позиции в строку                                 |
//+------------------------------------------------------------------+
void PositionSys::GetPositionProperties(string mask) //метод возвращения свойства позиции
  {
//--- Узнаем, есть ли позиция
   pos.exists=PositionSelect(_Symbol);
//--- Если позиция есть, получим её свойства
   if(pos.exists)
     {    
      if(StringGetCharacter(mask,0)=='1')
         {
          pos.time=(datetime)PositionGetInteger(POSITION_TIME);
          pos.total_deals=CurrentPositionTotalDeals();             
         }                            
      if(StringGetCharacter(mask,1)=='1') pos.symbol=PositionGetString(POSITION_SYMBOL);                 
      if(StringGetCharacter(mask,2)=='1') pos.magic=PositionGetInteger(POSITION_MAGIC);                  
      if(StringGetCharacter(mask,3)=='1') pos.comment=PositionGetString(POSITION_COMMENT);               
      if(StringGetCharacter(mask,4)=='1') pos.swap=PositionGetDouble(POSITION_SWAP);                      
      if(StringGetCharacter(mask,5)=='1') pos.commission=PositionGetDouble(POSITION_COMMISSION);          
      if(StringGetCharacter(mask,6)=='1')
         {
          pos.time=(datetime)PositionGetInteger(POSITION_TIME);
          pos.first_deal_price=CurrentPositionFirstDealPrice();
         }                                 
      if(StringGetCharacter(mask,7)=='1') pos.price=PositionGetDouble(POSITION_PRICE_OPEN);               
      if(StringGetCharacter(mask,8)=='1') pos.current_price=PositionGetDouble(POSITION_PRICE_CURRENT);    
      if(StringGetCharacter(mask,9)=='1')
         {
          pos.time=(datetime)PositionGetInteger(POSITION_TIME);
          pos.last_deal_price=CurrentPositionLastDealPrice();           
         }                        
      if(StringGetCharacter(mask,10)=='1') pos.profit=PositionGetDouble(POSITION_PROFIT);                  
      if(StringGetCharacter(mask,11)=='1') pos.volume=PositionGetDouble(POSITION_VOLUME);                  
      if(StringGetCharacter(mask,12)=='1')
         {
          pos.time=(datetime)PositionGetInteger(POSITION_TIME);
          pos.initial_volume=CurrentPositionInitialVolume();          
         }                           
      if(StringGetCharacter(mask,13)=='1') pos.sl=PositionGetDouble(POSITION_SL);                          
      if(StringGetCharacter(mask,14)=='1') pos.tp=PositionGetDouble(POSITION_TP);                          
      if(StringGetCharacter(mask,15)=='1') pos.time=(datetime)PositionGetInteger(POSITION_TIME);           
      if(StringGetCharacter(mask,16)=='1') pos.duration=CurrentPositionDuration(SECONDS);                  
      if(StringGetCharacter(mask,17)=='1') pos.id=PositionGetInteger(POSITION_IDENTIFIER);                 
      if(StringGetCharacter(mask,18)=='1') pos.type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   
     }
//--- Если позиции нет, обнулим переменные свойств позиции
   else
      ZeroPositionProperties();
  }
//+------------------------------------------------------------------+
//| Конструктор класса                                               |
//+------------------------------------------------------------------+  
PositionSys::PositionSys(void) 
   {
   
   }
//+------------------------------------------------------------------+
//| Деструктор класса                                                |
//+------------------------------------------------------------------+   
PositionSys::~PositionSys(void) //деструктор класса
   {
   
   }