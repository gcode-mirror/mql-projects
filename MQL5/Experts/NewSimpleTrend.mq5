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
#include <Lib CisNewBarDD.mqh>                     // для проверки формирования нового бара
#include <CompareDoubles.mqh>                      // для сравнения вещественных чисел
#include <TradeManager\TradeManager.mqh>           // торговая библиотека
#include <BlowInfoFromExtremums.mqh>               // класс по работе с экстремумами индикатора DrawExtremums
#include <SIMPLE_TREND\SimpleTrendLib.mqh>         // библиотека робота Simple Trend
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
int              stopLoss;                         // стоп лосс
int              indexForTrail     = 0;            // индекс для трейлинга
double           curPrice          = 0;            // для хранения текущей цены
double           prevPrice         = 0;            // для хранения предыдущей цены
ENUM_TENDENTION  lastTendention;                   // переменная для хранения последней тенденции
// буферы для хранения расхождений на MACD
double divMACD_M5[];                               // на пятиминутке
double divMACD_M15[];                              // на 15-минутке
double divMACD_H1[];                               // на часовике
// буферы для проверки пробития экстремумов
Extr             lastExtrHigh[4];                  // буфер последних экстремумов по HIGH
Extr             lastExtrLow[4];                   // буфер последних экстремумов по LOW
Extr             currentExtrHigh[4];               // буфер текущих экстремумов по HIGH
Extr             currentExtrLow[4];                // буфер текущих экстремумов по LOW
bool             extrHighBeaten[4];                // буфер флагов пробития экстремумов HIGH
bool             extrLowBeaten[4];                 // буфер флагов пробития экстремумов LOW
                           
int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"TemparySMYDMACD","",clrBlue);  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"TemparySMYDMACD","",clrRed);    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"TemparySMYDMACD","",clrGreen);   
   if (handleSmydMACD_M5  == INVALID_HANDLE || handleSmydMACD_M15 == INVALID_HANDLE || handleSmydMACD_H1 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD ");
     return (INIT_FAILED);
    }              
   // создаем объект класса TradeManager
   ctm = new CTradeManager();                    
   // создаем объекты класса CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   // создаем объекты класса CBlowInfoFromExtremums
   blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,1000,clrLightYellow,clrYellow); // минутка
   blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,1000,clrLightBlue,clrBlue);     // 5-ти минутка
   blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,clrPink,clrRed);          // 15-ти минутка
   blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,1000,clrLightGreen,clrGreen);   // часовик    
   if (!blowInfo[0].IsInitFine() || !blowInfo[1].IsInitFine() ||
       !blowInfo[2].IsInitFine() || !blowInfo[3].IsInitFine()  )
        return (INIT_FAILED);
   // пытаемся загрузить экстремумы
   if ( blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
       )
        {
         // получаем первые экстремумы
         for (int index=0;index<4;index++)
           {
            lastExtrHigh[index]   =  blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // сохраним значение последнего экстремума HIGH
            lastExtrLow[index]    =  blowInfo[index].GetExtrByIndex(EXTR_LOW,0);   // сохраним значение последнего экстремума LOW
           }
       }
   else
     return (INIT_FAILED);
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_M1,1000);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_M5,1000);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_M15,1000);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_H1,1000);   
   ArrayInitialize(extrHighBeaten,false);
   ArrayInitialize(extrLowBeaten,false);   
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
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
   delete blowInfo[3];
  }

void OnTick()
  {  
   
    ctm.OnTick(); 
    ctm.UpdateData();
    ctm.DoTrailing(blowInfo[indexForTrail]);
    prevPrice = curPrice;                                // сохраним предыдущую цену
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену     
    if (blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
         )
        {   
    // получаем новые значения экстремумов
    for (int index=0;index<4;index++)
      {
       currentExtrHigh[index]  = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);
       currentExtrLow[index]   = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);    
       if (currentExtrHigh[index].time != lastExtrHigh[index].time)          // если пришел новый HIGH экстремум
        {
         lastExtrHigh[index] = currentExtrHigh[index];   // то сохраняем текущий экстремум в качестве последнего
         extrHighBeaten[index] = false;                  // и выставляем флаг пробития  в false     
        }
       if (currentExtrLow[index].time != lastExtrLow[index].time)            // если пришел новый LOW экстремум
        {
         lastExtrLow[index] = currentExtrLow[index];     // то сохраняем текущий экстремум в качестве последнего
         extrLowBeaten[index] = false;                   // и выставляем флаг пробития в false
        } 
      } 
              
    // если это первый запуск эксперта или сформировался новый бар 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
    {
     firstLaunch = false;
     if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )     
      {
       lastTendention = GetTendention(lastBarD1[0].open,lastBarD1[0].close);        // получаем предыдущую тенденцию 
      }
    }
     // если общая тенденция  - вверх
     if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_UP)
     {   
      // если текущая цена пробила один из экстемумов на одном из таймфреймов
      if ( IsExtremumBeaten(0,BUY) || IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) )
      {
       // если текущее расхождение MACD НЕ противоречит текущему движению
       if (IsMACDCompatible(BUY))
       {                 
        // вычисляем стоп лосс по последнему нижнему экстремуму, переводим в пункты
        stopLoss = int(MathAbs(curPrice - blowInfo[0].GetExtrByIndex(EXTR_LOW,0).price)/_Point);      
        // открываем позицию на BUY
        ctm.OpenUniquePosition(_Symbol, _Period, OP_BUY, 1.0, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
        // выставляем флаг открытия позиции BUY
        openedPosition = BUY;                
       } 
      }
     }
     // если общая тенденция - вниз
     if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_DOWN)
     {              
      // если текущая цена пробила один из экстемумов на одном из таймфреймов
      if ( IsExtremumBeaten(0,SELL) || IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL)  )
      {    
       // если текущее расхождение MACD НЕ противоречит текущему движению
       if (IsMACDCompatible(SELL))
       {
        // вычисляем стоп лосс по последнему экстремуму, переводим в пункты
        stopLoss = int(MathAbs(curPrice-blowInfo[0].GetExtrByIndex(EXTR_HIGH,0).price)/_Point);
        // открываем позицию на SELL
        ctm.OpenUniquePosition(_Symbol, _Period, OP_SELL, 1.0, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
        // выставляем флаг открытия позиции SELL
        openedPosition = SELL;                                         
       } 
      }      
     }
    

    }  // END OF UPLOAD EXTREMUMS
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
  switch (direction)
   {
    case BUY:
    if (LessDoubles(curPrice,lastExtrLow[index].price)&& GreatDoubles(prevPrice,lastExtrLow[index].price) && !extrLowBeaten[index])
      {      
       extrLowBeaten[index] = true;
       return (true);    
      }     
    break;
    case SELL:
    if (GreatDoubles(curPrice,lastExtrHigh[index].price) && LessDoubles(prevPrice,lastExtrHigh[index].price) && !extrHighBeaten[index])
      {
       extrHighBeaten[index] = true;
       return (true);
      }     
    break;
   }
  return (false);
 }
 
void  ChangeTrailIndex()   // функция трейлит 
 {
  // трейлим стоп лосс
  if (indexForTrail < 2)  // если индекс трейлинга меньше 2-х  
    {
     // если пробили экстремум на более старшем таймфрейме
     if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
       {
        indexForTrail ++;  // то переходим на более старший таймфрейм
       }
    }
 }   