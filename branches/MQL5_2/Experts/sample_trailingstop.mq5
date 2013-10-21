//+------------------------------------------------------------------+
//|                                          Sample_TrailingStop.mq5 |
//|                                        MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Sample_TrailingStop.mqh> // подключение класса трейлинга

//--- input parameters
input double   SARStep     =  0.02;    // Ўаг Parabolic
input double   SARMaximum  =  0.02;    // ћаксимум Parabolic
input int      NRTRPeriod  =  40;      // ѕериод NRTR
input double   NRTRK       =  2;       //  оэффициент NRTR

string Symbols[]={"EURUSD","GBPUSD","USDCHF","USDJPY"};

CParabolicStop *SARTrailing[];
CNRTRStop *NRTRTrailing[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(SARTrailing,ArraySize(Symbols));  // изменение размера в соответствии с количеством используемых символов
   ArrayResize(NRTRTrailing,ArraySize(Symbols)); // изменение размера в соответствии с количеством используемых символов   
   for(int i=0;i<ArraySize(Symbols);i++)
     { // дл€ всех символов
      SARTrailing[i]=new CParabolicStop(); // создание экземпл€ра класса CParabolicStop
      SARTrailing[i].Init(Symbols[i],PERIOD_CURRENT,false,true,true,5,15+i*17,Silver,Blue); // инициализаци€ экземпл€ра класса CParabolicStop 
      if(!SARTrailing[i].SetParameters(SARStep,SARMaximum))
        { // установка параметров экземпл€ра класса CParabolicStop 
         Alert("trailing error");
         return(-1);
        }
      SARTrailing[i].StartTimer(); // запуск таймера
      //----
      NRTRTrailing[i]=new CNRTRStop(); // создание экземпл€ра класса CNRTRStop
      NRTRTrailing[i].Init(Symbols[i],PERIOD_CURRENT,false,true,true,127,15+i*17,Silver,Blue); // инициализаци€ экземпл€ра класса CNRTRStop 
      if(!NRTRTrailing[i].SetParameters(NRTRPeriod,NRTRK))
        { // установка параметров экземпл€ра класса CNRTRcStop 
         Alert("trailing error");
         return(-1);
        }
      NRTRTrailing[i].StartTimer(); // запуск таймера         
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].Deinit();
      NRTRTrailing[i].Deinit();
      delete(SARTrailing[i]);
      delete(NRTRTrailing[i]);
     }

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].DoStoploss();
      NRTRTrailing[i].DoStoploss();
     }

  }
//+------------------------------------------------------------------+

void OnTimer()
  {
   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].Refresh();
      NRTRTrailing[i].Refresh();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam
                  )
  {

   for(int i=0;i<ArraySize(Symbols);i++)
     {
      SARTrailing[i].EventHandle(id,lparam,dparam,sparam);
      NRTRTrailing[i].EventHandle(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
