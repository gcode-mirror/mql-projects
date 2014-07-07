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

 
   ENUM_EXTR_USE GetLastExtrType(int historyDepth,double &extrBufferHigh[],double &extrBufferLow[])
    {
     // проходим от конца глубины истории до первого попавшегося экстремума
     for (int index=historyDepth-1;index>0;index--)
      {
        if (extrBufferHigh[index] != 0 )  // если верхний экстремум найден
         { 
           if (extrBufferLow[index] == 0) // если нижнего экстремума нет
             return EXTR_HIGH;  
           else 
             continue;                
         }
        if (extrBufferLow[index] != 0)
         return EXTR_LOW;
      } 
      return EXTR_NO;
    }
  