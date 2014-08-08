//+------------------------------------------------------------------+
//|                                                     AllIWant.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TMPCTM.mqh>
#include <Graph\Widgets\WTradeWidget.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

CTMTradeFunctions *ctm;
WTradeWidget *widget;

int OnInit()
  {
   ctm = new CTMTradeFunctions();
   widget = new WTradeWidget(_Symbol,"TradeWidget","TradeWidget",10,10,0,0,0);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete ctm;
   delete widget;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


void OnTick()
  {
   widget.OnTick();
  }
  
// метод обработки событий  
void OnChartEvent(const int id,
                const long &lparam,
                const double &dparam,
                const string &sparam)
 { 
   // если нажата кнопка
   if(id==CHARTEVENT_OBJECT_CLICK)
    {
     widget.Action(sparam);  
    }
 }