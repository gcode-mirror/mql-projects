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
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // размер входных таймсерий
                 const int prev_calculated,  // обработано баров на предыдущем вызове
                 const datetime& time[],     // Time
                 const double& open[],       // Open
                 const double& high[],       // High
                 const double& low[],        // Low
                 const double& close[],      // Close
                 const long& tick_volume[],  // Tick Volume
                 const long& volume[],       // Real Volume
                 const int& spread[]         // Spread
               )
  {
//---
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(Buffer, true);
   for(int i=2; i < depth-1; i++)
   {
    if(isExtremum(close[i-1], close[i], close[i+1]) == 1)
    {
     Buffer[i] = high[i];
    }
    if(isExtremum(close[i-1], close[i], close[i+1]) == -1)
    {
     Buffer[i] = low[i];
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