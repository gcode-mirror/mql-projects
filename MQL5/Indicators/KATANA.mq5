//+------------------------------------------------------------------+
//|                                                       KATANA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <CompareDoubles.mqh>              //для сравнения переменных типа double
#include <Lib CisNewBar.mqh>               //для проверки формирования нового бара

//+------------------------------------------------------------------+
//| Индикатор KATANA                                                 |
//+------------------------------------------------------------------+
//---- всего задействовано 2 буфера
#property indicator_buffers 2
//---- использовано 1 графическое пос троение
#property indicator_plots   2

//---- в качестве индикатора использованы отрезки
#property indicator_type1 DRAW_SECTION
//---- цвет индикатора
#property indicator_color1  clrBlue
//---- стиль линии индикатора
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width1  2
//---- отображение метки линии индикатора
#property indicator_label1  "TREND_UP"

//---- в качестве индикатора использованы отрезки
#property indicator_type2 DRAW_SECTION
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора
#property indicator_width2  2
//---- отображение метки линии индикатора
#property indicator_label2  "TREND_DOWN"

//---- системные параметры индикатора
input uint priceDifference=0;//разница цен для поиска экстремумов
//---- структура экстремумов 
struct Extrem
  {
   uint   n_bar;             //номер бара 
   double price;             //ценовое положение экстремума
  };
//---- системные параменные индикатора

double tg_up;                //тангенс угла наклона линии вверх (нижняя линия)
double tg_down;              //тангенс угла наклона линии вниз (верхняя линия)

bool   first_start=true;     //флаг первого запуска OnCalculate

//---- буферы значений линий
double line_up[];            //буфер линии вверх (нижняя линия)
double line_down[];          //буфер линии вниз (верхняя линия)
//---- экстремумы
Extrem left_extr_up;         //левый экстремум тренда вверх (нижняя линия)
Extrem right_extr_up;        //правый экстремум тренда вверх (нижняя линия)
Extrem left_extr_down;       //левый экстремум тренда вниз (верхняя линия)
Extrem right_extr_down;      //правый экстремум тренда вниз (верхняя линия)
//----  флаги поиска экстремумов
uint   flag_up;              //флаг поиска экстремумов тренда вверх
uint   flag_down;            //флаг поиска экстремумов тренда вниз
//----  для проверки формирования нового бара
CisNewBar     isNewBar; 
//----  массивы для хранения разниц цен 
double priceDiff_left;       
double priceDiff_right;

                   
double   GetTan(bool trend_type)
//вычисляет значение тангенса наклона линии
 {
  //если хотим вычислить тангенс наклона тренда вверх (нижней линии)
  if (trend_type == true)
   return ( right_extr_up.price - left_extr_up.price ) / ( right_extr_up.n_bar - left_extr_up.n_bar );
  //если хотим вычислить тангенс наклона тренда вниз (верхней линии)
  return ( right_extr_down.price - left_extr_down.price ) / ( right_extr_down.n_bar - left_extr_down.n_bar );   
 } 

double   GetLineY (bool trend_type,uint n_bar)
//возвращает значение Y точки текущей линии
 {
  //если хотим вычислить значение точки на линии тренда вверх
  if (trend_type == true)
   return (left_extr_up.price + (n_bar-left_extr_up.n_bar)*tg_up);
  //если хотим вычислить значение точки на линии тренда вниз
  return (right_extr_down.price + (n_bar-right_extr_down.n_bar)*tg_down);
 }

int OnInit()
  {
  
   SetIndexBuffer(0,line_up,    INDICATOR_DATA);   
   SetIndexBuffer(1,line_down,  INDICATOR_DATA);  
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   
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
  uint index; 

  //если первый запуск
  if (first_start)
   {
   //0) обнуляем флаги поиска экстремумов
     flag_up   = 0;
     flag_down = 0;
   //обнуление элементов массива
     line_up[rates_total-1]=0;     
     line_up[rates_total-2]=0;
     line_down[rates_total-1]=0;     
     line_down[rates_total-2]=0;     
   //1) проходим по барам и ищем два экстремума
    for (index=rates_total-3;index>0 && (flag_up < 2 || flag_down < 2);index--)
     {
      //---- обнуление элементов массива
      line_up[index]   = 0;
      line_down[index] = 0;
      //---- обработка экстремумов нижних цен
      //вычисление разниц цен
      priceDiff_left  = low[index+1]-low[index];
      priceDiff_right = low[index-1]-low[index]; 
      //если найден экстремум
      if (priceDiff_left > priceDifference && priceDiff_right > priceDifference)
       { 
        //если это первый найденный экстремум
        if (flag_up == 0)
         {
           right_extr_up.n_bar = index;
           right_extr_up.price = low[index];
           flag_up = 1;
         }
        //если это второй найденный экстремум
        else
         {
           left_extr_up.n_bar = index;
           left_extr_up.price = low[index];
           flag_up = 2;
         }
       }
      //---- обработка экстремумов верхних цен
      //вычисление разниц цен
      priceDiff_left  = high[index]-high[index+1];
      priceDiff_right = high[index]-high[index-1]; 
      //если найден экстремум
      if (priceDiff_left > priceDifference && priceDiff_right > priceDifference)
       { 
        //если это первый найденный экстремум
        if (flag_down == 0)
         {
           right_extr_down.n_bar = index;
           right_extr_down.price = high[index];
           flag_down = 1;
         }
        //если это второй найденный экстремум
        else
         {
           left_extr_down.n_bar = index;
           left_extr_down.price = high[index];
           flag_down = 2;
         }
       }      
       
     }


     //если для тренда вверх найдены два экстремума
     if (flag_up == 2)
      {
  
       //то вычисляем тангенс наклона линии тренда
       tg_up = GetTan(true);
       //сохраняем значения в массив
       line_up[left_extr_up.n_bar] = left_extr_up.price;
       line_up[rates_total-1] = GetLineY(true,rates_total-1);
       first_start = false;
      }
     //если для тренда вниз найдены два экстремума
     if (flag_down == 2)
      {
  
       //то вычисляем тангенс наклона линии тренда
       tg_down = GetTan(false);
       //сохраняем значения в массив
       line_down[left_extr_down.n_bar] = left_extr_down.price;
       line_down[rates_total-1] = GetLineY(false,rates_total-1);
       first_start = false;
      }      
   }
   //если не первый запуск 
   else
    {
     //---- если сформирован новый бар
     if ( isNewBar.isNewBar() > 0 )
      {
      
       //---- вычисляем разницу цен 
       priceDiff_left  = low[rates_total-2]-low[rates_total-3];  
       priceDiff_right = low[rates_total-4]-low[rates_total-3]; 
       //---- обнуляем значение элемента массива
       line_up[rates_total-2] = 0;

       //---- если найден экстремум
       if (priceDiff_left >= priceDifference && priceDiff_right >= priceDifference) 
        {     
          //---- если цена не перешла за линию тренда
          if (low[rates_total-3] > GetLineY(true,rates_total-3) )
           {
             //---- сохраняем новое значение для левого экстремума
             line_up[left_extr_up.n_bar] = 0;
             left_extr_up.price = right_extr_up.price;
             left_extr_up.n_bar = right_extr_up.n_bar;
             line_up[left_extr_up.n_bar] = left_extr_up.price;             
           } 
             //---- сохраняем текущий экстремум
             right_extr_up.price = low[rates_total-3];
             right_extr_up.n_bar = rates_total-3;        
             //---- вычисляем тангенс тренд линии     
        } 
        line_up[rates_total-1] = GetLineY(true,rates_total-1);
        
       //---- вычисляем разницу цен 
       priceDiff_left  = high[rates_total-3]-high[rates_total-2];  
       priceDiff_right = high[rates_total-3]-high[rates_total-4]; 
       //---- обнуляем значение элемента массива
       line_down[rates_total-2] = 0;

       //---- если найден экстремум
       if (priceDiff_left >= priceDifference && priceDiff_right >= priceDifference) 
        {     
          //---- если цена не перешла за линию тренда
          if (high[rates_total-3] < GetLineY(false,rates_total-3) )
           {
             //---- сохраняем новое значение для левого экстремума
             line_down[left_extr_down.n_bar] = 0;
             left_extr_down.price = right_extr_down.price;
             left_extr_down.n_bar = right_extr_down.n_bar;
             line_down[left_extr_down.n_bar] = left_extr_down.price;             
           } 
             //---- сохраняем текущий экстремум
             right_extr_down.price = high[rates_total-3];
             right_extr_down.n_bar = rates_total-3;        
             //---- вычисляем тангенс тренд линии     
        } 
        line_down[rates_total-1] = GetLineY(false,rates_total-1);        
        
      }
    }
   return(rates_total);
  }