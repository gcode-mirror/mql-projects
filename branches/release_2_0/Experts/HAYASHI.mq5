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



input double lot             = 1;          // лот
input int    n_spreads       = 1;          // количество спреда


  ///--------------------------------------------
  ///------------------------------------------ /
  ///                                        / /
  ///                                       / /
  ///                JAPAN                 / /
  ///              JAPANJAPAN             / /
  ///            JAPANJAPANJAPA          / /
  ///           JAPANJAPANJAPANJ        / /
  ///           JAPANJAPANJAPANJ        \ \ 
  ///            JAPANJAPANJAPA          \ \
  ///              JAPANJAPAN             \ \
  ///                JAPAN                 \ \
  ///                                       \ \
  ///                                        \ \
  ///-----------------------------------------  \
  ///--------------------------------------------
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  
//+------------------------------------------------------------------+
//| Эксперт Funayama (ex. HAYASHI)                                   |
//+------------------------------------------------------------------+

CTradeManager ctm();            // объект торговой библиотеки
bool   openedPosition = false;  // флаг окрытия позиции
double openPrice;               // цена открытия
double currentPrice;            // текущая цена
double spread;                  // спред

CisNewBar isNewBar(_Symbol, _Period);   // для проверки формирования нового бара

int OnInit()
  {

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  { 
    ctm.OnTick();
    // если сформирован новый бар
    if(isNewBar.isNewBar() > 0)
     {        

      if (openedPosition == false)
       { // если до этого момента еще не была открыта позиция
     
         if (ctm.OpenUniquePosition(_Symbol,_Period, OP_BUY, lot) )              // пытаемся открыться на BUY
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);                   // сохраняем цену открытия позиции
             openedPosition = true;                                              // флаг открытия позиции выставляем в true
           }
          
       }
      else
       {
         // если уже есть открытая позиция
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);                       // то сохраняем текущую цену открытия 

       }
       
     }
    else
     { // если бар не сформирован
       if (openedPosition == true)
        { // если была открыта позиция
         
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);                   // получаем текущую цену
          spread       = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice;    // вычисляем уровень спреда
         
          if ( (currentPrice - openPrice) > n_spreads*spread )
           {
              ctm.ClosePosition(_Symbol);                                        // закрываем позицию
              openedPosition = false;                                            // выставляем флаг открытия позиции в false
     
           }
      
        }
     }
  }