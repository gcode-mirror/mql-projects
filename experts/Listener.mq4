//+------------------------------------------------------------------+
//|                                                      Speaker.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#import "kernel32.dll"
  bool CloseHandle                // Закрытие объекта
       ( int hObject );                // Хэндл объекта
  int CreateFileA                 // Создание открытие объекта
      ( string lpFileName,             // Полный путь доступа к объекту
        int    dwDesiredAccess,        // Тип доступа к объекту
        int    dwShareMode,            // Флаги общего доступа
        int    lpSecurityAttributes,   // Описатель безопасности
        int    dwCreationDisposition,  // Описатель действия
        int    dwFlagsAndAttributes,   // Флаги аттрибутов
        int    hTemplateFile );        //
  bool ReadFile                   // Чтение данных из файла
       ( int    hFile,                 // handle of file to read
         string lpBuffer,              // address of buffer that receives data 
         int    nNumberOfBytesToRead,  // number of bytes to read
         int&   lpNumberOfBytesRead[], // address of number of bytes read
         int    lpOverlapped );        // address of structure for data
  bool WriteFile                  // Запись данных в файл
       ( int    hFile,                      // handle to file to write to
         string lpBuffer,                   // pointer to data to write to file
         int    nNumberOfBytesToWrite,      // number of bytes to write
         int&   lpNumberOfBytesWritten[],   // pointer to number of bytes written
         int    lpOverlapped );             // pointer to structure needed for overlapped I/O
#import

// Тип доступа к объекту
#define GENERIC_READ    0x80000000
#define GENERIC_WRITE   0x40000000
#define GENERIC_EXECUTE 0x20000000
#define GENERIC_ALL     0x10000000
// Флаги общего доступа
#define FILE_SHARE_READ   0x00000001
#define FILE_SHARE_WRITE  0x00000002
#define FILE_SHARE_DELETE 0x00000004
// Описатель действия
#define CREATE_NEW        1
#define CREATE_ALWAYS     2
#define OPEN_EXISTING     3
#define OPEN_ALWAYS       4
#define TRUNCATE_EXISTING 5

extern string path = "C:\\Users\\Desepticon2\\Desktop\\ГОВОРУН\\";
extern string filename = "loh.txt";

void start() 
{
  string full_path = path+filename;
  
  ReadFrom(full_path);
}

//+----------------------------------------------------------------------------+
//|  Копирование файла без его блокировки на момент чтения                     |
//|  Параметры:                                                                |
//|    nf1 - имя файла источника                                               |
//|    nf2 - имя файла получателя                                              |
//+----------------------------------------------------------------------------+
bool ReadFrom(string nf1) 
{
  bool   ret=True;
  int    h1, nBytesRead[1]={1};
  string Buffer="1";
  string result_buf = "";

  h1=CreateFileA(nf1, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 128, NULL);
  if (h1>0) 
  {
    Print("успех"); 
    while (nBytesRead[0]>0) 
    {
       ReadFile(h1, Buffer, 1, nBytesRead, NULL);
       if(nBytesRead[0]>0)result_buf = StringConcatenate(result_buf, Buffer);
       //Print("buffer = ", nBytesRead[0]);
    }
  } 
  else
  { 
   ret=False;
   result_buf = "неудача";
  }
  
  Alert(result_buf);
  CloseHandle(h1);
  return(ret);
}