//+------------------------------------------------------------------+
//|                                                      TIHIRO2.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Робот для пробития трендовой линии между экстремумами            |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <TradeManager/TradeManager.mqh>  // торговая библиотека
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <SystemLib/IndicatorManager.mqh>  // библиотека по работе с индикаторами
#include <DrawExtremums/SExtremum.mqh> // структура экстремума
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <CLog.mqh>  // для ведения лога

// параметры робота
input double lot = 1.0; // лот
input int stop_loss = 300; // стоп лосс
input int take_profit = 300; // тейк профит

// необходимые переменные
int handleDE; // хэндл индикатора DrawExtremums
double curBid; // текущая цена Bid
double prevBid; // предыдущая цена Bid
// объекты классов
CChartObjectTrend trend; // трендовая линия по верхним экстремумам
CTradeManager *ctm; // объект торгового класса
// массивы экстремумов для отрисовки трендовых лучей
SExtremum extrHigh[2];  // два последних нижних экстремума
// структуры позиции и трейлинга
SPositionInfo pos_info; // структура информации о позиции
STrailing     trailing; // структура информации о трейлинге
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
   
   // если не удалось получить последние экстремумы
   if (!GetFirstTrend () )
    {
     Print("Не удалось прогрузить последние экстремумы для построения трендовых линий");
     return (INIT_FAILED); // то возвращаем нуль, чтобы попробовать в след. раз    
    }
   // создаем трендовые линии по последним экстремумам
   
   trend.Create(0,"TihiroTrend",0,datetime(extrHigh[1].time),extrHigh[1].price,datetime(extrHigh[0].time),extrHigh[0].price); 
   
   // устанавливаем свойства лучей
   ObjectSetInteger(0,"TihiroTrend",OBJPROP_RAY_RIGHT,1);
   // получаем цены
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   prevBid = curBid;
   // заполняем поля позиции
   pos_info.volume = 1.0;
   pos_info.expiration = 0;
   pos_info.sl = stop_loss;
   pos_info.tp = take_profit;     
   // заполняем 
   trailing.trailingType = TRAILING_TYPE_NONE;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {  
   // удаляем объекты
   delete ctm;
  }

void OnTick()
  {
   ctm.OnTick();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if (SignalToOpenPosition ())
    {
     pos_info.type = OP_BUY;  
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
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
   // если пришел новый верхний экстремум
   if (sparam == "EXTR_UP_FORMED")
    {
     // то обновляем линию тренда
     UpdateTrend(dparam,datetime(lparam));
     DragRay(lparam);
    } 
  }  
  
// дополнительные функции робота

bool GetFirstTrend () // функция получает первый тренд при запуске робота
 {
  double buffHigh[];
  double buffTime[];
  bool countExtr=false;
  int bars = Bars(_Symbol,_Period);
  for (int ind=1;ind<bars;)
   {
    // если не удалось прогрузить последние значения буферов
    if (CopyBuffer(handleDE,0,ind,1,buffHigh) < 1 || CopyBuffer(handleDE,4,ind,1,buffTime) < 1)
     {
      Sleep(100);
      continue;
     }    
    // если найден экстремум
    if (buffHigh[0] != 0)
     {
      // если это первый попавшийся на пути экстремум
      if (countExtr==false)
       {
        extrHigh[0].direction = 1;
        extrHigh[0].price = buffHigh[0];
        extrHigh[0].time = datetime(buffTime[0]);
        countExtr=true;
       }
      else
       {
        // если найденный экстремум выше первого
        if (GreatDoubles(buffHigh[0],extrHigh[0].price))
         {
          // то сохраняем второй экстремум и возвращаем true
          extrHigh[1].direction = 1;
          extrHigh[1].price = buffHigh[0];
          extrHigh[1].time = datetime(buffTime[0]);
          return (true);
         }
       }
       
     }
    ind++;
   }
  return(false);
 }
 
// функция обновления тренда (с приходом нового экстремума
void UpdateTrend (double price,datetime time)
 {
  // если новый экстремум ниже последнего
  if (LessDoubles(price,extrHigh[0].price))
   {
    // то перемещаем начало тренда на последний экстремум
    extrHigh[1] = extrHigh[0];
   }
  // если новый экстремум выше начала линии тренда
  if (GreatDoubles(price,extrHigh[1].price))
   {
    // снова вычисляем изначальный тренд
    GetFirstTrend();
   }
  else
   {
    // заменяем последний экстремум на новый 
    extrHigh[0].direction = 1;
    extrHigh[0].price = price;
    extrHigh[0].time = time;
   }
 }
 
// функция обновляет лучи
void DragRay (int type)
 {
  ObjectDelete(0,"TihiroTrend");
  trend.Create(0,"TihiroTrend",0,datetime(extrHigh[1].time),extrHigh[1].price,datetime(extrHigh[0].time),extrHigh[0].price);
  ObjectSetInteger(0,"TihiroTrend",OBJPROP_RAY_RIGHT,1);    
 } 
 
// функция получения сигнала открытия позиции
bool SignalToOpenPosition ()
 {
  double priceTrendLine = ObjectGetValueByTime(0,"TihiroTrend",TimeCurrent());
  // если тренд пробит снизу вверх
  if ( LessDoubles(prevBid,priceTrendLine) && GreatOrEqualDoubles(curBid,priceTrendLine) )
    return (true);     
  return (false);
 }