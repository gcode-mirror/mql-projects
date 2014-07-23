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
#include <DrawExtemums/CDrawExtremums.mqh>
#include <CExtremum.mqh>
#include <Lib CisNewBarDD.mqh>
#include <CLog.mqh>
#include <StringUtilities.mqh>
//----------------------------------------------------------------
 
//--- input параметры
input  ENUM_TIMEFRAMES period     = PERIOD_H4;   // период экстремумов
input  int     history_depth      = 1000;        // сколько свечей показывать
input  int     period_ATR         = 30;          // период ATR
input  int     period_average_ATR = 30;           // период устреднения индикатора ATR
input  int     codeSymbol         = 217;         // код символа

//--- индикаторные буферы
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];

int indexPrevUp   = -1;                      // индекс последнего верхнего экстремума, которого нужно затереть
int indexPrevDown = -1;                      // индекс последнего нижнего экстремума, которого нужно затереть 
int jumper        = 0;                       // переменная-попрыгун. ня ^_^

double lastExtrUpValue;                      // значение последнего экстремума
double lastExtrDownValue;                    // значение последнего экстемума   

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
   if(Bars(symbol, period) < depth) depth = Bars(symbol, period);
   PrintFormat("Глубина поиска равна: %d", depth);
   NewBarCurrent.SetPeriod(period);
   ENUM_TIMEFRAMES per;

   handle_ATR = iCustom(Symbol(),period,"AverageATR",period_ATR,period_average_ATR); 
   if (handle_ATR == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать хэндл индикатора AverageATR");
     return (INIT_FAILED);
    }      
    
   extr = new CExtremum(Symbol(), Period(),handle_ATR/*, per, period_ATR, percentage_ATR*/);
 //  handle_ATR = iCustom(Symbol(), per,"AverageATR",
 //  handle_ATR = iATR(Symbol(), per, period_ATR);

//--- indicator buffers mapping
   SetIndexBuffer(0, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtDownArrowBuffer, INDICATOR_DATA);

   ArrayInitialize(ExtUpArrowBuffer   , 0);
   ArrayInitialize(ExtDownArrowBuffer , 0);

   PlotIndexSetInteger(0, PLOT_ARROW, codeSymbol+1);
   PlotIndexSetInteger(1, PLOT_ARROW, codeSymbol);
   
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
   
   if(prev_calculated == 0) 
   {
   if (BarsCalculated(handle_ATR) < 1)
    {
    return (0);
    }
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);   
   
   PrintFormat("%s Первый расчет индикатора", __FUNCTION__);
    
   ArrayInitialize(ExtUpArrowBuffer   , 0);
   ArrayInitialize(ExtDownArrowBuffer , 0);
   //Print("DRAW EXTREMUMS: N = ",IntegerToString(ArraySize(time))," DEPTH = ",IntegerToString(depth));
   NewBarCurrent.isNewBar(time[depth]);
   
   for(int i = depth-1; i >= 0;  i--)    
   {
    RecountUpdated(time[i], false, extr_cur);
    if (extr_cur[0].direction > 0)
    {
     
    // ExtUpArrowBuffer[i] = extr_cur[0].price;
     lastExtrUpValue = extr_cur[0].price;
     if (jumper == -1)
      {
       ExtDownArrowBuffer[indexPrevDown] = lastExtrDownValue;
      }
     jumper = 1;
     indexPrevUp = i;  // обновляем предыдущий индекс
     extr_cur[0].direction = 0;
    }
    if (extr_cur[1].direction < 0)
    {
    
   //  ExtDownArrowBuffer[i] = extr_cur[1].price;
     lastExtrDownValue = extr_cur[1].price;
     if (jumper == 1)
      {
       ExtUpArrowBuffer[indexPrevUp] = lastExtrUpValue;
      }
     jumper = -1;
     indexPrevDown = i;  // обновляем предыдущий индекс      
     extr_cur[1].direction = 0;
    }
   }
   // переворачиваем индексы
   indexPrevDown = rates_total - 1 - indexPrevDown;
   indexPrevUp   = rates_total - 1 - indexPrevUp;
   PrintFormat("%s Первый расчет индикатора ОКОНЧЕН.", __FUNCTION__);
   return (rates_total);
  }
   
   //PrintFormat("buffer_index = %d; time = %s;", buffer_index, TimeToString(time[0]));   
   RecountUpdated(time[rates_total-1], true, extr_cur);
   
   ArraySetAsSeries(ExtUpArrowBuffer   , false);
   ArraySetAsSeries(ExtDownArrowBuffer , false);
     
   if (extr_cur[0].direction > 0)
   {
    lastExtrUpValue = extr_cur[0].price;
    if (jumper == -1)
    {
     ExtDownArrowBuffer[indexPrevDown] = lastExtrDownValue; 
    }
    jumper = 1;
    indexPrevUp = rates_total-1;  // обновляем предыдущий индекс
    extr_cur[0].direction = 0;    
   }
   
   if (extr_cur[1].direction < 0)
   {
    lastExtrDownValue = extr_cur[1].price;
    if (jumper == 1)
    {
     ExtUpArrowBuffer[indexPrevUp] = lastExtrUpValue;
    }
    jumper = -1;
    indexPrevDown = rates_total-1;  // обновляем предыдущий индекс      
    extr_cur[1].direction = 0;    
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