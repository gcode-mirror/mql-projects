//+------------------------------------------------------------------+
//|                                                    Sheet_PBI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <Lib CisNewBarDD.mqh>
#define DEPTH 100

input double   percentage_ATR = 1;   
input double   difToTrend = 1.5;
input string   file_name = "Sheet_PBI";
input datetime end_time = D'2014.03.03';

CisNewBar *isNewBarMN1;   // для проверки формирования нового бара на месяце
CisNewBar *isNewBarW1;    // для проверки формирования нового бара на неделе
CisNewBar *isNewBarD1;    // для проверки формирования нового бара на дне
CisNewBar *isNewBarH4;    // для проверки формирования нового бара на 4 часах
CisNewBar *isNewBarH1;    // для проверки формирования нового бара на часе
CisNewBar *isNewBarM15;   // для проверки формирования нового бара на 15 минутах

int file_handle_MN1;
int file_handle_W1;
int file_handle_D1;
int file_handle_H4;
int file_handle_H1;
int file_handle_M15;
int file_handle_time;

int handle_PBI_M15;
int handle_PBI_H1;
int handle_PBI_H4;
int handle_PBI_D1;
int handle_PBI_W1;
int handle_PBI_MN1;
double buffer_PBI_M15[];
double buffer_PBI_H1 [];
double buffer_PBI_H4 [];
double buffer_PBI_D1 [];
double buffer_PBI_W1 [];
double buffer_PBI_MN1[];
datetime buffer_time[];

string str_MN1 = "PERIOD_MN1;";
string str_W1  = "PERIOD_W1;";
string str_D1  = "PERIOD_D1;";
string str_H4  = "PERIOD_H4;";
string str_H1  = "PERIOD_H1;";
string str_M15 = "PERIOD_M15;";
string str_time = "datetime;";

bool written = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 file_handle_MN1 = FileOpen(StringFormat("%s_MN1.csv", file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_W1  = FileOpen(StringFormat("%s_W1.csv" , file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_D1  = FileOpen(StringFormat("%s_D1.csv" , file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_H4  = FileOpen(StringFormat("%s_H4.csv" , file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_H1  = FileOpen(StringFormat("%s_H1.csv" , file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_M15 = FileOpen(StringFormat("%s_M15.csv", file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 file_handle_time = FileOpen(StringFormat("%s_time.csv", file_name), FILE_WRITE|FILE_CSV|FILE_COMMON);
 
 handle_PBI_MN1 = -1;//iCustom(Symbol(), PERIOD_MN1, "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 handle_PBI_W1  = -1;//iCustom(Symbol(), PERIOD_W1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 handle_PBI_D1  = -1;//iCustom(Symbol(), PERIOD_D1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 handle_PBI_H4  = -1;//iCustom(Symbol(), PERIOD_H4 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 handle_PBI_H1  = -1;//iCustom(Symbol(), PERIOD_H1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 handle_PBI_M15 = iCustom(Symbol(), PERIOD_M15, "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 
 isNewBarM15 = new CisNewBar(_Symbol, PERIOD_M15);   // для проверки формирования нового бара на 15 минутах
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 PrintFormat("REASON FOR DEINIT %d", reason);
 
 FileClose(file_handle_M15);
 FileClose(file_handle_H1);
 FileClose(file_handle_H4);
 FileClose(file_handle_D1);
 FileClose(file_handle_W1);
 FileClose(file_handle_MN1);
 FileClose(file_handle_time);
 IndicatorRelease(handle_PBI_M15);
 IndicatorRelease(handle_PBI_H1);
 IndicatorRelease(handle_PBI_H4);
 IndicatorRelease(handle_PBI_D1);
 IndicatorRelease(handle_PBI_W1);
 IndicatorRelease(handle_PBI_MN1);
 ArrayFree(buffer_PBI_M15);
 ArrayFree(buffer_PBI_H1);
 ArrayFree(buffer_PBI_H4);
 ArrayFree(buffer_PBI_D1);
 ArrayFree(buffer_PBI_W1);
 ArrayFree(buffer_PBI_MN1);
 ArrayFree(buffer_time);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
 ArraySetAsSeries(time, true);
 
 if(isNewBarM15.isNewBar())
 {
  
  //int err1 = CopyBuffer(handle_PBI_MN1, 4, 0, 1, buffer_PBI_MN1);
  //int err2 = CopyBuffer(handle_PBI_W1 , 4, 0, 1, buffer_PBI_W1 );
  //int err3 = CopyBuffer(handle_PBI_D1 , 4, 1, 1, buffer_PBI_D1 );
  //int err4 = CopyBuffer(handle_PBI_H4 , 4, 1, 1, buffer_PBI_H4 );
  //int err5 = CopyBuffer(handle_PBI_H1 , 4, 1, 1, buffer_PBI_H1 );
  int err6 = CopyBuffer(handle_PBI_M15, 4, 1, 1, buffer_PBI_M15);
  
  PrintFormat("Новый бар %s; загружено M15 = %d (%d)", TimeToString(time[0]), err6, buffer_PBI_M15[0]);
    
  //StringConcatenate(str_MN1, str_MN1, StringFormat("%d;", buffer_PBI_MN1[0]));
  //StringConcatenate(str_W1 , str_W1 , StringFormat("%d;", buffer_PBI_W1 [0]));
  //StringConcatenate(str_D1 , str_D1 , StringFormat("%d;", buffer_PBI_D1 [0]));
  //StringConcatenate(str_H4 , str_H4 , StringFormat("%d;", buffer_PBI_H4 [0]));
  //StringConcatenate(str_H1 , str_H1 , StringFormat("%d;", buffer_PBI_H1 [0]));
  StringConcatenate(str_M15, str_M15, StringFormat("%d;", buffer_PBI_M15[0]));
  StringConcatenate(str_time, str_time, StringFormat("%s;", TimeToString(time[0])));
 }
 
 if(time[0] == (end_time - PeriodSeconds(PERIOD_M15)) && written)
 {
  written = false;
  PrintFormat("%s Закончилась запись в файл. Дальнейшее выполнение бесполесно. time = %s", __FUNCTION__, TimeToString(time[0]));
  FileWrite(file_handle_M15, str_M15);
  FileWrite(file_handle_H1 , str_H1);
  FileWrite(file_handle_H4 , str_H4);
  FileWrite(file_handle_D1 , str_D1);
  FileWrite(file_handle_W1 , str_W1);
  FileWrite(file_handle_MN1, str_MN1);
  FileWrite(file_handle_time, str_time);
  PrintFormat("%s", str_time);
  PrintFormat("%s", str_M15);
 }
 
 return(rates_total);
}
//+------------------------------------------------------------------+

