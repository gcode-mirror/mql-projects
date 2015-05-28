//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// эксперт собирает статистику по флэтам типа А

#include <MoveContainer/CMoveContainer.mqh> // контейнер движений
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <DrawExtremums/CExtremum.mqh> // объект экстремумов
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда

input double percent = 0.1;


CExtrContainer *extr_container;
bool firstUploadedExtr = false;
int handleDE;
string cameHighEvent;  // имя события прихода верхнего экстремума
string cameLowEvent;   // имя события прихода нижнего экстремума
// переменные канала
double h; // ширина канала флэта
double bottom_price; // цена нижней границы канала
double top_price; // цена верхней границы канала
// экстремумы движений
CExtremum trend_high0,trend_high1; 
CExtremum trend_low0,trend_low1;

CExtremum flat_high0,flat_high1;
CExtremum flat_low0,flat_low1;

// объекты отображения канала флэтов
CChartObjectTrend flatLine;    // объект класса флэтовой линии
CChartObjectTrend trendLine;   // объект класса трендовой линии
CChartObjectHLine topLevel;    // верхний уровень
CChartObjectHLine bottomLevel; // нижний уровень

// параметры для рассчета статистики

// тренд вверх, экстремум вверх
int countTotal0 = 0;
int countUp0 = 0;
int countDown0 = 0;
// тренд вверх, экстремум вниз
int countTotal1 = 0;
int countUp1 = 0;
int countDown1 = 0;
// тренд вниз, экстремум вверх
int countTotal2 = 0;
int countUp2 = 0;
int countDown2 = 0;
// тренд вниз, экстремум вниз
int countTotal3 = 0;
int countUp3 = 0;
int countDown3 = 0;

int mode = 0;  // 0 - режим поиска ситуации, 1 - режим ожидания пробития
int type; // тип ситуации 
int trend;
int extr;

// переменные для файла
int fileHandle; // хэндл файла

int OnInit()
  {
   
   // создаем хэндл файла тестирования статистики прохождения уровней
   fileHandle = FileOpen("FLAT_STAT/FLAT_C_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //не удалось открыть файл
    {
     Print("Не удалось создать файл тестирования статистики прохождения уровней");
     return (INIT_FAILED);
    }   
   // сохраняем имена событий
   cameHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   cameLowEvent  = GenUniqEventName("EXTR_DOWN_FORMED");
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
   extr_container = new CExtrContainer(handleDE,_Symbol,_Period);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete extr_container;
   SaveStatToFile ();
   FileClose(fileHandle);
  }

void OnTick()
  {
    int crossed;
    if (!firstUploadedExtr)
    {
     firstUploadedExtr = extr_container.Upload();
    }    
   if (!firstUploadedExtr)
    return;    
   // если сейчас режим пробития границ канала 
   if (mode == 1)
    {
     crossed = CrossChannel();
     // если пробита верхняя граница
     if (crossed == 1)
      {
       // подсчитываем 
       CountStatForSituation (1);
       // переводим в режим поиска новой ситуации
       mode = 0;
       // и удаляем линии
       DeleteAllLines ();
       
       Comment("пересечена верхняя линия",
               "\n trend = ",trend,
               "\nэкстремум = ",extr,
               "\n countTotal0 = ",countTotal0,
               "\n countUp0 = ",countUp0,
               "\n countDown0 = ",countDown0,
               "\n countTotal1 = ",countTotal1,
               "\n countUp1 = ",countUp1,
               "\n countDown1 = ",countDown1,
               "\n countTotal2 = ",countTotal2,
               "\n countUp2 = ",countUp2,
               "\n countDown2 = ",countDown2,
               "\n countTotal3 = ",countTotal3,
               "\n countUp3 = ",countUp3,
               "\n countDown3 = ",countDown3                                             
               );
       
      }
     // если пробита нижняя граница
     if (crossed == -1)
      {
       // подсчитываем
       CountStatForSituation (-1);
       // переводим в режим поиска новой ситуации
       mode = 0;
       // и удаляем линии
       DeleteAllLines ();
       
       Comment("пересечена нижняя линия",
               "\n trend = ",trend,
               "\nэкстремум = ",extr,
               "\n countTotal0 = ",countTotal0,
               "\n countUp0 = ",countUp0,
               "\n countDown0 = ",countDown0,
               "\n countTotal1 = ",countTotal1,
               "\n countUp1 = ",countUp1,
               "\n countDown1 = ",countDown1,
               "\n countTotal2 = ",countTotal2,
               "\n countUp2 = ",countUp2,
               "\n countDown2 = ",countDown2,
               "\n countTotal3 = ",countTotal3,
               "\n countUp3 = ",countUp3,
               "\n countDown3 = ",countDown3                                             
               );       
       
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

    // обновляем контейнер экстремумов
    extr_container.UploadOnEvent(sparam,dparam,lparam);
    // если пришло событие, что сформировался верхний экстремум
    if (sparam == cameHighEvent)
     {
      // если сейчас режим 0, то ищем флэт
      if (mode == 0)
       {
        extr = 1;
        // если сейчас флэт 
        if ( IsFlatC(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // проверяем, что предыдущее движение не является трендом
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                         {
                          // проверяем, что пред предыщушиее движение - тренд
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // вычисляем параметры канала
                                           CountFlatChannel();
                                           // отрисовываем ситуации
                                           DrawChannel ();      
                                           // переходим в режим 1 (пробитие границ канала или приход нового тренда) 
                                           mode = 1;   
                                           
                                           // определяем тип ситуации
                                           if (trend == 1)
                                            {
                                             countTotal0++;
                                             type = 0;
                                            }
                                           if (trend == -1)
                                            {
                                             countTotal2++;
                                             type = 2;
                                            }   
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM
    // если пришло событие, что сформировался нижний экстремум
    if (sparam == cameLowEvent)
     {
      // если сейчас режим 0, то ищем флэт
      if (mode == 0)
       {
        extr = -1;
        // если сейчас флэт 
        if ( IsFlatC(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // проверяем, что предыдущее движение не является трендом
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                         {
                          // проверяем, что пред предыщушиее движение - тренд
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // вычисляем параметры канала
                                           CountFlatChannel();
                                           // отрисовываем ситуации
                                           DrawChannel ();      
                                           // переходим в режим 1 (пробитие границ канала или приход нового тренда) 
                                           mode = 1;   
                                           
                                           // определяем тип ситуации
                                           if (trend == 1)
                                            {
                                             countTotal1++;
                                             type = 1;
                                            }
                                           if (trend == -1)
                                            {
                                             countTotal3++;
                                             type = 3;
                                            }   
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM     
  }
  
 // функция вычисляет параметры канала флэта
 void CountFlatChannel ()
  {
   h = MathMax(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price,extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price) -
       MathMin(extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price,extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price);
   top_price = extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price + 0.75*h;
   bottom_price = extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price - 0.75*h;
  } 
  
  
 // дополнительные функции
 void  DrawChannel ()  // создает линии флэта
  {
   DeleteAllLines ();
   flatLine.Create(0, "flatUp", 0, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price); // верхняя линия  
   
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   flatLine.Create(0, "flatDown", 0, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price); // нижняя линия  
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   
   
   trendLine.Create(0, "trendUp", 0, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).price); // верхняя линия  
   
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);
   trendLine.Create(0, "trendDown", 0, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(2,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(2,EXTR_LOW).price); // нижняя линия  
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);   
   
   topLevel.Create(0, "topLevel", 0, top_price);
   bottomLevel.Create(0, "bottomLevel", 0, bottom_price);   
  }
  
 // функция удаляет линии с графика
 void DeleteAllLines ()
  {
   ObjectDelete(0,"flatUp");
   ObjectDelete(0,"flatDown");
   ObjectDelete(0,"trendUp");
   ObjectDelete(0,"trendDown");
   topLevel.Delete();
   bottomLevel.Delete();   
  }
 
int IsFlatC (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт C
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price),percent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price),percent*height)
     )
    {
     return (true);
    }
  return (false);
 } 
 

int IsItTrend(CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // проверяет, является ли данный канал трендовым
 {
  double h1,h2;
  double H1,H2;
  // если тренд вверх 
  if ( GreatDoubles(high0.price,high1.price) && GreatDoubles(low0.price,low1.price))
   {
    // если последний экстремум - вниз
    if (low0.time > high0.time)
     {
      H1 = high0.price - low1.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
    // если последний экстремум - вверх
    if (low0.time < high0.time)
     {
      H1 = high1.price - low0.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
      
   }
  // если тренд вниз
  if ( LessDoubles(high0.price,high1.price) && LessDoubles(low0.price,low1.price))
   {
    
    // если  последний экстремум - вверх
    if (high0.time > low0.time)
     {
      H1 = high1.price - low0.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
    // если последний экстремум - вниз
    else if (high0.time < low0.time)
     {
      H1 = high0.price - low1.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h2,H1*percent) && GreatDoubles(h1,H2*percent) )    
       return (-1);
     }
     
   }   
   
  return (0);
 } 
 

// генерирует имя события 
string  GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }
 
// смотрит пробитие границ канала
int CrossChannel ()
 {
  // если цена пересекла верхнюю границу канала
  if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),top_price))
   {
    return (1);
   }
  // если цена пересекла нижнюю границу канала
  if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottom_price))
   {
    return (-1);
   }
  return (0);
 } 

// подсчитывает параметры пробитий
void CountStatForSituation (int crossType)
 {
  switch (type)
   {
    case 0: // тренд вверх, экстремум верхний
     // если пересекли верхнюю линию
     if (crossType == 1)
      {
       countUp0++;
      }
     // если пересекли нижнюю линию\
     if (crossType == -1)
      {
       countDown0++;
      }
    break;
    case 1: // тренд вверх, экстремум нижний
     // если пересекли верхнюю линию
     if (crossType == 1)
      {
       countUp1++;
      }
     // если пересекли нижнюю линию\
     if (crossType == -1)
      {
       countDown1++;
      }
    break;
    case 2: // тренд вверх, экстремум верхний
     // если пересекли верхнюю линию
     if (crossType == 1)
      {
       countUp2++;
      }
     // если пересекли нижнюю линию\
     if (crossType == -1)
      {
       countDown2++;
      }
    break;
    case 3: // тренд вверх, экстремум верхний
     // если пересекли верхнюю линию
     if (crossType == 1)
      {
       countUp3++;
      }
     // если пересекли нижнюю линию\
     if (crossType == -1)
      {
       countDown3++;
      }
    break;            
   }
 }
 
// сохраняет статистику в файл
void SaveStatToFile ()
 { 
  FileWriteString(fileHandle,"Статистика по флэту типа C: \n");
  FileWriteString(fileHandle," {\n");
  FileWriteString(fileHandle,"  Для тренда вверх, последний экстремум - верхний: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество всего: "+IntegerToString(countTotal0)+"\n");
  FileWriteString(fileHandle,"     количество пробитий верха: "+IntegerToString(countUp0)+"\n");   
  FileWriteString(fileHandle,"     количество пробитий низа: "+IntegerToString(countDown0)+"\n");
  FileWriteString(fileHandle,"   }\n");
  FileWriteString(fileHandle,"  Для тренда вверх, последний экстремум - нижний: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество всего: "+IntegerToString(countTotal1)+"\n");
  FileWriteString(fileHandle,"     количество пробитий верха: "+IntegerToString(countUp1)+"\n");   
  FileWriteString(fileHandle,"     количество пробитий низа: "+IntegerToString(countDown1)+"\n");
  FileWriteString(fileHandle,"   }\n");        
  FileWriteString(fileHandle,"  Для тренда вниз, последний экстремум - верхний: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество всего: "+IntegerToString(countTotal2)+"\n");
  FileWriteString(fileHandle,"     количество пробитий верха: "+IntegerToString(countUp2)+"\n");   
  FileWriteString(fileHandle,"     количество пробитий низа: "+IntegerToString(countDown2)+"\n");
  FileWriteString(fileHandle,"   }\n");  
  FileWriteString(fileHandle,"  Для тренда вниз, последний экстремум - нижний: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество всего: "+IntegerToString(countTotal3)+"\n");
  FileWriteString(fileHandle,"     количество пробитий верха: "+IntegerToString(countUp3)+"\n");   
  FileWriteString(fileHandle,"     количество пробитий низа: "+IntegerToString(countDown3)+"\n");
  FileWriteString(fileHandle,"   }\n");        
  FileWriteString(fileHandle," }\n");   
 } 