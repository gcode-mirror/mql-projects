//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh> //подключаем библиотеку бэктеста
#include <StringUtilities.mqh>       //подключаем библиотеку констант
#include <Charts\Chart.mqh>


//+------------------------------------------------------------------+
//| Скрипт вычисления результатов бэктеста                           |
//+------------------------------------------------------------------+

//---- массив имен экспертов

string expert_array[5] =
{
"FollowWhiteRabbit",
"condom",
"Dinya",
"Sanya",
"TIHIRO"
}; 
 
//---- массив символов

string symbol_array[6] = 
{
"EURUSD",
"GBPUSD",
"USDCHF",
"USDJPY",
"USDCAD",
"AUDUSD"
};
 
input datetime time_from=0;                      //время с которого вычислять параметры бэктеста
input datetime time_to=0;                        //время, по какое вычисляеть параметры бэктеста

string historyList[]; //массив для хренения имен файлов истории 

BackTest backtest;   //объект класса бэктеста

CChart obj = new CChart();

//---- функция возвращает имя эксперта

string GetExpertName(uint num)
 {
  return expert_array[num];
 }
 
//---- функция возвращает символ

string GetSymbolName(uint num)
 {
  return symbol_array[num];
 }

//---- функция возвращает адрес файла истории

string GetHistoryFileName (uint exp_num,uint sym_num,ENUM_TIMEFRAMES  tf_num)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(exp_num), "History", GetExpertName(exp_num), GetSymbolName(sym_num), PeriodToString(tf_num));
  return str;
 }
 
//---- функция возвращает адрес файла результатов вычислений бэктеста 
 
string GetBackTestFileName (uint exp_num,uint sym_num,ENUM_TIMEFRAMES tf_num)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(exp_num), "Backtest", GetExpertName(exp_num), GetSymbolName(sym_num), PeriodToString(tf_num));
  return str;
 } 
 
//---- функция считывания списка файлов истории

bool  ReadHistoryList ()
 {
  return (true);  
 }


void OnStart()
  {
   string historyFile;
   string backtestFile;
   bool flag;
   uint expert_num;     //переменная для перебора имен экспертов
   uint symbol_num;     //переменная для перебора символов
   ENUM_TIMEFRAMES timeframe_num;  //переменная для перебора таймфреймов
   //---- проходим по циклам и перебираем параметры выходных файлов
   
   Alert("ИМЯ ПРОГРАММЫ = ",MQL5InfoString(MQL5_PROGRAM_NAME));   
   
   obj.GetString(
   
   //---- проходим по именам экспертов
    for (expert_num=0; expert_num < 5; expert_num++)
     {
      //---- проходим по символам
      for (symbol_num=0; symbol_num < 6; symbol_num++)
       {
        //---- проходим по тайм фреймам
        for (timeframe_num=0; timeframe_num < 20; timeframe_num++)
         {
 
          //---- получаем имя файла истории
          historyFile  = GetHistoryFileName (expert_num,symbol_num,timeframe_num);
          //---- получаем имя файла бэктеста
          backtestFile = GetBackTestFileName (expert_num,symbol_num,timeframe_num);
          //---- загружаем файл истории
          flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
          //---- загружаем файл истории
          if (flag == true )
          //---- если файл истории удалось прочитать
           {
            //---- то вычисляем параметры бэктеста и сохраняем их в файл
            backtest.SaveBackTestToFile(backtestFile,GetSymbolName(symbol_num));
         //   backtest.SaveArray("new_history.csv");
           }
          
         }    
       } 
     }
  }