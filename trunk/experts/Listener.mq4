//+------------------------------------------------------------------+
//|                                                     Listener.mq4 |
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
/*   bool ReadFile (int hFile, double& lpBuffer[], int nNumberOfBytesToRead, int& lpNumberOfBytesRead[], int lpOverlapped);
   int CreateFileW(string lpFileName,         // pointer to name of the file
                   int dwDesiredAccess,       // access (read-write) mode
                   int dwShareMode,           // share mode
                   int lpSecurityAttributes,  // pointer to security attributes
                   int dwCreationDisposition, // how to create
                   int dwFlagsAndAttributes,  // file attributes
                   int hTemplateFile          // handle to file with attributes to
                   );*/
#import


int    deal_type=0;         //тип сделки
double deal_volume=0;       //объем сделки
double deal_price=0;        //цена сделки
double date_last_pos;       //дата последней позиции


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Alert("Init");
   date_last_pos=TimeCurrent();
   Alert(ReadFile("C:\Users\Desepticon2\Desktop\Speaker.txt"));
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
 }
//+------------------------------------------------------------------+

string ReadFile (string path) 
  {
    int handle=_lopen (path,OF_READ);           
    if(handle<0) 
      {
        Print("Ошибка открытия файла ",path); 
        return ("");
      }
    int result=_llseek (handle,0,0);      
    if(result<0) 
      {
        Print("Ошибка установки указателя" ); 
        return ("");
      }
    string buffer="";
    string char1="x";
    int count=0;
    result=_lread (handle,char1,1);
    while(result>0) 
      {
        buffer=buffer+char1;
        char1="x";
        count++;
        result=_lread (handle,char1,1);
     }
    result=_lclose (handle);              
    if(result<0)  
      Print("Ошибка закрытия файла ",path);
    return (buffer);
  }