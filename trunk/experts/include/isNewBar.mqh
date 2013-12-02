//+------------------------------------------------------------------+
//|                                                     isNewBar.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//===============================================================================
// Функция контроля нового бара
//===============================================================================
bool isNewBar(int timeframe, string symb = "")
 {
  int index;
  if (symb == "") symb = Symbol();
  switch(timeframe)
  {
   case PERIOD_D1:
       index = 0;
       break;
   case PERIOD_H4:
       index = 1;
       break;
   case PERIOD_H1:
       index = 2;
       break;
   case PERIOD_M30:
       index = 3;
       break;
   case PERIOD_M15:
       index = 4;
       break;
   case PERIOD_M5:
       index = 5;
       break;
   case PERIOD_M1:
       index = 6;
       break;
   default:
       Alert("isNewBar: Вы ошиблись с таймфреймом");
       return(false);
  }
  
    static int PrevTime[7];
    if (PrevTime[index]==iTime(symb,timeframe,0)) return(false);
    PrevTime[index]=iTime(symb,timeframe,0);
    return(true);
}

//+------------------------------------------------------------------+
//| Запрос на появление нового месяца.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если новый месяц                                |
//|         false  - если не новый месяц или получили ошибку         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool isNewMonth()
{
 datetime current_time = TimeCurrent();
 
 //--- Проверяем появление нового месяца: 
 if (m_last_month_number < current_time - slowPeriod*24*60*60)  // прошло _slowPeriod дней
 {
  if (TimeHour(current_time) >= startHour) // Новый месяц начинается в _startHour часов
  { 
   m_last_month_number = current_time; // запоминаем текущий день
   return(true);
  }
 }
 //--- дошли до этого места - значит месяц не новый
 return(false);
}

//+------------------------------------------------------------------+
//| Проверка на время обновления младщей дельта                      |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - если пришло время                               |
//|         false  - если время не пришло или получили ошибку        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool timeToUpdateFastDelta()
{
 datetime current_time = TimeCurrent();
 //--- Проверяем появление нового месяца: 
 if (m_last_day_number < current_time - fastPeriod*60*60)  // прошло _fastPeriod часов
 {
  if (TimeHour(current_time) >= startHour) // Новый день начинается в _startHour часов
  { 
   m_last_day_number = current_time; // запоминаем текущий день
   return(true);
  }
 }

 //--- дошли до этого места - значит день не новый
 return(false);
}