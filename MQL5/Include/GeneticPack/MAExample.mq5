//+------------------------------------------------------------------+
//| Пересечение двух МА: оптимизируем периоды                        |
//+------------------------------------------------------------------+
#include            "MATrainLib.mqh"
#include            "MustHaveLib.mqh"
//---
input double        trainDD=0.5;   // Максимально возможная просадка баланса в тренировке
input double        maxDD=0.2;     // Просадка баланса, после которой сеть перетренируется
//---
int                 MAlong,MAshort;              // МА-хэндлы
double              LongBuffer[],ShortBuffer[];  // Индикаторные буферы
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
   ArrayResize(LongBuffer,count);
   ArrayResize(ShortBuffer,count);
   ArrayInitialize(LongBuffer,0);
   ArrayInitialize(ShortBuffer,0);
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
   if(isNewBars()==true)
     {
      bool trig=false;
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
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
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
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
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        {
         request.type=ORDER_TYPE_SELL;
         OpenPosition();
        }
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        {
         request.type=ORDER_TYPE_BUY;
         OpenPosition();
        }
     };
  }
//+------------------------------------------------------------------+
