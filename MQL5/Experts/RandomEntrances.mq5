//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций
#include <CExpertID.mqh> 

input int step = 100;
input int countSteps = 4;
input int volume = 5;
input double ko = 2;        // Коэффициент доливки

input bool allatonce = false;  // Открываемся сразу 5 лотом
input bool stepbystep = true;  // Долив равными долями
input bool degradelot = false; // Долив уменьш. долями 
input bool upgradelot = false; // Долив увелич. долями

input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_USUAL;
//input bool stepbypart = false; // 

string symbol;
ENUM_TIMEFRAMES timeframe;
int count;
double lot;
double rnd;
ENUM_TM_POSITION_TYPE opBuy, opSell;
int startVol, firstAdd, secondAdd, thirdAdd;
double aDeg[4];
double aUpg[4];
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
   MathSrand(TimeLocal());
   count = 0;
   history_start=TimeCurrent();     //--- запомним время запуска эксперта для получения торговой истории
   
   //handle_PBI = iCustom(symbol, timeframe, "PriceBasedIndicator", 1000, 2, 1.5, 12, 2, 1.5, 12);
   
   startVol = 100 / (1 + ko + ko*ko + ko*ko*ko);
   firstAdd = startVol * ko;
   secondAdd = firstAdd * ko;
   thirdAdd = 100 - secondAdd - firstAdd - startVol;
   
   aDeg[0] = volume * startVol * 0.01;
   aDeg[1] = volume * firstAdd * 0.01;
   aDeg[2] = volume * secondAdd * 0.01;
   aDeg[3] = volume * thirdAdd * 0.01;
   
   aUpg[0] = volume * thirdAdd * 0.01;
   aUpg[1] = volume * secondAdd * 0.01;
   aUpg[2] = volume * firstAdd * 0.01;
   aUpg[3] = volume * startVol * 0.01;
   
   for (int i = 0; i < 4; i++)
   {
    PrintFormat("aUpg[%d] = %.02f", i, aUpg[i]);
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
   if (allatonce) lot = 5;
   if (stepbystep) lot = 1;
   if (degradelot) lot = aDeg[0];
   if (upgradelot) lot = aUpg[0];
   count = 1;
   rnd = (double)MathRand()/32767;
   ENUM_TM_POSITION_TYPE operation = GreatDoubles(rnd, 0.5, 5) ? 1 : 0;
   ctm.OpenUniquePosition(symbol, timeframe, operation, lot, step, 0, trailingType, step, step, step);   
  }
   
  if (ctm.GetPositionCount() > 0)
  {
   profit = ctm.GetPositionPointsProfit(symbol);
   if (profit > step && count < countSteps) 
   {
    if (stepbystep)
    {
     lot = 1;
     ctm.PositionChangeSize(symbol, lot);
     count++;
    }
    if (degradelot)
    {
     lot = aDeg[count];
     ctm.PositionChangeSize(symbol, lot);
     count++;
    }
    if (upgradelot)
    {
     lot = aUpg[count];
     ctm.PositionChangeSize(symbol, lot);
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

