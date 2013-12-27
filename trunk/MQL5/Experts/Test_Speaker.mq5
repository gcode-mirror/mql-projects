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
input string   path     = "D:\\";        // путь к файлу, хранящего информацию о последних ордерах 
input string   file_instant = "INSTANT"; // часть  имени файла, хранящего информацию о последних немедленных ордерах
input string   file_pending = "PENDING"; // часть  имени файла, хранящего информацию о последних отложенных ордерах

string   full_path_instant;              // полный путь к файлу немедленных ордеров
string   full_path_pending;              // полный путь к файлу отложенных ордеров  

int      total_instant_orders  = 0;            // всего немедленных ордеров в истории

// параметры для всех типов сделок
long     order_type     = 0;     //тип ордера
double   order_volume   = 0;     //объем ордера
double   take_profit    = 0;     //тейк профит
double   stop_loss      = 0;     //стоп лосс
// параметры для отложенников
double   order_price    = -1;    //цена ордера 


//+------------------------------------------------------------------+
//| Функции спикера                                                  |
//+------------------------------------------------------------------+

// Проходит по всем последним немедленным ордерам и сохраняет их в файл 

void SaveNewInstantOrders (int total) 
{
 bool   openFileFlag = true;  // Флаг открытия файла на 
 int    file_handle  = -1;    // хэндл файла  
  //--- Пройдем по всем ордерам в полученном списке от последнего ордера в списке к последнему ордеру предыдущей итерации
 for(int i = total-1; i >= total_instant_orders; i--)
  {
     // если символ ордера равен текущему символу
   if (HistoryOrderGetString(HistoryOrderGetTicket(i), ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_TYPE);          // извлекаем тип ордера
        order_volume =  HistoryOrderGetDouble(HistoryOrderGetTicket(i),ORDER_VOLUME_INITIAL);  // извлекаем объем ордера (лот) 
        take_profit  =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_TP);             // тейк профит ордера
        stop_loss    =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_SL);             // стоп лосс ордера    
     
    // если нашли первый ордер с текущим символом
    if (openFileFlag)               
     {
      // открываем файл на запись
      file_handle = CreateFileW(full_path_instant, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // меняем флаг 
      openFileFlag = false;
     }
    // записываем ордер в файл  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // сохраняем новое количество ордеров истории
  total_instant_orders = total;
  // закрываем файл
  CloseHandle(file_handle);
}


// Проходит по всем последним отложенным ордерам и сохраняет их в файл 

void SaveNewPendingOrders (int total) 
{
 bool   openFileFlag = true;  // Флаг открытия файла на 
 int    file_handle  = -1;    // хэндл файла  
  //--- Пройдем по всем ордерам в полученном списке от последнего ордера в списке к последнему ордеру предыдущей итерации
 for(int i = total-1; i >= total_instant_orders; i--)
  {
     // если символ ордера равен текущему символу
   if (HistoryOrderGetString(HistoryOrderGetTicket(i), ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_TYPE);          // извлекаем тип ордера
        order_volume =  HistoryOrderGetDouble(HistoryOrderGetTicket(i),ORDER_VOLUME_INITIAL);  // извлекаем объем ордера (лот) 
        take_profit  =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_TP);             // тейк профит ордера
        stop_loss    =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_SL);             // стоп лосс ордера    
     
    // если нашли первый ордер с текущим символом
    if (openFileFlag)               
     {
      // открываем файл на запись
      file_handle = CreateFileW(full_path_instant, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // меняем флаг 
      openFileFlag = false;
     }
    // записываем ордер в файл  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // сохраняем новое количество ордеров истории
  total_instant_orders = total;
  // закрываем файл
  CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //сохраняет информациб об оредере в файл 
{
 if(handle < 0 )
 {
  Alert("Не удалось записать ордер в файл");
  return false;
 }
 
 WriteTo(handle, IntegerToString(order_type)+"&");   // сохраняем тип ордера
 WriteTo(handle, DoubleToString(order_volume)+"&");  // сохраняем объем ордера
 WriteTo(handle, DoubleToString(take_profit)+"&");   // сохраняем take profit
 WriteTo(handle, DoubleToString(stop_loss)+"&");     // сохраняем stop loss  
 // если использованы отложенники, то цена существует
 if (order_price != -1 )
  {
   WriteTo(handle, DoubleToString(order_price)+"&"); // сохраняем цену отложенного ордера 
  }
   
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
   Print("неудача. плохой хэндл для файла Говоруна");
}


int OnInit()
{
 // формируем адрес выходного файла немедленных ордеров
 full_path_instant = path + file_instant+"_"+_Symbol+".txt";
 // формируем адрес выходного файла отложенных ордеров
 full_path_pending = path + file_pending+"_"+_Symbol+".txt"; 
 // сохраняем текущее количество ордеров в истории
 if(HistorySelect(0,TimeCurrent()))
 {
  //--- Получим количество немедленных ордеров в полученном списке
  total_instant_orders = HistoryOrdersTotal();     
 }
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
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
   if (total > total_instant_orders)
    SaveNewInstantOrders (total);  
  }
 // проверка на изменение в списке отложенников
}