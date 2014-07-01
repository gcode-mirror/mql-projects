//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Робот, торгующий на простом тренде                               |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <Lib CisNewBarDD.mqh>           // для проверки формирования нового бара
#include <CompareDoubles.mqh>            // для сравнения вещественных чисел
#include <TradeManager\TradeManager.mqh> // торговая библиотека
#include <BlowInfoFromExtremums.mqh>     // класс по работе с экстремумами индикатора DrawExtremums

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
sinput string baseStr = "";                                        // ОСНОВНЫЕ ПАРАМЕТРЫ
input  double lot     = 0.1;                                       // начальный лот
input  double lot_step = 0.1;                                      // шаг увеличения лота
input  ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_EXTREMUMS;  // тип трейлинга

// хэндлы индикатора SmydMACD
int handleSmydMACD_M5;                             // хэндл индикатора расхождений MACD на минутке
int handleSmydMACD_M15;                            // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydMACD_H1;                             // хэндл индикатора расхождений MACD на часовике

// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике

// объекты классов
CTradeManager *ctm;                                // объект торговой библиотеки
CisNewBar     *isNewBar_D1;                        // новый бар на D1
CBlowInfoFromExtremums *blowInfo[4];               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 

// дополнительные системные переменные
bool             firstLaunch       = true;         // флаг первого запуска эксперта
int              openedPosition    = 0;            // тип открытой позиции 
int              countAddingToLot  = 0;            // счетчик доливок
int              indexForTrail     = 0;            // индекс объекта BlowInfoFromExtremums для трейлинга 
double           curPrice          = 0;            // для хранения текущей цены
double           prevPrice         = 0;            // для хранения предыдущей цены
double           stopLoss;                         // переменная для хранения стоп лосса
ENUM_TENDENTION  lastTendention;                   // переменная для хранения последней тенденции

// буферы для хранения расхождений на MACD
double divMACD_M5[];                               // на пятиминутке
double divMACD_M15[];                              // на 15-минутке
double divMACD_H1[];                               // на часовике

// описание системных функций робота
ENUM_TENDENTION GetTendention(double priceOpen,double priceAfter);  // возвращает тенденцию 
bool            IsMACDCompatible (int direction);  // проверяет совместимость расхождений MACD с текущей тенденцией
bool            IsExtremumBeaten (int index,
                                  int direction);  // проверяет пробитие экстремума по индексу
                                  
  

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD");  
       
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
   // создаем объект класса TradeManager
   ctm = new CTradeManager();                    
   // создаем объекты класса CisNewBar
   isNewBar_D1 = new CisNewBar(_Symbol,PERIOD_D1);
   // создаем объекты класса CBlowInfoFromExtremums
   blowInfo[0] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1);   // минутка
   blowInfo[1] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5);   // 5-ти минутка
   blowInfo[2] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15);  // 15-ти минутка
   blowInfo[3] = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1);   // часовик      
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // освобождаем буферы
   ArrayFree(divMACD_M5);
   ArrayFree(divMACD_M15);
   ArrayFree(divMACD_H1);
   ArrayFree(lastBarD1);
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   // удаляем объекты классов
   delete ctm;
   delete isNewBar_D1;
  }

void OnTick()
  {
    blowInfo[0].Upload();
    blowInfo[1].Upload();
    blowInfo[2].Upload();
    blowInfo[3].Upload();
    ctm.OnTick(); 
    ctm.UpdateData();
    ctm.DoTrailing(blowInfo[indexForTrail]);
    prevPrice = curPrice;                                // сохраним предыдущую цену
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену
    // если это первый запуск эксперта или сформировался новый бар 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
    {
     firstLaunch = false;
     if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )     
      {
       lastTendention = GetTendention(lastBarD1[0].open,lastBarD1[0].close);        // получаем предыдущую тенденцию 
      }
    }
                   
    Comment("Экстремум верхний H1 = ",DoubleToString(blowInfo[3].GetExtrByIndex(EXTR_HIGH,1).price) );       
    
    // на каждом тике 
    if ( ctm.GetPositionCount() == 0 )   // если позиция еще не открыта
    {
     // если общая тенденция  - вверх
     if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_UP)
     {
      // если текущая цена пробила один из экстемумов на одном из таймфреймов
      if ( IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) || IsExtremumBeaten(3,BUY) )
      
      {
       // если текущее расхождение MACD НЕ противоречит текущему движению
       if (IsMACDCompatible(BUY))
       {                 
        // вычисляем стоп лосс по последнему нижнему экстремуму, переводим в пункты
        stopLoss = int(blowInfo[1].GetExtrByIndex(EXTR_LOW,0).price/_Point);
        // открываем позицию на BUY
        ctm.OpenUniquePosition(_Symbol, _Period, OP_BUY, lot, stopLoss, 0, trailingType);
        // выставляем флаг открытия позиции BUY
        openedPosition = BUY;         
        // обнуляем индекс хэндлов индикатора Extremums для трейлинга
        indexForTrail = 0;           
       } 
       
      }
     }
     // если общая тенденция - вниз
     if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_DOWN)
     {       
      // если текущая цена пробила один из экстемумов на одном из таймфреймов
      if ( IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL) || IsExtremumBeaten(3,SELL)   )
      {
     //  Comment("Общая тенденция ВНИЗ"); 
       // если текущее расхождение MACD НЕ противоречит текущему движению
       if (IsMACDCompatible(SELL))
       {
        // вычисляем стоп лосс по последнему экстремуму, переводим в пункты
        stopLoss = int(blowInfo[1].GetExtrByIndex(EXTR_HIGH,0).price/_Point);
        // открываем позицию на SELL
        ctm.OpenUniquePosition(_Symbol, _Period, OP_SELL, lot, stopLoss, 0, trailingType);
        // выставляем флаг открытия позиции SELL
        openedPosition = SELL;  
        // обнуляем индекс хэндлов индикатора Extremums для трейлинга
        indexForTrail = 0;                                         
       } 
      }      
     }
    }
    // если есть открытые позиции
    else
    { 
      // если позиция была открыта на BUY
      if (openedPosition == BUY) 
       {
        if (countAddingToLot < 4)
          {
           // если цена пробила последний верхний экстремум на M1
           if ( IsExtremumBeaten(0,BUY) )
            {
             // то доливаемся 
             ctm.PositionChangeSize(_Symbol, lot_step);
             // и увеличиваем количество доливок на единицу
             countAddingToLot++;
            } 
          }
         // если еще можно переходить на более старший таймфрейм
         if ( indexForTrail < 3)
           {
            if (  IsExtremumBeaten (indexForTrail+1,BUY) )    // если цена пробила экстремум текущего таймфрейма
               indexForTrail ++; 
           }          
       }

      // если позиция была открыта на SELL
      if (openedPosition == SELL) 
       {
        if (countAddingToLot < 4)
          {
           // если цена пробила последний верхний экстремум на M1
           if ( IsExtremumBeaten(0,SELL) )
            {
             // то доливаемся 
             ctm.PositionChangeSize(_Symbol, lot_step);
             // и увеличиваем количество доливок на единицу
             countAddingToLot++;
            } 
          }
         // если еще можно переходить на более старший таймфрейм
         if ( indexForTrail < 3)
           {
            if (  IsExtremumBeaten (indexForTrail+1,SELL) )    // если цена пробила экстремум текущего таймфрейма
               indexForTrail ++; 
           }          
       }       
       
       
    }
   }
  
 // кодирование функций
 
 ENUM_TENDENTION GetTendention (double priceOpen,double priceAfter)            // возвращает тенденцию по двум ценам
  {
      if ( GreatDoubles (priceAfter,priceOpen) )
       return (TENDENTION_UP);
      if ( LessDoubles  (priceAfter,priceOpen) )
       return (TENDENTION_DOWN); 
    return (TENDENTION_NO); 
  }
  
bool IsMACDCompatible(int direction)        // проверяет, не противоречит ли расхождение MACD текущей тенденции
{
 int copiedMACD_M5  = CopyBuffer(handleSmydMACD_M5,1,0,1,divMACD_M5);
 int copiedMACD_M15 = CopyBuffer(handleSmydMACD_M15,1,0,1,divMACD_M15);
 int copiedMACD_H1  = CopyBuffer(handleSmydMACD_H1,1,0,1,divMACD_H1);   
   
 if (copiedMACD_M5  < 1 || copiedMACD_M15 < 1 || copiedMACD_H1  < 1)
 {
  Print("Ошибка эксперта SimpleTrend. Не удалось получить данные о расхождениях");
  return (false);
 }        
 // dir = 1 или -1, div = -1 или 1; Если расхождение против направления, то рез-т будет 0 = false, в противном случае true
 return ((divMACD_M5[0]+direction) && (divMACD_M15[0]+direction) && (divMACD_H1[0]+direction));
}

bool IsExtremumBeaten (int index,int direction)   // проверяет пробитие ценой экстремума
 {
  Extr   lastExtrHigh;                                         // последний HIGH экстремум
  Extr   lastExtrLow;                                          // последний LOW экстремум
  ENUM_EXTR_USE last_extr;                                     // переменная для хранения последнего экстремума 
   // получаем тип последнего экстремума
   last_extr = blowInfo[index].GetLastExtrType();
   if (last_extr == EXTR_NO)
    return (0.0);
   if (direction == OP_BUY)
    {
     // если последним экстремумом был HIGH или BOTH
     if (last_extr == EXTR_HIGH || last_extr == EXTR_BOTH)
       lastExtrHigh = blowInfo[index].GetExtrByIndex(EXTR_HIGH,1);  // то берем для пробития предпоследний экстремум
     if (last_extr == EXTR_LOW)
      lastExtrHigh  = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // то берем для пробития последний экстремум 
     lastExtrLow = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);      // получаем последний нижний экстремум
     // если текущая цена пробила последний значимый HIGH экстремум
     if ( GreatDoubles(curPrice,lastExtrHigh.price) && GreatDoubles(lastExtrHigh.price,prevPrice) && prevPrice > 0 )
      {
       // то возвратим true (цена пробила экстремум)
       return (true);
      }
    }
    
   if (direction == OP_SELL)
    {
      // если последним экстремумом был LOW или BOTH
      if (last_extr == EXTR_LOW || last_extr == EXTR_BOTH)
       lastExtrLow = blowInfo[index].GetExtrByIndex(EXTR_LOW,1);  // то берем для пробития предпоследний экстремум
      if (last_extr == EXTR_HIGH)
       lastExtrLow  = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);  // то берем для пробития последний экстремум 
      lastExtrHigh = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // получаем последний верхний экстремум
      // если текущая цена пробила последний значимый HIGH экстремум 
      if ( LessDoubles(curPrice,lastExtrLow.price) && LessDoubles(lastExtrLow.price,prevPrice) && prevPrice > 0 )
       {
        // то возвратим true (цена пробила экстремум)
        return (true);
       }
    }
  return (false);
 }   