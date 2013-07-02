//+------------------------------------------------------------------+
//|                                       ChartObjectsTradeLines.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

color EntryPriceLineColor=DarkBlue;
color StopLossLineColor=DarkOrange;
color TakeProfitLineColor=Brown;

//#include "Log.mqh"

#include "TradeManagerEnums.mqh"
#include <ChartObjects/ChartObjectsLines.mqh>
//+------------------------------------------------------------------+
/// Horizontal line on chart indicating a virtual trade entry.
//+------------------------------------------------------------------+
class CEntryPriceLine : public CChartObjectHLine
  {
public:
   bool Create(long lTicket,double price,ENUM_TM_POSITION_TYPE type);
   double Value(){return GetDouble(OBJPROP_PRICE);}
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CEntryPriceLine::Create(long lTicket,double price,ENUM_TM_POSITION_TYPE type)
  {
   string strName=::GetNameOP(type)+(string)lTicket;
   if(CChartObjectHLine::Create(0,strName,0,price))
     {
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__,"("+(string)price+","+strName+") returning true");
      Color(EntryPriceLineColor);
      Style(STYLE_DASHDOTDOT);
      SetString(OBJPROP_TEXT,strName);
      return(true);
     }
   else
     {
      //LogFile.Log(LOG_MAJOR,__FUNCTION__,"("+(string)price+","+strName+") returning false");
      return(false);
     }
  }
  
//+------------------------------------------------------------------+
/// Horizontal line on chart indicating a virtual trade stop loss.
//+------------------------------------------------------------------+
class CStopLossLine : public CChartObjectHLine
  {
public:
   bool Create(long lTicket,double price);
   double Value(){return GetDouble(OBJPROP_PRICE);}
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStopLossLine::Create(long lTicket,double price)
  {
   string strName="sl"+(string)lTicket;
   if(CChartObjectHLine::Create(0,strName,0,price))
     {
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__,"("+(string)price+","+strName+") returning true");
      Color(StopLossLineColor);
      Style(STYLE_DASHDOTDOT);
      return(true);
     }
   else
     {
      //LogFile.Log(LOG_MAJOR,__FUNCTION__,"("+(string)price+","+strName+") returning false");
      return(false);
     }
  }
  
//+------------------------------------------------------------------+
/// Horizontal line on chart indicating a virtual take profit.
//+------------------------------------------------------------------+
class CTakeProfitLine : public CChartObjectHLine
  {
public:
   bool Create(long lTicket,double price);
   double Value(){return GetDouble(OBJPROP_PRICE);}
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTakeProfitLine::Create(long lTicket,double price)
  {
   string strName="tp"+(string)lTicket;
   if(CChartObjectHLine::Create(0,strName,0,price))
     {
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__,"("+(string)price+","+strName+") returning true");
      Color(TakeProfitLineColor);
      Style(STYLE_DASHDOTDOT);
      return(true);
     }
   else
     {
      //LogFile.Log(LOG_MAJOR,__FUNCTION__,"("+(string)price+","+strName+") returning false");
      return(false);
     }
  }
//+------------------------------------------------------------------+
