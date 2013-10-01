//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <CExtremumCalc.mqh>
#include <Lib CisNewBar.mqh>

input int epsilon = 25;
input int depth = 50;

input bool show_Extr_MN = true;
input bool show_Extr_W1 = true;
input bool show_Extr_D1 = true;
input bool show_Extr_H4 = true;
input bool show_Extr_H1 = true;
input bool show_Price_D1 = true;

CExtremumCalc calcMN(epsilon, depth);
CExtremumCalc calcW1(epsilon, depth);
CExtremumCalc calcD1(epsilon, depth);
CExtremumCalc calcH4(epsilon, depth);
CExtremumCalc calcH1(epsilon, depth);

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

string symbol = Symbol();

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 if(depth < 10) return(INIT_PARAMETERS_INCORRECT);
//--- indicator buffers mapping
 if(show_Extr_MN)  FillThreeExtr(symbol, PERIOD_MN1, calcMN, estructMN);
 if(show_Extr_W1)  FillThreeExtr(symbol, PERIOD_W1,  calcW1, estructW1);
 if(show_Extr_D1)  FillThreeExtr(symbol, PERIOD_D1,  calcD1, estructD1);
 if(show_Extr_H4)  FillThreeExtr(symbol, PERIOD_H4,  calcH4, estructH4);
 if(show_Extr_H1)  FillThreeExtr(symbol, PERIOD_H1,  calcH1, estructH1);
 if(show_Price_D1) FillFourPrice(symbol, PERIOD_D1, pstructD1);
 
 if(show_Extr_MN)  CreateExtrLines(estructMN, PERIOD_MN1, clrRed);
 if(show_Extr_W1)  CreateExtrLines(estructW1,  PERIOD_W1, clrOrange);
 if(show_Extr_D1)  CreateExtrLines(estructD1,  PERIOD_D1, clrYellow);
 if(show_Extr_H4)  CreateExtrLines(estructH4,  PERIOD_H4, clrBlue);
 if(show_Extr_H1)  CreateExtrLines(estructH1,  PERIOD_H1, clrAqua);
 if(show_Price_D1) CreatePriceLines(pstructD1, PERIOD_D1, clrYellow);  
//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 if(show_Extr_MN)  DeleteExtrLines(PERIOD_MN1);
 if(show_Extr_W1)  DeleteExtrLines(PERIOD_W1);
 if(show_Extr_D1)  DeleteExtrLines(PERIOD_D1);
 if(show_Extr_H4)  DeleteExtrLines(PERIOD_H4);
 if(show_Extr_H1)  DeleteExtrLines(PERIOD_H1);
 if(show_Price_D1) DeletePriceLines(PERIOD_D1);
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
   if(barMN.isNewBar() > 0)
   {
    if(show_Extr_MN)
    {
     FillThreeExtr(symbol, PERIOD_MN1, calcMN, estructMN);
     MoveExtrLines(estructMN, PERIOD_MN1);
    }
   }
   if(barW1.isNewBar() > 0)
   {
    if(show_Extr_W1)
    {
     FillThreeExtr(symbol, PERIOD_W1, calcW1, estructW1);
     MoveExtrLines(estructW1, PERIOD_W1);
    }
   }
   if(barD1.isNewBar() > 0)
   {
    if(show_Extr_D1)
    {
     FillThreeExtr(symbol, PERIOD_D1, calcD1, estructD1);
     MoveExtrLines(estructD1, PERIOD_D1);
    }
    if(show_Price_D1)
    {
     FillFourPrice(symbol, PERIOD_D1, pstructD1);
     MovePriceLines(pstructD1, PERIOD_D1);
    }
   }
   if(barH4.isNewBar() > 0)
   {
    if(show_Extr_H4)
    {
     FillThreeExtr(symbol, PERIOD_H4, calcH4, estructH4);
     MoveExtrLines(estructH4, PERIOD_H4);
    }
   }
   if(barH1.isNewBar() > 0)
   {
    if(show_Extr_H1)
    {
     FillThreeExtr(symbol, PERIOD_H1, calcH1, estructH1);
     MoveExtrLines(estructH1, PERIOD_H1);
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID графика
                 const string          name="HLine",      // имя линии
                 const int             sub_window=0,      // номер подокна
                 double                price=0,           // цена линии
                 const color           clr=clrRed,        // цвет линии
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линии
                 const int             width=1,           // толщина линии
                 const bool            back=false         // на заднем плане
                )      
{
//--- если цена не задана, то установим ее на уровне текущей цены Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
 ResetLastError();
//--- создадим горизонтальную линию
 if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
 {
  Print(__FUNCTION__, ": не удалось создать горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- установим цвет линии
 ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль отображения линии
 ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину линии
 ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- отобразим на переднем (false) или заднем (true) плане
 ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- успешное выполнение
 return(true);
}

bool HLineMove(const long   chart_ID=0,   // ID графика
               const string name="HLine", // имя линии
               double       price=0)      // цена линии
{
//--- если цена линии не задана, то перемещаем ее на уровень текущей цены Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
 ResetLastError();
//--- переместим горизонтальную линию
 if(!ObjectMove(chart_ID,name,0,0,price))
 {
  Print(__FUNCTION__, ": не удалось переместить горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

bool HLineDelete(const long   chart_ID=0,   // ID графика
                 const string name="HLine") // имя линии
{
//--- сбросим значение ошибки
 ResetLastError();
//--- удалим горизонтальную линию
 if(!ObjectDelete(chart_ID,name))
 {
  Print(__FUNCTION__, ": не удалось удалить горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

void FillFourPrice(string symbol, ENUM_TIMEFRAMES tf, SExtremum &resArray[])
{
 double open_buf[1];
 double close_buf[1];
 double high_buf[1];
 double low_buf[1];
   
 CopyOpen (symbol, tf, 1, 1,  open_buf);
 CopyClose(symbol, tf, 1, 1, close_buf);
 CopyHigh (symbol, tf, 1, 1,  high_buf);
 CopyLow  (symbol, tf, 1, 1,   low_buf);
 
 resArray[0].price  = open_buf[0];
 resArray[1].price = close_buf[0];
 resArray[2].price  = high_buf[0];
 resArray[3].price   = low_buf[0];
}

void CreatePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open" , 0,  fp[0].price, clr);
 HLineCreate(0, name+"close", 0, fp[1].price, clr);
 HLineCreate(0, name+"high" , 0,  fp[2].price, clr);
 HLineCreate(0, name+"low"  , 0,   fp[3].price, clr);
}

void MovePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open" ,  fp[0].price);
 HLineMove(0, name+"close", fp[1].price); 
 HLineMove(0, name+"high" ,  fp[2].price); 
 HLineMove(0, name+"low"  ,   fp[3].price);  
}

void DeletePriceLines(ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"open");
 HLineDelete(0, name+"close");
 HLineDelete(0, name+"high");
 HLineDelete(0, name+"low");
}

void FillThreeExtr (string symbol, ENUM_TIMEFRAMES tf, CExtremumCalc &extrcalc, SExtremum &resArray[])
{
 extrcalc.FillExtremumsArray(symbol, tf);
 if (extrcalc.NumberOfExtr() < 3)
 {
  Alert(__FUNCTION__, "Не удалось рассчитать три экстремума на таймфрейме ", EnumToString((ENUM_TIMEFRAMES)tf));
  return;
 }
 
 int count = 0;
 for(int i = 0; i < depth && count < 3; i++)
 {
  if(extrcalc.getExtr(i).price > 0)
  {
   resArray[count] = extrcalc.getExtr(i);
   count++;
  }
 }
}

void CreateExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"one"   , 0, te[0].price, clr);
 HLineCreate(0, name+"two"   , 0, te[1].price, clr);
 HLineCreate(0, name+"three" , 0, te[2].price, clr);
}

void MoveExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   , te[0].price);
 HLineMove(0, name+"two"   , te[1].price);
 HLineMove(0, name+"three" , te[2].price);
}

void DeleteExtrLines(ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"one");
 HLineDelete(0, name+"two");
 HLineDelete(0, name+"three");
}