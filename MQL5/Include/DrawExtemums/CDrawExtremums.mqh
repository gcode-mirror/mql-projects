//+------------------------------------------------------------------+
//|                                                   CExtremums.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//|  Класс  для получения данных индикатора DrawExtremums            |
//+------------------------------------------------------------------+

// перечисление типов эктсремумов
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

// структура хранения экстремумов
struct Extr
 {
  double   price;
  datetime time; 
 };

   bool IsInitFine ();                                                                         // проверяет, хорошо ли проиницилизирован объект   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000); // функция обновляет экстремумы
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // возвращает значение экстремума по индексу
   ENUM_EXTR_USE GetLastExtrType ();                                                           // возвращает тип последнего экстремума
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // отображает в виде строки тип экстремумов 
  // конструкторы и деструкторы
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,double percentageATR=1,int periodATR=30,int period_average_ATR=1);
 ~CBlowInfoFromExtremums ();
 };
 
 // кодирование методов класса
 
 bool CBlowInfoFromExtremums::IsInitFine(void)   // проверяет правильность инициализации объекта
  {
   if (_handleExtremums == INVALID_HANDLE)
    {
     Print("Ошибка инициализации класса CBlowInfoFromExtremums. Не удалось создать хэндл индикатора DrawExtremums");
     return(false);
    }
   return(true);
  }
 
  
 Extr GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // получает значение экстремума по индексу
  {
   int    countExtr = -1;  // счетчик индексов экстремумов
   int    index;           // индекс прохода по циклу
   Extr extr;              // экстремум
   extr.price = 0;
   extr.time  = 0;
   if (extr_use == EXTR_HIGH)
    {
     // проходим по всему буферу
     for (index=_historyDepth-1;index>0;index--)
      {
       // если в буфере найден экстремум
       if ( _extrBufferHigh[index] != 0 )
        {
          countExtr ++;  
          // если нашли экстремум по индексу 
          if (countExtr == extr_index)
           {
            
            extr.price = _extrBufferHigh[index];
            extr.time  = _timeBufferHigh[index];
            //return (extr); 
           }
        }
      }
     }
    else if (extr_use == EXTR_LOW)
     {
     // проходим по всему буферу
     for (index=_historyDepth-1;index>0;index--)
      {
       // если в буфере найден экстремум
       if ( _extrBufferLow[index] != 0 )
        {
          countExtr ++;  
          // если нашли экстремум по индексу 
          if (countExtr == extr_index)
           {
            extr.price = _extrBufferLow[index];
            extr.time  = _timeBufferLow[index];
            return (extr); 
           }
        }
      }      
     }
     
   return (extr);
  }
  
   
   GetLastExtrType(void)
    {
     // проходим от конца глубины истории до первого попавшегося экстремума
     for (int index=_historyDepth-1;index>0;index--)
      {
        if (_extrBufferHigh[index] != 0 )  // если верхний экстремум найден
         { 
           if (_extrBufferLow[index] == 0) // если нижнего экстремума нет
             return EXTR_HIGH;  
           else 
             continue;                
         }
        if (_extrBufferLow[index] != 0)
         return EXTR_LOW;
      } 
      return EXTR_NO;
    }
  