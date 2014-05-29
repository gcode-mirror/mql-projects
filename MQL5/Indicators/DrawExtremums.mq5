//+------------------------------------------------------------------+
//|                                                DrawExtremums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_type4   DRAW_LINE 

//----------------------------------------------------------------
#include <CompareDoubles.mqh>
#include <CExtremum.mqh>
#include <Lib CisNewBarDD.mqh>
#include <CLog.mqh>
//----------------------------------------------------------------
 
//--- input параметры

input  bool    useCurrentTimeframe = true;   // флаг использования текущего таймфрейма   
input  ENUM_TIMEFRAMES period = PERIOD_H4;   // период экстремумов
input  int     history_depth  = 1000;        // сколько свечей показывать
input  double  percentage_ATR = 1;           // процент АТР для появления нового экстремума
input  int     period_ATR     = 30;          // период ATR
input  int     period_average_ATR = 1;       // период устреднения индикатора ATR

//--- индикаторные буферы
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];
double LastUpArrowBuffer[];
double LastDownArrowBuffer[];

double lastUpArrow   = 0;                    // последнее значение верхнего экстремума
double lastDownArrow = 0;                    // последнее значение нижнего экстремума

CisNewBar NewBarCurrent;
CExtremum *extr;
int handle_ATR;
              
string symbol;
ENUM_TIMEFRAMES current_timeframe;
ENUM_TIMEFRAMES tf_ATR = PERIOD_H4; // таймфрейм ATR
int depth = history_depth;
bool series_order = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   PrintFormat("%s Init", __FUNCTION__);
   symbol = Symbol();
   if (useCurrentTimeframe)
    current_timeframe = Period();
   else
    current_timeframe = period;
   if(Bars(symbol, current_timeframe) < depth) depth = Bars(symbol, current_timeframe);
   PrintFormat("Глубина поиска равна: %d", depth);
   NewBarCurrent.SetPeriod(current_timeframe);
   ENUM_TIMEFRAMES per;
   if (current_timeframe > tf_ATR)
    {
     per = current_timeframe;
    }
   else
    {
     per = tf_ATR;
    }
    
   extr = new CExtremum(Symbol(), Period(), per, period_ATR, percentage_ATR);
 //  handle_ATR = iCustom(Symbol(), per,"AverageATR",
 //  handle_ATR = iATR(Symbol(), per, period_ATR);
   handle_ATR = iCustom(Symbol(),per,"AverageATR",period_ATR,period_average_ATR); 
   if (handle_ATR == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать хэндл индикатора AverageATR");
     return (INIT_FAILED);
    }  
//--- indicator buffers mapping
   SetIndexBuffer(0, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtDownArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LastUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LastDownArrowBuffer,INDICATOR_DATA);

   ArrayInitialize(ExtUpArrowBuffer   , 0);
   ArrayInitialize(ExtDownArrowBuffer , 0);
   ArrayInitialize(LastUpArrowBuffer,   0);
   ArrayInitialize(LastDownArrowBuffer, 0);
   
   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217);
   
   ArraySetAsSeries(   ExtUpArrowBuffer, series_order);   
   ArraySetAsSeries( ExtDownArrowBuffer, series_order);
   ArraySetAsSeries( LastUpArrowBuffer, series_order);
   ArraySetAsSeries( LastDownArrowBuffer,series_order);
   
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayFree(ExtUpArrowBuffer);
   ArrayFree(ExtDownArrowBuffer);
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
   SExtremum extr_cur[2] = {{0, -1}, {0, -1}};
   
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);
 
   if(prev_calculated == 0) 
   {
    PrintFormat("%s Первый расчет индикатора", __FUNCTION__);
    
    ArrayInitialize(ExtUpArrowBuffer   , 0);
    ArrayInitialize(ExtDownArrowBuffer , 0);
    NewBarCurrent.isNewBar(time[depth]);
    
    for(int i = depth-1; i >= 0;  i--)    
    {
     RecountUpdated(time[i], false, extr_cur);
    
     if (extr_cur[0].direction > 0)
     {
      ExtUpArrowBuffer[i] = extr_cur[0].price;// + 50*_Point;
      lastUpArrow = extr_cur[0].price;
      extr_cur[0].direction = 0;
     }
     if (extr_cur[1].direction < 0)
     {
      ExtDownArrowBuffer[i] = extr_cur[1].price;// - 50*_Point;
      lastDownArrow = extr_cur[1].price;
      extr_cur[1].direction = 0;
     }
      LastDownArrowBuffer[i] = lastDownArrow;
      LastUpArrowBuffer[i]   = lastUpArrow; 
    }
    PrintFormat("%s Первый расчет индикатора ОКОНЧЕН.", __FUNCTION__);
   }
   
   //PrintFormat("buffer_index = %d; time = %s;", buffer_index, TimeToString(time[0]));   
   RecountUpdated(time[0], true, extr_cur);
   
   
    
   if (extr_cur[0].direction > 0)
   {
    ExtUpArrowBuffer[0] = extr_cur[0].price;// + 50*_Point;
    lastUpArrow = extr_cur[0].price;
    extr_cur[0].direction = 0;
   }
   if (extr_cur[1].direction < 0)
   {
    ExtDownArrowBuffer[0] = extr_cur[1].price;// - 50*_Point;
    lastDownArrow = extr_cur[1].price;
    extr_cur[1].direction = 0;
   }
   
   LastDownArrowBuffer[0] = lastDownArrow;
   LastUpArrowBuffer[0]   = lastUpArrow;

   if(NewBarCurrent.isNewBar() && prev_calculated != 0)
   {
     
   }
   
   return(rates_total);
  }
  
  
void RecountUpdated(datetime start_pos, bool now, SExtremum &ret_extremums[])
{
 int count_new_extrs = extr.RecountExtremum(start_pos, now);
 if (count_new_extrs > 0)
 { //В массиве возвращаемых экструмумов на 0 месте стоит max, на месте 1 стоит min
  if(count_new_extrs == 1)
  {
   if(extr.getExtr(0).direction == 1)       ret_extremums[0] = extr.getExtr(0);
   else if(extr.getExtr(0).direction == -1) ret_extremums[1] = extr.getExtr(0);
  }
  
  if(count_new_extrs == 2)
  {
   if(extr.getExtr(0).direction == 1)       { ret_extremums[0] = extr.getExtr(0); ret_extremums[1] = extr.getExtr(1);}
   else if(extr.getExtr(0).direction == -1) { ret_extremums[0] = extr.getExtr(1); ret_extremums[1] = extr.getExtr(0); }
  }     
 }
}