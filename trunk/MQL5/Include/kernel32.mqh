//+------------------------------------------------------------------+
//|                                                     kernel32.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//+------------------------------------------------------------------+
//| библиотека Kernel32 функций                                      | 
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
        
  bool ReadFile                   // Чтение данных из файла
       ( int    hFile,                 // handle of file to read
         char    &lpBuffer[],              // address of buffer that receives data 
         int    nNumberOfBytesToRead,  // number of bytes to read
         int&   lpNumberOfBytesRead[], // address of number of bytes read
         int    lpOverlapped );        // address of structure for data              
  
  int  RtlGetLastWin32Error();
  int  WinExec(uchar &NameEx[], int dwFlags);  // запускает приложение BackTest
    
#import

// Тип доступа к объекту
#define _GENERIC_READ_       0x80000000
#define _GENERIC_WRITE_      0x40000000
// Флаги общего доступа
#define _FILE_SHARE_READ_    0x00000001
#define _FILE_SHARE_WRITE_   0x00000002
// Описатель действия
#define _OPEN_EXISTING_      3
#define _CREATE_ALWAYS_      2