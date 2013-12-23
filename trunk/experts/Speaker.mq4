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

  CheckForUpdate(full_path);
}

//+----------------------------------------------------------------------------+
//|  Копирование файла без его блокировки на момент чтения                     |
//|  Параметры:                                                                |
//|    nf1 - имя файла источника                                               |
//|    nf2 - имя файла получателя                                              |
//+----------------------------------------------------------------------------+
void WriteTo(int handle, string buffer) 
{
  int    nBytesRead[1]={1};

  if(handle>0) 
  {
    //Print("успех"); 
    WriteFile(handle, buffer, StringLen(buffer), nBytesRead, NULL);
  } 
  else
   Print("неудача. плохой хэндл для файла Говоруна");
}




//+------------------------------------------------------------------+

void CheckForUpdate(string nf2)
{
 //static int total = 0;
 //if(total != OrdersTotal())
 //{
  int total = OrdersTotal();
  int handle = CreateFileA(nf2, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);
  for(int i = 0; i < total; i ++)
  {
   WriteTo(handle, OrderToString(i));
  }
  CloseHandle(handle);
 //}
}

string OrderToString(int pos)
{
 string result = "";
 if(OrderSelect(pos, SELECT_BY_POS, MODE_TRADES))
 {
  //Print("ok");
  result = result + OrderSymbol() + "@";
  if(OrderType() == OP_BUY)result = result + "OP_BUY@";
  else if(OrderType() == OP_SELL)result = result + "OP_SELL@";
  else if(OrderType() == OP_BUYLIMIT)result = result + "OP_BUYLIMIT@";
  else if(OrderType() == OP_BUYSTOP)result = result + "OP_BUYSTOP@";
  else if(OrderType() == OP_SELLSTOP)result = result + "OP_SELLSTOP@";
  else if(OrderType() == OP_SELLLIMIT)result = result + "OP_SELLLIMIT@";
  result = result + OrderLots() + "@";
  result = result + OrderOpenPrice() + "\r\n";
  //Alert(result);  
 }
 else
 {
  //Print("bad");
  result = "error";
 }
 return(result);
}