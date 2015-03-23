//+------------------------------------------------------------------+
//|                                                    PBI_SHARP.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW

// подключаем необходимые библиотеки
#include <CompareDoubles.mqh>                             // для сравнения вещественных чисел
#include <Lib CisNewBarDD.mqh>                            // для появления нового бара
#include <ColoredTrend/ColoredTrendWithNewExtremums.mqh>  // класс CColoredTrend
#include <ColoredTrend/ColoredTrendUtilities.mqh>         // константы и перечисления CColoredTrend
#include <DrawExtremums/CExtrContainer.mqh>               // контейнер экстремумов
#include <SystemLib/IndicatorManager.mqh>                 // библиотека по работе с индикаторами
#include <CEventBase.mqh>                                 // для генерации событий   
#include <CLog.mqh>                                       // для лога

// входные параметры
input int  depth_history = 100;                           // глубина истории      
input bool show_top  = false;                             // показывать текущий таймфрейм или старший
input bool is_it_top = false;                             // если true вычисляется только текущий таймфрейм; false вычислятеся дополнительный индикатор для старшего таймфрейма

// индикаторные буферы
double ColorCandlesBuffer1[];
double ColorCandlesBuffer2[];
double ColorCandlesBuffer3[];
double ColorCandlesBuffer4[];
double ColorCandlesColors[];
double ColorCandlesColorsTop[];

int i,count;
string str="";
SExtremum extr;

// системные параменные индикатора               
int  depth = depth_history;           // переменная для хранения глубины истории
int  extrCount;                       // количество экстремумов на истории
bool uploadedSuc=false;               // флаг успешной загрузки экстремумов
bool trendCalculated=false;           // флаг перерасчета тренда
// хэндлы индикаторов
int handleDE;                         // хэндл DrawExtremums
int handle_top_trend;                 // хэндл старшего таймфрейма
int handle_atr;                       // хэндл ATR
// дополнительные переменные
double last_move;                     // последнее движение
// объекты классов
CExtrContainer *container;            // контейнер экстремумов
CisNewBar NewBarCurrent;              // для формирования нового бара
CColoredTrend *trend;                 // тип ценового движения
CEventBase *event;                    // для генерации событий 
SEventData eventData;                 // структура полей событий

int OnInit()
  {      
   // привязка индикатора DrawExtremums 
   handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol,_Period,handleDE);
    }   
   // выделяем память под объект класса для доступа     
   container = new CExtrContainer(_Symbol,_Period,handleDE);
   if ( container == NULL )
    {
     Print("Ошибка при инициализации индикатора PriceBasedIndicator. Не удалось создать объект класса CExtrContainer");
     return (INIT_FAILED);
    }

   // создаем объект генерации событий 
   event = new CEventBase(300);
   if (event == NULL)
    {
     Print("Ошибка при инициализации индикатора PriceBasedIndicator. Не удалось создать объект класса CEventBase");
     return (INIT_FAILED);
    }
   // создаем события
   event.AddNewEvent(_Symbol,_Period,"смена движения"); 
  
   if(Bars(_Symbol,_Period) < depth) depth = Bars(_Symbol,_Period)-1;
   PrintFormat("Глубина поиска равна: %d", depth);
   
   NewBarCurrent.SetPeriod(_Period);
   handle_atr = iMA(_Symbol,_Period, 100, 0, MODE_EMA, iATR(_Symbol,_Period, 30));
   trend = new CColoredTrend(_Symbol,_Period, handle_atr, depth,container);
   if(!is_it_top) handle_top_trend = iCustom(_Symbol, GetTopTimeframe(_Period), "PBIWithNewExtremums", depth, false, true);

   SetIndexBuffer(0, ColorCandlesBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ColorCandlesBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ColorCandlesBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ColorCandlesBuffer4, INDICATOR_DATA);
   
   if(show_top)    //выбор раскраску с какого таймфрейма мы показываем: current или top
   {
    SetIndexBuffer(4, ColorCandlesColorsTop, INDICATOR_DATA);
    SetIndexBuffer(5, ColorCandlesColors,    INDICATOR_CALCULATIONS);
   }
   else
   {
    SetIndexBuffer(4, ColorCandlesColors,    INDICATOR_DATA);
    SetIndexBuffer(5, ColorCandlesColorsTop, INDICATOR_CALCULATIONS);
   }

   InitializeIndicatorBuffers();
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   PlotIndexSetInteger(3, PLOT_ARROW, 234);
   PlotIndexSetInteger(4, PLOT_ARROW, 233);
   
   ArraySetAsSeries(ColorCandlesBuffer1,   true);
   ArraySetAsSeries(ColorCandlesBuffer2,   true);
   ArraySetAsSeries(ColorCandlesBuffer3,   true);
   ArraySetAsSeries(ColorCandlesBuffer4,   true);
   ArraySetAsSeries(ColorCandlesColors,    true);
   ArraySetAsSeries(ColorCandlesColorsTop, true);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
{
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason," период =  ",PeriodToString(_Period));
   ArrayFree(ColorCandlesBuffer1);
   ArrayFree(ColorCandlesBuffer2);
   ArrayFree(ColorCandlesBuffer3);
   ArrayFree(ColorCandlesBuffer4);
   ArrayFree(ColorCandlesColors);
   ArrayFree(ColorCandlesColorsTop);
   if(!is_it_top) IndicatorRelease(handle_top_trend);
   IndicatorRelease(handleDE);
   IndicatorRelease(handle_atr);
   delete trend;
   delete container;
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
   static int buffer_index = 0;
   double buffer_top_trend[1] = {MOVE_TYPE_UNKNOWN};  // масссив для хранения типа движения на старшем таймфреме
   int countMoveTypeEvent;
   
   // переворачиваем индексацию массивов как в таймсерии
   ArraySetAsSeries(open , true);
   ArraySetAsSeries(high , true);
   ArraySetAsSeries(low  , true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time , true);
   
   if(prev_calculated == 0) // расчет раскраски на истории
   {
    PrintFormat("%s Первый расчет индикатора", MakeFunctionPrefix(__FUNCTION__));
    buffer_index = 0;
    trend.Zeros();
    InitializeIndicatorBuffers();
    //depth = rates_total;
    NewBarCurrent.isNewBar(time[depth]);
      
    for(int i = depth-1; i >= 0;  i--)    
    {
     if(!is_it_top) 
      if(CopyBuffer(handle_top_trend, 4, time[i], 1, buffer_top_trend) < 1)
      {
       PrintFormat("%s Не удалось подгрузить значения TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)_Period), GetLastError());
       return(0);
      }       
       
       // пытаемся добавить экстремумы если это возможно
       container.AddNewExtr(time[i]);    
       // получаем событие от метода вычисления движения
       trend.CountMoveType(buffer_index, time[i], (ENUM_MOVE_TYPE)buffer_top_trend[0]);
       
       ColorCandlesBuffer1[i]   = open[i];
       ColorCandlesBuffer2[i]   = high[i];
       ColorCandlesBuffer3[i]   = low[i];
       ColorCandlesBuffer4[i]   = close[i];       
       ColorCandlesColors[i]    = trend.GetMoveType(buffer_index); 
       ColorCandlesColorsTop[i] = buffer_top_trend[0];   
                                                                                                
     if(NewBarCurrent.isNewBar(time[i])) 
     {
      buffer_index++;     //для того что бы считать на истории
     }     
    }
    // сохраняем последнее движение
    last_move = ColorCandlesColors[0]; 
    PrintFormat("%s Первый расчет индикатора ОКОНЧЕН", MakeFunctionPrefix(__FUNCTION__));
   }  
   // рассчет индикатора в реальном времени
          
      // вычисление типа движения в текущий момент
      if(!is_it_top && CopyBuffer(handle_top_trend, 4, time[0], 1, buffer_top_trend) < 1)
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s/%s Не удалось подгрузить значения TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)_Period), EnumToString((ENUM_TIMEFRAMES)GetTopTimeframe(_Period)), GetLastError()));
      } 
      
      // если тренд не был обновлен
      if (!trendCalculated)
          trend.ZeroTrend();  // то обнуляем тренд
        
     /* if (container.AddNewExtr(TimeCurrent()))   
        {         
         // обновляем экстремумы         
         if (trend.UpdateExtremums()==1)
          {
           trend.CountTrend();   
          }
        } 
     */  
           
      // вычисляем текущее движение в реальном времени 
      trend.CountMoveTypeA(buffer_index, time[0], (ENUM_MOVE_TYPE)buffer_top_trend[0]);
      // сбрасываем флаг того, что тренд вычислялся
      trendCalculated = false;
      // заполняем буферы
      ColorCandlesBuffer1[0]   = open[0];
      ColorCandlesBuffer2[0]   = high[0];
      ColorCandlesBuffer3[0]   = low [0];
      ColorCandlesBuffer4[0]   = close[0]; 
      ColorCandlesColors[0]    = trend.GetMoveType(buffer_index);
      ColorCandlesColorsTop[0] = buffer_top_trend[0];
      
      // если движение изменилось, генерим соответствующее событие
      if (ColorCandlesColors[0] != last_move)
       {
        // то обновляем последнее движение
        last_move = ColorCandlesColors[0];
        eventData.dparam = last_move;
        Generate("смена движения",eventData,true);
       }
       
      if(NewBarCurrent.isNewBar() && prev_calculated != 0)
      {
       buffer_index++; 
      }
       
   return (rates_total);
  }

void InitializeIndicatorBuffers()
{
 Print("Обнулили буфера");
 ArrayInitialize(ColorCandlesBuffer1, 0);
 ArrayInitialize(ColorCandlesBuffer2, 0);
 ArrayInitialize(ColorCandlesBuffer3, 0);
 ArrayInitialize(ColorCandlesBuffer4, 0);
 ArrayInitialize(ColorCandlesColors , 0);
 ArrayInitialize(ColorCandlesColorsTop, 0);
}

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   // пришло событие "пришел новый экстремум"
   if (sparam == "экстремум")
    {
     // догружаем контейнер новыми экстремумами. И если успешно загрузили экстремумы
     container.AddExtrToContainer(lparam,dparam,TimeCurrent());
     //if (container.AddNewExtr(TimeCurrent() ))
      //{
       // если удалось обновить экстремумы
       if (trend.UpdateExtremums()==1)
        {
         // рассчитываем тренд
         trend.CountTrend();
         // выставляем флаг того, что тренд был пересчитан
         trendCalculated = true;
        }
      ///}
    }
   
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
  