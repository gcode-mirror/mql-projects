//+------------------------------------------------------------------+
//|                                                   TradeLines.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//#include <CLog.mqh>
#include <ChartObjects/ChartObjectsLines.mqh>
//+------------------------------------------------------------------+
/// Horizontal line on chart indicating a virtual trade entry.
//+------------------------------------------------------------------+
class CTradeLine : public CChartObjectHLine
  {
public:
   bool              Create(double price, string name, color clr = clrOrange);
   double				Value(){return GetDouble(OBJPROP_PRICE);}
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeLine::Create(double price, string name, color clr = clrOrange)
{
 bool createSuccess = false;
 string strName=name;
 if(CChartObjectHLine::Create(0,strName,0,price))
 {
  //LogFile.Log(LOG_VERBOSE,__FUNCTION__,"("+(string)price+","+strName+") returning true");
  //Color(Config.EntryPriceLineColor);
  Color(clr);
  Style(STYLE_DASHDOTDOT);
  SetString(OBJPROP_TEXT,strName);
  createSuccess = true;
 }
 else
 {
 //LogFile.Log(LOG_MAJOR,__FUNCTION__,"("+(string)price+","+strName+") returning false");
  createSuccess = false;
 }
return createSuccess;    
}
