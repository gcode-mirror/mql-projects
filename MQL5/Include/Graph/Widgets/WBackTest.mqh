//+------------------------------------------------------------------+
//|                                                    WBackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <Graph\Objects\Panel.mqh>  //подключаем библиотеку панели
//+------------------------------------------------------------------+
//| Виджет свойств позиций                                           |
//+------------------------------------------------------------------+
 class WBackTest 
  {
   private:
    // поля виджета
    Panel * _wBackTest;  // объект панели бэктеста
    bool    _showPanel; // флаг отображения панели на графике. true - панель отображена, false - панель скрыта 
   public:
    // методы графической панели
    void HidePanel (){_wBackTest.HidePanel();};  // скрывает панель
    void ShowPanel (){_wBackTest.ShowPanel();};  // отображает панель на графике
    // конструктор класса виджета
    WBackTest (string name,
         string caption,
         uint x,
         uint y,
         uint width,
         uint height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order)
     { 
      // создаем объект панели виджета
      _wBackTest = new Panel(name, caption, x, y, width, height, chart_id, sub_window, corner, z_order);
      // создаем элементы панели
      _wBackTest.AddElement (PE_LABEL,"label",caption,x+13,y,width,height);              // тело панели
      _wBackTest.AddElement (PE_BUTTON,"close_button","x",width-16,2,13,13);             // кнопка закрытия панели
      _wBackTest.AddElement (PE_BUTTON,"all_expt","все эксперты",0,30,width/2,20);       // кнопка
      _wBackTest.AddElement (PE_BUTTON,"cur_expt","этот эксперт",width/2,30,width/2,20); // кнопка      
     };
  };   