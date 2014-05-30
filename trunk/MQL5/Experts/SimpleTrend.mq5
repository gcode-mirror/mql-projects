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
 
// константы сигналов
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0

// входные параметры
input double lot     = 0.1;              // начальный лот
input double lotStep = 0.2;              // размер доливки

// системные переменные

// хэндлы индикаторов
int handleSmydMACD_M5;                   // хэндл индикатора расхождений MACD на минутке
int handleSmydMACD_M15;                  // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydMACD_H1;                   // хэндл индикатора расхождений MACD на часовике
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
int  openedPosition = 0;                 // тип открытой позиции 
int  countAddingToLot = 0;               // счетчик доливок
double curPrice;                         // для хранения текущей цены
double stopLoss;                         // переменная для хранения стоп лосса
double currentLot;                       // текущий лот
ENUM_TENDENTION  lastTendention;         // переменная для хранения последней тенденции 

// буферы для хранения значений экстремумов
double lastExtr_M5_up[];                 // значение последнего верхнего экстремума на M5
double lastExtr_M5_down[];               // значение последнего нижнего экстремума на M5
double lastExtr_M15_up[];                // значение последнего верхнего экстремума на M15
double lastExtr_M15_down[];              // значение последнего нижнего экстремума на M15
double lastExtr_H1_up[];                 // значение последнего верхнего экстремума на H1
double lastExtr_H1_down[];               // значение последнего нижнего экстремума на H1

// буферы для хранения расхождений на MACD
double divMACD_M5[];                     // на пятиминутке
double divMACD_M15[];                    // на 15-минутке
double divMACD_H1[];                     // на часовике

// описание системных функций робота
ENUM_TENDENTION GetLastTendention();               // возвращает потенциальную тенденцию на предыдущем баре
ENUM_TENDENTION GetCurrentTendention();            // возвращает текущую тенденцию цены
bool            GetExtremums();                    // ищет значения экстремумов на M5 M15 H1
bool            IsMACDCompatible (int direction);  // проверяет совместимость расхождений MACD с текущей тенденцией
void            MoveStopLossForBuy ();             // переносит стоп лосс на новое положение для позиции BUY
void            MoveStopLossForSell();             // переносит стоп лосс на новое положение для позиции SELL

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,periodM5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   // пытаемся инициализировать хэндлы идникатора Extremums
   handleDrawExtr_M5  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleDrawExtr_M15 = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleDrawExtr_H1  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
   if (handleSmydMACD_M5  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на M5");
     errorValue = INIT_FAILED;
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на M15");
     errorValue = INIT_FAILED;     
    }        
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD на H1");
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
   // создаем объекты класса CisNewBar
   isNewBar_D1 = new CisNewBar(_Symbol,PERIOD_D1);
   // инициализируем переменные
   currentLot = lot;
   
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // освобождаем буферы
   ArrayFree(divMACD_M5);
   ArrayFree(divMACD_M15);
   ArrayFree(divMACD_H1);
   ArrayFree(lastExtr_H1_down);
   ArrayFree(lastExtr_H1_up);
   ArrayFree(lastExtr_M15_down);
   ArrayFree(lastExtr_M15_up);
   ArrayFree(lastExtr_M5_down);
   ArrayFree(lastExtr_M5_up);
   ArrayFree(lastBarD1);
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
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
    GetExtremums();           // получаем значения последних экстремумов
    // если это первый запуск эксперта или сформировался новый бар 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      // если позиция еще не открыта
      if ( openedPosition == NO_POSITION )
       {
        lastTendention = GetLastTendention();                      // получаем предыдущую тенденцию                   
       } 
     }
       // на каждом тике 
       if ( openedPosition == NO_POSITION )   // если позиция еще не открыта
        {
         curPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // получаем текущую цену
         // если общая тенденция  - вверх
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
             // если текущая цена пробила один из экстемумов на одном из таймфреймов
             if ( GreatDoubles (curPrice,lastExtr_M5_up[0])  ||
                  GreatDoubles (curPrice,lastExtr_M15_up[0]) ||
                  GreatDoubles (curPrice,lastExtr_H1_up[0]) )
                {
                  // если текущее расхождение MACD НЕ противоречит текущему движению
                  if ( IsMACDCompatible (BUY) )
                   {
                     Comment("Открылись на BUY");                   
                     // вычисляем стоп лосс по последнему экстремуму
                     stopLoss = int(lastExtr_M5_down[0]/_Point);
                     // открываем позицию
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                     // выставляем флаг открытия позиции BUY
                     openedPosition = BUY;                    
                   } 
                        

                }
    
           }
         // если общая тенденция - вниз
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {          
             // если текущая цена пробила один из экстемумов на одном из таймфреймов
             if ( LessDoubles (curPrice,lastExtr_M5_down[0])  ||
                  LessDoubles (curPrice,lastExtr_M15_down[0]) ||
                  LessDoubles (curPrice,lastExtr_H1_down[0]) )
                {
                  // если текущее расхождение MACD НЕ противоречит текущему движению
                  if ( IsMACDCompatible (SELL) )
                   {
                     Comment("Открылись на SELL");
                     // вычисляем стоп лосс по последнему экстремуму
                     stopLoss = int(lastExtr_M5_up[0]/_Point);
                     // открываем позицию
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,currentLot,stopLoss);
                     // выставляем флаг открытия позиции SELL
                     openedPosition = SELL;                    
                   } 
                 
                }      

                
                  
           }
        }
       // если позиция была открыта на BUY
       else if ( openedPosition == BUY ) 
        {
         // меняем стоп лосс
         MoveStopLossForBuy ();
        }
       // если позиция была открыта на SELL
       else if ( openedPosition == SELL)
        {
         // меняем стоп лосс 
         MoveStopLossForSell ();
        }
        
  }
  
 // кодирование функций
 
 ENUM_TENDENTION GetLastTendention ()            // возвращает тенденцию на последнем баре
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
  
  ENUM_TENDENTION GetCurrentTendention ()        // проверяет тенденцию текущей цены
   {
    if ( GreatDoubles (curPrice,lastBarD1[1].open) )  
       return (TENDENTION_UP);
    if ( LessDoubles  (curPrice,lastBarD1[1].open) )
       return (TENDENTION_DOWN);
     return (TENDENTION_NO); 
   }
   
  bool  GetExtremums()                           // загружает экстремумы 
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
    
   bool  IsMACDCompatible (int direction)        // проверяет, не противоречит ли расхождение MACD текущей тенденции
    {
     int copiedMACD_M5  = CopyBuffer(handleSmydMACD_M5,1,0,1,divMACD_M5);
     int copiedMACD_M15 = CopyBuffer(handleSmydMACD_M15,1,0,1,divMACD_M15);
     int copiedMACD_H1  = CopyBuffer(handleSmydMACD_H1,1,0,1,divMACD_H1);   
     
     if (copiedMACD_M5  < 1 ||
         copiedMACD_M15 < 1 ||
         copiedMACD_H1  < 1
        )
         {
          Print("Ошибка эксперта SimpleTrend. Не удалось получить данные о расхождениях");
          return (false);
         }        
      if ( (divMACD_M5[0]+direction) && (divMACD_M15[0]+direction) && (divMACD_H1[0]+direction) )
       {
        return (true);
       }
     return (false);
    }
    
   void MoveStopLossForBuy ()         // перетаскивает стоп лосс для позиции BUY
    {
     int type;
     switch (type)
      {
       case 0: // для M5
        // если цена пробила последний экстремум
        if ( GreatDoubles (curPrice, lastExtr_M5_up[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний экстремум 
          stopLoss = lastExtr_M5_down[0];
         }
       break;
       case 1: // для M15
        if ( GreatDoubles (curPrice, lastExtr_M15_up[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний экстремум
          stopLoss = lastExtr_M15_down[0];
         }
       break;  
       case 2: // для H1
        if ( GreatDoubles (curPrice, lastExtr_H1_up[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний эктсремум
          stopLoss = lastExtr_H1_down[0];
         }
       break;  
      }
    }
    
   void MoveStopLossForSell ()         // перетаскивает стоп лосс для позиции SELL
    {
     int type;
     switch (type)
      {
       case 0: // для M5
        // если цена пробила последний экстремум
        if ( LessDoubles (curPrice, lastExtr_M5_down[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний экстремум 
          stopLoss = lastExtr_M5_up[0];
         }
       break;
       case 1: // для M15
        if ( LessDoubles (curPrice, lastExtr_M15_down[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний экстремум
          stopLoss = lastExtr_M15_up[0];
         }
       break;  
       case 2: // для H1
        if ( LessDoubles (curPrice, lastExtr_H1_down[0]) )
         {
          // то перемещаем стоп лосс на предыдущий нижний эктсремум
          stopLoss = lastExtr_H1_up[0];
         }
       break;  
      }
    }    