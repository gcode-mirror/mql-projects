//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций

#define DEPTH_PBI 100

input int step = 100;
input int countSteps = 4;
input int volume = 5;
input double ko = 2;        // ko=0-весь объем, ko=1-равные доли, ko>1-увелич.доли, k0<1-уменьш.доли 

input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_USUAL;
//input bool stepbypart = false; // 
input double   percentage_ATR_cur = 2;   
input double   difToTrend_cur = 1.5;
input int      ATR_ma_period_cur = 12;

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
   
   if (trailingType == TRAILING_TYPE_PBI)
   {
    handle_PBI = iCustom(symbol, timeframe, "PriceBasedIndicator", DEPTH_PBI, percentage_ATR_cur, difToTrend_cur);
    if(handle_PBI == INVALID_HANDLE)                                //проверяем наличие хендла индикатора
    {
     Print("Не удалось получить хендл Price Based Indicator");      //если хендл не получен, то выводим сообщение в лог об ошибке
    }
   }
   ArrayResize(aDeg, countSteps);
   ArrayResize(aKo, countSteps);
   
   double k = 0, sum = 0;
   for (int i = 0; i < countSteps; i++)
   {
    k = k + MathPow(ko, i);
   }
   aKo[0] = 100 / k;
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
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  ctm.OnTick();
  ctm.DoTrailing();
  if (ctm.GetPositionCount() == 0)
  {
   lot = aDeg[0];
   count = 1;
   rnd = (double)MathRand()/32767;
   ENUM_TM_POSITION_TYPE operation = GreatDoubles(rnd, 0.5, 5) ? OP_SELL : OP_BUY;
   ctm.OpenUniquePosition(symbol, timeframe, operation, lot, step, 0, trailingType, step, step, step, handle_PBI);   
  }
   
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

