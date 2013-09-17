//+------------------------------------------------------------------+
//| Пересечение двух МА: оптимизируем периоды                        |
//+------------------------------------------------------------------+
#include            <GeneticPack/MATrainLib.mqh>
#include            <GeneticPack/MustHaveLib.mqh>
#include            <GeneticPack/UGAlib.mqh>
#include            <TradeBlocks/CrossEMA.mq5>
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
//int                 MAlong,MAshort;              // МА-хэндлы
//double              LongBuffer[],ShortBuffer[];  // Индикаторные буферы
string              sym = _Symbol;               //текущий символ
ENUM_TIMEFRAMES     timeFrame = _Period;     
CTradeManager       new_trade; //класс торговли 

//---

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  traindd = trainDD;
  trade_block.InitTradeBlock(sym,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price); //инициализируем торговый блок
   tf=Period();
//--- для побарного тестирования...
   prevBT[0]=D'2001.01.01';
//... очень давно
   TimeToStruct(prevBT[0],prevT);
//--- глубина истории (задаем, так как оптимизируем на исторических данных)
   depth=10000;
//--- сколько за раз копируем (задаем, так как оптимизируем на исторических данных)
   count=2;
   //ArrayResize(LongBuffer,count);
   //ArrayResize(ShortBuffer,count);
   //ArrayInitialize(LongBuffer,0);
   //ArrayInitialize(ShortBuffer,0);
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
  
  signal =  trade_block.GetSignal(false); //получаем торговый сигнал
   
   if(signal!=OP_IMPOSSIBLE)  
     {
      bool trig=false;
    //  CopyBuffer(MAshort,0,0,count,ShortBuffer);
    //  CopyBuffer(MAlong,0,0,count,LongBuffer);
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if (signal == OP_SELL)
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
    //  if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        if (signal == OP_BUY)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
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
     // CopyBuffer(MAshort,0,0,count,ShortBuffer);
     // CopyBuffer(MAlong,0,0,count,LongBuffer);
      trade_block.GetSignal(false); 
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if(signal == OP_SELL)
        {
         request.type=ORDER_TYPE_SELL;
         OpenPosition();
        }
    //  if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        if(signal == OP_BUY)
        {
         request.type=ORDER_TYPE_BUY;
         OpenPosition();
        }
     };
  }
//+------------------------------------------------------------------+
