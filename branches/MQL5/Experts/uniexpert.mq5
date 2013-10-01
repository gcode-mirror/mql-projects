//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
#include<Trigger64/PositionSys.mqh>     //подключаем библиотеку дл€ работы с позици€ми
#include<Trigger64/SymbolSys.mqh>       //подключаем библиотеку дл€ работы с символом
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

enum USE_PRICE_DIFFERENCE //режим вычислени€ priceDifference
 { 
  USE_LIMIT_ORDERS=0, //useLimitOrders = true
  USE_STOP_ORDERS,    //useStopOrders = true
  USE_NO_ORDERS       //оба равны false
 };

input TRADE_BLOCKS_TYPE TRADE_BLOCK = TB_CROSSEMA;    //торгова€ стратеги€
//общие параметры
sinput string main;                                   //базовые параметры
input int      TakeProfit=500;                        //take profit
input int      StopLoss=150;                          //stop loss
input double   _lot = 1;                              //размер лота
input int historyDepth = 40;                          //глубина истории
input double supremacyPercent = 0.2;
input double profitPercent = 0.5;  
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;          //таймфрейм
input bool trailing = false;                          //трейлинг
input int minProfit = 250;                            //минимальный профит
input int trailingStop = 150;                         //трейлинг стоп
input int trailingStep = 5;                           //шаг трейлинга
input USE_PRICE_DIFFERENCE pride_diff_type;           //тип Price Difference                    
input int limitPriceDifference = 20;                  //Limit Price Difference
input int stopPriceDifference = 20;                   //Stop Price Difference
sinput string ema_param;                              //параметры CrossEMA
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;              //режим EMA
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;   //примен€ема€ цена
input uint SlowPer=26;                                //период медленной EMA     
input uint FastPer=12;                                //период быстрой EMA
sinput string macd_param;                             //параметры Price Based Indicator
input bool tradeOnTrend = false;                      //торговл€ на тренде
input int fastMACDPeriod = 12;                        
input int slowMACDPeriod = 26;                        
input int signalPeriod = 9;                           
input double levelMACD = 0.02;



string sym;
datetime history_start;
int takeProfit;
int stopLoss;
//ENUM_TM_POSITION_TYPE op_buy,op_sell; //торговые сигналы
ENUM_TM_POSITION_TYPE signal; //торговые сигналы
int priceDifference; 

CTradeManager ctm(true);    //класс тогровых операций

CrossEMA  cross_ema;  //объ€вл€ем объект класса CrossEMA
FWRabbit  rabbit;     //объ€вл€ем объект класса FWRabbit
Condom    condom;     //объ€вл€ем объект класса Condom

int OnInit()
  {
   sym=Symbol();                 //сохраним текущий символ графика дл€ дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним врем€ запуска эксперта дл€ получени€ торговой истории
   ctm.Initialization();  //инициализирует торговую библиотеку
   stopLoss = StopLoss;
   takeProfit = TakeProfit;   
   
   switch (pride_diff_type)  //вычисление priceDifference
    {
     case USE_LIMIT_ORDERS: //useLimitsOrders = true;
      priceDifference = limitPriceDifference;
     break;
     case USE_STOP_ORDERS:
      priceDifference = stopPriceDifference;     
     break;
     case USE_NO_ORDERS: 
      priceDifference = 0;
     break;
    }
             
   switch (TRADE_BLOCK)  //выбор 
   {
     case TB_CROSSEMA:
      return cross_ema.InitTradeBlock(sym,
                                      timeframe,
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
                                        historyDepth);  //инициализирует торговый блок кролика
     break;
     case TB_CONDOM:     
      return condom.InitTradeBlock(sym,
                                   timeframe,
                                   tradeOnTrend,
                                   historyDepth); //инициализирует торговый блок гандона
                                   
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
    ctm.OpenPosition(sym,signal,_lot,stopLoss,rabbit.GetTakeProfit(),0,0,0,priceDifference); //то открываем позицию
    break;
    case TB_RABBIT:
     signal = rabbit.GetSignal(false); //получаем торговый сигнал
         if (signal != OP_UNKNOWN)       //если сигнал успешно получен
          {
    ctm.OpenPosition(sym, signal, _lot, stopLoss, rabbit.GetTakeProfit(), minProfit, trailingStop, trailingStep, priceDifference); //то открываем позицию
          }
    break;
    case TB_CONDOM:
     signal = condom.GetSignal(false); //получаем торговый сигнал
         if (signal != OP_UNKNOWN)       //если сигнал успешно получен
    ctm.OpenPosition(sym,signal,_lot,stopLoss,condom.GetTakeProfit(),0,0,priceDifference); //то открываем позицию
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
  
