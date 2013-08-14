//+------------------------------------------------------------------+
//|                                                    Extremums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "Label1"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#include <CompareDoubles.mqh>
//--- input parameters
input int      depth=20;
//--- indicator buffers
double         Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, Buffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_ARROW, 234);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   ArraySetAsSeries(price, true);
   ArraySetAsSeries(Buffer, true);
   for(int i=2; i < depth-1; i++)
   {
    if(isExtremum(price[i-1], price[i], price[i+1]) == 1)
    {
     Buffer[i] = price[i];
     Print(i);
    } 
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
int isExtremum(double a, double b, double c)
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