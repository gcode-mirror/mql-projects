//+------------------------------------------------------------------+
//|                                        QualityDivergenceMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//TODO удаление линий на OnDeinit
//     проверка рабочего состояния!

#include <Lib CisNewBAr.mqh>
#include <divergenceMACD.mqh>

input int fast_ema_period = 12; // период быстрой EMA MACD
input int slow_ema_period = 26; // период медленной EMA MACD
input int signal_period = 9;    // период сигнальной EMA MACD

int handleMACD;
CisNewBar bar;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 handleMACD = iMACD(NULL, Period(), fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE); 
 return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{
 IndicatorRelease(handleMACD);
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
 int direction = 0;
 PointDiv divergence_point = {0};
 if(bar.isNewBar() > 0)
 {
    direction = divergenceMACD(handleMACD, Symbol(), Period(), 0, null);
    if(direction != 0)
    {
     int rand_color = rand()%255;
     TrendCreate(0, TimeToString(TimeCurrent())+"_1", 0, divergence_point.extrMACD1,  divergence_point.valuePrice1, 
                                                         divergence_point.extrPrice2, divergence_point.valuePrice2,
                                                         rand_color);
     TrendCreate(0, TimeToString(TimeCurrent()+"_2"), 1, divergence_point.extrMACD1, divergence_point.valueMACD1, 
                                                         divergence_point.extrMACD2, divergence_point.valueMACD2,
                                                         rand_color);                                               
    }
 }
 return(rates_total);
}
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID=0,        // ID графика
                 const string          name="TrendLine",  // имя линии
                 const int             sub_window=0,      // номер подокна
                 datetime              time1=0,           // время первой точки
                 double                price1=0,          // цена первой точки
                 datetime              time2=0,           // время второй точки
                 double                price2=0,          // цена второй точки
                 const color           clr=clrRed,        // цвет линии
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линии
                 const int             width=1,           // толщина линии
                 const bool            back=false,        // на заднем плане
                 const bool            selection=true,    // выделить для перемещений
                 const bool            ray_left=false,    // продолжение линии влево
                 const bool            ray_right=false,   // продолжение линии вправо
                 const bool            hidden=true,       // скрыт в списке объектов
                 const long            z_order=0)         // приоритет на нажатие мышью
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- создадим трендовую линию по заданным координатам
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": не удалось создать линию тренда! Код ошибки = ",GetLastError());
      return(false);
     }
//--- установим цвет линии
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль отображения линии
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину линии
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- включим (true) или отключим (false) режим перемещения линии мышью
//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект
//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection
//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- включим (true) или отключим (false) режим продолжения отображения линии влево
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- включим (true) или отключим (false) режим продолжения отображения линии вправо
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- установим приоритет на получение события нажатия мыши на графике
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- успешное выполнение
   return(true);
  }

//+------------------------------------------------------------------+
//| Функция удаляет линию тренда с графика.                          |
//+------------------------------------------------------------------+
bool TrendDelete(const long   chart_ID=0,       // ID графика
                 const string name="TrendLine") // имя линии
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- удалим линию тренда
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": не удалось удалить линию тренда! Код ошибки = ",GetLastError());
      return(false);
     }
//--- успешное выполнение
   return(true);
  }
