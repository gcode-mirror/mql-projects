//+------------------------------------------------------------------+
//|                                      TesterEventDeleteExpert.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CLog.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int handleTest;
int OnInit()
{
 handleTest = iCustom(_Symbol,_Period,"TesterEventDelete");
 handleTest = iCustom(_Symbol,_Period,"TesterEventDelete");
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

   
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 if(sparam == "NEW_EVENT")
 { 
  log_file.Write(LOG_DEBUG, StringFormat("%s Событие время = %s счетчик = %d", _Symbol, TimeToString(datetime(lparam)),dparam));
 } 
   
}
//+------------------------------------------------------------------+
