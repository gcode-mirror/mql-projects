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

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {
    static CisNewBar isNewBar(_Symbol, _Period);   // для проверки формирования нового бара
    double currentPrice;                           // текущая цена
    // если сформирован новый бар
    if(isNewBar.isNewBar() > 0)
     {
      if (openedPosition == false)
       { // если до этого момента еще не была открыта позиция
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, lot) ) // пытаемся открыться на BUY 
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // сохраняем цену открытия позиции
             openedPosition = true;                            // флаг открытия позиции выставляем в true
           }  
       }
      else
       {
         // если уже есть открытая позиция
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // то сохраняем текущую цену открытия 
       }
     }
    else
     { // если бар не сформирован
       if (openedPosition == true)
        { // если была открыта позиция
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // получаем текущую цену
          if ((currentPrice - openPrice) > 0.0001)
           { // если текущая цена превысила цену открытия
             
             ctm.ClosePosition(_Symbol); // закрываем позицию
             openedPosition = false;     // выставляем флаг открытия позиции в false
           }
        }
     }
  }