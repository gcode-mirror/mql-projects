//+------------------------------------------------------------------+
//|                                                           DE.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6   // задействовано 4 буфера
#property indicator_plots   2   // два из которых отрисовываются на графике

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW

//+------------------------------------------------------------------+
//| Индикатор, отображающий экстремумы                               |
//+------------------------------------------------------------------+
#include <DrawExtremums/TempCExtremum.mqh> // вычисление экстремумов
#include <CLog.mqh>                        // для сохранения в лог
#include <CompareDoubles.mqh>              // для сравнения действительных чисел
#include <CEventBase.mqh>                  // для генерации событий     

// подключение необходимых библиотек

// индикаторные буферы
double bufferFormedExtrHigh[];  // буфер сформированных верхних экстремумов
double bufferFormedExtrLow[];   // буфер сформированных нижних экстремумов
double bufferAllExtrHigh[];     // буфер, хранящий все верхние экстремумы на истории
double bufferAllExtrLow[];      // буфер, хранящий все нижние экстремумы на истории
double bufferTimeExtrHigh[];    // буфер времени сформированных верхних экстремумов
double bufferTimeExtrLow[];     // буфер времени сформированных нижних экстремумов
 
// системные переменные

// хэндлы индикаторов
int handleForAverBar;      // хэндл индикатора для вычисления среднего бара 
int handleIsNewBar;        // хэндл индикатора IsNewBar
// другие переменные
int indexPrevUp   = -1;    // индекс последнего верхнего экстремума, которого нужно затереть
int indexPrevDown = -1;    // индекс последнего нижнего экстремума, которого нужно затереть
int depth;                 // глубина истории
int jumper=0;              // переменная для чередования экстремумов
int prevJumper=0;          // предыдущее значение jumper
double lastExtrUpValue;    // значение последнего экстремума
double lastExtrDownValue;  // значение последнего экстемума   
datetime lastExtrUpTime;   // время последнего экстремума HIGH
datetime lastExtrDownTime; // время последнего экстремума LOW
datetime lastBarTime = 0;  // время последнего бара
// объекты 
CExtremum  *extr;          // объект класса вычисления экстремумов 
CEventBase *event;         // для генерации событий 
SEventData eventData;      // структура полей событий
// структуры экстремумов
SExtremum extrHigh = {0,-1,0};      // структура для хранения верхнего экстремума
SExtremum extrLow  = {0,-1,0};      // структура для хранения нижнего экстремума
 
int OnInit()
  {
   // задаем индикаторную глубину на все бары
   depth = Bars(_Symbol,_Period);
   // создаем хэндл индикатора для вычисления среднего бара
   handleForAverBar = iMA(_Symbol, _Period, 100, 0, MODE_EMA, iATR(Symbol(), _Period, 30));
   if (handleForAverBar == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать хэндл индикатора AverageATR");
     return (INIT_FAILED);
    }      
   // создаем объект класса вычисления экстремумов
   extr = new CExtremum(_Symbol, _Period, handleForAverBar);
   if (extr == NULL)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать объект класса CExtremum");
     return (INIT_FAILED);
    }   
   // создаем объект генерации событий 
   event = new CEventBase(100);
   if (event == NULL)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать объект класса CEventBase");
     return (INIT_FAILED);
    }
   // создаем события
   event.AddNewEvent(_Symbol,_Period,"новый экстремум");
  // event.AddNewEvent(_Symbol,_Period,event.GenUniqEventName("сформировался экстремум",_Symbol,_Period) );
   
   event.PrintAllNames();
   // задаем индексацию индикаторных буферов
   SetIndexBuffer(0, bufferFormedExtrHigh, INDICATOR_DATA);
   SetIndexBuffer(1, bufferFormedExtrLow, INDICATOR_DATA);
   SetIndexBuffer(2, bufferAllExtrHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, bufferAllExtrLow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, bufferTimeExtrHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, bufferTimeExtrLow,INDICATOR_CALCULATIONS);
   // выставляем индексацию буферов
   ArraySetAsSeries(bufferAllExtrHigh,false);
   ArraySetAsSeries(bufferAllExtrLow,false);
   ArraySetAsSeries(bufferFormedExtrHigh,false);
   ArraySetAsSeries(bufferFormedExtrLow,false);
   ArraySetAsSeries(bufferTimeExtrHigh,false);
   ArraySetAsSeries(bufferTimeExtrLow,false);
   // задаем тип графическ
   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217); 
   //
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
  {   
   //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);  
   // освобождаем индикаторные буферы
   ArrayFree(bufferFormedExtrHigh);
   ArrayFree(bufferFormedExtrLow);
   ArrayFree(bufferAllExtrHigh);
   ArrayFree(bufferAllExtrLow);
   ArrayFree(bufferTimeExtrHigh);
   ArrayFree(bufferTimeExtrLow);
   // освобождаем индикаторный хэндл
   IndicatorRelease(handleForAverBar);
   // удаляем объекты
   delete extr;
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
   // если это первый расчет индикатора
   if(prev_calculated == 0) 
   {
   if (BarsCalculated(handleForAverBar) < 1)
    {
     return (0);
    }
    // проходим по всей истории и вычисляем экстремум\экстремумы
    for(int i = 0; i < rates_total;  i++)    
      {
       // обнуляем значения экстремумов
       bufferAllExtrHigh[i]    = 0;
       bufferAllExtrLow[i]     = 0;
       bufferFormedExtrHigh[i] = 0;
       bufferFormedExtrLow[i]  = 0;
       // если удалось вычислить экстремумы
       if ( extr.isExtremum(extrHigh,extrLow,time[i],false) )
        {
          // если обновился верхний экстремум 
          if (extrHigh.time >= time[i])
           {
            bufferAllExtrHigh[i] = extrHigh.price;       // сохраняем в буфер значение полученного экстремума
            bufferFormedExtrHigh[i] = extrHigh.price; 
            bufferTimeExtrHigh[i] = double(extrHigh.time);
            
            lastExtrUpValue = extrHigh.price;
            lastExtrUpTime  = extrHigh.time;
            //Comment("экстр HIGH время = ",TimeToString(extrHigh.time) );
            //Generate("Новый экстремум"                 // здесь будем генерировать событие появления нового экстремума
            
            if (jumper == -1)
              {
               bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue; // сохраняем сформированный экстремум         
               bufferTimeExtrLow[indexPrevDown] = double(lastExtrDownTime);    // сохраняем время сформированного экстремума   
               prevJumper = jumper;   
              //  Generate                               // здесь будем генерить событие, что сформировался новый экстремум
              } 
            jumper = 1;
            indexPrevUp = i;  // обновляем предыдущий индекс             
           }
          // если обновился нижний экстремум
          if (extrLow.time >= time[i])
           {        
            bufferAllExtrLow[i] = extrLow.price;
            bufferFormedExtrLow[i] = extrLow.price;  
            bufferTimeExtrLow[i] = double(extrLow.time);
            lastExtrDownValue = extrLow.price;
            lastExtrDownTime  = extrLow.time;
            //Comment("экстр LOW время = ",TimeToString(extrLow.time) );            
            //Generate                                   // здесь будем генерить событие появления нового экстремума
            if (jumper == 1)
             {
              bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue; // сохраняем сформированный экстремум
              bufferTimeExtrHigh[indexPrevUp] = double(lastExtrUpTime);  // сохраняем время сформированного экстремума        
              prevJumper = jumper;
              //Generate                                 // здесь будем генерить событие, что сформировался новый экстремум
             }
            jumper = -1;
            indexPrevDown = i; // обновляем предыдущий индекс
           }
           
        }
      }
      lastBarTime = time[rates_total-1];   // сохраняем время последнего бара
     }
    // если в реальном времени
    else
     {              
      // если удалось вычислить экстремум\экстремумы
      if (  extr.isExtremum(extrHigh,extrLow,time[rates_total-1],true) )
       {
        // если обновился верхний экстремум
        if (extrHigh.time >= time[rates_total-1]   )
         {        
          bufferAllExtrHigh[rates_total-1] = extrHigh.price;
          bufferFormedExtrHigh[rates_total-1] = extrHigh.price;  // потом удалить
          bufferTimeExtrHigh[rates_total-1] = double(extrHigh.time);
          lastExtrUpValue = extrHigh.price;
          lastExtrUpTime = extrHigh.time;
          //Comment("экстр HIGH время = ",TimeToString(extrHigh.time) );          
          // генерим событие для всех графиков
          Generate("новый экстремум",eventData,true); 
          
        //  Print("Время = ",TimeToString(lastExtrUpTime)," цена = ",DoubleToString(lastExtrUpValue) );
          if (jumper == -1)
           {
            bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue;        // сохраняем сформированный экстремум
            bufferTimeExtrLow[indexPrevDown] = long(lastExtrDownTime);     // сохраняем время сформированного экстремума
            prevJumper = jumper;
           }
          jumper = 1;
          indexPrevUp = rates_total-1;
         }
        // если обновился нижний экстремум
        if (extrLow.time >= time[rates_total-1])
         {
          bufferAllExtrLow[rates_total-1] = extrLow.price;
          bufferFormedExtrLow[rates_total-1] = extrLow.price;   // потом удалить
          bufferTimeExtrLow[rates_total-1] = double(extrLow.time);
          lastExtrDownValue = extrLow.price;
          lastExtrDownTime = extrLow.time;
          //Comment("экстр LOW время = ",TimeToString(extrLow.time) );             
          // генерим событие для всех графиков
          Generate("новый экстремум",eventData,true);  
         // Print("Время = ",TimeToString(lastExtrDownTime)," цена = ",DoubleToString(lastExtrDownValue) );           
          if (jumper == -1)
           {
            bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue;        // сохраняемт сформированный экстремум
            bufferTimeExtrHigh[indexPrevUp] = long(lastExtrUpTime);     // сохраняем время сформированного экстремума
            prevJumper = jumper;
           }
          jumper = -1;
          indexPrevDown = rates_total-1;
         }
       }       
     }
     
  /*   if (bufferFormedExtrLow[rates_total-1] == 1.31571)
      Comment(" верхний экстремум = ",DoubleToString(bufferFormedExtrHigh[rates_total-1])," ",TimeToString(datetime(bufferTimeExtrHigh[rates_total-1]) ),
              "\n нижний экстремум = ",DoubleToString(bufferFormedExtrLow[rates_total-1])," ",TimeToString(datetime(bufferTimeExtrLow[rates_total-1]) )  
             );
    */ 
   return(rates_total);
  }
   
// дополнительные функции индикатора 

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
         event.Generate(z,id_nam,_data,_is_custom);
        }
      z = ChartNext(z);      
     }     
  }     