//+------------------------------------------------------------------+
//|                                               StatisticRobot.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// сбор статистики пробития линий

#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <TradeManager/TradeManager.mqh>    // торговая библиотека

input double percent = 0.1; // процент 
input double lot = 1.0; // лот
input bool use = true; // условие
input bool half_stop = true;
input int n = 2; 


// структура точек для построения линии
struct pointLine
 {
  int direction;
  int bar;
  double price;
  datetime time;
 };
 
CTradeManager *ctm; 

int  handleDE;
bool switchTrend = false; // количество пробитий трендовой линии
bool switchHor = false; // количество пробитий горизонтальной линии
bool printed = false;
bool validTrend = false;
// счетчики 
int countTotal = 0; // всего экстремумов
int NoTrendNoHor = 0; 
int YesTrendNoHor = 0;
int NoTrendYesHor = 0;
int YesTrendYesHor = 0;
int trend = 0; // текущий тренд
double curBid; // текущая цена bid
double prevBid; // предыдущая цена bid
double priceTrend;
double horPrice;
pointLine extr[4]; // точки для отображения линий
CChartObjectTrend  trendLine; // объект класса трендовой линии
CChartObjectHLine  horLine; // объект класса горизонтальной линии

// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге

int OnInit()
 {
  ctm = new CTradeManager(); 
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
  // если удалось прогрузить последние экстремумы
  if (UploadExtremums())
  {
   trend = IsTrendNow();
   // сохраняем валидность тренда
   validTrend = IsValidState (trend);
   if (validTrend)
   {
    // строим линии 
    DrawLines ();    
   }
  }
  countTotal = 0;
   // сохраняем цены  
  curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  prevBid = curBid;
   // заполняем поля позиции
  pos_info.volume = lot;
  pos_info.expiration = 0;
   // заполняем 
  trailing.trailingType = TRAILING_TYPE_NONE;
  trailing.handleForTrailing = 0;     
  return(INIT_SUCCEEDED);
 }

void OnDeinit(const int reason)
  {
   delete ctm;
   IndicatorRelease(handleDE);
  }
  
  
void OnTick()
  {     
   ctm.OnTick();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
     // если движение валидно
     if (validTrend)
      {
       if (trend == 1)
        priceTrend = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
       if (trend == -1)
        priceTrend = ObjectGetValueByTime(0,"trendDown",TimeCurrent());          
       
       // если тренд вниз
       if (trend == -1)
        {
         // если цена пробила параллельную линию
         if (LessDoubles(curBid,priceTrend))
            {
             switchTrend = true; // то увеличиваем количество пробитий
            }
         // если цена пробила горизонтальную линию
         if (LessDoubles(curBid,horPrice))
            {
             switchHor = true;
            }
         }
       // если тренд вверх
       if (trend == 1)
        {
         // если цена пробила параллельную линию
         if (GreatDoubles(curBid,priceTrend))
            {
             switchTrend = true; // то увеличиваем количество пробитий
            }
         // если цена пробила горизонтальную линию
         if (GreatDoubles(curBid,horPrice))
            {
             switchHor = true;
            }  
        }
      } 
    
    prevBid = curBid;
  }

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   double price;
   if (sparam == "EXTR_DOWN_FORMED")
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     pos_info.type = OP_BUY; 
    }
   if (sparam == "EXTR_UP_FORMED")
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     pos_info.type = OP_SELL;
    }
   // пришло событие "сформировался новых экстремум"
   if (sparam == "EXTR_DOWN_FORMED" || sparam == "EXTR_UP_FORMED")
    {
     // удаляем линии с графика
     DeleteLines();
     // если движение было валидно
     if (validTrend)
      {
       // обрабатываем счетчики
       if (switchHor == false && switchTrend == false)
        NoTrendNoHor ++;
       if (switchHor == false && switchTrend == true)
        YesTrendNoHor ++;
       if (switchHor == true && switchTrend == false)
        NoTrendYesHor ++;
       if (switchHor == true && switchTrend == true)
        YesTrendYesHor ++;
       countTotal ++;
      }
     // сбрасываем счетчики пробоев
     switchHor = false;
     switchTrend = false;
     // получаем новые значение экстремумов и смещаем
     UploadExtremums ();
    // DragExtremums(direction,dparam,datetime(lparam));
     trend = IsTrendNow();
     // сохраняем валидность тренда
     validTrend = IsValidState (trend);
     if (validTrend)
      {
       if (half_stop)
        pos_info.sl = int(MathAbs((price-extr[0].price)/2)/_Point);
       else
       pos_info.sl = int(MathAbs(price-extr[0].price)/_Point);
       pos_info.tp = int(MathAbs(price-extr[1].price)/_Point);
       if (use)
        {
         if (pos_info.tp > pos_info.sl*n)
         ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
        }
       else
        {
          ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);        
        }
        
       // перерисовываем линии
       DrawLines ();
      }
    }

  } 

// функция закрузки экстремумов на OnInit
bool UploadExtremums ()
 {
  double extrHigh[];
  double extrLow[];
  double extrHighTime[];
  double extrLowTime[];
  int count=0; // счетчик экстремумов
  int bars = Bars(_Symbol,_Period);
  for (int ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,0,ind,1,extrHigh) < 1 || CopyBuffer(handleDE,1,ind,1,extrLow) < 1 ||
        CopyBuffer(handleDE,4,ind,1,extrHighTime) < 1 || CopyBuffer(handleDE,5,ind,1,extrLowTime) < 1 )
       {
        Sleep(100);
        continue;
       }
    // если найден новый эктсремум high
    if (extrHigh[0] != 0)
     {
      extr[count].price = extrHigh[0];
      extr[count].time = datetime(extrHighTime[0]);
      extr[count].direction = 1;
      extr[count].bar = ind;
      count++;
     }
    // если найдено все 3 экстремума
    if (count == 4)
     return (true);     
    // если найден новый эктсремум low
    if (extrLow[0] != 0)
     {
      extr[count].price = extrLow[0];
      extr[count].time = datetime(extrLowTime[0]);
      extr[count].direction = -1;
      extr[count].bar = ind;
      count++;
     }     
    // если найдено все 4 экстремума
    if (count == 4)
     return (true);
    ind++;
   }
  return(false);
 }
 
// функция смещает экстремумы в массиве
void DragExtremums (int direction,double price,datetime time)
 {
  for (int ind=3;ind>0;ind--)
   {
    extr[ind] = extr[ind-1];
   }
  extr[0].direction = direction;
  extr[0].price = price;
  extr[0].time = time;
 }

// функция удаляет линии с графика
void DeleteLines ()
 {
  ObjectDelete(0,"trendUp");
  ObjectDelete(0,"trendDown");
  ObjectDelete(0,"horLine");
 }

// возвращает тип движения (тренд вверх, тренд вниз или не тренд
int   IsTrendNow ()
 {
  // если тренд вверх
  if (GreatDoubles(extr[0].price,extr[2].price) && GreatDoubles(extr[1].price,extr[3].price) )
   return (1);
  // если тренд вниз
  if (LessDoubles(extr[0].price,extr[2].price) && LessDoubles(extr[1].price,extr[3].price) )
   return (-1);
  return (0);   
 }
 
// вернет true, если тренд валиден
bool  IsValidState (int trendType)
 {
  double H1,H2;
  double h1,h2;
  // вычисляем расстояния h1,h2
  h1 = MathAbs(extr[0].price - extr[2].price);
  h2 = MathAbs(extr[1].price - extr[3].price);
  // если тренд вверх
  if (trendType == 1)
   {
    // если последний экстремум - вниз
    if (extr[0].direction == -1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (true);
     }
   }
  // если тренд вниз
  if (trendType == -1)
   {
    // если  последний экстремум - вверх
    if (extr[0].direction == 1)
     {
     
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (true);
     }

   }   
  return (false);   
 }
 
 // функция отрисовывает линии по экстремумам  
void DrawLines ()
 {
    // то создаем линии по точкам
    if (extr[0].direction == 1)
     {
      trendLine.Create(0,"trendUp",0,extr[2].time,extr[2].price,extr[0].time,extr[0].price); // верхняя  линия
      ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);
      trendLine.Create(0,"trendDown",0,extr[3].time,extr[3].price,extr[1].time,extr[1].price); // нижняя  линия
      ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine",0,extr[0].price); // горизонтальная линия    
        horPrice = extr[0].price;    
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine",0,extr[1].price); // горизонтальная линия       
        horPrice = extr[1].price;         
       }        
     }
    // то создаем линии по точкам
    if (extr[0].direction == -1)
     {
      trendLine.Create(0,"trendDown",0,extr[2].time,extr[2].price,extr[0].time,extr[0].price); // нижняя  линия
      ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);
      trendLine.Create(0,"trendUp",0,extr[3].time,extr[3].price,extr[1].time,extr[1].price); // верхняя  линия
      ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine",0,extr[1].price); // горизонтальная линия     
        horPrice = extr[1].price;           
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine",0,extr[0].price); // горизонтальная линия      
        horPrice = extr[0].price;          
       }          
     }   
   
 }