//+------------------------------------------------------------------+
//|                                                      Speaker.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

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
//| Параметры Спикера                                                |
//+------------------------------------------------------------------+

// параметры эксперта
input string   path          = "D:\\";            // путь к файлам, хранящего информацию о последних ордерах 
input string   file_history  = "ORDERS_HISTORY";  // часть  имени файла, хранящего историю ордеров
input string   file_terminal = "ORDERS_TERMINAL"; // часть  имени файла, хранящего текущие ордера

string   full_path_history;                       // полный путь к файлу истории ордеров
string   full_path_terminal;                      // полный путь к файлу текущим ордеров

// переменные для проверки обновления ордеров 
int      total_orders_history   = 0;              // всего ордеров в истории

// параметры для всех типов сделок
long     order_type     = 0;     //тип ордера
long     order_status   = 0;     //статус ордера
double   order_volume   = 0;     //объем ордера
double   take_profit    = 0;     //тейк профит
double   stop_loss      = 0;     //стоп лосс
string   comment        = "";    //комментарий к ордеру
ulong    ticket         = 0;     //тикет 
// параметры для отложенников
double   order_price    = -1;    //цена ордера 


//+------------------------------------------------------------------+
//| Функции спикера                                                  |
//+------------------------------------------------------------------+

// Проходит по всем последним изменениям в ордерах и сохраняет их в файл 

void SaveOrdersFromHistory  (int total) 
{
 bool   openFileFlag = true;  // Флаг открытия файла 
 int    file_handle  = -1;    // хэндл файла  
 Alert("TOTAL = ",total," OLD TOTAL = ",total_orders_history);
  //--- Пройдем по всем ордерам в полученном списке от последнего ордера в списке к последнему ордеру предыдущей итерации
 for(int i = total-1; i >= total_orders_history; i--)
  {
   // получаем тикет 
   ticket = HistoryOrderGetTicket(i);
   // если символ ордера равен текущему символу
   if (HistoryOrderGetString(ticket, ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(ticket, ORDER_TYPE);          // извлекаем тип ордера
        order_status =  HistoryOrderGetInteger(ticket, ORDER_STATE);         // извлекаем статус ордера
        order_volume =  HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL);  // извлекаем объем ордера (лот) 
        take_profit  =  HistoryOrderGetDouble(ticket, ORDER_TP);             // тейк профит ордера
        stop_loss    =  HistoryOrderGetDouble(ticket, ORDER_SL);             // стоп лосс ордера  
        comment      =  HistoryOrderGetString(ticket, ORDER_COMMENT);        // комментарий к ордеру
        
    // если нашли первый ордер с текущим символом
    if (openFileFlag)               
     {
      // открываем файл на запись
      file_handle = CreateFileW(full_path_history, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // меняем флаг 
      openFileFlag = false;
     }
    // записываем ордер в файл  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // сохраняем новое количество ордеров истории
  total_orders_history = total;
  // закрываем файл
  CloseHandle(file_handle);
}


// Проходит по всем последним изменениям в ордерах и сохраняет их в файл 

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
   ticket = OrderGetTicket(i);
   // если тикет больше нуля 
   if (ticket > 0)
    {
     // если символ ордера равен текущему символу
   if (OrderGetString(ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  OrderGetInteger(ORDER_TYPE);           // извлекаем тип ордера
        order_status =  OrderGetInteger(ORDER_STATE);          // извлекаем статус ордера
        order_volume =  OrderGetDouble(ORDER_VOLUME_INITIAL);  // извлекаем объем ордера (лот) 
        take_profit  =  OrderGetDouble(ORDER_TP);              // тейк профит ордера
        stop_loss    =  OrderGetDouble(ORDER_SL);              // стоп лосс ордера  
        comment      =  OrderGetString(ORDER_COMMENT);         // комментарий к ордеру
        order_price  =  OrderGetDouble(ORDER_PRICE_OPEN);      // цена, указанная в ордере
        
    // если нашли первый ордер с текущим символом
    if (openFileFlag)               
     {
      // открываем файл на запись
      file_handle = CreateFileW(full_path_terminal, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // меняем флаг 
      openFileFlag = false;
     }
    // записываем ордер в файл  
     SaveOrderToFile(file_handle);
     } 
   }
 }
  // закрываем файл
  CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //сохраняет информациб об ордере в файл 
{
 if(handle < 0 )
 {
  Alert("Не удалось записать ордер в файл");
  return false;
 }
 WriteTo(handle, IntegerToString(ticket)+"&");       // сохраняем тикет ордера
 WriteTo(handle, IntegerToString(order_type)+"&");   // сохраняем тип ордера
 WriteTo(handle, IntegerToString(order_status)+"&"); // статус ордера
 WriteTo(handle, DoubleToString(order_volume)+"&");  // сохраняем объем ордера
 WriteTo(handle, DoubleToString(take_profit)+"&");   // сохраняем take profit
 WriteTo(handle, DoubleToString(stop_loss)+"&");     // сохраняем stop loss
 WriteTo(handle, comment+"&");                       // комментарий к ордеру  
 WriteTo(handle, DoubleToString(order_price)+"&");   // получаем цену ордера
 // если использованы отложенники, то цена существует
 
 return true;
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
   Print("неудача. плохой хэндл для файла SPEAKER");
}


int OnInit()
{
 // формируем адрес выходного файла ордеров в истории
 full_path_history = path + file_history+"_"+_Symbol+".txt";
 // формируем адрес выходного файла ордеров
 full_path_terminal = path + file_terminal+"_"+_Symbol+".txt"; 
 // сохраняем текущее количество ордеров в истории
 if(HistorySelect(0,TimeCurrent()))
 {
  //--- Получим количество немедленных ордеров в полученном списке
  total_orders_history = HistoryOrdersTotal();     
 }
 
 return(INIT_SUCCEEDED);
}


void OnTrade()
{
 int total; 
 // проверка на изменение в истории ордеров
 if(HistorySelect(0,TimeCurrent()))
  {
   // вычисляем количество ордеров в истории
   total = HistoryOrdersTotal(); 
   // если текущее количество ордеров больше, чем предыдущее  
   if (total > total_orders_history)
    SaveOrdersFromHistory (total);  
  }
 // проверка на изменение в списке отложенников
  SaveOrdersFromTerminal();
}