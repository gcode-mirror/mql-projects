//+------------------------------------------------------------------+
//|                                                     FlatStat.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Робот статистики по флэтам                                       |
//+------------------------------------------------------------------+
// библиотеки
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <CTrendChannel.mqh> // трендовый контейнер
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
// параметры
input double percent = 0.1; // процент
// базовые переменные
bool trendNow = false;
bool firstUploaded = false; // флаг загрузки истории Экстремумов
bool firstUploadedTrend = false; // флаг загрузки истории трендов
int  calcMode = 0;  // режим вычисления
int  flatType = 0;
int  trendType = 0;
int  countFlat = 0;
// хэндлы
int handleDE;
// счетчики ситуаций
int flat_a_up_tup = 0,flat_a_down_tup = 0; 
int flat_a_up_tdown = 0,flat_a_down_tdown = 0; 

int flat_b_up_tup = 0,flat_b_down_tup = 0; 
int flat_b_up_tdown = 0,flat_b_down_tdown = 0; 

int flat_c_up_tup = 0,flat_c_down_tup = 0; 
int flat_c_up_tdown = 0,flat_c_down_tdown = 0; 

int flat_d_up_tup = 0,flat_d_down_tup = 0; 
int flat_d_up_tdown = 0,flat_d_down_tdown = 0; 

int flat_e_up_tup = 0,flat_e_down_tup = 0; 
int flat_e_up_tdown = 0,flat_e_down_tdown = 0;   

// переменные для хранения инфы о флэтах
double extrUp0,extrUp1;
datetime timeUp0,timeUp1;
double extrDown0,extrDown1;
datetime timeDown0,timeDown1;
double H; // высота флэта
double top_point; // верхняя точка, которую нужно достичь
double bottom_point; // нижняя точка, которую нужно достичь
// объекты классов
CExtrContainer *container;
CTrendChannel *trend;
CChartObjectTrend flatLine; // объект класса флэтовой линии
CChartObjectHLine topLevel; // верхний уровень
CChartObjectHLine bottomLevel; // нижний уровень

int fileTestStat; // хэндл файла


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
    // создаем хэндл файла тестирования статистики прохождения уровней
    fileTestStat = FileOpen("FlatStat.txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileTestStat == INVALID_HANDLE) //не удалось открыть файл
     {
      Print("Не удалось создать файл тестирования статистики прохождения уровней");
      return (INIT_FAILED);
     }           
   // создаем объекты классов
   container = new CExtrContainer(handleDE,_Symbol,_Period);
   trend = new CTrendChannel(0,_Symbol,_Period,handleDE,percent);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   FileWriteString(fileTestStat,"тренд вверх: ");
   FileWriteString(fileTestStat,"флэт а: " + " верх: "+IntegerToString(flat_a_up_tup)+" низ: "+IntegerToString(flat_a_up_tdown)+"\n");
   FileWriteString(fileTestStat,"флэт b: " + " верх: "+IntegerToString(flat_b_up_tup)+" низ: "+IntegerToString(flat_b_up_tdown)+"\n");                                
   FileWriteString(fileTestStat,"флэт c: " + " верх: "+IntegerToString(flat_c_up_tup)+" низ: "+IntegerToString(flat_c_up_tdown)+"\n");
   FileWriteString(fileTestStat,"флэт d: " + " верх: "+IntegerToString(flat_d_up_tup)+" низ: "+IntegerToString(flat_d_up_tdown)+"\n");   
   FileWriteString(fileTestStat,"флэт e: " + " верх: "+IntegerToString(flat_e_up_tup)+" низ: "+IntegerToString(flat_e_up_tdown)+"\n");
   FileWriteString(fileTestStat,"тренд вниз: ");
   FileWriteString(fileTestStat,"флэт а: " + " верх: "+IntegerToString(flat_a_down_tup)+" низ: "+IntegerToString(flat_a_down_tdown)+"\n");
   FileWriteString(fileTestStat,"флэт b: " + " верх: "+IntegerToString(flat_b_down_tup)+" низ: "+IntegerToString(flat_b_down_tdown)+"\n");                                
   FileWriteString(fileTestStat,"флэт c: " + " верх: "+IntegerToString(flat_c_down_tup)+" низ: "+IntegerToString(flat_c_down_tdown)+"\n");
   FileWriteString(fileTestStat,"флэт d: " + " верх: "+IntegerToString(flat_d_down_tup)+" низ: "+IntegerToString(flat_d_down_tdown)+"\n");   
   FileWriteString(fileTestStat,"флэт e: " + " верх: "+IntegerToString(flat_e_down_tup)+" низ: "+IntegerToString(flat_e_down_tdown)+"\n");    
   FileClose(fileTestStat); 
   // удаляем объекты
   delete trend; 
   delete container;
  }

void OnTick()
  {
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
    
   
   Comment("mode = ",calcMode,
           "\n тренд = ",trendType,
           "\n флэт = ",flatType
          );
  }
  
// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   int newDirection;
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam);
   // если сейчас режим "пока не было тренда"
   if (calcMode == 0)
    { 
     trendNow = trend.IsTrendNow();
     // если сейчас таки тренд 
     if (trendNow)
       {
        // переходим в режим обработки флэтовых движений
        calcMode = 1;
        trendType = trend.GetTrendByIndex(0).GetDirection();
       }
    }
   // если сейчас режим "нашли тренд, нужно искать ближайший флэт"
   else if (calcMode == 1)
    {
     trendNow = trend.IsTrendNow();
     // если сейчас не тренд
     if (!trendNow)
      {
       // то значит сейчас флэт и мы переходим в режим обработки статистики
       calcMode = 2;
      }
    }
   // если сейчас режим "обрабатываем флэт"
   else if (calcMode == 2)
    {
     // загружаем последние экстремумы
     extrUp0 = container.GetExtrByIndex(1,EXTR_HIGH).price;
     extrUp1 = container.GetExtrByIndex(2,EXTR_HIGH).price;
     timeUp0 = container.GetExtrByIndex(1,EXTR_HIGH).time;
     timeUp1 = container.GetExtrByIndex(2,EXTR_HIGH).time;
     extrDown0 = container.GetExtrByIndex(1,EXTR_LOW).price;
     extrDown1 = container.GetExtrByIndex(2,EXTR_LOW).price;
     timeDown0 = container.GetExtrByIndex(1,EXTR_LOW).time;
     timeDown1 = container.GetExtrByIndex(2,EXTR_LOW).time;
     
     H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
     top_point = SymbolInfoDouble(_Symbol,SYMBOL_BID) + H*0.75;
     bottom_point = SymbolInfoDouble(_Symbol,SYMBOL_BID) - H*0.75;     
     // вычисляем тип флэта
     if (IsFlatA())
      flatType = 1;
     if (IsFlatB())
      flatType = 2;
     if (IsFlatC())
      flatType = 3;
     if (IsFlatD())
      flatType = 4;
     if (IsFlatE())
      flatType = 5;
     // если удалось вычислить флэт
     if (flatType != 0)
      {
       // переходим в режим подсчета статистики
       calcMode = 3;
       countFlat ++; // увеличиваем количество флэтов
       GenFlatName (); // отрисовываем флэт
      }                       
    }
   else if (calcMode == 3)
    {
      // если цена достигла верхнего уровня
      if ( GreatOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            flat_a_up_tup ++;
           if (trendType == -1)
            flat_a_up_tdown ++;
          break;
          case 2: 
           if (trendType == 1) 
            flat_b_up_tup ++;
           if (trendType == -1)
            flat_b_up_tdown ++;
          break;
          case 3: 
           if (trendType == 1) 
            flat_c_up_tup ++;
           if (trendType == -1)
            flat_c_up_tdown ++;
          break;
          case 4: 
           if (trendType == 1) 
            flat_d_up_tup ++;
           if (trendType == -1)
            flat_d_up_tdown ++;
          break;
          case 5: 
           if (trendType == 1) 
            flat_e_up_tup ++;
           if (trendType == -1)
            flat_e_up_tdown ++;
          break;                                        
         }    
        calcMode = 0; // снова возвращаемся в старый режим  
        topLevel.Delete();           
        bottomLevel.Delete();        
       }
      // если цена достигла нижнего уровня
      if ( LessOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),bottom_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            flat_a_down_tup ++;
           if (trendType == -1)
            flat_a_down_tdown ++;
          break;
          case 2: 
           if (trendType == 1) 
            flat_b_down_tup ++;
           if (trendType == -1)
            flat_b_down_tdown ++;
          break;
          case 3: 
           if (trendType == 1) 
            flat_c_down_tup ++;
           if (trendType == -1)
            flat_c_down_tdown ++;
          break;
          case 4: 
           if (trendType == 1) 
            flat_d_down_tup ++;
           if (trendType == -1)
            flat_d_down_tdown ++;
          break;
          case 5: 
           if (trendType == 1) 
            flat_e_down_tup ++;
           if (trendType == -1)
            flat_e_down_tdown ++;
          break;                                        
         }      
        calcMode = 0; // снова возвращаемся в старый режим
        topLevel.Delete();           
        bottomLevel.Delete();
       }       
    }
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
 
 // дополнительные функции
 void GenFlatName ()  // создает линии флэта
  {
   flatLine.Color(clrYellow);
   flatLine.Width(5);
   flatLine.Create(0, "flatUp_" + countFlat, 0, timeUp0, extrUp0, timeUp1, extrUp1); // верхняя линия  
   flatLine.Color(clrYellow);
   flatLine.Width(5);
   flatLine.Create(0,"flatDown_" + countFlat, 0, timeDown0, extrDown0, timeDown1, extrDown1); // нижняя линия
   
   topLevel.Delete();
   topLevel.Create(0, "topLevel", 0, top_point);
   bottomLevel.Delete();
   bottomLevel.Create(0, "bottomLevel", 0, bottom_point);   
   
  
  }