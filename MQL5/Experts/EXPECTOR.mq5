//+------------------------------------------------------------------+
//|                                                     EXPECTOR.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Constants.mqh>
#include <TradeManager\Backtest.mqh>

//+------------------------------------------------------------------+
//| Робот, прерывающий работу запущенных экспертов по просадке       |
//+------------------------------------------------------------------+

// вводимые пользователем параметры
input double max_drawdown = 1;  // максимальный уровень просадки
input double min_profit   = 1;  // минимально допустимая текущая прибыль 

// глобальные параменные экспектора
datetime time_from;             // время, с которого начать считывать историю из файла
BackTest backtest;              // объект бэктеста


//---- функция возвращает адреса файла истории 
string GetFileHistory (string from_var)
 {
  string expertName = StringSubstr(from_var,1,StringFind(from_var,"_")-1);
  return expertName+"//"+"History"+"//"+StringSubstr(from_var,1)+".csv";
 } 

int OnInit()
  {
   // сохраняем время при запуске Экспектора
   time_from = TimeCurrent();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()
  {
   int index;                             // индекс цикла по глобальным переменным
   int totalVar = GlobalVariablesTotal(); // колчиество глобальных переменных
   string file_history;                   // строка, содержащая имя файла истории
   datetime  current_time;                // текущее время 
   double    current_profit;              // текущая прибыль
   double    current_drawdown;            // текущая просадка по балансу
   // проходим по всем глобальным переменным
   for (index = 0; index < totalVar; index++)
    {
     // если обнаружена переменная-флаг какого либо эксперта
     if (StringSubstr(GlobalVariableName(index), 0, 1) == "&")
      {    
        // если эксперт записал что-то в историю позиций
        if (GlobalVariableGet(GlobalVariableName(index)) == TradeModeToInt(TM_DEAL_DONE) )
         {
           // сформируем имя файла истории
           file_history = GetFileHistory(GlobalVariableName(index));
           // загружаем историю позиций из файла  
           if ( backtest.LoadHistoryFromFile(file_history,time_from,TimeCurrent()) )
            {// если история позиций успешна загрузилась
            // вычисляем текущую просадку по балансу
            current_drawdown = backtest.GetMaxDrawdown();
            // вычисляем текущую прибыль
            backtest.GetProfits();
            // получаем значение текущей прибыли
            current_profit = backtest.GetCleanProfit();
            // если параметры привысили допустимые параметры 
            Alert("ПРИБЫЛЬ РАВНА = ",current_profit," ПРОСАДКА = ",current_drawdown);
            if (current_drawdown > max_drawdown || current_profit < min_profit)
             {
             // то выставляем переменную в CANNOT_TRADE, т.е. прерываем торговлю эксперта
             GlobalVariableSet(GlobalVariableName(index), TradeModeToInt(TM_CANNOT_TRADE) );
             }
            else
             {
             // то выставляем переменную в режим "не было новых сделок"
             GlobalVariableSet(GlobalVariableName(index), TradeModeToInt(TM_NO_DEALS) );            
             }
             }
         }
      }  
    } 
 
  }
