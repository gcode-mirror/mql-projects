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

enum SYMBOLS 
 {
  SYM_EURUSD=0,
  SYM_GBPUSD,
  SYM_USDCHF,
  SYM_USDJPY,
  SYM_USDCAD,
  SYM_AUDUSD
 };


input double lot             = 1;          // лот
input int    n_spreads       = 1;          // количество спреда
input SYMBOLS sym            = SYM_EURUSD; // символ
input ENUM_TIMEFRAMES per    = PERIOD_M1;  // период


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
//| Эксперт Хаяcи                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // флаг окрытия позиции
double openPrice;               // цена открытия
string symb;

    static CisNewBar isNewBar(symb, per);   // для проверки формирования нового бара

MqlDateTime timeStr;            // структура времени для хранения текущего времени

int OnInit()
  {
   switch (sym)
    {
     case SYM_EURUSD:
      symb = "EURUSD";
     break;
     case SYM_AUDUSD:
      symb = "AUDUSD";
     break;
     case SYM_GBPUSD:
      symb = "GBPUSD";
     break;
     case SYM_USDCAD:
      symb = "USDCAD";
     break;
     case SYM_USDCHF:
      symb = "USDCHF";
     break;
     case SYM_USDJPY:
      symb = "USDJPY";
     break;
    }
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  { 

    double currentPrice;                           // текущая цена
    double spread;                                 // спред
    
    // если сформирован новый бар
    if(isNewBar.isNewBar() > 0)
     {        
      if (openedPosition == false)
       { // если до этого момента еще не была открыта позиция
     
         if (ctm.OpenUniquePosition(symb,per, OP_SELL, lot) ) // пытаемся открыться на SELL
           {
             openPrice = SymbolInfoDouble(symb,SYMBOL_BID);       // сохраняем цену открытия позиции
             openedPosition = true;                                  // флаг открытия позиции выставляем в true
           }
          
       }
      else
       {
         // если уже есть открытая позиция
         openPrice = SymbolInfoDouble(symb,SYMBOL_BID); // то сохраняем текущую цену открытия 

       }
     }
    else
     { // если бар не сформирован
       if (openedPosition == true)
        { // если была открыта позиция
         
          currentPrice = SymbolInfoDouble(symb,SYMBOL_ASK);                // получаем текущую цену
          spread       = currentPrice - SymbolInfoDouble(symb,SYMBOL_BID); // вычисляем уровень спреда
         
          if ( (currentPrice - openPrice) > n_spreads*spread )
           {
              ctm.ClosePosition(symb);             // закрываем позицию
             openedPosition = false;                  // выставляем флаг открытия позиции в false
     
           }
       
          
           
               
        }
     }
  }