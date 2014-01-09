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
  int CreateFileW                 // Создание открытие объекта
      ( string lpFileName,               // Полный путь доступа к объекту
        int    dwDesiredAccess,          // Тип доступа к объекту
        int    dwShareMode,              // Флаги общего доступа
        int    lpSecurityAttributes,     // Описатель безопасности
        int    dwCreationDisposition,    // Описатель действия
        int    dwFlagsAndAttributes,     // Флаги аттрибутов
        int    hTemplateFile );          //
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
  int  RtlGetLastWin32Error ();
  int  RtlSetLastWin32Error (int dwErrCode);  
#import
//---------------------------------------------------------------------------------------------
// CONST
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

extern string   path         = "C:\\speaker\\A";            // путь к файлам, хранящего информацию о последних ордерах 
extern string   file_instant = "ORDERS_INSTANT";  // часть  имени файла, хранящего историю ордеров
extern string   file_pending = "ORDERS_PENDING"; // часть  имени файла, хранящего текущие ордера

string   full_path_instant;                       // полный путь к файлу истории ордеров
string   full_path_pending;                      // полный путь к файлу текущим ордеров

// переменные для проверки обновления ордеров 
int      total_orders = 0;              // всего ордеров в истории
bool check = true;

// параметры для всех типов сделок
int      order_type     = 0;     //тип ордера
int      order_status   = 0;     //статус ордера
double   order_volume   = 0;     //объем ордера
double   take_profit    = 0;     //тейк профит
double   stop_loss      = 0;     //стоп лосс
string   comment        = "";    //комментарий к ордеру
int      ticket         = 0;     //тикет 
// параметры для отложенников
double   order_price    = -1;    //цена ордера 
//---------------------------------------------------------------------------------------------
void start() 
{
  // формируем адреса выходных файлов
  full_path_instant = StringConcatenate(path, file_instant, "_", Symbol(), ".txt");
  full_path_pending = path + file_pending + "_" + Symbol() + ".txt"; 
/*  if(total_orders != OrdersTotal())
  {
   Print(total_orders, " = ", OrdersTotal());
   SaveOrdersFromTerminal();
   total_orders = OrdersTotal();
  }*/
  if(check)
  {
   check = false;
   int file_handle = CreateFileW(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL); 
   Print("Открыт файл. handle = ", file_handle, " name = ", full_path_instant);   
   SaveOrderToFile(file_handle);
   
   CloseHandle(file_handle);
  }
}
//---------------------------------------------------------------------------------------------
//+----------------------------------------------------------------------------+
//|  Копирование файла без его блокировки на момент чтения                     |
//|  Параметры:                                                                |
//|    nf1 - имя файла источника                                               |
//|    nf2 - имя файла получателя                                              |
//+----------------------------------------------------------------------------+
void WriteTo(int handle, string buffer) 
{
  int nBytesRead[1]={1};
  if(handle>0) 
  {
    //Print("успех"); 
    WriteFile(handle, buffer, StringLen(buffer), nBytesRead, NULL);
  } 
  else
   Print("неудача. плохой хэндл для файла Говоруна");
}

//+------------------------------------------------------------------+

void SaveOrdersFromTerminal  () 
{
 bool   openFileFlag = true;  // Флаг открытия файла 
 int    file_handle  = -1;    // хэндл файла  
 int    total        = 0;     // размер буфера ордеров
 total = OrdersTotal();       // получаем размер буфера ордеров
  //--- Пройдем по всем ордерам в полученном списке от последнего ордера в списке к последнему ордеру предыдущей итерации
 for(int i = total-1; i >= 0; i--)
  {
   // извлекаем тикет 
   if (OrderSelect(i, SELECT_BY_POS))
   {
     // если символ ордера равен текущему символу
     if (OrderSymbol() == Symbol())
     {
        Print("Совпал символ");
        order_type   =  OrderType();           // извлекаем тип ордера
        //order_status =  OrderGetInteger(ORDER_STATE);          // извлекаем статус ордера
        order_volume =  OrderLots();           // извлекаем объем ордера (лот) 
        take_profit  =  OrderTakeProfit();     // тейк профит ордера
        stop_loss    =  OrderStopLoss();       // стоп лосс ордера  
        comment      =  OrderComment();        // комментарий к ордеру
        order_price  =  OrderOpenPrice();      // цена, указанная в ордере
        
        // если нашли первый ордер с текущим символом
        if (openFileFlag)               
        {
         // открываем файл на запись
         file_handle = CreateFileW(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);  
         // меняем флаг 
         openFileFlag = false;
        }
        // записываем ордер в файл  
        SaveOrderToFile(file_handle);
     }
     Print("Выбран ордер ", i); 
   }
 }
 if (!openFileFlag) CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //сохраняет информациб об ордере в файл 
{
 if(handle < 0 )
 {
  Print("Не удалось записать ордер в файл");
  return(false);
 }
 WriteTo(handle, DoubleToStr(      ticket, 0)+"&");       // сохраняем тикет ордера
 WriteTo(handle, DoubleToStr(  order_type, 0)+"&");       // сохраняем тип ордера
 WriteTo(handle, DoubleToStr(order_status, 0)+"&");       // статус ордера
 WriteTo(handle, DoubleToStr(order_volume, Digits)+"&");  // сохраняем объем ордера
 WriteTo(handle, DoubleToStr( take_profit, Digits)+"&");  // сохраняем take profit
 WriteTo(handle, DoubleToStr(   stop_loss, Digits)+"&");  // сохраняем stop loss
 WriteTo(handle, comment+"&");                            // комментарий к ордеру  
 WriteTo(handle, DoubleToStr( order_price, Digits)+"&");  // получаем цену ордера
 // если использованы отложенники, то цена существует
 
 return(true);
}