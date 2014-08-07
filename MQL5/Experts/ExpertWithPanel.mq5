//+------------------------------------------------------------------+
//|                                              ExpertWithPanel.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Graph\Objects\Panel.mqh>   // класс панели
#include <TradeManager\TMPCTM.mqh>   // торговая библиотека

Panel * panel;           // объект панели
CTMTradeFunctions * ctm; // объект торговой библиотеки

int OnInit()
  {
   panel = new Panel("panel","panel",1,1,200,400,0,0,CORNER_LEFT_UPPER,0);
   panel.AddElement (PE_BUTTON,"inst_buy","BUY",30,0,50,15);                       // кнопка на немедленную покупку
   panel.AddElement (PE_BUTTON,"inst_sell","SELL",30,25,50,15);                    // кнопка на немедленную продажу
   panel.AddElement (PE_BUTTON,"buy_stop","BUY STOP",30,50,150,15);                // кнопка на buy stop
   panel.AddElement (PE_BUTTON,"sell_stop","SELL STOP",30,75,150,15);              // кнопка на sell stop
   panel.AddElement (PE_BUTTON,"buy_limit","BUY LIMIT",30,100,150,15);             // кнопка на buy limit
   panel.AddElement (PE_BUTTON,"sell_limit","SELL LIMIT",30,125,150,15);           // кнопка на sell limit
   panel.AddElement (PE_LABEL, "label_price","цена отложенника",30,150,150,15);    
   panel.AddElement (PE_INPUT, "price","",30,175,150,15);                          // цена для отложенников
   
   panel.AddElement (PE_LABEL, "new_stoploss_label","новый стоп лосс",30,200,150,15);
   panel.AddElement (PE_INPUT, "new_stoploss","",30,225,150,15);                   // новое значение стоп лосса    
   
   panel.AddElement (PE_LABEL, "new_takeprofit_label","новый тейк профит",30,250,150,15);
   panel.AddElement (PE_INPUT, "new_takeprofit","",30,275,150,15);                 // новое значение тейк профита     
   
   panel.AddElement (PE_LABEL, "new_volume_label","новый объем",30,300,150,15);
   panel.AddElement (PE_INPUT, "new_volume","",30,325,150,15);                     // новый объем
   
   panel.AddElement (PE_BUTTON,"close_position","Закрыть позицию",30,350,150,15);  // закрытие позиции  
         
   panel.AddElement (PE_BUTTON,"delete_order","Удалить посл. ордер",30,375,150,15);  // удалить последний ордер  
   
   panel.AddElement (PE_BUTTON,"change_sltp","Изменить стоп и тейк",30,400,150,15);  // изменить стоп лосс и тейк профит  
   
   panel.AddElement (PE_BUTTON,"change_volume","Изменить объем",30,425,150,15);  // изменить объем     
   
   ctm = new CTMTradeFunctions();
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete panel;
   delete ctm;
  }

void OnTick()
  {

  }
  
// метод обработки событий  
void OnChartEvent(const int id,
                const long &lparam,
                const double &dparam,
                const string &sparam)
  { 
   // если нажата кнопка
   if(id==CHARTEVENT_OBJECT_CLICK)
    {
     // обработка типа нажатой кнопки

       if (sparam == "panel_inst_buy")     // кнопка немедленная покупка
        {
         ctm.PositionOpen(_Symbol,POSITION_TYPE_BUY,1.0,SymbolInfoDouble(_Symbol,SYMBOL_ASK),
          0.0,0.0,"немедленно купили");     
         Print("BUY");
        }
       if (sparam == "panel_inst_sell")     // кнопка немедленная продажа
        {
         ctm.PositionOpen(_Symbol,POSITION_TYPE_SELL,1.0,SymbolInfoDouble(_Symbol,SYMBOL_BID),
          0.0,0.0,"немедленно продали");     
         Print("SELL");
        }
       if (sparam == "panel_buy_stop")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_BUY_STOP,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("Значение в = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_sell_stop")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_SELL_STOP,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("Значение в = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_buy_limit")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_BUY_LIMIT,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("Значение в = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_sell_limit")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_SELL_LIMIT,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("Значение в = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }                        
       if (sparam == "panel_close_position")
        {
         ctm.PositionClose(_Symbol);  // закрываем позицию
        }
       if (sparam == "panel_delete_order") // удалить последний ордер
        {
         for (int ind=0;ind<OrdersTotal();ind++)
          {
            ctm.OrderDelete(OrderGetTicket(ind));  // удаляем последний ордер
            return;
          }
        }
    }
  } 