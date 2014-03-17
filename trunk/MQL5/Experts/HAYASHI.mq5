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

input double lot             = 0.1;  // изначальный размер лота
input double max_lot         = 1;    // максимальный размер лота
input double lot_diff        = 0.1;  // единица изменения лота
input double aver            = 8;    // среднее длина серии

//+------------------------------------------------------------------+
//| Эксперт Хаяcи                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // флаг окрытия позиции
double openPrice;               // цена открытия
bool   was_a_part = false;      // флаг подсчета серии
int    count_long = 0;          // счетчик длины серии
double current_lot = lot;       // текущий лот

int    startPeriod  = 10;       // время в часах - начало волатильности
int    finishPeriod = 20;       // время в часах - конец волатильности

MqlDateTime timeStr;            // структура времени для хранения текущего времени
int    handlePBI;               // хэндл индикатора-расскраски

double bufferPBI[];             // буфер индикатора-расскраски 



int OnInit()
  {
   // пытаемся загрузить хэндл индикатора-расскраски
   handlePBI = iCustom (_Symbol,_Period,"test_PBI_NE");
   // если хэндл не действителен 
   if ( handlePBI == INVALID_HANDLE)
    return (INIT_FAILED);  // то возвращаем неудачную инициализацию
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
    ArrayFree(bufferPBI);
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
         
         TimeCurrent(timeStr);  // получаем текущее время
        
        // пытаемся извлечь значение индикаторного бара
        if ( CopyBuffer(handlePBI,4,1,1,bufferPBI) < 1)  
         return;
         
         // если сейчас не ночное время суток 
         if ( timeStr.hour >= startPeriod && timeStr.hour <= finishPeriod &&  ( bufferPBI[0] == 7 || bufferPBI[0] == 2 || bufferPBI[0] == 1) )
          {
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, current_lot) ) // пытаемся открыться на BUY 
           {
           //  Comment("ТЕКУЩИЙ ЛОТ = "+current_lot);
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // сохраняем цену открытия позиции
             openedPosition = true;                            // флаг открытия позиции выставляем в true
             was_a_part     = true;                            // открыли новую позицию, значит можно начать подсчет длины серии
           }
          }  
       }
      else
       {
         // если уже есть открытая позиция
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // то сохраняем текущую цену открытия 
         count_long = 0; // обнуляем счетчик серии 
         was_a_part     = false;  // больше серию не подсчитываем
         current_lot    = lot;    // выставляем текущий лот на начальный уровень
       }
     }
    else
     { // если бар не сформирован
       if (openedPosition == true)
        { // если была открыта позиция
         
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // получаем текущую цену
          spread = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice; // вычисляем уровень спреда
         
          if ((currentPrice - openPrice) < spread)
           { // если текущая цена превысила цену открытия
             
             ctm.ClosePosition(_Symbol); // закрываем позицию
             openedPosition = false;     // выставляем флаг открытия позиции в false
             count_long ++;              // увеличиваем длину серии
             if ( (current_lot+lot_diff) < max_lot)  // если лот не превысил допустимые нормы
                current_lot = current_lot + lot_diff; // увеличиваем лот
             
              
           }
        }
     }
  }