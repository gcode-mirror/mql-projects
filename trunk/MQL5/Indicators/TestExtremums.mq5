//+------------------------------------------------------------------+
//|                                                TestExtremums.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <ExtrLine\HLine.mqh>
#include <Lib CisNewBar.mqh>

input int    period_ATR_channel = 30;   //Период ATR для канала
input double percent_ATR_channel = 0.1; //Ширина канала уровня в процентах от ATR
input double precentageATR_price = 1;    //Процентр ATR для нового экструмумa
input ENUM_TIMEFRAMES period = PERIOD_H1;

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6
//--- plot MainLine
#property indicator_label1  "MainLine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot DifLine
#property indicator_label2  "DifLine"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot MainLine2
#property indicator_label3  "MainLine2"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrAliceBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot DifLine2
#property indicator_label4  "DifLine2"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrAliceBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot MainLine3
#property indicator_label5  "MainLine3"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrBlueViolet
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot DifLine3
#property indicator_label6  "DifLine3"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrBlueViolet
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- indicator buffers
double         MainLineBuffer[];
double         DifLineBuffer[];
double         MainLine2Buffer[];
double         DifLine2Buffer[];
double         MainLine3Buffer[];
double         DifLine3Buffer[];

CExtremumCalc extrCalc (Symbol(), period, precentageATR_price, period_ATR_channel, percent_ATR_channel);
SExtremum sExtr[3];
CisNewBar isNewLevelBar (Symbol(), period);
bool first = true;
 bool series_order = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,MainLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DifLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,MainLine2Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,DifLine2Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,MainLine3Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,DifLine3Buffer,INDICATOR_DATA);
   
   ArrayInitialize(MainLineBuffer , 0);
   ArrayInitialize(DifLineBuffer  , 0);
   ArrayInitialize(MainLine2Buffer, 0);
   ArrayInitialize(DifLine2Buffer , 0);
   ArrayInitialize(MainLine3Buffer, 0);
   ArrayInitialize(DifLine3Buffer , 0);

   ArraySetAsSeries(MainLineBuffer , series_order);
   ArraySetAsSeries(DifLineBuffer  , series_order);
   ArraySetAsSeries(MainLine2Buffer, series_order);
   ArraySetAsSeries(DifLine2Buffer , series_order);
   ArraySetAsSeries(MainLine3Buffer, series_order);
   ArraySetAsSeries(DifLine3Buffer , series_order);
      
   InitializeExtrArray(sExtr);
   CreateExtrLines(sExtr, period , Red);
   
//---
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 ArrayFree(MainLineBuffer);
 ArrayFree(MainLine2Buffer);
 ArrayFree(MainLine3Buffer);
 ArrayFree(DifLineBuffer);
 ArrayFree(DifLine2Buffer);
 ArrayFree(DifLine3Buffer);
  
 DeleteExtrLines (period);
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
   bool load = FillATRBuffer();
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);
 
   if(load)
   {
    if(first)
    {          
     extrCalc.SetStartDayPrice(close[rates_total-1]);
     PrintFormat("Установлены стартдэйпрайс на всех тф");
     
     for(int i = rates_total-2; i >= 0; i--)  //rates_total-2 т.к. идет обращение к i+1 элементу
     {
      while(!FillATRBuffer()) {}
      //PrintFormat("time calc = %s", TimeToString(time[i]));
      if(time[i] % PeriodSeconds(period) == 0) CalcExtr(extrCalc, sExtr, time[i], false);
      
      MainLineBuffer[i]  = sExtr[0].price;
      DifLineBuffer[i]   = sExtr[0].channel;
      MainLine2Buffer[i] = sExtr[1].price;
      DifLine2Buffer[i]  = sExtr[1].channel;
      MainLine3Buffer[i] = sExtr[2].price;
      DifLine3Buffer[i]  = sExtr[2].channel;
      //PrintExtrArray(sExtr, period);      
     }
     
     PrintFormat("%s num0 = {%.05f, %.05f}, num1 = {%.05f, %.05f}, num2 = {%.05f, %.05f}", TimeToString(time[0]), sExtr[0].price, sExtr[0].channel, sExtr[1].price, sExtr[1].channel,sExtr[2].price, sExtr[2].channel);
     MoveExtrLines(sExtr, period);
     PrintFormat("Закончен расчет на истории. (prev_calculated == 0)");
     first = false; 
    }//end prev_calculated == 0
    else
    {
     //for(int i = rates_total - prev_calculated - 1; i >= 0; i--)
     //{
      
      //if(isNewLevelBar.isNewBar() > 0) 
      //{
       //PrintFormat("%s num0 = {%.05f, %.05f}, num1 = {%.05f, %.05f}, num2 = {%.05f, %.05f}", TimeToString(time[0]), sExtr[0].price, sExtr[0].channel, sExtr[1].price, sExtr[1].channel,sExtr[2].price, sExtr[2].channel);
       while(!FillATRBuffer()) {} 
       CalcExtr(extrCalc, sExtr, time[0], true);
       //PrintExtrArray(sExtr, period); 
     // } 
            
      MainLineBuffer[0]  = sExtr[0].price;
      DifLineBuffer[0]   = sExtr[0].channel;
      MainLine2Buffer[0] = sExtr[1].price;
      DifLine2Buffer[0]  = sExtr[1].channel;
      MainLine3Buffer[0] = sExtr[2].price;
      DifLine3Buffer[0]  = sExtr[2].channel;  
     //}
     MoveExtrLines(sExtr, period);
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void InitializeExtrArray (SExtremum &te[])
{
 int size = ArraySize(te);
 for(int i = 0; i < size; i++)
 {
  te[i].price = 0;
  te[i].direction = 0;
  te[i].channel = 0;
 }
}

//---------------------------------------------
// Создание линий
//---------------------------------------------
void CreateExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"one"   , 0, te[0].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"one+"  , 0, te[0].price+te[0].channel, clr, 2);
 HLineCreate(0, name+"one-"  , 0, te[0].price-te[0].channel, clr, 2);
 HLineCreate(0, name+"two"   , 0, te[1].price              , clrAliceBlue, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"two+"  , 0, te[1].price+te[1].channel, clrAliceBlue, 2);
 HLineCreate(0, name+"two-"  , 0, te[1].price-te[1].channel, clrAliceBlue, 2);
 HLineCreate(0, name+"three" , 0, te[2].price              , clrBlueViolet, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"three+", 0, te[2].price+te[2].channel, clrBlueViolet, 2);
 HLineCreate(0, name+"three-", 0, te[2].price-te[2].channel, clrBlueViolet, 2);
}

//---------------------------------------------
// Сдвиг линий на заданный уровень
//---------------------------------------------
void MoveExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   , te[0].price);
 HLineMove(0, name+"one+"  , te[0].price+te[0].channel);
 HLineMove(0, name+"one-"  , te[0].price-te[0].channel);
 HLineMove(0, name+"two"   , te[1].price);
 HLineMove(0, name+"two+"  , te[1].price+te[1].channel);
 HLineMove(0, name+"two-"  , te[1].price-te[1].channel);
 HLineMove(0, name+"three" , te[2].price);
 HLineMove(0, name+"three+", te[2].price+te[2].channel);
 HLineMove(0, name+"three-", te[2].price-te[2].channel);
}

//---------------------------------------------
// Удаление линий
//---------------------------------------------
void DeleteExtrLines(ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"one");
 HLineDelete(0, name+"one+");
 HLineDelete(0, name+"one-");
 HLineDelete(0, name+"two");
 HLineDelete(0, name+"two+");
 HLineDelete(0, name+"two-");
 HLineDelete(0, name+"three");
 HLineDelete(0, name+"three+");
 HLineDelete(0, name+"three-");
}

//---------------------------------------------
// Пересчет экстремумов для заданного ТФ
//---------------------------------------------
void CalcExtr(CExtremumCalc &extrcalc, SExtremum &resArray[], datetime start_pos_time, bool now = false)
{
 extrcalc.RecountExtremum(now, start_pos_time);
 for(int j = 0; j < 3; j++)
 {
  resArray[j] = extrcalc.getExtr(j);
 }
}

bool FillATRBuffer()
{
 bool result = true;
 
 if(!extrCalc.isATRCalculated(Bars(Symbol(), period) - period_ATR_channel, Bars(Symbol(), ATR_TIMEFRAME) - ATR_PERIOD))
  result = false;
 return (result);
}

void PrintExtrArray(SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 PrintFormat("%s {%.05f, %d, %.05f}; {%.05f, %d, %.05f}; {%.05f, %d, %.05f};", EnumToString((ENUM_TIMEFRAMES)tf),
                                                                               te[0].price, te[0].direction, te[0].channel,
                                                                               te[1].price, te[1].direction, te[1].channel,
                                                                               te[2].price, te[2].direction, te[2].channel);
}