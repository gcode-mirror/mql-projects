//+------------------------------------------------------------------+
//|                                             IndicatorManager.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Системный файл для работы с индикаторами                         |
//+------------------------------------------------------------------+

 // функция добавляет индикатор по хэндлу
 void SetIndicatorByHandle (string symbol,ENUM_TIMEFRAMES period,int handle_indicator)
  {
   //Добавим окно с символом и периодом индюка если его нет
   bool chart = true;
   long z = ChartFirst();
   // проходим по графикам и ищем график с заданным символом и таймфреймом
   while (chart && z>=0)
    {
     if ( ChartSymbol(z)== symbol && ChartPeriod(z)==period ) 
       {
        chart=false;
        break;
       }
     z = ChartNext(z);
    }
   // если не был найден ни один график с заданными символом и периодом, добавляем его
   if (chart) z = ChartOpen(symbol, period);
   // и добавляем индикатора по заданному хэндлу
   ChartIndicatorAdd(z,0, handle_indicator);   
  }   
  
 // функция проверяет, есть ли индикатор с заданным именем на каком нибудь графике и возвращает его хэндл
 int DoesIndicatorExist (string symbol,ENUM_TIMEFRAMES period,string indicator_name)
  {
   bool chart = true;
   int handleIndicator = INVALID_HANDLE;
   long z = ChartFirst();
   // проходим по графикам и ищем график с заданным символом и таймфреймом
   while (chart && z>=0)
    {
     // если найден график с заданным символом и таймфреймом
     if ( ChartSymbol(z)== symbol && ChartPeriod(z)==period ) 
       {
        handleIndicator = ChartIndicatorGet(z,0,indicator_name);  
        // если найден индикатор по данному хэндлу
        if (handleIndicator!=INVALID_HANDLE)
         {
          return (handleIndicator);
         }
       }
     z = ChartNext(z);
    }
   return (handleIndicator);
  }     