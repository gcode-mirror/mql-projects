//+------------------------------------------------------------------+
//|                                                     OnNewBar.mqh |
//|                                            Copyright 2010, Lizar |
//|                                                    Lizar@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar@mail.ru"

#include <Lib CisNewBar.mqh>
CisNewBar current_chart; // экземпляр класса CisNewBar: текущий график

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int period_seconds=PeriodSeconds(_Period);                     // Количество секунд в периоде текущего графика
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // Время открытия бара на текущем графике
   if(current_chart.isNewBar(new_time)) OnNewBar();               // При появлении нового бара запускаем обработчик события NewBar
  }
