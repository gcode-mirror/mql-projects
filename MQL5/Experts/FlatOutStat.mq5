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
input double volume = 1.0; // лот

struct statElem
 {
  int count;    // количество таких случаев в истории
  int trend;    // тип тренда 
  int flat;     // тип флэта
  int lastExtr; // тип последнего экстремума
 };

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
int countFlat = 0;
double H; // высота флэта
double top_point; // верхняя точка, которую нужно достичь
double bottom_point; // нижняя точка, которую нужно достичь
double extrUp0,extrUp1;
double extrDown0,extrDown1;
datetime extrUp0Time;
datetime extrDown0Time;
datetime extrUp1Time;
datetime extrDown1Time;

CChartObjectTrend flatLine; // объект класса флэтовой линии
CChartObjectHLine topLevel; // верхний уровень
CChartObjectHLine bottomLevel; // нижний уровень


// массив ситуаций
statElem elem[28];

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
   // сбрасываем параметры ситуаций
   ResetAllElems (); 
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
   if (ctm.GetPositionCount()>0)
    mode = 0;
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
         extrUp1Time = container.GetFormedExtrByIndex(1,EXTR_HIGH).time;
         extrDown0Time = container.GetFormedExtrByIndex(0,EXTR_LOW).time;
         extrDown1Time = container.GetFormedExtrByIndex(1,EXTR_LOW).time;
         
         //---------- обработка всех условий

         // если сейчас флэт А и последний экстремум - верхний, тренд вверх
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(0,1,1,1);
          }
         // если сейчас флэт А и последний экстремум - верхний, тренд вниз
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(1,1,1,-1);
          }   
         // если сейчас флэт А и последний экстремум - нижний, тренд вверх
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(2,1,-1,1);
          }                    
         // если сейчас флэт А и последний экстремум - нижний, тренд вниз
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(3,1,-1,-1);
          }            
           
        
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
 
void ResetAllElems ()
 {
  for (int i = 0;i<28;i++)
   {
    elem[i].count = 0;
    elem[i].flat = 0;
    elem[i].lastExtr = 0;
    elem[i].trend = 0;
   }
 }
 
 // дополнительные функции
 void DrawFlatLines ()  // создает линии флэта
  {
   flatLine.Create(0, "flatUp_" + countFlat, 0, extrUp0Time, extrUp0, extrUp1Time, extrUp1); // верхняя линия  
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   flatLine.Create(0,"flatDown_" + countFlat, 0, extrDown0Time, extrDown0, extrDown1Time, extrDown1); // нижняя линия
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   countFlat ++;   
   topLevel.Delete();
   topLevel.Create(0, "topLevel", 0, top_point);
   bottomLevel.Delete();
   bottomLevel.Create(0, "bottomLevel", 0, bottom_point);   
  } 
  
 // вычисление параметров текущего флэта при его обнаружениии
 void CalcFlat (int index,int flatType,int lastExtr,int trend)
  {
   H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
   top_point = extrUp0 + H*0.75;
   bottom_point = extrDown0 - H*0.75;
   DrawFlatLines ();
   elem[index].flat = 1;
   elem[index].lastExtr = 1;
   elem[index].trend = 1;
  }