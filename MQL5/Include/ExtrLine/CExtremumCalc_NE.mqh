//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>

#define ATR_PERIOD 30
#define ATR_TIMEFRAME PERIOD_H4

struct SExtremum
{
 int direction;
 double price;
 double channel;
};

class CExtremumCalc
{
 private:
 string _symbol;
 ENUM_TIMEFRAMES _period;
 int digits;
 double _startDayPrice;
 double difToNewExtremum;
 SExtremum  num0,
            num1,
            num2;
 int _depth;
 double _percentageATR_price;
 double _percentageATR_channel;
 int handleATR_channel;
 int handleATR_price;
 
 public:
 CExtremumCalc(string symbol, ENUM_TIMEFRAMES period,  double percentageATR_price, int ATRperiod_channel, double percentageATR_channel);
~CExtremumCalc();
 SExtremum isExtremum(bool now = true, datetime start_index_time = __DATETIME__);
 SExtremum getExtr(int i);
 ENUM_TIMEFRAMES getPeriod() { return(_period); } 
 void CalcThreeExtrOnHistory(datetime start_index_time = __DATETIME__);
 void SetPeriod(ENUM_TIMEFRAMES tf) { _period = tf; }
 void RecountExtremum(bool now = true, datetime start_index_time = __DATETIME__);
 bool isThreeExtrExist();
 bool isATRCalculated();
};

CExtremumCalc::CExtremumCalc(string symbol, ENUM_TIMEFRAMES period, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel):
               _symbol (symbol),
               _period (period),
               _percentageATR_price (percentageATR_price),
               _percentageATR_channel (percentageATR_channel)
               {
                digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
                MqlRates buffer[1];
                CopyRates(_symbol, _period, 0, 1, buffer); // _depth?!
                _startDayPrice = buffer[0].close;
                handleATR_channel = iATR(_symbol,       _period, ATRperiod_channel);
                handleATR_price   = iATR(_symbol, ATR_TIMEFRAME, ATR_PERIOD);              
                if(handleATR_channel == INVALID_HANDLE || handleATR_price == INVALID_HANDLE) Alert("Invalid handle ATR.");
               }
CExtremumCalc::~CExtremumCalc()
                {
                 IndicatorRelease(handleATR_channel);
                 IndicatorRelease(handleATR_price);
                }             

SExtremum CExtremumCalc::isExtremum(bool now = true, datetime start_index_time = __DATETIME__)
{
 SExtremum result = {0, -1};
 MqlRates buffer[1];
 double ATR_channel[1];
 double ATR_price[1];

 
 if(CopyRates(_symbol, _period, start_index_time, 1, buffer) < 1)
  PrintFormat("Rates buffer: error = %d, calculated = %d, start_index = %s", GetLastError(), Bars(_symbol, _period), TimeToString(start_index_time));
 if(CopyBuffer(handleATR_channel, 0, start_index_time, 1, ATR_channel) < 1)
  PrintFormat("ATR channel: error = %d, calculated = %d, start_index = %s", GetLastError(), BarsCalculated(handleATR_channel), TimeToString(start_index_time));
 if(CopyBuffer(handleATR_price, 0, start_index_time, 1, ATR_price) < 1)
  PrintFormat("ATR price: error = %d, calculated = %d, start_index = %s", GetLastError(), BarsCalculated(handleATR_price), TimeToString(start_index_time)); 
 difToNewExtremum = ATR_price[0]*_percentageATR_price;
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
 
 if ((num0.direction == 0 && (GreatDoubles(high, _startDayPrice + 2*difToNewExtremum, digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(num0.direction >  0 && (GreatDoubles(high, num0.price, digits)))
   ||(num0.direction <  0 && (GreatDoubles(high, num0.price + difToNewExtremum, digits))))
 {
  result.direction = 1;
  result.price = high;
  result.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s startday price = %0.5f; difToNewExtremum = %0.5f, max %s %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_period), _startDayPrice, difToNewExtremum, TimeToString(start_index_time), high);
 }
 
 if ((num0.direction == 0 && (LessDoubles(low, _startDayPrice - 2*difToNewExtremum, digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(num0.direction <  0 && (LessDoubles(low, num0.price, digits)))
   ||(num0.direction >  0 && (LessDoubles(low, num0.price - difToNewExtremum, digits))))
 {
  result.direction = -1;
  result.price = low;
  result.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s startday price = %0.5f; difToNewExtremum = %0.5f, min %s  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), _startDayPrice, difToNewExtremum, TimeToString(start_index_time), low);
 }
 
 //PrintFormat("%s %s startday price = %0.5f; difToNewExtremum = %0.5f, %s  %0.5f %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), _startDayPrice, difToNewExtremum, TimeToString(start_index_time), low, high);
 return(result);
}


void CExtremumCalc::RecountExtremum(bool now = true, datetime start_index_time = __DATETIME__)
{
 SExtremum current_bar = {0, -1};
 
 current_bar = isExtremum(now, start_index_time); 
 if (current_bar.direction != 0)
 {
  if (current_bar.direction == num0.direction) // если новый экстремум в том же напрвлении, что старый
  {
   num0.price = current_bar.price;
  }
  else
  {
   num2 = num1;
   num1 = num0;
   num0 = current_bar;
  }       
 }
}

void CExtremumCalc::CalcThreeExtrOnHistory(datetime start_index_time = __DATETIME__)
{
 SExtremum current_bar = {0, -1};
 for(int i = 1; i < 5;)
 {
  current_bar = isExtremum(false, start_index_time); 
  if (current_bar.direction != 0)
  {
   if(i == 4 && current_bar.direction != num0.direction) break;
   if(current_bar.direction == num0.direction) // если новый экстремум в том же напрвлении, что старый
   {
    num0.price = current_bar.price;
   }
   else
   {
    num2 = num1;
    num1 = num0;
    num0 = current_bar;
    i++;    
   }   
  }
  start_index_time -= PeriodSeconds(_period);
 }
 //переворот крайних экстремумов так как шли справа налево, а не по привычному слева направо
 current_bar = num0;
 num0 = num2;
 num2 = current_bar;
// PrintFormat("%s END num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", TimeToString(start_index_time), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
}


bool CExtremumCalc::isThreeExtrExist()
{
 if(num0.direction != 0 && num1.direction != 0 && num2.direction != 0)
  return(true);
 return(false);
}

bool CExtremumCalc::isATRCalculated()
{
 if(BarsCalculated(handleATR_channel) >= 1 &&
    BarsCalculated(handleATR_price  ) >= 1)
  return(true);
 PrintFormat("%s %s . дл€ channel расчитано %d, дл€ price расчитано %d", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), BarsCalculated(handleATR_channel), BarsCalculated(handleATR_price  ));
 return(false);
}

SExtremum CExtremumCalc::getExtr(int i)
{
 SExtremum zero = {0, 0, 0};
 switch(i)
 {
 case(0):
  return num0;
 case(1):
  return num1;
 case(2):
  return num2;
 default:
  return zero;
 }
}

/*int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe_curr, ENUM_TIMEFRAMES timeframe_top, int current_bars)
{
  return ((current_bars*PeriodSeconds(timeframe_curr))/PeriodSeconds(timeframe_top));
}*/