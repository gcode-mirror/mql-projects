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
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#include <CompareDoubles.mqh>
#include <CExtremumCalc_NE.mqh>
#include <Lib CisNewBar.mqh>
//--- input parameters
 input int    period_ATR = 100;        //Период ATR для канала
 input double percent_ATR = 0.03;      //Ширина канала уровня в процентах от ATR
 input double precentageATR_price = 2; //Процентр ATR для нового экструмума
 input int depth = 100;
 

CExtremumCalc extrcalc(Symbol(), Period(), precentageATR_price, period_ATR, percent_ATR); 
CisNewBar bar;
//--- indicator buffers
bool first = true;
double         Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, Buffer, INDICATOR_DATA);
   //PrintFormat("depth = %d", depth);
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
   ArraySetAsSeries(Buffer, true);
   ArraySetAsSeries(close, true);
   //if(bar.isNewBar() > 0)
   //{  
    extrcalc.FillExtremumsArray(Symbol(), Period());
    
    for(int i = depth-1; i > 0; i--)
    {
     //Alert("EXTR : ", i, " ", extrcalc.getExtr(i).price);
     Buffer[i] = extrcalc.getExtr(i).price;
    }
   //}
   
    
   return(rates_total);
  }
//+------------------------------------------------------------------+