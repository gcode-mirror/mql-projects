//+------------------------------------------------------------------+
//|                                                       condom.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include <TradeManager\TradeManager.mqh> //подключаем библиотеку для совершения торговых операций
#include <CLog.mqh>
//#include <Graph\Graph.mqh>
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
//input ulong _magic = 1122;
input int SL = 150;
input int TP = 500;
input double _lot = 1;
input int historyDepth = 40;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool usualTrailing = true;
input bool losslessTrailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input bool tradeOnTrend = false;
input int fastMACDPeriod = 12;
input int slowMACDPeriod = 26;
input int signalPeriod = 9;
input double levelMACD = 0.02;

input bool useLimitOrders = false;
input int limitPriceDifference = 20;
input bool useStopOrders = false;
input int stopPriceDifference = 20;

string symbol;                               //переменная для хранения символа
datetime history_start;

CTradeManager ctm();
MqlTick tick;

int handleMACD;
double MACD_buf[1], high_buf[], low_buf[], close_buf[2];
ENUM_TM_POSITION_TYPE opBuy, opSell;
int priceDifference;

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории
   
   if (usualTrailing && losslessTrailing)
   {
    PrintFormat("Должен быть выбран только один тип трейлинга");
    return(INIT_FAILED);
   }

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
   
   if (tradeOnTrend)
   {
    handleMACD = iMACD(symbol, timeframe, fastMACDPeriod, slowMACDPeriod, signalPeriod, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
    if(handleMACD == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
    {
     Print("Не удалось получить хендл MACD");               //если хендл не получен, то выводим сообщение в лог об ошибке
     return(-1);                                                  //завершаем работу с ошибкой
    }
   }

   //устанавливаем индексацию для массивов ХХХ_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   globalMax = 0;
   globalMin = 0;
   waitForSell = false;
   waitForBuy = false;
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
   int errMACD = 0;
   
   static CisNewBar isNewBar(symbol, timeframe);
   
   if(isNewBar.isNewBar() > 0)
   {
    if (tradeOnTrend)
    {
     //копируем данные из индикаторного массива в динамический массив MACD_buf для дальнейшей работы с ними
     errMACD=CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     if(errMACD < 0)
     {
      Alert("Не удалось скопировать данные из индикаторного буфера"); 
      return; 
     }
    } 
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow=CopyLow(symbol, timeframe, 2, historyDepth, low_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errHigh=CopyHigh(symbol, timeframe, 2, historyDepth, high_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errClose=CopyClose(symbol, timeframe, 1, 2, close_buf); // (0 - тек. бар, копируем 2 сформ. бара)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                  //и выходим из функции
    }

    globalMax = high_buf[ArrayMaximum(high_buf)];
    globalMin = low_buf[ArrayMinimum(low_buf)];
    
    if(LessDoubles(close_buf[1], globalMin)) // Последний Close(0 - старше, 1 - моложе, т.е НЕ как в таймсерии) ниже глобального минимума
    {
     waitForSell = false;
     waitForBuy = true;
    }
    
    if(GreatDoubles(close_buf[1], globalMax)) // Последний Close(0 - старше, 1 - моложе, т.е НЕ как в таймсерии) выше глобального максимума
    {
     waitForBuy = false;
     waitForSell = true;
    }
   }
   
   if (tradeOnTrend)
   {
    if (GreatDoubles(MACD_buf[0], levelMACD) || LessDoubles (MACD_buf[0], -levelMACD))
    {
     if (usualTrailing)
     {
      ctm.DoUsualTrailing();
     }
     if (losslessTrailing)
     {
      ctm.DoLosslessTrailing();
     }
     return;
    }
   }
      
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return;
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {
     if (ctm.OpenUniquePosition(symbol, opBuy, _lot, SL, TP, minProfit, trailingStop, trailingStep, priceDifference))
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   } 

   if (waitForSell)
   { 
    if (LessDoubles(tick.bid, close_buf[0]) && LessDoubles(tick.bid, close_buf[1]))
    {
     if (ctm.OpenUniquePosition(symbol, opSell, _lot, SL, TP, minProfit, trailingStop, trailingStep, priceDifference))
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
   if (usualTrailing)
   {
    ctm.DoUsualTrailing();
   }
   if (losslessTrailing)
   {
    ctm.DoLosslessTrailing();
   }
   return;   
  }
//+------------------------------------------------------------------+

void OnTrade()
  {
   ctm.OnTrade(history_start);
  }

