//+------------------------------------------------------------------+
//|                                                        Label.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//#include <Graph\Style.mqh>  //подключаем библиотеку стилей
//+------------------------------------------------------------------+
//| Класс списка                                                     |
//+------------------------------------------------------------------+
class List
{
 private:
  string           _name;             // имя объекта
  uint             _x,_y;             // координаты списка
  uint             _width,_height;    // ширина спсика и высота шапки 
  short             _elem_height;     // высота элемента
  string           _caption;          // надпись на шапке
  long             _chart_id;         // id графика
  int              _sub_window;       // номер окна (подокна) 
  ENUM_BASE_CORNER _corner;           // угол графика  
  long             _z_order;          // приоритет   
  short            _n_elems;          // количество элементов списка
  
 void CreateElem(string elem_name,string caption,uint y);   // создает элемент списка
   
 public:
  //методы set
  List(string name,
         string caption,
         uint x,
         uint y,
         uint elem_height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order
         ): 
  _name (name),
  _caption(caption), 
  _x(x),_y(y),
  _elem_height(elem_height),
  _chart_id(chart_id),
  _sub_window(sub_window),
  _corner(corner),
  _z_order(z_order),
  _n_elems(0)
  {
   bool objectCreated;
   //проверка уникальности имени объекта
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
    
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //пытаемся создать объект

   if(objectCreated)  //если графический объект успешно создан
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // установка угла графика
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrAliceBlue);
      ObjectSetString(_chart_id, _name,OBJPROP_TEXT,"");                          // надпись   
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // установка координаты X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // установка координаты Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // установка ширины
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // установка высоты                  
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // нельзя выделить объект, если FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // приоритет объекта
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // нет всплывающей подсказки, если "\n"

        
     }
   }
  };  //конструктор класса кнопка
 ~List()   
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
  void AddToList(string caption,int value);  //добавляет элемент Integer списка 
  void AddToList(string caption,double value,short digits=8);  //добавляет элемент Double списка 
  void AddToList(string caption,string value);  //добавляет элемент String списка 
  void AddToList(string caption,datetime value,int flags=TIME_DATE|TIME_MINUTES);  //добавляет элемент Datetime списка       
};

 void List::CreateElem(string elem_name,string caption,uint y)
 {
   bool objectCreated;
       
   objectCreated = ObjectCreate(_chart_id,elem_name,OBJ_LABEL,_sub_window,0,0); //пытаемся создать объект
    
    if(objectCreated)  //если графический объект успешно создан
     {
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_CORNER,_corner);                  // установка угла графика
      ObjectSetString (_chart_id, elem_name, OBJPROP_TEXT,caption);                    // надпись   
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_XDISTANCE,_x);                    // установка координаты X
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_YDISTANCE,y);                     // установка координаты Y
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_XSIZE,_width);                    // установка ширины
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_YSIZE,_height);                   // установка высоты                  
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_SELECTABLE,false);                // нельзя выделить объект, если FALSE
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_ZORDER,_z_order);                 // приоритет объекта
      ObjectSetString (_chart_id, elem_name, OBJPROP_TOOLTIP,"\n");                    // нет всплывающей подсказки, если "\n"
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_COLOR,clrWhite);                // цвет шрифта 
     }
 }

 void List::AddToList(string caption,int value)
  {
    AddToList(caption,IntegerToString(value));
  }
  
 void List::AddToList(string caption,double value,short digits=8)
  {
    AddToList(caption,DoubleToString(value,digits));
  }
  
 void List::AddToList(string caption,datetime value,int flags=TIME_DATE|TIME_MINUTES)
  { 
    AddToList(caption,TimeToString(value,flags));
  }
 void List::AddToList(string caption,string value)
  {
    string new_caption = caption+" : "+value;  //строка в элементе списка
    string new_name  = '*'+_name+'_'+IntegerToString(_n_elems);  //записываем новое имя
    CreateElem(new_name,new_caption,_y+_n_elems*_elem_height);     //создаем новый элемент списка
    _n_elems++; //увеличиваем количество элементов списка на единицу
  }