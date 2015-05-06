//+------------------------------------------------------------------+
//|                                                      FlatOut.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Робот выхода из флэта                                            |
//+------------------------------------------------------------------+
// подключение библиотек
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <TradeManager/TradeManager.mqh> // торговая библиотека
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <SystemLib/IndicatorManager.mqh>  // библиотека по работе с индикаторами
#include <StringUtilities.mqh> // строковые константы

#include <CTrendChannel.mqh> 
// входные параметры
input double percent = 0.1; // процент

CTradeManager *ctm;
CExtrContainer *container;
CTrendChannel *trend;
int handleDE;
bool firstUploaded = false;
bool firstUploadedTrend = false;
string formedExtrHighEvent;
string formedExtrLowEvent;
int mode = 0;
int trendType;
double extrUp0,extrUp1;
double extrDown0,extrDown1;
datetime extrUp0Time;
datetime extrDown0Time;
double H; // высота флэта
double top_point; // верхняя точка, которую нужно достичь
double bottom_point; // нижняя точка, которую нужно достичь
// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге

int OnInit()
  {
   // привязка индикатора DrawExtremums 
   handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol,_Period,handleDE);
    }    
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("Не удалось создать торговую библиотеку");
     return (INIT_FAILED);
    }
   container = new CExtrContainer(handleDE,_Symbol,_Period);
   if (container == NULL)
    {
     Print("Не удалось создать контейнер экстремумов");
     return (INIT_FAILED);
    }
   trend = new CTrendChannel(0,_Symbol,_Period,handleDE,percent);
   if (trend == NULL)
    {
     Print("Не удалось создать контейнер трендов");
     return (INIT_FAILED);
    }    
   // сохраняем имена событий
   formedExtrHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   formedExtrLowEvent = GenUniqEventName("EXTR_DOWN_FORMED");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete ctm;
   delete container;
   delete trend;
  }

void OnTick()
  {
   ctm.OnTick();
   if (!firstUploaded)
    {
     firstUploaded = container.Upload();
    }
   if (!firstUploadedTrend)
    {
     firstUploadedTrend = trend.UploadOnHistory();
    }
   if (!firstUploaded || !firstUploadedTrend)
    return;   
  }

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   int flatNow;   
   // то загружаем данные в контейнер экстремумов и трендов
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam); 
   // если пришло событие "сформировался экстремум"
   if (sparam == formedExtrHighEvent || sparam == formedExtrLowEvent)
    { 

     // если еще не найден тренд
     if (mode == 0)
      {
       // если мы нашли тренд
       trendType = trend.GetTrendByIndex(0).GetDirection();
       if (trendType != 0)
        {
         // переходим в режим отслеживания флэта
         mode = 1;
        }
      }
     else if (mode == 1)
      {
       // если сейчас не тренд
       if (!trend.IsTrendNow())
        { 
         // загружаем экстремумы
         extrUp0 = container.GetFormedExtrByIndex(0,EXTR_HIGH).price;
         extrUp1 = container.GetFormedExtrByIndex(1,EXTR_HIGH).price;
         extrDown0 = container.GetFormedExtrByIndex(0,EXTR_LOW).price;
         extrDown1 = container.GetFormedExtrByIndex(1,EXTR_LOW).price;
         extrUp0Time = container.GetFormedExtrByIndex(0,EXTR_HIGH).time;
         extrDown0Time = container.GetFormedExtrByIndex(0,EXTR_LOW).time;
         Print ("Попали сюда и ждем чуда extr0 = ",TimeToString(extrUp0Time)," extrDown = ",TimeToString(extrDown0Time));
         //---------- обработка всех условий
         
         // если сейчас флэт А и последний экстремум - верхний
         if (IsFlatA() && extrUp0Time > extrDown0Time)
          {
           H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
           top_point = extrUp0 + H*0.75;
           bottom_point = extrDown0 - H*0.75;           
           pos_info.sl = int(MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-bottom_point)/_Point);
           pos_info.tp = int(MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-top_point)/_Point);      
           pos_info.type = OP_BUY;
           ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
          }
          
         // если сейчас флэт А и последний экстремум - верхний
       /*  if (IsFlatA() && extrUp0Time > extrDown0Time)
          {
           H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
           top_point = extrUp0 + H*0.75;
           bottom_point = extrDown0 - H*0.75;           
           pos_info.sl = int(MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-bottom_point)/_Point);
           pos_info.tp = int(MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-top_point)/_Point);      
           pos_info.type = OP_BUY;
           ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
          }          
       */    
       // переходим в режим 0 (ищем другой тренд)
       mode = 0;
        
        }
      }
    }
  }
  
// генерирует уникальное имя события
string GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 } 
 
// функции обработки типов флэтов

bool IsFlatA ()
 {
  //  если 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatB ()
 {
  //  если 
  if ( GreatOrEqualDoubles (extrUp1-extrUp0,percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

bool IsFlatC ()
 {
  //  если 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatD ()
 {
  //  если 
  if ( GreatOrEqualDoubles (extrUp1-extrUp0,percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatE ()
 {
  //  если 
  if ( GreatOrEqualDoubles (extrUp0-extrUp1,percent*H) &&
       GreatOrEqualDoubles (extrDown1 - extrDown0,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }     