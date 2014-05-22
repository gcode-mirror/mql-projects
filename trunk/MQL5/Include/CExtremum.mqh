//+------------------------------------------------------------------+
//|                                                CExtremum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>
#include <Lib CisNewBarDD.mqh>

#define ARRAY_SIZE 4

struct SExtremum
{
 int direction;
 double price;
 datetime time;
};

class CExtremum
{
 protected:
 string _symbol;
 ENUM_TIMEFRAMES _period; 
 int _digits;
 SExtremum extremums[ARRAY_SIZE];
 
 public:
 CExtremum() {_symbol = Symbol(); _period = Period();};
 CExtremum(string symbol, ENUM_TIMEFRAMES period);
~CExtremum();

 int isExtremum(SExtremum& extr_array[], double difToNewExtremum, datetime start_pos_time = __DATETIME__,  bool now = true);
 int RecountExtremum(double difToNewExtremum, datetime start_pos_time = __DATETIME__, bool now = true);
 SExtremum getExtr(int i);
 ENUM_TIMEFRAMES getPeriod() { return(_period); }
 void SetSymbol(string symb) { _symbol = symb; }
 void SetPeriod(ENUM_TIMEFRAMES tf) { _period = tf; }
 void SetDigits(int digits) { _digits = digits; }
 void PrintExtremums();
 int ExtrCount();
};

CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period):
               _symbol (symbol),
               _period (period)
               {
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
               }
CExtremum::~CExtremum()
                {
                }             

//-----------------------------------------------------------------

int CExtremum::isExtremum(SExtremum& extr_array [], double difToNewExtremum, datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum result1 = {0, -1};
 SExtremum result2 = {0, -1};
 int count = 0;
 MqlRates buffer[1];

 
 if(CopyRates(_symbol, _period, start_pos_time, 1, buffer) < 1)
  PrintFormat("%s Rates buffer: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_period), GetLastError(), Bars(_symbol, _period), TimeToString(start_pos_time));
 //if(now) PrintFormat("«агружен бар %s", TimeToString(buffer[0].time));
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
 
 //PrintFormat("%s MAX dif = %.05f, time = %s, price = %.05f; extr[0].direction %d; extr[0].price = %.05f RESULT = %.05f", __FUNCTION__, difToNewExtremum, TimeToString(start_pos_time), high, extremums[0].direction, extremums[0].price, GreatDoubles(high, extremums[0].price));
 //PrintExtremums();
 if ((extremums[0].direction == 0 && (GreatDoubles(high, 2*difToNewExtremum, _digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction >  0 && (GreatDoubles(high, extremums[0].price, _digits)))
   ||(extremums[0].direction <  0 && (GreatDoubles(high, extremums[0].price + difToNewExtremum, _digits))))
 {
  result1.direction = 1;
  result1.price = high;
  result1.time = start_pos_time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), high);
 }
 
  //PrintFormat("%s MIN dif = %.05f, time = %s, price = %.05f / %.05f; direction %d; extr[0].price = %.05f/%.05f", __FUNCTION__, difToNewExtremum, TimeToString(start_pos_time), high, low, extremums[0].direction, extremums[0].price, extremums[0].price-difToNewExtremum);
 if ((extremums[0].direction == 0 && (LessDoubles(low, 2*difToNewExtremum, _digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction <  0 && (LessDoubles(low, extremums[0].price, _digits)))
   ||(extremums[0].direction >  0 && (LessDoubles(low, extremums[0].price - difToNewExtremum, _digits))))
 {
  result2.direction = -1;
  result2.price = low;
  result2.time = start_pos_time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), low);
 }
 
 if(buffer[0].close <= buffer[0].open) //если close ниже open то сначала пишем high потом low
 {
  extr_array[0] = result1;
  extr_array[1] = result2;
 }
 else                                  //если close выше open то сначала пишем low потом high
 {
  extr_array[0] = result2;
  extr_array[1] = result1;
 }  
 
 return(count);
}


int CExtremum::RecountExtremum(double difToNewExtremum, datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum new_extr[2] = {{0, -1}, {0, -1}};
 int count_new_extrs = isExtremum(new_extr, difToNewExtremum, start_pos_time, now);
 
 if(count_new_extrs > 0)
 {
  for(int i = 0; i < 2; i++)
  {
   if (new_extr[i].direction != 0)
   {
    if (new_extr[i].direction == extremums[0].direction) // если новый экстремум в том же напрвлении, что старый
    {
     extremums[0].price = new_extr[i].price;
    }
    else
    {
     for(int j = ARRAY_SIZE-1; j >= 1; j--)
     {
      extremums[j] = extremums[j-1];     
     }
     extremums[0] = new_extr[i];
    }       
   }
  }
 }
 return(count_new_extrs);
}

int CExtremum::ExtrCount()
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

void CExtremum::PrintExtremums()
{
 string result = "";
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  StringConcatenate(result, result, StringFormat("num%d = {%d %.05f %s}; ", i, extremums[i].direction, extremums[i].price, TimeToString(extremums[i].time)));
 }
 PrintFormat("%s %s", __FUNCTION__, result);
}