//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
#include <Trade\Trade.mqh> //подключаем библиотеку для совершения торговых операций
#include<Trigger64/PositionSys.mqh>     //подключаем библиотеку для работы с позициями
#include<Trigger64/SymbolSys.mqh>       //подключаем библиотеку для работы с символом
#include<Trigger64/Graph.mqh>           //подключаем библиотеку отображения панели
//подключение торговых блоков
#include <TradeBlocks/CrossEMA.mq5>
#include <TradeBlocks/FollowWhiteRabbit.mq5>  
#include <TradeBlocks/Condom.mq5>
//подключаем перечисление торговых блоков
#include <TradeBlocks/TradeBlocksEnums.mqh>
//+------------------------------------------------------------------+
//| универсальный эксперт                                            |
//+------------------------------------------------------------------+
//параметр торгового блока
input TRADE_BLOCKS_TYPE TRADE_BLOCK = TB_CROSSEMA;
//общие параметры
input int      TakeProfit=500;//take profit
input int      StopLoss=150; //stop loss
input double   _lot = 1;
input ulong    magic = 111222;
input int historyDepth = 40;
input double supremacyPercent = 0.2;
input double profitPercent = 0.5; 
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool trailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
//дополнительные параметры
input bool useLimitOrders = false;
input int limitPriceDifference = 20;
input bool useStopOrders = false;
input int stopPriceDifference = 20;
//параметры CrossEMA
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
input uint SlowPer=26;             //для CrossEMA
input uint FastPer=12;             //для CrossEMA
//параметры MACD
input bool tradeOnTrend = false;
input int fastMACDPeriod = 12;
input int slowMACDPeriod = 26;
input int signalPeriod = 9;
input double levelMACD = 0.02;

string sym;
datetime history_start;
int takeProfit;
int stopLoss;
ENUM_TM_POSITION_TYPE signal;

CTradeManager ctm();    //класс тогровых операций
CrossEMA  cross_ema;  //объявляем объект класса CrossEMA
FWRabbit  rabbit;     //объявляем объект класса FWRabbit
Condom    condom;     //объявляем объект класса Condom

int OnInit()
  {
   sym=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
   ctm.Initialization();  //инициализирует торговую библиотеку
   stopLoss = StopLoss;
   takeProfit = TakeProfit;    
   switch (TRADE_BLOCK)  //выбор 
   {
     case TB_CROSSEMA:
      return cross_ema.InitTradeBlock(sym,
                                      timeframe,
                                      takeProfit,
                                      FastPer,
                                      SlowPer,
                                      MA_METHOD,
                                      applied_price);  //инициализирует торговый блок CrossEMA
     break;
     case TB_RABBIT:
      return rabbit.InitTradeBlock(sym,
                                        timeframe,
                                        supremacyPercent,
                                        profitPercent,
                                        historyDepth,
                                        useLimitOrders,
                                        useStopOrders,
                                        limitPriceDifference,
                                        stopPriceDifference);  //инициализирует торговый блок кролика
     break;
     case TB_CONDOM:     
      return condom.InitTradeBlock(sym,
                                   timeframe,
                                   takeProfit,
                                   tradeOnTrend,
                                   fastMACDPeriod,
                                   slowMACDPeriod,
                                   signalPeriod,
                                   levelMACD,
                                   historyDepth,
                                   useLimitOrders,
                                   useStopOrders,
                                   limitPriceDifference,
                                   stopPriceDifference); //инициализирует торговый блок гандона
                                   
     break;
   }                           
    return 1;
  }

void OnDeinit(const int reason)
  {
   ctm.Deinitialization();
   cross_ema.DeinitTradeBlock();
   rabbit.DeinitTradeBlock();   
   condom.DeinitTradeBlock();
  }

void OnTick()
  {   
   ctm.OnTick();

   
   switch (TRADE_BLOCK)
   {
    case TB_CROSSEMA:
     signal = cross_ema.GetSignal(false);//получаем торговый сигнал  
        if (signal == OP_SELL || signal == OP_BUY)      //если сигнал успешно получен
    ctm.OpenPosition(sym,signal,_lot,stopLoss,takeProfit,0,0,0,0); //то открываем позицию
    break;
    case TB_RABBIT:
     signal = rabbit.GetSignal(false); //получаем торговый сигнал
         if (signal != OP_UNKNOWN)       //если сигнал успешно получен
          {
    ctm.OpenPosition(sym, signal, _lot, stopLoss, rabbit.takeProfit, minProfit, trailingStop, trailingStep, rabbit.priceDifference); //то открываем позицию
          }
    break;
    case TB_CONDOM:
     signal = condom.GetSignal(false); //получаем торговый сигнал
         if (signal != OP_UNKNOWN)       //если сигнал успешно получен
    ctm.OpenPosition(sym,signal,_lot,stopLoss,condom.takeProfit,0,0,condom.priceDifference); //то открываем позицию
    break;

   }
      if (trailing)
   {
    ctm.DoTrailing();
   } 
  }

void OnTrade()
  {
   ctm.OnTrade(history_start);
  }