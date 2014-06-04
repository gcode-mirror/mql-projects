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
  EXTR_BOTH
 };

class CBlowInfoFromExtremums
 {
  private:
   // буферы класса
   double _extrBufferHigh[]; // буфер высоких экстремумов
   double _extrBufferLow[];  // буфер низких эксремумов
   // приватные поля класса
   int _handleExtremums;    // хэндл индикатора DrawExtremums    
  public:
  // методы класса
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=100); // функция обновляет экстремумы
  // конструкторы и деструкторы
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period);
  CBlowInfoFromExtremums (int handle): _handleExtremums(handle) {};
 ~CBlowInfoFromExtremums ();
 };
 
 // кодирование методов класса
 
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=100)       // обновляет данные экстремумов
  {
   int copiedHigh = historyDepth;
   int copiedLow  = historyDepth;
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