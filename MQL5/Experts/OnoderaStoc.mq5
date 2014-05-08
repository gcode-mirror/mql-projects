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

#define ADD_TO_STOPPLOSS 0

//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении Стохастика                    |
//+------------------------------------------------------------------+

// входные параметры
sinput string base_param                           = "";                 // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  int    StopLoss                             = 0;                  // Стоп Лосс
input  int    TakeProfit                           = 0;                  // Тейк Профит
input  double Lot                                  = 1;                  // Лот
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // Тип отложенного ордера                    
input  int    priceDifference                      = 50;                 // Price Difference
input  int    lengthBetween2Div                    = 100;                // количество баров в истории для поиска последнего расхождения

sinput string trailingStr                          = "";                 // ПАРАМЕТРЫ трейлинга
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // тип трейлинга
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // минимальная прибыль

sinput string pbi_Str                              = "";                 // ПАРАМЕТРЫ PBI
input double  percentage_ATR_cur                   = 2;   
input double  difToTrend_cur                       = 1.5;
input int     ATR_ma_period_cur                    = 12;

// объекты
CTradeManager * ctm;                                                     // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара

// хэндлы индикаторов 
int handleSmydSTOC;                                                      // хэндл индикатора ShowMeYourDivSTOC
int handlePBIcur;                                                        // хэндл PriceBasedIndicator

// переменные эксперта
int divSignal;                                                           // сигнал на расхождение
int prevDivSignal;                                                       // предыдущий сигнал на расхождение
double currentPrice;                                                     // текущая цена
string symbol;                                                           // текущий символ
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора

int    stopLoss;                                                         // переменная для хранения действительного стоп лосса
int    copiedSmydSTOC;                                                   // переменная для проверки копирования буфера сигналов расхождения

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 handlePBIcur = iCustom(symbol, period, "PriceBasedIndicator",historyDepth, percentage_ATR_cur, difToTrend_cur);
 // создаем хэндл индикатора ShowMeYourDivSTOC
 handleSmydSTOC = iCustom (symbol,period,"smydSTOC");   
 if ( handleSmydSTOC == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }
 // получаем последнее расхождение на истории 
 prevDivSignal  =  FindLastDivType (handleSmydSTOC);      
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // удаляем объект класса TradeManager
 delete isNewBar;
 delete ctm;
 // удаляем индикаторы
 IndicatorRelease(handleSmydSTOC);
 IndicatorRelease(handlePBIcur);  
}

void OnTick()
{
 ctm.OnTick();
 ctm.DoTrailing();  
 // выставляем переменную проверки копирования буфера сигналов в начальное значение
 copiedSmydSTOC = -1;
 // если сформирован новый бар
 if (isNewBar.isNewBar() > 0)
  {
   copiedSmydSTOC = CopyBuffer(handleSmydSTOC,2,0,1,signalBuffer);

   if (copiedSmydSTOC < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
        
   if ( signalBuffer[0] == _Buy)  // получили расхождение на покупку
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      stopLoss = CountStoploss(1);
      // если предыдущий сигнал расхождения тоже BUY
      if (prevDivSignal == _Buy)
       {
        // то мы просто открываемся на BUY немедленного исполнения
        ctm.OpenUniquePosition(symbol,period, OP_BUY, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);         
       }
      else
       {
        // иначе мы используем LIMIT
        
       }
        // сохраняем текущее расхождение в качестве предыдущего
        prevDivSignal = signalBuffer[0];
     }
   if ( signalBuffer[0] == _Sell) // получили расхождение на продажу
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      ctm.OpenUniquePosition(symbol,period, opSell, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
      // сохраняем текущее расхождение в качестве предыдущего
      prevDivSignal = signalBuffer[0];   
     }
   }  
}
// функция вычисляет стоп лосс
int CountStoploss(int point)
{
 int stoploss = 0;
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
  copiedPBI = CopyBuffer(handlePBIcur, extrBufferNumber, 0,historyDepth, bufferStopLoss);
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
    stoploss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 // на случай сбоя матрицы, в которой мы живем, а возможно и не живем
 // возможно всё вокруг - это лишь результат работы моего больного воображения
 // так или иначе, мы не можем исключать, что stopLoss может быть отрицательным числом
 // хотя гарантировать, что он будет положительным не из-за сбоя матрицы, мы опять таки не можем
 // к чему вообще вся эта дискуссия, пойду напьюсь ;) 
 if (stoploss <= 0)
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stoploss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

// функция возвращает тип последнего расхождения до начала работы эксперта

int  FindLastDivType (int smydHandle)
 {
  int copiedBuf = -1;   // переменная для хранения количества скопированных данных из буфера
  double smydBuffer[];  // буфер временного хранения значений индикатора
  // пытаемся прогрузить буферы индикатора
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedBuf = CopyBuffer(smydHandle,2,0,lengthBetween2Div,smydBuffer);   
    Sleep(100);
   }
   if ( copiedBuf < lengthBetween2Div)
    {
     Print("Не удалось прогрузить буферы индикатора, поэтому последнее расхождение на истори найти не удалось");
     return (0);
    }
   // пройдем по циклу от конца истории и попытаемся найти последнее расхождение
   for (int index = lengthBetween2Div-1;index > 0; index++)
    {
      // если нашли отличное от нуля значение, значит нашли расхождение
      if (smydBuffer[index] != 0)
       return (smydBuffer[index]);
    }
   return (0);  // попали сюда, значит не нашли на истории ни одного расхождения
 }
 
// функция вычисляет Тейк Профит по двум экстремумам расхождения 
int  GetTakeProfitByExtremums ()
 {
 
 }
 
