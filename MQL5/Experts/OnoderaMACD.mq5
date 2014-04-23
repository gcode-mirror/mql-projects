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

sinput string trailingStr                          = "";                 // ПАРАМЕТРЫ трейлинга
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // тип трейлинга
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // минимальная прибыль

// объекты
CTradeManager * ctm;                                                     // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара

// хэндлы индикаторов 
int handleSmydMACD;                                                      // хэндл индикатора ShowMeYourDivMACD
int handlePBIcur;

// переменные эксперта
int divSignal;                                                           // сигнал на расхождение
double currentPrice;                                                     // текущая цена
ENUM_TM_POSITION_TYPE opBuy,opSell;                                      // типы ордеров 
string symbol;
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора

int    stopLoss;                                                         // переменная для хранения действительного стоп лосса

int    copiedSmydMACD;                                                   // переменная для проверки копирования буфера сигналов расхождения

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 handlePBIcur = iCustom(symbol, period, "PriceBasedIndicator");
 // создаем хэндл индикатора ShowMeYourDivMACD
 handleSmydMACD = iCustom (symbol,period,"smydMACD");   
   
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

int countSell=0;
int countBuy =0;

void OnTick()
{
 ctm.OnTick();
 int stopLoss = 0;
 // выставляем переменную проверки копирования буфера сигналов в начальное значение
 copiedSmydMACD = -1;
 // если сформирован новый бар
 if (isNewBar.isNewBar() > 0)
  {
   copiedSmydMACD = CopyBuffer(handleSmydMACD,1,0,1,signalBuffer);

   if (copiedSmydMACD < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
   if ( signalBuffer[0] == _Buy)
        countBuy++;
   if ( signalBuffer[0] == _Sell)
        countSell++;
 
   if ( signalBuffer[0] == _Buy)  // получили расхождение на покупку
     { 
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      stopLoss = CountStoploss(1);
      ctm.OpenUniquePosition(symbol,period, opBuy, Lot, StopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
     }
   if ( signalBuffer[0] == _Sell) // получили расхождение на продажу
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      ctm.OpenUniquePosition(symbol,period, opSell, Lot, StopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
     }
   }  
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, 1000);
 
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
  copiedPBI = CopyBuffer(handlePBIcur, extrBufferNumber, 0,historyDepth, bufferStopLoss);
 }
 if (copiedPBI < 0)
 {
  PrintFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(false);
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
 
 if (stopLoss <= 0)
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}
