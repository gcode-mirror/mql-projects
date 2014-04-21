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
input double precentageATR_price = 1;    //Процентр ATR для нового экструмума

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
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot DifLine2
#property indicator_label4  "DifLine2"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot MainLine3
#property indicator_label5  "MainLine3"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot DifLine3
#property indicator_label6  "DifLine3"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- indicator buffers
double         MainLineBuffer[];
double         DifLineBuffer[];
double         MainLine2Buffer[];
double         DifLine2Buffer[];
double         MainLine3Buffer[];
double         DifLine3Buffer[];

CExtremumCalc extrCalc (Symbol(), PERIOD_H1, precentageATR_price, period_ATR_channel, percent_ATR_channel);
SExtremum sExtr[3];
CisNewBar barH1(Symbol(), PERIOD_H1);
bool first = true;

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
   
   ArrayInitialize(MainLineBuffer, 0);
   ArrayInitialize(DifLineBuffer, 0);
   ArrayInitialize(MainLine2Buffer, 0);
   ArrayInitialize(DifLine2Buffer, 0);
   ArrayInitialize(MainLine3Buffer, 0);
   ArrayInitialize(DifLine3Buffer, 0);
   
   InitializeExtrArray(sExtr);
   CreateExtrLines (sExtr, PERIOD_H1 , Red);
   
//---
   return(INIT_SUCCEEDED);
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
 
   if(load)
   {
    if(first)
    {     
     extrCalc.SetStartDayPrice(close[rates_total-1]);
     PrintFormat("Установлены стартдэйпрайс на всех тф");
     
     for(int i = rates_total-period_ATR_channel; i > 0; i--)  //rates_total-2 т.к. идет обращение к i+1 элементу
     {
      while(!FillATRBuffer()) {}
      CalcExtr(extrCalc, sExtr, time[i], false);
      
      MainLineBuffer[i] = sExtr[0].price;
      DifLineBuffer[i] = sExtr[0].channel;
     }
     
     MoveExtrLines(sExtr, PERIOD_H1);
     PrintFormat("Закончен расчет на истории. (prev_calculated == 0)");
     first = false; 
    }//end prev_calculated == 0
    else
    {
     for(int i = rates_total - prev_calculated - 1; i >= 0; i--)
     {      
      MainLineBuffer[i] = sExtr[0].price;
      DifLineBuffer[i] = sExtr[0].channel;
      if(barH1.isNewBar() > 0) CalcExtr(extrCalc, sExtr, time[i], true); 
     }
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void InitializeExtrArray (SExtremum &te[])
{
 te[0].price = 0;
 te[0].direction = 0;
 te[0].channel = 0;
 te[1].price = 0;
 te[1].direction = 0;
 te[1].channel = 0;
 te[2].price = 0;
 te[2].direction = 0;
 te[2].channel = 0;
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
 HLineCreate(0, name+"two"   , 0, te[1].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"two+"  , 0, te[1].price+te[1].channel, clr, 2);
 HLineCreate(0, name+"two-"  , 0, te[1].price-te[1].channel, clr, 2);
 HLineCreate(0, name+"three" , 0, te[2].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"three+", 0, te[2].price+te[2].channel, clr, 2);
 HLineCreate(0, name+"three-", 0, te[2].price-te[2].channel, clr, 2);
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
 
 if(extrCalc.isATRCalculated(Bars(Symbol(), PERIOD_H1) - period_ATR_channel, Bars(Symbol(), ATR_TIMEFRAME) - ATR_PERIOD))
  result = false;
 return (result);
}
