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
double currentPrice;                // переменная хранения текущей цены
ENUM_EXTR_USE   lastExtrType;       // тип последнего экстремума
ENUM_EXTR_USE   curExtrType;        // тип текущего экстремума
double          lastExtrValue;      // значение последнего экстремума
bool            extrBeaten = false; // флаг пробития экстремума

CTradeManager *ctm;                 // торговая библиотека
CBlowInfoFromExtremums *blowInfo;   // объект класса для получения информации об экстремумах
CChartObjectHLine  horLine;         // объект класса горизонтальной линии
int OnInit()
  {
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED); 
   if (blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    {
     lastExtrType = blowInfo.GetLastExtrType(); // сохраняем тип последнего экстремума  
     if (lastExtrType == EXTR_HIGH)
       {
        lastExtrValue = blowInfo.GetExtrByIndex(EXTR_LOW,1).price;  // сохраним значение последнего экстремума
       }
     else if (lastExtrType == EXTR_LOW)
       {
        lastExtrValue = blowInfo.GetExtrByIndex(EXTR_HIGH,1).price; // сохраним значение последнего экстремума
       }
     else 
      return (INIT_FAILED);
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
     curExtrType  = blowInfo.GetLastExtrType();            // получаем значение последнего экстремума
     
     // временный индусский код для проверки
     if (curExtrType == EXTR_HIGH)
       curExtrType = EXTR_LOW;
     else if (curExtrType == EXTR_LOW)
       curExtrType = EXTR_HIGH;
     
     
     
     if (curExtrType != lastExtrType)                      // если пришел противоположный экстремум
      {

        // то сохраним текущий экстремум
        lastExtrType = curExtrType;
        // и его значение
        if (lastExtrType == EXTR_HIGH)
         lastExtrValue = blowInfo.GetExtrByIndex(EXTR_LOW,1).price;
        if (lastExtrType == EXTR_LOW)
         lastExtrValue = blowInfo.GetExtrByIndex(EXTR_HIGH,1).price;         
        // и флаг пробития экстремума выставим в false
        extrBeaten = false;
      }       
     
     Comment("ПОСЛЕДНИЙ ЭКСТРЕМУМ = ",DoubleToString(lastExtrValue) ); 
     horLine.Create(0,"kolk",0,lastExtrValue);
   
     
      
     if (lastExtrType == EXTR_HIGH && !extrBeaten)         // если последний экстремум HIGH и и предыдущий экстремум не пробит
      {
        //то проверяем, пробит ли экстремум
        if (currentPrice < lastExtrValue)
          {
           // открываем позицию
           ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
           // и выставляем флаг пробития экстремума в true
           extrBeaten = true;
          }
      }
     if (lastExtrType == EXTR_LOW && !extrBeaten)         // если последний экстремум HIGH и и предыдущий экстремум не пробит
      {
        //то проверяем, пробит ли экстремум
        if (currentPrice > lastExtrValue)
          {
           // открываем позицию
           ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
           // и выставляем флаг пробития экстремума в true
           extrBeaten = true;
          }
      }      
      
      
    } // конец Upload
  }