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
  
  int  RtlSetLastWin32Error (int dwErrCode);   
  
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

input string   file_catalog = "C:\\_backtest_.dat"; // файл списка url бэктестов
input string   file_url  = "C:\\";                  // расположение файла истории 
input datetime time_from = 0;                       // с какого времени
input datetime time_to   = 0;                       // по какое время

void OnStart()
  {
uchar    val[];
string   backtest_file="C:\\BACKTEST.txt";
bool     flag;             
int      file_handle;      // хэндл файла списка URL файлов бэктестов
BackTest backtest;         // объект класса бэктеста
//---- получаем историю позиций из файла 
flag = backtest.LoadHistoryFromFile(file_url,time_from,time_to);
//---- если история благополучно получена
if (flag)
 {
//---- открываем файл списка URL адресов бэкстеста
file_handle = CreateFileW(file_catalog, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
//---- сохраняем файл бэктеста
backtest.SaveBackTestToFile(backtest_file,_Symbol);
//---- сохраняем URL в файл списка URL бэктеста
Comment("");
WriteTo(file_handle,backtest_file+" ");
//---- закрываем файл списка URL
CloseHandle(file_handle);
//---- запускаем приложение отображения результатов бэктеста
StringToCharArray ("cmd /C start C:\\GetBackTest.exe",val);
WinExec(val, 1);
 }
else
 {
  Comment("Не удалось вычислить отчетность");
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