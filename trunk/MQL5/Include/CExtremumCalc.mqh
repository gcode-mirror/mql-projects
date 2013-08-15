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
 UNKNOWN, 
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
 CExtremumCalc(double e, int depth);
~CExtremumCalc();
 int isExtremum(double a, double b, double c);
 void FillExtremumsArray(const double& price[]); 
 
};

CExtremumCalc::CExtremumCalc(double e,int depth):
               _e (e),
               _depth (depth)
               {
                ArrayResize(_extr_array, depth);
                ArraySetAsSeries(_extr_array, true);
               }

int CExtremumCalc::isExtremum(double a, double b, double c)
{
 if(GreatDoubles(b, a) && GreatDoubles(b, c))
 {
  return(1);
 }
 else if(LessDoubles(b, a) && LessDoubles(b, c))
      {
       return(-1);
      }
 return(0);
}

void CExtremumCalc::FillExtremumsArray(const double &price[])
{
 ArraySetAsSeries(price, true);
 CExtremum temp = {UNKNOWN, 0};
 for(int i = 2; i < _depth-1; i++)
 {
   if(isExtremum(price[i-1], price[i], price[i+1]) == 1)
   {
    temp.direction = MAX;
    temp.price = price[i];
   }
   if(isExtremum(price[i-1], price[i], price[i+1]) == -1)
   {
    temp.direction = MIN;
    temp.price = price[i];
   } 
 }
}