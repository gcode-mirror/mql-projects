//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <ExtrLine\HLine.mqh>
#include <Lib CisNewBar.mqh>

 input int    period_ATR = 100;      //Период ATR для канала
 input double percent_ATR = 0.03; //Ширина канала уровня в процентах от ATR
 input double precentageATR_price = 1; //Процентр ATR для нового экструмума
 

 input bool  show_Extr_MN  = false;
 input color color_Extr_MN = clrRed;
 input bool  show_Extr_W1  = false;
 input color color_Extr_W1 = clrOrange;
 input bool  show_Extr_D1  = false;
 input color color_Extr_D1 = clrYellow;
 input bool  show_Extr_H4  = false;
 input color color_Extr_H4 = clrBlue;
 input bool  show_Extr_H1  = false;
 input color color_Extr_H1 = clrAqua;
 input bool  show_Price_D1  = false;
 input color color_Price_D1 = clrDarkKhaki;

 CExtremumCalc calcMN (Symbol(), PERIOD_MN1, precentageATR_price, period_ATR, percent_ATR);
 CExtremumCalc calcW1 (Symbol(),  PERIOD_W1, precentageATR_price, period_ATR, percent_ATR);
 CExtremumCalc calcD1 (Symbol(),  PERIOD_D1, precentageATR_price, period_ATR, percent_ATR);
 CExtremumCalc calcH4 (Symbol(),  PERIOD_H4, precentageATR_price, period_ATR, percent_ATR);
 CExtremumCalc calcH1 (Symbol(),  PERIOD_H1, precentageATR_price, period_ATR, percent_ATR);

 SExtremum estructMN[3];
 SExtremum estructW1[3];
 SExtremum estructD1[3];
 SExtremum estructH4[3];
 SExtremum estructH1[3];
 SExtremum pstructD1[4];
 
 CisNewBar barMN(Symbol(), PERIOD_MN1);
 CisNewBar barW1(Symbol(), PERIOD_W1);
 CisNewBar barD1(Symbol(), PERIOD_D1);
 CisNewBar barH4(Symbol(), PERIOD_H4);
 CisNewBar barH1(Symbol(), PERIOD_H1);
 
 double buffer_ATR_D1[];
 int handle_ATR_D1;
 
 bool first = true;
 //+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 SetInfoTabel();
 PrintFormat("INITIALIZATION");
 
 
//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handle_ATR_D1);
 ArrayFree(buffer_ATR_D1); 
 if(show_Extr_MN)  DeleteExtrLines(PERIOD_MN1);
 if(show_Extr_W1)  DeleteExtrLines(PERIOD_W1);
 if(show_Extr_D1)  DeleteExtrLines(PERIOD_D1);
 if(show_Extr_H4)  DeleteExtrLines(PERIOD_H4);
 if(show_Extr_H1)  DeleteExtrLines(PERIOD_H1);
 if(show_Price_D1) DeletePriceLines(PERIOD_D1);
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
 
   if(load)
   {
    if(first)
    {
     if(show_Extr_MN)
     {
      FillThreeExtr(calcMN, estructMN);
      CreateExtrLines(estructMN, PERIOD_MN1, color_Extr_MN);
     }
     if(show_Extr_W1)
     {
      FillThreeExtr(calcW1, estructW1);
      CreateExtrLines(estructW1,  PERIOD_W1, color_Extr_W1);
     }
     if(show_Extr_D1)
     {
      FillThreeExtr(calcD1, estructD1);
      CreateExtrLines(estructD1,  PERIOD_D1, color_Extr_D1); 
     }
     if(show_Price_D1)
     {
      FillFourPrice(Symbol(), PERIOD_D1, pstructD1);
      CreatePriceLines(pstructD1, PERIOD_D1, color_Price_D1);
     }
     if(show_Extr_H4)
     {
      FillThreeExtr(calcH4, estructH4);
      CreateExtrLines(estructH4,  PERIOD_H4, color_Extr_H4);
     }
     if(show_Extr_H1)
     {
      FillThreeExtr(calcH1, estructH1);
      CreateExtrLines(estructH1,  PERIOD_H1, color_Extr_H1);
     }
     first = false;
    }//end first
    //-------------------------------------------------------
    if(barMN.isNewBar() > 0)
    {
     if(show_Extr_MN)
     {
      RecountThreeExtr(calcMN, estructMN);
      MoveExtrLines(estructMN, PERIOD_MN1);
     }
    }
    if(barW1.isNewBar() > 0)
    {
     if(show_Extr_W1)
     {
      RecountThreeExtr(calcW1, estructW1);
      MoveExtrLines(estructW1, PERIOD_W1);
     }
    }
    if(barD1.isNewBar() > 0)
    { 
     if(show_Extr_D1)
     {
      RecountThreeExtr(calcD1, estructD1);
      MoveExtrLines(estructD1, PERIOD_D1);
     }
     if(show_Price_D1)
     {
      FillFourPrice(Symbol(), PERIOD_D1, pstructD1);
      MovePriceLines(pstructD1, PERIOD_D1);
     }
    }
    if(barH4.isNewBar() > 0)
    {
     if(show_Extr_H4)
     {
      RecountThreeExtr(calcH4, estructH4);
      MoveExtrLines(estructH4, PERIOD_H4);
     }
    }
    if(barH1.isNewBar() > 0)
    {
     if(show_Extr_H1)
     {
      RecountThreeExtr(calcH1, estructH1);
      MoveExtrLines(estructH1, PERIOD_H1);
     }
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
  
//-------------------------------------------------------------------+
bool FillATRBuffer()
{
 bool result = true;
 
 if(show_Extr_MN)
  if(!calcMN.isATRCalculated())
   result = false;
   
 if(show_Extr_W1)
  if(!calcW1.isATRCalculated())
   result = false;
   
 if(show_Extr_D1 || show_Price_D1)
  if(!calcD1.isATRCalculated())
   result = false;
   
 if(show_Extr_H4)
  if(!calcH4.isATRCalculated())
   result = false;
   
 if(show_Extr_H1)
  if(!calcH1.isATRCalculated())
   result = false;   
   
 if(!result)
  PrintFormat("%s Не получилось загрузить буфера ATR, подожди чутка братан. Ошибочка вышла %d", __FUNCTION__, GetLastError()); 
 return(result);
}


void FillFourPrice(string symbol, ENUM_TIMEFRAMES tf, SExtremum &resArray[])
{
 double  open_buf[1];
 double close_buf[1];
 double  high_buf[1];
 double   low_buf[1];
   
 CopyOpen (symbol, tf, 1, 1,  open_buf);
 CopyClose(symbol, tf, 1, 1, close_buf);
 CopyHigh (symbol, tf, 1, 1,  high_buf);
 CopyLow  (symbol, tf, 1, 1,   low_buf);
 CopyBuffer(handle_ATR_D1, 0, 1, 1, buffer_ATR_D1);
 
 resArray[0].price   =   open_buf[0];
 resArray[0].channel = (buffer_ATR_D1[0]*percent_ATR)/2;
 resArray[1].price   =  close_buf[0];
 resArray[1].channel = (buffer_ATR_D1[0]*percent_ATR)/2;
 resArray[2].price   =   high_buf[0];
 resArray[2].channel = (buffer_ATR_D1[0]*percent_ATR)/2;
 resArray[3].price   =    low_buf[0];
 resArray[3].channel = (buffer_ATR_D1[0]*percent_ATR)/2;
}



void FillThreeExtr (CExtremumCalc &extrcalc, SExtremum &resArray[])
{
 //extrcalc.CalcThreeExtrOnHistory();
 
 for(int j = 0; j < 3; j++)
 {
  resArray[j] = extrcalc.getExtr(j);
 }
 PrintFormat("num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", resArray[0].direction, resArray[0].price, resArray[1].direction, resArray[1].price, resArray[2].direction, resArray[2].price);
}

void RecountThreeExtr (CExtremumCalc &extrcalc, SExtremum &resArray[])
{
 extrcalc.RecountExtremum();

 for(int j = 0; j < 3; j++)
 {
  resArray[j] = extrcalc.getExtr(j);
 }
 PrintFormat("num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", resArray[0].direction, resArray[0].price, resArray[1].direction, resArray[1].price, resArray[2].direction, resArray[2].price);
}

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

void CreatePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open"  , 0, fp[0].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"open+" , 0, fp[0].price+fp[0].channel, clr, 2);
 HLineCreate(0, name+"open-" , 0, fp[0].price-fp[0].channel, clr, 2); 
 HLineCreate(0, name+"close" , 0, fp[1].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"close+", 0, fp[1].price+fp[1].channel, clr, 2);
 HLineCreate(0, name+"close-", 0, fp[1].price-fp[1].channel, clr, 2);
 HLineCreate(0, name+"high"  , 0, fp[2].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"high+" , 0, fp[2].price+fp[2].channel, clr, 2);
 HLineCreate(0, name+"high-" , 0, fp[2].price-fp[2].channel, clr, 2);
 HLineCreate(0, name+"low"   , 0, fp[3].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"low+"  , 0, fp[3].price+fp[3].channel, clr, 2);
 HLineCreate(0, name+"low-"  , 0, fp[3].price-fp[3].channel, clr, 2);
}

void MovePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open"  , fp[0].price);
 HLineMove(0, name+"open+" , fp[0].price+fp[0].channel);
 HLineMove(0, name+"open-" , fp[0].price-fp[0].channel);
 HLineMove(0, name+"close" , fp[1].price);
 HLineMove(0, name+"close+", fp[1].price+fp[1].channel);
 HLineMove(0, name+"close-", fp[1].price-fp[1].channel); 
 HLineMove(0, name+"high"  , fp[2].price);
 HLineMove(0, name+"high+" , fp[2].price+fp[2].channel);
 HLineMove(0, name+"high-" , fp[2].price-fp[2].channel); 
 HLineMove(0, name+"low"   , fp[3].price);
 HLineMove(0, name+"low+"  , fp[3].price+fp[3].channel);
 HLineMove(0, name+"low-"  , fp[3].price-fp[3].channel);  
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
