//+------------------------------------------------------------------+
//|                                              VOM Template EA.mq5 |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
#property version   "1.00"

#include "..\VirtualOrderManager.mqh"

input int Stop_Loss=1000;
input int Take_Profit=1000;
input ENUM_LOG_LEVEL Log_Level=LOG_DEBUG;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   LogFile.LogLevel(Log_Level);

// Need to include these lines in all EAs using CVirtualOrderManager
// default magic is created from EA name, otherwise enter as parameter here
   VOM.Initialise();

// Simple list of orders using comment field  
   Comment(VOM.m_OpenOrders.SummaryList());

   return(0);
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
// Need to include these lines in all EAs using CVirtualOrderManager  
   VOM.OnTick();
   Comment(VOM.m_OpenOrders.SummaryList());

// for acting at beginning of bar only
//	if (!VOM.NewBar()) return;

// Simplest Buy and Sell commands
// VOM.Buy(Symbol(),Lots,Stop_Loss,Take_Profit);
// VOM.Sell(Symbol(),Lots,Stop_Loss,Take_Profit);
  }
//+------------------------------------------------------------------+
