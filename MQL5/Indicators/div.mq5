//+------------------------------------------------------------------+
//|                                                          div.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "div"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#include <Lib CisNewBar.mqh>
#include <divSignals.mqh>


input ENUM_MA_METHOD Method = MODE_SMA; // Метод сглаживания

input int    kPeriod = 5;       // К-период
input int    dPeriod = 3;       // D-период
input int    slov  = 3;         // Сглаживание графика. Возможные значения от 1 до 3.
input int    deep = 12;         // обрабатываемый период, количество баров.
input int    delta = 2;         // разнца в барах между правыми экстремумами цены и стохастика
input double highLine = 80;     // верхняя значимая граница стохастика
input double lowLine = 20;      // нижняя значимая граница стохастика
input int    firstBarsCount = 3;// количество первых баров на которых должен находиться максимум или минимум цены

int    stoHandle;               // указатель на индикатор.
int    firstBar;                // индекс бара, с которго начинаются вычисления.
int    t;                       // флаг для первого вхождения до появления нового бара.
double mainLine[];              // массив основной линии стохастика.
double divBufferRight[];        // массив индикатора
double signalsMode[];

enum ENUM_SIGNALS_MODE
{
 DIVERGENCE = 0,
 CONVERGENCE = 1,
 NONE = 2
};



divSignals ds;                  // элемент класса divSignals
CisNewBar nb;                   // элемент класса CisNewBar

int OnInit()
  {
   stoHandle = iStochastic(NULL, 0, kPeriod, dPeriod, slov, Method, STO_LOWHIGH); // Инициализация указателя.
   if (stoHandle < 0)
   {
    Print("Error: Хэндл (указатель) не инициализирован!", GetLastError());
    return(-1);
   }
   else Print("Инициализация хэндла (указателя) прошла успешно!");
   
   SetIndexBuffer(0,divBufferRight,INDICATOR_DATA);
   SetIndexBuffer(1,signalsMode,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, deep - 1);
   
   ArraySetAsSeries(mainLine, true);
   ArraySetAsSeries(divBufferRight, true);
   ArraySetAsSeries(signalsMode, true);
   
   t = 0;
   
   ds.SetDelta(delta);
   ds.SetHighLineOfStochastic(highLine);
   ds.SetLowLineOfStochastic(lowLine);
   ds.SetFirstBarsCount(firstBarsCount);

   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   
   if((nb.isNewBar() > 0) || (t == 0))
   {
        
    ArraySetAsSeries(price, true);
    
    if (rates_total < deep - 1)
    {
     return(0);
    }
    
    if (CopyBuffer(stoHandle, MAIN_LINE, 0, rates_total, mainLine) < 0) // заполнение и проверка массива основной линии.
    {
    Print("Ошибка заполнения массива main");
    return(false);
    }
    if (t == 0)
    {
    t = rates_total;
    }
    else
    {
     t = deep;
    }
    
    for (firstBar = deep - 1; firstBar < t; firstBar++)
    {
     if (ds.Divergence(price, mainLine, firstBar, deep))
     {
      signalsMode[ds.GetRightIndexOfPrice()] = DIVERGENCE;
      divBufferRight[ds.GetRightIndexOfPrice()] = ds.GetRightPointOfPrice();
     }
     else if (ds.Convergence(price, mainLine, firstBar, deep))
     {
      signalsMode[ds.GetRightIndexOfPrice()] = CONVERGENCE;
      divBufferRight[ds.GetRightIndexOfPrice()] = ds.GetRightPointOfPrice();
     }
     else 
     {
      signalsMode[ds.GetRightIndexOfPrice()] = NONE;
     }    
    }
    }
    
   return(rates_total);
  }