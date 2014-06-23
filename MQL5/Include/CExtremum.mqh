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
#define DEFAULT_TF_ATR PERIOD_H4
#define DEFAULT_PERIOD_ATR 30
#define DEFAULT_PERCENTAGE_ATR 1.0

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
 int _digits;
 ENUM_TIMEFRAMES _tf_period;
 //--параметры ATR дл€ difToNewExtremum-----
 ENUM_TIMEFRAMES _tf_ATR;
 int _period_ATR; 
 double _percentage_ATR;
 //-----------------------------------------
 SExtremum extremums[ARRAY_SIZE];
 
 public:
 CExtremum();
 CExtremum(string symbol, ENUM_TIMEFRAMES period, double percentage_ATR);
~CExtremum();

 int isExtremum(SExtremum& extr_array[], datetime start_pos_time = __DATETIME__,  bool now = true);
 int RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true);
 double AverageBar (ENUM_TIMEFRAMES tf, int period, datetime start_pos);
 SExtremum getExtr(int i);
 void PrintExtremums();
 int  ExtrCount();
 ENUM_TIMEFRAMES getPeriod() { return(_tf_period); }
 void SetSymbol(string symb) { _symbol = symb; }
 void SetPeriod(ENUM_TIMEFRAMES tf) { _tf_period = tf; }
 void SetDigits(int digits) { _digits = digits; }
};

CExtremum::CExtremum(void):
            _period_ATR (DEFAULT_PERIOD_ATR),
            _percentage_ATR (DEFAULT_PERCENTAGE_ATR)
           {
            _symbol = Symbol();
            _tf_period = Period();
            _tf_ATR = GetATR_TF(_tf_period);
            _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
           }

CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, double percentage_ATR):
            _symbol (symbol),
            _tf_period (period),
            _period_ATR (DEFAULT_PERIOD_ATR),
            _percentage_ATR (percentage_ATR)
            {
             _tf_ATR = GetATR_TF(_tf_period);
             _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
            }
CExtremum::~CExtremum()
           {
           }             

//-----------------------------------------------------------------

int CExtremum::isExtremum(SExtremum& extr_array [], datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum result1 = {0, -1};
 SExtremum result2 = {0, -1};
 int count = 0;
 MqlRates buffer[1];

 if(CopyRates(_symbol, _tf_period, start_pos_time, 1, buffer) < 1)
  PrintFormat("%s Rates buffer: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_tf_period), GetLastError(), Bars(_symbol, _tf_period), TimeToString(start_pos_time));
 double difToNewExtremum = AverageBar(_tf_ATR, _period_ATR, start_pos_time) * _percentage_ATR;
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
 
 if ((extremums[0].direction == 0 && (GreatDoubles(high, 2*difToNewExtremum, _digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction >  0 && (GreatDoubles(high, extremums[0].price, _digits)))
   ||(extremums[0].direction <  0 && (GreatDoubles(high, extremums[0].price + difToNewExtremum, _digits))))
 {
  result1.direction = 1;
  result1.price = high;
  result1.time = start_pos_time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), high);
 }
 
 if ((extremums[0].direction == 0 && (LessDoubles(low, 2*difToNewExtremum, _digits))) // ≈сли экстремумов еще нет и есть 2 шага от стартовой цены
   ||(extremums[0].direction <  0 && (LessDoubles(low, extremums[0].price, _digits)))
   ||(extremums[0].direction >  0 && (LessDoubles(low, extremums[0].price - difToNewExtremum, _digits))))
 {
  result2.direction = -1;
  result2.price = low;
  result2.time = start_pos_time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), low);
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


int CExtremum::RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum new_extr[2] = {{0, -1}, {0, -1}};
 int count_new_extrs = isExtremum(new_extr, start_pos_time, now);
 
 if(count_new_extrs > 0)
 {
  for(int i = 0; i < 2; i++)
  {
   if (new_extr[i].direction != 0)
   {
    if (new_extr[i].direction == extremums[0].direction) // если новый экстремум в том же напрвлении, что старый
    {
     extremums[0] = new_extr[i];
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

double CExtremum::AverageBar (ENUM_TIMEFRAMES tf, int period, datetime start_pos)
{
 double result = 0;
 MqlRates buffer_rates[];
 if(CopyRates(_symbol, tf, start_pos, period, buffer_rates) < 0)
 {
  PrintFormat("%s Ќе удалось загрузить цены дл€ самосто€тельного подсчета ATR. TF = %s. Error = %d", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), GetLastError());
 }
 int size = ArraySize(buffer_rates);
 
 for(int i = 0; i < size; i++)
 {
  result += MathAbs(buffer_rates[i].high - buffer_rates[i].low);
 }
 result = result/size;
 
 ArrayFree(buffer_rates);
 return(result);
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
  StringConcatenate(result, result, StringFormat("num%d = {%d %.05f %s ,(%.05f)}; ", i, extremums[i].direction, extremums[i].price, TimeToString(extremums[i].time), AverageBar(_tf_period, _period_ATR, extremums[i].time)*_percentage_ATR));
 }
 PrintFormat("%s %s", __FUNCTION__, result);
}

ENUM_TIMEFRAMES GetATR_TF(ENUM_TIMEFRAMES tf)
{
 ENUM_TIMEFRAMES result = DEFAULT_TF_ATR;
 if(tf >= DEFAULT_TF_ATR) result = tf;
 
 PrintFormat("TIMEFRAME FOR ATR %s", EnumToString((ENUM_TIMEFRAMES)result));
 return(result);
}