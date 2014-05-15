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
 double channal[ARRAY_SIZE];
 
 ENUM_TIMEFRAMES _period_ATR;
 double _percentageATR_price;
 double _percentageATR_channel;
 int handleATR_channel;
 int handleATR_price;
 
 public:
 CLevel(string symbol, ENUM_TIMEFRAMES period);
~CLevel();

 void RecountLevel(bool now = true, datetime start_index_time = __DATETIME__);
 SLevel getLevel(int i);
};

CLevel::CLevel(string symbol, ENUM_TIMEFRAMES period)//:
               //_period_ATR (period_ATR),
               //_percentageATR_price (percentageATR_price),
               //_percentageATR_channel (percentageATR_channel)
               {
                _symbol = symbol;
                _period = period;
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);

                //handleATR_channel = iATR(_symbol, _period, ATRperiod_channel);
                //handleATR_price = iATR(_symbol, _period_ATR, ATR_PERIOD);              
                //if(handleATR_channel == INVALID_HANDLE || handleATR_price == INVALID_HANDLE) Alert("Invalid handle ATR.");
               }
CLevel::~CLevel()
                {
                 IndicatorRelease(handleATR_channel);
                 IndicatorRelease(handleATR_price);
                }             

//-----------------------------------------------------------------

void CLevel::RecountLevel(bool now = true, datetime start_index_time = __DATETIME__)
{
 
}


SLevel CLevel::getLevel(int i)
{
 SLevel result = {{0, -1}, 0};
 return(result);
}