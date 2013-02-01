//+------------------------------------------------------------------+
//|                                               Example5NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar newbar_ind; // экземпляр класса CisNewBar: определение новой тиковой свечи
int HandleIndicator;  // хэндл индикатора
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Получаем хендл индикатора:
   HandleIndicator=iCustom(_Symbol,_Period,"TickColorCandles v2.00",16,0,""); 
   if(HandleIndicator==INVALID_HANDLE)
     {
      Alert(" Ошибка при создании хэндла индикатора, номер ошибки: ",GetLastError());
      Print(" Инициализация советника завершена некорректно. Торговля запрещена.");
      return(1);
     }

//--- Присоединяем индикатор к графику:  
   if(!ChartIndicatorAdd(ChartID(),1,HandleIndicator))
     {
      Alert(" Ошибка присоединения индикатора к графику, номер ошибки: ",GetLastError());
      return(1);
     }
//--- Если дошли до сюда, то инициализация прошла успешно     
   Print(" Инициализация советника завершена успешно. Торговля разрешена.");
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double iTime[1];

//--- Получаем время открытия последней незавершенной тиковой свечи:
   if(CopyBuffer(HandleIndicator,5,0,1,iTime)<=0)
     {
      Print(" Неудачная попытка получить значение времени индикатора. "+
            "\nСледующая попытка получить значения индикатора будет предпринята на следующем тике.",GetLastError());
      return;
     }
//--- Определяем появление новой тиковой свечи:
   if(newbar_ind.isNewBar((datetime)iTime[0]))
     {
      PrintFormat("Новый бар. Время открытия: %s  Время последнего тика: %s",TimeToString((datetime)iTime[0],TIME_SECONDS),TimeToString(TimeCurrent(),TIME_SECONDS));
     }
  }
  
 
