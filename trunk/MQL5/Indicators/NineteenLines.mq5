//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <CExtremumCalc_NE.mqh>
#include <Lib CisNewBar.mqh>

 input int    period_ATR = 100;      //Период ATR для канала
 input double percent_ATR = 0.03; //Ширина канала уровня в процентах от ATR
 input double precentageATR_price = 2; //Процентр ATR для нового экструмума
 

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
   
// if(show_Extr_H4)  потому что ATR H4  требуется для расчетов любых экстремумов
  if(!calcH4.isATRCalculated())
   result = false;
   
 if(show_Extr_H1)
  if(!calcH1.isATRCalculated())
   result = false;   
   
 if(!result)
  PrintFormat("%s Не получилось загрузить буфера ATR, подожди чутка братан. Ошибочка вышла %d", __FUNCTION__, GetLastError()); 
 return(result);
}
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID графика
                 const string          name="HLine",      // имя линии
                 const int             sub_window=0,      // номер подокна
                 double                price=0,           // цена линии
                 const color           clr=clrRed,        // цвет линии
                 const int             width=1,           // толщина линии
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линии
                 const bool            back=true          // на заднем плане
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

void FillThreeExtr (CExtremumCalc &extrcalc, SExtremum &resArray[])
{
 for(int i = 0; !extrcalc.isThreeExtrExist(); i++)
 {
   extrcalc.RecountExtremum(i);
 }
 
 for(int j = 0; j < 3; j++)
 {
  resArray[j] = extrcalc.getExtr(j);
 }
 //PrintFormat("num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", resArray[0].direction, resArray[0].price, resArray[1].direction, resArray[1].price, resArray[2].direction, resArray[2].price);
}

void RecountThreeExtr (CExtremumCalc &extrcalc, SExtremum &resArray[])
{
 extrcalc.RecountExtremum(0);

 for(int j = 0; j < 3; j++)
 {
  resArray[j] = extrcalc.getExtr(j);
 }
 //PrintFormat("num0: {%d, %0.5f}; num1: {%d, %0.5f}; num2: {%d, %0.5f};", resArray[0].direction, resArray[0].price, resArray[1].direction, resArray[1].price, resArray[2].direction, resArray[2].price);
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
//+------------------------------------------------------------------+
//| Создает прямоугольную метку                                      |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // ID графика
                     const string           name="RectLabel",         // имя метки
                     const int              sub_window=0,             // номер подокна
                     const int              x=0,                      // координата по оси X
                     const int              y=0,                      // координата по оси Y
                     const int              width=50,                 // ширина
                     const int              height=18,                // высота
                     const color            back_clr=C'236,233,216',  // цвет фона
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // тип границы
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // угол графика для привязки
                     const color            clr=clrRed,               // цвет плоской границы (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // стиль плоской границы
                     const int              line_width=1,             // толщина плоской границы
                     const bool             back=false,               // на заднем плане
                     const bool             selection=false,          // выделить для перемещений
                     const bool             hidden=true)              // скрыт в списке объектов
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- создадим прямоугольную метку
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": не удалось создать прямоугольную метку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- установим координаты метки
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- установим размеры метки
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- установим цвет фона
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- установим тип границы
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- установим цвет плоской рамки (в режиме Flat)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль линии плоской рамки
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину плоской границы
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- включим (true) или отключим (false) режим перемещения метки мышью
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- успешное выполнение
   return(true);
  }
//+------------------------------------------------------------------+
//| Удаляет прямоугольную метку                                      |
//+------------------------------------------------------------------+
bool RectLabelDelete(const long   chart_ID=0,       // ID графика
                     const string name="RectLabel") // имя метки
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- удалим метку
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": не удалось удалить прямоугольную метку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- успешное выполнение
   return(true);
  }
//+------------------------------------------------------------------+
//| Создает прямоугольную метку                                      |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // ID графика
                 const string            name="Label",             // имя метки
                 const int               sub_window=0,             // номер подокна
                 const int               x=0,                      // координата по оси X
                 const int               y=0,                      // координата по оси Y
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки
                 const string            text="Label",             // текст
                 const string            font="Arial",             // шрифт
                 const int               font_size=10,             // размер шрифта
                 const color             clr=clrRed,               // цвет
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки
                 const bool              back=false,               // на заднем плане
                 const bool              selection=false,          // выделить для перемещений
                 const bool              hidden=true)              // скрыт в списке объектов
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- создадим текстовую метку
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": не удалось создать текстовую метку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- установим координаты метки
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- установим текст
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- установим размер шрифта
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- установим способ привязки
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- установим цвет
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- отобразим на переднем (false) или заднем (true) плане
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- включим (true) или отключим (false) режим перемещения метки мышью
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- успешное выполнение
   return(true);
  }

//+------------------------------------------------------------------+
//| Удаляет текстовую метку                                          |
//+------------------------------------------------------------------+
bool LabelDelete(const long   chart_ID=0,   // ID графика
                 const string name="Label") // имя метки
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- удалим метку
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": не удалось удалить текстовую метку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- успешное выполнение
   return(true);
  }