//+------------------------------------------------------------------+
//|                                    test_CHistoryTradeManager.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

//CROSS EMA
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 

#include <UGA/CHistoryTradeManager.mqh>
#include <CompareDoubles.mqh>

input datetime start_time = D'2013.08.01 00:00';
input datetime stop_time =  D'2013.09.01 00:00';
input ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
input int slow_period = 26;
input int fast_period = 12;

CHistoryTradeManager manager(Symbol(), timeframe, start_time, stop_time);
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
 datetime buffer_date[];
 double buffer_close[];
 double buffer_EMAfast[];
 double buffer_EMAslow[];
 double buffer_EMA3[];
 int handleEMAfast = iMA(Symbol(), timeframe, fast_period, 0, MODE_EMA, PRICE_CLOSE);
 int handleEMAslow = iMA(Symbol(), timeframe, slow_period, 0, MODE_EMA, PRICE_CLOSE);
 int handleEMA3    = iMA(Symbol(), timeframe,           3, 0, MODE_EMA, PRICE_CLOSE); 
 int copiedDate    = -1;
 int copiedClose   = -1;
 int copiedEMAfast = -1;
 int copiedEMAslow = -1;
 int copiedEMA3    = -1;
 int depth = Bars(Symbol(), timeframe, start_time, stop_time);
 for(int attempts = 0; attempts < 25 && copiedDate   < 0
                                     && copiedClose  < 0
                                     && copiedEMAfast  < 0
                                     && copiedEMAslow < 0
                                     && copiedEMA3   < 0; attempts++)
 {
  copiedDate   =  CopyTime(Symbol(), timeframe, start_time, stop_time, buffer_date);
  copiedClose  = CopyClose(Symbol(), timeframe, start_time, stop_time, buffer_close);
  copiedEMAfast = CopyBuffer(handleEMAfast, 0, start_time, stop_time, buffer_EMAfast);
  copiedEMAslow = CopyBuffer(handleEMAslow, 0, start_time, stop_time, buffer_EMAslow);
  copiedEMA3    = CopyBuffer(   handleEMA3, 0, start_time, stop_time, buffer_EMA3);
 }
 if(copiedDate  != depth || copiedClose  != depth ||
    copiedEMAfast != depth || copiedEMAslow != depth || copiedEMA3 != depth)
 {
  Alert("Не удалось скопировать буфер.(", depth, ") (", GetLastError(), ")");
  return;
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s BEGIN TIME %s", __FUNCTION__, TimeToString(buffer_date[0])));
 log_file.Write(LOG_DEBUG, StringFormat("%s END TIME %s", __FUNCTION__, TimeToString(buffer_date[depth-1])));
 for(int i = 1; i < depth; i++)
 {
  if(GreatDoubles(buffer_EMAslow[i-1], buffer_EMAfast[i-1]) && GreatDoubles(buffer_EMAfast[i], buffer_EMAslow[i]) && GreatDoubles( buffer_EMA3[i], buffer_close[i]))
  {
   manager.OpenPosition(BUY, i);
   log_file.Write(LOG_DEBUG, StringFormat("%s open position BUY %s", __FUNCTION__, TimeToString(buffer_date[i])));
  }
  if(GreatDoubles(buffer_EMAfast[i-1], buffer_EMAslow[i-1]) && GreatDoubles(buffer_EMAslow[i], buffer_EMAfast[i]) && GreatDoubles(buffer_close[i],  buffer_EMA3[i]))
  {
   manager.OpenPosition(SELL, i);
   log_file.Write(LOG_DEBUG, StringFormat("%s open position SELL %s", __FUNCTION__, TimeToString(buffer_date[i])));
  }
 }
 ArrayFree(buffer_date);
}
//+------------------------------------------------------------------+
//   log_file.Write(LOG_DEBUG, StringFormat("%s BUY %s", __FUNCTION__, TimeToString(buffer_date[i])));
