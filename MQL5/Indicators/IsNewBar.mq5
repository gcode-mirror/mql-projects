//+------------------------------------------------------------------+
//|                                                     IsNewBar.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include  <Lib CisNewBar.mqh>  // для проверки на новый бар
#include  <CEventBase.mqh>  // для генерации новых событий 
//+------------------------------------------------------------------+
//| Индикатор, генерирующий события пришествия нового бара           |
//+------------------------------------------------------------------+
CisNewBar *isNewBar; // объект появления нового экстремума
CEventBase *eventBase; // объект формирования 
SEventData eventData; // структура полей событий

int OnInit()
  {
   isNewBar = new CisNewBar(_Symbol,_Period);
   eventBase = new CEventBase(100);
   if (eventBase == NULL)
    {
     Print("Не удалось создать объект класса генератора событий");
     return (INIT_FAILED);
    }
   // создаем id события 
   eventBase.AddNewEvent(_Symbol,_Period,"Новый бар");
   eventBase.AddNewEvent(_Symbol,PERIOD_M5,"Такие дела");
   return(INIT_SUCCEEDED);
  }

void OnDeinit()
  { 
   delete isNewBar;
   delete eventBase;
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
   if (isNewBar.isNewBar()>0)
    {
     // генерим события для всех графиков
     Generate("Новый бар",eventData,true); 
    }
   return(rates_total);
  }
  
// проходим по всем графикам и генерим события под них
void Generate(string id_nam,SEventData &_data,const bool _is_custom=true)
  {
   // проходим по всем открытым графикам с текущим символом и ТФ и генерируем для них события
   long z = ChartFirst();
   while (z>=0)
     {
      if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // если найден график с текущим символом и периодом 
        {
         // генерим событие для текущего графика
         eventBase.Generate(z,id_nam,_data,_is_custom);
        }
      z = ChartNext(z);      
     }     
  }    