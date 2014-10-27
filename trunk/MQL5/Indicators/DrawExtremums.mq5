//+------------------------------------------------------------------+
//|                                                DrawExtremums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6
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
//--- индикаторные буферы
double ExtUpArrowBuffer[];                       // буфер верхних экстремумов
double ExtDownArrowBuffer[];                     // буфер нижних экстремумов
double LastExtrSignal[];                         // сигнал формирующегося экстремума
double PrevExtrSignal[];                         // сигнал сформированного экстремума
double ExtrNumberHigh[];                         // буфер счетчик экстремумов HIGH
double ExtrNumberLow[];                          // буфер счетчки экстремумов LOW

int indexPrevUp   = -1;                          // индекс последнего верхнего экстремума, которого нужно затереть
int indexPrevDown = -1;                          // индекс последнего нижнего экстремума, которого нужно затереть 
int jumper        = 0;                           // переменная-попрыгун. ня ^_^
int prevJumper    = 0;                           // предыдущее значение переменной-попгрыгуна, и опять таки 
int countExtrHigh = 0;                           // счетчик экстремумов HIGH
int countExtrLow  = 0;                           // счетчки экстремумов LOW
int history_depth = 0;
double lastExtrUpValue;                          // значение последнего экстремума
double lastExtrDownValue;                        // значение последнего экстемума   

CisNewBar NewBarCurrent;
CExtremum *extr;
int handle_ATR;
              
string symbol;
ENUM_TIMEFRAMES current_timeframe;
ENUM_TIMEFRAMES tf_ATR = PERIOD_H4; // таймфрейм ATR
bool series_order = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   PrintFormat("%s Init", __FUNCTION__);
   symbol = Symbol();
   //if(Bars(symbol, _Period) < history_depth)
   history_depth = Bars(symbol, _Period);
   PrintFormat("Глубина поиска равна: %d", history_depth);
   NewBarCurrent.SetPeriod(_Period);

   handle_ATR = iMA(Symbol(), _Period, 100, 0, MODE_EMA, iATR(Symbol(), _Period, 30));
   if (handle_ATR == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать хэндл индикатора AverageATR");
     return (INIT_FAILED);
    }      
    
   extr = new CExtremum(_Symbol, _Period, handle_ATR);

//--- indicator buffers mapping
   SetIndexBuffer(0, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtDownArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LastExtrSignal,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, PrevExtrSignal,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, ExtrNumberHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, ExtrNumberLow,INDICATOR_CALCULATIONS);

   ArrayInitialize(ExtUpArrowBuffer   , 0);
   ArrayInitialize(ExtDownArrowBuffer , 0);
   ArrayInitialize(LastExtrSignal, 0);
   ArrayInitialize(PrevExtrSignal, 0);
   ArrayInitialize(ExtrNumberHigh,0);
   ArrayInitialize(ExtrNumberLow,0);

   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217);
   
   ArraySetAsSeries( ExtUpArrowBuffer,    series_order);   
   ArraySetAsSeries( ExtDownArrowBuffer,  series_order);
   ArraySetAsSeries( LastExtrSignal,      true);
   ArraySetAsSeries( PrevExtrSignal,      true);
   ArraySetAsSeries( ExtrNumberHigh,      true);
   ArraySetAsSeries( ExtrNumberLow,       true);
   
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   ArrayFree(ExtUpArrowBuffer);
   ArrayFree(ExtDownArrowBuffer);
   ArrayFree(LastExtrSignal);
   ArrayFree(PrevExtrSignal);
   ArrayFree(ExtrNumberHigh);
   ArrayFree(ExtrNumberLow);
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

   NewBarCurrent.isNewBar(time[history_depth-1]);
   
   for(int i = history_depth - 1; i >= 0;  i--)    
   {
    RecountUpdated(time[i], false, extr_cur);
    if (extr_cur[0].direction > 0)
    {     
     lastExtrUpValue = extr_cur[0].price;
     if (jumper == -1)
      {
       ExtDownArrowBuffer[indexPrevDown] = lastExtrDownValue;
       countExtrLow ++;     // увеличиваем количество экстремумов HIGH    
       prevJumper = jumper;   
      }
     jumper = 1;
     indexPrevUp = i;  // обновляем предыдущий индекс
     extr_cur[0].direction = 0;
    }
    if (extr_cur[1].direction < 0)
    {
    // ExtDownArrowBuffer[i] = extr_cur[1].price;
     lastExtrDownValue = extr_cur[1].price;
     if (jumper == 1)
      {
       ExtUpArrowBuffer[indexPrevUp] = lastExtrUpValue;
       countExtrHigh ++;       // увеличиваем количество экстремумов LOW     
       prevJumper = jumper;
      }
     jumper = -1;
   
     indexPrevDown = i;  // обновляем предыдущий индекс      
     extr_cur[1].direction = 0;
    }
    ExtrNumberHigh[0] = countExtrHigh;
    ExtrNumberLow[0]  = countExtrLow;    
   }
   // переворачиваем индексы
   indexPrevDown = rates_total - 1 - indexPrevDown;
   indexPrevUp   = rates_total - 1 - indexPrevUp;
   PrintFormat("%s Первый расчет индикатора ОКОНЧЕН.", __FUNCTION__);
   jumper = jumper*-1;
   return (rates_total);
  }
   LastExtrSignal[0] = jumper;
   PrevExtrSignal[0] = prevJumper;
   RecountUpdated(time[rates_total-1], true, extr_cur);
   
   ArraySetAsSeries(ExtUpArrowBuffer   , false);
   ArraySetAsSeries(ExtDownArrowBuffer , false);
     
   if (extr_cur[0].direction > 0)
   {
    
    lastExtrUpValue = extr_cur[0].price;

    
    if (jumper == -1)
    {
     ExtDownArrowBuffer[indexPrevDown] = lastExtrDownValue;
     countExtrLow ++;                 // увеличиваем количество экстремумов на единицу  HIGH
     prevJumper = jumper;
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
     countExtrHigh ++;                   // увеличиваем количество экстремумов на единицу LOW      
     prevJumper = jumper;     
    }
    jumper = -1;
    indexPrevDown = rates_total-1;  // обновляем предыдущий индекс        
    extr_cur[1].direction = 0;   
   }
   
   LastExtrSignal[0] = jumper;
   PrevExtrSignal[0] = prevJumper;
   
   ExtrNumberHigh[0] = countExtrHigh;
   ExtrNumberLow [0] = countExtrLow;   
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