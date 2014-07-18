//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// подсключение библиотек 
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки
#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <CompareDoubles.mqh>                   // для проверки соотношения  цен
#include <Constants.mqh>                        // библиотека констант

#define ADD_TO_STOPPLOSS 50
// константы сигналов
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении MACD                          |
//+------------------------------------------------------------------+

// входные параметры
sinput string base_param                           = "";                 // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  int    StopLoss                             = 0;                  // Стоп Лосс
input  int    TakeProfit                           = 0;                  // Тейк Профит
input  double Lot                                  = 1;                  // Лот
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // Тип отложенного ордера                    
input  int    priceDifference                      = 50;                 // Price Difference
input  int    backlogValue                         = 2;                  // максимальное отставание сигнала расхождения

sinput string trailingStr                          = "";                 // ПАРАМЕТРЫ трейлинга
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // тип трейлинга
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // минимальная прибыль

sinput string PriceBasedIndicator                  = "";                 // ПАРАМЕТРЫ PBI
input double   percentage_ATR = 1;   // процент АТР для появления нового экстремума
input double   difToTrend = 1.5;     // разница между экстремумами для появления тренда

// объекты
CTradeManager * ctm;                                                     // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара

// хэндлы индикаторов 
int handleSmydMACD;                                                      // хэндл индикатора ShowMeYourDivMACD
int handle_PBI;

// переменные эксперта
int divSignal;                                                           // сигнал на расхождение
double currentPrice;                                                     // текущая цена
ENUM_TM_POSITION_TYPE opBuy,opSell;                                      // типы ордеров 
string symbol;
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора
double backlogBuffer[];                                                  // буфер для получения отставания сигнала от последнего экстремума

int    stopLoss;                                                         // переменная для хранения действительного стоп лосса
int    copiedSmydMACD;                                                   // переменная для проверки копирования буфера сигналов расхождения
int    copiedBacklog;                                                    // переменная для проверки копирования буфера отставания сигнала от последнего экстремума
bool   catchedDiv = false;                                               // флаг пойманного расхождения

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 if (trailingType == TRAILING_TYPE_PBI)
 {
  handle_PBI = iCustom(symbol, period, "PriceBasedIndicator", historyDepth, percentage_ATR, difToTrend);
  if(handle_PBI == INVALID_HANDLE)                                //проверяем наличие хендла индикатора
  {
   Print("Не удалось получить хендл Price Based Indicator");      //если хендл не получен, то выводим сообщение в лог об ошибке
  }
 }
 // создаем хэндл индикатора ShowMeYourDivMACD
 handleSmydMACD = iCustom (symbol,period,"smydMACD_modernized");   
   
 if ( handleSmydMACD == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл ShowMeYourDivMACD");
  return(INIT_FAILED);
 }
 // сохранение типов ордеров
 switch (pending_orders_type)  
 {
  case USE_LIMIT_ORDERS: 
   opBuy  = OP_BUYLIMIT;
   opSell = OP_SELLLIMIT;
   break;
  case USE_STOP_ORDERS:
   opBuy  = OP_BUYSTOP;
   opSell = OP_SELLSTOP;
   break;
  case USE_NO_ORDERS:
   opBuy  = OP_BUY;
   opSell = OP_SELL;      
   break;
 }          
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // удаляем объект класса TradeManager
 delete isNewBar;
 delete ctm;
 // удаляем индикатор 
 IndicatorRelease(handleSmydMACD);
}

void OnTick()
{
 ctm.OnTick();
 ctm.DoTrailing();
 // выставляем переменную проверки копирования буфера сигналов в начальное значение
 copiedSmydMACD = -1;
 copiedBacklog  = -1;
 // если сформирован новый бар
 if (isNewBar.isNewBar() > 0)
  catchedDiv = false;
 // {
   copiedSmydMACD = CopyBuffer(handleSmydMACD,1,0,1,signalBuffer);
   copiedBacklog  = CopyBuffer(handleSmydMACD,2,0,1,backlogBuffer);
   if (copiedSmydMACD < 1 || copiedBacklog < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
 
   if ( signalBuffer[0] == BUY && backlogBuffer[0] <= backlogValue && !catchedDiv)  // получили расхождение на покупку и отставание сигнала меньше или равно заданному числу
     { 
      catchedDiv = true;
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      stopLoss = CountStoploss(1);
      ctm.OpenUniquePosition(symbol,period, opBuy, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handle_PBI, priceDifference);        
     }
   if ( signalBuffer[0] == SELL && backlogBuffer[0] <= backlogValue && !catchedDiv) // получили расхождение на продажу и отставание сигнала меньше или равно заданному числу
     {
      catchedDiv = true;
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      ctm.OpenUniquePosition(symbol,period, opSell, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handle_PBI, priceDifference);        
     }
   //}  
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, historyDepth);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // Если point > 0 возьмем буфер с минимумами, иначе с максимумами
  priceAB = SymbolInfoDouble(symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,historyDepth, bufferStopLoss);
 }
 if (copiedPBI < historyDepth)
 {
  PrintFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 
 for(int i = 0; i < historyDepth; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 // на случай сбоя матрицы, в которой мы живем, а возможно и не живем
 // возможно всё вокруг - это лишь результат работы моего больного воображения
 // так или иначе, мы не можем исключать, что stopLoss может быть отрицательным числом
 // хотя гарантировать, что он будет положительным не из-за сбоя матрицы, мы опять таки не можем
 // к чему вообще вся эта дискуссия, пойду напьюсь ;) 
 if (stopLoss <= 0)  
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}
