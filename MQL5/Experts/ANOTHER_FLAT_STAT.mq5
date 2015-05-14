//+------------------------------------------------------------------+
//|                                            ANOTHER_FLAT_STAT.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Собирает статистику по флэтам                                    |
//+------------------------------------------------------------------+
#include <CMoveContainer.mqh> // контейнер ценовых движений 
#include <SystemLib/IndicatorManager.mqh>  // библиотека по работе с индикаторами
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <CompareDoubles.mqh> // для сравнения вещественных чисел

// входные параметры
input double percent = 0.1; // процент

// структура для хранения статистики
struct stat_elem
 {
  string flat_type; // тип флэта
  int last_extr; // направление последнего экстремума
  int trend_direction; // направление последнего тренда
  int countUp; // количество достижений верхней границы канала
  int countDown; // количество достижений нижней границы канала
 };
 
// переменные 
bool firstUploadedMovements = false; // флаг первой загрузки движений
bool firstUploadedExtremums = false; // флаг первой загрузки экстремумов
string eventExtrUpFormed; // имя события "пришел сформированный верхний экстремум"
string eventExtrDownFormed; // имя события "пришел сформированных нижний экстремум"
int handleDE; // хэндл DrawExtremums
double extrUp0,extrUp1;     
double extrDown0,extrDown1;
datetime extrUp0Time, extrUp1Time;
datetime extrDown0Time, extrDown1Time;
CMoveContainer *moveContainer;
CExtrContainer *extrContainer;

CChartObjectHLine topLine; // верхний уровень
CChartObjectHLine bottomLine; // нижний уровень

// параметры вычисления статистики
double topLevel;   // верхний уровень, который нужно пробить
double bottomLevel; // нижний уровень, который нужно пробить
double H;  // ширина канала
int lastTrendDirection = 0; // направление последнего тренда
int flatType = 0; // тип флэта
int mode = 0; // режим

stat_elem stat[]; // буфер статистики
int countSit = 0; // количество ситуаций

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
   extrContainer = new CExtrContainer(handleDE,_Symbol,_Period);
   moveContainer = new CMoveContainer(0,_Symbol,_Period,handleDE,percent);
   // генерируем уникальные имена событий прихода новых сформированных экстремумов
   eventExtrDownFormed = GenUniqEventName("EXTR_UP_FORMED");
   eventExtrUpFormed = GenUniqEventName("EXTR_DOWN_FORMED");
   if (!firstUploadedMovements)
    {
     firstUploadedMovements = moveContainer.UploadOnHistory();
    }
   if (!firstUploadedExtremums)
    {
     firstUploadedExtremums = extrContainer.Upload();
    }   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete extrContainer;
   delete moveContainer;
  }

void OnTick()
  {
   if (!firstUploadedMovements)
    {
     firstUploadedMovements = moveContainer.UploadOnHistory();
    }
   if (!firstUploadedExtremums)
    {
     firstUploadedExtremums = extrContainer.Upload();
    }
   if (!firstUploadedMovements || !firstUploadedExtremums)
    return;   
   // если сейчас режим mode = 1, то проверяем пробитие 
   if (mode == 1)
    {
     // если цена достигла верхней линии
     if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),topLevel))
      {
       // переводим в режим поиска тренда
       mode = 0;
       // удаляем линии канала 
       DeleteChannel();
      }
     // если цена достигла нижней линии
     if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottomLevel))
      {
       // сохраняем параметры ситуации статистики
       stat[countSit-1].countDown ++;
       stat[countSit-1].flat_type =        
       // переводим в режим поиска тренда
       mode = 0;
       // удаляем линии канала
       DeleteChannel();
      }
    }
  }
  
// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   int flatNow;  
   int countMove;
   // то загружаем данные в контейнер экстремумов и трендов
   moveContainer.UploadOnEvent(sparam,dparam,lparam);
   extrContainer.UploadOnEvent(sparam,dparam,lparam); 
   // если пришло событие "сформировался экстремум"
   if (sparam == eventExtrUpFormed || sparam == eventExtrDownFormed)
    { 
      // сохраняем экстремумы
      
      extrUp0 = extrContainer.GetFormedExtrByIndex(0,EXTR_HIGH).price;
      extrUp1 = extrContainer.GetFormedExtrByIndex(1,EXTR_HIGH).price;
      extrDown0 = extrContainer.GetFormedExtrByIndex(0,EXTR_LOW).price;
      extrDown1 = extrContainer.GetFormedExtrByIndex(1,EXTR_LOW).price;
      extrUp0Time = extrContainer.GetFormedExtrByIndex(0,EXTR_HIGH).time;
      extrUp1Time = extrContainer.GetFormedExtrByIndex(1,EXTR_HIGH).time;      
      extrDown0Time = extrContainer.GetFormedExtrByIndex(0,EXTR_LOW).time;
      extrDown1Time = extrContainer.GetFormedExtrByIndex(1,EXTR_LOW).time;
      
      // если пришел тренд вверх
      if (moveContainer.GetMoveByIndex(0).GetMoveType() == 1)
       {
        lastTrendDirection = 1;
       }
      // если пришел тренд вниз
      if (moveContainer.GetMoveByIndex(0).GetMoveType() == -1)
       {
        lastTrendDirection = -1;
       }      
      // если сейчас не режим пробития тренда и мы только нашли ситуацию для построения канала для вычисления статистики
      if (mode == 0)
       {
        // если сейчас в контейнере движений - 3 движения, значит самое время вычислять параметры канала
        if (moveContainer.GetTotal()==3)
         {
          flatType = moveContainer.GetMoveByIndex(0).GetMoveType();
          // то вычисляем параметры каналов
          H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
          topLevel = extrUp0 + H*0.75;
          bottomLevel = extrDown0 - H*0.75;
          // выделяем память под новую ситуацию
          countSit ++;
          ArrayResize(stat,countSit);
          // рисуем линии  
          DrawChannel();
          // выставляем режим mode в 1, что означает, что мы ждем пробития линий канала или другого тренда
          mode = 1;
         }
       }
      // если сейчас режим пробития линий каналов
      else 
       {
        // если пришел другой тренд
        if (moveContainer.GetMoveByIndex(0).GetMoveType() == 1 || moveContainer.GetMoveByIndex(0).GetMoveType() == -1)
         {
          mode = 0;
          DeleteChannel ();
         }
       }
     
    }
  }
  
// генерирует уникальное имя события
string GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }   

// рисует канал 
void DrawChannel ()
 {
  topLine.Create(0,"topLevel",0,topLevel);
  bottomLine.Create(0,"bottomLevel",0,bottomLevel);
 }

// удаляем линии
void DeleteChannel ()
 {
  topLine.Delete();
  bottomLine.Delete();
 }

// сохраняет параметры флэта 
void SaveFlatParams (int trend,int flat,int extr,int up,int down)
 {
  stat[countSit-1].countDown = down;
  stat[countSit-1].countUp = up;
  stat[countSit-1].flat_type = flat;
  stat[countSit-1].last_extr = extr;
  stat[countSit-1].trend_direction = trend;
 }
 
// функция возвращает строку с подсчитанными данными для типа тренда
string GetFlatTypeStat (string flatType,int trend,int flat,int extr)
 {
  string str="";
  int countUp=0; // количество достижений верхней линии
  int countDown=0; // количество достижений нижней линии
  // проходим по всему буферу и подсчитываем количества
  for (int i=0;i<countSit;i++)
   {
    // если нашли нашу ситуацию
    if (trend == stat[i].trend_direction && 
        flat == stat[i].flat_type &&
        extr == stat[i].last_extr)
         {
          if (stat[i].countUp == 1)
           countUp++;
          if (stat[i].countDown == 1)
           countDown++;
         }
   }
  // формируем строку
  str = "Тип флэта: "+flatType+" тренд: "+trend+" flat: "+flat+" extr: "+extr+" верха: "+countUp+" низа: "+countDown;
  return str;
 }