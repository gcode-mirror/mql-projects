//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
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
 };
 
input EXPERT_NAME expert_name=0;                 //имя эксперта 
input string symbol="EURUSD";                    //символ
input ENUM_TIMEFRAMES InpLoadedPeriod=PERIOD_H1; //период
input datetime time_from=0;                      //время с которого вычислять параметры бэктеста
input datetime time_to=0;                        //время, по какое вычисляеть параметры бэктеста

string historyList[]; //массив для хренения имен файлов истории 

BackTest backtest;   //объект класса бэктеста

Panel * panel;

//---- функция возвращает адрес файла истории

string GetHistoryFileName ()
 {
  string str;
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", MQL5InfoString(MQL5_PROGRAM_NAME), name, EXPERT_NAME, StringSubstr(Symbol(),0,6), PeriodToString(InpLoadedPeriod));
  return str;
 }
 
//---- функция считывания списка файлов истории

bool  ReadHistoryList ()
 {
   
 }


void OnStart()
  {
   //---- переменная индекс
   uint index;
   //---- если удалось прочитать файла со списком файлов истории 
   if (ReadHistoryList () )
    {
     //---- проходим по всему списку имен файлов
     for(index=0;index<ArraySize(historyList);index++)
      {
       //---- загружаем файл истории в бэктест
       if (backtest.LoadHistoryFromFile(historyList[index]) )
        {
         //---- если загрузка прошла успешно
         //---- то вычисляем парамеры бэктеста
         //---- и сохраняем файл результатов
         backtest.SaveBackTestToFile();
        }
       else
        return;
      }
    }
    
  }