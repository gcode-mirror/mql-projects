//+------------------------------------------------------------------+
//|                                  BIG_BROTHER_IS_WATCHING_YOU.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager\PositionArray.mqh>  // подключаем класс по работе с позициями

 // класс блокатора торговли
 class TradeBreak 
  {
   private:
    double _current_profit;     // текущая прибыль 
    double _current_drawdown;   // текущая просадка баланса
    double _min_profit;         // минимально допустимая прибыль
    double _max_drawdown;       // максимально допустимая просадка
    double _max_balance;        // максимальный баланс
    CPositionArray *_positionsHistory; //массив позиций, находящихся в истории    
   public:
    //---- описание системных методов класса 
    
    // обноваляет данные о текущей прибыли и просадке
    // возвращает true, если ни один из параметров не привысил допустимые нормы
    bool   UpdateData (CPositionArray * positionsHistory);
    // возвращает текущую прибыль
    double GetCurrentProfit() { return(_current_profit);};
    // возвращает  текущую просадку по балансу
    double GetCurrentDrawdown() { return(_current_drawdown); };  
   TradeBreak (double min_profit,double max_drawdown):
   _min_profit(min_profit),
   _max_drawdown(max_drawdown),
   _current_profit(0),
   _current_drawdown(0),
   _max_balance(0)
   {
   }; // конструктор класса 
  };
  
  //---- описания методов класса
  
  // обновляет данные о текущей прибыли и просадке
  bool TradeBreak::UpdateData(CPositionArray * positionsHistory)
   {
    int index;  // индекс прохода по циклу
    int length = positionsHistory.Total(); // длина переданного массива истории
    CPosition *pos; // указатель на текущую позицию
    // проходим по всем массиву и вычисляем текущую прибыль
    for (index = 0; index<length;index++)
     {
      // извлекаем указатель на текущую позицию по индексу
      pos = _positionsHistory.At(index);
      // изменяем текущую прибыль 
      _current_profit = _current_profit + pos.getPosProfit();
      //если баланс превысил текущий максимальный баланс
      if (_current_profit > _max_balance)  
        {
          // то перезаписываем его
          _max_balance = _current_profit;
        }
      else 
        {
        //если обнаружена больше просадка, чем была
         if ((_max_balance-_current_profit) > _current_drawdown) 
          {
           //то записываем новую просадку баланса
            _current_drawdown = _max_balance-_current_profit;  
          }
        }  
     }
     // если текущая прибыль меньше минимально допустимой
     // или если текущая просадка больше максимально допустимой
     if (_current_profit < _min_profit || _current_drawdown > _max_drawdown)
      return false; 
    return true;
   }