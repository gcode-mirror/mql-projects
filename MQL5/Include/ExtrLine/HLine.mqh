//+------------------------------------------------------------------+
//|                                                        HLine.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

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
