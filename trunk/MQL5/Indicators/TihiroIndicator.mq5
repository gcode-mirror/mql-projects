//+------------------------------------------------------------------+
//|                                              TihiroIndicator.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//---- всего задействовано 1 буфер
#property indicator_buffers 1
//---- использовано 1 графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы линии
#property indicator_type1   DRAW_LINE
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "TIHIRO"


//---- буфер значений линии тренда
double trendLine[];


int OnInit()
  {
//---- назначаем индекс буфера
   SetIndexBuffer(0,trendLine,INDICATOR_DATA);
//---- настраиваем свойства индикатора
   //PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, clrYellow);
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
   for(int i = 0; i <= rates_total; i++)
    {
     trendLine[i] = 1.37860;
    }
   return(rates_total);
  }
