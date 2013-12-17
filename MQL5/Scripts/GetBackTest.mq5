//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>    //подключаем библиотеку бэктеста
#include <StringUtilities.mqh>          //подключаем библиотеку констант
#include <Charts\Chart.mqh>
#include <Expertoscop\CExpertoScop.mqh> //подключаем класс экспертоскопа


//+------------------------------------------------------------------+
//| Скрипт вычисления результатов бэктеста для запущенных экспертов  |
//+------------------------------------------------------------------+

 
input datetime time_from=0;                      // время с которого вычислять параметры бэктеста
input datetime time_to=0;                        // время, по какое вычисляеть параметры бэктеста

BackTest backtest;                               // объект класса бэктеста

CExpertoscop * expscop  = new CExpertoscop();    // объект класса экспертоскопа

//---- функция возвращает адрес файла истории

string GetHistoryFileName (string exp_name,string sym,string  tf)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv",exp_name, "History",exp_name, sym, tf);
  return str;
 }
 
//---- функция возвращает адрес файла результатов вычислений бэктеста 
 
string GetBackTestFileName (string exp_name,string sym,string  tf)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", exp_name, "Backtest", exp_name, sym, tf);
  return str;
 } 
 
//---- функция считывания списка файлов истории

bool  ReadHistoryList ()
 {
  return (true);  
 }


void OnStart()
  {
   string historyFile;   // адрес файла истории
   string backtestFile;  // адрес файла бэктеста
   bool   flag;          // флаг проверки существования файла истории
   uint   n_experts;     // количество запущенных экспертов 
   uint   index;         // счетчик для прохождения в цикле по массиву
   
   string expert_name;   // имя запущенного эксперта
   string expert_symbol; // символ, по которому запущен эксперт
   string expert_period; // период (таймфрейм) по которому запущен эксперт
   
    //---- вызываем экспертоскоп и получаем массив параметров запущенных экспертов
    expscop.DoExpertoScop();
    //---- получаем количество запущенных экспертов
    n_experts = expscop.GetParamLength();
    
    //---- проходим по всем параметрам запущенных экспертов и получаем параметры
    
    for (index=0;index < n_experts; index++)
     {
      expert_name   = expscop.GetExpertName(index); // получаем имя эксперта
      expert_symbol = expscop.GetSymbol(index);     // получаем символ
      expert_period = PeriodToString(expscop.GetTimeFrame(index));  // получаем таймфрейм
      Alert("ИМЯ ЭКСПЕРТА = ", expert_name);
      Alert("СИМВОЛ = ", expert_symbol);
      Alert("ПЕРИОД = ",expert_period);
      //---- получаем имя файла истории
      historyFile   = GetHistoryFileName  (expert_name,expert_symbol,expert_period);
      //---- получаем имя файла бэктеста
      backtestFile  = GetBackTestFileName (expert_name,expert_symbol,expert_period);
      //---- загружаем файл истории
      flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
      //---- загружаем файл истории
      if (flag == true )
      //---- если файл истории удалось прочитать
       {
       //---- то вычисляем параметры бэктеста и сохраняем их в файл
       backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       }
     }
  }