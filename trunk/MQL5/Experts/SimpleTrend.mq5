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

// хэндлы индикатора SmydMACD
int handleSmydMACD_M5;                   // хэндл индикатора расхождений MACD на минутке
int handleSmydMACD_M15;                  // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydMACD_H1;                   // хэндл индикатора расхождений MACD на часовике
// массив хэндлов индикатора Extremums
int handleExtremums[4];                  // 0 - M1,1 - M5, 2 - M15, 3 - H1             

// таймфреймы
ENUM_TIMEFRAMES periodD1  = PERIOD_D1;   // дневник
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;   // часовик
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;   // 5-ти минутка
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;  // 15-ти минутка
ENUM_TIMEFRAMES periodM1  = PERIOD_M1;   // минутка

// необходимые буферы
MqlRates lastBarD1[];                    // буфер цен на дневнике

// объекты классов
CTradeManager *ctm;                      // объект торговой библиотеки
CisNewBar     *isNewBar_D1;              // новый бар на D1

 
// дополнительные системные переменные
bool firstLaunch    = true;              // флаг первого запуска эксперта
int  openedPosition = 0;                 // тип открытой позиции 
int  countAddingToLot = 0;               // счетчик доливок
int  indexHandleForTrail;                // индекс хэндла индикатора Extremums для трейлинга 
double curPrice;                         // для хранения текущей цены
double stopLoss;                         // переменная для хранения стоп лосса
double currentLot;                       // текущий лот
ENUM_TENDENTION  lastTendention;         // переменная для хранения последней тенденции
ENUM_TIMEFRAMES  periodForTrailing = PERIOD_M1; // период для трейлинга 

// буферы для хранения значений экстремумов
double lastExtr_M1_up[];                 // значение последнего верхнего экстремума на M1
double lastExtr_M1_down[];               // значение последнего нижнего экстремума на M1
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
double          ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, int handlePeriod); // трейлинг

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,periodM5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   // пытаемся инициализировать хэндлы идникатора Extremums
   handleExtremums[0]  = iCustom(_Symbol,periodM1,"DrawExtremums",false,PERIOD_M1);   
   handleExtremums[1]  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleExtremums[2]  = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleExtremums[3]  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
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
   if (handleExtremums[3] == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на H1");
     errorValue = INIT_FAILED;       
    }  
   if (handleExtremums[2] == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на M15");
     errorValue = INIT_FAILED;       
    }  
   if (handleExtremums[1] == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на M5");
     errorValue = INIT_FAILED;       
    }          
   if (handleExtremums[0] == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперат SimpleTrend. Не удалось создать хэндл индикатора DrawExtremums на M1");  
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
   ArrayFree(lastExtr_M1_down);
   ArrayFree(lastExtr_M1_down);
   ArrayFree(lastBarD1);
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleExtremums[0]);
   IndicatorRelease(handleExtremums[1]);
   IndicatorRelease(handleExtremums[2]);
   IndicatorRelease(handleExtremums[3]);
   // удаляем объекты классов
   delete ctm;
   delete isNewBar_D1;
  }

void OnTick()
  {
    ctm.OnTick(); 
    ctm.DoTrailing();  
    GetExtremums();           // получаем значения последних экстремумов
    curPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // получаем текущую цену
    // если это первый запуск эксперта или сформировался новый бар 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      
      // если нет открытых позиций 
      if ( ctm.GetPositionCount() == 0 )
       {
        lastTendention = GetLastTendention();                      // получаем предыдущую тенденцию                   
       } 
     }
       // на каждом тике 
       if ( ctm.GetPositionCount() == 0 )   // если позиция еще не открыта
        {
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
                     // вычисляем стоп лосс по последнему экстремуму
                     stopLoss = int(lastExtr_M5_down[0]/_Point);
                     // открываем позицию на BUY
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                     // выставляем флаг открытия позиции BUY
                     openedPosition = BUY;         
                     // обнуляем индекс хэндлов индикатора Extremums для трейлинга
                     indexHandleForTrail = 0;           
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
                     // вычисляем стоп лосс по последнему экстремуму
                     stopLoss = int(lastExtr_M5_up[0]/_Point);
                     // открываем позицию на SELL
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,currentLot,stopLoss);
                     // выставляем флаг открытия позиции SELL
                     openedPosition = SELL;  
                     // обнуляем индекс хэндлов индикатора Extremums для трейлинга
                     indexHandleForTrail = 0;                                         
                   } 
                 
                }      

                
                  
           }
        }
       // если есть открытые позиции
       else
        {
       // если позиция была открыта на BUY
       if ( openedPosition == BUY ) 
        {
         // если было сделано меньше 4-х доливок 
         if ( countAddingToLot < 4 )
           {
            // если цена пробила последний верхний экстремум на M1
            if (GreatDoubles(curPrice, lastExtr_M1_up[0]) )
             {
               // то доливаемся 
               currentLot = currentLot + lotStep;
               ctm.PositionChangeSize(_Symbol, lot);
               // и увеличиваем количество доливок на единицу
               countAddingToLot ++;
             } 
           }
         // трейлим стоп лосс
         switch (indexHandleForTrail)
          {
           case 0:  //  M1
            if ( GreatDoubles (curPrice,lastExtr_M5_up[0]) )  // если цена пробила экстремум на M5
             {
              indexHandleForTrail = 1;  // то переходим на M5
             }
           break;
           case 1:  // M5
            if ( GreatDoubles (curPrice,lastExtr_M15_up[0]) )  // если цена пробила экстремум на M15
             {
              indexHandleForTrail = 2;  // то переходим на M15
             }           
           break;
           case 2:  // M15
            if ( GreatDoubles (curPrice,lastExtr_H1_up[0]) )  // если цена пробила экстремум на H1
             {
              indexHandleForTrail = 3;  // то переходим на H1
             }           
           break;
          }
         // изменяем стоп лосс
         stopLoss = ExtremumsTrailing(_Symbol,OP_BUY,stopLoss,handleExtremums[indexHandleForTrail]);
        }
       // если позиция была открыта на SELL
       else if ( openedPosition == SELL)
        {
         // если было сделано меньше 4-х доливок 
         if ( countAddingToLot < 4 )
           {
            // если цена пробила последний нижний экстремум на M1
            if (LessDoubles(curPrice, lastExtr_M1_down[0]) )
             {
               // то доливаемся 
               currentLot = currentLot + lotStep;
               ctm.PositionChangeSize(_Symbol, lot);
               // и увеличиваем количество доливок на единицу
               countAddingToLot ++;
             } 
           }
         // трейлим стоп лосс
         switch (indexHandleForTrail)
          {
           case 0:  //  M1
            if ( LessDoubles (curPrice,lastExtr_M5_down[0]) )  // если цена пробила экстремум на M5
             {
              indexHandleForTrail = 1;  // то переходим на M5
             }
           break;
           case 1:  // M5
            if ( LessDoubles (curPrice,lastExtr_M15_down[0]) )  // если цена пробила экстремум на M15
             {
              indexHandleForTrail = 2;  // то переходим на M15
             }           
           break;
           case 2:  // M15
            if ( LessDoubles (curPrice,lastExtr_H1_down[0]) )  // если цена пробила экстремум на H1
             {
              indexHandleForTrail = 3;  // то переходим на H1
             }           
           break;
          }
         // изменяем стоп лосс
         stopLoss = ExtremumsTrailing(_Symbol,OP_SELL,stopLoss,handleExtremums[indexHandleForTrail]);
        }
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
    int copiedM1_up        = CopyBuffer(handleExtremums[0],2,1,1,lastExtr_M1_up);
    int copiedM1_down      = CopyBuffer(handleExtremums[0],3,1,1,lastExtr_M1_down);
    int copiedM5_up        = CopyBuffer(handleExtremums[1],2,1,1,lastExtr_M5_up);
    int copiedM5_down      = CopyBuffer(handleExtremums[1],3,1,1,lastExtr_M5_down);
    int copiedM15_up       = CopyBuffer(handleExtremums[2],2,1,1,lastExtr_M15_up);
    int copiedM15_down     = CopyBuffer(handleExtremums[2],3,1,1,lastExtr_M15_down);
    int copiedH1_up        = CopyBuffer(handleExtremums[3],2,1,1,lastExtr_H1_up);
    int copiedH1_down      = CopyBuffer(handleExtremums[3],3,1,1,lastExtr_H1_down);  
          
    
    if (copiedH1_down  < 1 ||
        copiedH1_up    < 1 ||
        copiedM15_down < 1 ||
        copiedM15_up   < 1 ||
        copiedM5_down  < 1 ||
        copiedM5_up    < 1 ||
        copiedM1_up    < 1 ||
        copiedM1_down  < 1
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
    
// трейлинг по экстремумам
double  ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, int handleExtremums)
 {
  double extrHigh[]; // буфер верхних экстремумов на младшем таймфрейме
  double extrLow[];  // буфер нижних экстремумов на младшем таймфрейме 
  double stopLoss;   // переменная для хранения нового стоп лосса 
  double currentPrice;  // текущая цена
  switch (type)
   {
    case OP_BUY:
     // извлекаем текущую цену
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);
     // если удалось прогрузить буферы
     if ( CopyBuffer(handleExtremums,2,1,1,extrHigh) == 1 &&
          CopyBuffer(handleExtremums,3,1,1,extrLow)  == 1 
        )
         {
           // если цена перевалила за верхний экстремум младшего таймфрейма 
           // и последний нижний экстремум лучше (выше), чем предыдущий стоп лосс
           if ( GreatDoubles(currentPrice,extrHigh[0]) && GreatDoubles(extrLow[0],sl) )
            {
             // сохраним новое значение стоп лосса
             stopLoss = extrLow[0];
             // очистим массивы
             ArrayFree(extrHigh);
             ArrayFree(extrLow);
             // то вернем стопЛосс на уровне последнего нижнего экстремума младшего таймфрейма
             return (stopLoss);
            }
         }
     
    break;
    case OP_SELL:
     // извлекаем текущую цену
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);
     // если удалось прогрузить буферы
     if ( CopyBuffer(handleExtremums,2,1,1,extrHigh) == 1 &&
          CopyBuffer(handleExtremums,3,1,1,extrLow)  == 1 
        )
         {
           // если цена перевалила за нижний экстремум младшего таймфрейма
           // и последний верхний экстремум лучше (ниже), чем предыдущий стоп лосс
           if ( LessDoubles(currentPrice,extrLow[0]) && LessDoubles(extrHigh[0],sl) )
            {
             // сохраним новое значение стоп лосса
             stopLoss = extrHigh[0];
             // очистим буферы
             ArrayFree(extrHigh);
             ArrayFree(extrLow);
             // то вернем стопЛосс на уровне последнего верхнего экстремума младшего таймфрейма
             return (stopLoss);
            }
         }
         
    break;
   }
  // освободим буферы
  ArrayFree(extrHigh);
  ArrayFree(extrLow);
  return (0.0);
 } 
   