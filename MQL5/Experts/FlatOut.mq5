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
int indexOfElemNow = 0; // индекс текущей ситуации в массиве ситуаций
double H; // высота флэта
double top_point; // верхняя точка, которую нужно достичь
double bottom_point; // нижняя точка, которую нужно достичь
double extrUp0,extrUp1;
double extrDown0,extrDown1;
datetime extrUp0Time;
datetime extrDown0Time;
datetime extrUp1Time;
datetime extrDown1Time;

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
   // заполняем поля позиции
   pos_info.volume = volume;
   pos_info.expiration = 0;
   // заполняем 
   trailing.trailingType = TRAILING_TYPE_NONE;   
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
   // если открытых позиций нет
   if (ctm.GetPositionCount() == 0)
    mode = 0; 
    
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
       // если сейчас тренд
       if (trend.IsTrendNow() != 0)
        {
         // если мы нашли тренд
         trendType = trend.GetTrendByIndex(0).GetDirection();
         if (trendType != 0)
          {
           // переходим в режим отслеживания флэта
           mode = 1;
          }
         }
      }
     else if (mode == 1)
      {
       // если сейчас снова тренд
       if (trend.IsTrendNow())
        {
         trendType = trend.GetTrendByIndex(0).GetDirection();
        }
       // если сейчас не тренд
       else
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

 // ДЛЯ ФЛЭТА А

         // если сейчас флэт А и последний экстремум - верхний, тренд вверх
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт А и последний экстремум - верхний, тренд вниз
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт А и последний экстремум - нижний, тренд вверх
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт А и последний экстремум - нижний, тренд вниз
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          } 
                    
 // ДЛЯ ФЛЭТА B

         // если сейчас флэт B и последний экстремум - верхний, тренд вверх
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт B и последний экстремум - верхний, тренд вниз
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт B и последний экстремум - нижний, тренд вверх
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт B и последний экстремум - нижний, тренд вниз
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }  
           
 // ДЛЯ ФЛЭТА C

         // если сейчас флэт B и последний экстремум - верхний, тренд вверх
         if (IsFlatC() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт C и последний экстремум - верхний, тренд вниз
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт C и последний экстремум - нижний, тренд вверх
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт C и последний экстремум - нижний, тренд вниз
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }     

 // ДЛЯ ФЛЭТА D

         // если сейчас флэт D и последний экстремум - верхний, тренд вверх
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт D и последний экстремум - верхний, тренд вниз
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт D и последний экстремум - нижний, тренд вверх
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт D и последний экстремум - нижний, тренд вниз
         if (IsFlatD() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }     

 // ДЛЯ ФЛЭТА E

         // если сейчас флэт E и последний экстремум - верхний, тренд вверх
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт E и последний экстремум - верхний, тренд вниз
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт E и последний экстремум - нижний, тренд вверх
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт E и последний экстремум - нижний, тренд вниз
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          } 

 // ДЛЯ ФЛЭТА F

         // если сейчас флэт F и последний экстремум - верхний, тренд вверх
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт F и последний экстремум - верхний, тренд вниз
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт F и последний экстремум - нижний, тренд вверх
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт F и последний экстремум - нижний, тренд вниз
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }      
                      
 // ДЛЯ ФЛЭТА G

         // если сейчас флэт G и последний экстремум - верхний, тренд вверх
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }
         // если сейчас флэт G и последний экстремум - верхний, тренд вниз
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
          }   
         // если сейчас флэт G и последний экстремум - нижний, тренд вверх
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           OpenPosition(1);
           mode = 2;
          }                    
         // если сейчас флэт G и последний экстремум - нижний, тренд вниз
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           OpenPosition(1);
           mode = 2;
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
 
bool IsFlatF ()
 {
  //  если 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0), percent*H) &&
       GreatOrEqualDoubles (extrDown1 - extrDown0 , percent*H)
     )
    {
     return (true);
    }
  return (false);
 } 

bool IsFlatG ()
 {
  //  если 
  if ( GreatOrEqualDoubles (extrUp0 - extrUp1, percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1), percent*H)
     )
    {
     return (true);
    }
  return (false);
 }   
 
 // вычисление параметров текущего флэта при его обнаружениии
 void OpenPosition (int type)
  {
   H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
   top_point = extrUp0 + H*0.75;
   bottom_point = extrDown0 - H*0.75;
   if (type == 1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int( MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_point)/_Point );       
     pos_info.tp = int( MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_point)/_Point );       
    }
   else
    {
     pos_info.type = OP_SELL;
     pos_info.sl = int( MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_BID) - bottom_point)/_Point );       
     pos_info.tp = int( MathAbs(SymbolInfoDouble(_Symbol,SYMBOL_BID) - top_point)/_Point );     
    }

   pos_info.priceDifference = 0;     
   ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
  }