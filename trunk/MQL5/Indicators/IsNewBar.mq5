//+------------------------------------------------------------------+
//|                                                     IsNewBar.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBarDD.mqh>  // для проверки на новый бар
#include <CEventBase.mqh>  // для генерации события
//+------------------------------------------------------------------+
//| Индикатор, генерирующий события пришествия нового бара           |
//+------------------------------------------------------------------+
CisNewBar *isNewBar;
CEventBase *event;

int OnInit()
  {
   isNewBar = new CisNewBar(_Symbol,_Period);
   //event = new CEventBase();
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
   // если пришел новый бар
   if (isNewBar.isNewBar())
    {
     // то запускаем генератор событий
     event = new CEventBase();
     if(CheckPointer(event)==POINTER_DYNAMIC)
       {
        SEventData data;
        // проходим по всем открытым графикам с текущим символом и ТФ и генерируем для них события
        long z = ChartFirst();
        while (z>=0)
         {
          if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // если найден график с текущим символом и периодом 
            {
            // генерим событие для текущего графика
            event.Generate(z,1,data); 
            }
         z = ChartNext(z);
        
        }   
      }  
    }
   return(rates_total);
  }