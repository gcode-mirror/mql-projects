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
CTradeManager    *ctm;                                                   // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара

// хэндлы индикаторов 
int handleSmydSTOC;                                                      // хэндл индикатора ShowMeYourDivSTOC
int handlePBIcur;                                                        // хэндл PriceBasedIndicator

// переменные эксперта
double currentPrice;                                                     // текущая цена
string symbol;                                                           // текущий символ
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора
double extrLeftTime[];                                                   // буфер для хранения времени левых экстремумов
double extrRightTime[];                                                  // буфер для хранения времени правых экстремумов
double pbiBuffer[];                                                      // буфер для хранения индикатора PriceBasedIndicator

int    stopLoss;                                                         // переменная для хранения действительного стоп лосса
int    copiedSmydSTOC;                                                   // переменная для проверки копирования буфера сигналов расхождения
int    copiedLeftExtr;                                                   // переменная для проверки копирования буфера левых экстремумов
int    copiedRightExtr;                                                  // переменная для проверки копирования буфера правых экстремумов
int    copiedPBI;                                                        // переменная для проверки копирования буфера PBI

// переменные для хранения минимума и максимума между экстремумами расхождения
double minBetweenExtrs;
double maxBetweenExtrs;

// переменные для хранения значений тейк профита и уровня лимит ордеров  
int    takeProfit;
int    limitOrderLevel;

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 handlePBIcur = iCustom(symbol, period, "PriceBasedIndicator",historyDepth, percentage_ATR_cur, difToTrend_cur);
 if ( handlePBIcur == INVALID_HANDLE)
  {
   Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл PriceBasedIndicator");
   return(INIT_FAILED);
  }
 // создаем хэндл индикатора ShowMeYourDivSTOC
 handleSmydSTOC = iCustom (symbol,period,"smydSTOC");   
 if ( handleSmydSTOC == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // освобождаем буферы
 ArrayFree(signalBuffer);
 ArrayFree(extrLeftTime);
 ArrayFree(extrRightTime);
 ArrayFree(pbiBuffer);   
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
 // выставляем переменные проверки копирования буферов сигналов и экстремумов в начальное значение
 copiedSmydSTOC  = -1;
 copiedLeftExtr  = -1;
 copiedRightExtr = -1;
 copiedPBI       = -1;
 // если сформирован новый бар
 if (isNewBar.isNewBar() > 0)
  {
   // пытаемся скопировать буферы 
   copiedSmydSTOC  = CopyBuffer(handleSmydSTOC,2,0,1,signalBuffer);
   copiedLeftExtr  = CopyBuffer(handleSmydSTOC,3,0,1,extrLeftTime);
   copiedRightExtr = CopyBuffer(handleSmydSTOC,4,0,1,extrRightTime);
   copiedPBI       = CopyBuffer(handlePBIcur,4,1,1,pbiBuffer);
   // проверка на успешность копирования всех буферов
   if (copiedSmydSTOC < 1 || copiedLeftExtr < 1 || copiedRightExtr < 1 || copiedPBI < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
       if (signalBuffer[0] != 0)
       { 
  Comment
   (
     "СИГНАЛ = ",signalBuffer[0],
     "\nДАТА ЛЕВОГО = ",TimeToString(datetime(extrLeftTime[0])),  
     "\nДАТА ПРАВОГО = ",TimeToString(datetime(extrRightTime[0]))      
   );
   }
   
   if ( signalBuffer[0] == _Buy)  // получили расхождение на покупку
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);    
      stopLoss = CountStoploss(1);
      // если тренд вниз
      if (pbiBuffer[0] == MOVE_TYPE_TREND_DOWN || pbiBuffer[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
       {
        // то мы просто открываемся на BUY немедленного исполнения
        ctm.OpenUniquePosition(symbol,period, OP_BUY, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);         
       }
      else
       {
        // иначе мы используем LIMIT ордера
        if ( GetMaxAndMinBetweenExtrs() )  // если удалось вычислить максимумы и минимумы
         {
          // вычисляем тейк профит 
          takeProfit      =  2*(maxBetweenExtrs-minBetweenExtrs)/_Point;
          //  уровень лимит ордера
          limitOrderLevel =  maxBetweenExtrs/_Point;
          // и открываем позицию лимит ордером на SELL
          ctm.OpenUniquePosition(symbol,period,OP_SELLLIMIT,Lot,stopLoss,takeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, limitOrderLevel);
         }
       }
    }  // END OF BUY
   if ( signalBuffer[0] == _Sell) // получили расхождение на продажу
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      if (pbiBuffer[0] == MOVE_TYPE_TREND_UP || pbiBuffer[0] == MOVE_TYPE_TREND_UP_FORBIDEN)
       {
        // то мы просто открываемся на SELL немедленного исполнения
        ctm.OpenUniquePosition(symbol,period, OP_SELL, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
       }
      else
       {
        // иначе мы использует LIMIT ордера
        if ( GetMaxAndMinBetweenExtrs() )  // если удалось вычислить максимумы и минимумы
         {
          // вычисляем тейк профит 
          takeProfit      =  2*(maxBetweenExtrs-minBetweenExtrs)/_Point;
          //  уровень лимит ордера
          limitOrderLevel =  minBetweenExtrs/_Point;
          // и открываем позицию лимит ордером на BUY
          ctm.OpenUniquePosition(symbol,period,OP_BUYLIMIT,Lot,stopLoss,takeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, limitOrderLevel);
         }        
       }
       
     }  // END OF SELL
     
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
 if (stoploss <= 0)
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stoploss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

// функция вычисляет минимум и максимум между двумя экстремумами
bool  GetMaxAndMinBetweenExtrs()
 {
  double tmpLow[];           // временный буфер низких цен
  double tmpHigh[];          // временный буфер высоких цен
  int    copiedHigh = -1;    // переменная для проверки копирования буфера высоких цен
  int    copiedLow  = -1;    // переменная для проверки копирования буфера низких цен
  int    n_bars;             // количество скопированных баров
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedHigh = CopyHigh(symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0],tmpLow);
    copiedLow  = CopyLow (symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0],tmpLow);    
    Sleep(100);
   }
  n_bars = Bars(symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0]);
  if (copiedHigh < n_bars || copiedLow < n_bars)
   {
    Print("Ошибка работы эксперта ONODERA. Не удалось скопировать буферы высоких и\или низких цен для поиска максимума и минимума");
    return (false);
   }
  // вычисляем максимум цены
  maxBetweenExtrs = ArrayMaximum(tmpHigh);
  // вычисляем минимум цены
  minBetweenExtrs = ArrayMinimum(tmpLow);
  return (true);
 }
 