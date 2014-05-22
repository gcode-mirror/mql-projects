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
 
 ENUM_TIMEFRAMES _period_ATR_price;
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
               _period_ATR_price (period_ATR),
               _percentageATR_price (percentageATR_price),
               _percentageATR_channel (percentageATR_channel)
               {
                _symbol = symbol;
                _period = period;
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
                handleATR_channel = iATR(_symbol, _period, ATRperiod_channel);
                handleATR_price = iATR(_symbol, _period_ATR_price, ATR_PERIOD);              
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
 double difToNewExtremum = 50*Point();
 double buffer_ATR_channel[1] = {0};
 double buffer_ATR_price[1] = {0};
 
 CopyBufferUpdated(handleATR_channel, start_index_time, 1, buffer_ATR_channel, "ATR для канала");
 CopyBufferUpdated(handleATR_price, start_index_time, 1, buffer_ATR_price, "ATR для цены");
 
 difToNewExtremum = buffer_ATR_price[0]*_percentageATR_price;
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

void CopyBufferUpdated(int handle, datetime start_index_time, int count, double& buffer[], string discription)
{
 int error = 0;
 int copied = CopyBuffer(handle, 0, start_index_time, count, buffer);
 
 if(copied < count)
 {
  error = GetLastError();
  if(error == 4806)
  {
   for(int i =0; i < 1000; i++)
   {
    if(BarsCalculated(handle) > 0)
    {
     PrintFormat("%s Была ошибка 4806. Вроде справились. Загружено для %s %d", __FUNCTION__, discription, BarsCalculated(handle));
     break;
    }
   }
   copied = CopyBuffer(handle, 0, start_index_time, count, buffer);
   error = GetLastError();
  }
  
  if(copied < count)
   PrintFormat("%s Bad news. У меня нет %s. Time = %s; Error = %d", __FUNCTION__, discription, TimeToString(start_index_time), error);
  
  ResetLastError();
 }
}