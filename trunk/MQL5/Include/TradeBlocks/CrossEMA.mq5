//+------------------------------------------------------------------+
//|                                                     CrossEMA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManagerEnums.mqh> 
#include <Lib CisNewBar.mqh>
#include <CompareDoubles.mqh>

 class CrossEMA                                                   //класс CrossEMA
  {
   private:
   //буферы
   double ma_slow[];                                              //массив для медленного индикатора iMA 
   double ma_fast[];                                              //массив для быстрого индикатора iMA
   double ma_ema3[];                                              //массив для EMA(3) 
   double close[];                                                //массив для Close
   datetime date_buffer[];                                        //массив для даты
   //хэндлы индикаторов
   int ma_slow_handle;                                            //хэндл медленного индикатора
   int ma_fast_handle;                                            //хэндл быстрого индикатора
   int ma_ema3_handle;                                            //хэндл EMA(3) индикатора
   //периоды индиакторов  
   uint fast_per;                                                 //период быстрого индикатора
   uint slow_per;                                                 //период медленного индикатора
   string sym;                                                    //текущий символ
   ENUM_TIMEFRAMES timeFrame;                                     //таймфрейм
   CisNewBar newCisBar; 
   public:
   int InitTradeBlock(string sym,
                      ENUM_TIMEFRAMES timeFrame,
                      uint FastPer, 
                      uint SlowPer,
                      ENUM_MA_METHOD method,
                      ENUM_APPLIED_PRICE applied_price);          //инициализирует торговый блок
   int DeinitTradeBlock();          
   ENUM_TM_POSITION_TYPE GetSignal ();                            //получает торговый сигнал            
  };
  
 int CrossEMA::InitTradeBlock(string sym,
                              ENUM_TIMEFRAMES timeFrame,
                              uint FastPer, 
                              uint SlowPer,
                              ENUM_MA_METHOD method,
                              ENUM_APPLIED_PRICE applied_price)   //инициализирует торговый блок
  {
   if (SlowPer<=FastPer || FastPer<=3)
    {
     fast_per=12;
     slow_per=26;
     Print("Не правильно заданы периоды. По умолчанию slow=15, fast=9");
    }
   else
    {
     fast_per=FastPer;
     slow_per=SlowPer;
    } 
   ma_slow_handle=iMA(sym,timeFrame,slow_per,0,method,applied_price); //инициализация медленного индикатора
   if(ma_slow_handle<0)
    return INIT_FAILED;
   ma_fast_handle=iMA(sym,timeFrame,fast_per,0,method,applied_price); //инициализация быстрого индикатора
   if(ma_fast_handle<0)
    return INIT_FAILED;
   ma_ema3_handle=iMA(sym,timeFrame,3,0,method,applied_price); //инициализация индикатора EMA3
   if(ma_ema3_handle<0)
    return INIT_FAILED;  
   ArraySetAsSeries(ma_fast, true); // разметка массивов в обратном порядке
   ArraySetAsSeries(ma_slow, true);        
   return INIT_SUCCEEDED;
  }
  
 int CrossEMA::DeinitTradeBlock(void)  //деинициализация торгового блока
  {
   //удаление из памяти буферов 
   ArrayFree(ma_slow);
   ArrayFree(ma_fast);
   ArrayFree(ma_ema3);
   ArrayFree(close);
   ArrayFree(date_buffer); 
   return 1;   
  }

 ENUM_TM_POSITION_TYPE CrossEMA::GetSignal(void)  //получает торговый сингал
  {
   if ( newCisBar.isNewBar() > 0 )
   {
   if(CopyBuffer(ma_slow_handle, 0, 1, 2, ma_slow) <= 0 || 
      CopyBuffer(ma_fast_handle, 0, 1, 2, ma_fast) <= 0 || 
      CopyBuffer(ma_ema3_handle, 0, 1, 1, ma_ema3) <= 0 ||
      CopyClose(sym, 0, 1, 1, close) <= 0 ||
      CopyTime(sym, 0, 1, 1, date_buffer) <= 0) //копирование буферов
     {
      return OP_UNKNOWN;
     }  
   if(GreatDoubles(ma_slow[1],ma_fast[1]) && GreatDoubles(ma_fast[0],ma_slow[0]) && GreatDoubles(ma_ema3[0],close[0]))
    {      
      return OP_BUY;  //получен сигнал на покупку
    }
   if (GreatDoubles(ma_fast[1],ma_slow[1]) && GreatDoubles(ma_slow[0],ma_fast[0]) && GreatDoubles(close[0],ma_ema3[0])  ) 
    {
      return OP_SELL; //получен сигнал на продажу
    }
   }
   return OP_UNKNOWN;
  } 