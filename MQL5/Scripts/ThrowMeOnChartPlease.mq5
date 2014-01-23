//+------------------------------------------------------------------+
//|                                         ThrowMeOnChartPlease.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>  // подключаем библиотеку бэктеста
#include <StringUtilities.mqh>        // подключаем библиотеку утилит 

//+------------------------------------------------------------------+
//| —крипт кидаетс€ на график и выводит следующую информацию:        |
//| - не ниже ли он какой либо прибыльности                          |
//| - не выше ли просадка заданной нормы                             |
//+------------------------------------------------------------------+

//---- входные параметры скрипта

input double   min_profit=0;   // минимально допустимый уровень прибыльности
input double   max_drawdown=0; // максимально допустимый уровень просадки баланса 
input datetime from=0;         // период с какого
input datetime to=0;           // по какое


//---- функци€ возвращает им€ эсперта на данном графике

string  GetExpertName ()
 {
  return "TIHIRO";
 }

//---- функци€ возвращает адрес файла истории

string GetHistoryFileName ()
 {
  string str="";
  
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "History", GetExpertName(), _Symbol, PeriodToString(_Period));
  return str;
 }

void OnStart()
  {
   BackTest backtest;          // объект класса бэктеста
   double  drawdown;           // просадка по балансу
   double  full_profit;        // прибыль 
   // пытаемс€ загрузить историю из файла
   
   if (backtest.LoadHistoryFromFile(GetHistoryFileName(),from,to) )
    {    
     // получаем просадку по балансу и конечную прибыль 
     drawdown = backtest.GetMaxDrawdown(_Symbol);
     // получаем конечную прибыль
     full_profit = backtest.GetTotalProfit(_Symbol);
     // если просада привысила допустимую норму или конечна€ прибыль меньше допустимого минимума  
     if (drawdown > max_drawdown || full_profit < min_profit)
      {
       Alert("Ёксперта необходимо остановить");
      }
     else
      {
       Alert("Ёксперт может продолжить работать");
      }
    }
  }
