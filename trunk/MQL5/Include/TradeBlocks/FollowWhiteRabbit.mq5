#property library
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Торговый класс Follow White Rabbit
//+------------------------------------------------------------------+
#include <TradeManager/TradeManagerEnums.mqh> 
#include <CIsNewBar.mqh>
#include <CompareDoubles.mqh>

 class FWRabbit  //класс Follow White Rabbit
  {
   private:
   //системные переменные
   string sym;                                       //переменная для хранения символа
   ENUM_TIMEFRAMES timeFrame;
   double supremacyPercent;
   double profitPercent;
   MqlTick tick;
   int historyDepth;                                //глубина истории
   //буферы
   double  high_buf[]; 
   double  low_buf[]; 
   double  close_buf[1]; 
   double  open_buf[1];
   ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
   public:
   double takeProfit;
   int priceDifference;
   int InitTradeBlock(string _sym,
                      ENUM_TIMEFRAMES _timeFrame,
                      double _supremacyPercent,
                      double _profitPercent,
                      int _historyDepth,
                      bool useLimitOrders,
                      bool useStopOrders,
                      int limitPriceDifference,
                      int stopPriceDifference);          //инициализирует торговый блок
   int DeinitTradeBlock();                                         //деинициализирует торговый блок
   bool UploadBuffers();                               //загружает буферы 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick);     //получает торговый сигнал 
  // FWRabbit ();   //конструктор класса Follow White Rabbit      
  };

int FWRabbit::InitTradeBlock(string _sym,
                             ENUM_TIMEFRAMES _timeFrame,
                             double _supremacyPercent,
                             double _profitPercent,
                             int _historyDepth,
                             bool useLimitOrders,
                             bool useStopOrders,
                             int limitPriceDifference,
                             int stopPriceDifference
                             )  //инициализация торгового блока
 {
   sym = _sym;                 //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   timeFrame = _timeFrame; //запомним время запуска эксперта для получения торговой истории
   supremacyPercent =  _supremacyPercent;
   profitPercent    =  _profitPercent;
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
   return(INIT_SUCCEEDED);
 }
 
int FWRabbit::DeinitTradeBlock(void)  //деинициализация торгового блока
 {
    // Освобождаем динамические массивы от данных
    ArrayFree(low_buf);
    ArrayFree(high_buf);
   return 1;
 } 
 
bool FWRabbit::UploadBuffers()    //загружает буферы
 {
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;
   errLow   = CopyLow(sym, timeFrame, 1, historyDepth, low_buf);
   errHigh  = CopyHigh(sym, timeFrame, 1, historyDepth, high_buf);
   errClose = CopyClose(sym, timeFrame, 1, 1, close_buf);          
   errOpen  = CopyOpen(sym, timeFrame, 1, 1, open_buf);
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //если есть ошибки
    {
     return false; //и выходим из функции 
    } 
  return true;
 }  

ENUM_TM_POSITION_TYPE FWRabbit::GetSignal(bool ontick)  //получает торговый сигнал
 {
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   long positionType;
   
   static CIsNewBar isNewBar;
   
   if ( isNewBar.isNewBar(sym, timeFrame) || ontick)
      
   {
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
  
    if ( !UploadBuffers () )  //проверка, загрузились ли буферы
     return OP_UNKNOWN;
     
    for(i = 0; i < historyDepth; i++)
    {
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;

    lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     double point = SymbolInfoDouble(sym, SYMBOL_POINT);
     int digits   = SymbolInfoInteger(sym, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
      
     if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
     {
      takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
      return opSell;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     {   
      takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
      return opBuy;
     }
 
    }
    
   }
   return OP_UNKNOWN;      
 }