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
datetime start_history;
int ticket1 = -1;
int ticket2 = -1;
int ticket3 = -1;
int count = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 log_file.Write(LOG_DEBUG, "Hello");  
 CreateRequest();
 start_history = TimeCurrent();
 OrderSend(request, result);
 count++;
 PrintHistoryState();
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
  HistorySelect(start_history, TimeCurrent());
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
  PrintHistoryState();
  
  if(!OrderSelect(ticket1) && ticket2 < 0 && ticket3 < 0)
  {
   CreateRequest();
   OrderSend(request, result);
   count++;
   PrintHistoryState();
   log_file.Write(LOG_DEBUG, "Open order#2");  
   ticket2 = result.order;
   Sleep(2000);
   CreateRequest(true);
   OrderSend(request, result);
   PrintHistoryState();
   log_file.Write(LOG_DEBUG, "Close oreder#2");  
   
   CreateRequest();
   OrderSend(request, result);
   ticket3 = result.order;
   count++;
   PrintHistoryState();
   log_file.Write(LOG_DEBUG, "Open order#3");  
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

void PrintHistoryState()
{
 HistorySelect(start_history, TimeCurrent());
 int total = HistoryOrdersTotal();
 
 int canceled = 0;
 int expired = 0;
 int filled = 0;
 int partial = 0;
 int placed = 0; 
 int rejected = 0;
 int request_add = 0;
 int request_cancel = 0;
 int request_modify = 0;
 int started = 0;
 string str = "";
 if (total != 0)
 {
 for(int i = total-1; i >= 0; i--)
 {
  str += HistoryOrderGetTicket(i) + "_";
  switch(HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_STATE))
  {
   case ORDER_STATE_CANCELED:
   canceled++;
   break;
   case ORDER_STATE_EXPIRED:
   expired++;
   break;
   case ORDER_STATE_FILLED:
   filled++;
   break;
   case ORDER_STATE_PARTIAL:
   partial++;
   break;
   case ORDER_STATE_PLACED:
   placed++;
   break;  
   case ORDER_STATE_REJECTED:
   rejected++;
   break;
   case ORDER_STATE_REQUEST_ADD:
   request_add++;
   break;
   case ORDER_STATE_REQUEST_CANCEL:
   request_cancel++;
   break;
   case ORDER_STATE_REQUEST_MODIFY:
   request_modify++;
   break;
   case ORDER_STATE_STARTED:
   log_file.Write(LOG_DEBUG, StringFormat("STARTED i = %d, ticket = %d, openprice = %f", i, HistoryOrderGetTicket(i), HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_PRICE_OPEN)));
   started++;
   break;
  }
 }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%d canceled=%d; expired=%d; filled=%d; started=%d; partial=%d; rejected=%d; request_a=%d; request_c=%d; request_m=%d; placed=%d;"
            , count, canceled, expired, filled, started, partial, rejected, request_add, request_cancel, request_modify, placed));
}