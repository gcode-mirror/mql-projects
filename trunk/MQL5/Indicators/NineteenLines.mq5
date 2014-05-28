//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"



#property indicator_chart_window
#property indicator_buffers 45  
#property indicator_plots   44

#include <ExtrLine\CLevel.mqh>
#include <ExtrLine\HLine.mqh>
#include <Lib CisNewBarDD.mqh>


#define TF_PERIOD_ATR_FOR_MN PERIOD_MN1
#define TF_PERIOD_ATR_FOR_W1 PERIOD_W1
#define TF_PERIOD_ATR_FOR_D1 PERIOD_D1
#define TF_PERIOD_ATR_FOR_H4 PERIOD_H4
#define TF_PERIOD_ATR_FOR_H1 PERIOD_H4

/*
#define PERCENTAGE_OF_ATR_FOR_MN  1.5
#define PERCENTAGE_OF_ATR_FOR_W1  1.5
#define PERCENTAGE_OF_ATR_FOR_D1  2
#define PERCENTAGE_OF_ATR_FOR_H4  3
#define PERCENTAGE_OF_ATR_FOR_H1  1.5
*/

sinput string mainStr = "";             //Базовые параметры индикатора
input int    period_ATR_channel = 30;   //Период ATR для канала
input int    period_average_ATR = 5;    //Период устреднения индикатора ATR


//input double percent_ATR_channel = 0.1; //Ширина канала уровня в процентах от ATR

sinput string levelStr = "";                 //ПАРАМЕТРЫ УРОВНЕЙ

sinput string mn1Str   = "";                 //Месячные уровни
input bool  flag1  = false;                  //Показывать экстремумы MN1
input double PERCENTAGE_OF_ATR_FOR_MN = 1.5; //Процент от ATR для поиска экстремума
input double channel_ATR_MN1  =  0.1;        //Ширина уровней

sinput string w1Str   = "";                  //Недельные уровни
input bool  flag2  = false;                  //Показывать экстремумы W1
input double PERCENTAGE_OF_ATR_FOR_W1 = 1.5; //Процент от ATR для поиска экстремума
input double channel_ATR_W1   =  0.25;       //Ширина уровней

sinput string d1Str   = "";                  //Дневные уровни
input bool  flag3  = false;                  //Показывать экстремумы D1
input double  PERCENTAGE_OF_ATR_FOR_D1 = 2;  //Процент от ATR для поиска экстремума
input double channel_ATR_D1   =  0.5;        //Ширина уровней

sinput string h1Str   = "";                  //4-х часовые уровни
input bool   flag4  = false;                 //Показывать экстремумы H4
input double PERCENTAGE_OF_ATR_FOR_H4 = 3;   //Процент от ATR для поиска экстремума
input double channel_ATR_H4   =  0.5;        //Ширина уровней

sinput string h4Str   = "";                  //Часовые уровни
input bool  flag5  = true;                   //Показывать экстремумы H1
input double PERCENTAGE_OF_ATR_FOR_H1 = 1.5; //Процент от ATR для поиска экстремума
input double channel_ATR_H1   =  0.5;        //Ширина уровней
 

sinput string dStr   = "";                   //Цены на дневнике
input bool  flag6  = false;                  //Показывать цены D1

//////////////////////////////


bool show_Extr_MN = flag1;
bool show_Extr_W1 = flag2;
bool show_Extr_D1 = flag3;
bool show_Extr_H4 = flag4;
bool show_Extr_H1 = flag5;
bool show_Price_D1 = flag6;


CLevel calcMN (Symbol(), PERIOD_MN1, TF_PERIOD_ATR_FOR_MN, PERCENTAGE_OF_ATR_FOR_MN, period_ATR_channel, channel_ATR_MN1);
CLevel calcW1 (Symbol(),  PERIOD_W1, TF_PERIOD_ATR_FOR_W1, PERCENTAGE_OF_ATR_FOR_W1, period_ATR_channel, channel_ATR_W1);
CLevel calcD1 (Symbol(),  PERIOD_D1, TF_PERIOD_ATR_FOR_D1, PERCENTAGE_OF_ATR_FOR_D1, period_ATR_channel, channel_ATR_D1);
CLevel calcH4 (Symbol(),  PERIOD_H4, TF_PERIOD_ATR_FOR_H4, PERCENTAGE_OF_ATR_FOR_H4, period_ATR_channel, channel_ATR_H4);
CLevel calcH1 (Symbol(),  PERIOD_H1, TF_PERIOD_ATR_FOR_H1, PERCENTAGE_OF_ATR_FOR_H1, period_ATR_channel, channel_ATR_H1);

SLevel extr_levelMN[4];
SLevel extr_levelW1[4];
SLevel extr_levelD1[4];
SLevel extr_levelH4[4];
SLevel extr_levelH1[4];
SLevel price_levelD1[4];
 
double Extr_MN_Buffer1[];
double Extr_MN_Buffer2[];
double Extr_MN_Buffer3[];
double Extr_MN_Buffer4[];
double  ATR_MN_Buffer1[];
double  ATR_MN_Buffer2[];
double  ATR_MN_Buffer3[];
double  ATR_MN_Buffer4[]; 
double Extr_W1_Buffer1[];
double Extr_W1_Buffer2[];
double Extr_W1_Buffer3[];
double Extr_W1_Buffer4[];
double  ATR_W1_Buffer1[];
double  ATR_W1_Buffer2[];
double  ATR_W1_Buffer3[];
double  ATR_W1_Buffer4[];
double Extr_D1_Buffer1[];
double Extr_D1_Buffer2[];
double Extr_D1_Buffer3[];
double Extr_D1_Buffer4[];
double  ATR_D1_Buffer1[];
double  ATR_D1_Buffer2[];
double  ATR_D1_Buffer3[];
double  ATR_D1_Buffer4[];
double Extr_H4_Buffer1[];
double Extr_H4_Buffer2[];
double Extr_H4_Buffer3[];
double Extr_H4_Buffer4[];
double  ATR_H4_Buffer1[];
double  ATR_H4_Buffer2[];
double  ATR_H4_Buffer3[];
double  ATR_H4_Buffer4[];
double Extr_H1_Buffer1[];
double Extr_H1_Buffer2[];
double Extr_H1_Buffer3[];
double Extr_H1_Buffer4[];
double  ATR_H1_Buffer1[];
double  ATR_H1_Buffer2[];
double  ATR_H1_Buffer3[];
double  ATR_H1_Buffer4[];
double Price_D1_Buffer1[];
double Price_D1_Buffer2[];
double Price_D1_Buffer3[];
double Price_D1_Buffer4[];
double   ATR_D1_Buffer [];

int ATR_handle_for_price_line;

bool series_order = true;
bool first = true;

CisNewBar isNewBarMN (_Symbol, PERIOD_MN1);   // для проверки формирования нового бара на месяце
CisNewBar isNewBarW1 (_Symbol, PERIOD_W1 );   // для проверки формирования нового бара на неделе
CisNewBar isNewBarD1 (_Symbol, PERIOD_D1 );   // для проверки формирования нового бара на дне
CisNewBar isNewBarH4 (_Symbol, PERIOD_H4 );   // для проверки формирования нового бара на 4 часах
CisNewBar isNewBarH1 (_Symbol, PERIOD_H1 );   // для проверки формирования нового бара на часе

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
 SetIndexBuffer( 6, Extr_MN_Buffer4, INDICATOR_DATA);
 SetIndexBuffer( 7,  ATR_MN_Buffer4, INDICATOR_DATA);
 SetIndexBuffer( 8, Extr_W1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer( 9,  ATR_W1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(10, Extr_W1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(11,  ATR_W1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(12, Extr_W1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(13,  ATR_W1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(14, Extr_W1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(15,  ATR_W1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(16, Extr_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(17,  ATR_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(18, Extr_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(19,  ATR_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(20, Extr_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(21,  ATR_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(22, Extr_D1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(23,  ATR_D1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(24, Extr_H4_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(25,  ATR_H4_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(26, Extr_H4_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(27,  ATR_H4_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(28, Extr_H4_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(29,  ATR_H4_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(30, Extr_H4_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(31,  ATR_H4_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(32, Extr_H1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(33,  ATR_H1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(34, Extr_H1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(35,  ATR_H1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(36, Extr_H1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(37,  ATR_H1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(38, Extr_H1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(39,  ATR_H1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(40, Price_D1_Buffer1, INDICATOR_DATA);
 SetIndexBuffer(41, Price_D1_Buffer2, INDICATOR_DATA);
 SetIndexBuffer(42, Price_D1_Buffer3, INDICATOR_DATA);
 SetIndexBuffer(43, Price_D1_Buffer4, INDICATOR_DATA);
 SetIndexBuffer(44,   ATR_D1_Buffer , INDICATOR_DATA);
 
 
 ArrayInitialize(Extr_MN_Buffer1,  0);
 ArrayInitialize(Extr_MN_Buffer2,  0);
 ArrayInitialize(Extr_MN_Buffer3,  0);
 ArrayInitialize(Extr_MN_Buffer4,  0); 
 ArrayInitialize( ATR_MN_Buffer1,  0);
 ArrayInitialize( ATR_MN_Buffer2,  0);
 ArrayInitialize( ATR_MN_Buffer3,  0);
 ArrayInitialize( ATR_MN_Buffer4,  0);
 ArrayInitialize(Extr_W1_Buffer1,  0);
 ArrayInitialize(Extr_W1_Buffer2,  0);
 ArrayInitialize(Extr_W1_Buffer3,  0);
 ArrayInitialize(Extr_W1_Buffer4,  0);
 ArrayInitialize( ATR_W1_Buffer1,  0);
 ArrayInitialize( ATR_W1_Buffer2,  0);
 ArrayInitialize( ATR_W1_Buffer3,  0);
 ArrayInitialize( ATR_W1_Buffer4,  0);
 ArrayInitialize(Extr_D1_Buffer1,  0);
 ArrayInitialize(Extr_D1_Buffer2,  0);
 ArrayInitialize(Extr_D1_Buffer3,  0);
 ArrayInitialize(Extr_D1_Buffer4,  0);
 ArrayInitialize( ATR_D1_Buffer1,  0);
 ArrayInitialize( ATR_D1_Buffer2,  0);
 ArrayInitialize( ATR_D1_Buffer3,  0);
 ArrayInitialize( ATR_D1_Buffer4,  0);
 ArrayInitialize(Extr_H4_Buffer1,  0);
 ArrayInitialize(Extr_H4_Buffer2,  0);
 ArrayInitialize(Extr_H4_Buffer3,  0);
 ArrayInitialize(Extr_H4_Buffer4,  0);
 ArrayInitialize( ATR_H4_Buffer1,  0);
 ArrayInitialize( ATR_H4_Buffer2,  0);
 ArrayInitialize( ATR_H4_Buffer3,  0);
 ArrayInitialize( ATR_H4_Buffer4,  0);
 ArrayInitialize(Extr_H1_Buffer1,  0);
 ArrayInitialize(Extr_H1_Buffer2,  0);
 ArrayInitialize(Extr_H1_Buffer3,  0);
 ArrayInitialize(Extr_H1_Buffer4,  0);
 ArrayInitialize( ATR_H1_Buffer1,  0);
 ArrayInitialize( ATR_H1_Buffer2,  0);
 ArrayInitialize( ATR_H1_Buffer3,  0);
 ArrayInitialize( ATR_H1_Buffer4,  0);
 ArrayInitialize(Price_D1_Buffer1, 0);
 ArrayInitialize(Price_D1_Buffer2, 0);
 ArrayInitialize(Price_D1_Buffer3, 0);
 ArrayInitialize(Price_D1_Buffer4, 0);
 ArrayInitialize(  ATR_D1_Buffer , 0);
 
 ArraySetAsSeries(Extr_MN_Buffer1,  series_order);
 ArraySetAsSeries(Extr_MN_Buffer2,  series_order);
 ArraySetAsSeries(Extr_MN_Buffer3,  series_order);
 ArraySetAsSeries(Extr_MN_Buffer4,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer1,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer2,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer3,  series_order);
 ArraySetAsSeries( ATR_MN_Buffer4,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer3,  series_order);
 ArraySetAsSeries(Extr_W1_Buffer4,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_W1_Buffer4,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer3,  series_order);
 ArraySetAsSeries(Extr_D1_Buffer4,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_D1_Buffer4,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer1,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer2,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer3,  series_order);
 ArraySetAsSeries(Extr_H4_Buffer4,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer1,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer2,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer3,  series_order);
 ArraySetAsSeries( ATR_H4_Buffer4,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer1,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer2,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer3,  series_order);
 ArraySetAsSeries(Extr_H1_Buffer4,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer1,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer2,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer3,  series_order);
 ArraySetAsSeries( ATR_H1_Buffer4,  series_order);
 ArraySetAsSeries(Price_D1_Buffer1, series_order);
 ArraySetAsSeries(Price_D1_Buffer2, series_order);
 ArraySetAsSeries(Price_D1_Buffer3, series_order);
 ArraySetAsSeries(Price_D1_Buffer4, series_order);
 ArraySetAsSeries(  ATR_D1_Buffer , series_order);
  
 InitializeExtrArray(extr_levelMN);
 InitializeExtrArray(extr_levelW1);
 InitializeExtrArray(extr_levelD1);
 InitializeExtrArray(extr_levelH4);
 InitializeExtrArray(extr_levelH1);
 InitializeExtrArray(price_levelD1);
 
 //ATR_handle_for_price_line = iATR(Symbol(), PERIOD_D1, period_ATR_channel);
 ATR_handle_for_price_line = iCustom(Symbol(),PERIOD_D1,"AverageATR",period_ATR_channel,period_average_ATR);
 
 if(Period() > PERIOD_MN1 && show_Extr_MN)  show_Extr_MN = false;
 if(Period() > PERIOD_W1  && show_Extr_W1)  show_Extr_W1 = false;
 if(Period() > PERIOD_D1  && show_Extr_D1)  show_Extr_D1 = false;
 if(Period() > PERIOD_H4  && show_Extr_H4)  show_Extr_H4 = false;
 if(Period() > PERIOD_H1  && show_Extr_H1)  show_Extr_H1 = false;
 if(Period() > PERIOD_D1  && show_Price_D1) show_Price_D1 = false;
  
 if(show_Extr_MN) CreateExtrLines (extr_levelMN, PERIOD_MN1, clrRed);
 if(show_Extr_W1) CreateExtrLines (extr_levelW1, PERIOD_W1 , clrOrange);
 if(show_Extr_D1) CreateExtrLines (extr_levelD1, PERIOD_D1 , clrYellow);
 if(show_Extr_H4) CreateExtrLines (extr_levelH4, PERIOD_H4 , clrBlue);
 if(show_Extr_H1) CreateExtrLines (extr_levelH1, PERIOD_H1 , clrAqua);
 if(show_Price_D1)CreatePriceLines(price_levelD1, PERIOD_D1 ,clrDarkKhaki); 
 
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
 ArrayFree(Extr_MN_Buffer4);
 ArrayFree( ATR_MN_Buffer1);
 ArrayFree( ATR_MN_Buffer2);
 ArrayFree( ATR_MN_Buffer3);
 ArrayFree( ATR_MN_Buffer4);
 //-------W1-LEVEL
 ArrayFree(Extr_W1_Buffer1);
 ArrayFree(Extr_W1_Buffer2);
 ArrayFree(Extr_W1_Buffer3);
 ArrayFree(Extr_W1_Buffer4);
 ArrayFree( ATR_W1_Buffer1);
 ArrayFree( ATR_W1_Buffer2);
 ArrayFree( ATR_W1_Buffer3);
 ArrayFree( ATR_W1_Buffer4);
 //-------D1-LEVEL
 ArrayFree(Extr_D1_Buffer1);
 ArrayFree(Extr_D1_Buffer2);
 ArrayFree(Extr_D1_Buffer3);
 ArrayFree(Extr_D1_Buffer4);
 ArrayFree( ATR_D1_Buffer1);
 ArrayFree( ATR_D1_Buffer2);
 ArrayFree( ATR_D1_Buffer3);
 ArrayFree( ATR_D1_Buffer4);
 //-------H4-LEVEL
 ArrayFree(Extr_H4_Buffer1);
 ArrayFree(Extr_H4_Buffer2);
 ArrayFree(Extr_H4_Buffer3);
 ArrayFree(Extr_H4_Buffer4);
 ArrayFree( ATR_H4_Buffer1);
 ArrayFree( ATR_H4_Buffer2);
 ArrayFree( ATR_H4_Buffer3);
 ArrayFree( ATR_H4_Buffer4);
 //-------H1-LEVEL
 ArrayFree(Extr_H1_Buffer1);
 ArrayFree(Extr_H1_Buffer2);
 ArrayFree(Extr_H1_Buffer3);
 ArrayFree(Extr_H1_Buffer4);
 ArrayFree( ATR_H1_Buffer1);
 ArrayFree( ATR_H1_Buffer2);
 ArrayFree( ATR_H1_Buffer3);
 ArrayFree( ATR_H1_Buffer4);
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
   bool load = true;//FillATRBuffer();
   
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);
    
   if(load)
   {
    if(first)
    {
     PrintFormat("%s Рассчет на истории. %s / %s", __FUNCTION__, TimeToString(time[rates_total-2]), TimeToString(time[0]));
     
     for(int i = rates_total-2; i >= 0; i--)  //rates_total-2 т.к. идет обращение к i+1 элементу
     {
      //PrintFormat("%s %s", __FUNCTION__, TimeToString(time[i]));
      if(show_Extr_MN  && isNewBarMN.isNewBar(time[i]) > 0) CalcExtr(calcMN, extr_levelMN, time[i], false);
      if(show_Extr_W1  && isNewBarW1.isNewBar(time[i]) > 0) CalcExtr(calcW1, extr_levelW1, time[i], false);
      if(show_Extr_D1  && isNewBarD1.isNewBar(time[i]) > 0) CalcExtr(calcD1, extr_levelD1, time[i], false);
      if(show_Extr_H4  && isNewBarH4.isNewBar(time[i]) > 0) CalcExtr(calcH4, extr_levelH4, time[i], false);
      if(show_Extr_H1  && isNewBarH1.isNewBar(time[i]) > 0) CalcExtr(calcH1, extr_levelH1, time[i], false);     
      if(show_Price_D1 && isNewBarD1.isNewBar(time[i]) > 0) CalcPrice(PERIOD_D1, time[i]);

      if(show_Extr_MN)
      {
       Extr_MN_Buffer1[i] = extr_levelMN[0].extr.price;
        ATR_MN_Buffer1[i] = extr_levelMN[0].channel;
       Extr_MN_Buffer2[i] = extr_levelMN[1].extr.price;
        ATR_MN_Buffer2[i] = extr_levelMN[1].channel;
       Extr_MN_Buffer3[i] = extr_levelMN[2].extr.price;
        ATR_MN_Buffer3[i] = extr_levelMN[2].channel;
       Extr_MN_Buffer4[i] = extr_levelMN[3].extr.price;
        ATR_MN_Buffer4[i] = extr_levelMN[3].channel;
      }//end show_Extr_MN
      if(show_Extr_W1)
      { 
       Extr_W1_Buffer1[i] = extr_levelW1[0].extr.price;
        ATR_W1_Buffer1[i] = extr_levelW1[0].channel;
       Extr_W1_Buffer2[i] = extr_levelW1[1].extr.price;
        ATR_W1_Buffer2[i] = extr_levelW1[1].channel;
       Extr_W1_Buffer3[i] = extr_levelW1[2].extr.price;
        ATR_W1_Buffer3[i] = extr_levelW1[2].channel;
       Extr_W1_Buffer4[i] = extr_levelW1[3].extr.price;
        ATR_W1_Buffer4[i] = extr_levelW1[3].channel;
           

      }//end show_Extr_W1
      if(show_Extr_D1)
      { 
       Extr_D1_Buffer1[i] = extr_levelD1[0].extr.price;
        ATR_D1_Buffer1[i] = extr_levelD1[0].channel;
       Extr_D1_Buffer2[i] = extr_levelD1[1].extr.price;
        ATR_D1_Buffer2[i] = extr_levelD1[1].channel;
       Extr_D1_Buffer3[i] = extr_levelD1[2].extr.price;
        ATR_D1_Buffer3[i] = extr_levelD1[2].channel;
       Extr_D1_Buffer4[i] = extr_levelD1[3].extr.price;
        ATR_D1_Buffer4[i] = extr_levelD1[3].channel;
      }//end show_Extr_D1
      if(show_Extr_H4)
      {      
       Extr_H4_Buffer1[i] = extr_levelH4[0].extr.price;
        ATR_H4_Buffer1[i] = extr_levelH4[0].channel;
       Extr_H4_Buffer2[i] = extr_levelH4[1].extr.price;
        ATR_H4_Buffer2[i] = extr_levelH4[1].channel;
       Extr_H4_Buffer3[i] = extr_levelH4[2].extr.price;
        ATR_H4_Buffer3[i] = extr_levelH4[2].channel;
       Extr_H4_Buffer4[i] = extr_levelH4[3].extr.price;
        ATR_H4_Buffer4[i] = extr_levelH4[3].channel;
      }// end show_Extr_H4
      if(show_Extr_H1)
      {  
       Extr_H1_Buffer1[i] = extr_levelH1[0].extr.price;
        ATR_H1_Buffer1[i] = extr_levelH1[0].channel;
       Extr_H1_Buffer2[i] = extr_levelH1[1].extr.price;
        ATR_H1_Buffer2[i] = extr_levelH1[1].channel;
       Extr_H1_Buffer3[i] = extr_levelH1[2].extr.price;
        ATR_H1_Buffer3[i] = extr_levelH1[2].channel;
       Extr_H1_Buffer4[i] = extr_levelH1[3].extr.price;
        ATR_H1_Buffer4[i] = extr_levelH1[3].channel;        
      }//end show_Extr_H1
      if(show_Price_D1)
      {         
       Price_D1_Buffer1[i] = price_levelD1[0].extr.price;
       Price_D1_Buffer2[i] = price_levelD1[1].extr.price;
       Price_D1_Buffer3[i] = price_levelD1[2].extr.price;
       Price_D1_Buffer4[i] = price_levelD1[3].extr.price;
          ATR_D1_Buffer[i] = price_levelD1[0].channel; // берем от 0 элемента так как у всех уровней цены ширина одинаковая
      }
     }//end fro
     
     if(show_Extr_MN) MoveExtrLines (extr_levelMN, PERIOD_MN1);
     if(show_Extr_W1) MoveExtrLines (extr_levelW1, PERIOD_W1 ); 
     if(show_Extr_D1) MoveExtrLines (extr_levelD1, PERIOD_D1 );
     if(show_Extr_H4) MoveExtrLines (extr_levelH4, PERIOD_H4 );
     if(show_Extr_H1) MoveExtrLines (extr_levelH1, PERIOD_H1 );
     if(show_Price_D1)MovePriceLines(price_levelD1, PERIOD_D1 );
     
     PrintFormat("Закончен расчет на истории. (prev_calculated == 0)");
     first = false; 
    }//end prev_calculated == 0
    else
    {     
     if(show_Extr_MN)
     {
      Extr_MN_Buffer1[0] = extr_levelMN[0].extr.price;
       ATR_MN_Buffer1[0] = extr_levelMN[0].channel;
      Extr_MN_Buffer2[0] = extr_levelMN[1].extr.price;
       ATR_MN_Buffer2[0] = extr_levelMN[1].channel;
      Extr_MN_Buffer3[0] = extr_levelMN[2].extr.price;
       ATR_MN_Buffer3[0] = extr_levelMN[2].channel;
      Extr_MN_Buffer4[0] = extr_levelMN[3].extr.price;
       ATR_MN_Buffer4[0] = extr_levelMN[3].channel;
     }//end show_Extr_MN
     if(show_Extr_W1)
     { 
      Extr_W1_Buffer1[0] = extr_levelW1[0].extr.price;
       ATR_W1_Buffer1[0] = extr_levelW1[0].channel;
      Extr_W1_Buffer2[0] = extr_levelW1[1].extr.price;
       ATR_W1_Buffer2[0] = extr_levelW1[1].channel;
      Extr_W1_Buffer3[0] = extr_levelW1[2].extr.price;
       ATR_W1_Buffer3[0] = extr_levelW1[2].channel;
      Extr_W1_Buffer4[0] = extr_levelW1[3].extr.price;
       ATR_W1_Buffer4[0] = extr_levelW1[3].channel;
       
     }//end show_Extr_W1
     if(show_Extr_D1)
     { 
      Extr_D1_Buffer1[0] = extr_levelD1[0].extr.price;
       ATR_D1_Buffer1[0] = extr_levelD1[0].channel;
      Extr_D1_Buffer2[0] = extr_levelD1[1].extr.price;
       ATR_D1_Buffer2[0] = extr_levelD1[1].channel;
      Extr_D1_Buffer3[0] = extr_levelD1[2].extr.price;
       ATR_D1_Buffer3[0] = extr_levelD1[2].channel;
      Extr_D1_Buffer4[0] = extr_levelD1[3].extr.price;
       ATR_D1_Buffer4[0] = extr_levelD1[3].channel;
     }//end show_Extr_D1
     if(show_Extr_H4)
     {      
      Extr_H4_Buffer1[0] = extr_levelH4[0].extr.price;
       ATR_H4_Buffer1[0] = extr_levelH4[0].channel;
      Extr_H4_Buffer2[0] = extr_levelH4[1].extr.price;
       ATR_H4_Buffer2[0] = extr_levelH4[1].channel;
      Extr_H4_Buffer3[0] = extr_levelH4[2].extr.price;
       ATR_H4_Buffer3[0] = extr_levelH4[2].channel;
      Extr_H4_Buffer4[0] = extr_levelH4[3].extr.price;
       ATR_H4_Buffer4[0] = extr_levelH4[3].channel;
     }// end show_Extr_H4
     if(show_Extr_H1)
     {  
      Extr_H1_Buffer1[0] = extr_levelH1[0].extr.price;
       ATR_H1_Buffer1[0] = extr_levelH1[0].channel;
      Extr_H1_Buffer2[0] = extr_levelH1[1].extr.price;
       ATR_H1_Buffer2[0] = extr_levelH1[1].channel;
      Extr_H1_Buffer3[0] = extr_levelH1[2].extr.price;
       ATR_H1_Buffer3[0] = extr_levelH1[2].channel;
      Extr_H1_Buffer4[0] = extr_levelH1[3].extr.price;
       ATR_H1_Buffer4[0] = extr_levelH1[3].channel;        
     }//end show_Extr_H1
     if(show_Price_D1)
     {
      Price_D1_Buffer1[0] = price_levelD1[0].extr.price;
      Price_D1_Buffer2[0] = price_levelD1[1].extr.price;
      Price_D1_Buffer3[0] = price_levelD1[2].extr.price;
      Price_D1_Buffer4[0] = price_levelD1[3].extr.price;
         ATR_D1_Buffer[0] = price_levelD1[0].channel; // берем от 0 элемента так как у всех уровней цены ширина одинаковая
     }
     
     //while(!FillATRBuffer()) {PrintFormat("REAL STOPIKI");} 
     if(show_Extr_MN) CalcExtr(calcMN, extr_levelMN, time[0], true); 
     if(show_Extr_W1) CalcExtr(calcW1, extr_levelW1, time[0], true);  
     if(show_Extr_D1) CalcExtr(calcD1, extr_levelD1, time[0], true);    
     if(show_Extr_H4) CalcExtr(calcH4, extr_levelH4, time[0], true);
     if(show_Extr_H1) CalcExtr(calcH1, extr_levelH1, time[0], true);
     if(show_Price_D1)CalcPrice(PERIOD_D1, time[0]);
      
     if(show_Extr_MN) MoveExtrLines (extr_levelMN, PERIOD_MN1);
     if(show_Extr_W1) MoveExtrLines (extr_levelW1, PERIOD_W1 ); 
     if(show_Extr_D1) MoveExtrLines (extr_levelD1, PERIOD_D1 );
     if(show_Extr_H4) MoveExtrLines (extr_levelH4, PERIOD_H4 );
     if(show_Extr_H1) MoveExtrLines (extr_levelH1, PERIOD_H1 );
     if(show_Price_D1)MovePriceLines(price_levelD1, PERIOD_D1 );
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
  
//-------------------------------------------------------------------+
/*bool FillATRBuffer()
{
 bool result = true;
 
 PrintFormat("Bars(MN1) = %d; SeriesInfoInteger = %d", Bars(Symbol(), PERIOD_MN1), SeriesInfoInteger(Symbol(), PERIOD_MN1, SERIES_BARS_COUNT));
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
}*/


//---------------------------------------------
// Пересчет экстремумов для заданного ТФ
//---------------------------------------------
void CalcExtr(CLevel &extrcalc, SLevel &resArray[], datetime start_pos_time, bool now = false)
{
 extrcalc.RecountLevel(start_pos_time, now);
 for(int j = 0; j < 4; j++)
 {
  resArray[j] = extrcalc.getLevel(j);
 }
 //PrintFormat("%s num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f}; num3: {%d, %0.5f};", __FUNCTION__, resArray[0].extr.direction, resArray[0].extr.price, resArray[1].extr.direction, resArray[1].extr.price, resArray[2].extr.direction, resArray[2].extr.price, resArray[3].extr.direction, resArray[3].extr.price);
}

void CalcPrice(ENUM_TIMEFRAMES tf, datetime start_pos)
{
 double  buffer_ATR[1];
 MqlRates rates_buffer[1];
 
 CopyBuffer(ATR_handle_for_price_line, 0, start_pos-PeriodSeconds(tf), 1, buffer_ATR);
 CopyRates(Symbol(), tf, start_pos-PeriodSeconds(tf), 1, rates_buffer);
 
 price_levelD1[0].extr.price = rates_buffer[0].open;
 price_levelD1[0].channel = (buffer_ATR[0]*channel_ATR_D1)/2;
 price_levelD1[1].extr.price = rates_buffer[0].high;
 price_levelD1[1].channel = (buffer_ATR[0]*channel_ATR_D1)/2;
 price_levelD1[2].extr.price = rates_buffer[0].low;
 price_levelD1[2].channel = (buffer_ATR[0]*channel_ATR_D1)/2;
 price_levelD1[3].extr.price = rates_buffer[0].close;
 price_levelD1[3].channel = (buffer_ATR[0]*channel_ATR_D1)/2;
}
//---------------------------------------------
// Создание линий
//---------------------------------------------
void CreateExtrLines(const SLevel &te[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";

 HLineCreate(0, name+"one"   , 0, te[0].extr.price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"one+"  , 0, te[0].extr.price+te[0].channel, clr, 2);
 HLineCreate(0, name+"one-"  , 0, te[0].extr.price-te[0].channel, clr, 2);
 HLineCreate(0, name+"two"   , 0, te[1].extr.price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"two+"  , 0, te[1].extr.price+te[1].channel, clr, 2);
 HLineCreate(0, name+"two-"  , 0, te[1].extr.price-te[1].channel, clr, 2);
 HLineCreate(0, name+"three" , 0, te[2].extr.price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"three+", 0, te[2].extr.price+te[2].channel, clr, 2);
 HLineCreate(0, name+"three-", 0, te[2].extr.price-te[2].channel, clr, 2);
 HLineCreate(0, name+"four"  , 0, te[3].extr.price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"four+" , 0, te[3].extr.price+te[3].channel, clr, 2);
 HLineCreate(0, name+"four-" , 0, te[3].extr.price-te[3].channel, clr, 2);
}

//---------------------------------------------
// Сдвиг линий на заданный уровень
//---------------------------------------------
void MoveExtrLines(const SLevel &te[], ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   , te[0].extr.price);
 HLineMove(0, name+"one+"  , te[0].extr.price+te[0].channel);
 HLineMove(0, name+"one-"  , te[0].extr.price-te[0].channel);
 HLineMove(0, name+"two"   , te[1].extr.price);
 HLineMove(0, name+"two+"  , te[1].extr.price+te[1].channel);
 HLineMove(0, name+"two-"  , te[1].extr.price-te[1].channel);
 HLineMove(0, name+"three" , te[2].extr.price);
 HLineMove(0, name+"three+", te[2].extr.price+te[2].channel);
 HLineMove(0, name+"three-", te[2].extr.price-te[2].channel);
 HLineMove(0, name+"four"  , te[3].extr.price);
 HLineMove(0, name+"four+" , te[3].extr.price+te[3].channel);
 HLineMove(0, name+"four-" , te[3].extr.price-te[3].channel);
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
 HLineDelete(0, name+"four");
 HLineDelete(0, name+"four+");
 HLineDelete(0, name+"four-");
}

void CreatePriceLines(const SLevel &te[], ENUM_TIMEFRAMES tf,color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open"  , 0, te[0].extr.price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"open+" , 0, te[0].extr.price+te[0].channel, clr, 2);
 HLineCreate(0, name+"open-" , 0, te[0].extr.price-te[0].channel, clr, 2); 
 HLineCreate(0, name+"high"  , 0, te[1].extr.price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"high+" , 0, te[1].extr.price+te[1].channel, clr, 2);
 HLineCreate(0, name+"high-" , 0, te[1].extr.price-te[1].channel, clr, 2);
 HLineCreate(0, name+"low"   , 0, te[2].extr.price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"low+"  , 0, te[2].extr.price+te[2].channel, clr, 2);
 HLineCreate(0, name+"low-"  , 0, te[2].extr.price-te[2].channel, clr, 2);
 HLineCreate(0, name+"close" , 0, te[3].extr.price, clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"close+", 0, te[3].extr.price+te[3].channel, clr, 2);
 HLineCreate(0, name+"close-", 0, te[3].extr.price-te[3].channel, clr, 2);
}

void MovePriceLines(const SLevel &te[], ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open"  , te[0].extr.price);
 HLineMove(0, name+"open+" , te[0].extr.price+te[0].channel);
 HLineMove(0, name+"open-" , te[0].extr.price-te[0].channel);
 HLineMove(0, name+"high"  , te[1].extr.price);
 HLineMove(0, name+"high+" , te[1].extr.price+te[1].channel);
 HLineMove(0, name+"high-" , te[1].extr.price-te[1].channel); 
 HLineMove(0, name+"low"   , te[2].extr.price);
 HLineMove(0, name+"low+"  , te[2].extr.price+te[2].channel);
 HLineMove(0, name+"low-"  , te[2].extr.price-te[2].channel);
 HLineMove(0, name+"close" , te[3].extr.price);
 HLineMove(0, name+"close+", te[3].extr.price+te[3].channel);
 HLineMove(0, name+"close-", te[3].extr.price-te[3].channel);   
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
 LabelCreate(0,  "Extr_PERIOD_MN", 0, X+65, Y+15, CORNER_LEFT_UPPER, "EXTREMUM MONTH", "Arial Black", 8,  clrRed, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_W1", 0, X+65, Y+30, CORNER_LEFT_UPPER,  "EXTREMUM WEEK", "Arial Black", 8,  clrOrange, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_D1", 0, X+65, Y+45, CORNER_LEFT_UPPER,   "EXTREMUM DAY", "Arial Black", 8,  clrYellow, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H4", 0, X+65, Y+60, CORNER_LEFT_UPPER, "EXTREMUM 4HOUR", "Arial Black", 8,  clrBlue, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H1", 0, X+65, Y+75, CORNER_LEFT_UPPER, "EXTREMUM 1HOUR", "Arial Black", 8,  clrAqua, ANCHOR_CENTER, false, false, false);
 LabelCreate(0, "Price_PERIOD_D1", 0, X+65, Y+90, CORNER_LEFT_UPPER,      "PRICE DAY", "Arial Black", 8,  clrDarkKhaki, ANCHOR_CENTER, false, false, false);
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

void InitializeExtrArray (SLevel &te[])
{
 int size = ArraySize(te);
 for(int i = 0; i < size; i++)
 {
  te[i].extr.price = 0;
  te[i].extr.direction = 0;
  te[i].channel = 0;
 }
}

void PrintExtrArray(SLevel &te[], ENUM_TIMEFRAMES tf)
{
 PrintFormat("%s {%.05f, %d, %.05f}; {%.05f, %d, %.05f}; {%.05f, %d, %.05f}; {%.05f, %d, %.05f};", EnumToString((ENUM_TIMEFRAMES)tf),
                                                                                                   te[0].extr.price, te[0].extr.direction, te[0].channel,
                                                                                                   te[1].extr.price, te[1].extr.direction, te[1].channel,
                                                                                                   te[2].extr.price, te[2].extr.direction, te[2].channel,
                                                                                                   te[3].extr.price, te[3].extr.direction, te[3].channel);
}