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

struct CExtremum
{
 public:
 DIRECTION direction;
 double price;
};

class CExtremumCalc
{
 private:
 CExtremum _extr_array[];
 int _e;
 int _depth;
 
 public:
 CExtremumCalc();
 CExtremumCalc(int e, int depth);
~CExtremumCalc();
 CExtremum getExtr(int index);
 DIRECTION isExtremum(double a, double b, double c);
 void FillExtremumsArray(const double& price[]);
 void SortByDirection();
 void SortByValue();
};
CExtremumCalc::CExtremumCalc():
               _e (50),
               _depth (128)
               {
                ArrayResize(_extr_array, _depth);
                ArraySetAsSeries(_extr_array, true);
               }

CExtremumCalc::CExtremumCalc(int e,int depth):
               _e (e),
               _depth (depth)
               {
                ArrayResize(_extr_array, _depth);
                ArraySetAsSeries(_extr_array, true);
               }
CExtremumCalc::~CExtremumCalc()
                {
                 ArrayFree(_extr_array);
                }             

DIRECTION CExtremumCalc::isExtremum(double a, double b, double c)
{
 if(GreatDoubles(b, a) && GreatDoubles(b, c))
 {
  return(MAX);
 }
 else if(LessDoubles(b, a) && LessDoubles(b, c))
      {
       return(MIN);
      }
 return(ZERO);
}

void CExtremumCalc::FillExtremumsArray(const double &price[])
{
 if(ArrayGetAsSeries(price)) ArraySetAsSeries(price, true);
 if(ArrayGetAsSeries(_extr_array)) ArraySetAsSeries(_extr_array, true);
 CExtremum temp = {ZERO, 0};
 _extr_array[0] = temp;
 _extr_array[1] = temp;
 _extr_array[_depth-1] = temp;
 for(int i = 2; i < _depth-1; i++)
 {
  temp.direction = isExtremum(price[i-1], price[i], price[i+1]);
  if(temp.direction == MAX || temp.direction == MIN)
  {
   temp.price = price[i];
  }
  else
  {
   temp.price = 0;
  }
  _extr_array[i] = temp;
 }
}

void CExtremumCalc::SortByDirection()
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
    if(MathAbs(_extr_array[i].price - _extr_array[prev_extr].price) <= _e*point)
    {
     _extr_array[i].direction = ZERO;
     _extr_array[i].price = 0;
    }
    else
     prev_extr = i;
   }
  }
 } 
}

CExtremum CExtremumCalc::getExtr(int index)
{
 if(0 <= index && index < _depth)
  return _extr_array[index];
 else
 {
  Alert(__FUNCTION__, " bad index = ", index);
  CExtremum error = {ZERO, -1};
  return error;
 }
}