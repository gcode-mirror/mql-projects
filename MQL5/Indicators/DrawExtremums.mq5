//+------------------------------------------------------------------+
//|                                                DrawExtremums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW

//----------------------------------------------------------------
#include <CompareDoubles.mqh>
#include <CExtremum.mqh>
#include <Lib CisNewBarDD.mqh>
#include <CLog.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input int      history_depth = 1000; // сколько свечей показывать
input double   percentage_ATR = 1;   // процент АТР для появления нового экстремума
//--- индикаторные буферы
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];

CisNewBar NewBarCurrent;
CExtremum *extr;
int handle_ATR;
              
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int      period_ATR = 30;      // период ATR
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
   current_timeframe = Period();
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
   handle_ATR = iATR(Symbol(), per, period_ATR);
//--- indicator buffers mapping
   SetIndexBuffer(0,    ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1,  ExtDownArrowBuffer, INDICATOR_DATA);

   ArrayInitialize(ExtUpArrowBuffer   , 0);
   ArrayInitialize(ExtDownArrowBuffer , 0);
   
   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217);
   
   ArraySetAsSeries(   ExtUpArrowBuffer, series_order);   
   ArraySetAsSeries( ExtDownArrowBuffer, series_order);
   
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
      extr_cur[0].direction = 0;
     }
     if (extr_cur[1].direction < 0)
     {
      ExtDownArrowBuffer[i] = extr_cur[1].price;// - 50*_Point;
      extr_cur[1].direction = 0;
     }
    }
    PrintFormat("%s Первый расчет индикатора ОКОНЧЕН.", __FUNCTION__);
   }
   
   //PrintFormat("buffer_index = %d; time = %s;", buffer_index, TimeToString(time[0]));   
   RecountUpdated(time[0], true, extr_cur);
    
   if (extr_cur[0].direction > 0)
   {
    ExtUpArrowBuffer[0] = extr_cur[0].price;// + 50*_Point;
    extr_cur[0].direction = 0;
   }
   if (extr_cur[1].direction < 0)
   {
    ExtDownArrowBuffer[0] = extr_cur[1].price;// - 50*_Point;
    extr_cur[1].direction = 0;
   }

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