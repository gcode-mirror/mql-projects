//+------------------------------------------------------------------+
//|                                              BeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>   // торговая библиотека
#include <BlowInfoFromExtremums.mqh>       // библиотека для получения информации об экстемумах

// робот, торгующий на пробитии экстремума

// системные переменные
double currentPrice;               // переменная хранения текущей цены
ENUM_EXTR_USE   lastExtr;          // последний экстремум
ENUM_EXTR_USE   curExtr;           // текущий экстремум
bool   openedPosition = false;     // флаг открытия позиции

CTradeManager *ctm;                // торговая библиотека
CBlowInfoFromExtremums *blowInfo;  // объект класса для получения информации об экстремумах

int OnInit()
  {
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED);
   // первая загрузка экстремумов
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    { 
     lastExtr = blowInfo.GetLastExtrType();
    }
   else
    return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // удаляем объекты
   delete ctm;
   delete blowInfo;
  } 

void OnTick()
  {
   ctm.OnTick();
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )    // если удалось обновить данные об экстремумах
    {
    
     currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // получаем текущую цену
     curExtr = blowInfo.GetLastExtrType();                 // получаем последний тип экстремумов
     if (curExtr != lastExtr)                              // если пришел новый экстремум (противоположный)
      {
        lastExtr = curExtr;                                // сохраняем последний экстремум
        openedPosition = false;                            // выставляем флаг открытой позиции в false
      }
     if (!openedPosition)  // если нет открытой позиции
      {
        if (lastExtr == EXTR_HIGH)
         {
          if (currentPrice < blowInfo.GetExtrByIndex(EXTR_LOW,0).price )  // если цена пробила экстремум
           {
             // то открываем позицию на SELL
             ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
             openedPosition = true;
           }
         }
        if (lastExtr == EXTR_LOW)
         {
          if (currentPrice > blowInfo.GetExtrByIndex(EXTR_HIGH,0).price ) // если цена пробила экстремум
           {
            // то открываем позицию на BUY
            ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
            openedPosition = true;
           }
         }
       } // конец if(!openedPosition)
     } // конец Upload
  }