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
 int _period_ATR_channel;
 double _percentageATR_channel;
 
 public:
 CLevel(string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES tf_ATR, double percentageATR_price, int period_ATR_channel, double percentageATR_channel);
~CLevel();

 void RecountLevel(datetime start_pos_time = __DATETIME__, bool now = true);
 SLevel getLevel(int i);
};

CLevel::CLevel(string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES tf_ATR, double percentageATR_price, int period_ATR_channel, double percentageATR_channel):
               _period_ATR_channel (period_ATR_channel),
               _percentageATR_channel (percentageATR_channel)
               {
                _symbol = symbol;
                _tf_period = tf;
                _tf_ATR = tf_ATR;
                _period_ATR = ATR_PERIOD;
                _percentage_ATR = percentageATR_price;
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
               }
CLevel::~CLevel()
                {
                  
                }             

//-----------------------------------------------------------------

void CLevel::RecountLevel(datetime start_pos_time = __DATETIME__, bool now = true)
{
 int count_new_extrs = RecountExtremum(start_pos_time, now);
 double level_channel = (AverageBar(_tf_period, _period_ATR_channel, start_pos_time) * _percentageATR_channel)/2;
 
 if(count_new_extrs == 1)               //в случае когда появился один экстремум на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 1; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[0] = level_channel;
 }
 
 if(count_new_extrs == 2)                //в случае когда появилось два экстремума на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 2; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[1] = level_channel;
  channel[0] = level_channel;
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