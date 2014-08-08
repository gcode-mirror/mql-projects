//+------------------------------------------------------------------+
//|                                                       Button.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| класс кнопки                                                     |
//+------------------------------------------------------------------+

class Button
{
 private:
  string           _name;             // имя объекта
  uint             _x,_y;             // координаты кнопки
  uint             _width,_height;    // ширина и высота кнопки
  string           _caption;          // надпись на кнопке
  long             _chart_id;         // id графика
  int              _sub_window;       // номер окна (подокна) 
  ENUM_BASE_CORNER _corner;           // угол графика  
  long             _z_order;          // приоритет   
 public:
  //методы set
  Button(string name,
         string caption,
         uint x,
         uint y,
         uint width,
         uint height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order
         ): 
  _name (name),
  _caption(caption), 
  _x(x),_y(y),
  _width(width),
  _height(height),
  _chart_id(chart_id),
  _sub_window(sub_window),
  _corner(corner),
  _z_order(z_order)
  {
   bool objectCreated;
   //проверка уникальности имени объекта
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
    
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_BUTTON,_sub_window,0,0); //пытаемся создать объект

   if(objectCreated)  //если графический объект успешно создан
     {

      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // установка угла графика
      ObjectSetString(_chart_id,  _name,OBJPROP_TEXT,_caption);                   // надпись на кнопке
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // ширина кнопки
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // высота кнопки
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // установка координаты X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // установка координаты Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // нельзя выделить объект, если FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // приоритет объекта
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // нет всплывающей подсказки, если "\n"
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrSilver);               // цвет заднего фона
       
     }
   }
  };  //конструктор класса кнопка
 ~Button()   
  {
   int  sub_window=0;      // Возвращаемый номер подокна, в котором находится объект
   bool res       =false;  // Результат после попытки удалить объект
   sub_window=ObjectFind(ChartID(),_name);
   if(sub_window>=0) 
     {
      res=ObjectDelete(ChartID(),_name); // ...удалим его
      if(!res)
         Print("Ошибка при удалении объекта: ",_name);
     }
  }; //деструктор класса
};
