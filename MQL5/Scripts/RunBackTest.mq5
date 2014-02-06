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
//+------------------------------------------------------------------+
//| Скрипт запускает приложение вычисления отчетности                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Импорт WIN API библиотеки                                        |
//+------------------------------------------------------------------+

#import "kernel32.dll"

  bool CloseHandle                // Закрытие объекта
       ( int hObject );                  // Хэндл объекта
       
  int CreateFileW                 // Создание открытие объекта
      ( string lpFileName,               // Полный путь доступа к объекту
        int    dwDesiredAccess,          // Тип доступа к объекту
        int    dwShareMode,              // Флаги общего доступа
        int    lpSecurityAttributes,     // Описатель безопасности
        int    dwCreationDisposition,    // Описатель действия
        int    dwFlagsAndAttributes,     // Флаги аттрибутов
        int    hTemplateFile );      
          
  bool WriteFile                  // Запись данных в файл
       ( int    hFile,                   // handle to file to write to
         char    &dBuffer[],             // pointer to data to write to file
         int    nNumberOfBytesToWrite,   // number of bytes to write
         int&   lpNumberOfBytesWritten[],// pointer to number of bytes written
         int    lpOverlapped );          // pointer to structure needed for overlapped I/O    
  
  int  RtlGetLastWin32Error();
  int  WinExec(uchar &NameEx[], int dwFlags);  // запускает приложение BackTest
    
#import

//+------------------------------------------------------------------+
//| Необходимые константы                                            |
//+------------------------------------------------------------------+

// Тип доступа к объекту
#define _GENERIC_WRITE_      0x40000000
// Флаги общего доступа
#define _FILE_SHARE_WRITE_   0x00000002
// Описатель действия
#define _CREATE_ALWAYS_      2

// параметры, вводимые пользователем

input string   file_catalog = "C:\\Taki";           // адрес каталога с программой TAKI
input string   expert_name  = "";                   // имя эксперта 
input datetime time_from = 0;                       // с какого времени
input datetime time_to   = 0;                       // по какое время

//---- функция возвращает адрес файла истории

string GetHistoryFileName ()
 {
  string str="";
   str = expert_name + "\\" + "History"+"\\"+expert_name+"_"+_Symbol+"_"+PeriodToString(_Period)+".csv";
  return str;
 }
 
//---- функция возвращает адрес файла результатов вычислений бэктеста 
 
string GetBackTestFileName ()
 {
  string str="";
  str = StringFormat("\dat\%s_%s_%s[%s,%s].dat", expert_name, _Symbol, PeriodToString(_Period), TimeToString(time_from),TimeToString(time_to));
  StringReplace(str," ","_");
  StringReplace(str,":",".");  
  str = file_catalog+str;
  return str;
 } 
 
//---- функция возвращает адрес файла списка URL адресов

string GetBacktestUrlList ()
 {
   return "C:\\"+"_backtest_.dat";
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
 string   url_list;         // адрес файла списка url к файлам бэктеста
 string   url_TAKI;         // адрес TAKI приложения
 bool     flag;             
 int      file_handle;      // хэндл файла списка URL файлов бэктестов
 BackTest backtest;         // объект класса бэктеста
 //---- формируем файл истории
 history_url = GetHistoryFileName ();
 //---- формируем файл отчетности 
 backtest_file = GetBackTestFileName ();
 //---- формируем файл списка url адресов  файлам бэктеста
 url_list = GetBacktestUrlList ();
 //---- формируем адреса приложения TAKI
 url_TAKI = GetTAKIUrl();
 //---- получаем историю позиций из файла 
 flag = backtest.LoadHistoryFromFile(history_url,time_from,time_to);
 //---- если история благополучно получена
 if (flag)
 {
  //---- открываем файл списка URL адресов бэкстеста
  file_handle = CreateFileW(url_list, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
  //---- сохраняем файл бэктеста
  backtest.SaveBackTestToFile(backtest_file,_Symbol,_Period,expert_name);
  //---- сохраняем URL в файл списка URL бэктеста
  Comment("");
  WriteTo(file_handle,file_catalog+"\ ");  
  //---- сохраняем имя эксперта, символ и периол в виде строки 
 // Comment("");
 // WriteTo(file_handle,expert_name+"-"+_Symbol+"-"+PeriodToString(_Period)+" ");     
  Comment("");
  WriteTo(file_handle,backtest_file+" ");
  //---- закрываем файл списка URL
  CloseHandle(file_handle);
  //---- запускаем приложение отображения результатов бэктеста
  StringToCharArray ( url_TAKI,val);
  WinExec(val, 1);
 }
 else
 {
  Comment("Не удалось считать историю из файла");
 }
}
  /*
  // сохраняет строку в файл
void WriteTo(int handle, string buffer) 
{
  int    nBytesRead[1]={1};
  char   buff[]; 
  StringToCharArray(buffer,buff);
  if(handle>0) 
  {
    Comment(" ");
    WriteFile(handle, buff, StringLen(buffer), nBytesRead, NULL);
    
  } 
  else
   Print("неудача. плохой хэндл для файла ");
}  */