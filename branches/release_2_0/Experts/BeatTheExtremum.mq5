//+------------------------------------------------------------------+
//|                                           TmpBeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>    // торговая библиотека
#include <BlowInfoFromExtremums.mqh>        // библиотека для получения информации об экстемумах

// системные переменные
double currentPrice;                        // переменная хранения текущей цены
double previewPrice;                        // переменная хранения предыдущей цены
Extr             lastExtrHigh;              // последний экстремум HIGH
Extr             lastExtrLow;               // последний экстремум LOW
Extr             currentExtrHigh;           // текущий экстремум HIGH
Extr             currentExtrLow;            // текущий экстремум LOW
bool             extrHighBeaten = false;    // флаг пробития верхнего экстремума
bool             extrLowBeaten  = false;    // флаг пробития нижнего экстремума

CTradeManager *ctm;                         // торговая библиотека
CBlowInfoFromExtremums *blowInfo;           // объект класса для получения информации об экстремумах
CChartObjectHLine  horLine;                 // объект класса горизонтальной линии
CChartObjectHLine  horLine2;               

int OnInit()
  {
   horLine.Color(clrRed);
   horLine2.Color(clrLightGreen);
   previewPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED); 
   if (blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    {
      lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0);  // сохраним значение последнего экстремума HIGH
      lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0);   // сохраним значение последнего экстремума LOW
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
 
 int count; 
  
void OnTick()
  {
   ctm.OnTick();
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )    // если удалось обновить данные об экстремумах
    {
     currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // получаем текущую цену
     // получаем значения последних экстремумов
     currentExtrHigh  = blowInfo.GetExtrByIndex(EXTR_LOW,0);
     currentExtrLow   = blowInfo.GetExtrByIndex(EXTR_HIGH,0);
     if (currentExtrHigh.time != lastExtrHigh.time)        // если пришел новый HIGH экстремум
      {
       lastExtrHigh = currentExtrHigh;
       extrHighBeaten = false;
       horLine.Create(0,"high"+count,0,currentExtrHigh.price);
       count++;       
      }
     if (currentExtrLow.time != lastExtrLow.time)          // если пришел новый LOW экстремум
      {
       lastExtrLow = currentExtrLow;
       extrLowBeaten = false;
       horLine2.Create(0,"low"+count,0,currentExtrLow.price);
       
       count++;        
      } 
      
     
      
     if (GreatDoubles(currentPrice,lastExtrHigh.price) && LessDoubles(previewPrice,lastExtrHigh.price) && !extrHighBeaten)
      {
      Print("Цена=",DoubleToString(currentPrice)," Пред=",DoubleToString(previewPrice)," Экстремум=",DoubleToString(lastExtrHigh.price)," Время=",TimeToString(lastExtrHigh.time)); 
       extrHighBeaten = true;
       ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
      }     
     if (LessDoubles(currentPrice,lastExtrLow.price)&& GreatDoubles(previewPrice,lastExtrLow.price) && !extrLowBeaten)
      {
      Print("Цена=",DoubleToString(currentPrice)," Пред=",DoubleToString(previewPrice)," Экстремум=",DoubleToString(lastExtrLow.price)," Время=",TimeToString(lastExtrHigh.time));       
       extrLowBeaten = true;
       ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
      }       
    }   
    // записываем предыдущую цену
    previewPrice = currentPrice;
  }
  