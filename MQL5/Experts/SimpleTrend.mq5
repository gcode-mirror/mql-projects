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
double lastExtr_M5_up[];                 // значение последнего верхнего экстремума на M5
double lastExtr_M5_down[];               // значение последнего нижнего экстремума на M5
double lastExtr_M15_up[];                // значение последнего верхнего экстремума на M15
double lastExtr_M15_down[];              // значение последнего нижнего экстремума на M15
double lastExtr_H1_up[];                 // значение последнего верхнего экстремума на H1
double lastExtr_H1_down[];               // значение последнего нижнего экстремума на H1

// описание системных функций робота
ENUM_TENDENTION GetLastTendention();     // возвращает потенциальную тенденцию на предыдущем баре
ENUM_TENDENTION GetCurrentTendention();  // возвращает текущую тенденцию цены
bool            GetExtremums_M5_M15_H1();// ищет значения экстремумов на M5 M15 H1

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD"); 
   // пытаемся инициализировать хэндлы идникатора Extremums
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
        lastTendention = GetLastTendention();                      // получаем предыдущую тенденцию                 
        GetExtremums_M5_M15_H1();                                  // получаем значения последних экстремумов
                  Comment(" \n",
                          "M5 UP: ",DoubleToString(lastExtr_M5_up[0]),
                          "\nM5 DOWN: ",DoubleToString(lastExtr_M5_down[0]),                          
                          "\nM15 UP: ",DoubleToString(lastExtr_M15_up[0]),
                          "\nM15 DOWN: ",DoubleToString(lastExtr_M15_down[0]),                          
                          "\nH1 UP: ",DoubleToString(lastExtr_H1_up[0]),
                          "\nH1 DOWN: ",DoubleToString(lastExtr_H1_down[0]),                          
                         "\nЦены: ",DoubleToString(currentPrice)    );        
       } 
     }
    // на каждом тике
       // если позиция еще не открыта
       if (!openedPosition )
        {
         currentPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // получаем текущую цену
         // если общая тенденция  - вверх
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
                 
             // если текущая цена пробила один из экстемумов на одном из таймфреймов
             if ( GreatDoubles (currentPrice,lastExtr_M5_up[0])  ||
                  GreatDoubles (currentPrice,lastExtr_M15_up[0]) ||
                  GreatDoubles (currentPrice,lastExtr_H1_up[0]) )
                {
                  // если текущее расхождение MACD НЕ противоречит текущему движению
    /*              Comment("Цена выше одного из экстремумов \n",
                          "M5: ",DoubleToString(lastExtr_M5_up[0]),
                          "\nM15: ",DoubleToString(lastExtr_M15_up[0]),
                          "\nH1: ",DoubleToString(lastExtr_H1_up[0]),
                         "\nЦены: ",DoubleToString(currentPrice)   
                  );
      */            
                  // сохраняем стоп лосс
                  stopLoss = 0;                  
                  // то открываем позицию на BUY
             //     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                  // выставляем флаг открытия позиции в true
                  openedPosition = true;
                }
    
           }
         // если общая тенденция - вниз
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {
                          
           
             // если текущая цена пробила один из экстемумов на одном из таймфреймов
             if ( LessDoubles (currentPrice,lastExtr_M5_down[0])  ||
                  LessDoubles (currentPrice,lastExtr_M15_down[0]) ||
                  LessDoubles (currentPrice,lastExtr_H1_down[0]) )
                {
                       /*          Comment("Цена ниже одного из экстремумов \n",
                          "M5: ",DoubleToString(lastExtr_M5_down[0]),
                          "\nM15: ",DoubleToString(lastExtr_M15_down[0]),
                          "\nH1: ",DoubleToString(lastExtr_H1_down[0]),
                          "\nЦены: ",DoubleToString(currentPrice)
                  ); */
                  // если текущее расхождение MACD НЕ противоречит текущему движению
                  
                  // сохраняем стоп лосс
                  stopLoss = 0;
                  // то открываем позицию на SELL
                 
                }      

                
                  
           }
        }
        
  }
  
 // кодирование функций
 ENUM_TENDENTION GetLastTendention ()
  {
  
   if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )
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
    int copiedM5_up        = CopyBuffer(handleDrawExtr_M5,2,1,1,lastExtr_M5_up);
    int copiedM5_down      = CopyBuffer(handleDrawExtr_M5,3,1,1,lastExtr_M5_down);
    int copiedM15_up       = CopyBuffer(handleDrawExtr_M15,2,1,1,lastExtr_M15_up);
    int copiedM15_down     = CopyBuffer(handleDrawExtr_M15,3,1,1,lastExtr_M15_down);
    int copiedH1_up        = CopyBuffer(handleDrawExtr_H1,2,1,1,lastExtr_H1_up);
    int copiedH1_down      = CopyBuffer(handleDrawExtr_H1,3,1,1,lastExtr_H1_down);        
    
    if (copiedH1_down  < 1 ||
        copiedH1_up    < 1 ||
        copiedM15_down < 1 ||
        copiedM15_up   < 1 ||
        copiedM5_down  < 1 ||
        copiedM5_up    < 1
       )
        {
         Print("Ошибка эксперта SimpleTrend. Не удалось получить данные об экстремумах");
         return (false);
        }
        
     return (true);
   }