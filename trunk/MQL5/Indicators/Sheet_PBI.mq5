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
input string file_name = "Sheet_PBI";
input string indicator_name = "PBI_alone";

CisNewBar *isNewBar;   // для проверки формирования нового бара на 15 минутах

int file_handle;

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
double buffer_PBI_top_M15[];
double buffer_PBI_top_H1 [];
double buffer_PBI_top_H4 [];
double buffer_PBI_top_D1 [];
double buffer_PBI_top_W1 [];
double buffer_PBI_top_MN1[];
datetime buffer_time[];

bool written = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 file_handle = FileOpen(StringFormat("%s_%s_PBI_%d.csv", file_name, EnumToString((ENUM_TIMEFRAMES)Period()),rand()%1000), FILE_WRITE|FILE_CSV|FILE_COMMON);
 FileWrite(file_handle, "DATETIME;PERIOD_M15;PERIOD_H1;PERIOD_H1;PERIOD_H4;PERIOD_H4;PERIOD_D1;PERIOD_D1;PERIOD_W1;PERIOD_W1;PERIOD_MN1;PERIOD_MN1;PERIOD_MN1");
 
 handle_PBI_MN1 = iCustom(Symbol(), PERIOD_MN1, indicator_name, DEPTH);
 handle_PBI_W1  = iCustom(Symbol(), PERIOD_W1 , indicator_name, DEPTH);
 handle_PBI_D1  = iCustom(Symbol(), PERIOD_D1 , indicator_name, DEPTH);
 handle_PBI_H4  = iCustom(Symbol(), PERIOD_H4 , indicator_name, DEPTH);
 handle_PBI_H1  = iCustom(Symbol(), PERIOD_H1 , indicator_name, DEPTH);
 handle_PBI_M15 = iCustom(Symbol(), PERIOD_M15, indicator_name, DEPTH);
 
 isNewBar = new CisNewBar(_Symbol, _Period);   // для проверки формирования нового бара на 15 минутах
 PrintFormat("Инициализация закончена. %d", DEPTH);
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 PrintFormat("REASON FOR DEINIT %d", reason);
 
 FileClose(file_handle);
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
 ArrayFree(buffer_PBI_top_M15);
 ArrayFree(buffer_PBI_top_H1);
 ArrayFree(buffer_PBI_top_H4);
 ArrayFree(buffer_PBI_top_D1);
 ArrayFree(buffer_PBI_top_W1);
 ArrayFree(buffer_PBI_top_MN1);
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
  
  CopyBuffer(handle_PBI_MN1, 4, 0, 1, buffer_PBI_MN1);
  CopyBuffer(handle_PBI_W1 , 4, 0, 1, buffer_PBI_W1 );
  CopyBuffer(handle_PBI_D1 , 4, 0, 1, buffer_PBI_D1 );
  CopyBuffer(handle_PBI_H4 , 4, 0, 1, buffer_PBI_H4 );
  CopyBuffer(handle_PBI_H1 , 4, 0, 1, buffer_PBI_H1 );
  CopyBuffer(handle_PBI_M15, 4, 0, 1, buffer_PBI_M15);
  CopyBuffer(handle_PBI_MN1, 7, 0, 1, buffer_PBI_top_MN1);
  CopyBuffer(handle_PBI_W1 , 7, 0, 1, buffer_PBI_top_W1 );
  CopyBuffer(handle_PBI_D1 , 7, 0, 1, buffer_PBI_top_D1 );
  CopyBuffer(handle_PBI_H4 , 7, 0, 1, buffer_PBI_top_H4 );
  CopyBuffer(handle_PBI_H1 , 7, 0, 1, buffer_PBI_top_H1 );
  CopyBuffer(handle_PBI_M15, 7, 0, 1, buffer_PBI_top_M15);
  
  //PrintFormat("Новый бар %s; загружено M15 = %d (%f)", TimeToString(time[0]), err6, buffer_PBI_M15[0]);
  
  FileWrite(file_handle, StringFormat("%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s", TimeToString(time[0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_M15[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_M15[0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_H1 [0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_H1 [0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_H4 [0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_H4 [0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_D1 [0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_D1 [0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_W1 [0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_W1 [0]),
                                                                                                  MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_MN1[0]), MoveTypeToString((ENUM_MOVE_TYPE)buffer_PBI_top_MN1[0])));
 }
 
 return(rates_total);
}
//+------------------------------------------------------------------+

