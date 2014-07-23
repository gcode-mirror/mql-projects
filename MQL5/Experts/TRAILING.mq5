//+------------------------------------------------------------------+
//|                                                     TRAILING.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Робот для тестирования трейлинга                                 |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <Lib CisNewBarDD.mqh>             // для проверки формирования нового бара
#include <CompareDoubles.mqh>              // для сравнения вещественных чисел
#include <TradeManager\TradeManager.mqh>   // торговая библиотека
#include <BlowInfoFromExtremums.mqh>       // класс по работе с экстремумами индикатора DrawExtremums
#include <SIMPLE_TREND\SimpleTrendLib.mqh> // библиотека робота Simple Trend

input  ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_EXTREMUMS;  // тип трейлинга
input  double lot     = 0.1;                                       // начальный лот
input  double lot_step = 0.1;                                      // шаг увеличения лота

// системные переменные 
double curPrice;          // текущая цена
double prevPrice;         // предыдущая цена
double lotNow = lot;      // изначальный лот
int    stopLoss;          // стоп лосс
bool   openedPos = false; // флаг открытой позиции
int    indexForTrail = 0; // индекс для трейлинга

// объекты классов 
CBlowInfoFromExtremums *blowInfo[3];               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 
CTradeManager *ctm;                                // торговая библиотека

// буферы для проверки пробития экстремумов
Extr             lastExtrHigh[3];                  // буфер последних экстремумов по HIGH
Extr             lastExtrLow[3];                   // буфер последних экстремумов по LOW
Extr             currentExtrHigh[3];               // буфер текущих экстремумов по HIGH
Extr             currentExtrLow[3];                // буфер текущих экстремумов по LOW
bool             extrHighBeaten[3];                // буфер флагов пробития экстремумов HIGH
bool             extrLowBeaten[3];                 // буфер флагов пробития экстремумов LOW

int OnInit()
  {
   ctm = new CTradeManager();
   blowInfo[0] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,1000,clrLightYellow,clrYellow);
   blowInfo[1] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,clrLightBlue,clrBlue);
   blowInfo[2] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,clrPink,clrRed);
   if (!blowInfo[0].IsInitFine() || !blowInfo[1].IsInitFine() ||
       !blowInfo[2].IsInitFine())
        return (INIT_FAILED);
   // пытаемся загрузить экстремумы
   if ( blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) )
       
       
        {
         // получаем первые экстремумы
         for (int index=0;index<3;index++)
           {
            lastExtrHigh[index]   =  blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // сохраним значение последнего экстремума HIGH
            lastExtrLow[index]    =  blowInfo[index].GetExtrByIndex(EXTR_LOW,0);   // сохраним значение последнего экстремума LOW
           }
       }
   else
     return (INIT_FAILED);   
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
   ArrayInitialize(extrHighBeaten,false);
   ArrayInitialize(extrLowBeaten,false);  
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_M5,1000);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_M15,1000);
   iCustom(_Symbol,_Period,"DrawExtremums",PERIOD_H1,1000);           
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   delete ctm;
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
  }
void OnTick()
  {
    ctm.OnTick();
    ctm.DoTrailing(blowInfo[indexForTrail]);   
    prevPrice = curPrice;                                // сохраним предыдущую цену
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену     
    if (!openedPos)
     {
      // вычисляем стоп лосс по последнему нижнему экстремуму, переводим в пункты
      stopLoss = int(MathAbs(curPrice - blowInfo[0].GetExtrByIndex(EXTR_LOW,0).price)/_Point); 
      ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0,stopLoss,0,trailingType);
      openedPos = true;
     }
    if (blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000)  )
        {   
    // получаем новые значения экстремумов
    for (int index=0;index<3;index++)
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
     Comment("\nM5:  HIGH = ",DoubleToString(lastExtrHigh[0].price), " LOW = ",DoubleToString(lastExtrLow[0].price),
             "\nM15: HIGH = ",DoubleToString(lastExtrHigh[1].price), " LOW = ",DoubleToString(lastExtrLow[1].price),  
             "\nH1:  HIGH = ",DoubleToString(lastExtrHigh[2].price), " LOW = ",DoubleToString(lastExtrLow[2].price),
             "\n Текущая цена = ",DoubleToString(curPrice)," пред. цена = ",DoubleToString(prevPrice)     
      );
     // трейлим стоп лосс
     if (indexForTrail < 2)  // если индекс трейлинга меньше 2-х  
      {
       // если последним экстремумов являлся низких экстремум
       if (blowInfo[indexForTrail].GetLastExtrType() == EXTR_LOW)
        {
         // если пробили экстремум на более старшем таймфрейме
         if (IsExtremumBeaten ( indexForTrail+1, BUY) )
           {
             indexForTrail ++;  // то переходим на более старший таймфрейм
           }
        }
      }
   
    } //END OF UPLOADS
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