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

//+------------------------------------------------------------------+
//| Скрипт вычисления результатов бэктеста                           |
//+------------------------------------------------------------------+

//---- входные параметры скрипта

//---- перечисление экспертов

enum EXPERT_NAME
 {
  FollowWhiteRabbit=0, //кролик
  Condom,              //гандон
  Dinya,               //динья
  Sanya,               //саня
  TIHIRO,              //тихиро
 };
 
input EXPERT_NAME expert_name=0;                 //имя эксперта 
input string symbol="EURUSD";                    //символ
input ENUM_TIMEFRAMES InpLoadedPeriod=PERIOD_H1; //период
input datetime time_from=0;                      //время с которого вычислять параметры бэктеста
input datetime time_to=0;                        //время, по какое вычисляеть параметры бэктеста

BackTest backtest;   //объект класса бэктеста

string GetExpertName()
 {
  switch (expert_name)
   {
    case FollowWhiteRabbit:
     return "FollowWhiteRabbit";
    break;
    case Condom:
     return "Condom";
    break;
    case Dinya:
     return "Dinya";
    break;
    case Sanya:
     return "Sanya";
    break;
    case TIHIRO:
     return "TIHIRO";
    break;
   }
  return "";
 }

//---- функция возвращает адрес файла истории

string GetHistoryFileName ()
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "History", GetExpertName(), StringSubstr(symbol,0,6), PeriodToString(InpLoadedPeriod));
  return str;
 }
 
//---- функция возвращает адрес файла результатов вычислений бэктеста 
 
string GetBackTestFileName ()
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "Backtest", GetExpertName(), StringSubstr(symbol,0,6), PeriodToString(InpLoadedPeriod));
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
   //---- получаем имя файла истории
   historyFile  = GetHistoryFileName ();
   //---- получаем имя файла бэктеста
   backtestFile = GetBackTestFileName ();
   //---- загружаем файл истории
   flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
   //---- загружаем файл истории
   if (flag == true )
   //---- если файл истории удалось прочитать
    {
     //---- то вычисляем параметры бэктеста и сохраняем их в файл
     backtest.SaveBackTestToFile(backtestFile,symbol);
    }
  }