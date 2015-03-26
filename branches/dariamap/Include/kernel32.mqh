//+------------------------------------------------------------------+
//|                                                     kernel32.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//+------------------------------------------------------------------+
//| утилита для работы с функциями библиотеки Kernel32 (WIN API)     | 
//+------------------------------------------------------------------+

#import "kernel32.dll"

  int  FindFirstFileW(string path, int& answer[]);   // для поиска первого файла в заданной директории
   
  bool FindNextFileW(int handle, int& answer[]);     // для поиска файла в заданной директории
   
  bool FindClose(int handle);                        // завершение поиска файлов в директории

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
#define _GENERIC_READ_         0x80000000
#define _GENERIC_WRITE_        0x40000000
// Флаги общего доступа
#define _FILE_SHARE_READ_      0x00000001
#define _FILE_SHARE_WRITE_     0x00000002
// Описатель действия
#define _OPEN_EXISTING_        3
#define _CREATE_ALWAYS_        2

// константы
#define OPEN_GENETIC           0x80000000
#define OPEN_EXISTING          3
#define FILE_ATTRIBUTE_NORMAL  128
#define FILE_SHARE_READ_KERNEL 0x00000001

// дополнительные функции

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

// считывает строку
string   ReadString(int handle)
 {
  int    nBytesRead[1]={1};
  char   buffer[2]={'_','-'};
  string str=""; 
  string ch="";
  if (handle>0) {
    // пропускаем пустой символ 
     ReadFile(handle, buffer, 2, nBytesRead, NULL);
    // считываем символы, пока не дойдем до конца строки
    while (nBytesRead[0]>0 && buffer[0]!=13) {
      // формируем строку
      str = str + ch;
      Comment(" ");
      // считываем очередной символ
      ReadFile(handle, buffer, 2, nBytesRead, NULL);
      // сохраняем символ
      ch =  CharToString(buffer[0]);
    }
  }
  return (str);
 }
 
// считать текст из буфера                                         
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
   }  