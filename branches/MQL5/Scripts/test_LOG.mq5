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

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   CLog m_log;
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
