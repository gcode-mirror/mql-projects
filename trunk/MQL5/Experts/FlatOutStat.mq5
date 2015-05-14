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
  int count;     // количество таких случаев в истории
  int countUp;   // количество достижений верхней границы
  int countDown; // количество достижений нижней границы
  int trend;     // тип тренда 
  string flat;   // тип флэта
  int lastExtr;  // тип последнего экстремума
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
int fileTestStat; // хэндл файла
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
   // создаем хэндл файла тестирования статистики прохождения уровней
   fileTestStat = FileOpen("FlatOutStat/FlatOutStat 8.5.15/FlatStat_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileTestStat == INVALID_HANDLE) //не удалось открыть файл
    {
     Print("Не удалось создать файл тестирования статистики прохождения уровней");
     return (INIT_FAILED);
    }      
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
   SaveStatToFile (); // сохраняем статистику в файл
   FileClose(fileTestStat);
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
   // если сейчас режим ожидания пробития каналов
   if (mode == 2)
    {
     // если цена достигла верхней линии
     if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point))
      {
       elem[indexOfElemNow].countUp ++; // увеличиваем количество пробитий
       mode = 0; // переходим в изначальный режим поиска тренда
       topLevel.Delete(); // удаляем верхнюю линию
       bottomLevel.Delete(); // удаляем нижнюю линию
      }
     // если цена достигла нижней линии
     if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottom_point))
      {
       elem[indexOfElemNow].countDown ++; // увеличиваем количество пробитий
       mode = 0; // переходим в изначальный режим поиска тренда
       topLevel.Delete(); // удаляем верхнюю линию
       bottomLevel.Delete(); // удаляем нижнюю линию
      }      
    } 
    
   
    Comment("тренд = ",trendType,
            "последний экстремум = "
    
            "\n\nтип А, тренд вверх, посл. экстр - вверх, количество пробитий вверх = ",elem[0].countUp,
            "\nтип А, тренд вверх, посл. экстр - вверх, количество пробитий вниз = ",elem[0].countDown,
            
            "\n\nтип А, тренд вниз, посл. экстр - вверх, количество пробитий вверх = ",elem[1].countUp,
            "\nтип А, тренд вниз, посл. экстр - вверх, количество пробитий вниз = ",elem[1].countDown,    
            
            "\n\nтип А, тренд вверх, посл. экстр - вниз, количество пробитий вверх = ",elem[2].countUp,
            "\nтип А, тренд вверх, посл. экстр - вниз, количество пробитий вниз = ",elem[2].countDown,    
            
            "\n\nтип А, тренд вниз, посл. экстр - вниз, количество пробитий вверх = ",elem[3].countUp,
            "\nтип А, тренд вниз, посл. экстр - вниз, количество пробитий вниз = ",elem[3].countDown                        
                    
            );
    
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
           CalcFlat(0,"A",1,1);
           mode = 2;
          }
         // если сейчас флэт А и последний экстремум - верхний, тренд вниз
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(1,"A",1,-1);
           mode = 2;
          }   
         // если сейчас флэт А и последний экстремум - нижний, тренд вверх
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(2,"A",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт А и последний экстремум - нижний, тренд вниз
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(3,"A",-1,-1);
           mode = 2;
          } 
                    
 // ДЛЯ ФЛЭТА B

         // если сейчас флэт B и последний экстремум - верхний, тренд вверх
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(4,"B",1,1);
           mode = 2;
          }
         // если сейчас флэт B и последний экстремум - верхний, тренд вниз
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(5,"B",1,-1);
           mode = 2;
          }   
         // если сейчас флэт B и последний экстремум - нижний, тренд вверх
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(6,"B",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт B и последний экстремум - нижний, тренд вниз
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(7,"B",-1,-1);
           mode = 2;
          }  
           
 // ДЛЯ ФЛЭТА C

         // если сейчас флэт B и последний экстремум - верхний, тренд вверх
         if (IsFlatC() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(8,"C",1,1);
           mode = 2;
          }
         // если сейчас флэт C и последний экстремум - верхний, тренд вниз
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(9,"C",1,-1);
           mode = 2;
          }   
         // если сейчас флэт C и последний экстремум - нижний, тренд вверх
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(10,"C",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт C и последний экстремум - нижний, тренд вниз
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(11,"C",-1,-1);
           mode = 2;
          }     

 // ДЛЯ ФЛЭТА D

         // если сейчас флэт D и последний экстремум - верхний, тренд вверх
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(12,"D",1,1);
           mode = 2;
          }
         // если сейчас флэт D и последний экстремум - верхний, тренд вниз
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(13,"D",1,-1);
           mode = 2;
          }   
         // если сейчас флэт D и последний экстремум - нижний, тренд вверх
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(14,"D",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт D и последний экстремум - нижний, тренд вниз
         if (IsFlatD() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(15,"D",-1,-1);
           mode = 2;
          }     

 // ДЛЯ ФЛЭТА E

         // если сейчас флэт E и последний экстремум - верхний, тренд вверх
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(16,"E",1,1);
           mode = 2;
          }
         // если сейчас флэт E и последний экстремум - верхний, тренд вниз
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(17,"E",1,-1);
           mode = 2;
          }   
         // если сейчас флэт E и последний экстремум - нижний, тренд вверх
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(18,"E",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт E и последний экстремум - нижний, тренд вниз
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(19,"E",-1,-1);
           mode = 2;
          } 

 // ДЛЯ ФЛЭТА F

         // если сейчас флэт F и последний экстремум - верхний, тренд вверх
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(20,"F",1,1);
           mode = 2;
          }
         // если сейчас флэт F и последний экстремум - верхний, тренд вниз
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(21,"F",1,-1);
           mode = 2;
          }   
         // если сейчас флэт F и последний экстремум - нижний, тренд вверх
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(22,"F",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт F и последний экстремум - нижний, тренд вниз
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(23,"F",-1,-1);
           mode = 2;
          }      
                      
 // ДЛЯ ФЛЭТА G

         // если сейчас флэт G и последний экстремум - верхний, тренд вверх
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(24,"G",1,1);
           mode = 2;
          }
         // если сейчас флэт G и последний экстремум - верхний, тренд вниз
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(25,"G",1,-1);
           mode = 2;
          }   
         // если сейчас флэт G и последний экстремум - нижний, тренд вверх
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(26,"G",-1,1);
           mode = 2;
          }                    
         // если сейчас флэт G и последний экстремум - нижний, тренд вниз
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(27,"G",-1,-1);
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
 
void ResetAllElems ()
 {
  for (int i = 0;i<28;i++)
   {
    elem[i].count = 0;
    elem[i].countDown = 0;
    elem[i].countUp = 0;
    elem[i].flat = "-";
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
 void CalcFlat (int index,string flatType,int lastExtr,int trend)
  {
   H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
   top_point = extrUp0 + H*0.75;
   bottom_point = extrDown0 - H*0.75;
   DrawFlatLines ();
   elem[index].flat = flatType;
   elem[index].lastExtr = lastExtr;
   elem[index].trend = trend;
   elem[index].count ++; 
   indexOfElemNow = index;
  }
 
 // сохраняет статистику в файл
 void SaveStatToFile ()
  {
   FileWriteString(fileTestStat,"Статистика: \n\n");
   for (int i=0;i<28;i++)
    {
     FileWriteString(fileTestStat,"тип флэта: "+elem[i].flat+" | тренд: "+IntegerToString(elem[i].trend)+" | посл. экстр: "+
                                  " | "+IntegerToString(elem[i].lastExtr)+" | достигло верха: "+IntegerToString(elem[i].countUp)+" | достигло низа: "+IntegerToString(elem[i].countDown)+"\n\n");
    }
  }