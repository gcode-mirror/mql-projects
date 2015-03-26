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

input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
//input bool stepbypart = false; // 
input double   percentage_ATR = 1;   // процент АТР для появления нового экстремума
input double   difToTrend = 1.5;     // разница между экстремумами для появления тренда
input int      trStop    = 100;      // Trailing Stop
input int      trStep    = 100;      // Trailing Step
input int      minProfit = 250;      // минимальная прибыль
input double   sizeLow = 0.5;        // размер уменьшения лота 

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
datetime history_start;
int handle_19Lines;

// структура уровней
struct bufferLevel
 {
  double price[];            // цена уровня
  double atr[];              // ширина уровня
 };

double  currentPrice = 0;    // текущая цена
double  previewPrice = 0;    // предыдущая цена
bool    isLotClosed;         // закрылся ли объем позиции

// буферы уровней 
bufferLevel buffers[10];      // буфер уровней

int historyDepth;
int stoploss=0;

double lowVolumeValue;       // размер пониженного лота 
bool   flagNotLow = true;    // флаг НЕ уменьшения объема

SPositionInfo pos_info;
STrailing trailing;
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
   
    handle_19Lines = iCustom(symbol,timeframe,"NineteenLines");     
    if (handle_19Lines == INVALID_HANDLE)
    {
     Print("Не удалось получить хэндл NineteenLines");
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
   currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // сохраняем текущую цену 
   
   pos_info.tp = 0;
   pos_info.expiration = 0;
   pos_info.priceDifference = 0;
  
   trailing.trailingType = trailingType;
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trStop;
   trailing.trailingStep = trStep;
   trailing.handlePBI    = handle_PBI;     
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
  // сохраняем предыдущую цену
  previewPrice = currentPrice;
  // сохраняем текущую цену
  currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  
  // пытаемся прогрузить буферы уровней
  if (!UploadBuffers())
   return;  
  // если позиции нет
  if (ctm.GetPositionCount() == 0)
  {
   lot = aDeg[0];
   count = 1;
   rnd = (double)MathRand()/32767;
   if ( GreatDoubles(rnd,0.5,5) )
   {
    pos_info.type = OP_SELL;
    stoploss = CountStoploss(-1);
   } 
   else
   {
    pos_info.type = OP_BUY;
    stoploss = CountStoploss(1);
   }
   lowVolumeValue = lot - sizeLow;  // размер уменьешенного лота
   flagNotLow = true;
   pos_info.volume = lot;
   pos_info.sl = MathMax(stoploss, 0);
   ctm.OpenUniquePosition(symbol, timeframe, pos_info, trailing);
  }

  // если есть открытая позиция
  if (ctm.GetPositionCount() > 0)
  {
   // если можно 
   if (AllowToLowVolume() && flagNotLow)
    {  
     ctm.PositionChangeSize(symbol,lowVolumeValue);
     flagNotLow = false;
     Print("Уменьшили объем = ",DoubleToString(lowVolumeValue));
    }
   if (flagNotLow)
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
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=0;indexPer<5;indexPer++)
   {
    for (indexBuff=0;indexBuff<2;indexBuff++)
     {
      copiedPrice = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+4,  0,1,  buffers[indexLines].price);
      copiedATR   = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+5,  0,1,buffers[indexLines].atr);
      if (copiedPrice < 1 || copiedATR < 1)
       {
        Print("Не удалось прогрузить буферы индикатора NineTeenLines");
        return (false);
       }
      indexLines++;
     }
   }
  return(true);     
 }
 
bool AllowToLowVolume ()    // вычисляет, можно ли изменять объем сделки
 {
  if (previewPrice != 0)
   {
    // проходим по всем уровням и проверяем данное условие
    for (int index=0;index < 10; index++)
     {
      // если текущая цена находится внутри уровня или на его границе
      if ( GreatOrEqualDoubles(currentPrice,buffers[index].price[0]-buffers[index].atr[0]) &&
           LessOrEqualDoubles (currentPrice,buffers[index].price[0]+buffers[index].atr[0]) )  
        {
         // если предыдущая цена находилась вне уровня
         if ( GreatDoubles(previewPrice,buffers[index].price[0]+buffers[index].atr[0]) ||
              LessDoubles (previewPrice,buffers[index].price[0]-buffers[index].atr[0]) ) 
            {
             Print("Цена прошла через уровень в: ",TimeToString(TimeCurrent()));
             return (true);   // то значит можно закрывать часть объем
            }
        }         
     }
   }
   return (false);
 } 