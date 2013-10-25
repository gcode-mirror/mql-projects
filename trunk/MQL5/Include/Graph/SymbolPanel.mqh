//+------------------------------------------------------------------+
//|                                                  SymbolPanel.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Objects\Label.mqh"
#include "Objects\Input.mqh"
//+------------------------------------------------------------------+
//| библиотека для функции отображения свойств символа               |
//+------------------------------------------------------------------+

 void SymbolPanel(string symbol,
                    string caption,
                    uint x,
                    uint y,
                    long chart_id,
                    int sub_window,
                    ENUM_BASE_CORNER corner,
                    long z_order)
  {
    string magic         =   IntegerToString(pos.getMagic());  //магическое число
    string symbol        =   pos.getSymbol(); //символ
    string posType       =   GetNameOP(pos.getType());    //тип позиции    
    string posStatus     =   PositionStatusToStr(pos.getPositionStatus());  //статус позиции    
    string posProfit     =   DoubleToString(pos.getPosProfit(),5);  //прибыль позиции
    string posPrice      =   DoubleToString(pos.getPositionPrice()); //цена позиции
    string posPriceClose =   DoubleToString(pos.getPriceClose());   //цена закрытия позиции
    string posCloseTime  =   TimeToString(pos.getClosePosDT()); //время закрытия позиции
    string posOpenTime   =   TimeToString(pos.getOpenPosDT());  //время открытия позиции    
    string posLot        =   DoubleToString(pos.getVolume());  //лот 
    
    //SymbolInfoString(
   

    new Input("PositionBody","",x,y,260,180,chart_id,sub_window,corner,z_order);
    new Input("PositionHead",caption,x,y,260,15,chart_id,sub_window,corner,z_order);    
    //магическое число
    new Label("PositionMagic", "Мэджик:",x,y+15,250,15,chart_id,sub_window,corner,z_order);
    new Label("PositionMagic2",magic,x+150,y+15,250,15,chart_id,sub_window,corner,z_order);    
    //символ
    new Label("PositionSymbol","Символ:",x,y+30,250,15,chart_id,sub_window,corner,z_order);
    new Label("PositionSymbol2",symbol,x+150,y+30,250,15,chart_id,sub_window,corner,z_order);
    //тип позиции
    new Label("PositionType",  "Тип позиции:",x,y+45,250,15,chart_id,sub_window,corner,z_order);       
    new Label("PositionType2",posType,x+150,y+45,250,15,chart_id,sub_window,corner,z_order);      
    //статус позиции     
    new Label("PositionStatus",  "Статус:",x,y+60,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionStatus2",posStatus,x+150,y+60,250,15,chart_id,sub_window,corner,z_order);    
    //прибыль позиции
    new Label("PositionProfit",  "Прибыль:",x,y+75,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionProfit2",posProfit,x+150,y+75,250,15,chart_id,sub_window,corner,z_order);  
    //цена открытия
    new Label("PositionPrOpen",  "Цена открытия:",x,y+90,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionPrOpen2",posPrice,x+150,y+90,250,15,chart_id,sub_window,corner,z_order);      
    //цена закрытия
    new Label("PositionPrClose",  "Цена закрытия:",x,y+105,250,15,chart_id,sub_window,corner,z_order); 
    new Label("PositionPrClose2",posPriceClose,x+150,y+105,250,15,chart_id,sub_window,corner,z_order); 
    //время цены открытия
    new Label("PositionOTime",  "Время цены открытия:",x,y+120,250,15,chart_id,sub_window,corner,z_order);   
    new Label("PositionOTime2",posOpenTime,x+150,y+120,250,15,chart_id,sub_window,corner,z_order);        
    //время цены закрытия
    new Label("PositionCTime",  "Время цены закрытия:",x,y+135,250,15,chart_id,sub_window,corner,z_order);   
    new Label("PositionCTime2",posCloseTime,x+150,y+135,250,15,chart_id,sub_window,corner,z_order);        
    //лот
    new Label("PositionLot",  "Лот:",x,y+150,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionLot2",posLot,x+150,y+150,250,15,chart_id,sub_window,corner,z_order);                                      
  }