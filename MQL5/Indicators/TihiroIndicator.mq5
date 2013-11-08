//+------------------------------------------------------------------+
//|                                              TihiroIndicator.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <TIHIRO\Extrem.mqh>     //подключаем библиотеку для класса экстремумов
#include <CompareDoubles.mqh>   

//---- всего задействовано 2 буфера
#property indicator_buffers 4
//---- использовано 1 графическое пос троение
#property indicator_plots   4
//---- в качестве индикатора использованы линии
#property indicator_type1 DRAW_LINE
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "TREND_DOWN"

//---- в качестве индикатора использованы линии
#property indicator_type2 DRAW_LINE
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "TREND_UP"


//---- в качестве индикатора использованы линии
#property indicator_type3 DRAW_LINE
//---- цвет индикатора
#property indicator_color3  clrYellow
//---- стиль линии индикатора
#property indicator_style3  STYLE_DASHDOT
//---- толщина линии индикатора
#property indicator_width3  1

//---- в качестве индикатора использованы линии
#property indicator_type4 DRAW_LINE
//---- цвет индикатора
#property indicator_color4  clrYellow
//---- стиль линии индикатора
#property indicator_style4  STYLE_DASHDOT
//---- толщина линии индикатора
#property indicator_width4  1


input short bars=50;  //начальное количество баров истории

//---- буфер значений линий  тренда
double trendLineDown[];
double trendLineUp[];
double priceHigh[];
double priceLow[];


//---- TD точки (экстремумы) восходящего тренда
Extrem point_up_left;    //левая точка
Extrem point_up_right;   //правая точка
//---- TD точки (экстремумы) нисходящего тренда
Extrem point_down_left;  //левая точка
Extrem point_down_right; //правая точка
//---- тангенсы наклона линии тренда
double tg_down;               //тангенс нисходящей тренд линии
double tg_up;                 //тангенс восходящей тренд линии
//---- флаги для поиска экстремумов
short  flag_up=0;        //флаг для восходящего тренда, 0-нет экстремума, 1-найден один, 2-оба найдены
short  flag_down=0;      //флаг для нисходящего тренда, 0-нет экстремума, 1-найден один, 2-оба найдены

int OnInit()
  {
//---- назначаем индексы буферов
   SetIndexBuffer(0,trendLineDown,INDICATOR_DATA);   
   SetIndexBuffer(1,trendLineUp,  INDICATOR_DATA);  
   SetIndexBuffer(2,priceHigh,  INDICATOR_DATA);     
   SetIndexBuffer(3,priceLow,  INDICATOR_DATA);                           
//---- настраиваем свойства индикатора
//--- зададим код символа для отрисовки в PLOT_ARROW

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
   int i;
   flag_down = 0;  
   flag_up = 0;   
   //проходим по циклу и вычисляем экстремумы
   
   for(i = rates_total-3; i > 0; i--)
    {
     trendLineDown[i]=0;    
     trendLineUp[i]=0;       
     //если текущая high цена больше high цен последующей и предыдущей
     if ( GreatDoubles(high[i],high[i-1]) && GreatDoubles(high[i],high[i+1]) && flag_down < 2 )
      {
       if ( flag_down == 0 )
        {
         //сохраняем правый экстремум
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down=1; 
        }
       else 
        {
         if( GreatDoubles(high[i],point_down_right.price) )
          {
          //сохраняем левый экстремум
          point_down_left.SetExtrem(time[i],high[i]);               
          flag_down=2;
          }
        }            
      }  //нисходящий тренд
     //если текущая low цена меньше low цен последующей и предыдущей
     if ( LessDoubles(low[i],low[i-1]) && LessDoubles(low[i],low[i+1])&&flag_up < 2)
      {
       if (flag_up == 0)
        {
         //сохраняем правый экстремум
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up=1; 
        }
       else 
        {
         if(LessDoubles(low[i],point_up_right.price))
          {
          //сохраняем левый экстремум
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up=2;
          }
        }            
      }  //восходящий тренд         
    } 
    //вычисляем тангенсы наклона тренд линий
    if (flag_down==2) //если оба экстремума для нисходящего тренда найдены
     {
      tg_down = (point_down_right.price-point_down_left.price)/(point_down_right.time-point_down_left.time);
     }
    if (flag_up==2) //если оба экстремума для восходящего тренда найдены
     {
      tg_up = (point_up_right.price-point_up_left.price)/(point_up_right.time-point_up_left.time);
     }     
    //проходим по циклу и вычисляем точки, принадлежащие линиям тренда
    
    priceHigh[rates_total-1] = high[rates_total-1];
    priceLow[rates_total-1]  = low[rates_total-1];
    
    for (i = rates_total-1; i > 0 ; i--)
     { 
       trendLineDown[i] = 0;
       trendLineUp[i] = 0;
       priceHigh[i] = high[i];
       priceLow[i]  = low[i];
       
      if (flag_down==2)
       {

        if (time[i]>=point_down_left.time)
         trendLineDown[i] = point_down_left.price+(time[i]-point_down_left.time)*tg_down;
       }
      if (flag_up==2)
       {
        if (time[i]>=point_up_left.time)
         trendLineUp[i] = point_up_left.price+(time[i]-point_up_left.time)*tg_up;
       }    
     }

   return(rates_total);
  }