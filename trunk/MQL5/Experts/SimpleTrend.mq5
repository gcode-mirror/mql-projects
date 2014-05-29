//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Робот, торгующий на тренде                                       |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <Lib CisNewBarDD.mqh>           // для проверки формирования нового бара
#include <CompareDoubles.mqh>            // для сравнения вещественных чисел

#include <TradeManager\TradeManager.mqh> // торговая библиотека

// перечисления и константы
enum ENUM_TENDENTION
 {
  TENDENTION_NO = 0,     // нет тенденции
  TENDENTION_UP,         // тенденция вверх
  TENDENTION_DOWN        // тенденция вниз
 };

// входные параметры
input double lot = 0.1;                  // начальный лот
input double lotStep = 0.2;              // размер доливки

// системные переменные

// хэндлы индикаторов
int handleSmydMACD_D1;                   // хэндл индикатора расхождений MACD на дневнике
int handleSmydMACD_H1;                   // хэндл индикатора расхождений MACD на часовике
int handleSmydMACD_M15;                  // хэндл индикатора расхождений MACD на 15 минутах
int handleDrawExtr_M5;                   // хэндл индикатора экстремумов на 5-минутке
int handleDrawExtr_M15;                  // хэндл индикатора экстремумов на 15-ти минутке
int handleDrawExtr_H1;                   // хэндл индикатора экстремумов на часовике

// таймфреймы
ENUM_TIMEFRAMES periodD1  = PERIOD_D1; 
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;
ENUM_TIMEFRAMES periodM1  = PERIOD_M1; 

// необходимые буферы
MqlRates lastBarD1[];                    // буфер цен на дневнике

// объекты классов
CTradeManager *ctm;                      // объект торговой библиотеки
CisNewBar     *isNewBar_D1;              // новый бар на D1
 
// дополнительные системные переменные
bool firstLaunch    = true;              // флаг первого запуска эксперта
bool openedPosition = false;             // флаг открытия позиции
double currentPrice;                     // для хранения текущей цены
double stopLoss;                         // переменная для хранения стоп лосса
double currentLot;                       // текущий лот
ENUM_TENDENTION  lastTendention;         // переменная для хранения последней тенденции 

// переменные для хранения значений экстремумов
double lastExtr_M5;                      // значение последнего экстремума на M5
double lastExtr_M15;                     // значение последнего экстремума на M15
double lastExtr_H1;                      // значение последнего экстремума на H1

// описание системных функций робота
ENUM_TENDENTION GetLastTendention();     // возвращает потенциальную тенденцию на предыдущем баре
ENUM_TENDENTION GetCurrentTendention();  // возвращает текущую тенденцию цены
bool            GetExtremums_M5_M15_H1();// ищет значения экстремумов на M5 M15 H1

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD и Стохастика
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD"); 
   handleDrawExtr_M5  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleDrawExtr_M15 = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleDrawExtr_H1  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
   if (handleSmydMACD_D1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на D1");
     errorValue = INIT_FAILED;
    }       
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на H1");
     errorValue = INIT_FAILED;  
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на M15");
     errorValue = INIT_FAILED;     
    }       
   if (handleDrawExtr_H1 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на H1");
     errorValue = INIT_FAILED;       
    }  
   if (handleDrawExtr_M15 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на M15");
     errorValue = INIT_FAILED;       
    }  
   if (handleDrawExtr_M5 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на M5");
     errorValue = INIT_FAILED;       
    }          
   // создаем объект класса TradeManager
   ctm = new CTradeManager();                    
   // создаем объект класса CisNewBar
   isNewBar_D1 = new CisNewBar(_Symbol,PERIOD_D1);
   // инициализируем переменные
   
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_D1);
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleSmydMACD_M15);
   IndicatorRelease(handleDrawExtr_H1);
   IndicatorRelease(handleDrawExtr_M15);
   IndicatorRelease(handleDrawExtr_M5);
   // удаляем объекты классов
   delete ctm;
   delete isNewBar_D1;
  }

void OnTick()
  {
    ctm.OnTick();
    // если это первый запуск эксперта или сформировался новый бар 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      // если позиция еще не открыта
      if (!openedPosition )
       {
        lastTendention = GetLastTendention();                   // получаем предыдущую тенденцию
       } 
     }
    // на каждом тике
    else
     {
       // если позиция еще не открыта
       if (!openedPosition )
        {
         currentPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // получаем текущую цену
         // если общая тенденция  - вверх
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
             
           }
         // если общая тенденция - вниз
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {
        
           }
        }
        
     }
  }
  
 // кодирование функций
 ENUM_TENDENTION GetLastTendention ()
  {
  
   if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 1 )
     {
      if ( GreatDoubles (lastBarD1[0].close,lastBarD1[0].open) )
       return (TENDENTION_UP);
      if ( LessDoubles  (lastBarD1[0].close,lastBarD1[0].open) )
       return (TENDENTION_DOWN); 
     }
    return (TENDENTION_NO); 
  }
  
  ENUM_TENDENTION GetCurrentTendention ()
   {
    if ( GreatDoubles (currentPrice,lastBarD1[1].open) )  
       return (TENDENTION_UP);
    if ( LessDoubles  (currentPrice,lastBarD1[1].open) )
       return (TENDENTION_DOWN);
     return (TENDENTION_NO); 
   }
   
  bool  GetExtremums_M5_M15_H1()
   {
   /*
    int copiedM5 = -1;
    int copiedM15
   */
     return (true);
   }