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
input string   url_list  = "C:\\";                     // адрес каталога url адресов
input datetime time_from    = 0;                       // с какого времени
input datetime time_to      = 0;                       // по какое время


//---- функция возвращает адреса файла истории 
 
string GetFileHistory (int n_robot, int n_symbol, int n_period)
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
 int win32_DATA[79];
 string   backtest_file;    // файл отчетности
 string   history_url;      // адрес файла истории
 string   url_backtest;     // адрес файла списка url к файлам бэктеста
 string   url_TAKI;         // адрес TAKI приложения
 // прочие переменные
 int      file_handle;      // хэндл файла списка URL файлов бэктестов
 bool     flag;             // флаг проверки успешной загрузки истории
 bool     flag_backtest;    // флаг проверки формирования файла отчетности
 
 // инициализиуем паременные
 robots_n  = ArraySize(robotArray);
 symbols_n = ArraySize(symbolArray);
 period_n  = ArraySize(periodArray);
 
 //Alert("N_ROBOTS = ",robots_n,);
   
 // формируем основные url адреса файлов
 url_backtest  = GetBacktestUrlList ();       // сохраняем файл списка url файлов бэктеста
 url_TAKI      = GetTAKIUrl ();               // сохраняем файл каталога с программой
 
 
 BackTest backtest;         // объект класса бэктеста
 // открываем файл списка URL адресов бэктеста
 file_handle   = CreateFileW(url_backtest, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL); 
 Comment("");
 WriteTo(file_handle,file_catalog+"\ ");  
 
 
 //ищем первый файл истории в заданном каталоге
 ArrayInitialize(win32_DATA,0); 
 handle = FindFirstFileW(filename+"*.chr", win32_DATA);
 //если файл успешно найден
 if(handle!=-1)
 {
  
 }
 
 // проходим по циклам и формирует файл истории
 for (i_rob=0;i_rob < robots_n; i_rob ++ )
  {
     Alert("РОБОТ = ",i_rob);
   for (i_sym=0;i_sym < symbols_n; i_sym ++)
    {
     for (i_per=0;i_per < period_n; i_per ++)
      {
       
       // формируем адрес файла истории
       history_url = GetFileHistory (i_rob,i_sym,i_per);
      // Alert("ФАЙЛ ИСТОРИИ = ",history_url);
       // получаем историю позиций из файла 
       flag = backtest.LoadHistoryFromFile(history_url,time_from,time_to);
            // Alert("ЦИКЛ ЗАВЕРШЕН [",i_sym,",",i_per,"]");
       // если файл истории успешно загружен
       if (flag)
         {
         Alert("ЦИКЛИТСЯ [",i_sym,",",i_per,"]");
          // формируем файл бэктестов
          backtest_file = GetBackTestFileName (i_rob,i_sym,i_per);
        //  Alert("BACKTEST = ",backtest_file);
          // сохраняем файл бэктеста
          flag_backtest = backtest.SaveBackTestToFile(backtest_file,symbolArray[i_sym],periodArray[i_per],robotArray[i_rob]);
          Alert("ЦИКЛ ЗАВЕРШЕН [",i_sym,",",i_per,"]");
          // очищаем файл истории
         
          backtest.DeleteHistory();
          if (flag_backtest)
           {
            // сохраняем URL в файл списка URL бэктеста
            Comment("");
            WriteTo(file_handle,backtest_file+" ");
           }
         }
        else
         {
          Comment("Не удалось считать историю из файла");
         }         
        
        
      }
        
    }
  
  }
  
  Alert("ВЫШЛИ ИЗ ЦИКЛОВ");

 //закрываем файл списка url
 CloseHandle(file_handle);

  if (flag_backtest)
   {
    // запускаем приложение отображения результатов бэктеста
    StringToCharArray ( url_TAKI,val);
    WinExec(val, 1);
   }  

}