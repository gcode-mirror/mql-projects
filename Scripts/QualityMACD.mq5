//+------------------------------------------------------------------+
//|                                                  QualityMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <divergenceMACD.mqh>

input int check_depth = 100;    //глубина проверки в барах
input int fast_ema_period = 12; // период быстрой EMA MACD
input int slow_ema_period = 26; // период медленной EMA MACD
input int signal_period = 9;    // период сигнальной EMA MACD
//input string filename = "qualityMACD.txt";

string symbol = _Symbol;
ENUM_TIMEFRAMES period = _Period;

void OnStart()
{

 //int filehandle=FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_COMMON);
 //if(filehandle == INVALID_HANDLE) {Print("Error");}
 int handleMACD = iMACD(symbol, PERIOD_CURRENT, fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE);
 int direction = 0;
 
 Print("BEGIN");
 for (int i = check_depth + 5; i > 5; i--)
 {
  direction = divergenceMACD(handleMACD, symbol, PERIOD_CURRENT, i);
  if(direction != 0) 
  {
   //PrintFormat("index = %d; direction = %d", i, direction);
   Quality(i-5);
  }
 } 
 Print("END");
 //FileClose(filehandle);  
}
//+------------------------------------------------------------------+
bool Quality(int start_pos)
{
 double buffer_high[5] = {0};
 double buffer_low[5] = {0};
 datetime date_buf[5] = {0};
 int copiedHigh = -1;
 int copiedLow = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedHigh < 0
                                   && copiedLow  < 0 
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedHigh = CopyHigh(symbol, period, start_pos, 5, buffer_high); 
  copiedLow  = CopyLow (symbol, period, start_pos, 5, buffer_low);
  copiedDate = CopyTime(symbol, period, start_pos, 5, date_buf); 
 }
 if (copiedHigh != 5 || copiedLow != 5)
 {
   int err = GetLastError();
   Alert(__FUNCTION__, "Не удалось скопировать буффер котировок полностью. Error = ", err);
   return(false);
 }
 
 double highhigh = buffer_high[ArrayMaximum(buffer_high)];
 double lowlow = buffer_low[ArrayMinimum(buffer_low)];
 PrintFormat("%d | проверенно на барах с  %s по %s: HighHigh = %f; LowLow = %f", start_pos, TimeToString(date_buf[0]), TimeToString(date_buf[4]), highhigh, lowlow);
 return(true);
}