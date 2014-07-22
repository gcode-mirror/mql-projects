//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh> //подключаем библиотеку для получения информации о позициях
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
#include <TradeManager\ReplayPosition.mqh>  

#define DEFAULT_LOT 1
#define ADD_TO_STOPPLOSS 50
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES timeframe = PERIOD_H1;
input int historyDepth = 40;
input double supremacyPercent = 0.2;
input double profitPercent = 0.5; 
input double levelsKo = 3;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           //Тип отложенного ордера                    
input int priceDifference = 50;                       // Price Difference
input bool replayPositions = true;
input int percentATRforReadyToReplay = 10;
input int percentATRforTrailing = 50;

string symbol;           //переменная для хранения символа
datetime history_start;

CTradeManager ctm;       //торговый класс
ReplayPosition *rp;      //класс отыгрыша убыточной позиции
MqlTick tick;

double takeProfit, stopLoss;
double high_buf[], low_buf[], close_buf[1], open_buf[1], pbi_buf[1];
ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
CPosition *pos;            // указатель на позицию

int handle_PBI;
int handle_19Lines;
struct bufferLevel         // структура уровней
{
 double price[];
 double atr[];
};
bufferLevel buffers[20];   // буферы уровней


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
   
   switch (pending_orders_type)  //вычисление priceDifference
   {
    case USE_LIMIT_ORDERS: //useLimitsOrders = true;
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
   
   rp = new ReplayPosition(symbol, timeframe, percentATRforReadyToReplay, percentATRforTrailing);
   handle_PBI     = iCustom(symbol, timeframe, "PriceBasedIndicator");
   handle_19Lines = iCustom(symbol, timeframe, "NineteenLines");     
   if (handle_PBI == INVALID_HANDLE || handle_19Lines == INVALID_HANDLE)
    {
     PrintFormat("%s Не удалось получить хэндл одного из вспомогательных индикаторов", MakeFunctionPrefix(__FUNCTION__));
    }       
   //устанавливаем индексацию для массивов ХХХ_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);
 
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete rp;
   // Освобождаем динамические массивы от данных
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ctm.OnTick();
   if (replayPositions)
     rp.CustomPosition();
   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;
   int errPBI = 0;

   
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   long positionType;

   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(symbol, timeframe))
   {
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow = CopyLow(symbol, timeframe, 1, historyDepth, low_buf);
    errHigh = CopyHigh(symbol, timeframe, 1, historyDepth, high_buf);
    errClose = CopyClose(symbol, timeframe, 1, 1, close_buf);          
    errOpen = CopyOpen(symbol, timeframe, 1, 1, open_buf);
    errPBI  = CopyBuffer(handle_PBI, 4, 1, 1, pbi_buf);
    UploadBuffers();
    
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                             //и выходим из функции
    }
    
    if(errPBI < 0)                                                           //если есть ошибки
    {
     Alert("Не удалось скопировать данные из вспомогательного индикатора");  //то выводим сообщение в лог об ошибке
     return;                                                                 //и выходим из функции
    }
    
    for(i = 0; i < historyDepth; i++)
    {
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;
    //lastBar = high_buf[i-1] - low_buf[i-1];
    lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
     int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
     if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
     {  
      pos_type = opSell;
      stopLoss = CountStoploss(-1);
      if(pbi_buf[0] == MOVE_TYPE_TREND_UP || pbi_buf[0] == MOVE_TYPE_TREND_UP_FORBIDEN ||
          GetClosestLevel(-1) <= levelsKo*GetClosestLevel(1))
       return;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     { 
      pos_type = opBuy;
      stopLoss = CountStoploss(1);
      if(pbi_buf[0] == MOVE_TYPE_TREND_DOWN || pbi_buf[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN ||
         GetClosestLevel(1) <= levelsKo*GetClosestLevel(-1))
       return;
     }
     takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
     
     ctm.OpenUniquePosition(symbol, timeframe, pos_type, DEFAULT_LOT, stopLoss, takeProfit, trailingType, minProfit, trailingStop, trailingStep, priceDifference);
    }
   }
 
   return;   
  }
//+------------------------------------------------------------------+
void OnTrade()
  {
   ctm.OnTrade();
   if(replayPositions)rp.OnTrade();
   if (history_start != TimeCurrent())
   {
    rp.setArrayToReplay(ctm.GetPositionHistory(history_start));
    history_start = TimeCurrent() + 1;
   }
  }
  
bool UploadBuffers()   // получает последние значения уровней
{
 int copiedPrice;
 int copiedATR;
 
 for (int i = 0; i < 20; i++)
 {
  copiedPrice = CopyBuffer(handle_19Lines,   i*2, 0, 1, buffers[i].price);
  copiedATR   = CopyBuffer(handle_19Lines, i*2+1, 0, 1, buffers[i].atr);
  if (copiedPrice < 1 || copiedATR < 1)
  {
   Print("Не удалось прогрузить буферы индикатора NineTeenLines");
   return (false);
  }
 }
 return(true);     
}

double GetClosestLevel(int direction)  // возвращает ближайший уровень к текущей цене
{
 double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double len = 0;  //расстояние до цены от уровня
 double tmpLen; 

 switch (direction)
 {
  case 1:  // ближний сверху
   for(int i = 0; i < 20; i++)
   {  // если уровень выше
    if (GreatDoubles((buffers[i].price[0]-buffers[i].atr[0]),cuPrice))
    {
     tmpLen = buffers[i].price[0] - buffers[i].atr[0] - cuPrice;
     if (tmpLen < len || len == 0)
      len = tmpLen;  
    }
   }
   break;
  case -1: // ближний снизу
   for(int j = 0; j < 20; j++)
   {  // если уровень ниже
    if ( LessDoubles((buffers[j].price[0]+buffers[j].atr[0]),cuPrice)  )
    {
     tmpLen = cuPrice - buffers[j].price[0] - buffers[j].atr[0] ;
     if (tmpLen < len || len == 0)
      len = tmpLen;
    }
   }
   break;
  }
 return (len);
}

// функция вычисляет стоп лосс
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
 // к чему вообще вся эта дискуссия, пойду напьюсь ;) (c) DMIRTRII
 if (stopLoss <= 0)  
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}