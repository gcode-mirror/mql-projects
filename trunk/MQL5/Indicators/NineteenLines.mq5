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
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
struct ThreeExtr
{
 CExtremum one;
 CExtremum two;
 CExtremum three;
};

struct FourPrice
{
 CExtremum open;
 CExtremum close;
 CExtremum high;
 CExtremum low;
};

CExtremumCalc calcMN;
CExtremumCalc calcW1;
CExtremumCalc calcD1;
CExtremumCalc calcH4;
CExtremumCalc calcH1;

ThreeExtr estructMN;
ThreeExtr estructW1;
ThreeExtr estructD1;
ThreeExtr estructH4;
ThreeExtr estructH1;
FourPrice pstructH1;

CisNewBar barMN(Symbol(), PERIOD_MN1);
CisNewBar barW1(Symbol(), PERIOD_W1);
CisNewBar barD1(Symbol(), PERIOD_D1);
CisNewBar barH4(Symbol(), PERIOD_H4);
CisNewBar barH1(Symbol(), PERIOD_H1);
int OnInit()
{
//--- indicator buffers mapping
 estructMN = FillThreeExtr(Symbol(), PERIOD_MN1);
 estructW1 = FillThreeExtr(Symbol(), PERIOD_W1);
 estructD1 = FillThreeExtr(Symbol(), PERIOD_D1);
 estructH4 = FillThreeExtr(Symbol(), PERIOD_H4);
 estructH1 = FillThreeExtr(Symbol(), PERIOD_H1);
 pstructH1 = FillFourPrice(Symbol(), PERIOD_H1);
 
 CreateExtrLines(estructMN, PERIOD_MN1, clrAntiqueWhite);
 CreateExtrLines(estructW1,  PERIOD_W1, clrDarkSalmon);
 CreateExtrLines(estructD1,  PERIOD_D1, clrOrange);
 CreateExtrLines(estructH4,  PERIOD_H4, clrYellow);
 CreateExtrLines(estructH1,  PERIOD_H1, clrLime);
 CreatePriceLines(pstructH1, PERIOD_H1, clrAqua);  
//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 DeleteExtrLines(PERIOD_MN1);
 DeleteExtrLines(PERIOD_W1);
 DeleteExtrLines(PERIOD_D1);
 DeleteExtrLines(PERIOD_H4);
 DeleteExtrLines(PERIOD_H1);
 DeletePriceLines(PERIOD_H1);
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
    estructMN = FillThreeExtr(Symbol(), PERIOD_MN1);
    MoveExtrLines(estructMN, PERIOD_MN1);
   }
   if(barW1.isNewBar() > 0)
   {
    estructW1 = FillThreeExtr(Symbol(), PERIOD_W1);
    MoveExtrLines(estructW1, PERIOD_W1);
   }
   if(barD1.isNewBar() > 0)
   {
    estructD1 = FillThreeExtr(Symbol(), PERIOD_D1);
    MoveExtrLines(estructD1, PERIOD_D1);
   }
   if(barH4.isNewBar() > 0)
   {
    estructH4 = FillThreeExtr(Symbol(), PERIOD_H4);
    MoveExtrLines(estructH4, PERIOD_H4);
   }
   if(barH1.isNewBar() > 0)
   {
    estructH1 = FillThreeExtr(Symbol(), PERIOD_H1);
    MoveExtrLines(estructH1, PERIOD_H1);
    
    pstructH1 = FillFourPrice(Symbol(), PERIOD_H1);
    MovePriceLines(pstructH1, PERIOD_H1);
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID графика
                 const string          name="HLine",      // им€ линии
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
  Print(__FUNCTION__, ": не удалось создать горизонтальную линию!  од ошибки = ",GetLastError());
  return(false);
 }
//--- установим цвет линии
 ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль отображени€ линии
 ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину линии
 ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- отобразим на переднем (false) или заднем (true) плане
 ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- успешное выполнение
 return(true);
}

bool HLineMove(const long   chart_ID=0,   // ID графика
               const string name="HLine", // им€ линии
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
  Print(__FUNCTION__, ": не удалось переместить горизонтальную линию!  од ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

bool HLineDelete(const long   chart_ID=0,   // ID графика
                 const string name="HLine") // им€ линии
{
//--- сбросим значение ошибки
 ResetLastError();
//--- удалим горизонтальную линию
 if(!ObjectDelete(chart_ID,name))
 {
  Print(__FUNCTION__, ": не удалось удалить горизонтальную линию!  од ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

FourPrice FillFourPrice(string symbol, ENUM_TIMEFRAMES tf)
{
 FourPrice result = {{ZERO, 0}, {ZERO, 0}, {ZERO, 0}, {ZERO, 0}};
 double open_buf[1];
 double close_buf[1];
 double high_buf[1];
 double low_buf[1];
   
 CopyOpen (symbol, tf, 1, 1,  open_buf);
 CopyClose(symbol, tf, 1, 1, close_buf);
 CopyHigh (symbol, tf, 1, 1,  high_buf);
 CopyLow  (symbol, tf, 1, 1,   low_buf);
 
 result.open.price  = open_buf[0];
 result.close.price = close_buf[0];
 result.high.price  = high_buf[0];
 result.low.price   = low_buf[0];
 return result;
}

void CreatePriceLines(const FourPrice& fp, ENUM_TIMEFRAMES tf, color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open" , 0,  fp.open.price, clr);
 HLineCreate(0, name+"close", 0, fp.close.price, clr);
 HLineCreate(0, name+"high" , 0,  fp.high.price, clr);
 HLineCreate(0, name+"low"  , 0,   fp.low.price, clr);
}

void MovePriceLines(const FourPrice& fp, ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open" ,  fp.open.price);
 HLineMove(0, name+"close", fp.close.price); 
 HLineMove(0, name+"high" ,  fp.high.price); 
 HLineMove(0, name+"low"  ,   fp.low.price);  
}

void DeletePriceLines(ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"open");
 HLineDelete(0, name+"close");
 HLineDelete(0, name+"high");
 HLineDelete(0, name+"low");
}

ThreeExtr FillThreeExtr (string symbol, ENUM_TIMEFRAMES tf)
{
 ThreeExtr result = {{ZERO, 0}, {ZERO, 0}, {ZERO, 0}};
 
 //TO DO: Fill three extr
 return result;
}

void CreateExtrLines(const ThreeExtr& te, ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"one"   , 0,   te.one.price, clr);
 HLineCreate(0, name+"two"   , 0,   te.two.price, clr);
 HLineCreate(0, name+"three" , 0, te.three.price, clr);
}

void MoveExtrLines(const ThreeExtr& te, ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   ,   te.one.price);
 HLineMove(0, name+"two"   ,   te.two.price);
 HLineMove(0, name+"three" , te.three.price);
}

void DeleteExtrLines(ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one");
 HLineMove(0, name+"two");
 HLineMove(0, name+"three");
}