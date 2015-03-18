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
input int price_diff = 50; // цена разницы

// необходимые переменные
int handleTrendLines; // хэндл идникатора трендовых линий
int handleATR; // хэндл ATR
int handleDE; // хэндл DrawExtremums
int currentMoveType=0; // текущее движение
int tradeSignal; // переменная для хранения сигнала открытия позиции
double curBid; // текущая цена Bid
double curAsk; // текущая цена Ask
double prevBid; // предыдущая цена Bid
double prevAsk; // предыдущая цена Ask
double price_difference;
string supportLineName; // имя линии поддержки
string resistanceLineName; // имя линии сопротивления
// объекты классов
CChartObjectTrend trend; // трендовая линия по верхним экстремумам
CTradeManager *ctm; // объект торгового класса
// структуры позиции и трейлинга
SPositionInfo pos_info; // структура информации о позиции
STrailing     trailing; // структура информации о трейлинге
//+------------------------------------------------------------------+
//| Системные функции робота TIHIRO 2                                |
//+------------------------------------------------------------------+
int OnInit()
  {    
   // сохраняем имена линий тренда
   supportLineName = _Symbol + "_" + PeriodToString(_Period) + "_supLine"; 
   resistanceLineName = _Symbol + "_" + PeriodToString(_Period) + "_resLine";      
   price_difference = price_diff * _Point;
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
   
   handleTrendLines = iCustom(_Symbol,_Period,"TrendLines");
   if (handleTrendLines == INVALID_HANDLE)
    {
     Print("Не удалось создать индикатор TrendLines");
     return (INIT_FAILED);
    }
   // пытаемся создать хэндл ATR
   handleATR = iATR(_Symbol,_Period, 25);
   if (handleATR == INVALID_HANDLE)
    {
     Print("Не удалось создать индикатор ATR");
     return (INIT_FAILED);
    }         
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("Не удалось создать торговую библиотеку");
     return (INIT_FAILED);
    }
   // получаем цены
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   prevBid = curBid;
   prevAsk = curAsk;
   // заполняем поля позиции
   pos_info.volume = lot;
   pos_info.expiration = 0;
   pos_info.tp = 0;     
   // заполняем 
  // trailing.trailingType = TRAILING_TYPE_ATR;
   trailing.trailingType = TRAILING_TYPE_USUAL;
   trailing.handleForTrailing = 0;
   //trailing.handleForTrailing = handleATR;   
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
   ctm.DoTrailing(); 
   // получаем текущее ценовое движение
   currentMoveType = GetMoveType();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   if (currentMoveType == 1)
    Comment("тренд вверх");
   if (currentMoveType == -1)
    Comment("тренд вниз");
   if (currentMoveType == 0)
    Comment("флэт");
  
   tradeSignal = SignalToOpenPosition();
   
   if (tradeSignal==1)
    {
     pos_info.type = OP_BUY;  
     pos_info.sl = CountStopLoss ();
     trailing.minProfit = pos_info.sl;
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
    }
   if (tradeSignal==-1)
    {
     pos_info.type = OP_SELL;  
     pos_info.sl = CountStopLoss ();
     trailing.minProfit = pos_info.sl;
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
    }    
   prevBid = curBid;
   prevAsk = curAsk;
  }
  
//+------------------------------------------------------------------+
//| Алгоритмические функции робота TIHIRO 2                          |
//+------------------------------------------------------------------+

// функция получения сигнала открытия позиции
int SignalToOpenPosition ()
 {
  double priceTrendLine;
  // если в данный момент - тренд вверх
  if (currentMoveType == 1)
   {
    priceTrendLine = ObjectGetValueByTime(0,supportLineName,TimeCurrent());
    // если тренд пробит снизу вверх
    if ( GreatDoubles(prevBid,priceTrendLine) && LessOrEqualDoubles(curBid,priceTrendLine) )
      return (1);     
   }
  // если в данный момент - тренд вниз
  if (currentMoveType == -1)
   {
    priceTrendLine = ObjectGetValueByTime(0,resistanceLineName,TimeCurrent());
    // если тренд пробит снизу вверх
    if ( LessDoubles(prevBid,priceTrendLine) && GreatOrEqualDoubles(curBid,priceTrendLine) )
      return (-1);     
   }     
  return (0);
 }

// функция определяет, какое сейчас направление ценового движения
int GetMoveType ()
 {
  color clrSup;
  color clrRes;
  clrSup = color(ObjectGetInteger(0,supportLineName,OBJPROP_COLOR));
  clrRes = color(ObjectGetInteger(0,resistanceLineName,OBJPROP_COLOR));
  if (clrSup == clrBlue && clrRes == clrBlue)
   return (1);
  if (clrSup == clrRed && clrRes == clrRed)
   return (-1);
  // иначе это флэт
  return (0);
 }

// функция вычисления стоп лосса
int CountStopLoss ()
 {
  // пока она выглядит так, но вскоре изменится
  double buffExtr[];
  double buffTime[];
  double curPrice;
  int buffInd;
  int timeInd;
  int bars = Bars(_Symbol,_Period);
  if (currentMoveType == 1)
   {
    buffInd = 1;
    timeInd = 5;
    curPrice = curBid;
   }
  if (currentMoveType == -1)
   {
    buffInd = 0;
    timeInd = 4;
    curPrice = curAsk;
   }
  for (int ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,buffInd,ind,1,buffExtr) < 1 || CopyBuffer(handleDE,timeInd,ind,1,buffTime) < 1) 
     {
      Sleep(100);
      continue;
     }
    if (buffExtr[0] != 0.0)
     {
       return (int(MathAbs(curPrice-buffExtr[0])/_Point));
     }
    ind++;
   } 
  return (0);
 }  