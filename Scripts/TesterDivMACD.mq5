//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs                  // делаем активными инпуты
#include <Divergence\divergenceMACD.mqh>                 // подключаем библиотеку для поиска схождений и расхождений Стохастика
#include <CompareDoubles.mqh>                 // для проверки соотношения  цен
//+------------------------------------------------------------------+
//| Скрипт тестировщик актуальности расхождения MACD                 |
//+------------------------------------------------------------------+

 // перечисление режима загрузки баров истории
 enum BARS_MODE
 {
  ALL_HISTORY=0, // вся история
  INPUT_BARS     // вводимое количество баром пользователя
 };

// параметры, вводимые пользователем

input BARS_MODE mode      = INPUT_BARS; // режим загрузки баров
input int depth           = 1000;       // глубина истории
input int bars_ahead      = 10;         // количество баров рассчета актуальности
input int fast_ema_period = 12;         // период быстрой средней MACD
input int slow_ema_period = 26;         // период медленной средней MACD
input int signal_period   = 9;          // период усреднения разности MACD 

// переменные для хранения количества акутальный и не актуальных сигналов

 int countConvPos = 0;       // количество положительных сигналов схождения
 int countConvNeg = 0;       // количество негативный сигналов схождения
 int countDivPos  = 0;       // количество положительный сигналов расхождения
 int countDivNeg  = 0;       // количество негативных сигналов расхождения 

// буферы хранения баров 
 double buffer_high [];      // высокие цены
 double buffer_low  [];      // низкие цены
 double buffer_close[];      // цены закрытия 

// переменные для проверки нормальной загрузки баров 

 int copiedHigh;             // высокие цены
 int copiedLow;              // низкие цены
 int copiedClose;            // цены закрытия
 
// хэндл MACD
 int handleMACD; 
 
// индексы загрузки баров
 int lastBarIndex;  // индекс последнего бара 

// буфер для хранения результатов поиска схождения\расхождения MACD
 PointDivMACD  divergencePoints;    

// временные параменные для хранения локальных минимумов и максимумов
 double localMax;
 double localMin;

// функция поиска максимума и минимума по заданным барам
 void GetMaxMin(int index)
 {
  int count;
  localMax = buffer_high[index];
  localMin = buffer_low[index];
  for (count=1;count<=bars_ahead;count++)
   {
//    if (buffer_high[index-count] > localMax)
    if (GreatDoubles(buffer_high[index-count],localMax) )
     localMax = buffer_high[index-count];
//    if (buffer_low[index-count] < localMin)
    if ( LessDoubles(buffer_low[index-count],localMin) )
     localMin = buffer_low[index-count];
   }
 }

void OnStart()
  {
   // присвоение значений переменных
   int      countBars;
   ArraySetAsSeries(buffer_high , true); // индексация как в таймсерии
   ArraySetAsSeries(buffer_low  , true); // индексация как в таймсерии
   ArraySetAsSeries(buffer_close, true); // индексация как в таймсерии
   // вычисление количества баров
   if (mode == ALL_HISTORY)
    countBars =    Bars(_Symbol,_Period); // всего баров истории
   else
    countBars =    depth;
   // вычисление индекса первого бара
   lastBarIndex  = countBars - 101;
   if (lastBarIndex <= bars_ahead)
    {
     Alert("Неправильньное соотношение глубины рассчета и количества баров истории");
     return;
    }
   // загружаем бары истории
   copiedHigh   = CopyHigh(_Symbol, _Period, 0, countBars, buffer_high);   
   copiedLow    = CopyLow(_Symbol, _Period, 0, countBars, buffer_low);   
   copiedClose  = CopyClose(_Symbol, _Period, 0, countBars, buffer_close);
   // проверка правильности загрузки баров
   if ( copiedClose < countBars || copiedHigh < countBars || copiedLow < countBars)
    { // если не удалось прогрузить все бары истории
     Alert("Не удалось прогрузить все бары истории");
     return;
    }
   // если удалось загрузить, то подключаем хэндл MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // проверка валидности хэдла MACD
   if (handleMACD <= 0)
    {
     Alert("Не удалось загрузить хэндл MACD");
     return;
    }  
   // пробегаем по всем барам истории и проверяем на сигнал схождения\расхождения (с начала истории к концу)
   for(int index=lastBarIndex;index>bars_ahead;index--)
    {
     Comment("____________________________");
     Comment("ПРОГРЕСС ВЫЧИСЛЕНИЯ: ",MathRound(100*(1.0*(lastBarIndex-bars_ahead-index)/(lastBarIndex-bars_ahead)))+"%");
     // вычисляем схождение\расхождение
     switch ( divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,index) )
      {
       // если найдено расхождение
       case 1:
        GetMaxMin(index+1); // находим максимум и минимум цен
        // если схождение валидно
       // if ( (localMax - buffer_close[index]) > (buffer_close[index] - localMin) )
        if ( GreatDoubles ( (localMax - buffer_close[index]), (buffer_close[index] - localMin) ) )
         {
          countDivPos ++; // увеличиваем счетчик положительных схождений
         }
        else
         {
          countDivNeg ++; // иначе увеличиваем счетчик отрицательных схождений
         }
       break;
       // если найдено схождение
       case -1:
        GetMaxMin(index+1); // находим максимум и минимум цен
        // если расхождение валидно
      //  if ( (localMax - buffer_close[index]) < (buffer_close[index] - localMin) )
        if (LessDoubles ( (localMax - buffer_close[index]), (buffer_close[index] - localMin) ) )
         {
          countConvPos ++; // увеличиваем счетчик положительных расхождений
         }
        else
         {
          countConvNeg ++; // иначе увеличиваем счетчик отрицательных расхождений
         }       
       break;
      }
    }
    Alert("________________________________________");
    Alert("Не актуальных расхождений: ",countDivNeg);
    Alert("Актуальных расхождений: ",countDivPos);
    Alert("Всего расхождений: ",countDivPos+countDivNeg);
    Alert("Не актуальных схождений: ",countConvNeg);
    Alert("Актуальных схождений: ",countConvPos);
    Alert("Всего схождений: ",countConvPos+countConvNeg);
    Alert("Результаты поиска схождений\расхождений:");
  }