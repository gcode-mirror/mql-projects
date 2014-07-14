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
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#define DEPTH 1000

//input double   percentage_ATR = 1;   
//input double   difToTrend = 1.5;
input ENUM_TIMEFRAMES tf = PERIOD_H4;
input string file_name = "test_pbi";
input string indicator_name = "PBI_alone";

CisNewBar *isNewBar;   // для проверки формирования нового бара на 15 минутах

int file_handle;

int handle_PBI;
double buffer_PBI[];
double buffer_PBI_top[];
datetime buffer_time[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 file_handle = FileOpen(StringFormat("%s_%s_PBI_%d.csv", file_name, EnumToString((ENUM_TIMEFRAMES)Period()),rand()%1000), FILE_WRITE|FILE_CSV|FILE_COMMON);
 FileWrite(file_handle, "DATETIME;%s;%s", EnumToString((ENUM_TIMEFRAMES)tf), EnumToString((ENUM_TIMEFRAMES)GetTopTimeframe(tf)));
 
 handle_PBI = iCustom(Symbol(), tf, indicator_name, DEPTH);

 isNewBar = new CisNewBar(_Symbol, _Period);   // для проверки формирования нового бара на 15 минутах
 PrintFormat("Инициализация закончена. %d", DEPTH);
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 PrintFormat("REASON FOR DEINIT %d", reason);
 
 FileClose(file_handle);
 IndicatorRelease(handle_PBI);
 ArrayFree(buffer_PBI);
 ArrayFree(buffer_PBI_top);
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
 if(isNewBar.isNewBar())
 {
  
  CopyBuffer(handle_PBI, 4, 0, 1, buffer_PBI);
  CopyBuffer(handle_PBI, 7, 0, 1, buffer_PBI_top);
  
  //PrintFormat("Новый бар %s; загружено M15 = %d (%f)", TimeToString(time[0]), err6, buffer_PBI_M15[0]);
  
  PrintFormat("%s;%s;%s", TimeToString(time[0]),
                          MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top[0]));
 }
 
 return(rates_total);
}
//+------------------------------------------------------------------+

