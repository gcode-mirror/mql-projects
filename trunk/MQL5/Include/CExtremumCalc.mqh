//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>

enum DIRECTION
{
 ZERO, 
 MAX, 
 MIN
};

struct SExtremum
{
 DIRECTION direction;
 double price;
};

class CExtremumCalc
{
 private:
 SExtremum _extr_array[];
 int _last;
 int _epsilon;
 int _depth;
 
 public:
 CExtremumCalc();
 CExtremumCalc(int e, int depth);
~CExtremumCalc();
 SExtremum getExtr(int index);
 DIRECTION isExtremum(double a, double b, double c);
 void FillExtremumsArray(string symbol, ENUM_TIMEFRAMES tf);
 void SortByDirection();
 void SortByValue();
};
CExtremumCalc::CExtremumCalc():
               _epsilon (50),
               _depth (128),
               _last (-1)
               {
                ArrayResize(_extr_array, _depth);
                SExtremum zero = {ZERO, 0};
                for(int i = _depth-1; i > 0; i--)
                {
                 _extr_array[i] = zero;
                }
               }

CExtremumCalc::CExtremumCalc(int e,int depth):
               _epsilon (e),
               _depth (depth),
               _last (-1)
               {
                ArrayResize(_extr_array, _depth);
                SExtremum zero = {ZERO, 0};
                for(int i = _depth-1; i > 0; i--)
                {
                 _extr_array[i] = zero;
                }
               }
CExtremumCalc::~CExtremumCalc()
                {
                 ArrayFree(_extr_array);
                }             

DIRECTION CExtremumCalc::isExtremum(double a,double b,double c)
{
 if(_last == -1 || GreatDoubles(MathAbs(b - _extr_array[_last].price), _epsilon*SymbolInfoDouble(Symbol(), SYMBOL_POINT)))
 {
  if(GreatDoubles(b, a) && GreatDoubles(b, c))
  {
   return(MAX);
  }
  else if(LessDoubles(b, a) && LessDoubles(b, c))
       {
        return(MIN);
       }
 }
 return(ZERO);
}


void CExtremumCalc::FillExtremumsArray(string symbol, ENUM_TIMEFRAMES tf)
{
 double price [];
 datetime time [];
 if (CopyClose(symbol, tf, 0, _depth + 1, price) != _depth + 1) {Alert ("Не удалось скопировать фубер цен");return;}
 CopyTime(symbol, tf, 0, _depth+1, time);
 if(!ArrayGetAsSeries(price)) ArraySetAsSeries(price, true);
 if(!ArrayGetAsSeries(_extr_array)) ArraySetAsSeries(_extr_array, true);
 if(!ArrayGetAsSeries(time)) ArraySetAsSeries(time, true);
 SExtremum zero = {ZERO, 0};
 _last = -1;
 for(int i = _depth; i > 1; i--)
 {  
  _extr_array[i].direction = isExtremum(price[i-1], price[i], price[i+1]);
  //Print(StringFormat("i = %d; price[i-1] = %f, price[i] = %f, price[i+1] = %f, dir = %s", i,  price[i-1], price[i], price[i+1], EnumToString((DIRECTION)_extr_array[i].direction)));
  if(_extr_array[i].direction != ZERO)
  {
   Alert( i, " ", _last, " ", time[i], " ", EnumToString((DIRECTION)_extr_array[i].direction));
   if(_last == -1)
   {
    _extr_array[i].price = price[i];
    _last = i;
    continue;
   }
   //if(_extr_array[_last].direction != _extr_array[i].direction)
   //{
    _extr_array[i].price = price[i];
    _last = i;
   //}
   /*else
   {
    if(_extr_array[i].direction == MAX)
    {
     if(_extr_array[i].price > _extr_array[_last].price)
     {
      _extr_array[_last] = zero;
      _last = i;
     }
     else
     {
      _extr_array[i] = zero;
     }
    }
    if(_extr_array[i].direction == MIN)
    {
     if(_extr_array[i].price < _extr_array[_last].price)
     {
      _extr_array[_last] = zero;
      _last = i;
     }
     else
     {
      _extr_array[i] = zero;
     }
    }   
   }*/  
  }
 }
 ArrayFree(price);
 ArrayFree(time);
}

/*void CExtremumCalc::SortByDirection()
{
 int prev_extr = -1;
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 for(int i = _depth - 1; i >= 0; i--)
 {
  if(_extr_array[i].price != 0)
  {
   if(prev_extr == -1)
   {
    prev_extr = i;
    continue;
   }
   else
   {
    if(_extr_array[i].direction != _extr_array[prev_extr].direction)
    {
     prev_extr = i;
     continue;
    }
    else
    {
     if(_extr_array[i].direction == MAX)
     {
      if(_extr_array[i].price > _extr_array[prev_extr].price)
      {
       _extr_array[prev_extr].direction = ZERO;
       _extr_array[prev_extr].price = 0;       
       prev_extr = i;
      }
      else
      {
       _extr_array[i].direction = ZERO;
       _extr_array[i].price = 0;
      }
     }
     if(_extr_array[i].direction == MIN)
     {
      if(_extr_array[i].price < _extr_array[prev_extr].price)
      {
       _extr_array[prev_extr].direction = ZERO;
       _extr_array[prev_extr].price = 0;
       prev_extr = i;
      }
      else
      {
       _extr_array[i].direction = ZERO;
       _extr_array[i].price = 0;
      }
     }
    }
   }
  }
 }
}

void CExtremumCalc::SortByValue(void)
{
 int prev_extr = -1;
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 for(int i = _depth - 1; i >= 0; i--)
 {
  if(_extr_array[i].price != 0)
  {
   if(prev_extr == -1)
   {
    prev_extr = i;
    continue;
   }
   else
   {
    if(MathAbs(_extr_array[i].price - _extr_array[prev_extr].price) <= _epsilon*point)
    {
     _extr_array[i].direction = ZERO;
     _extr_array[i].price = 0;
    }
    else
     prev_extr = i;
   }
  }
 } 
}*/

SExtremum CExtremumCalc::getExtr(int index)
{
 if(0 <= index && index < _depth)
  return _extr_array[index];
 else
 {
  Alert(__FUNCTION__, " bad index = ", index);
  SExtremum error = {ZERO, -1};
  return error;
 }
}