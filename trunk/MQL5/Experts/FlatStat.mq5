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
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <CTrendChannel.mqh> // трендовый контейнер
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
// параметры
input double percent = 0.1; // процент
// базовые переменные
bool trendNow = false;
bool firstUploaded = false; // флаг загрузки истории трендов
int  calcMode = 0;  // режим вычисления
int  flatType = 0;
int  trendType = 0;
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
double extrDown0,extrDown1;
double H; // высота флэта
double top_point; // верхняя точка, которую нужно достичь
double bottom_point; // нижняя точка, которую нужно достичь
// объекты классов
CExtrContainer *container;
CTrendChannel *trend;

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
   // создаем объекты классов
   container = new CExtrContainer(handleDE,_Symbol,_Period);
   trend = new CTrendChannel(0,_Symbol,_Period,handleDE,percent);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
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
   int newDirection;
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam);
   // если сейчас режим "пока не было тренда"
   if (calcMode == 0)
    { 
     trendNow = trend.IsTrendNow();
     // если сейчас таки тренд 
     if (trendNow )
       {
        // переходим в режим обработки флэтовых движений
        calcMode = 1;
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
     extrUp0 = container.GetExtrByIndex(0,EXTR_HIGH).price;
     extrUp1 = container.GetExtrByIndex(1,EXTR_HIGH).price;
     extrDown0 = container.GetExtrByIndex(0,EXTR_LOW).price;
     extrDown1 = container.GetExtrByIndex(1,EXTR_LOW).price;
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
       }       
    }
  }   
  
// функции обработки типов флэтов


bool IsFlatA ()
 {
  //  если 
  if ( LessDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       GreatDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatB ()
 {
  //  если 
  if ( GreatDoubles (extrUp1-extrUp0,percent*H) &&
       LessDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

bool IsFlatC ()
 {
  //  если 
  if ( LessDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       LessDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatD ()
 {
  //  если 
  if ( GreatDoubles (extrUp1-extrUp0,percent*H) &&
       GreatDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatE ()
 {
  //  если 
  if ( GreatDoubles (extrUp0-extrUp1,percent*H) &&
       GreatDoubles (extrDown1 - extrDown0,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }    