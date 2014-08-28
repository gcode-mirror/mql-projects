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

#include <StringUtilities.mqh>
#include <CLog.mqh>

// перечисление типов эктсремумов
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

// структура хранения эктсремумов
struct Extr
 {
  double   price;
  datetime time; 
 };

class CBlowInfoFromExtremums
 {
  private:
   // буферы класса
   double   _extrBufferHigh[];  // буфер высоких экстремумов
   double   _extrBufferLow [];  // буфер низких эксремумов
   datetime _timeBufferHigh[];  // время появления верхних экстремумов
   datetime _timeBufferLow [];  // время появления нижних экстремумов
   // приватные поля класса
   int _handleExtremums;        // хэндл индикатора DrawExtremums   
   int _historyDepth;           // глубина истории
   string _symbol;              // символ
   ENUM_TIMEFRAMES _period;     // период
   int _symbolCode;             // код символа экстремума
  public:
  // методы класса
   bool IsInitFine ();                                                                         // проверяет, хорошо ли проиницилизирован объект   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000); // функция обновляет экстремумы
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // возвращает значение экстремума по индексу
   ENUM_EXTR_USE GetLastExtrType ();                                                           // возвращает тип последнего экстремума
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // отображает в виде строки тип экстремумов 
  // конструкторы и деструкторы
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=1,int symbolCode=217);
 ~CBlowInfoFromExtremums ();
 };
 
 // кодирование методов класса
 
 bool CBlowInfoFromExtremums::IsInitFine(void)   // проверяет правильность инициализации объекта
  {
   if (_handleExtremums == INVALID_HANDLE)
    {
    // Print("Ошибка инициализации класса CBlowInfoFromExtremums. Не удалось создать хэндл индикатора DrawExtremums");
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка инициализации класса CBlowInfoFromExtremums. Не удалось создать хэндл индикатора DrawExtremums", MakeFunctionPrefix(__FUNCTION__)));     
     return(false);
    }
   return(true);
  }
 
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000)       // обновляет данные экстремумов
  {
   int copiedHigh     = historyDepth;
   int copiedLow      = historyDepth;
   int copiedHighTime = historyDepth;
   int copiedLowTime  = historyDepth;
   _historyDepth = historyDepth;
    if (extr_use == EXTR_NO)
     return (false);
     
      for (int attempts = 0; attempts < 25; attempts ++)
       {
       if (extr_use != EXTR_LOW) 
         {      
          copiedHigh     = CopyBuffer(_handleExtremums,0,start_time,historyDepth,_extrBufferHigh);
          copiedHighTime = CopyTime  (_symbol,_period,start_time,historyDepth,_timeBufferHigh);
          
         }
       if (extr_use != EXTR_HIGH) 
         {
          copiedLow      = CopyBuffer(_handleExtremums,1,start_time,historyDepth,_extrBufferLow); 
          copiedLowTime  = CopyTime  (_symbol,_period,start_time,historyDepth,_timeBufferLow);
          
          
         }
        Sleep(1000);
       }
      // Print("copiedHIGH = ",copiedHigh," copiedHighTime = ",copiedHighTime, " PERIOD = ",PeriodToString(_period));
      // Print("copiedLOW = ",copiedLow," copiedLowTime = ",copiedLowTime, " PERIOD = ",PeriodToString(_period));
      if ( copiedHigh != historyDepth || copiedLow != historyDepth || copiedHighTime != historyDepth || copiedLowTime != historyDepth)
       {
     //   Print("Ошибка метода Upload класса CExtremums. Не удалось прогрузить буферы индикатора DrawExtremums ",PeriodToString(_period));
        log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка метода Upload класса CExtremums. Не удалось прогрузить буферы индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);
       }
       
   return (true);
  }
  
 Extr CBlowInfoFromExtremums::GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // получает значение экстремума по индексу
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
  
   
   ENUM_EXTR_USE CBlowInfoFromExtremums::GetLastExtrType(void)
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
  
   
   string CBlowInfoFromExtremums::ShowExtrType(ENUM_EXTR_USE extr_use)  // отображает в виде строки тип экстремумов
    {
     switch (extr_use)
      {
       case EXTR_BOTH:
        return "Оба типа экстремумов";
       break;
       case EXTR_HIGH:
        return "Высокие экстремумы";
       break;
       case EXTR_LOW:
        return "Низкие экстремумы";
       break;
       case EXTR_NO:
        return "Нет эксремумов";
       break;
      }
     return "";
    }
   

   CBlowInfoFromExtremums::CBlowInfoFromExtremums(string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=1,int symbolCode=217)   // конструктор класса 
    {
     _historyDepth = historyDepth;
     _symbol       = symbol;
     _period       = period;
     _symbolCode   = symbolCode;
     _handleExtremums = iCustom(symbol,period,"DrawExtremums",period,historyDepth,periodATR,period_average_ATR,symbolCode);
    }
    
   CBlowInfoFromExtremums::~CBlowInfoFromExtremums(void)   // деструктор класса
    {
     ArrayFree(_extrBufferHigh);
     ArrayFree(_extrBufferLow);
     IndicatorRelease(_handleExtremums);
    }