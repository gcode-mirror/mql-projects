//+------------------------------------------------------------------+
//|                                             testOrderStateII.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>
#include <CLog.mqh>

MqlTradeRequest t_request;
MqlTradeResult t_result;
datetime start_history;
static CisNewBar bar4H(PERIOD_H4);
static CisNewBar bar1H(PERIOD_H1);
int count = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 start_history = TimeCurrent();
 bar4H.isNewBar();
 bar1H.isNewBar();
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
 if(bar4H.isNewBar() > 0)
 {
  CreateRequest();
  OrderSend(t_request, t_result);
  count++;
 }
 
 if(bar1H.isNewBar() > 0)
 {
  PrintHistoryState();
  PrintHistoryInfo();
 }
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
 
}
//+------------------------------------------------------------------+
void CreateRequest()
{
 ZeroMemory(t_request);
 ZeroMemory(t_result);
 t_request.action       = TRADE_ACTION_PENDING;
 t_request.magic        = 1122;
 t_request.symbol       = Symbol();
 t_request.volume       = 1.0;
 t_request.price        = SymbolInfoDouble(Symbol(), SYMBOL_ASK) + 1000*Point();
 t_request.type         = ORDER_TYPE_SELL_LIMIT;
 t_request.type_filling = ORDER_FILLING_FOK;
 t_request.type_time    = ORDER_TIME_SPECIFIED;
 t_request.expiration   = TimeCurrent() + PeriodSeconds(PERIOD_H2);
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

void PrintHistoryInfo()
{
 HistorySelect(start_history, TimeCurrent());
 int total = HistoryOrdersTotal();
 if(total > 10)
 {
  long state;
  for(int i = total-1; i >= 0; i--)
  {
   if(HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_STATE, state))
    log_file.Write(LOG_DEBUG, StringFormat("%d %d", i, HistoryOrderGetTicket(i)));
   else
    log_file.Write(LOG_DEBUG, "BAD");
  }
 }
}