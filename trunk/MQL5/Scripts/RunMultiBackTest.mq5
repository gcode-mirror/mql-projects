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
input string   catalog_url  = "";                      // адрес каталога с файлами истории
input datetime time_from    = 0;                       // с какого времени
input datetime time_to      = 0;                       // по какое время
 
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
   return file_catalog+"/"+"_backtest_.dat";
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
}  


// метод получения всех файлов истории в каталоге 
void GetAllCatalog()
{
 int win32_DATA[79];
 int handle;
 int url_handle;     // хэндл файла, содержащего url адреса результатов бэктеста
 string file_url;    // url адрес файла
 //открываем файл  
 ArrayInitialize(win32_DATA,0); 
 //---- ищем первый файл 
 handle = FindFirstFileW(catalog_url+"*.csv", win32_DATA);
 //---- открываем файл списка URL адресов бэкстеста  
 url_handle  = CreateFileW(GetBacktestUrlList(), _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
 
 if(handle!=-1)
 {
  file_url = bufferToString(win32_DATA);
  //---- если файл считан
  if (CreateBackTestFile(file_url) )  // загружаем историю из файла 
   {
    Comment("");
    WriteTo(file_handle,backtest_file+" ");
   }
  ArrayInitialize(win32_DATA,0);
 // открываем остальные файлы
 while(FindNextFileW(handle, win32_DATA))
 {
  file_url = bufferToString(win32_DATA); 
  CreateBackTestFile(file_url);
  ArrayInitialize(win32_DATA,0);
 }
 if (handle > 0) FindClose(handle);
 }
 // закрываем файл списка url файлов
 CloseHandle(url_handle);
}

// метод обработки файла истории

bool CreateBackTestFile (string fileHandle)
{
 bool flag;
 //---- получаем историю позиций из файла 
 flag = backtest.LoadHistoryFromFile(fileHandle,time_from,time_to);
//---- если история благополучно получена
 if (flag)
 {
  //---- открываем файл списка URL адресов бэкстеста
  file_handle = CreateFileW(url_list, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
  //---- сохраняем файл бэктеста
  backtest.SaveBackTestToFile(backtest_file,_Symbol,_Period,expert_name);
  //---- сохраняем URL в файл списка URL бэктеста
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

//+------------------------------------------------------------------+
//|  Переводит int массив в строку                                   |
//+------------------------------------------------------------------+ 
string bufferToString(int &fileContain[])
   {
   string text="";
   
   int pos = 10;
   for (int i = 0; i < 64; i++)
      {
      pos++;
      int curr = fileContain[pos];
      text = text + CharToString(curr & 0x000000FF)
         +CharToString(curr >> 8 & 0x000000FF)
         +CharToString(curr >> 16 & 0x000000FF)
         +CharToString(curr >> 24 & 0x000000FF);
      }
   return (text);
