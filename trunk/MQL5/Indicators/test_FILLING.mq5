//+------------------------------------------------------------------+
//|                                                 DRAW_FILLING.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#property description "Индикатор для демонстрации DRAW_FILLING"

//#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot Intersection
#property indicator_label1  "Intersection"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrRed

enum COLOR
{
 COLOR_RED = 0,
 COLOR_BLUE = 1,
 COLOR_AQUA = 2,
 COLOR_BROWN = 3,
 COLOR_CORAL = 4, 
 COLOR_GREAY = 5
};

//--- input параметры
input int      shift=1;          // сдвиг средних в будущее (положительный)
input double A = 1.3600;
input double B = 1.3500;
input COLOR  indicator_color = COLOR_RED; //индекс элемента в массиве цветов(0-7)
//--- индикаторные буферы
double         IntersectionBuffer1[];
double         IntersectionBuffer2[];
//--- массив для хранения цветов
color colors[]={clrRed,clrBlue,clrGreen,clrAquamarine,clrBrown,clrCoral,clrGray};
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,IntersectionBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,IntersectionBuffer2,INDICATOR_DATA);
//---
   PlotIndexSetInteger(0,PLOT_SHIFT,shift);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, colors[indicator_color]);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

//--- делаем первый расчет индикатора или данные изменились и требуется полный перерасчет
      for(int i = 0; i <= rates_total; i++)
      {
       IntersectionBuffer1[i] = A;
       IntersectionBuffer2[i] = B;
      }
//--- return value of prev_calculated for next call
   return(rates_total);
  }