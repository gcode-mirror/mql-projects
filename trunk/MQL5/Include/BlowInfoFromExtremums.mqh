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

enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

class CBlowInfoFromExtremums
 {
  private:
   // буферы класса
   double _extrBufferHigh[]; // буфер высоких экстремумов
   double _extrBufferLow[];  // буфер низких эксремумов
   // приватные поля класса
   int _handleExtremums;     // хэндл индикатора DrawExtremums   
   int _historyDepth;        // глубина истории
  public:
  // методы класса
   bool IsInitFine ();                                                                    // проверяет, хорошо ли проиницилизирован объект   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=1000); // функция обновляет экстремумы
   double GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                         // возвращает значение экстремума по индексу
   ENUM_EXTR_USE GetLastExtrType ();                                                     // возвращает тип последнего экстремума
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                          // отображает в виде строки тип экстремумов 
  // конструкторы и деструкторы
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,double percentageATR=1,int periodATR=30,int period_average_ATR=1);
  CBlowInfoFromExtremums (int handle): _handleExtremums(handle) {};
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
 
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=1000)       // обновляет данные экстремумов
  {
   int copiedHigh = historyDepth;
   int copiedLow  = historyDepth;
   _historyDepth = historyDepth;
    if (extr_use == EXTR_NO)
     return (false);
     
      for (int attempts = 0; attempts < 5; attempts ++)
       {
       if (extr_use != EXTR_LOW)  copiedHigh = CopyBuffer(_handleExtremums,0,start_index,historyDepth,_extrBufferHigh);
       if (extr_use != EXTR_HIGH) copiedLow  = CopyBuffer(_handleExtremums,1,start_index,historyDepth,_extrBufferLow);
        Sleep(100);
       }
      if ( copiedHigh != historyDepth || copiedLow != historyDepth)
       {
        Print("Ошибка метода Upload класса CExtremums. Не удалось прогрузить буферы индикатора DrawExtremums");
        return (false);
       }
       
   return (true);
  }
  
 double CBlowInfoFromExtremums::GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // получает значение экстремума по индексу
  {
   int    countExtr = -1;  // счетчик индексов экстремумов
   int    index;           // индекс прохода по циклу
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
           return (_extrBufferHigh[index]); 
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
           return (_extrBufferLow[index]); 
        }
      }      
     }
     
   return (0.0);
  }
  
  ENUM_EXTR_USE CBlowInfoFromExtremums::GetLastExtrType(void)  // возвращает тип последнего экстремума
   {
    for (int index=_historyDepth-1;index>0;index--)
     {
       if (_extrBufferHigh[index] != 0.0 )
        {
         if (_extrBufferLow[index] != 0.0 )
           return EXTR_BOTH;
          return EXTR_HIGH;
        }
       if (_extrBufferLow[index] != 0.0 )
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
   

   CBlowInfoFromExtremums::CBlowInfoFromExtremums(string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,double percentageATR=1,int periodATR=30,int period_average_ATR=1)   // конструктор класса 
    {
     _historyDepth = historyDepth;
     _handleExtremums = iCustom(symbol,period,"DrawExtremums",false,period,historyDepth,percentageATR,periodATR,period_average_ATR);
    }
    
   CBlowInfoFromExtremums::~CBlowInfoFromExtremums(void)   // деструктор класса
    {
     ArrayFree(_extrBufferHigh);
     ArrayFree(_extrBufferLow);
     IndicatorRelease(_handleExtremums);
    }