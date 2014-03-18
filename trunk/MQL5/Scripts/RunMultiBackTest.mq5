//+------------------------------------------------------------------+
//|                                                  RunBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>    //подключаем библиотеку бэктеста
#include <StringUtilities.mqh>        
#include <kernel32.mqh>                 //для WIN API функций
 
//+------------------------------------------------------------------+
//| Скрипт запускает приложение вычисления отчетности                |
//+------------------------------------------------------------------+

// параметры, вводимые пользователем

input string   file_catalog = "C:\\Taki";              // адрес каталога с программой TAKI
input string   url_list     = "C:\\";                  // адрес каталога url адресов
input datetime time_from    = 0;                       // с какого времени
input datetime time_to      = 0;                       // по какое время

//---- глобальные переменные и массивы

// динамический массив наименований отчетностей
string backtest_titles[];
// динамический массив url адресов 
string url_list_array[];

// массив имен экспертов
string robotArray[3] =
 {
  "condom",
  "TIHIRO",
  "HAYASHI",
  "HAYASHI"
 };
// массив символов
string symbolArray[6] =
 {
  "EURUSD",
  "GBPUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };
// массив периодов
ENUM_TIMEFRAMES periodArray[20] =
 {
   PERIOD_M1,
   PERIOD_M2,
   PERIOD_M3,
   PERIOD_M4,
   PERIOD_M5,
   PERIOD_M6,
   PERIOD_M10,
   PERIOD_M12,
   PERIOD_M15,
   PERIOD_M20,
   PERIOD_M30,
   PERIOD_H1,
   PERIOD_H2,
   PERIOD_H3,
   PERIOD_H4,
   PERIOD_H6,
   PERIOD_H8,
   PERIOD_D1,
   PERIOD_W1,
   PERIOD_MN1  
 };

//---- функция возвращает адреса файла истории 
 
string GetFileHistory (int n_robot,int n_symbol,int n_period)
 {
  return robotArray[n_robot]+"/"+"History"+"/"+robotArray[n_robot]+"_"+symbolArray[n_symbol]+"_"+PeriodToString(periodArray[n_period])+".csv";
 } 
 
//---- функция возвращает адрес файла результатов вычислений бэктеста 
 
string GetBackTestFileName (int n_robot, int n_symbol, int n_period)
 {
  string str="";
  str = StringFormat("\dat\%s_%s_%s[%s,%s].dat", robotArray[n_robot], symbolArray[n_symbol], PeriodToString(periodArray[n_period]), TimeToString(time_from),TimeToString(time_to));
  StringReplace(str," ","_");
  StringReplace(str,":",".");  
  str = file_catalog+str;
  return str;
 } 
 
//---- функция возвращает адрес файла списка URL адресов

string GetBacktestUrlList ()
 {
   return url_list+"/"+"_backtest_.dat";
 }
 
//---- функция возвращает адрес приложения TAKI

string GetTAKIUrl ()
 {
   return "cmd /C start "+file_catalog+"/"+"TAKI.exe";
 }


void OnStart()
{
 uchar    val[];
 string   backtest_file;    // файл отчетности
 string   history_url;      // адрес файла истории
 string   url_backtest;     // адрес файла списка url к файлам бэктеста
 string   url_TAKI;         // адрес TAKI приложения
 // прочие переменные
 int      file_handle;      // хэндл файла списка URL файлов бэктестов
 int      i_rob,i_sym,i_per;// переменные-счетчики для прохода по циклам
 int      robots_n;         // количество роботов 
 int      symbols_n;        // количество символов
 int      period_n;         // количество периодов
 bool     flag;             // флаг проверки успешной загрузки истории
 bool     flag_backtest;    // флаг проверки формирования файла отчетности
 int      size_of_url_list; // счетчик url адресов бэктеста
 int      index_url;        // счетчик прохождения по циклам 
 
 // инициализиуем паременные
 robots_n  = ArraySize(robotArray);
 symbols_n  = ArraySize(symbolArray);
 period_n  = ArraySize(periodArray);
 size_of_url_list = 0;
 // формируем основные url адреса файлов
 url_backtest  = GetBacktestUrlList ();       // сохраняем файл списка url файлов бэктеста
 url_TAKI      = GetTAKIUrl ();               // сохраняем файл каталога с программой
 
 BackTest backtest;         // объект класса бэктеста

 // проходим по всем роботам и ищем файлы истории
 for (i_rob=0;i_rob < robots_n; i_rob ++ )
  {
   for (i_sym=0;i_sym < symbols_n; i_sym ++)
    {
     for (i_per=0;i_per < period_n; i_per ++)
      {
       
       // формируем адрес файла истории
       history_url = GetFileHistory (i_rob,i_sym,i_per);
       // получаем историю позиций из файла 
       flag = backtest.LoadHistoryFromFile(history_url,time_from,time_to);
       // если файл истории успешно загружен
       if (flag)
         {
          // формируем файл бэктестов
          backtest_file = GetBackTestFileName (i_rob,i_sym,i_per);
          // сохраняем файл бэктеста
          flag_backtest = backtest.SaveBackTestToFile(backtest_file,symbolArray[i_sym],periodArray[i_per],robotArray[i_rob]);
          // сохраняем url файла бэктеста в массив url адресов
          ArrayResize(backtest_titles,size_of_url_list+1);   // увеличиваем размер массива наименований на единицу
          ArrayResize(url_list_array,size_of_url_list+1);   // увеличиваем размер массива url адресов на единицу
          backtest_titles[size_of_url_list] = robotArray[i_rob]+"-"+symbolArray[i_sym]+"-"+PeriodToString(periodArray[i_per]);           
          url_list_array[size_of_url_list]  = backtest_file; // сохраняем url адреса файла бэктеста
          // увеличиваем счетчик url адресов бэктеста на единицу
          size_of_url_list++;
         }
        else
         {
          Comment("Не удалось считать историю из файла = ",history_url);
         }         
        
        
      }
        
    }
  
  }
  
   // открываем файл списка URL адресов бэктеста
   file_handle   = CreateFileW(url_backtest, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL); 
   Comment("");
   WriteTo(file_handle,file_catalog+"\ ");  
   //---- сохраняем количество url адресов бэктеста
   Comment("");  
   WriteTo(file_handle,size_of_url_list+" ");     
   for (index_url=0;index_url<size_of_url_list;index_url++)
    {
       //---- сохраняем имя эксперта, символ и периол в виде строки 
       Comment("");
       WriteTo(file_handle, backtest_titles[index_url]+" ");                
       //---- сохраняем URL в файл списка URL бэктеста
       Comment("");
       WriteTo(file_handle, url_list_array[index_url] +" ");
    }
   //закрываем файл списка url
   CloseHandle(file_handle);

   if (size_of_url_list > 0)
    {
     // запускаем приложение отображения результатов бэктеста
     StringToCharArray ( url_TAKI,val);
     WinExec(val, 1);
    }  
}