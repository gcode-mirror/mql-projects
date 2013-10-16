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

//#include <Trade\Trade.mqh> //подключаем библиотеку для совершения торговых операций
#include <Trade\PositionInfo.mqh> //подключаем библиотеку для получения информации о позициях
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
#include <TradeManager\ReplayPosition.mqh>  
#include <Graph\Graph.mqh>
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int SL = 150;
input double _lot = 1;
input int historyDepth = 40;
input double supremacyPercent = 0.2;
input double profitPercent = 0.5; 
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool trailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;

input bool useLimitOrders = false;
input int limitPriceDifference = 150;
input bool useStopOrders = false;
input int stopPriceDifference = 150;

string my_symbol;                                       //переменная для хранения символа
datetime history_start;

CTradeManager ctm(true);  //торговый класс
ReplayPosition rp;        //класс отыгрыша убыточной позиции
MqlTick tick;

double takeProfit, stopLoss;
double high_buf[], low_buf[], close_buf[1], open_buf[1];
ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
int priceDifference;
CPosition * pos;   //указатель на позицию

//GraphModule  graphModule;   //графический модуль

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
             
   my_symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
   
   ctm.Initialization();
   if (useLimitOrders)
   {
    opBuy = OP_BUYLIMIT;
    opSell = OP_SELLLIMIT;
    priceDifference = limitPriceDifference;
   }
   else if (useStopOrders)
        {
         opBuy = OP_BUYSTOP;
         opSell = OP_SELLSTOP;
         priceDifference = stopPriceDifference;
        }
        else
        {
         opBuy = OP_BUY;
         opSell = OP_SELL;
         priceDifference = 0;
        }
        
   //устанавливаем индексацию для массивов ХХХ_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);
   ctm.LoadHistoryFromFile(); //загружаем историю позиций из файла
   ctm.ZeroParam();  //обнуляем все параметры бэктест
   ctm.GetNTrades(); //проверяем количество трейдов в истории
   ctm.GetNWinLoseTrades(); //проверяем количество трейдов выйгрышных и убыточных
   ctm.GetProfitTradesPer(); //процент выйгрышных по отношению ко всему
   ctm.GetMaxWinTrade();  //получаем максимальный выйгрышный трейд
   ctm.GetMaxLoseTrade();  //получаем максимальный выйгрышный трейд  
   ctm.GetMedLoseTrade();  //получаем среднее значение убытка 
   ctm.GetMaxWinTradesN();  //получаем максимальное количество подряд идущих выйгрышных трейдов
   //Comment("Кол-во трейдов = ",ctm.tmpParam.nTrades);
   //Comment("кол-во выйгрышных и убыточных =  ",ctm.tmpParam.nWinTrades," | ",ctm.tmpParam.nLoseTrades); //отображаем на графике
   Comment("Процент выйгр. ко всем = ",ctm.tmpParam.profitTradesPer);
   //Comment("Максимальный профит = ",ctm.tmpParam.maxWinTrade);
   //Comment("Максимальный убыток = ",ctm.tmpParam.maxLoseTrade);
   //Comment("Средний убыток = ",ctm.tmpParam.medLoseTrade);
   //Comment("Макс. = ",ctm.tmpParam.maxWinTradesN);
   //LoadHistoryFromFile()
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   
   ctm.Deinitialization();
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
   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;

   
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   long positionType;

   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(my_symbol, timeframe))
   {
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow = CopyLow(my_symbol, timeframe, 1, historyDepth, low_buf);
    errHigh = CopyHigh(my_symbol, timeframe, 1, historyDepth, high_buf);
    errClose = CopyClose(my_symbol, timeframe, 1, 1, close_buf);          
    errOpen = CopyOpen(my_symbol, timeframe, 1, 1, open_buf);
    
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                                      //и выходим из функции
    }
    
    for(i = 0; i < historyDepth; i++)
    {
     //Print("high_buf[",i,"] = ", NormalizeDouble(high_buf[i],8), " low_buf[",i,"] = ", NormalizeDouble(low_buf[i],8));
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;
    //lastBar = high_buf[i-1] - low_buf[i-1];
    lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     //PrintFormat("last bar = %.08f avg Bar = %.08f", NormalizeDouble(lastBar,8), NormalizeDouble(avgBar,8));
     double point = SymbolInfoDouble(my_symbol, SYMBOL_POINT);
     int digits = SymbolInfoInteger(my_symbol, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
     if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
     {
      pos_type = opSell;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     {
      pos_type = opBuy;
     }
     takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
     //PrintFormat("(open-close) = %.05f, vol = %.05f, (1+profitpercent) = %.02f, takeprofit = %.01f"
     //           , MathAbs(open_buf[0] - close_buf[0]), vol, (1+profitPercent), takeProfit);
     ctm.OpenUniquePosition(my_symbol, pos_type, _lot, SL, takeProfit, minProfit, trailingStop, trailingStep, priceDifference);
    }
   }
   
   
   pos = ctm.GetLastClosedPosition(); //получаем последнюю закрытую позицию
   if (pos != NULL)  //если позиция существует
    {
     if (pos.getPosProfit() < 0)  //если позиция убыточная
      {
        rp.AddToArray(pos); //тогда добавляем позицию в массив ожидания
      }
      ctm.DeleteLastPosition();  //удаляем последнюю закрытую позицию
    }
    
   uint index;
   //проходим по циклу, пока не переберем все позиции, готовые на отыгрыш
   while (!index = rp.CustomPosition())>0)
    {
      pos = rp.GetPosition(index);
      pos.getPositionPrice();
     ctm.OpenPosition(my_symbol, pos.getType(), _lot, SL, , minProfit, trailingStop, trailingStep, priceDifference); 
      rp.DeletePosition(index); //удаляем позицию из очереди ожидания отыгрыша
      
      
      
    }
   
   if (trailing)
   {
    ctm.DoTrailing();
   }
   
   
   
   return;   
  }
//+------------------------------------------------------------------+

void OnTrade()
  {
   
   ctm.OnTrade();
  }
