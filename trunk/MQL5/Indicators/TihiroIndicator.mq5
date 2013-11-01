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

//---- всего задействовано 1 буфер
#property indicator_buffers 1
//---- использовано 1 графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы линии
#property indicator_type1 DRAW_LINE
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "TIHIRO"

input short bars=50;  //начальное количество баров истории

//---- буфер значений линии  тренда
double trendLine[];


//---- TD точки (экстремумы) восходящего тренда
Extrem point_up_left;    //левая точка
Extrem point_up_right;   //правая точка
//---- TD точки (экстремумы) нисходящего тренда
Extrem point_down_left;  //левая точка
Extrem point_down_right; //правая точка
//---- тангенсы наклона линии тренда
double tg;               //тангенс тренд линии
//---- флаги для поиска экстремумов
short  flag_up=0;        //флаг для восходящего тренда, 0-нет экстремума, 1-найден один, 2-оба найдены
short  flag_down=0;      //флаг для нисходящего тренда, 0-нет экстремума, 1-найден один, 2-оба найдены

int OnInit()
  {
//---- назначаем индексы буфера
   SetIndexBuffer(0,trendLine,INDICATOR_DATA);   
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
   //проходим по циклу и вычисляем экстремумы
   for(i = rates_total-2; i > 0; i--)
    {
     trendLine[i]=0;    
     //если текущая high цена больше high цен последующей и предыдущей
     if (high[i] > high[i-1] && high[i] > high[i+1] && flag_down < 2 )
      {
       if (flag_down == 0)
        {
         //сохраняем правый экстремум
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down++; 
        }
       else 
        {
         if(high[i] > point_down_right.price)
          {
          //сохраняем левый экстремум
          point_down_left.SetExtrem(time[i],high[i]);               
          flag_down++;
          }
        }            
      }  //нисходящий тренд
     //если текущая low цена меньше low цен последующей и предыдущей
     if (low[i] < low[i-1] && low[i] < low[i+1] && flag_up < 2 )
      {
       if (flag_up == 0)
        {
         //сохраняем правый экстремум
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up++; 
        }
       else 
        {
         if(low[i] < point_up_right.price)
          {
          //сохраняем левый экстремум
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up++;
          }
        }            
      }  //восходящий тренд         
    } 
    //вычисляем тангенсы наклона тренд линий
    if (flag_down==2) //если оба экстремума для нисходящего тренда найдены
     {
      flag_down = 0;
      if (flag_up > 0)
       { 
        if (point_up_right.time > point_down_right.time)
         {
          tg = (point_down_right.price-point_down_left.price)/(point_down_right.time-point_down_left.time);
          flag_up = 0;
          flag_down = 2;
         }
       }
     }
    if (flag_up==2) //если оба экстремума для восходящего тренда найдены
     {
      flag_up = 0;
      if (flag_down > 0)
       {
        if (point_down_right.time > point_up_right.time)
         {
          tg = (point_up_right.price-point_up_left.price)/(point_up_right.time-point_up_left.time);
          flag_down=0;
          flag_up = 2;
         }
       }
     }     
    //проходим по циклу и вычисляем точки, принадлежащие линиям тренда
    for (i = rates_total-1; i > 0 ; i--)
     {
      if (flag_down==2)
       {
        if (time[i]>=point_down_left.time)
         trendLine[i] = point_down_left.price+(time[i]-point_down_left.time)*tg;
       }
      if (flag_up==2)
       {
        if (time[i]>=point_up_left.time)
         trendLine[i] = point_up_left.price+(time[i]-point_up_left.time)*tg;
       }       
     }
     flag_down = 0;
     flag_up = 0;
   return(rates_total);
  }
