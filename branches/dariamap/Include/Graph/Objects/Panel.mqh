//+------------------------------------------------------------------+
//|                                                        Panel.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Button.mqh"   // подключаем объект "Кнопка"
#include "Input.mqh"    // подключаем объект "Поле ввода"
#include "Label.mqh"    // подключаем объект "Текстовое поле"
#include "List.mqh"     // подключаем объект "Список"

 //перечисление типов объектов на панеле 
 enum PANEL_ELEMENTS
  { 
   PE_BUTTON = 0, //кнопка
   PE_INPUT,      //поле ввода
   PE_LABEL,      //лейбл
   PE_LIST        //список
  };

//+------------------------------------------------------------------+
//| класс панели                                                     |
//+------------------------------------------------------------------+

class Panel
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
  //---- переменные для хренения количества объектов различного класса
  string           _object_name[];    // массив имен созданных объектов
  uint             _n_objects;        // количество объектов 
  bool             _show_panel;       // флаг отображения панели на графике. true - панель отображена, false - панель скрыта 
 private:
  // приватные методы панели
  void DrawPanel (bool show_panel);   // приватный метод, оторбражающий или скрывающий панель с графика
 public:
  //методы set
  
  Panel(string name,
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
  _z_order(z_order),
  _n_objects(0),
  _show_panel(true)
  {
   bool objectCreated;
   //проверка уникальности имени объекта
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
   
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //пытаемся создать объект

   if(objectCreated)  //если графический объект успешно создан
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // установка угла графика
    //  ObjectSetInteger(_chart_id, _name,OBJPROP_FONTSIZE,_style.font_size);     // установка размера шрифта
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // установка координаты X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // установка координаты Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // установка ширины
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,15);                        // установка высоты шапки         
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // нельзя выделить объект, если FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // приоритет объекта
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // нет всплывающей подсказки, если "\n"
        
     }
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //пытаемся создать объект

   if(objectCreated)  //если графический объект успешно создан
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // установка угла графика
    //  ObjectSetInteger(_chart_id, _name,OBJPROP_FONTSIZE,_style.font_size);     // установка размера шрифта
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // установка координаты X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // установка координаты Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // установка ширины
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // установка высоты шапки         
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // нельзя выделить объект, если FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // приоритет объекта
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // нет всплывающей подсказки, если "\n"
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrSilver);               // цвет заднего фона  
     }     
   }
  };  //конструктор класса кнопка
 ~Panel()   
  {
   int  sub_window=0;      // Возвращаемый номер подокна, в котором находится объект
   bool res       =false;  // Результат после попытки удалить объект
   // проходим по всем объектам на панеле и удаляем их
   for (int index=0;index<ArraySize(_object_name);index++)
    {
     sub_window=ObjectFind(ChartID(),_object_name[index]);
     if(sub_window>=0) 
       {
        res=ObjectDelete(ChartID(),_object_name[index]); // ...удалим его
        if(!res)
         Print("Ошибка при удалении объекта: ",_object_name[index]);
       }     
    }
   sub_window=ObjectFind(ChartID(),_name);
   if(sub_window>=0) 
     {
      res=ObjectDelete(ChartID(),_name); // ...удалим его
      if(!res)
         Print("Ошибка при удалении объекта: ",_name);
     }
  }; //деструктор класса
  
//+-------------------------------------------------------------------+
//| Публичные методы класса панели                                    |
//+-------------------------------------------------------------------+

 //----  скрывает элементы панели
 void HidePanel ();
 //----  отображает элементы панели
 void ShowPanel (); 
 //----  создает объекты 
 void AddElement (PANEL_ELEMENTS elem_type, string elem_name,string caption,uint x,uint y,uint w,uint h);
 //---   перемещает панель на координаты x, y
 void MoveTo(int x,int y);
 //---   показана ли панель или нет
 bool IsPanelShown(){ return (_show_panel); };
};

//описание методов класса Panel

//+-------------------------------------------------------------------+
//| Приватные методы класса панели                                    |
//+-------------------------------------------------------------------+

 void Panel::DrawPanel(bool show_panel)
  {
   int index;
   _show_panel = !show_panel;
   // изменение видимости панели
   ObjectSetInteger(_chart_id, _name,OBJPROP_HIDDEN,show_panel);
    for (index=0;index<_n_objects;index++)
       { 
        // изменение видимости элементов панели
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_HIDDEN,show_panel);  
       }
  }

//+-------------------------------------------------------------------+
//| Публичные методы класса панели                                    |
//+-------------------------------------------------------------------+

 void Panel::HidePanel(void)
  //скрывает элементы панели
  {
   DrawPanel(true);
  }
  
 void Panel::ShowPanel(void)
  //отображает элементы панели
  {
   DrawPanel(false);
  }

 void Panel::AddElement(PANEL_ELEMENTS elem_type,string elem_name,string caption,uint x,uint y,uint w,uint h)
  //добавляет элемент с заданным именем
  {
   //возвращаемый номер подокна, в котором находится объект
   int  sub_win=0;      
   //создаем уникальное имя внутри панели
   string new_name = _name + "_" + elem_name;
   //проверка на существования объекта с таким же именем
   sub_win = ObjectFind(_chart_id,new_name);
   //если объект с таким именем не существует
   if (sub_win < 0)
    {
     //сохраняем имя созданного объекта в массив имен
     _n_objects++; 
     ArrayResize(_object_name, _n_objects,0);
     _object_name[_n_objects-1] = new_name;
     //создание объектов по типу
     switch (elem_type)
      {
       //объект "Кнопка"
       case PE_BUTTON:
       new Button(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;
       //объект "Поле ввода"
       case PE_INPUT:
       new Input(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;
       //объект "Лейбл"
       case PE_LABEL:
       new Label(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;              
      }
    }
  }
  
  void Panel::MoveTo(int x,int y)
  //перемещает панель с объектами на координаты x, y
   {
    //индекс для цикла
    uint index;
    // смещение координат  
    int x_diff,y_diff;
    // текущие координаты объекта
    int x_now,y_now;
    //если координаты удовлетворяют условиям
    if (x>=0&&y>=0)
     {
      //вычисляем смещение координат
      x_diff = x-ObjectGetInteger(_chart_id,_name,OBJPROP_XDISTANCE);
      y_diff = y-ObjectGetInteger(_chart_id,_name,OBJPROP_YDISTANCE);
      //перемещаем панель на новые координаты
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,x);  // установка координаты X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,y);  // установка координаты Y
      //пробегаем по всем элементам массива имен объектов 
      for (index=0;index<_n_objects;index++)
       {
        //получаем текущие координаты объектов
        x_now = ObjectGetInteger(_chart_id,_object_name[index],OBJPROP_XDISTANCE);
        y_now = ObjectGetInteger(_chart_id,_object_name[index],OBJPROP_YDISTANCE);        
        //и перемещаем все объекты на заданные координаты в соответсвии со своми координатами
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_XDISTANCE,x_now+x_diff);
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_YDISTANCE,y_now+y_diff);        
       }
     }
   }