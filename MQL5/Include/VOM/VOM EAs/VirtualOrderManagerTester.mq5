//+------------------------------------------------------------------+
//|                                           VirtualOrderTester.mq5 |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
#property version   "1.00"

#include <Log.mqh>
#include "..\SimpleChartObject.mqh"
#include "..\VirtualOrderManager.mqh"

CButton cBuy,cSell,cModify,cClose,cCloseAll,cBuyStop,cBuyLimit,cSellStop,cSellLimit,cDelete;
CEdit cVolume,cStoploss,cTakeprofit,cPrice,cTicket;
CLabel cVolumeLabel,cStoplossLabel,cTakeprofitLabel,cTicketLabel,cPriceLabel;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   VOM.Initialise();
   Comment(VOM.m_OpenOrders.SummaryList());

   LogFile.LogLevel(LOG_VERBOSE);

   CreateVirtualTradeChartObjects();

//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Need to include this line in all EAs using CVirtualOrderManager  
   VOM.OnTick();
   Comment(VOM.m_OpenOrders.SummaryList());
  }
//+------------------------------------------------------------------+
/// Process signals from chart objects.
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;

// Handling of button clicks on chart below this
   string strObjectName=sparam;

   ENUM_OBJECT ObjectType=(ENUM_OBJECT)ObjectGetInteger(0,strObjectName,OBJPROP_TYPE);

// no action with edit boxes
   if(ObjectType==OBJ_EDIT) return;

// push button back up to give it more of a Windows feel   
   if(ObjectType==OBJ_BUTTON)
     {
      Sleep(150);
      ObjectSetInteger(0,strObjectName,OBJPROP_STATE,false);
      ChartRedraw();
     }

// action appropriate button
   if(strObjectName=="Buy")
     {
      VOM.Buy(Symbol(),cVolume.DoubleValue(),cStoploss.IntegerValue(),cTakeprofit.IntegerValue(),"Test");
     }
   if(strObjectName=="Sell")
     {
      VOM.Sell(Symbol(),cVolume.DoubleValue(),cStoploss.IntegerValue(),cTakeprofit.IntegerValue(),"Test");
     }
   if(strObjectName=="Modify")
     {
      VOM.OrderModify(cTicket.IntegerValue(),cPrice.DoubleValue(),cStoploss.IntegerValue(),cTakeprofit.IntegerValue(),0);
     }
   if(strObjectName=="Close")
     {
      VOM.OrderClose(cTicket.IntegerValue(),Config.Deviation);
     }
   if(strObjectName=="Close all")
     {
      VOM.CloseAllOrders(_Symbol,VIRTUAL_ORDER_TYPE_BUY);
      VOM.CloseAllOrders(_Symbol,VIRTUAL_ORDER_TYPE_SELL);
     }
   if(strObjectName=="Buy stop")
     {
      VOM.OrderSend(Symbol(),VIRTUAL_ORDER_TYPE_BUYSTOP,cVolume.DoubleValue(),cPrice.DoubleValue(),Config.Deviation,0,0,"Test");
     }
   if(strObjectName=="Buy limit")
     {
      VOM.OrderSend(Symbol(),VIRTUAL_ORDER_TYPE_BUYLIMIT,cVolume.DoubleValue(),cPrice.DoubleValue(),Config.Deviation,0,0,"Test");
     }
   if(strObjectName=="Sell stop")
     {
      VOM.OrderSend(Symbol(),VIRTUAL_ORDER_TYPE_SELLSTOP,cVolume.DoubleValue(),cPrice.DoubleValue(),Config.Deviation,0,0,"Test");
     }
   if(strObjectName=="Sell limit")
     {
      VOM.OrderSend(Symbol(),VIRTUAL_ORDER_TYPE_SELLLIMIT,cVolume.DoubleValue(),cPrice.DoubleValue(),Config.Deviation,0,0,"Test");
     }
   if(strObjectName=="Delete")
     {
      VOM.OrderDelete(cTicket.IntegerValue());
     }
   Comment(VOM.m_OpenOrders.SummaryList());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateVirtualTradeChartObjects()
  {
   int nTop=210;
   int nLeft=200;
   int nWidth=80;
   int nHeight=25;
   int nGap=2;
   string strFont= "Tahoma Bold";
   int nFontSize = 10;

// Labels
   cVolumeLabel.Create("VolumeLabel",nLeft,nTop,nWidth,nHeight,Blue,"Volume",DarkBlue,strFont,nFontSize);
   cVolumeLabel.Align(ANCHOR_RIGHT);
   nTop+=nHeight+nGap;
   cStoplossLabel.Create("SlLabel",nLeft,nTop,nWidth,nHeight,Blue,"Stoploss",DarkBlue,strFont,nFontSize);
   cStoplossLabel.Align(ANCHOR_RIGHT);
   nTop+=nHeight+nGap;
   cTakeprofitLabel.Create("TpLabel",nLeft,nTop,nWidth,nHeight,Blue,"Takeprofit",DarkBlue,strFont,nFontSize);
   cTakeprofitLabel.Align(ANCHOR_RIGHT);
   nTop+=nHeight+nGap;
   cPriceLabel.Create("PriceLabel",nLeft,nTop,nWidth,nHeight,Blue,"Price",DarkBlue,strFont,nFontSize);
   cPriceLabel.Align(ANCHOR_RIGHT);
   nTop+=nHeight+nGap;
   cTicketLabel.Create("TicketLabel",nLeft,nTop,nWidth,nHeight,Blue,"Ticket",DarkBlue,strFont,nFontSize);
   cTicketLabel.Align(ANCHOR_RIGHT);


//	Edit boxes
   nLeft=220;
   nTop = 200;
   cVolume.Create("Volume",nLeft,nTop,nWidth,nHeight,White,"0.1",Black,strFont,nFontSize);
   cVolume.Align(ANCHOR_LEFT);
   nTop+=nHeight+nGap;
   cStoploss.Create("Stop loss",nLeft,nTop,nWidth,nHeight,White,"200",Black,strFont,nFontSize);
   cStoploss.Align(ANCHOR_LEFT);
   nTop+=nHeight+nGap;
   cTakeprofit.Create("Take profit",nLeft,nTop,nWidth,nHeight,White,"200",Black,strFont,nFontSize);
   cTakeprofit.Align(ANCHOR_LEFT);
   nTop+=nHeight+nGap;
   cPrice.Create("Price",nLeft,nTop,nWidth,nHeight,White,"",Black,strFont,nFontSize);
   cPrice.Align(ANCHOR_LEFT);
   nTop+=nHeight+nGap;
   cTicket.Create("Ticket",nLeft,nTop,nWidth,nHeight,White,"",Black,strFont,nFontSize);
   cTakeprofit.Align(ANCHOR_LEFT);
   nTop+=nHeight+nGap;

   nTop=200;
   nLeft=320;
   nWidth=100;

//	Buttons
   cBuy.Create("Buy",nLeft,nTop,nWidth,nHeight,Blue,"Buy",White,strFont,nFontSize);
   nTop+=2*nHeight+2*nGap;
   cSell.Create("Sell",nLeft,nTop,nWidth,nHeight,Orange,"Sell",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cModify.Create("Modify",nLeft,nTop,nWidth,nHeight,Green,"Modify",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cClose.Create("Close",nLeft,nTop,nWidth,nHeight,Red,"Close",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cCloseAll.Create("Close all",nLeft,nTop,nWidth,nHeight,OrangeRed,"Close all",White,strFont,nFontSize);

	nTop = 200;   
   nLeft += nWidth+nGap;

   cBuyStop.Create("Buy stop",nLeft,nTop,nWidth,nHeight,Blue,"Buy stop",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cBuyLimit.Create("Buy limit",nLeft,nTop,nWidth,nHeight,Blue,"Buy limit",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cSellStop.Create("Sell stop",nLeft,nTop,nWidth,nHeight,Orange,"Sell stop",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cSellLimit.Create("Sell limit",nLeft,nTop,nWidth,nHeight,Orange,"Sell limit",White,strFont,nFontSize);
   nTop+=nHeight+nGap;
   cDelete.Create("Delete",nLeft,nTop,nWidth,nHeight,Red,"Delete",White,strFont,nFontSize);
  }
  

//+------------------------------------------------------------------+