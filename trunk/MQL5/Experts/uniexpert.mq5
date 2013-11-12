//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
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

enum USE_PENDING_ORDERS //режим вычислени€ priceDifference
 { 
  USE_LIMIT_ORDERS=0, //useLimitOrders = true
  USE_STOP_ORDERS,    //useStopOrders = true
  USE_NO_ORDERS       //оба равны false
 };

input TRADE_BLOCKS_TYPE TRADE_BLOCK = TB_RABBIT;    //торгова€ стратеги€
//общие параметры
sinput string main;                                   //базовые параметры

input int      TakeProfit=500;                        //take profit
input int      StopLoss=150;                          //stop loss
input double   _lot = 1;                              //размер лота
input int historyDepth = 40;                          //глубина истории
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;          //таймфрейм
input bool trailing = false;                          //трейлинг
input int minProfit = 250;                            //минимальный профит
input int trailingStop = 150;                         //трейлинг стоп
input int trailingStep = 5;                           //шаг трейлинга
input USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           //тип Price Difference                    
input int priceDifference = 50;                       // Price Difference

sinput string ema_param;                              //параметры CrossEMA

input ENUM_MA_METHOD MA_METHOD=MODE_EMA;              //режим EMA
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;   //примен€ема€ цена
input uint SlowPer=26;                                //период медленной EMA     
input uint FastPer=12;                                //период быстрой EMA

sinput string rabbit_param;                           //параметры  ролика

input double supremacyPercent = 0.2;                  // во сколько раз новый бар больше среднего 
input double profitPercent = 0.5;                     // сколько процентов от движени€ брать прибылью

sinput string condom_param;                           //параметры Condom

input bool tradeOnTrend = false;                      //торговл€ на тренде

string sym;
datetime history_start;
//int takeProfit;
int stopLoss;
ENUM_TM_POSITION_TYPE op_buy,op_sell; //торговые сигналы
ENUM_TM_POSITION_TYPE signal=OP_UNKNOWN; //торговые сигналы
double take_profit;

CTradeManager ctm();    //класс тогровых операций

CrossEMA  cross_ema;  //объ€вл€ем объект класса CrossEMA
FWRabbit  rabbit;     //объ€вл€ем объект класса FWRabbit
Condom    condom;     //объ€вл€ем объект класса Condom

int OnInit()
  {
   sym=Symbol();                 //сохраним текущий символ графика дл€ дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним врем€ запуска эксперта дл€ получени€ торговой истории
   ctm.Initialization();  //инициализирует торговую библиотеку
   stopLoss = StopLoss;
 //  takeProfit = TakeProfit;   
   
   switch (pending_orders_type)  //вычисление priceDifference
    {
     case USE_LIMIT_ORDERS: //useLimitsOrders = true;
      op_buy  = OP_BUYLIMIT;
      op_sell = OP_SELLLIMIT;
     break;
     case USE_STOP_ORDERS:
      op_buy  = OP_BUYSTOP;
      op_sell = OP_SELLSTOP;
     break;
     case USE_NO_ORDERS:
      op_buy  = OP_BUY;
      op_sell = OP_SELL;      
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
    return INIT_SUCCEEDED;
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
   //выбор торговой стратегии
   case TB_CROSSEMA: //пересечение EMA
    signal = cross_ema.GetSignal(false);//получаем торговый сигнал
    take_profit = TakeProfit;
   break;
   case TB_CONDOM:   //√андон
    signal = condom.GetSignal(false); //получаем торговый сигнал 
    take_profit = condom.GetTakeProfit();         
   break;
   case TB_RABBIT:   // ролик
    signal = rabbit.GetSignal(false); //получаем торговый сигнал   
    take_profit = rabbit.GetTakeProfit();      
   break; 
  }
  
  switch (signal)
  {
   case 1: //сигнал buy
    ctm.OpenPosition(sym,op_buy,_lot,stopLoss,take_profit,minProfit, trailingStop, trailingStep,priceDifference); //то открываем позицию на покупку
   break;
   case 2://сигнал sell
    ctm.OpenPosition(sym,op_sell,_lot,stopLoss,take_profit,minProfit, trailingStop, trailingStep,priceDifference); //то открываем позицию на продажу
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
  
