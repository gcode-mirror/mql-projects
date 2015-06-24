//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <MC/CMoveContainer.mqh>
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами

input double percent = 0.1;

CMoveContainer *move_container;
bool firstUploaded = false;
int handleDE;

int OnInit()
  {
   // привязка индикатора DrawExtremums
   handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol, _Period, handleDE);
    }
   move_container = new CMoveContainer(0,_Symbol,_Period,handleDE,percent);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()
  {
   if (!firstUploaded)
    {
     firstUploaded = move_container.UploadOnHistory();
    }
   if (!firstUploaded)
    return;
  }

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string
                 )
  {
    move_container.UploadOnEvent(sparam,dparam,lparam);
  }