//+------------------------------------------------------------------+
//|                                                      Speaker.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"


// константы для функции _lopen
#define OF_READ               0
#define OF_WRITE              1
#define OF_READWRITE          2
#define OF_SHARE_COMPAT       3
#define OF_SHARE_DENY_NONE    4
#define OF_SHARE_DENY_READ    5
#define OF_SHARE_DENY_WRITE   6
#define OF_SHARE_EXCLUSIVE    7
 
 
#import "kernel32.dll"
   int _lopen  (string path, int of);
   int _lcreat (string path, int attrib);
   int _llseek (int handle, int offset, int origin);
   int _lread  (int handle, string buffer, int bytes);
   int _lwrite (int handle, string buffer, int bytes);
   int _lclose (int handle);
#import

int    deal_type=0;  //тип сделки
double deal_volume=0; //объем сделки
double deal_price=0; //цена сделки
int    start_time;     //самая первая дата при загрузке эксперта
int    handle = 0;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
 start_time = TimeCurrent();
 WriteFile("C:\Users\Desepticon2\Desktop\Speaker.txt", "HELLO WORLD!");
 return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
 return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
 
 return(0);
}
//+------------------------------------------------------------------+

bool CurrentPositionLastDealPrice() //возвращает параметры последней сделки
{
 int    total       = 0;   // Всего сделок в списке выбранной истории
 string deal_symbol = "";  // Символ сделки
 //--- Получим количество сделок в полученном списке
 total = OrdersHistoryTotal();     
 //--- Пройдем по всем сделкам в полученном списке от последней сделки в списке к первой
 for(int i = total-1; i >= 0; i--)
 {
  OrderSelect(i, SELECT_BY_POS, MODE_HISTORY);
  deal_symbol = OrderSymbol();
  //--- Если символ сделки и текущий символ равны, остановим цикл
  if(deal_symbol == Symbol())
  {
   deal_type = OrderType();
   deal_volume = OrderLots();
   deal_price = OrderClosePrice();              
   start_time = TimeCurrent();
   return (true); 
  }
 }
 return (false);
}

void WriteFile (string path, string buffer) 
{
 int count=StringLen (buffer); 
 int result;
 int handle=_lopen (path,OF_SHARE_DENY_NONE);
 if(handle<0) 
 {
  handle=_lcreat (path,0);
  if(handle<0) 
  {
    Print ("Ошибка создания файла ",path);
    return;
  }
  result=_lclose (handle);
 }
 
 handle=_lopen (path,OF_WRITE);               
 if(handle<0) 
 {
  Print("Ошибка открытия файла ",path); 
  return;
 }
 
 result=_llseek (handle,0,0);          
 if(result<0) 
 {
  Print("Ошибка установки указателя"); 
  return;
 }
 
 result=_lwrite (handle,buffer,count); 
 if(result<0)  
  Print("Ошибка записи в файл ",path," ",count," байт");
  
 result=_lclose (handle);              
 if(result<0)  
  Print("Ошибка закрытия файла ",path);
}