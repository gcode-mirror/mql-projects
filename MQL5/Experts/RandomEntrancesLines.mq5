//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций

#define ADD_TO_STOPPLOSS 50

input int step = 100;
input int countSteps = 4;
input int volume = 5;
input double ko = 2;        // ko=0-весь объем, ko=1-равные доли, ko>1-увелич.доли, k0<1-уменьш.доли 
input double levelsKo = 3;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
//input bool stepbypart = false; // 
input double   percentage_ATR = 1;   // процент АТР для появления нового экстремума
input double   difToTrend = 1.5;     // разница между экстремумами для появления тренда
input int      trStop    = 100;      // Trailing Stop
input int      trStep    = 100;      // Trailing Step
input int      minProfit = 250;      // минимальная прибыль


string symbol;
ENUM_TIMEFRAMES timeframe;
int count;
double lot;
double rnd;
ENUM_TM_POSITION_TYPE opBuy, opSell;
double aDeg[], aKo[];
int profit;
CTradeManager ctm();

int handle_PBI;
int handle_19Lines;
datetime history_start;

int historyDepth;
int stoploss=0;

// структура уровней
struct bufferLevel
 {
  double price[];
  double atr[];
 };

// буферы уровней 
bufferLevel buffers[20];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   timeframe = Period();
   MathSrand((int)TimeLocal());
   count = 0;
   history_start=TimeCurrent();     //--- запомним время запуска эксперта для получения торговой истории
   historyDepth = 1000;
   if (trailingType == TRAILING_TYPE_PBI)
   {
    handle_PBI = iCustom(symbol, timeframe, "PriceBasedIndicator", historyDepth, percentage_ATR, difToTrend);
    if(handle_PBI == INVALID_HANDLE)                                //проверяем наличие хендла индикатора
    {
     Print("Не удалось получить хендл Price Based Indicator");      //если хендл не получен, то выводим сообщение в лог об ошибке
    }
   }
   
   handle_19Lines = iCustom(symbol, timeframe, "NineteenLines");     
   if (handle_19Lines == INVALID_HANDLE)
    {
     PrintFormat("%s Не удалось получить хэндл NineteenLines", MakeFunctionPrefix(__FUNCTION__));
    }      
   
   ArrayResize(aDeg, countSteps);
   ArrayResize(aKo, countSteps);
   
   double k = 0, sum = 0;
   for (int i = 0; i < countSteps; i++)
   {
    k = k + MathPow(ko, i);
   }
   aKo[0] = 100 / k;
   
   sum = aKo[0];
   for (int i = 1; i < countSteps - 1; i++)
   {
    aKo[i] = aKo[i - 1] * ko;
    sum = sum + aKo[i];
   }
   aKo[countSteps - 1] = 100 - sum;
         
   for (int i = 0; i < countSteps; i++)
   {
    aDeg[i] = NormalizeDouble(volume * aKo[i] * 0.01, 2);
   }
        
   for (int i = 0; i < countSteps; i++)
   {
    PrintFormat("aDeg[%d] = %.02f", i, aDeg[i]);
   }
         
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // удаляем хэндл индикатора PBI
   IndicatorRelease(handle_PBI);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  ctm.OnTick();
  ctm.DoTrailing();
  
  if ( !UploadBuffers () )   // если не удалось прогрузить буферы индикатора NineTeenLines
    return;  
  
  // если позиции нет
  if (ctm.GetPositionCount() == 0)
  {
   lot = aDeg[0];
   count = 1;
   rnd = (double)MathRand()/32767;
   ENUM_TM_POSITION_TYPE operation;
   if ( GreatDoubles(rnd,0.5,5) )
   {
    Comment("СНИЗУ = ",DoubleToString(GetClosestLevel(-1))," СВЕРХУ = ",DoubleToString(GetClosestLevel(1)));
    if (levelsKo*GetClosestLevel(-1) <= GetClosestLevel(1) )
     return;   
    operation = OP_SELL;
    stoploss = CountStoploss(-1);
   } 
   else
   {
    Comment("СНИЗУ = ",DoubleToString(GetClosestLevel(-1))," СВЕРХУ = ",DoubleToString(GetClosestLevel(1)));   
    if (levelsKo*GetClosestLevel(1) <= GetClosestLevel(-1) )
     return;   
    operation = OP_BUY;
    stoploss = CountStoploss(1);
   }
   ctm.OpenUniquePosition(symbol, timeframe, operation, lot, MathMax(stoploss, 0), 0, trailingType,minProfit, trStop, trStep, handle_PBI);
  }

  // если есть открытая позиция
  if (ctm.GetPositionCount() > 0)
  {
   profit = ctm.GetPositionPointsProfit(symbol);
   if (profit > step && count < countSteps) 
   {
    lot = aDeg[count];
    if (lot > 0) ctm.PositionChangeSize(symbol, lot);
    count++;
   }
  }
 }

//+------------------------------------------------------------------+
void OnTrade()
  {
   ctm.OnTrade(history_start);
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
 // к чему вообще вся эта дискуссия, пойду напьюсь ;) 
 if (stopLoss <= 0)  
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}


bool UploadBuffers ()   // получает последние значения уровней
 {
  int copiedPrice;
  int copiedATR;
  for (int index=0;index<20;index++)
   {
    copiedPrice = CopyBuffer(handle_19Lines,index*2,  0,1,  buffers[index].price);
    copiedATR   = CopyBuffer(handle_19Lines,index*2+1,0,1,buffers[index].atr);
    if (copiedPrice < 1 || copiedATR < 1)
     {
      Print("Не удалось прогрузить буферы индикатора NineTeenLines");
      return (false);
     }
   }
  return(true);     
 }

// возвращает ближайший уровень к текущей цене
 double GetClosestLevel (int direction) 
  {
   double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double len = 0;  //расстояние до цены от уровня
   double tmpLen; 
   bool   foundLevel = false;  // флаг найденного первого уровня
   int    index;
   
   switch (direction)
    {
     case 1:  // ближний сверху
      for (index=0;index<20;index++)
       {
        // если уровень выше
        if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),cuPrice)  )
         {
          if (foundLevel)
           {
             tmpLen = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
             if (tmpLen < len)
              len = tmpLen;  
           }
          else
           {
            len = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
            foundLevel = true;
           }
         }
       }
     break;
     case -1: // ближний снизу
      for (index=0;index<20;index++)
       {
        // если уровень ниже
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),cuPrice)  )
          {
          if (foundLevel)
           {
             tmpLen = cuPrice - buffers[index].price[0] - buffers[index].atr[0] ;
             if (tmpLen < len)
              len = tmpLen;
           }
          else
           {
            len =  cuPrice - buffers[index].price[0] - buffers[index].atr[0];
            foundLevel = true;
           }
         }

       }     
       
      break;
   }
   return (len);
  }
  
  