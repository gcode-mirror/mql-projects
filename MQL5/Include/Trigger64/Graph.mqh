//+------------------------------------------------------------------+
//|                                                        Graph.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <StringUtilities.mqh>
#include "TestFunc.mqh"
#include "PosConst.mqh"
#include "PositionSys.mqh"
//графическая библиотека

//

class GraphModule  //класс графического модуля
 {
  private:

  public:
  void CreateEdit(long             chart_id,         // id графика
                int              sub_window,       // номер окна (подокна)
                string           name,             // имя объекта
                string           text,             // отображаемый текст
                ENUM_BASE_CORNER corner,           // угол графика
                string           font_name,        // шрифт
                int              font_size,        // размер шрифта
                color            font_color,       // цвет шрифта
                int              x_size,           // ширина
                int              y_size,           // высота
                int              x_distance,       // координата по оси X
                int              y_distance,       // координата по оси Y
                long             z_order,          // приоритет
                color            background_color, // цвет фона
                bool             read_only);        // флаг "только для чтения"
   void CreateLabel(long               chart_id,   // id графика
                 int                sub_window, // номер окна (подокна)
                 string             name,       // имя объекта
                 string             text,       // отображаемый текст
                 ENUM_ANCHOR_POINT  anchor,     // точка привязки
                 ENUM_BASE_CORNER   corner,     // угол графика
                 string             font_name,  // шрифт
                 int                font_size,  // размер шрифта
                 color              font_color, // цвет шрифта
                 int                x_distance, // координата по оси X
                 int                y_distance, // координата по оси Y
                 long               z_order);    // приоритет  
   public:                            
   void DeleteObjectByName(string name); //удаляет объект   
   void SetInfoPanel(PositionSys * my_pos);    
   void DeleteInfoPanel();     
   GraphModule();  //конструктор класса
  ~GraphModule();  //деструктор класса        
 };

void GraphModule::CreateEdit(long             chart_id,         // id графика
                int              sub_window,       // номер окна (подокна)
                string           name,             // имя объекта
                string           text,             // отображаемый текст
                ENUM_BASE_CORNER corner,           // угол графика
                string           font_name,        // шрифт
                int              font_size,        // размер шрифта
                color            font_color,       // цвет шрифта
                int              x_size,           // ширина
                int              y_size,           // высота
                int              x_distance,       // координата по оси X
                int              y_distance,       // координата по оси Y
                long             z_order,          // приоритет
                color            background_color, // цвет фона
                bool             read_only)        // флаг "только для чтения"
  {
// Если объект создался успешно, то...
   if(ObjectCreate(chart_id,name,OBJ_EDIT,sub_window,0,0))
     {
      // ...установим его свойства
      ObjectSetString (chart_id,name,OBJPROP_TEXT,text);                 // отображаемый текст
      ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);            // установка угла графика
      ObjectSetString (chart_id,name,OBJPROP_FONT,font_name);            // установка шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,font_size);       // установка размера шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,font_color);         // цвет шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_BGCOLOR,background_color); // цвет фона
      ObjectSetInteger(chart_id,name,OBJPROP_XSIZE,x_size);             // ширина
      ObjectSetInteger(chart_id,name,OBJPROP_YSIZE,y_size);             // высота
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,x_distance);     // установка координаты X
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,y_distance);     // установка координаты Y
      ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);         // нельзя выделить объект, если FALSE
      ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,z_order);           // приоритет объекта
      ObjectSetInteger(chart_id,name,OBJPROP_READONLY,read_only);       // только для чтения
      ObjectSetInteger(chart_id,name,OBJPROP_ALIGN,ALIGN_LEFT);         // выравнивание по левому краю
      ObjectSetString (chart_id,name,OBJPROP_TOOLTIP,"\n");              // нет всплывающей подсказки, если "\n"
     }                 
  }
//+------------------------------------------------------------------+
//| Создает объект Label                                             |
//+------------------------------------------------------------------+
void GraphModule::CreateLabel(long               chart_id,   // id графика
                 int                sub_window, // номер окна (подокна)
                 string             name,       // имя объекта
                 string             text,       // отображаемый текст
                 ENUM_ANCHOR_POINT  anchor,     // точка привязки
                 ENUM_BASE_CORNER   corner,     // угол графика
                 string             font_name,  // шрифт
                 int                font_size,  // размер шрифта
                 color              font_color, // цвет шрифта
                 int                x_distance, // координата по оси X
                 int                y_distance, // координата по оси Y
                 long               z_order)    // приоритет
  {
// Если объект создался успешно, то...
   if(ObjectCreate(chart_id,name,OBJ_LABEL,sub_window,0,0))
     {
      // ...установим его свойства
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);              // отображаемый текст
      ObjectSetString(chart_id,name,OBJPROP_FONT,font_name);         // установка шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,font_color);      // установка цвета шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,anchor);         // установка точки привязки
      ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);         // установка угла графика
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,font_size);    // установка размера шрифта
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,x_distance);  // установка координаты X
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,y_distance);  // установка координаты Y
      ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);      // нельзя выделить объект, если FALSE
      ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,z_order);        // приоритет объекта
      ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n");           // нет всплывающей подсказки, если "\n"
     }
  }
//+------------------------------------------------------------------+
//|   Удаляет объект по имени                                        |
//+------------------------------------------------------------------+
void GraphModule::DeleteObjectByName(string name)
  {
   int  sub_window=0;      // Возвращаемый номер подокна, в котором находится объект
   bool res       =false;  // Результат после попытки удалить объект
//--- Найдём объект по имени
   sub_window=ObjectFind(ChartID(),name);
//---
   if(sub_window>=0) // Если найден,..
     {
      res=ObjectDelete(ChartID(),name); // ...удалим его
      //---
      // Если была ошибка при удалении, сообщим об этом
      if(!res)
         Print("Ошибка при удалении объекта: ("+IntegerToString(GetLastError())+"): "+ErrorDescription(GetLastError()));
     }
  }

void GraphModule::SetInfoPanel(PositionSys  * my_pos)  //устанавливает графическую панель
  {
  
//--- Режим визуализации или реального времени
   if(IsVisualMode() || IsRealtime())
     {
      int               y_bg=18;             // Координата по оси Y для фона и заголовка
      int               y_property=32;       // Координата по оси Y для списка свойств и их значений
      int               line_height=12;      // Высота строки
      //---
      int               font_size=8;         // Размер шрифта
      string            font_name="Calibri"; // Шрифт
      color             font_color=clrWhite; // Цвет шрифта
      //---
      ENUM_ANCHOR_POINT anchor=ANCHOR_RIGHT_UPPER; // Точка привязки в правом верхнем углу
      ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER; // Начало координат в правом верхнем углу графика
      //--- Координаты по оси X
      int               x_first_column=120;  // Первый столбец (названия свойств)
      int               x_second_column=10;  // Второй столбец (значения свойств)
      //--- Тестирование в режиме визуализации
      if(IsVisualMode())
        {
         y_bg=2;
         y_property=16;
        }
      //--- Массив с координатами по оси Y для названий свойств позиции и их значений
      int               y_prop_array[INFOPANEL_SIZE];
      //--- Заполним массив координатами для каждой строки на информационной панели
      for(int i=0; i<INFOPANEL_SIZE; i++)
        {
         if(i==0) y_prop_array[i]=y_property;
         else     y_prop_array[i]=y_property+line_height*i;
        }
      //--- Фон инфо-панели
      CreateEdit(0,0,"InfoPanelBackground","",corner,font_name,8,clrWhite,230,250,231,y_bg,0,C'15,15,15',true);
      //--- Заголовок инфо-панели
      CreateEdit(0,0,"InfoPanelHeader","  POSITION  PROPERTIES",corner,font_name,8,clrWhite,230,14,231,y_bg,1,clrFireBrick,true);
      //--- Список названий свойств позиции и их значений
      for(int i=0; i<INFOPANEL_SIZE; i++)
        {
         //--- Название свойства
         CreateLabel(0,0,pos_prop_names[i],pos_prop_texts[i],anchor,corner,font_name,font_size,font_color,x_first_column,y_prop_array[i],2);
         //--- Значение свойства
         CreateLabel(0,0,pos_prop_values[i],my_pos.GetPropertyValue(i),anchor,corner,font_name,font_size,font_color,x_second_column,y_prop_array[i],2);
        }
      //---
      ChartRedraw(); // Перерисовать график
     }
  }
//+------------------------------------------------------------------+
//| Удаляет информационную панель                                    |
//+------------------------------------------------------------------+
void GraphModule::DeleteInfoPanel()
  {
   DeleteObjectByName("InfoPanelBackground");   // Удалить фон панели
   DeleteObjectByName("InfoPanelHeader");       // Удалить заголовок панели
//--- Удалить свойства позиции и их значения
   for(int i=0; i<INFOPANEL_SIZE; i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      DeleteObjectByName(pos_prop_names[i]);    // Удалить свойство
      DeleteObjectByName(pos_prop_values[i]);   // Удалить значение
     }
//---
   ChartRedraw(); // Перерисовать график
  }
  
  GraphModule::GraphModule(void) //конструктор класса
   {

   }
  
  GraphModule::~GraphModule(void) //деструктор класса
   {
   
   } 