//+------------------------------------------------------------------+
//|                                           FraMA Cross EA VOM.mq5 |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
#property version   "1.00"

// this is the only VOM include required.  It points to the parent folder
#include "..\VirtualOrderManager.mqh"

input double   Lots=0.1;
input int      Fast_MA_Period=2;
input int      Slow_MA_Period=58;
/* 
Because the broker is 3/5 digit, stoplosses and takeprofits should be x10.  
It seems likely that all brokers offering MT5 will be 3/5 digit brokers, 
but if this turns out to be incorrect it will not be a major task to add 
digit size detection. */
input int      Stop_Loss=5000;
input int      Take_Profit=0;
/*
We can also change the level of logging.  LOG_VERBOSE is the most prolific 
log level.  Once an EA has been fully debugged the level can be reduced to 
LOG_MAJOR.  Log files are written under the files\EAlogs folder and are 
automatically deleted after 30 days.  */
input ENUM_LOG_LEVEL Log_Level=LOG_VERBOSE;

// The following global variables will store the handles and values for the MAs 
double g_FastFrAMA[];
double g_SlowFrAMA[];
int g_hFastFrAMA;
int g_hSlowFrAMA;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   LogFile.LogLevel(Log_Level);

// Need to include this line in all EAs using CVirtualOrderManager  
   VOM.Initialise();
   Comment(VOM.m_OpenOrders.SummaryList());

   g_hFastFrAMA = iFrAMA(_Symbol,_Period,Fast_MA_Period,0,PRICE_CLOSE);
   g_hSlowFrAMA = iFrAMA(_Symbol,_Period,Slow_MA_Period,0,PRICE_CLOSE);
   ArraySetAsSeries(g_FastFrAMA,true);
   ArraySetAsSeries(g_SlowFrAMA,true);

   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Need to include this line in all EAs using CVirtualOrderManager  
   VOM.OnTick();
   Comment(VOM.m_OpenOrders.SummaryList());

// We now obtain copies of the most recent two FrAMA values in the 
// g_FastFrAMA and  g_SlowFrAMA arrays.  
   if((CopyBuffer(g_hFastFrAMA,0,1,2,g_FastFrAMA)!=2) || 
      CopyBuffer(g_hSlowFrAMA,0,1,2,g_SlowFrAMA)!=2)
     {
      Print("Not enough history loaded");
      return;
     }

// And now we detect a cross of the fast FrAMA over the slow FrAMA,
// close any opposite orders and Buy a single new one
   if(g_FastFrAMA[0]>g_SlowFrAMA[0] && g_FastFrAMA[1]<=g_SlowFrAMA[1])
     {
      VOM.CloseAllOrders(_Symbol,VIRTUAL_ORDER_TYPE_SELL);
      if(VOM.OpenedOrdersInSameBar()<1 && VOM.OpenOrders()==0)
        {
         VOM.Buy(_Symbol,Lots,Stop_Loss,Take_Profit);
        }
     }

// Opposite for Sell
   if(g_FastFrAMA[0]<g_SlowFrAMA[0] && g_FastFrAMA[1]>=g_SlowFrAMA[1])
     {
      VOM.CloseAllOrders(_Symbol,VIRTUAL_ORDER_TYPE_BUY);
      if(VOM.OpenedOrdersInSameBar()<1 && VOM.OpenOrders()==0)
        {
         VOM.Sell(_Symbol,Lots,Stop_Loss,Take_Profit);
        }
     }
  }
//+------------------------------------------------------------------+
