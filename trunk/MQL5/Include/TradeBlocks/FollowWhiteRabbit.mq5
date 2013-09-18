#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Торговый класс Follow White Rabbit
//+------------------------------------------------------------------+
#include <TradeManager/TradeManagerEnums.mqh> 
#include <Lib CisNewBar.mqh>
#include <CompareDoubles.mqh>

 class FWRabbit  //класс Follow White Rabbit
  {
   private:
   //системные переменные
   string sym;                                       //переменная для хранения символа
   datetime history_start;
   double supremacyPercent;
   MqlTick tick;
   int historyDepth;                                //глубина истории
   //буферы
   double  high_buf[]; 
   double  low_buf[]; 
   double  close_buf[1]; 
   double  open_buf[1];
   double  takeProfit, stopLoss;
   ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
   int priceDifference;
   public:
   int InitTradeBlock(string _sym,
                      ENUM_TIMEFRAMES _timeFrame,
                      double _supremacyPercent,
                      int _historyDepth,
                      bool useLimitOrders,
                      bool useStopOrders);          //инициализирует торговый блок
   int DeinitTradeBlock();                                         //деинициализирует торговый блок
   bool UploadBuffers(uint start=1);                               //загружает буферы 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick,uint start=1);     //получает торговый сигнал 
   FWRabbit ();   //конструктор класса CrossEMA      
  };

int FWRabbit::InitTradeBlock(string _sym,
                             ENUM_TIMEFRAMES _timeFrame,
                             double _supremacyPercent,
                             int _historyDepth,
                             bool useLimitOrders,
                             bool useStopOrders)  //инициализация торгового блока
 {
   sym = _sym;                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   history_start = _timeFrame; //запомним время запуска эксперта для получения торговой истории
   supremacyPercent = _supremacyPercent;
   historyDepth     =  _historyDepth;
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
 }
 
int FWRabbit::DeinitTradeBlock(void)  //деинициализация торгового блока
 {
    // Освобождаем динамические массивы от данных
    ArrayFree(low_buf);
    ArrayFree(high_buf);
 } 

ENUM_TM_POSITION_TYPE FWRabbit::GetSignal(bool ontick,uint start=1)  //получает торговый сигнал
 {
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
    errLow   = CopyLow(my_symbol, timeframe, 1, historyDepth, low_buf);
    errHigh  = CopyHigh(my_symbol, timeframe, 1, historyDepth, high_buf);
    errClose = CopyClose(my_symbol, timeframe, 1, 1, close_buf);          
    errOpen  = CopyOpen(my_symbol, timeframe, 1, 1, open_buf);
    
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return(;                                                                                      //и выходим из функции
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
     int digits   = SymbolInfoInteger(my_symbol, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
     if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
     {
      return opSell;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     {   
      return opBuy;
     }
    }
   }
   
   if (trailing)
   {
    ctm.DoTrailing();
   }
   return;      
      
 }

