//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 36  
#property indicator_plots   36

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <ExtrLine\HLine.mqh>
#include <Lib CisNewBar.mqh>

#define TF_PERIOD_ATR_FOR_MN PERIOD_MN1
#define TF_PERIOD_ATR_FOR_W1 PERIOD_W1
#define TF_PERIOD_ATR_FOR_D1 PERIOD_D1
#define TF_PERIOD_ATR_FOR_H4 PERIOD_H4
#define TF_PERIOD_ATR_FOR_H1 PERIOD_H4

#define PERCENTAGE_OF_ATR_FOR_MN  1
#define PERCENTAGE_OF_ATR_FOR_W1  1
#define PERCENTAGE_OF_ATR_FOR_D1  1
#define PERCENTAGE_OF_ATR_FOR_H4  2
#define PERCENTAGE_OF_ATR_FOR_H1  1

input int    period_ATR_channel = 30;   //Период ATR для канала
input double percent_ATR_channel = 0.1; //Ширина канала уровня в процентах от ATR


input bool  flag1  = false;                  //Показывать экстремумы MN1
input color color_Extr_MN = clrRed;          //Цвет линий экстремумов
input bool  flag2  = false;                  //Показывать экстремумы W1
input color color_Extr_W1 = clrOrange;       //Цвет линий экстремумов
input bool  flag3  = false;                  //Показывать экстремумы D1
input color color_Extr_D1 = clrYellow;       //Цвет линий экстремумов
input bool  flag4  = false;                  //Показывать экстремумы H4
input color color_Extr_H4 = clrBlue;         //Цвет линий экстремумов
input bool  flag5  = true;                   //Показывать экстремумы H1
input color color_Extr_H1 = clrAqua;         //Цвет линий экстремумов
input bool  flag6  = false;                  //Показывать цены D1
input color color_Price_D1 = clrDarkKhaki;   //Цвет линий экстремумов

bool show_Extr_MN = flag1;
bool show_Extr_W1 = flag2;
bool show_Extr_D1 = flag3;
bool show_Extr_H4 = flag4;
bool show_Extr_H1 = flag5;
bool show_Price_D1 = flag6;


CExtremumCalc calcMN (Symbol(), PERIOD_MN1, TF_PERIOD_ATR_FOR_MN, PERCENTAGE_OF_ATR_FOR_MN, period_ATR_channel, percent_ATR_channel);
CExtremumCalc calcW1 (Symbol(),  PERIOD_W1, TF_PERIOD_ATR_FOR_W1, PERCENTAGE_OF_ATR_FOR_W1, period_ATR_channel, percent_ATR_channel);
CExtremumCalc calcD1 (Symbol(),  PERIOD_D1, TF_PERIOD_ATR_FOR_D1, PERCENTAGE_OF_ATR_FOR_D1, period_ATR_channel, percent_ATR_channel);
CExtremumCalc calcH4 (Symbol(),  PERIOD_H4, TF_PERIOD_ATR_FOR_H4, PERCENTAGE_OF_ATR_FOR_H4, period_ATR_channel, percent_ATR_channel);
CExtremumCalc calcH1 (Symbol(),  PERIOD_H1, TF_PERIOD_ATR_FOR_H1, PERCENTAGE_OF_ATR_FOR_H1, period_ATR_channel, percent_ATR_channel);

SExtremum estructMN[3];
SExtremum estructW1[3];
SExtremum estructD1[3];
SExtremum estructH4[3];
SExtremum estructH1[3];
SExtremum pstructD1[4];
 
double Extr_MN_Buffer1[];
double Extr_MN_Buffer2[];
double Extr_MN_Buffer3[];
double  ATR_MN_Buffer1[];
double  ATR_MN_Buffer2[];
double  ATR_MN_Buffer3[]; 
double Extr_W1_Buffer1[];
double Extr_W1_Buffer2[];
double Extr_W1_Buffer3[];
double  ATR_W1_Buffer1[];
double  ATR_W1_Buffer2[];
double  ATR_W1_Buffer3[];
double Extr_D1_Buffer1[];
double Extr_D1_Buffer2[];
double Extr_D1_Buffer3[];
double  ATR_D1_Buffer1[];
double  ATR_D1_Buffer2[];
double  ATR_D1_Buffer3[];
double Extr_H4_Buffer1[];
double Extr_H4_Buffer2[];
double Extr_H4_Buffer3[];
double  ATR_H4_Buffer1[];
double  ATR_H4_Buffer2[];
double  ATR_H4_Buffer3[];
double Extr_H1_Buffer1[];
double Extr_H1_Buffer2[];
double Extr_H1_Buffer3[];
double  ATR_H1_Buffer1[];
double  ATR_H1_Buffer2[];
double  ATR_H1_Buffer3[];
double Price_D1_Buffer1[];
double Price_D1_Buffer2[];
double Price_D1_Buffer3[];
double Price_D1_Buffer4[];
double   ATR_D1_Buffer [];

int ATR_handle_for_price_line;

bool series_order = true;
bool first = true;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 SetInfoTabel();
 PrintFormat("INITIALIZATION");

 SetIndexBuffer( 0, Extr_MN_Buffer1, INDICATOR_DATA);
 SetIndexBuffer( 1,  ATR_MN_Buffer1, INDICATOR_DATA);
 SetIndexBuffer( 2, Extr_MN_Buffer2, INDICATOR_DATA);
 SetIndexBuffer( 3,  ATR_MN_Buffer2, INDICATOR_DATA);
 SetIndexBuffer( 4, Extr_MN_Buffer3, INDICATOR_DATA);
 SetIndexBuffer( 5,  ATR_MN_Buffer3, INDICATOR_DATA);
 SetIndexBuffer( 6, Extr_W1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer( 7,  ATR_W1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer( 8, Extr_W1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer( 9,  ATR_W1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(10, Extr_W1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(11,  ATR_W1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(12, Extr_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(13,  ATR_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(14, Extr_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(15,  ATR_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(16, Extr_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(17,  ATR_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(18, Extr_H4_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(19,  ATR_H4_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(20, Extr_H4_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(21,  ATR_H4_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(22, Extr_H4_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(23,  ATR_H4_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(24, Extr_H1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(25,  ATR_H1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(26, Extr_H1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(27,  ATR_H1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(28, Extr_H1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(29,  ATR_H1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(30, Price_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(31, Price_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(32, Price_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(33, Price_D1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(34,   ATR_D1_Buffer , INDICATOR_DATA);
 
 ArrayInitialize(Extr_MN_Buffer1,  0);
 ArrayInitialize(Extr_MN_Buffer2,  0);
 ArrayInitialize(Extr_MN_Buffer3,  0);
 ArrayInitialize( ATR_MN_Buffer1,  0);
 ArrayInitialize( ATR_MN_Buffer2,  0);
 ArrayInitialize( ATR_MN_Buffer3,  0);
 ArrayInitialize(Extr_W1_Buffer1,  0);
 ArrayInitialize(Extr_W1_Buffer2,  0);
 ArrayInitialize(Extr_W1_Buffer3,  0);
 ArrayInitialize( ATR_W1_Buffer1,  0);
 ArrayInitialize( ATR_W1_Buffer2,  0);
 ArrayInitialize( ATR_W1_Buffer3,  0);
 ArrayInitialize(Extr_D1_Buffer1,  0);
 ArrayInitialize(Extr_D1_Buffer2,  0);
 ArrayInitialize(Extr_D1_Buffer3,  0);
 ArrayInitialize( ATR_D1_Buffer1,  0);
 ArrayInitialize( ATR_D1_Buffer2,  0);
 ArrayInitialize( ATR_D1_Buffer3,  0);
 ArrayInitialize(Extr_H4_Buffer1,  0);
 ArrayInitialize(Extr_H4_Buffer2,  0);
 ArrayInitialize(Extr_H4_Buffer3,  0);
 ArrayInitialize( ATR_H4_Buffer1,  0);
 ArrayInitialize( ATR_H4_Buffer2,  0);
 ArrayInitialize( ATR_H4_Buffer3,  0);
 ArrayInitialize(Extr_H1_Buffer1,  0);
 ArrayInitialize(Extr_H1_Buffer2,  0);
 ArrayInitialize(Extr_H1_Buffer3,  0);
 ArrayInitialize( ATR_H1_Buffer1,  0);
 ArrayInitialize( ATR_H1_Buffer2,  0);
 ArrayInitialize( ATR_H1_Buffer3,  0);
 ArrayInitialize(Price_D1_Buffer1, 0);
 ArrayInitialize(Price_D1_Buffer2, 0);
 ArrayInitialize(Price_D1_Buffer3, 0);
 ArrayInitialize(Price_D1_Buffer4, 0);
 ArrayInitialize(  ATR_D1_Buffer , 0);
 
 ArraySetAsSeries(Extr_MN_Buffer1,  series_order);
 ArraySetAsSeries(Extr_MN_Buffer2,  series_order);
 ArraySetAsSeries(Extr_MN_Buffer3,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer1,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer2,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer3,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer3,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer3,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer1,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer2,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer3,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer1,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer2,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer3,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer3,  series_order);
 ArraySetAsSeries(Price_D1_Buffer1, series_order);
 ArraySetAsSeries(Price_D1_Buffer2, series_order);
 ArraySetAsSeries(Price_D1_Buffer3, series_order);
 ArraySetAsSeries(Price_D1_Buffer4, series_order);
 ArraySetAsSeries(  ATR_D1_Buffer , series_order);
  
 InitializeExtrArray(estructMN);
 InitializeExtrArray(estructW1);
 InitializeExtrArray(estructD1);
 InitializeExtrArray(estructH4);
 InitializeExtrArray(estructH1);
 InitializeExtrArray(pstructD1);
 
 ATR_handle_for_price_line = iATR(Symbol(), PERIOD_D1, period_ATR_channel);
 
 if(Period() > PERIOD_MN1 && show_Extr_MN)  show_Extr_MN = false;
 if(Period() > PERIOD_W1  && show_Extr_W1)  show_Extr_W1 = false;
 if(Period() > PERIOD_D1  && show_Extr_D1)  show_Extr_D1 = false;
 if(Period() > PERIOD_H4  && show_Extr_H4)  show_Extr_H4 = false;
 if(Period() > PERIOD_H1  && show_Extr_H1)  show_Extr_H1 = false;
 if(Period() > PERIOD_D1  && show_Price_D1) show_Price_D1 = false;
  
 if(show_Extr_MN) CreateExtrLines (estructMN, PERIOD_MN1, color_Extr_MN);
 if(show_Extr_W1) CreateExtrLines (estructW1, PERIOD_W1 , color_Extr_W1);
 if(show_Extr_D1) CreateExtrLines (estructD1, PERIOD_D1 , color_Extr_D1);
 if(show_Extr_H4) CreateExtrLines (estructH4, PERIOD_H4 , color_Extr_H4);
 if(show_Extr_H1) CreateExtrLines (estructH1, PERIOD_H1 , color_Extr_H1);
 if(show_Price_D1)CreatePriceLines(pstructD1, PERIOD_D1 , color_Price_D1); 
 
//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(ATR_handle_for_price_line);
 //-------MN-LEVEL
 ArrayFree(Extr_MN_Buffer1);
 ArrayFree(Extr_MN_Buffer2);
 ArrayFree(Extr_MN_Buffer3);
 ArrayFree( ATR_MN_Buffer1);
 ArrayFree( ATR_MN_Buffer2);
 ArrayFree( ATR_MN_Buffer3);
 //-------W1-LEVEL
 ArrayFree(Extr_W1_Buffer1);
 ArrayFree(Extr_W1_Buffer2);
 ArrayFree(Extr_W1_Buffer3);
 ArrayFree( ATR_W1_Buffer1);
 ArrayFree( ATR_W1_Buffer2);
 ArrayFree( ATR_W1_Buffer3);
 //-------D1-LEVEL
 ArrayFree(Extr_D1_Buffer1);
 ArrayFree(Extr_D1_Buffer2);
 ArrayFree(Extr_D1_Buffer3);
 ArrayFree( ATR_D1_Buffer1);
 ArrayFree( ATR_D1_Buffer2);
 ArrayFree( ATR_D1_Buffer3);
 //-------H4-LEVEL
 ArrayFree(Extr_H4_Buffer1);
 ArrayFree(Extr_H4_Buffer2);
 ArrayFree(Extr_H4_Buffer3);
 ArrayFree( ATR_H4_Buffer1);
 ArrayFree( ATR_H4_Buffer2);
 ArrayFree( ATR_H4_Buffer3);
 //-------H1-LEVEL
 ArrayFree(Extr_H1_Buffer1);
 ArrayFree(Extr_H1_Buffer2);
 ArrayFree(Extr_H1_Buffer3);
 ArrayFree( ATR_H1_Buffer1);
 ArrayFree( ATR_H1_Buffer2);
 ArrayFree( ATR_H1_Buffer3);
 //-------D1-LEVEL-PRICE
 ArrayFree(Price_D1_Buffer1);
 ArrayFree(Price_D1_Buffer2);
 ArrayFree(Price_D1_Buffer3);
 ArrayFree(Price_D1_Buffer4);
 ArrayFree(  ATR_D1_Buffer );
  
 if(show_Extr_MN) DeleteExtrLines (PERIOD_MN1);
 if(show_Extr_W1) DeleteExtrLines (PERIOD_W1);
 if(show_Extr_D1) DeleteExtrLines (PERIOD_D1);
 if(show_Extr_H4) DeleteExtrLines (PERIOD_H4);
 if(show_Extr_H1) DeleteExtrLines (PERIOD_H1);
 if(show_Price_D1)DeletePriceLines(PERIOD_D1);
 DeleteInfoTabel();
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
//---
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
     calcMN.SetStartDayPrice(close[rates_total-1]);
     calcW1.SetStartDayPrice(close[rates_total-1]);
     calcD1.SetStartDayPrice(close[rates_total-1]);
     calcH4.SetStartDayPrice(close[rates_total-1]);
     calcH1.SetStartDayPrice(close[rates_total-1]);
     PrintFormat("Установлены стартдэйпрайс на всех тф");
     
     for(int i = rates_total-2; i > 0; i--)  //rates_total-2 т.к. идет обращение к i+1 элементу
     {
      while(!FillATRBuffer()) {}
      if(show_Extr_MN  && (Period() ==  PERIOD_MN1 || time[i]%PeriodSeconds(PERIOD_MN1) == 0)) CalcExtr(calcMN, estructMN, time[i], false);
      if(show_Extr_W1  && (Period() ==  PERIOD_W1  || time[i]%PeriodSeconds(PERIOD_W1)  == 0)) CalcExtr(calcW1, estructW1, time[i], false);
      if(show_Extr_D1  && (Period() ==  PERIOD_D1  || time[i]%PeriodSeconds(PERIOD_D1)  == 0)) CalcExtr(calcD1, estructD1, time[i], false);
      if(show_Price_D1 && (Period() ==  PERIOD_D1  || time[i]%PeriodSeconds(PERIOD_D1)  == 0)) CalcPrice(pstructD1, PERIOD_D1, time[i]);
      if(show_Extr_H4  && (Period() ==  PERIOD_H4  || time[i]%PeriodSeconds(PERIOD_H4)  == 0)) CalcExtr(calcH4, estructH4, time[i], false);
      if(show_Extr_H1  && (Period() ==  PERIOD_H1  || time[i]%PeriodSeconds(PERIOD_H1)  == 0)) CalcExtr(calcH1, estructH1, time[i], false);
      
      if(show_Extr_MN)
      {
       Extr_MN_Buffer1[i] = estructMN[0].price;
        ATR_MN_Buffer1[i] = estructMN[0].channel;
       Extr_MN_Buffer2[i] = estructMN[1].price;
        ATR_MN_Buffer2[i] = estructMN[1].channel;
       Extr_MN_Buffer3[i] = estructMN[2].price;
        ATR_MN_Buffer3[i] = estructMN[2].channel;
      }//end show_Extr_MN
      if(show_Extr_W1)
      { 
       Extr_W1_Buffer1[i] = estructW1[0].price;
        ATR_W1_Buffer1[i] = estructW1[0].channel;
       Extr_W1_Buffer2[i] = estructW1[1].price;
        ATR_W1_Buffer2[i] = estructW1[1].channel;
       Extr_W1_Buffer3[i] = estructW1[2].price;
        ATR_W1_Buffer3[i] = estructW1[2].channel;
      }//end show_Extr_W1
      if(show_Extr_D1)
      { 
       Extr_D1_Buffer1[i] = estructD1[0].price;
        ATR_D1_Buffer1[i] = estructD1[0].channel;
       Extr_D1_Buffer2[i] = estructD1[1].price;
        ATR_D1_Buffer2[i] = estructD1[1].channel;
       Extr_D1_Buffer3[i] = estructD1[2].price;
        ATR_D1_Buffer3[i] = estructD1[2].channel;
      }//end show_Extr_D1
      if(show_Extr_H4)
      {      
       Extr_H4_Buffer1[i] = estructH4[0].price;
        ATR_H4_Buffer1[i] = estructH4[0].channel;
       Extr_H4_Buffer2[i] = estructH4[1].price;
        ATR_H4_Buffer2[i] = estructH4[1].channel;
       Extr_H4_Buffer3[i] = estructH4[2].price;
        ATR_H4_Buffer3[i] = estructH4[2].channel;
      }// end show_Extr_H4
      if(show_Extr_H1)
      {  
       Extr_H1_Buffer1[i] = estructH1[0].price;
        ATR_H1_Buffer1[i] = estructH1[0].channel;
       Extr_H1_Buffer2[i] = estructH1[1].price;
        ATR_H1_Buffer2[i] = estructH1[1].channel;
       Extr_H1_Buffer3[i] = estructH1[2].price;
        ATR_H1_Buffer3[i] = estructH1[2].channel;
      }//end show_Extr_H1
      if(show_Price_D1)
      {         
       Price_D1_Buffer1[i] = pstructD1[0].price;
       Price_D1_Buffer2[i] = pstructD1[1].price;
       Price_D1_Buffer3[i] = pstructD1[2].price;
       Price_D1_Buffer4[i] = pstructD1[3].price;
          ATR_D1_Buffer[i] = pstructD1[0].channel; // берем от 0 элемента так как у всех уровней цены ширина одинаковая
      }
     }//end fro
     
     if(show_Extr_MN) MoveExtrLines (estructMN, PERIOD_MN1);
     if(show_Extr_W1) MoveExtrLines (estructW1, PERIOD_W1 ); 
     if(show_Extr_D1) MoveExtrLines (estructD1, PERIOD_D1 );
     if(show_Extr_H4) MoveExtrLines (estructH4, PERIOD_H4 );
     if(show_Extr_H1) MoveExtrLines (estructH1, PERIOD_H1 );
     if(show_Price_D1)MovePriceLines(pstructD1, PERIOD_D1 );
     
     PrintFormat("Закончен расчет на истории. (prev_calculated == 0)");
     first = false; 
    }//end prev_calculated == 0
    else
    {     
     if(show_Extr_MN)
     {
      Extr_MN_Buffer1[0] = estructMN[0].price;
       ATR_MN_Buffer1[0] = estructMN[0].channel;
      Extr_MN_Buffer2[0] = estructMN[1].price;
       ATR_MN_Buffer2[0] = estructMN[1].channel;
      Extr_MN_Buffer3[0] = estructMN[2].price;
       ATR_MN_Buffer3[0] = estructMN[2].channel;
     }//end show_Extr_MN
     if(show_Extr_W1)
     { 
      Extr_W1_Buffer1[0] = estructW1[0].price;
       ATR_W1_Buffer1[0] = estructW1[0].channel;
      Extr_W1_Buffer2[0] = estructW1[1].price;
       ATR_W1_Buffer2[0] = estructW1[1].channel;
      Extr_W1_Buffer3[0] = estructW1[2].price;
       ATR_W1_Buffer3[0] = estructW1[2].channel;
     }//end show_Extr_W1
     if(show_Extr_D1)
     { 
      Extr_D1_Buffer1[0] = estructD1[0].price;
       ATR_D1_Buffer1[0] = estructD1[0].channel;
      Extr_D1_Buffer2[0] = estructD1[1].price;
       ATR_D1_Buffer2[0] = estructD1[1].channel;
      Extr_D1_Buffer3[0] = estructD1[2].price;
       ATR_D1_Buffer3[0] = estructD1[2].channel;
     }//end show_Extr_D1
     if(show_Extr_H4)
     {      
      Extr_H4_Buffer1[0] = estructH4[0].price;
       ATR_H4_Buffer1[0] = estructH4[0].channel;
      Extr_H4_Buffer2[0] = estructH4[1].price;
       ATR_H4_Buffer2[0] = estructH4[1].channel;
      Extr_H4_Buffer3[0] = estructH4[2].price;
       ATR_H4_Buffer3[0] = estructH4[2].channel;
     }// end show_Extr_H4
     if(show_Extr_H1)
     {  
      Extr_H1_Buffer1[0] = estructH1[0].price;
       ATR_H1_Buffer1[0] = estructH1[0].channel;
      Extr_H1_Buffer2[0] = estructH1[1].price;
       ATR_H1_Buffer2[0] = estructH1[1].channel;
      Extr_H1_Buffer3[0] = estructH1[2].price;
       ATR_H1_Buffer3[0] = estructH1[2].channel;
     }//end show_Extr_H1
     if(show_Price_D1)
     {
      Price_D1_Buffer1[0] = pstructD1[0].price;
      Price_D1_Buffer2[0] = pstructD1[1].price;
      Price_D1_Buffer3[0] = pstructD1[2].price;
      Price_D1_Buffer4[0] = pstructD1[3].price;
         ATR_D1_Buffer[0] = pstructD1[0].channel; // берем от 0 элемента так как у всех уровней цены ширина одинаковая
     }
     
     while(!FillATRBuffer()) {} 
     CalcExtr(calcMN, estructMN, time[0], true); 
     CalcExtr(calcW1, estructW1, time[0], true);  
     CalcExtr(calcD1, estructD1, time[0], true);
     CalcPrice(pstructD1, PERIOD_D1, time[0]);
     CalcExtr(calcH4, estructH4, time[0], true);
     CalcExtr(calcH1, estructH1, time[0], true);
      
     if(show_Extr_MN) MoveExtrLines (estructMN, PERIOD_MN1);
     if(show_Extr_W1) MoveExtrLines (estructW1, PERIOD_W1 ); 
     if(show_Extr_D1) MoveExtrLines (estructD1, PERIOD_D1 );
     if(show_Extr_H4) MoveExtrLines (estructH4, PERIOD_H4 );
     if(show_Extr_H1) MoveExtrLines (estructH1, PERIOD_H1 );
     if(show_Price_D1)MovePriceLines(pstructD1, PERIOD_D1 );
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
  
//-------------------------------------------------------------------+
bool FillATRBuffer()
{
 bool result = true;
 
 if(show_Extr_MN && !calcMN.isATRCalculated(Bars(Symbol(), PERIOD_MN1) - period_ATR_channel, Bars(Symbol(), TF_PERIOD_ATR_FOR_MN) - ATR_PERIOD))
  result = false;
   
 if(show_Extr_W1 && !calcW1.isATRCalculated(Bars(Symbol(), PERIOD_W1) - period_ATR_channel, Bars(Symbol(), TF_PERIOD_ATR_FOR_W1) - ATR_PERIOD))
   result = false;
   
 if((show_Extr_D1 || show_Price_D1) && !calcD1.isATRCalculated(Bars(Symbol(), PERIOD_D1) - period_ATR_channel, Bars(Symbol(), TF_PERIOD_ATR_FOR_D1) - ATR_PERIOD))
   result = false;
   
 if(show_Extr_H4 && !calcH4.isATRCalculated(Bars(Symbol(), PERIOD_H4) - period_ATR_channel, Bars(Symbol(), TF_PERIOD_ATR_FOR_H4) - ATR_PERIOD))
   result = false;
   
 if(show_Extr_H1 && !calcH1.isATRCalculated(Bars(Symbol(), PERIOD_H1) - period_ATR_channel, Bars(Symbol(), TF_PERIOD_ATR_FOR_H1) - ATR_PERIOD))
   result = false;   
   
 if(!result)
  PrintFormat("%s Не получилось загрузить буфера ATR, подожди чутка братан. Ошибочка вышла %d", __FUNCTION__, GetLastError()); 
 return(result);
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
 //PrintFormat("%s num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", EnumToString((ENUM_TIMEFRAMES)extrcalc.getPeriod()), resArray[0].direction, resArray[0].price, resArray[1].direction, resArray[1].price, resArray[2].direction, resArray[2].price);
}

void CalcPrice(SExtremum &resArray[], ENUM_TIMEFRAMES tf, datetime start_pos)
{
 double  buffer_ATR[1];
 MqlRates rates_buffer[1];
 
 CopyBuffer(ATR_handle_for_price_line, 0, start_pos-PeriodSeconds(tf), 1, buffer_ATR);
 CopyRates(Symbol(), tf, start_pos-PeriodSeconds(tf), 1, rates_buffer);
 
 pstructD1[0].price = rates_buffer[0].open;
 pstructD1[0].channel = (buffer_ATR[0]*percent_ATR_channel)/2;
 pstructD1[1].price = rates_buffer[0].high;
 pstructD1[1].channel = (buffer_ATR[0]*percent_ATR_channel)/2;
 pstructD1[2].price = rates_buffer[0].low;
 pstructD1[2].channel = (buffer_ATR[0]*percent_ATR_channel)/2;
 pstructD1[3].price = rates_buffer[0].close;
 pstructD1[3].channel = (buffer_ATR[0]*percent_ATR_channel)/2;
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

void CreatePriceLines(const SExtremum &te[], ENUM_TIMEFRAMES tf,color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open"  , 0, te[0].price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"open+" , 0, te[0].price+te[0].channel, clr, 2);
 HLineCreate(0, name+"open-" , 0, te[0].price-te[0].channel, clr, 2); 
 HLineCreate(0, name+"high"  , 0, te[1].price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"high+" , 0, te[1].price+te[1].channel, clr, 2);
 HLineCreate(0, name+"high-" , 0, te[1].price-te[1].channel, clr, 2);
 HLineCreate(0, name+"low"   , 0, te[2].price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"low+"  , 0, te[2].price+te[2].channel, clr, 2);
 HLineCreate(0, name+"low-"  , 0, te[2].price-te[2].channel, clr, 2);
 HLineCreate(0, name+"close" , 0, te[3].price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"close+", 0, te[3].price+te[3].channel, clr, 2);
 HLineCreate(0, name+"close-", 0, te[3].price-te[3].channel, clr, 2);
}

void MovePriceLines(const SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open"  , te[0].price);
 HLineMove(0, name+"open+" , te[0].price+te[0].channel);
 HLineMove(0, name+"open-" , te[0].price-te[0].channel);
 HLineMove(0, name+"high"  , te[1].price);
 HLineMove(0, name+"high+" , te[1].price+te[1].channel);
 HLineMove(0, name+"high-" , te[1].price-te[1].channel); 
 HLineMove(0, name+"low"   , te[2].price);
 HLineMove(0, name+"low+"  , te[2].price+te[2].channel);
 HLineMove(0, name+"low-"  , te[2].price-te[2].channel);
 HLineMove(0, name+"close" , te[3].price);
 HLineMove(0, name+"close+", te[3].price+te[3].channel);
 HLineMove(0, name+"close-", te[3].price-te[3].channel);   
}

void DeletePriceLines(ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"open");
 HLineDelete(0, name+"open+");
 HLineDelete(0, name+"open-");
 HLineDelete(0, name+"close");
 HLineDelete(0, name+"close+");
 HLineDelete(0, name+"close-");
 HLineDelete(0, name+"high");
 HLineDelete(0, name+"high+");
 HLineDelete(0, name+"high-");
 HLineDelete(0, name+"low");
 HLineDelete(0, name+"low+");
 HLineDelete(0, name+"low-");
}

//CREATE AND DELETE LABEL AND RECTLABEL
void SetInfoTabel()
{
 int X = 10;
 int Y = 30;
 RectLabelCreate(0, "Extr_Title", 0, X, Y, 130, 105, clrBlack, BORDER_FLAT, CORNER_LEFT_UPPER, clrWhite, STYLE_SOLID, 1, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_MN", 0, X+65, Y+15, CORNER_LEFT_UPPER, "EXTREMUM MONTH", "Arial Black", 8,  color_Extr_MN, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_W1", 0, X+65, Y+30, CORNER_LEFT_UPPER,  "EXTREMUM WEEK", "Arial Black", 8,  color_Extr_W1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_D1", 0, X+65, Y+45, CORNER_LEFT_UPPER,   "EXTREMUM DAY", "Arial Black", 8,  color_Extr_D1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H4", 0, X+65, Y+60, CORNER_LEFT_UPPER, "EXTREMUM 4HOUR", "Arial Black", 8,  color_Extr_H4, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H1", 0, X+65, Y+75, CORNER_LEFT_UPPER, "EXTREMUM 1HOUR", "Arial Black", 8,  color_Extr_H1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0, "Price_PERIOD_D1", 0, X+65, Y+90, CORNER_LEFT_UPPER,      "PRICE DAY", "Arial Black", 8, color_Price_D1, ANCHOR_CENTER, false, false, false);
 ChartRedraw();
}

void DeleteInfoTabel()
{
 RectLabelDelete(0, "Extr_Title");
 LabelDelete(0, "Extr_PERIOD_MN");
 LabelDelete(0, "Extr_PERIOD_W1");
 LabelDelete(0, "Extr_PERIOD_D1");
 LabelDelete(0, "Extr_PERIOD_H4");
 LabelDelete(0, "Extr_PERIOD_H1");
 LabelDelete(0, "Price_PERIOD_D1");
 ChartRedraw();
}

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

void PrintExtrArray(SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 PrintFormat("%s {%.05f, %d, %.05f}; {%.05f, %d, %.05f}; {%.05f, %d, %.05f};", EnumToString((ENUM_TIMEFRAMES)tf),
                                                                               te[0].price, te[0].direction, te[0].channel,
                                                                               te[1].price, te[1].direction, te[1].channel,
                                                                               te[2].price, te[2].direction, te[2].channel);
}