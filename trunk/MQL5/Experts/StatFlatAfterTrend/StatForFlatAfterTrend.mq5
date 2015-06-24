//+------------------------------------------------------------------+
//|                                        StatForFlatAfterTrend.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт для проведения статистики флэтов после трендов           |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <DrawExtremums/CExtremum.mqh> // объект экстремумов
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда

// входные параметры
input double trendPercent = 0.1; // процент вычисления тренда 

CExtrContainer *extr_container;
bool firstUploadedExtr = false;
int handleDE;
int mode = 0; // переменная для хранения режима вычисления статистики (0 - еще не найден тренд,1 - найден тренд, а значит ищем флэт)
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

// статистические данные
int total = 0; // всего количество ситуаций

// для флэта A
int AtrendUp = 0;
int AtrendDown = 0;
// для флэта B
int BtrendUp = 0;
int BtrendDown = 0;
// для флэта C
int CtrendUp = 0;
int CtrendDown = 0;
// для флэта D
int DtrendUp = 0;
int DtrendDown = 0;
// для флэта E
int EtrendUp = 0;
int EtrendDown = 0;
// для флэта F
int FtrendUp = 0;
int FtrendDown = 0;
// для флэта G
int GtrendUp = 0;
int GtrendDown = 0;

int last_trend; // переменная для хранения последнего тренда
int flat_now; // сохраняет тип флэта

CChartObjectTrend _trendLine; // объект класса линии тренда
CChartObjectTrend _flatLine; // объект класса линии
int countFlat = 0; // количество флэтов
int countTrend = 0; // количество трендов

// переменные для файла
int fileHandle; // хэндл файла

int OnInit()
  {
   // создаем хэндл файла тестирования статистики прохождения уровней
   fileHandle = FileOpen("FLAT_STAT_AFTER_TREND/STAT" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
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
   DeleteAllLines ();
   FileClose(fileHandle);
  }

void OnTick()
  {
   if (!firstUploadedExtr)
    {
     firstUploadedExtr = extr_container.isUploaded();
    }    
   if (!firstUploadedExtr)
    return;       
  }
  
// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   int tempTrend; // переменная для хранения временного значения тренда
   // обновляем контейнер экстремумов
   extr_container.UploadOnEvent(sparam,dparam,lparam);   
   // если пришло событие "сформировался новый экстремум"
   if (sparam == cameHighEvent || sparam == cameLowEvent)
    {
     // если сейчас режим поиска тренда
     if (mode == 0)
      {
       // если сейчас тренд
       last_trend = IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                              extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) );
       countTrend ++;
       DrawTrendLines(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                 extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW));                              
       if (last_trend == 1 || last_trend == -1)
        {
         mode = 1;
        }
      }
     // если сейчас режим поиск флэта
     else if (mode == 1)
     {
      // проверяем флэт при условии что следующее движение - не тренд
      if (sparam == cameHighEvent)
       {
        flat_now = GetTypeFlat(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                               extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) );
        // если словили  флэт
        if (flat_now > 0)
         {
         

                                 
          tempTrend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) );
          // если предыдущее движение не тренд
          if (tempTrend != 1 && tempTrend != -1)
           {
            countFlat ++;
            DrawFlatLines(flat_now,extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                   extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW));
            // то увеличиваем счетчики в зависимости от типа флэта
            RecountCounts();
            mode = 0;
           }
  
         }
                               
       }
      // проверяем флэт при условии что следующее движение - не тренд
      if (sparam == cameLowEvent)
       {
        flat_now = GetTypeFlat(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                               extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) );
        // если словили  флэт
        if (flat_now > 0)
         {
          tempTrend = IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) );
          // если предыдущее движение не тренд
          if (tempTrend != 1 && tempTrend != -1)
           {
            countFlat ++;
            DrawFlatLines(flat_now,extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                   extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW));         
            // то увеличиваем счетчики в зависимости от типа флэта
            RecountCounts();
            mode = 0;
           }
  
         }
                               
       }       
       
     }  
    } // END OF SPARAM
  }
  
  
// системные функции

// определяет, не является ли движение по заданным точкам трендом
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
      if (GreatDoubles(h1,H1*trendPercent) && GreatDoubles(h2,H2*trendPercent) )
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
      if (GreatDoubles(h1,H1*trendPercent) && GreatDoubles(h2,H2*trendPercent) )
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
      if (GreatDoubles(h1,H1*trendPercent) && GreatDoubles(h2,H2*trendPercent) )    
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
      if (GreatDoubles(h2,H1*trendPercent) && GreatDoubles(h1,H2*trendPercent) )    
       return (-1);
     }
     
   }   
   
  return (0);
 } 
 
 
 bool IsFlatA (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1)  // флэт А  
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price),trendPercent*height) &&
       GreatOrEqualDoubles (low0.price - low1.price,trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 } 
 
 bool IsFlatB (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт B
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( GreatOrEqualDoubles (high1.price-high0.price,trendPercent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price),trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 }
 
 bool IsFlatC (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт C
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price),trendPercent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price),trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 } 
 
 bool IsFlatD (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт D
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( GreatOrEqualDoubles (high1.price - high0.price,trendPercent*height) &&
       GreatOrEqualDoubles (low0.price - low1.price,trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 }  

 bool IsFlatE (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт E
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( GreatOrEqualDoubles (high0.price-high1.price,trendPercent*height) &&
       GreatOrEqualDoubles (low1.price - low0.price,trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 }
 
 bool IsFlatF (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт F
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price), trendPercent*height) &&
       GreatOrEqualDoubles (low1.price -low0.price , trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 }   
 
 bool IsFlatG (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // флэт G
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( GreatOrEqualDoubles (high0.price - high1.price, trendPercent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price), trendPercent*height)
     )
    {
     return (true);
    }
  return (false);
 }   
 
// функция возвращает тип флэта в данный момент
int GetTypeFlat (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1)
 {
  if (IsFlatA(high0,high1,low0,low1))
   return (1);
  if (IsFlatB(high0,high1,low0,low1))
   return (2);
  if (IsFlatC(high0,high1,low0,low1))
   return (3);
  if (IsFlatD(high0,high1,low0,low1))
   return (4);
  if (IsFlatE(high0,high1,low0,low1))
   return (5);
  if (IsFlatF(high0,high1,low0,low1))
   return (6);
  if (IsFlatG(high0,high1,low0,low1))
   return (7);  
  return (0);               
 } 
 
// функция изменяет счетчики ситуаций
void RecountCounts ()
 {
  if (flat_now == 1) // если был пойман флэт А 
   {
    if (last_trend == 1)
     AtrendUp ++;
    if (last_trend == -1)
     AtrendDown ++;     
   }
  if (flat_now == 2) // если был пойман флэт B
   {
    if (last_trend == 1)
     BtrendUp ++;
    if (last_trend == -1)
     BtrendDown ++;     
   }   
  if (flat_now == 3) // если был пойман флэт C
   {
    if (last_trend == 1)
     CtrendUp ++;
    if (last_trend == -1)
     CtrendDown ++;     
   }   
  if (flat_now == 4) // если был пойман флэт D
   {
    if (last_trend == 1)
     DtrendUp ++;
    if (last_trend == -1)
     DtrendDown ++;     
   }   
  if (flat_now == 5) // если был пойман флэт E
   {
    if (last_trend == 1)
     EtrendUp ++;
    if (last_trend == -1)
     EtrendDown ++;     
   }
  if (flat_now == 6) // если был пойман флэт F
   {
    if (last_trend == 1)
     FtrendUp ++;
    if (last_trend == -1)
     FtrendDown ++;     
   } 
  if (flat_now == 1) // если был пойман флэт G
   {
    if (last_trend == 1)
     GtrendUp ++;
    if (last_trend == -1)
     GtrendDown ++;     
   }  
 } 

// генерирует имя события 
string  GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }
 
// рисует флэтовые линии
void DrawFlatLines (int flatType,CExtremum *high0,CExtremum *high1,CExtremum *low0,CExtremum *low1)
 {
  switch (flatType)
   {
    case 1:
    ObjectSetInteger(0,"flatAUp"+countFlat,OBJPROP_COLOR,clrYellow); 
    _flatLine.Create(0,"flatAUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatAUp"+countFlat,OBJPROP_COLOR,clrYellow);  
    ObjectSetInteger(0,"flatADown"+countFlat,OBJPROP_COLOR,clrYellow);
    _flatLine.Create(0,"flatADown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatADown"+countFlat,OBJPROP_COLOR,clrYellow);
    break;
    case 2:
    ObjectSetInteger(0,"flatBUp"+countFlat,OBJPROP_COLOR,clrRed); 
    _flatLine.Create(0,"flatBUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatBUp"+countFlat,OBJPROP_COLOR,clrRed);  
    ObjectSetInteger(0,"flatBDown"+countFlat,OBJPROP_COLOR,clrRed);
    _flatLine.Create(0,"flatBDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatBDown"+countFlat,OBJPROP_COLOR,clrRed);
    break;
    case 3:
    ObjectSetInteger(0,"flatCUp"+countFlat,OBJPROP_COLOR,clrGreenYellow); 
    _flatLine.Create(0,"flatCUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatCUp"+countFlat,OBJPROP_COLOR,clrGreenYellow);  
    ObjectSetInteger(0,"flatCDown"+countFlat,OBJPROP_COLOR,clrGreenYellow);
    _flatLine.Create(0,"flatCDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatCDown"+countFlat,OBJPROP_COLOR,clrGreenYellow);
    break;
    case 4:
    ObjectSetInteger(0,"flatDUp"+countFlat,OBJPROP_COLOR,clrPink);  
    _flatLine.Create(0,"flatDUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatDUp"+countFlat,OBJPROP_COLOR,clrPink);  
    ObjectSetInteger(0,"flatDDown"+countFlat,OBJPROP_COLOR,clrPink);
    _flatLine.Create(0,"flatDDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatDDown"+countFlat,OBJPROP_COLOR,clrPink);
    break;
    case 5:
    ObjectSetInteger(0,"flatEUp"+countFlat,OBJPROP_COLOR,clrViolet);  
    _flatLine.Create(0,"flatEUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatEUp"+countFlat,OBJPROP_COLOR,clrViolet);  
    ObjectSetInteger(0,"flatEDown"+countFlat,OBJPROP_COLOR,clrViolet);
    _flatLine.Create(0,"flatEDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatEDown"+countFlat,OBJPROP_COLOR,clrViolet);
    break;
    case 6:
    ObjectSetInteger(0,"flatFUp"+countFlat,OBJPROP_COLOR,clrLightCyan);  
    _flatLine.Create(0,"flatFUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatFUp"+countFlat,OBJPROP_COLOR,clrLightCyan);  
    ObjectSetInteger(0,"flatFDown"+countFlat,OBJPROP_COLOR,clrLightCyan);
    _flatLine.Create(0,"flatFDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatFDown"+countFlat,OBJPROP_COLOR,clrLightCyan);
    break;
    case 7:
    ObjectSetInteger(0,"flatGUp"+countFlat,OBJPROP_COLOR,clrLightGreen);  
    _flatLine.Create(0,"flatGUp"+countFlat,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"flatGUp"+countFlat,OBJPROP_COLOR,clrLightGreen);  
    ObjectSetInteger(0,"flatGDown"+countFlat,OBJPROP_COLOR,clrLightGreen);
    _flatLine.Create(0,"flatGDown"+countFlat,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"flatGDown"+countFlat,OBJPROP_COLOR,clrLightGreen);
    break;                        
   }
 }
 
// функция рисует линии тренда
void DrawTrendLines (CExtremum *high0,CExtremum *high1,CExtremum *low0,CExtremum *low1)
 {
    _trendLine.Create(0,"trendUp"+countTrend,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(0,"trendUp"+countTrend,OBJPROP_COLOR,clrLightBlue);  
    ObjectSetInteger(0,"trendUp"+countTrend,OBJPROP_WIDTH,3);
    _trendLine.Create(0,"trendDown"+countTrend,0,low0.time,low0.price,low1.time,low1.price); // нижняя линия 
    ObjectSetInteger(0,"trendDown"+countTrend,OBJPROP_COLOR,clrLightBlue);
    ObjectSetInteger(0,"trendDown"+countTrend,OBJPROP_WIDTH,3);    
 }

// функция удаляет все линии
void DeleteAllLines ()
 {
  int index;
  for (index=0;index<countFlat;index++)
   {
    ObjectDelete(0,"flatAUp"+index); 
    ObjectDelete(0,"flatADown"+index);    
    ObjectDelete(0,"flatBUp"+index);
    ObjectDelete(0,"flatBDown"+index);    
    ObjectDelete(0,"flatCUp"+index);
    ObjectDelete(0,"flatCDown"+index);    
    ObjectDelete(0,"flatDUp"+index);
    ObjectDelete(0,"flatDDown"+index);    
    ObjectDelete(0,"flatEUp"+index);
    ObjectDelete(0,"flatEDown"+index);    
    ObjectDelete(0,"flatFUp"+index);
    ObjectDelete(0,"flatFDown"+index);    
    ObjectDelete(0,"flatGUp"+index);   
    ObjectDelete(0,"flatGDown"+index);                            
   }
  for (index=0;index<countTrend;index++)
   {
    ObjectDelete(0,"trendUp"+index);
    ObjectDelete(0,"trendDown"+index);
                      
   }   
 }
 
 
// сохраняет статистику в файл
void SaveStatToFile ()
 { 
  FileWriteString(fileHandle,"Статистика по движениям после тренда: " + _Symbol + "\n");
  FileWriteString(fileHandle," {\n");
  FileWriteString(fileHandle,"  После тренда вверх: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество флэтов A: "+IntegerToString(AtrendUp)+"\n");   
  FileWriteString(fileHandle,"     количество флэтов B: "+IntegerToString(BtrendUp)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов C: "+IntegerToString(CtrendUp)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов D: "+IntegerToString(DtrendUp)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов E: "+IntegerToString(EtrendUp)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов F: "+IntegerToString(FtrendUp)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов G: "+IntegerToString(GtrendUp)+"\n");  
  FileWriteString(fileHandle,"   }\n");
   
  FileWriteString(fileHandle,"  После тренда вниз: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     количество флэтов A: "+IntegerToString(AtrendDown)+"\n");   
  FileWriteString(fileHandle,"     количество флэтов B: "+IntegerToString(BtrendDown)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов C: "+IntegerToString(CtrendDown)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов D: "+IntegerToString(DtrendDown)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов E: "+IntegerToString(EtrendDown)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов F: "+IntegerToString(FtrendDown)+"\n");  
  FileWriteString(fileHandle,"     количество флэтов G: "+IntegerToString(GtrendDown)+"\n");  
  FileWriteString(fileHandle,"   }\n");     
  FileWriteString(fileHandle," }\n");   
 } 