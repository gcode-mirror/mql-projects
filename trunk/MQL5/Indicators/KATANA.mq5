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
#property indicator_label1  "TREND_UP"

//---- в качестве индикатора использованы отрезки
#property indicator_type2 DRAW_COLOR_SECTION
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "TREND_DOWN"

//---- системные параметры индикатора

//---- системные параменные индикатора

double tg_up;   //тангенс угла наклона линии
double tg_down; //тангенс угла наклона линии
bool   first_start=true;   //первый запуск

//---- буферы значений линий
double line_up[];
double line_down[];

double   GetTan(double value_left,double value_right)
//вычисляет значение тангенса наклона линии
 {
  //т.к. линия строится всегда между соседними барами, то делить на разницу по X не нужно, т.к. она равна единице
  return  value_right - value_left; 
 } 
 
double   GetAverageY (double value1,double value2,double value3)
//возвращает среднее значение трех значений 
 {
   return (value1+value2+value3)/3;
 }

double   GetLineY (double value,double tg)
//возвращает значение Y точки текущей линии
 {
   return value+tg;
 }

int OnInit()
  {
  
   SetIndexBuffer(0,line_up,    INDICATOR_DATA);   
//   SetIndexBuffer(1,line_down,  INDICATOR_DATA);  
   
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
  //если первый запуск 
  
  if (first_start)
   {
    //сохраняем первые две точки 
    line_up[rates_total-2] = low[rates_total-2];
    line_up[rates_total-3] = low[rates_total-3];    
    //вычисляем тангенс угла наклона линии
    tg_up = GetTan(line_up[rates_total-3],line_up[rates_total-2]);
    //сохраняем первые две точки 
    line_down[rates_total-2] = high[rates_total-2];
    line_down[rates_total-3] = high[rates_total-3];    
    //вычисляем тангенс угла наклона линии
    tg_down = GetTan(line_down[rates_total-3],line_down[rates_total-2]);    
    first_start = false;
   }
  else
   {
    //очищаем предыдущую левую  точку
    line_up[rates_total-4] = 0;
    line_down[rates_total-4] = 0;    
    //если значение линии в точке меньше, чем низкая цена последнего бара 
    if (GetLineY(line_up[rates_total-3],tg_up) < low[rates_total-2])
     {
      line_up[rates_total-2] = low[rates_total-2];
      tg_up = GetTan(line_up[rates_total-3],line_up[rates_total-2]);
     }
    else
     {
      line_up[rates_total-2] = GetAverageY(low[rates_total-2],low[rates_total-3],GetLineY(line_up[rates_total-2],tg_up));
      tg_up = GetTan(line_up[rates_total-3],line_up[rates_total-2]);     
     }

    //если значение линии в точке меньше, чем низкая цена последнего бара 
    if (GetLineY(line_down[rates_total-3],tg_down) > high[rates_total-2])
     {
      line_down[rates_total-2] = high[rates_total-2];
      tg_down = GetTan(line_down[rates_total-3],line_down[rates_total-2]);
     }
    else
     {
      line_down[rates_total-2] = GetAverageY(high[rates_total-2],high[rates_total-3],GetLineY(line_down[rates_total-2],tg_down));
      tg_down = GetTan(line_down[rates_total-3],line_down[rates_total-2]);     
     }     
     
   }
   return(rates_total);
  }