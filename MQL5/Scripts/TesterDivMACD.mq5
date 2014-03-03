//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <divergenceMACD.mqh>                 // подключаем библиотеку для поиска схождений и расхождений Стохастика
#include <CompareDoubles.mqh>                 // для проверки соотношения  цен
//+------------------------------------------------------------------+
//| Скрипт тестировщик актуальности расхождения MACD                 |
//+------------------------------------------------------------------+

input int bars_ahead=10; // колчиество баров вперед после сигнала для проверки актуальности   

// переменные для хранения количества акутальный и не актуальных сигналов

 int countConvPos;       // количество положительных сигналов схождения
 int countConvNeg;       // количество негативный сигналов схождения
 int countDivPos;        // количество положительный сигналов расхождения
 int countDivNeg;        // количество негативных сигналов расхождения 

// буферы хранения баров 
 double buffer_high[];   // высокие цены
 double buffer_low[];    // низкие цены
 double buffer_close[];  // цены закрытия 

// переменные для проверки нормальной загрузки баров 

 int copiedHigh;         // высокие цены
 int copiedLow;          // низкие цены
 int copiedClose;        // цены закрытия
 
// хэдл MACD
 int handleMACD; 
 
// индексы загрузки баров

int lastBarIndex;  // индекс последнего бара /// = rates_total - 101;

void OnStart()
  {
   // присвоение значений переменных
   datetime current = TimeCurrent();           // текущее время
   int      countBars = Bars(_Symbol,_Period); // всего баров истории
   ArraySetAsSeries(Buffer, true); // индексация как в таймсерии
   ArraySetAsSeries(Buffer, true);
   ArraySetAsSeries(Buffer, true);      
   // 0) - вычисление индексов первого и последнего баров
   lastBarIndex  = countBars - 101;
   if (lastBarIndex > 
   // 1) - загружаем бары истории
   copiedHigh   = CopyHigh(_Symbol, _Period, 0, countBars, buffer_high);   
   copiedLow    = CopyLow(_Symbol, _Period, 0, countBars, buffer_low);   
   copiedClose  = CopyClose(_Symbol, _Period, 0, countBars, buffer_close);
   // 2) - проверка правильности загрузки баров
   if ( copiedClose < countBars || copiedHigh < countBars || copiedLow < countBars)
    { // если не удалось прогрузить все бары истории
     Alert("Не удалось прогрузить все бары истории");
     return;
    }
   // 3) - если удалось загрузить, то подключаем хэндл MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // 4) - проверка валидности хэдла MACD
   if (handleMACD <= 0)
    {
     Alert("Не удалось загрузить хэндл MACD");
     return;
    }  
   // 5) - пробегаем по всем барам истории и проверяем на сигнал схождения\расхождения
   
  }