//+------------------------------------------------------------------+
//|                                        ProbalisticGarbagePBI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   3
//--- plot ColorCandles
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow

#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW

//----------------------------------------------------------------
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include <ColoredTrend/ColoredTrendNE.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//------------------INPUT-PARAMETRS------------------------------
input int      depth = 1000;         // сколько свечей показывать
input bool     show_top = false;
input double   percentage_ATR_cur = 2;   
input double   difToTrend_cur = 1.5;
input int      ATR_ma_period_cur = 12;
input double   percentage_ATR_top = 2;   
input double   difToTrend_top = 1.5;
input int      ATR_ma_period_top = 12; 
//------------------INDICATOR BUFFERS-----------------------------
double ColorCandlesBuffer1[];
double ColorCandlesBuffer2[];
double ColorCandlesBuffer3[];
double ColorCandlesBuffer4[];
double ColorCandlesColors[];
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];
//-------------------GLOBAL-VARIABLES-----------------------------
int countTCFnormal  = 0;  //TREND->CORRECTION->FLAT->TREND
int countTCFinverse = 0;  //TREND->CORRECTION->FLAT->TREND_inverse
int countTCnormal   = 0;  //TREND->CORRECTION->TREND_inverse
int countTCinverse  = 0;  //TREND->CORRECTION->TREND_inverse
int countTFnormal   = 0;  //TREND->FLAT->TREND_inverse
int countTFinverse  = 0;  //TREND->FLAT->TREND_inverse


CisNewBar NewBarBottom,
          NewBarCurrent, 
          NewBarTop;

CColoredTrend *trend, 
              *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init");
   symbol = Symbol();
   current_timeframe = Period();
   NewBarBottom.SetPeriod(GetBottomTimeframe(current_timeframe));
   NewBarCurrent.SetLastBarTime(current_timeframe);
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   //PrintFormat("TOP = %s, BOTTOM = %s", EnumToString((ENUM_TIMEFRAMES)NewBarTop.GetPeriod()), EnumToString((ENUM_TIMEFRAMES)NewBarBottom.GetPeriod()));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), depth, percentage_ATR_top, difToTrend_top, ATR_ma_period_top);
   trend    = new CColoredTrend(symbol,                  current_timeframe, depth, percentage_ATR_cur, difToTrend_cur, ATR_ma_period_cur);
//--- indicator buffers mapping
   SetIndexBuffer(0,ColorCandlesBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ColorCandlesBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ColorCandlesBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ColorCandlesBuffer4,INDICATOR_DATA);
   SetIndexBuffer(4,ColorCandlesColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);

   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   
   ArraySetAsSeries(ColorCandlesBuffer1, false);
   ArraySetAsSeries(ColorCandlesBuffer2, false);
   ArraySetAsSeries(ColorCandlesBuffer3, false);
   ArraySetAsSeries(ColorCandlesBuffer4, false);

   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);
   SavePorabolistic("statictic_PBI.txt");
   ArrayInitialize(ExtUpArrowBuffer, 0);
   ArrayInitialize(ExtDownArrowBuffer, 0); 
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
   topTrend.Zeros();
   trend.Zeros();
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
   static int start_index = 0;
   static int start_iteration = 0;
   static datetime start_time;
   static int buffer_index = 0;
   static int top_buffer_index = 0;
   SExtremum extr_cur = {0, -1};
   SExtremum extr_top = {0, -1};
   
   int seconds_current = PeriodSeconds(current_timeframe);
   int seconds_top = PeriodSeconds(GetTopTimeframe(current_timeframe));

   if(prev_calculated == 0) 
   {
    Print("Первый расчет индикатора");
    buffer_index = 0;
    top_buffer_index = 0;
    start_index = rates_total - depth;
    start_time = TimeCurrent() - depth*seconds_current;
    start_iteration = rates_total - depth;
    topTrend.Zeros();
    trend.Zeros();
    ArrayInitialize(ColorCandlesBuffer1, 0);
    ArrayInitialize(ColorCandlesBuffer2, 0);
    ArrayInitialize(ColorCandlesBuffer3, 0);
    ArrayInitialize(ColorCandlesBuffer4, 0);
   }
   else 
   { 
    //buffer_index = prev_calculated - start_index;
    start_iteration = start_index + buffer_index - 1;//prev_calculated-1;
   }
   
   bool error = true;
   
   for(int i = 0; i < (rates_total-start_iteration)/(seconds_top/seconds_current);i++)
   {
     error = topTrend.CountMoveType(i, (int)((rates_total-start_iteration)/(seconds_top/seconds_current)-i), extr_top);
     //PrintFormat("top_buffer_index = %d, start_pos_top = %d, extr_top = {%d;%.05f}", top_buffer_index, start_pos_top, extr_top.direction, extr_top.price);
     if(!error)
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR ON TOP TIMEFRAME");
      return(0);
     }
   }
     
   for(int i =  start_iteration; i < rates_total;  i++)    
   {
    //PrintFormat("start_iteration = %d; rates_total = %d, bi = %d, tbi = %d", start_iteration, rates_total, buffer_index, top_buffer_index);
    int start_pos_top = GetNumberOfTopBarsInCurrentBars(current_timeframe, depth) - top_buffer_index;
    int start_pos_cur = (buffer_index < depth) ? (rates_total-1) - i : 0; 
    if(start_pos_top < 0) start_pos_top = 0;
       
    error = trend.CountMoveType(buffer_index, start_pos_cur, extr_cur, topTrend.GetMoveType(top_buffer_index));
    if(!error) 
    {
     Print("YOU NEED TO WAIT FOR THE NEXT BAR ON CURRENT TIMEFRAME");
     return(0);
    } 
    
    CalculateProbalistic(trend.GetMoveType(buffer_index));
    
    ColorCandlesBuffer1[i] = open[i];
    ColorCandlesBuffer2[i] = high[i];
    ColorCandlesBuffer3[i] = low[i];
    ColorCandlesBuffer4[i] = close[i]; 
    ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
        
    if(buffer_index < depth)
    {
     buffer_index++;
     top_buffer_index = (start_time + seconds_current*buffer_index)/seconds_top - start_time/seconds_top;
    }
    //if(buffer_index == depth-1)
     //PrintFormat("TCF = %d; TCFi = %d; TF = %d; TFi = %d; TC = %d; TCi = %d;", countTCFnormal, countTCFinverse, countTFnormal, countTFinverse, countTCnormal, countTCinverse);
   }
  
   if(NewBarCurrent.isNewBar() > 0 && prev_calculated != 0)
   {
    buffer_index++;
   }
   
   if(NewBarTop.isNewBar() > 0 && prev_calculated != 0)
   {
    top_buffer_index++;
   }
   
   return(rates_total);
  }
  
  int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe, int current_bars)
  {
   return ((current_bars*PeriodSeconds(timeframe))/PeriodSeconds(GetTopTimeframe(timeframe)));
  }
//+------------------------------------------------------------------+

void CalculateProbalistic (ENUM_MOVE_TYPE type)
{
 static ENUM_MOVE_TYPE combination[4] = {MOVE_TYPE_UNKNOWN, MOVE_TYPE_UNKNOWN, MOVE_TYPE_UNKNOWN, MOVE_TYPE_UNKNOWN};
 static int count = 0;
 static ENUM_MOVE_TYPE previous_move = MOVE_TYPE_UNKNOWN;
 
 if(type != previous_move)
 {
  if(count == 0 && (previous_move == MOVE_TYPE_TREND_UP || previous_move == MOVE_TYPE_TREND_DOWN))
  {
   combination[count] = previous_move;
   count++;
  } 
  combination[count] = type;
  previous_move = type;
  count++;
  //PrintFormat("previous = %s ; new = %s; count = %d", MoveTypeToString(previous_move), MoveTypeToString(type), count);
  //PrintFormat("[0] = %s; [1] = %s; [2] = %s; [3] = %s", MoveTypeToString(combination[0]), MoveTypeToString(combination[1]), MoveTypeToString(combination[2]), MoveTypeToString(combination[3]));
 }

 if(count == 1)
 {
  if(combination[0] == MOVE_TYPE_FLAT)
  {
   count = 0;
  }
 }
 
 if(count == 3)    // Модель TREND->FLAT->TREND OR TREND_inverse
                   // Модель TREND->CORRECTION->TREND OR TREND_inverse
 {
  if(combination[0] == MOVE_TYPE_TREND_UP || combination[0] == MOVE_TYPE_TREND_UP_FORBIDEN)
  {
   if(combination[1] == MOVE_TYPE_CORRECTION_DOWN)
   {
    if(combination[2] == MOVE_TYPE_TREND_UP || combination[2] == MOVE_TYPE_TREND_UP_FORBIDEN)
    {
     countTCnormal++;
     count = 0;
    }
    else if(combination[2] == MOVE_TYPE_TREND_DOWN || combination[2] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
    {
     countTCinverse++;
     count = 0;
    }
   }
   else if(combination[1] == MOVE_TYPE_FLAT)
   {
    if(combination[2] == MOVE_TYPE_TREND_UP || combination[2] == MOVE_TYPE_TREND_UP_FORBIDEN)
    {
     countTFnormal++;
     count = 0;
    }
    else if(combination[2] == MOVE_TYPE_TREND_DOWN || combination[2] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
    {
     countTFinverse++;
     count = 0;
    }
   }
  }
  else if(combination[0] == MOVE_TYPE_TREND_DOWN || combination[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
  {
   if(combination[1] == MOVE_TYPE_CORRECTION_UP)
   {
    if(combination[2] == MOVE_TYPE_TREND_DOWN || combination[2] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
    {
     countTCnormal++;
     count = 0;
    }
    else if(combination[2] == MOVE_TYPE_TREND_UP || combination[2] == MOVE_TYPE_TREND_UP_FORBIDEN)
    {
     countTCinverse++;
     count = 0;
    }
   }
   else if(combination[1] == MOVE_TYPE_FLAT)
   {
    if(combination[2] == MOVE_TYPE_TREND_DOWN || combination[2] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
    {
     countTFnormal++;
     count = 0;
    }
    else if(combination[2] == MOVE_TYPE_TREND_UP || combination[2] == MOVE_TYPE_TREND_UP_FORBIDEN)
    {
     countTFinverse++;
     count = 0;
    }
   }
  }
  
 }
 
 if(count == 4) // Модель TREND->CORRECTION->FLAT->TREND OR TREND_inverse
 {
  if((combination[0] == MOVE_TYPE_TREND_UP || combination[0] == MOVE_TYPE_TREND_UP_FORBIDEN) && combination[1] == MOVE_TYPE_CORRECTION_DOWN && combination[2] == MOVE_TYPE_FLAT)
  {
   if(combination[3] == MOVE_TYPE_TREND_UP || combination[3] == MOVE_TYPE_TREND_UP_FORBIDEN)
   {
    countTCFnormal++;
   }
   else if(combination[3] == MOVE_TYPE_TREND_DOWN || combination[3] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
   {
    countTCFinverse++;
   }
  }
  else if((combination[0] == MOVE_TYPE_TREND_DOWN || combination[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && combination[1] == MOVE_TYPE_CORRECTION_UP && combination[2] == MOVE_TYPE_FLAT)
  {
   if(combination[3] == MOVE_TYPE_TREND_DOWN || combination[3] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
   {
    countTCFnormal++;
   }
   else if(combination[3] == MOVE_TYPE_TREND_UP || combination[0] == MOVE_TYPE_TREND_UP_FORBIDEN)
   {
    countTCFinverse++;
   }
  }
  count = 0;
 }
 //PrintFormat("TCF = %d; TCFi = %d; TF = %d; TFi = %d; TC = %d; TCi = %d;", countTCFnormal, countTCFinverse, countTFnormal, countTFinverse, countTCnormal, countTCinverse);
 if(count == 0)
 {
  combination[0] = MOVE_TYPE_UNKNOWN;
  combination[1] = MOVE_TYPE_UNKNOWN;
  combination[2] = MOVE_TYPE_UNKNOWN;
  combination[3] = MOVE_TYPE_UNKNOWN;
 }
}

void SavePorabolistic(string filename)
{
 int file_handle = FileOpen(filename, FILE_WRITE|FILE_ANSI|FILE_TXT|FILE_COMMON);
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  Alert("Ошибка открытия файла");
 }
 
 FileWriteString(file_handle, StringFormat("%s %s %s %s\r\n", __FILE__, EnumToString(Period()), Symbol(), TimeToString(TimeCurrent())));
 FileWriteString(file_handle, StringFormat("Parametrs: depth = %d\r\n", depth));
 FileWriteString(file_handle, StringFormat("CURRENT TF: percentage ATR = %.03f, ATR ma period = %d, dif to trend = %.03f\r\n", percentage_ATR_cur, ATR_ma_period_cur, difToTrend_cur));
 //FileWriteString(file_handle, StringFormat("    TOP TF: percentage ATR = %.03f, ATR ma period = %d, dif to trend = %.03f\r\n", percentage_ATR_top, ATR_ma_period_top, difToTrend_top));
 FileWriteString(file_handle, "Ситуации развития тренда: \r\n");
 FileWriteString(file_handle, StringFormat("TREND->CORRECTION->FLAT->TREND = %d; TREND->CORRECTION->FLAT->TREND(inverse) = %d\r\n", countTCFnormal, countTCFinverse));
 FileWriteString(file_handle, StringFormat("TREND->CORRECTION->TREND = %d; TREND->CORRECTION->TREND(inverse) = %d\r\n", countTCnormal, countTCinverse));
 FileWriteString(file_handle, StringFormat("TREND->FLAT->TREND = %d; TREND->FLAT->TREND(inverse) = %d\r\n", countTFnormal, countTFinverse));
 FileWriteString(file_handle, StringFormat("Выход из модели TFCT в ту же сторону происходит в %f % и в %f % случаев в обратную\r\n", 100*(countTCFnormal)/(countTCFnormal+countTCFinverse), 100*(countTCFinverse)/(countTCFnormal+countTCFinverse)));
 FileWriteString(file_handle, StringFormat("Выход из модели TCT в ту же сторону происходит в %f % и в %f % случаев в обратную\r\n", 100*(countTCnormal)/(countTCnormal+countTCinverse), 100*(countTCinverse)/(countTCnormal+countTCinverse)));
 FileWriteString(file_handle, StringFormat("Выход из модели TFT в ту же сторону происходит в %f % и в %f % случаев в обратную\r\n", 100*(countTFnormal)/(countTFnormal+countTFinverse), 100*(countTFinverse)/(countTFnormal+countTFinverse)));
 FileClose(file_handle); 
}
