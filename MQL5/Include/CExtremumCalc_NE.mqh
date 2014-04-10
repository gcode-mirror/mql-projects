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
 SExtremum isExtremum(int start_index);
 SExtremum getExtr(int i);
 void RecountExtremum(int start_index = 0);
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
                //PrintFormat("%s Для handleATR_channel удалось постчитать только %d баров", EnumToString((ENUM_TIMEFRAMES)_period), BarsCalculated(handleATR_channel));
                //PrintFormat("%s Для handleATR_price удалось постчитать только %d баров", EnumToString((ENUM_TIMEFRAMES)_period), BarsCalculated(handleATR_price));
               }
CExtremumCalc::~CExtremumCalc()
                {
                 IndicatorRelease(handleATR_channel);
                 IndicatorRelease(handleATR_price);
                }             

SExtremum CExtremumCalc::isExtremum(int start_index)
{
 SExtremum result = {0,0};
 MqlRates buffer[1];
 double ATR_channel[1];
 double ATR_price[1];
 
 if(CopyRates(_symbol, _period, start_index, 1, buffer) < 1)
  PrintFormat("Rates buffer: error = %d, calculated = %d, start_index = %d", GetLastError(), Bars(_symbol, _period), start_index);
 if(CopyBuffer(handleATR_channel, 0, start_index, 1, ATR_channel) < 1)
  PrintFormat("ATR channel: error = %d, calculated = %d, start_index = %d=", GetLastError(), BarsCalculated(handleATR_channel), start_index);
 if(CopyBuffer(handleATR_price, 0, GetNumberOfTopBarsInCurrentBars(_period, ATR_TIMEFRAME,start_index), 1, ATR_price) < 1)
  PrintFormat("ATR price: error = %d, calculated = %d, start_index = %d", GetLastError(), BarsCalculated(handleATR_price), start_index); 
 difToNewExtremum = ATR_price[0]*_percentageATR_price;
 double high = 0, low = 0;
 
 if (start_index == 0)
 {
  high = buffer[0].close;
  low = buffer[0].close;
 }
 else
 {
  high = buffer[0].high;
  low = buffer[0].low;
 }
 
 if ((num0.direction == 0 && (GreatDoubles(high, _startDayPrice + 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   ||(num0.direction >  0 && (GreatDoubles(high, num0.price, digits)))
   ||(num0.direction <  0 && (GreatDoubles(high, num0.price + difToNewExtremum, digits))))
 {
  result.direction = 1;
  result.price = high;
  result.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s startday price = %0.5f; difToNewExtremum = %0.5f, max %d %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_period), _startDayPrice, difToNewExtremum, start_index, high);
 }
 
 if ((num0.direction == 0 && (LessDoubles(low, _startDayPrice - 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   ||(num0.direction <  0 && (LessDoubles(low, num0.price, digits)))
   ||(num0.direction >  0 && (LessDoubles(low, num0.price - difToNewExtremum, digits))))
 {
  result.direction = -1;
  result.price = low;
  result.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s startday price = %0.5f; difToNewExtremum = %0.5f, min %d %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), _startDayPrice, difToNewExtremum, start_index, low);
 }
 
 return(result);
}


void CExtremumCalc::RecountExtremum(int start_index = 0)
{
 SExtremum current_bar = {0, -1};
 
 current_bar = isExtremum(start_index); 
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
 PrintFormat("%s %s . для channel расчитано %d, для price расчитано %d", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), BarsCalculated(handleATR_channel), BarsCalculated(handleATR_price  ));
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

int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe_curr, ENUM_TIMEFRAMES timeframe_top, int current_bars)
{
  return ((current_bars*PeriodSeconds(timeframe_curr))/PeriodSeconds(timeframe_top));
}