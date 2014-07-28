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
// системные переменные 
double curPrice;          // текущая цена
double prevPrice;         // предыдущая цена
int    stopLoss;          // стоп лосс
bool   openedPos = false; // флаг открытой позиции

// объекты классов 
CBlowInfoFromExtremums *blowInfo;               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 
CTradeManager *ctm;                             // торговая библиотека

// буферы для проверки пробития экстремумов
Extr             lastExtrHigh;                  // буфер последних экстремумов по HIGH
Extr             lastExtrLow;                   // буфер последних экстремумов по LOW
Extr             currentExtrHigh;               // буфер текущих экстремумов по HIGH
Extr             currentExtrLow;                // буфер текущих экстремумов по LOW
bool             extrHighBeaten=false;          // буфер флагов пробития экстремумов HIGH
bool             extrLowBeaten=false;           // буфер флагов пробития экстремумов LOW

int OnInit()
  {
   ctm = new CTradeManager();
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period,1000,30,30,217);
   if (!blowInfo.IsInitFine())
        return (INIT_FAILED);
   // пытаемся загрузить экстремумы
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
        {
         // получаем первые экстремумы
         lastExtrHigh   =  blowInfo.GetExtrByIndex(EXTR_HIGH,0);  // сохраним значение последнего экстремума HIGH
         lastExtrLow    =  blowInfo.GetExtrByIndex(EXTR_LOW,0);   // сохраним значение последнего экстремума LOW
       }
   else
     return (INIT_FAILED);   
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   iCustom(_Symbol,_Period,"DrawExtremums",_Period,1000,30,30,217);
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   delete ctm;
   delete blowInfo;
  }
void OnTick()
  {
    ctm.OnTick();
    ctm.UpdateData();
    ctm.DoTrailing(blowInfo);   
    prevPrice = curPrice;                                // сохраним предыдущую цену
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену     
    if (ctm.GetPositionCount() <= 0)
     {
      blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000);      
      // вычисляем стоп лосс по последнему нижнему экстремуму, переводим в пункты
      stopLoss = int(MathAbs(curPrice - blowInfo.GetExtrByIndex(EXTR_LOW,0).price)/_Point); 
      ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0,stopLoss,0,TRAILING_TYPE_EXTREMUMS);
      openedPos = true;
     }
  } 