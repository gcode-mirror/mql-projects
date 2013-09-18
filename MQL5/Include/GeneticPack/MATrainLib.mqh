//+------------------------------------------------------------------+
//| Оптимизирует процентом капитала                                  |
//+------------------------------------------------------------------+
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
#include        <TradeBlocks/CrossEMA.mq5>
#include        <TradeManager/TradeManager.mqh>
//---
double          cap=10000;           // Стартовый капитал
double          optF=0.3;            // Оптимальное F
long            leverage;            // Плечо счета
double          contractSize;        // Размер контракта
double          dig;                 // Кол-во знаков после запятой в котировке (для корректного прогноза кривой баланса на валютных парах с разным кол-вом знаков)
//---
int             OptParamCount=2;     // Кол-во оптимизируемых параметров
int             MaxMAPeriod=250;     // Максимальный период скользящих средних
//---
int             depth=250;           // Глубина истории (по умолчанию - 250, если надо иное - поменять в Инициализаторе эксперта/скрипта)
int             from=0;              // Откуда начинаем копировать (обязательно инициализировать перед каждым обращением к функции InitFirstLayer())
int             count=2;             // Сколько за раз копируем (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
//---
double          ERROR=0.0;           // Средняя ошибка на ген (это для генетического оптимизатора, значение мне неизвестно)

CrossEMA        trade_block;         //трейд блок

int                 MAlong,MAshort;              // МА-хэндлы
double              LongBuffer[],ShortBuffer[];  // Индикаторные буферы

ENUM_TM_POSITION_TYPE   signal;      //торговый сигнал
ENUM_TM_POSITION_TYPE   signal2;      //торговый сигнал

double traindd;
//+------------------------------------------------------------------+
//| InitArrays()                                                     |
//| Обязательно вызывать в Инициализаторе эксперта/скрипта           |
//+------------------------------------------------------------------+
void InitArrays()
  {
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(d,count);
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(o,count);
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(h,count);
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(l,count);
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(c,count);
//--- вспомогательный массив для оптимизации нейросети на исторических данных
   ArrayResize(v,count);
  }
//+------------------------------------------------------------------+
//| Фитнесс-функция для генетического оптимизатора нейросети:        |
//| выбирает пару, optF, веса синапсов;                              |
//| можно оптимизировать что угодно, но необходимо                   |
//| внимательно следить за количествами генов                        |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos)
  {
   int    b;
//--- есть открытая позиция?   
   bool   trig=false;
//--- направление открытой позиции
   string dir="";
//--- цена открытия позиции
   double OpenPrice=0;
//--- промежуточное звено между колонией генов и оптимизируемыми параметрами
   int    z;
//--- текущий баланс
   double t=cap;
//--- максимальный баланс
   double maxt=t;
//--- абсолютная просадка
   double aDD=0;
//--- относительная просадка
   double rDD=0.000001;
//--- непосредственно фитнесс-функция
   double ff=0;
//--- ГА выбирает пару
   z=(int)MathRound(Colony[GeneCount-1][chromos]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
  // MAshort=iMA(s,tf,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
  // MAlong =iMA(s,tf,(int)MathRound(Colony[2][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
  
   trade_block.UpdateHandle(FAST_EMA,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1); //обновляем хэндл быстрого индикатора   
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Colony[2][chromos]*MaxMAPeriod)+1); //обновляем хэндл медленного индикатора

   
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
//--- ГА выбирает оптимальное F
   optF=Colony[GeneCount][chromos];
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count-MaxMAPeriod,depth);
//--- Для нейросети, использующей исторические данные - откуда начинаем их копировать
   for(from=b;from>=1;from--)
     {
     // CopyBuffer(MAshort,0,from,count,ShortBuffer);
     // CopyBuffer(MAlong,0,from,count,LongBuffer);
      
      signal2 = trade_block.GetSignal(true,from); //получаем торговый сигнал
      
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if(signal2 == OP_SELL)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="SELL";
            trig=true;
           }
         else
           {
            if(dir=="BUY")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(o[1]-OpenPrice)*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="SELL";
               trig=true;
              }
           }
        }
     // if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
       if (signal2 == OP_BUY)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="BUY";
            trig=true;
           }
         else
           {
            if(dir=="SELL")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(OpenPrice-o[1])*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="BUY";
               trig=true;
              }
           }
        }
     }
   if(rDD<=traindd) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction                                                  |
//+------------------------------------------------------------------+
void ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| Подготовка и вызов генетического оптимизатора                    |
//+------------------------------------------------------------------+
void GA()
  {
//--- кол-во генов (равно кол-ву оптимизируемых переменных, 
//--- всех их необходимо не забывать упомянуть в FitnessFunction())
   GeneCount=OptParamCount+2;
//--- кол-во хромосом в колонии
   ChromosomeCount=GeneCount*11;
//--- минимум диапазона поиска
   RangeMinimum=0.0;
//--- максимум диапазона поиска
   RangeMaximum=1.0;
//--- шаг поиска
   Precision=0.0001;
//--- 1-минимум, любое другое-максимум
   OptimizeMethod=2;
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- кол-во эпох без улучшения
   Epoch=100;
//--- доля Репликации, естественной мутации, искусственной мутации, заимствования генов, 
//--- кроссинговера, коэффициент смещения границ интервала, вероятность мутации каждого гена в %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);
  }
//+------------------------------------------------------------------+
//| Получаем оптимизированные параметры нейросети                    |
//| и других переменных; всегда должно быть равно кол-ву генов       |
//+------------------------------------------------------------------+
void GetTrainResults() //
  {
//--- промежуточное звено между колонией генов и оптимизируемыми параметрами
   int z;
   
 //  MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
 //  MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1);   //меняем хэндлы индикаторов
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1);
   
   trade_block.UploadBuffers(from);  //запоняем буферы
   
// CopyBuffer(MAshort,0,from,count,ShortBuffer);
//   CopyBuffer(MAlong,0,from,count,LongBuffer);
//--- запоминаем лучшую пару
   z=(int)MathRound(Chromosome[GeneCount-1]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
//--- запоминаем лучшее значение оптимального F
   optF=Chromosome[GeneCount];
  }
//+------------------------------------------------------------------+
