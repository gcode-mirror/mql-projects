//+------------------------------------------------------------------+
//|                                             TestIsNewBarData.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
#include <Lib CisNewBarDD.mqh>

input datetime start_time = D'2005.03.17';
input datetime end_time   = D'2014.04.01';

//CisNewBar barM15(PERIOD_M15);
CisNewBar barH1 (PERIOD_D1);
CisNewBar barH4 (PERIOD_W1);
CisNewBar barD1 (PERIOD_MN1);

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
    datetime time [];
    CopyTime(Symbol(), PERIOD_H1, start_time, end_time, time);
    int size = ArraySize(time);
    PrintFormat("start: %s; end: %s; size = %d", TimeToString(start_time), TimeToString(end_time), size);
    PrintFormat("time[0] = %s; time[size-1] = %s", TimeToString(time[0]), TimeToString(time[size-1]));
    for(int i = 0; i < size; i++)
    {
     //if(barM15.isNewBar(time[i])) PrintFormat("New bar M15. time = %s", TimeToString(time[i]));
     //if( barH1.isNewBar(time[i])) PrintFormat("New bar  D1. time = %s", TimeToString(time[i]));
     if( barH4.isNewBar(time[i])) PrintFormat("New bar  W4. time = %s", TimeToString(time[i]));
     if( barD1.isNewBar(time[i])) PrintFormat("New bar  MN1. time = %s", TimeToString(time[i]));
    }
    PrintFormat("END");
  }
//+------------------------------------------------------------------+
