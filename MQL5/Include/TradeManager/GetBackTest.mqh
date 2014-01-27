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

//+------------------------------------------------------------------+
//| Функции вычисления результатов бэктеста для запущенных экспертов |
//+------------------------------------------------------------------+


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
  str = StringFormat("C:\%s_%s_%s.txt", exp_name, sym, tf);
  return str;
 } 
 
//---- функция считывания списка файлов истории

bool  ReadHistoryList ()
 {
  return (true);  
 }
 

//---- функция вычисляет параметры бэктестра

void CalculateBackTest (datetime time_from,datetime time_to)
  {
   string historyFile;   // адрес файла истории
   string backtestFile;  // адрес файла бэктеста
   bool   flag;          // флаг проверки существования файла истории
   uint   n_experts;     // количество запущенных экспертов 
   uint   index;         // счетчик для прохождения в цикле по массиву
   
   string expert_name;   // имя запущенного эксперта
   string expert_symbol; // символ, по которому запущен эксперт
   string expert_period; // период (таймфрейм) по которому запущен эксперт
   
   int file_handle;      // хэндл файл списка URL адресов бэктеста
   
    //---- вызываем экспертоскоп и получаем массив параметров запущенных экспертов
    expscop.DoExpertoScop();
    //---- получаем количество запущенных экспертов
    n_experts = expscop.GetParamLength();
    
    //---- если есть запущенные эксперты
    
    if (n_experts > 0)
    {
    //---- открываем файл списка URL адресов бэкстеста
    file_handle = CreateFileW("C:\\_backtest_.dat", _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
    //---- проходим по всем параметрам запущенных экспертов и получаем параметры
    
    for (index=0;index < n_experts; index++)
     {
      expert_name   = expscop.GetExpertName(index);                 // получаем имя эксперта
      expert_symbol = expscop.GetSymbol(index);                     // получаем символ
      expert_period = PeriodToString(expscop.GetTimeFrame(index));  // получаем таймфрейм
      Print("_____________________________");
      Print("ИМЯ ЭКСПЕРТА = ", expert_name);
      Print("СИМВОЛ = ", expert_symbol);
      Print("ПЕРИОД = ",expert_period);
      Print("_____________________________");      
      //---- получаем имя файла истории
      historyFile   = GetHistoryFileName  (expert_name,expert_symbol,expert_period);
      //---- получаем имя файла бэктеста
      backtestFile  = GetBackTestFileName (expert_name,expert_symbol,expert_period);
      Alert("ТАКИЕ ПИРОГИ = ", backtestFile);
      //---- загружаем файл истории
      flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
      //---- загружаем файл истории
      if (flag)
      //---- если файл истории удалось прочитать
       {
       //---- то вычисляем параметры бэктеста и сохраняем их в файл
       //backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       //---- сохраняем URL в файл списка URL бэктеста
       Comment("");
       WriteTo(file_handle,backtestFile+" ");
       }
     }
     //---- закрываем файл списка URL файлов
     CloseHandle(file_handle);
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