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
input double lot = 1;
input int historyDepth = 40;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_USUAL;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input int spread   = 30;
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

int  handlePBI;
double  high_buf[], low_buf[], close_buf[2];
ENUM_TM_POSITION_TYPE opBuy, opSell;
int priceDifference;

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;

SPositionInfo pos_info;
STrailing trailing;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start=TimeCurrent();     //--- запомним время запуска эксперта для получения торговой истории
   
   // если задан тип трейлинга PBI      
   if (trailingType == TRAILING_TYPE_PBI)
    {
     // создаем хэндл PBI
     handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
     if (handlePBI == INVALID_HANDLE)
      {
       Print("Ошибка инициализации эксперат Condom. Не удалось создать хэндл PriceBasedIndicator");
       return (INIT_FAILED);        
      }      
    }  
   pos_info.volume       = lot;
   pos_info.expiration   = 0;
   trailing.trailingType = trailingType;
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trailingStop;
   trailing.trailingStep = trailingStep;     
   trailing.handlePBI    = handlePBI; 
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
   // освобождаем хэндлы индикаторов 
   IndicatorRelease(handlePBI);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ctm.OnTick();
   ctm.DoTrailing();
   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errMACD = 0;
   bool openPos;    // флаг успешно открытой позиции
   static CisNewBar isNewBar(symbol, timeframe);
   
   if(isNewBar.isNewBar() > 0)
   {
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
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return;
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {  
     pos_info.type = opBuy;
     pos_info.sl = SL;
     pos_info.priceDifference = priceDifference;       
     openPos = ctm.OpenUniquePosition(symbol, timeframe, pos_info, trailing, spread);
     if (openPos)
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
     pos_info.type = opSell;
     pos_info.sl = SL;
     pos_info.priceDifference = priceDifference;      
     openPos = ctm.OpenUniquePosition(symbol, timeframe, pos_info, trailing, spread); 
     if (openPos)
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
   return;   
  }
//+------------------------------------------------------------------+

void OnTrade()
  {
   ctm.OnTrade(history_start);
  }

