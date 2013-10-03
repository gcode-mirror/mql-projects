//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>

struct SExtremum
{
 int direction;
 double price;
 int width;
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
 SExtremum isExtremum(double vol1,double vol2,double vol3);
 void FillExtremumsArray(string symbol, ENUM_TIMEFRAMES tf);
 void ZeroArray();
 int NumberOfExtr();
 SExtremum getExtr(int index);
};

CExtremumCalc::CExtremumCalc():
               _epsilon (50),
               _depth (128),
               _last (-1)
               {
                ArrayResize(_extr_array, _depth);
                ZeroArray();
               }

CExtremumCalc::CExtremumCalc(int e,int depth):
               _epsilon (e),
               _depth (depth),
               _last (-1)
               {
                ArrayResize(_extr_array, _depth);
                ZeroArray();
               }
CExtremumCalc::~CExtremumCalc()
                {
                 ArrayFree(_extr_array);
                }             

SExtremum CExtremumCalc::isExtremum(double vol1,double vol2,double vol3)
{
 SExtremum res;
 res.direction = 0;
 res.price = vol2;
 if(_last == -1 || GreatDoubles(MathAbs(vol2 - _extr_array[_last].price), _epsilon*Point()))
 {
  if(GreatDoubles(vol2, vol1) && GreatDoubles(vol2, vol3))
  {
   res.direction = 1;// минимум в точке vol2
  }
  else if(LessDoubles(vol2, vol1) && LessDoubles(vol2, vol3))
       {
        res.direction = -1;// минимум в точке vol2
       }
 }
 return(res);
}


void CExtremumCalc::FillExtremumsArray(string symbol, ENUM_TIMEFRAMES tf)
{
 double price [];
 int copiedPrice = -1;
 for(int attempts = 0; attempts < 25 && copiedPrice < 0; attempts++)
 {
  copiedPrice = CopyClose(symbol, tf, 0, _depth + 1, price);
 }
 if (copiedPrice != _depth + 1) 
 {
  Alert(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", GetLastError());
  if(GetLastError() == 4401) 
   Alert(__FUNCTION__, "Подождите некоторое время или подгрузите историю вручную.");
  return;
 }
 //datetime time [];
 //CopyTime(symbol, tf, 0, _depth + 1, time);

 if(!ArrayGetAsSeries(price)) ArraySetAsSeries(price, true);
 if(!ArrayGetAsSeries(_extr_array)) ArraySetAsSeries(_extr_array, true);
 //if(!ArrayGetAsSeries(time)) ArraySetAsSeries(time, true);
 SExtremum zero = {0, 0, 0};
 ZeroArray();
 _last = -1;
 for(int i = _depth-1; i > 1; i--)
 {  
  _extr_array[i].direction = isExtremum(price[i+1], price[i], price[i-1]).direction;
  //Print(StringFormat("%s i = %d; price[i+1] = %f, price[i] = %f, price[i-1] = %f, dir = %s", TimeToString(time[i]), i,  price[i+1], price[i], price[i-1], EnumToString((DIRECTION)_extr_array[i].direction)));
  if(_extr_array[i].direction != 0)
  {
   _extr_array[i].width = 1;
   //Alert( i, " ", _last, " ", time[i], " ", EnumToString((DIRECTION)_extr_array[i].direction));
   if(_last == -1)
   {
    _extr_array[i].price = price[i];
    _last = i;
    continue;
   }
   _extr_array[i].price = price[i];
   if(_extr_array[_last].direction != _extr_array[i].direction)
   {
    _last = i;
   }
   else
   {
    if(_extr_array[i].direction == 1)
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
    if(_extr_array[i].direction == -1)
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
   }  
  }
 }
 ArrayFree(price);
 //ArrayFree(time);
}

void CExtremumCalc::ZeroArray()
{
 SExtremum zero = {0, 0};
 for(int i = _depth-1; i > 0; i--)
 {
  _extr_array[i] = zero;
 }
}

int CExtremumCalc::NumberOfExtr ()
{
 int count = 0;
 for(int i = _depth-1; i > 0; i--)
 {
  if (_extr_array[i].price != 0)
   count++;
 }
 return count;
}

SExtremum CExtremumCalc::getExtr(int index)
{
 if(0 <= index && index < _depth)
  return _extr_array[index];
 else
 {
  Alert(__FUNCTION__, " bad index = ", index);
  SExtremum error = {0, -1};
  return error;
 }
}