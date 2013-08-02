//+------------------------------------------------------------------+
//|                                               testOrderState.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManagerEnums.mqh>
#include <TradeManager\PositionOnPendingOrders.mqh>
#include <TradeManager\PositionArray.mqh>
#include <Trade\PositionInfo.mqh>
#include <Lib CisNewBar.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>

MqlTradeRequest request;
MqlTradeResult result;
CisNewBar bar;
datetime startHistory;
int ticket1 = -1;
int ticket2 = -1;
int ticket3 = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{  
 CreateRequest();
 startHistory = TimeCurrent();
 OrderSend(request, result);
 ticket1 = result.order;
 bar.isNewBar();
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
  HistorySelect(startHistory, TimeCurrent());
 if(bar.isNewBar() > 0)
 {
  if(OrderSelect(ticket1))
   PrintFormat("%d %s", ticket1, EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
  else
  {
   PrintFormat("%d %s", ticket1, EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(ticket1, ORDER_STATE)));
  }
  if(OrderSelect(ticket2))
   PrintFormat("%d %s", ticket2, EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
  else if (ticket2 > 0)
  {
   PrintFormat("%d %s", ticket2, EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(ticket2, ORDER_STATE)));
  }
  if(OrderSelect(ticket3))
   PrintFormat("%d %s", ticket3, EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
  else if (ticket3 > 0)
  {
   PrintFormat("%d %s", ticket3, EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(ticket3, ORDER_STATE)));
  }
  
  if(!OrderSelect(ticket1) && ticket2 < 0 && ticket3 < 0)
  {
   CreateRequest();
   OrderSend(request, result);
   ticket2 = result.order;
   Sleep(2000);
   CreateRequest(true);
   OrderSend(request, result);
   
   CreateRequest();
   OrderSend(request, result);
   ticket3 = result.order;
  } 
 } 
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
  
}
//+------------------------------------------------------------------+
void CreateRequest(bool remove = false)
{
 ZeroMemory(request);
 ZeroMemory(result);
 request.action       = TRADE_ACTION_PENDING;
 if(remove)
 {
  request.action       = TRADE_ACTION_REMOVE;
  request.order        = ticket2;
 }
 request.magic        = 1122;
 request.symbol       = Symbol();
 request.volume       = 1.0;
 request.price        = SymbolInfoDouble(Symbol(), SYMBOL_ASK) + 500*Point();
 request.type         = ORDER_TYPE_SELL_LIMIT;
 request.type_filling = ORDER_FILLING_FOK;
 request.type_time    = ORDER_TIME_SPECIFIED;
 request.expiration   = TimeCurrent() + 2*PeriodSeconds(Period());
}