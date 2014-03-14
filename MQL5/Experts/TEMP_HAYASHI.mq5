//+------------------------------------------------------------------+
//|                                                      HAYASHI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>  // торговая библиотека
#include <CompareDoubles.mqh>             // для сравнения вещественных чисел
#include <Lib CisNewBar.mqh>              // для формирования нового бара

input double lot             = 1;  // размер лота
input double priceDifference = 10; // разница цен в пунктах

//+------------------------------------------------------------------+
//| Эксперт Хаяcи                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // флаг окрытия позиции
double openPrice;               // цена открытия
int    stopLoss;                // уровень стопа
datetime history_start;

int OnInit()
  {
   history_start=TimeCurrent();    
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {
    static CisNewBar isNewBar(_Symbol, _Period);   // для проверки формирования нового бара
    double currentPrice;                           // текущая цена
    double spread;                                 // спред
    // если сформирован новый бар
    if(isNewBar.isNewBar() > 0)
     {
      if (openedPosition == false)
       { // если до этого момента еще не была открыта позиция
        // stopLoss = ( SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID) )/_Point;
         stopLoss = 30;
         Comment("СТОП ЛОСС = ",stopLoss);
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, lot,stopLoss) ) // пытаемся открыться на BUY 
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // сохраняем цену открытия позиции
             openedPosition = true;                            // флаг открытия позиции выставляем в true
           }  
       }
      else
       {
         // если уже есть открытая позиция
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // то сохраняем текущую цену открытия 
         stopLoss = ( SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID) )/_Point;       
       }
     }
    if (ctm.isHistoryChanged())
     {
      Alert("ЗАКРЫЛИ");
      openedPosition = false;
     }
  }
  
void OnTrade()
 {
     ctm.OnTrade(history_start);
 }