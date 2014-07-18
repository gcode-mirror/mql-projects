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

input ENUM_TIMEFRAMES tf_1 = PERIOD_M15;
input ENUM_TIMEFRAMES tf_2 = PERIOD_H1;
input string file_name = "test_pbi";
input string indicator_name = "PriceBasedIndicator";

CisNewBar *isNewBar;   // для проверки формирования нового бара на 15 минутах

int file_handle;

int handle_PBI_1;
int handle_PBI_2;
datetime buffer_time[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 file_handle = FileOpen(StringFormat("%s_%s_PBI_%d.csv", file_name, EnumToString((ENUM_TIMEFRAMES)Period()),rand()%1000), FILE_WRITE|FILE_CSV|FILE_COMMON);
 FileWrite(file_handle, "DATETIME;%s;%s", EnumToString((ENUM_TIMEFRAMES)GetTopTimeframe(tf_1)), EnumToString((ENUM_TIMEFRAMES)tf_2));
 
 handle_PBI_1 = iCustom(Symbol(), tf_1, indicator_name, DEPTH);
 handle_PBI_2 = iCustom(Symbol(), tf_2, indicator_name, DEPTH);

 isNewBar = new CisNewBar(_Symbol, _Period);   // для проверки формирования нового бара на 15 минутах
 PrintFormat("Инициализация закончена. %d", DEPTH);
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 PrintFormat("REASON FOR DEINIT %d", reason);
 
 FileClose(file_handle);
 IndicatorRelease(handle_PBI_1);
 IndicatorRelease(handle_PBI_2);
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
 double buffer_PBI_1[1] = {MOVE_TYPE_UNKNOWN};
 double buffer_PBI_top_1[1] = {MOVE_TYPE_UNKNOWN};
 double buffer_PBI_2[1] = {MOVE_TYPE_UNKNOWN};
 double buffer_PBI_top_2[1] = {MOVE_TYPE_UNKNOWN};
 
 datetime date_from = D'2014.05.09 23:10:00';
 datetime date_to   = D'2014.05.09 23:20:00';
 
 if(isNewBar.isNewBar())
 {
  if(TimeCurrent() >= date_from && TimeCurrent() <= date_to)PrintFormat("запускаю копибуфер.до:  movetype_1 = %s; movetype_top_1 = %s; movetype_2 = %s; movetype_top_2 = %s",
                                                                        MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_1[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_1[0]),
                                                                        MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_2[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_2[0]));
  CopyBuffer(handle_PBI_1, 4, 0, 1, buffer_PBI_1);
  CopyBuffer(handle_PBI_1, 7, 0, 1, buffer_PBI_top_1);
  CopyBuffer(handle_PBI_2, 4, 0, 1, buffer_PBI_2);
  CopyBuffer(handle_PBI_2, 7, 0, 1, buffer_PBI_top_2);
  
  if(TimeCurrent() >= date_from && TimeCurrent() <= date_to)PrintFormat("после: movetype_1 = %s; movetype_top_1 = %s; movetype_2 = %s; movetype_top_2 = %s",
                                                                        MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_1[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_1[0]),
                                                                        MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_2[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_2[0]));
  FileWrite(file_handle ,StringFormat("%s;%s;%s;%s;%s", TimeToString(time[0]),
                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_1[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_1[0]),
                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_2[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_2[0])));
 }
 
 return(rates_total);
}
//+------------------------------------------------------------------+

