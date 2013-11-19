//+------------------------------------------------------------------+
//|                                                       KATANA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <CompareDoubles.mqh>  

//+------------------------------------------------------------------+
//| Индикатор KATANA                                                 |
//+------------------------------------------------------------------+
//---- всего задействовано 2 буфера
#property indicator_buffers 2
//---- использовано 1 графическое пос троение
#property indicator_plots   2

//---- в качестве индикатора использованы отрезки
#property indicator_type1 DRAW_COLOR_SECTION
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "TREND_DOWN"

//---- в качестве индикатора использованы отрезки
#property indicator_type2 DRAW_COLOR_SECTION
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "TREND_UP"

//---- системные параметры индикатора

//---- системные параменные индикатора

double tg;  //тангенс угла наклона линии
double point_y_left;  //высота левой точки линии
double point_y_right; //высота правой точки линии

//---- буферы значений линий
double line_up[];
double line_down[];

void   GetTan()
//вычисляет значение тангенса наклона линии
 {
  //т.к. линия строится всегда между соседними барами, то делить на разницу по X не нужно, т.к. она равна единице
  tg = point_y_right - point_y_left; 
 } 
 
double   GetAverageY (double a)
//возвращает среднее значение трех значений 
 {
   return 1;
 }

double   GetLineY ()
//возвращает значение Y точки текущей линии
 {
   return point_y_right+tg;
 }

int OnInit()
  {
  
   SetIndexBuffer(0,line_up,    INDICATOR_DATA);   
   SetIndexBuffer(1,line_down,  INDICATOR_DATA);  
   
   return(INIT_SUCCEEDED);
  }


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
   /*for(i = rates_total-1; i > 0; i--)
    {
      
    }*/
    
   line_up[rates_total-1] = high[rates_total-1];
   line_up[rates_total-2] = high[rates_total-2];
   
   return(rates_total);
  }