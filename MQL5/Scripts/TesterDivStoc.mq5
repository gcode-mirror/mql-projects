//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs                  // делаем активными инпуты
#include <divergenceStochastic.mqh>           // подключаем библиотеку для поиска схождений и расхождений Стохастика
#include <CompareDoubles.mqh>                 // для проверки соотношения  цен
//+------------------------------------------------------------------+
//| Скрипт тестировщик актуальности расхождения стохастика           |
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
input ENUM_MA_METHOD      ma_method=MODE_SMA;           // тип сглаживания
input ENUM_STO_PRICE      price_field=STO_LOWHIGH;      // способ расчета стохастика           
input int                 top_level=80;                 // верхний уровень 
input int                 bottom_level=20;              // нижний уровень 
input int                 DEPTH_STOC=10;                // большой хвост буфера 
input int                 ALLOW_DEPTH_FOR_PRICE_EXTR=3; // малый хвост буфера

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
 
// хэндл стохастика
 int handleSTOC; 
 
// индексы загрузки баров
 int lastBarIndex;  // индекс последнего бара 

// буфер для хранения результатов поиска схождения\расхождения стохастика
 PointDiv  divergencePoints;    

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
    if (buffer_high[index-count] > localMax)
     localMax = buffer_high[index-count];
    if (buffer_low[index-count] < localMin)
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
   // если удалось загрузить, то подключаем хэндл стохастика
   handleSTOC = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   // проверка валидности хэдла стохастика
   if (handleSTOC <= 0)
    {
     Alert("Не удалось загрузить хэндл Стохастика");
     return;
    }  
   // пробегаем по всем барам истории и проверяем на сигнал схождения\расхождения (с начала истории к концу)
   for(int index=lastBarIndex;index>bars_ahead;index--)
    {
     Comment("____________________________");
     Comment("ПРОГРЕСС ВЫЧИСЛЕНИЯ: ",MathRound(100*(1.0*(lastBarIndex-bars_ahead-index)/(lastBarIndex-bars_ahead)))+"%");
     // вычисляем схождение\расхождение
     switch ( divergenceSTOC (handleSTOC,_Symbol,_Period,top_level,bottom_level,DEPTH_STOC,ALLOW_DEPTH_FOR_PRICE_EXTR,divergencePoints,index) )
      {
       // если найдено расхождение
       case 1:
        GetMaxMin(index+1); // находим максимум и минимум цен
        // если схождение валидно
        if ( (localMax - buffer_close[index]) > (buffer_close[index] - localMin) )
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
        if ( (localMax - buffer_close[index]) < (buffer_close[index] - localMin) )
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