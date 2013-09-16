//+------------------------------------------------------------------+
//| Пересечение двух МА: оптимизируем периоды                        |
//+------------------------------------------------------------------+


#include            <UGA\MATrainLib.mqh>
#include            <UGA\MustHaveLib.mqh>
#include            <TradeManager/TradeManager.mqh>

//---
input double        trainDD=0.5;   // Максимально возможная просадка баланса в тренировке
input double        maxDD=0.2;     // Просадка баланса, после которой сеть перетренируется
input uint          SlowPer=26;    // Период медленного EMA
input uint          FastPer=12;    // Период быстрого ЕМА
input int           TakeProfit=100;//take profit
input int           StopLoss=100; //stop loss
input double        orderVolume = 1;
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
//---
int                 MAlong,MAshort;              // МА-хэндлы
double              LongBuffer[],ShortBuffer[];  // Индикаторные буферы
string              sym = _Symbol;               //текущий символ
ENUM_TIMEFRAMES     timeFrame = _Period;     
CTradeManager       new_trade; //класс торговли 



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   tf=Period();
//--- для побарного тестирования...
   prevBT[0]=D'2001.01.01';
//... очень давно
   TimeToStruct(prevBT[0],prevT);
//--- глубина истории (задаем, так как оптимизируем на исторических данных)
   depth=10000;
//--- сколько за раз копируем (задаем, так как оптимизируем на исторических данных)
   count=2;
   traindd = trainDD;    
   
  // ArrayResize(LongBuffer,count);
  // ArrayResize(ShortBuffer,count);
  // ArrayInitialize(LongBuffer,0);
  // ArrayInitialize(ShortBuffer,0);
   
  trade.InitTradeBlock(_Symbol,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price);  //инициализируем торговый блок
      
//--- вызываем функцию генетической оптимизации нейросети
   GA();
//--- получаем оптимизированные параметры нейросети и других переменных
   GetTrainResults();
//--- получаем просадку по балансу
   InitRelDD();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    trade.DeinitTradeBlock();   //удаляем из памяти объект класса CrossEMA
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

      bool trig=false;
      new_trade.OnTick();
      my_signal =  trade.GetSignal(false); //получаем торговый сигнал
      
      if (my_signal != OP_UNKNOWN)      //если сигнал успешно получен
       {
        new_trade.OpenPosition(sym,my_signal,orderVolume,StopLoss,TakeProfit,0,0,0); //то открываем позицию      
        trig=true;
       }
       
       /*
        if(my_signal == OP_SELL)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
        if (my_signal == OP_BUY)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               ClosePosition();
               trig=true;
              }
           }
        } */
        
        
      if(trig==true)
        {
        //--- если просадка баланса превысила допустимую:
         if(GetRelDD()>maxDD) 
           {
            //--- вызываем функцию генетической оптимизации нейросети
            GA();
            //--- получаем оптимизированные параметры нейросети и других переменных
            GetTrainResults();
            //--- отсчет просадки будем теперь вести не от максимума баланса, а от текущего баланса
            maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
           }
        }
      my_signal = trade.GetSignal(false); //получаем торговый сигнал
      if (my_signal != OP_UNKNOWN)      //если сигнал успешно получен
       new_trade.OpenPosition(sym,my_signal,orderVolume,StopLoss,TakeProfit,0,0,0); //то открываем позицию      
      
     
  }
//+------------------------------------------------------------------+
