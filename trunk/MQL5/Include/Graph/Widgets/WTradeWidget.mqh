//+------------------------------------------------------------------+
//|                                                    WBackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <Graph\Objects\Panel.mqh>  //подключаем библиотеку панели
#include <TradeManager\TMPCTM.mqh>  //подключаем торговую библиотеку 
//+------------------------------------------------------------------+
//| Торговый виджет                                                  |
//+------------------------------------------------------------------+
  
 class WTradeWidget 
  {
   private:
    // системные поля
    string  _symbol;         // символ
    CTMTradeFunctions *_ctm; // объект класса торговой библиотеки
    // поля виджета
    Panel * _wTradeWidget;   // объект торгового виджета
    Panel * _subPanel;       // панель дополнительных инструментов
    bool    _showPanel;      // флаг отображения панели на графике. true - панель отображена, false - панель скрыта 
    string  _name;           // имя виджета
    string  _caption;        // наименование виджета
    uint    _x;              // положение x
    uint    _y;              // положение y
    uint    _sx;             // текущее положение курсора X
    uint    _sy;             // текущее положение курсора Y
    long    _chart_id;       // id графика 
    int     _sub_window;     
    long    _z_order;
    bool    _widgetMove;     // флаг перемещение виджета
   public:
    // методы графической панели
    void   HidePanel (){_wTradeWidget.HidePanel();};  // скрывает панель
    void   ShowPanel (){_wTradeWidget.ShowPanel();};  // отображает панель на графике
    void   OnTick();                                  // для обновления данных на панели
    void   Action(string sparam);                     // действия панели
    
    // конструктор класса виджета
    WTradeWidget (
         string symbol,
         string name,
         string caption,
         uint x,
         uint y,
         long chart_id,
         int sub_window,
         long z_order)
     { 
      // пытаемся создать объект класса CTMTradeFunctions
      _ctm = new CTMTradeFunctions();
      // заполняем приватные поля класса
      _symbol = symbol;
      _name = name;
      _caption = caption;
      _x = x;
      _y = y;
      _chart_id = chart_id;
      _sub_window = sub_window;
      _z_order = z_order;
      _widgetMove = false;
      // создаем объект панели виджета
      _wTradeWidget = new Panel(name, caption, x, y, 200, 170, chart_id, sub_window, CORNER_LEFT_UPPER, z_order);
      // создаем панель дополнительных параметров
      _subPanel     = new Panel(name+"_subPanel","",x,y+140,200,130,chart_id,sub_window,CORNER_LEFT_UPPER,z_order);
      // создаем элементы основной панели
      _wTradeWidget.AddElement (PE_BUTTON,"move","",0,0,200,10);                       // кнопка перемещения панели
      _wTradeWidget.AddElement (PE_BUTTON,"close_widget","",190,2,8,8);                // кнопка закрытия панели
      _wTradeWidget.AddElement (PE_BUTTON,"inst_buy","BUY",0,10,100,50);               // кнопка на немедленную покупку
      _wTradeWidget.AddElement (PE_BUTTON,"inst_sell","SELL",100,10,100,50);           // кнопка на немедленную продажу   
      _wTradeWidget.AddElement (PE_INPUT, "volume","1.0",70,10,60,25);                 // лот      
      _wTradeWidget.AddElement (PE_BUTTON,"close","CLOSE",70,35,60,25);                // кнопка закрытия позиции   
      _wTradeWidget.AddElement (PE_LABEL, "ask","0.0",0,40,70,20);                     // лейбл цены ASK
      _wTradeWidget.AddElement (PE_LABEL, "bid","0.0",130,40,70,20);                   // лейбл цены BID
      _wTradeWidget.AddElement (PE_LABEL, "sl_label","stop loss",0,60,100,30);         // лейбл стоп лосса
      _wTradeWidget.AddElement (PE_LABEL, "tp_label","take profit",100,60,100,30);     // лейбл тейк профита           
      _wTradeWidget.AddElement (PE_INPUT, "stoploss","0.0",0,90,100,30);               // stop loss
      _wTradeWidget.AddElement (PE_INPUT, "takeprofit","0.0",100,90,100,30);           // take profit      
      _wTradeWidget.AddElement (PE_BUTTON,"edit_pos","изменить позицию",0,120,200,20); // изменяет позицию\     
      // создаем элементы дополнительной панели
      _subPanel.AddElement (PE_BUTTON,"buy_stop","BUY STOP",0,0,100,60);               // кнопка BUY STOP
      _subPanel.AddElement (PE_BUTTON,"sell_stop","SELL STOP",100,0,100,60);           // кнопка SELL STOP

      _subPanel.AddElement (PE_BUTTON,"buy_limit","BUY LIMIT",0,60,100,60);            // кнопка BUY LIMIT
      _subPanel.AddElement (PE_BUTTON,"sell_limit","SELL LIMIT",100,60,100,60);        // кнопка SELL LIMIT
      
      _subPanel.AddElement (PE_INPUT,"price_stop_limit","0.0",70,45,60,30);            // цена ордер стопа и лимит ордера
      
     // _subPanel.AddElement (PE_LIST,"list_orders","",0,120,100,50);                    // список ордеров
      _subPanel.AddElement (PE_BUTTON,"delete_orders","удалить все ордера",0,120,200,20); // удалть все ордера          
     };
    // деструктор класса виджета
    ~WTradeWidget()
     {
      // удаляем объекты виджета
      delete _wTradeWidget;
      delete _subPanel;
     };
  };   
  
  // для обновления данных на панели
  void WTradeWidget::OnTick(void)
   {
    ObjectSetString(_chart_id,_name+"_"+"ask",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) );
    ObjectSetString(_chart_id,_name+"_"+"bid",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) );    
   }
   
  // метод действий панели
  void WTradeWidget::Action(string sparam)
   {
    int stopLoss;
    int takeProfit;
    double sl,tp;
    double orderPrice;
    if (sparam == _name+"_inst_buy")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_ASK)-stopLoss*_Point;
        }
       else if (stopLoss == 0)
         sl = 0.0;
       else 
         Print("Ошибка отправки ордера BUY. Не корректно задан стоп лосс");
         
          
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_ASK)+takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;       
       else 
        Print("Ошибка отправки ордера BUT. Не корректно задан тейк профит");
         
       _ctm.PositionOpen(_symbol,POSITION_TYPE_BUY,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_ASK),
                         sl,
                         tp,
                         "немедленно купили"); 
     }
    if (sparam == _name+"_inst_sell")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_BID)+stopLoss*_Point;
        }
       else if (stopLoss == 0)
        sl = 0.0;
       else 
        Print("Ошибка отправки оредера SELL. Не корректно задан стоп лосс");
        
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_BID)-takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;
       else
        Print("Ошибка отправки ордера SELL. Не корректно задан тейк профит");
        
       _ctm.PositionOpen(_symbol,POSITION_TYPE_SELL,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_BID),
                         sl,
                         tp,
                         "немедленно купили");     
     }
    if (sparam == _name+"_close")
     {
      _ctm.PositionClose(_symbol);
     }
    if (sparam == _name+"_edit_pos")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_ASK)-stopLoss*_Point;
        }
       else if (stopLoss == 0)
         sl = 0.0;
       else 
         Print("Ошибка отправки ордера BUY. Не корректно задан стоп лосс");
         
          
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_ASK)+takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;       
       else 
        Print("Ошибка отправки ордера BUT. Не корректно задан тейк профит");
     
       _ctm.PositionModify(_Symbol,sl,tp);
              
     }
 
    if (sparam == _name+"_close_widget")
     {
      delete _subPanel;
      delete _wTradeWidget;
     }     
     
    if (sparam ==  _name+"_subPanel_buy_stop")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) ); 
      if ( GreatDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_ASK)+SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
          _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_STOP,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         orderPrice
                         );            
        }
      else
        Print("Не улалось утановить Buy Stop");
     }

    if (sparam ==  _name+"_subPanel_sell_stop")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );
      if (LessDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_BID)-SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
         _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_STOP,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }    
    if (sparam ==  _name+"_subPanel_buy_limit")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );     
      if (LessDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_BID)-SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {      
         _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_LIMIT,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }
    if (sparam ==  _name+"_subPanel_sell_limit")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );     
      if (GreatDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_ASK)+SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
         _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_LIMIT,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }        
    if (sparam == _name+"_delete_orders")
     {
      Print("Удаляем ордера");
      if ( !_ctm.DeleteAllOrders() )
        Print("Не удалось удалить все отложенные ордеры");
     }
   }
    
  