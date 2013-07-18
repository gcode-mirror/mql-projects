//+------------------------------------------------------------------+
//|                                         divergenceStochastic.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>

#define DEPTH_STOC 10

bool divergenceSTOC(int handleSTOC, const string symbol, ENUM_TIMEFRAMES timeframe, int top_level, int startIndex = 0)
{
 double iSTOC_buf[DEPTH_STOC];
 double iHigh_buf[DEPTH_STOC];
 datetime date_buf[DEPTH_STOC];
 int index_STOC_global_max;
 int index_Price_global_max;

 Sleep(5000);
 int sizeSTOC = CopyBuffer(handleSTOC, 0, startIndex, DEPTH_STOC, iSTOC_buf);
 int sizeHigh = CopyHigh(symbol, timeframe, startIndex, DEPTH_STOC, iHigh_buf);
 int sizeDate = CopyTime(symbol, timeframe, startIndex, DEPTH_STOC, date_buf);
 if (sizeSTOC < 0 || sizeHigh < 0/* || sizeDate < 0*/)
 {
   int err = GetLastError();
   Alert(__FUNCTION__, ": Не удалось скопировать буффер. Error = ", err);
   return(false);
 }
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_STOC_global_max = ArrayMaximum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 if ((DEPTH_STOC-2) <= index_Price_global_max && index_Price_global_max < DEPTH_STOC)       //самая высокая цены находится в последних 2 барах
 {
  if (isSTOCExtremum(handleSTOC, (DEPTH_STOC-3)) && iSTOC_buf[index_STOC_global_max] > top_level)
  { 
   for(int i = index_STOC_global_max+2; i < DEPTH_STOC; i++)
   {
    if(isSTOCExtremum(handleSTOC, ((DEPTH_STOC-1)-i)) == 1 && iSTOC_buf[i] < top_level)
    {
     Alert("BEGIN = ", date_buf[0]);
     Alert("global max = ", index_STOC_global_max, "; time = ", date_buf[index_STOC_global_max]);
     Alert("extremum = ", i, "; time = ", date_buf[i]); 
     Alert("Найдено расхождение на стохастике.");
     Alert("END = ", date_buf[DEPTH_STOC-1]);
     return true;
    }
   }
  }
 }
    
 return(false); 
}

/////-------------------------------
/////-------------------------------
int isSTOCExtremum(int handleSTOC, int startIndex = 0, int precision = 6, bool LOG = false)
{
 double iSTOC_buf[4];
 Sleep(1000);
 if (CopyBuffer(handleSTOC, 0, startIndex, 4, iSTOC_buf) < 0)
 {
  Alert (__FUNCTION__, "Не удалось загрузить буфер индикатора Stochastic");
  return(0);
 }

 if ( GreatDoubles(iSTOC_buf[1], iSTOC_buf[0], precision) && GreatDoubles(iSTOC_buf[1], iSTOC_buf[2], precision) )
 {
  return(1);
 }
 else if ( LessDoubles(iSTOC_buf[1], iSTOC_buf[0], precision) && LessDoubles(iSTOC_buf[1], iSTOC_buf[2], precision) ) 
      {
       return(-1);     
      }
 //if (LOG) Alert("Не найдено экстремумов");
 return(0);
}