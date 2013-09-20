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
//+------------------------------------------------------------------+
//|Последний апдейт - 16.09.2013   
//|Добавлено перечисление для типа EMA                                  
//|Добавлен метод  UpdateHandle для редактирования хэндла EMA        
//|Добавлен метод загрузки буферов UploadBuffers 
//|Добавлен конструктор класса, в котором переворачиваются массивы                                     
//+------------------------------------------------------------------+ 
 enum CROSS_EMA_HANDLE //тип хэндла для CrossEMA
  {
   SLOW_EMA=0,
   FAST_EMA=1  
  };

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
   ENUM_MA_METHOD method;                                         //
   ENUM_APPLIED_PRICE applied_price;                              //
   CisNewBar newCisBar; 
   public:
   double takeProfit;                                             //тейк профит
   int priceDifference;                                           
   int InitTradeBlock(string _sym,
                      ENUM_TIMEFRAMES _timeFrame,
                      double _takeProfit,
                      uint FastPer, 
                      uint SlowPer,
                      ENUM_MA_METHOD _method,
                      ENUM_APPLIED_PRICE _applied_price);          //инициализирует торговый блок
   int DeinitTradeBlock();                                         //деинициализирует торговый блок
   int UpdateHandle(CROSS_EMA_HANDLE handle,uint period);          //изменяет параметры выбранной EMA на period. Если не успешно, то вернет false, а параметры не поменяет
   bool UploadBuffers(uint start=1);                                           //загружает буферы 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick,uint start=1);                 //получает торговый сигнал 
  // bool UpdateParam (string sym,ENUM_TIMEFRAMES timeframe);      //обновдяет параметры объекта
   CrossEMA ();   //конструктор класса CrossEMA           
  };
  
  
 int CrossEMA::InitTradeBlock(string _sym,
                              ENUM_TIMEFRAMES _timeFrame,
                              double _takeProfit,
                              uint FastPer, 
                              uint SlowPer,
                              ENUM_MA_METHOD _method,
                              ENUM_APPLIED_PRICE _applied_price)   //инициализирует торговый блок
  {
   
   if (SlowPer<=FastPer || FastPer<=3)
    {
     fast_per=12;
     slow_per=26;
     Print("Не правильно заданы периоды. По умолчанию slow=26, fast=12");
    }
   else
    {
     fast_per=FastPer;
     slow_per=SlowPer;
    } 
   sym             = _sym;
   timeFrame       = _timeFrame;
   method          = _method;
   applied_price   = _applied_price; 
   takeProfit      = _takeProfit;
   priceDifference = 0;
   ma_slow_handle=iMA(sym,timeFrame,slow_per,0,method,applied_price); //инициализация медленного индикатора
   if(ma_slow_handle<0)
    return INIT_FAILED;
   ma_fast_handle=iMA(sym,timeFrame,fast_per,0,method,applied_price); //инициализация быстрого индикатора
   if(ma_fast_handle<0)
    return INIT_FAILED;
   ma_ema3_handle=iMA(sym,timeFrame,3,0,method,applied_price); //инициализация индикатора EMA3
   if(ma_ema3_handle<0)
    return INIT_FAILED;    
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
  
 int CrossEMA::UpdateHandle(CROSS_EMA_HANDLE handle,uint period) //обновляет параметры хэндлов
   {
    switch (handle)  //выборка по хэндлу
     {
      case SLOW_EMA: //изменение параметров медленной EMA
       if (period > fast_per) 
        {
         slow_per = period;
         ma_slow_handle=iMA(sym,timeFrame,slow_per,0,method,applied_price); //инициализация медленного индикатора
         if(ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }
      break;
      case FAST_EMA: //изменение параметров быстрой EMA
       if (period < slow_per && period > 3) 
        {
         fast_per = period;
         ma_fast_handle=iMA(sym,timeFrame,fast_per,0,method,applied_price); //инициализация медленного индикатора
         if(ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }      
      break;
     }
     return INIT_FAILED;
   } 
   
 bool CrossEMA::UploadBuffers(uint start=1)                       //загружает буферы 
  {
     if(CopyBuffer(ma_slow_handle, 0, start, 2, ma_slow) <= 0 || 
      CopyBuffer(ma_fast_handle, 0, start, 2, ma_fast) <= 0 || 
      CopyBuffer(ma_ema3_handle, 0, start, 1, ma_ema3) <= 0 ||
      CopyClose(sym, 0, start, 1, close) <= 0 ||
      CopyTime(sym, 0, start, 1, date_buffer) <= 0) //копирование буферов
      return false;
     return true;
  }  

 ENUM_TM_POSITION_TYPE CrossEMA::GetSignal(bool ontick,uint start=1)  //получает торговый сингал
  {
   if ( newCisBar.isNewBar() > 0 || ontick)
   {
   if(!UploadBuffers()) //копирование буферов
     {
      return OP_UNKNOWN;  //неизвестный сигнал
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
   return OP_UNKNOWN; //признак неисполнения функции
  } 
  
  CrossEMA::CrossEMA(void)  //конструктор класса CrossEMA
   {
    ArraySetAsSeries(ma_fast, true); // разметка массивов в обратном порядке
    ArraySetAsSeries(ma_slow, true);     
   }