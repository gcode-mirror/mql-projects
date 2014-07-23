//+------------------------------------------------------------------+
//|                                                      Chicken.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>

#define DEPTH 20
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
CisNewBar *isNewBar;

int handle_pbi;
double buffer_pbi[1];
double buffer_high[];
double buffer_low[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 isNewBar = new CisNewBar(_Symbol, _Period);
 handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handle_pbi);
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 static double max = 0;
 static double min = 0;
 static bool open = false;
 CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi);
 if(isNewBar.isNewBar())
 {
  CopyHigh(_Symbol, _Period, 0, DEPTH, buffer_high);
  CopyLow(_Symbol, _Period, 0, DEPTH, buffer_low);
  
  max = ArrayMaximum(buffer_high);
  min = ArrayMinimum(buffer_low);
 }
 
 if(OrdersTotal() > 0 && open)
 {
  //стоплосс + тейкпрофит
  open = false;
 }
 
 if(buffer_pbi[0] == MOVE_TYPE_FLAT)
 {
  //Кто ты
  if(1)//Ask() > max + STOPLEVEL)
  {
   //поставить отложенник
   open = true;
  }
  if(1)//Bid() < min - STOPLEVEL)
  {
   //поставить отложенник
   open = true;
  }
 }
 else
 {
  //удалить отложенник
 }
}
//+------------------------------------------------------------------+
