//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CExtremum.mqh>
#include <CompareDoubles.mqh>

#define ATR_PERIOD 30

struct SLevel
{
 SExtremum extr;
 double channel;
};

class CLevel: public CExtremum
{
 private:
 double channel[ARRAY_SIZE];
 
 ENUM_TIMEFRAMES _period_ATR;
 double _percentageATR_price;
 double _percentageATR_channel;
 int handleATR_channel;
 int handleATR_price;
 
 public:
 CLevel(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel);
~CLevel();

 void RecountLevel(datetime start_index_time = __DATETIME__, bool now = true);
 SLevel getLevel(int i);
};

CLevel::CLevel(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel):
               _period_ATR (period_ATR),
               _percentageATR_price (percentageATR_price),
               _percentageATR_channel (percentageATR_channel)
               {
                _symbol = symbol;
                _period = period;
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
                handleATR_channel = iATR(_symbol, _period, ATRperiod_channel);
                handleATR_price = iATR(_symbol, _period_ATR, ATR_PERIOD);              
                if(handleATR_channel == INVALID_HANDLE || handleATR_price == INVALID_HANDLE) Alert("Invalid handle ATR.");
               }
CLevel::~CLevel()
                {
                 IndicatorRelease(handleATR_channel);
                 IndicatorRelease(handleATR_price);
                }             

//-----------------------------------------------------------------

void CLevel::RecountLevel(datetime start_index_time = __DATETIME__, bool now = true)
{
 double difToNewExtremum = 1;
 double buffer_ATR_channel[1];
 
 //CopyBuffer
 int count_new_extrs = RecountExtremum(difToNewExtremum, start_index_time, now);
 if(count_new_extrs == 1)               //в случае когда появился один экстремум на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 1; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[0] = (buffer_ATR_channel[0]*_percentageATR_channel)/2;
 }
 
 if(count_new_extrs == 2)                //в случае когда появилось два экстремума на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 2; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[1] = (buffer_ATR_channel[0]*_percentageATR_channel)/2;
  channel[0] = (buffer_ATR_channel[0]*_percentageATR_channel)/2;
 }       
}


SLevel CLevel::getLevel(int i)
{
 SLevel result = {{0, -1}, 0};
 if(i < 0 || i >= ARRAY_SIZE) 
  return(result);
  
 result.extr = extremums[i];
 result.channel = channel[i];
 return(result);
}