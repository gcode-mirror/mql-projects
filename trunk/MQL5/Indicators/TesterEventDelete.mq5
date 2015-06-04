//+------------------------------------------------------------------+
//|                                            TesterEventDelete.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <CEventBase.mqh>
//#include <>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
// создать генератор событий
CEventBase *event;
SEventData eventData;      // структура полей событий
int schenchick;
int OnInit()
{
 event = new CEventBase(_Symbol, _Period, 100);
 schenchick = 0;
 Print("индикатор успешно запущен");
 return(INIT_SUCCEEDED);
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
 eventData.dparam = schenchick;
 eventData.lparam = long(TimeCurrent());
 event.Generate("NEW_EVENT", eventData, true);  
 schenchick++; 
 return(rates_total);
}
//+------------------------------------------------------------------+
