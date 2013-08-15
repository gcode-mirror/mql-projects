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
 double _e;
 int _depth;
 
 public:
 CExtremumCalc();
 CExtremumCalc(double e, int depth);
~CExtremumCalc();
 DIRECTION isExtremum(double a, double b, double c);
 void FillExtremumsArray(const double& price[]); 
 void SortExtremumsArray();
};
CExtremumCalc::CExtremumCalc():
               _e (50),
               _depth (128)
               {
                ArrayResize(_extr_array, _depth);
                ArraySetAsSeries(_extr_array, true);
               }

CExtremumCalc::CExtremumCalc(double e,int depth):
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
 ArraySetAsSeries(price, true);
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
  _extr_array[i] = temp;
 }
}

void CExtremumCalc::SortExtremumsArray()
{
}