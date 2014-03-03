//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций

input int step = 100;
input int countSteps = 4;

input bool allatonce = false;  // Открываемся сразу 5 лотом
input bool stepbystep = true;  // Долив равными долями
input bool degradelot = false; // Долив уменьш. долями 
input bool upgradelot = false; // Долив увелич. долями
//input bool stepbypart = false; // 

string symbol;
int count;
double rnd;
ENUM_TM_POSITION_TYPE opBuy, opSell;
double lot;
int profit;
CTradeManager ctm();
double aDeg[4] = {0.7, 0.5, 0.3, 0.1};
double aUpg[4] = {0.1, 0.3, 0.5, 0.7};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   MathSrand(TimeLocal());
   count = 0;
   //history_start=TimeCurrent();     //--- запомним время запуска эксперта для получения торговой истории
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
   if (ctm.GetPositionCount() == 0)
   {
    if (allatonce) lot = 5;
    if (stepbystep || degradelot) lot = 1;
    if (upgradelot) lot = 0.1;
    count = 0;
    rnd = (double)MathRand()/32767;
    ENUM_TM_POSITION_TYPE operation = GreatDoubles(rnd, 0.5, 5) ? 1 : 0;
    ctm.OpenUniquePosition(symbol, operation, lot, step, 0, step, step, step);
   }
   
   if (ctm.GetPositionCount() > 0)
   {
    profit = ctm.GetPositionPointsProfit(symbol);
    if (stepbystep)
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, 1);
      count++;
     }
    }
    if (degradelot) 
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, aDeg[count]);
      count++;
     }
    }
    if (upgradelot) 
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, aUpg[count]);
      count++;
     }
    }
    ctm.DoUsualTrailing();
   }
  }
//+------------------------------------------------------------------+
