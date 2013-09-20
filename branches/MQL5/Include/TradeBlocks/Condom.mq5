//+------------------------------------------------------------------+
//|                                                       Condom.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CompareDoubles.mqh>
#include <TradeManager/TradeManagerEnums.mqh> 
#include <TradeManager/TradeManager.mqh> 
#include <Lib CisNewBar.mqh>

//+------------------------------------------------------------------+
//| Торговый класс Condom                                            |
//+------------------------------------------------------------------+

 class Condom //торговый класс Condom
  {
    private:
     //системные параметры
     bool waitForSell;
     bool waitForBuy;
     bool tradeOnTrend;
     double globalMax;
     double globalMin;  
     int historyDepth;                       //глубина истории
     string sym;                             //переменная для хранения символа
     ENUM_TIMEFRAMES timeFrame;              //таймфрейм
     MqlTick tick;   
     ENUM_TM_POSITION_TYPE opBuy,opSell;               //торговые сигналы 
     //параметры MACD
     int handleMACD;
     double MACD_buf[1], high_buf[], low_buf[], close_buf[2];   //буферы      
     int fastMACDPeriod;     //период быстрого MACD
     int slowMACDPeriod;     //период медленного MACD
     int signalPeriod;
     double levelMACD;     
    public:
     double takeProfit;
     int priceDifference;   
     //------------------
     int InitTradeBlock(string _sym,
                        ENUM_TIMEFRAMES _timeFrame,
                        double _takeProfit,
                        bool   _tradeOnTrend,                        
                        int    _fastMACDPeriod,
                        int _slowMACDPeriod,
                        int _signalPeriod,
                        double _levelMACD,
                        int _historyDepth,
                        bool useLimitOrders,
                        bool useStopOrders,
                        int limitPriceDifference,
                        int stopPriceDifference);       //метод инициализации торгового блока
     int DeinitTradeBlock();                             //метод деинициализации торгового блока
     bool UploadBuffers();                               //загружает буферы 
     ENUM_TM_POSITION_TYPE GetSignal (bool ontick);      //получает торговый сигнал     
       
  };
  
 int Condom::InitTradeBlock(string _sym,
                        ENUM_TIMEFRAMES _timeFrame,
                        double _takeProfit,
                        bool   _tradeOnTrend,
                        int    _fastMACDPeriod,
                        int _slowMACDPeriod,
                        int _signalPeriod,    
                        double _levelMACD,                    
                        int _historyDepth,
                        bool useLimitOrders,
                        bool useStopOrders,
                        int limitPriceDifference,
                        int stopPriceDifference)
   {
    sym          = _sym;
    timeFrame    = _timeFrame;
   // isNewBar.SetSymbol(sym);
   // isNewBar.SetPeriod(timeFrame);
    tradeOnTrend = _tradeOnTrend;   
    historyDepth = _historyDepth; 
    takeProfit   = _takeProfit;
    if (tradeOnTrend)
    {
     fastMACDPeriod = _fastMACDPeriod;     //период быстрого MACD
     slowMACDPeriod = _slowMACDPeriod;     //период медленного MACD
     signalPeriod   = _signalPeriod;       //период сигнала
     levelMACD      = _levelMACD;          //уровень MACD
     handleMACD = iMACD(sym, timeFrame, fastMACDPeriod, slowMACDPeriod, signalPeriod, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
     if(handleMACD == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
      {
       Print("Не удалось получить хендл MACD");               //если хендл не получен, то выводим сообщение в лог об ошибке
       return(-1);                                                  //завершаем работу с ошибкой
      }      
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
         
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   globalMax = 0;
   globalMin = 0;
   waitForSell = false;
   waitForBuy = false;
   
   return(0);      
    }
    
  int  Condom::DeinitTradeBlock(void)  //деинициализация торгового блока Condom
    {
     //высвобождаем массивы
     ArrayFree(low_buf);
     ArrayFree(high_buf);
     return 1;
    } 
    
  bool Condom::UploadBuffers(void)     //загружает буферы 
   {
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errMACD = 0;
   if (tradeOnTrend)
    {
     //копируем данные из индикаторного массива в динамический массив MACD_buf для дальнейшей работы с ними
     errMACD=CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     if(errMACD < 0)
     {
      Alert("Не удалось скопировать данные из индикаторного буфера"); 
      return false; 
     }
    } 
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow=CopyLow(sym, timeFrame, 2, historyDepth, low_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errHigh=CopyHigh(sym, timeFrame, 2, historyDepth, high_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errClose=CopyClose(sym, timeFrame, 1, 2, close_buf); // (0 - тек. бар, копируем 2 сформ. бара)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return false;                                                                  //и выходим из функции
    }  
    return true;
   }
    
  ENUM_TM_POSITION_TYPE Condom::GetSignal(bool ontick)  //получает торговый сигнал
   {
   CisNewBar isNewBar(sym, timeFrame);
    ENUM_TM_POSITION_TYPE order_type = OP_UNKNOWN;
     if(isNewBar.isNewBar() > 0)
       {       
       if (!UploadBuffers()) //если буферы не удалось скопировать
        return OP_UNKNOWN;
       
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
        if(tradeOnTrend)
          {
           if(GreatDoubles(MACD_buf[0], levelMACD) || LessDoubles (MACD_buf[0], -levelMACD))
             {
              return OP_UNKNOWN;
             }
          } 
         if(!SymbolInfoTick(sym,tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return OP_UNKNOWN;
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {
      waitForBuy = false;
      waitForSell = false;
      order_type = opBuy;    
    }
   } 

   if (waitForSell)
   { 
    if (LessDoubles(tick.bid, close_buf[0]) && LessDoubles(tick.bid, close_buf[1]))
    {
      waitForBuy = false;
      waitForSell = false;   
      order_type = opSell;        
    }
   }  
      
      return order_type;
   }