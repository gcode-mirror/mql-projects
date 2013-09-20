//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#define ONEDAY 60*60*24
#include <CLog.mqh>
#include <Trigger64/PositionSys.mqh>
#include <Trigger64/SymbolSys.mqh>
#include <Trigger64/Graph.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   CLog m_log;
   GraphModule GP;
   SymbolSys my_sym;
   


      

 
 my_sym.symb.ask = 0;
 my_sym.symb.bid = 0;
 my_sym.symb.digits = 0;
 my_sym.symb.down_level = 0;
 my_sym.symb.offset = 0;
 my_sym.symb.point = 0;
 my_sym.symb.spread = 0;
 my_sym.symb.stops_level = 0;
 my_sym.symb.up_level = 0;
 my_sym.symb.volume_limit = 0;
 my_sym.symb.volume_max = 0;
 my_sym.symb.volume_min = 0;
 
  my_sym.GetSymbolProperties("1100100000000");
 
  Alert("______________________________________");
  Alert("ask = ",DoubleToString(my_sym.symb.ask));
  Alert("bid = ",DoubleToString(my_sym.symb.bid));  
  Alert("digits = ",IntegerToString(my_sym.symb.digits));
  Alert("down level = ",IntegerToString(my_sym.symb.down_level));  
  Alert("offset = ",IntegerToString(my_sym.symb.offset));
  Alert("point = ",DoubleToString(my_sym.symb.point));  
  Alert("spread = ",DoubleToString(my_sym.symb.spread));
  Alert("stops level = ",IntegerToString(my_sym.symb.stops_level));  
  Alert("up level = ",IntegerToString(my_sym.symb.up_level));  
  Alert("volume limit = ",DoubleToString(my_sym.symb.volume_limit));  
  Alert("volume max = ",DoubleToString(my_sym.symb.volume_max));
  Alert("volume min = ",DoubleToString(my_sym.symb.volume_min));                  
 
      
   /*m_log.CreateLogFile (TimeLocal());
   m_log.CreateLogFile (TimeLocal()-3*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-7*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-12*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-16*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-35*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-45*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-60*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-100*ONEDAY);
   m_log.CreateLogFile (TimeLocal()-356*ONEDAY);*/
   //m_log.DeleteLogFile ();
  }
//+------------------------------------------------------------------+
