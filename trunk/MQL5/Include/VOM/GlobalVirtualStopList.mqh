//+------------------------------------------------------------------+
//|                                        GlobalVirtualStopList.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include "VirtualOrderManagerConfig.mqh"
#include "Log.mqh"
#include "VirtualOrderManagerEnums.mqh"
//+------------------------------------------------------------------+
/// Maintains a list of all active virtual stops
//+------------------------------------------------------------------+
class CGlobalVirtualStopList
  {
public:
   bool              Add(long VirtualOrderTicket,string strSymbol,ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType,double dblValue);
   bool              Delete(long VirtualOrderTicket);
   bool              Modify(long VirtualOrderTicket,double dblNewValue);
   bool              ParseName(string strGlobalVariable,long &VirtualOrderTicket,string &strSymbol,ENUM_VIRTUAL_ORDER_TYPE &VirtualOrderType);
   void              TightestStops(string strSymbol,double &dblTightestShortStop,double &dblTightestLongStop);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CGlobalVirtualStopList::Add(long VirtualOrderTicket,string strSymbol,ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType,double dblValue)
  {
   string strStopName="";
   StringConcatenate(strStopName,(string)VirtualOrderTicket,Config.GlobalVirtualStopListIdentifier,strSymbol,"_",VirtualOrderTypeToStr(VirtualOrderType));
   return(GlobalVariableSet(strStopName,dblValue));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CGlobalVirtualStopList::Delete(long VirtualOrderTicket)
  {
   string strSymbol="";
   ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType=VIRTUAL_ORDER_TYPE_UNDEFINED;
   long lTicket=0;

   for(int i=0; i<GlobalVariablesTotal(); i++)
     {
      string strGlobalVariable=GlobalVariableName(i);
      ParseName(strGlobalVariable,lTicket,strSymbol,VirtualOrderType);
      if(lTicket==VirtualOrderTicket)
        {
         GlobalVariableDel(strGlobalVariable);
         return(true);
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CGlobalVirtualStopList::Modify(long VirtualOrderTicket,double dblNewValue)
  {
   string strSymbol="";
   ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType=VIRTUAL_ORDER_TYPE_UNDEFINED;
   long lTicket=0;

   for(int i=0; i<GlobalVariablesTotal(); i++)
     {
      string strGlobalVariable=GlobalVariableName(i);
      ParseName(strGlobalVariable,lTicket,strSymbol,VirtualOrderType);
      if(lTicket==VirtualOrderTicket)
        {
         GlobalVariableSet(strGlobalVariable,dblNewValue);
         return(true);
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CGlobalVirtualStopList::ParseName(string strGlobalVariable,long &VirtualOrderTicket,string &strSymbol,ENUM_VIRTUAL_ORDER_TYPE &VirtualOrderType)
  {
   int nMarker=StringFind(strGlobalVariable,Config.GlobalVirtualStopListIdentifier);
   if(nMarker==-1) return(false);
   string strVirtualOrderTicket=StringSubstr(strGlobalVariable,0,nMarker);
   VirtualOrderTicket=StringToInteger(strVirtualOrderTicket);
   nMarker+=StringLen(Config.GlobalVirtualStopListIdentifier);
   int nNextUnderscore=StringFind(strGlobalVariable,"_",nMarker);
   strSymbol=StringSubstr(strGlobalVariable,nMarker,nNextUnderscore-nMarker);
   nMarker=nNextUnderscore+1;
   string strOrderType=StringSubstr(strGlobalVariable,nMarker);
   VirtualOrderType=StringToVirtualOrderType(strOrderType);
   return(VirtualOrderType==VIRTUAL_ORDER_TYPE_BUY || VirtualOrderType==VIRTUAL_ORDER_TYPE_SELL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CGlobalVirtualStopList::TightestStops(string strOrderSymbol,double &dblTightestShortStop,double &dblTightestLongStop)
  {
   dblTightestShortStop=DBL_MAX;
   dblTightestLongStop=0.0;
   string strSymbol="";
   ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType=VIRTUAL_ORDER_TYPE_UNDEFINED;
   long lTicket=0;

   for(int i=0; i<GlobalVariablesTotal(); i++)
     {
      string strGlobalVariable=GlobalVariableName(i);
      if(!ParseName(strGlobalVariable,lTicket,strSymbol,VirtualOrderType)) continue;
      if(strOrderSymbol!=strSymbol) continue;

      double dblStopValue=GlobalVariableGet(strGlobalVariable);

      switch(VirtualOrderType)
        {
         case VIRTUAL_ORDER_TYPE_BUY:
            dblTightestLongStop=MathMax(dblTightestLongStop,dblStopValue);
            break;
         case VIRTUAL_ORDER_TYPE_SELL:
            dblTightestShortStop=MathMin(dblTightestShortStop,dblStopValue);
            break;
         default:
            LogFile.Log(LOG_MAJOR,__FUNCTION__," error - invalid Virtual Order Type in ",strGlobalVariable);
            continue;
        }
     }
    LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat(" returning dblTightestLongStop %0.5G and dblTightestShortStop %0.5G",dblTightestLongStop,dblTightestShortStop));
  }
//+------------------------------------------------------------------+
