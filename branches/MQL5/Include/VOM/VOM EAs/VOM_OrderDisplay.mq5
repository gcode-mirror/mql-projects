//+------------------------------------------------------------------+
//|                                             VOM_OrderDisplay.mq5 |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
#property version   "1.00"

#include "..\Log.mqh"
#include "..\VirtualOrderArray.mqh"
#include "..\VirtualOrderManagerConfig.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   LogFile.LogLevel(LOG_MAJOR);
   Display();
   EventSetTimer(60);
   return(0);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam  // Parameter of type string events
                  )
  {
// id arrives with CHARTEVENT_CUSTOM added
   if(id==CHARTEVENT_CUSTOM+Config.CustomVirtualOrderEvent)
      Display();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   Display();
  }
//+------------------------------------------------------------------+

void Display()
  {
   CVirtualOrderArray voa;
   voa.ReadAllVomOpenOrders(Config.FileBase);
   string strComment="";
   for(int i=0; i<voa.Total();i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      StringConcatenate(strComment,strComment,voa.VirtualOrder(i).Trace(),"\n");
     }
   Comment(strComment);
  }
//+------------------------------------------------------------------+
