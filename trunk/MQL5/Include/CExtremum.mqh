//+------------------------------------------------------------------+
//|                                                CExtremum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>

#define ARRAY_SIZE 10

struct SExtremum
{
 int direction;
 double price;
};

class CExtremum
{
 private:
 string _symbol;
 ENUM_TIMEFRAMES _period;
 int digits;
 double _startDayPrice;
 SExtremum extremums[ARRAY_SIZE];
 
 public:
 CExtremum(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel);
~CExtremum();

 bool isExtremum(SExtremum& extr_array[], double difToNewExtremum, datetime start_index_time = __DATETIME__,  bool now = true);
 void RecountExtremum(datetime start_index_time = __DATETIME__, bool now = true);
 SExtremum getExtr(int i);
 ENUM_TIMEFRAMES getPeriod() { return(_period); }
 void SetPeriod(ENUM_TIMEFRAMES tf) { _period = tf; }
 void SetStartDayPrice(double price) { _startDayPrice = price; }
 int howManyExtrExist();
};

CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel):
               _symbol (symbol),
               _period (period)
               {
                digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
                _startDayPrice = -1;
               }
CExtremum::~CExtremum()
                {
                }             

//-----------------------------------------------------------------

bool CExtremum::isExtremum(SExtremum& extr_array [], double difToNewExtremum, datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum result1 = {0, -1};
 SExtremum result2 = {0, -1};
 if(_startDayPrice == -1) { Alert(StringFormat("Вы забыли установить startDayPrice на %s таймфрейме!", EnumToString((ENUM_TIMEFRAMES)_period))); }
 MqlRates buffer[1];
 double ATR_channel[1];
 double ATR_price[1];

 
 if(CopyRates(_symbol, _period, start_pos_time, 1, buffer) < 1)
  PrintFormat("%s Rates buffer: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_period), GetLastError(), Bars(_symbol, _period), TimeToString(start_pos_time));
 //if(now) PrintFormat("Загружен бар %s", TimeToString(buffer[0].time));
  //return(result);
 double high = 0, low = 0;
 
 if (now)
 {
  high = buffer[0].close;
  low = buffer[0].close;
 }
 else
 {
  high = buffer[0].high;
  low = buffer[0].low;
 }
 
 if ((extremums[0].direction == 0 && (GreatDoubles(high, _startDayPrice + 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction >  0 && (GreatDoubles(high, extremums[0].price, digits)))
   ||(extremums[0].direction <  0 && (GreatDoubles(high, extremums[0].price + difToNewExtremum, digits))))
 {
  result1.direction = 1;
  result1.price = high;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), high);
 }
 
 if ((extremums[0].direction == 0 && (LessDoubles(low, _startDayPrice - 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction <  0 && (LessDoubles(low, extremums[0].price, digits)))
   ||(extremums[0].direction >  0 && (LessDoubles(low, extremums[0].price - difToNewExtremum, digits))))
 {
  result2.direction = -1;
  result2.price = low;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), low);
 }
 
 extr_array[0] = result1;
 extr_array[1] = result2;
  
 if(result1.price != 0 || result2.price != 0) return(true);
 return(false);
}


void CExtremum::RecountExtremum(datetime start_index_time = __DATETIME__, bool now = true)
{
 SExtremum new_extr[2] = {{0, -1}, {0, -1}};
 SExtremum current_bar = {0, -1};
 
 if(isExtremum(new_extr, now, start_index_time))
 {
  for(int i = 0; i < 2; i++)
  {
   current_bar = new_extr[i];
   if (current_bar.direction != 0)
   {
    if (current_bar.direction == extremums[0].direction) // если новый экстремум в том же напрвлении, что старый
    {
     extremums[0].price = current_bar.price;
    }
    else
    {
     for(int j = ARRAY_SIZE-1; j >= 1; j--)
     {
      extremums[j] = extremums[j-1];     
     }
     extremums[0] = current_bar;
    }       
   }
  }
 }
}

int CExtremum::howManyExtrExist(void)
{
 int count = 0;
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  if(extremums[i].direction != 0) count++;
 }
 return(count);
}

SExtremum CExtremum::getExtr(int i)
{
 SExtremum zero = {0, 0};
 if(i < 0 || i >= ARRAY_SIZE)
  return zero;
 return(extremums[i]);
}