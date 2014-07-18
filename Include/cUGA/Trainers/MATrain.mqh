//+------------------------------------------------------------------+
//|                                                      MATrain.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <cUGA/CTrainLib.mqh>  //подключаем класс CTrainLib для наследования
#include <TradeBlocks/CrossEMA.mq5>  //подключаем библиотеку для работы с CrossEMA
//+------------------------------------------------------------------+
//| класс MATrain                                                    |
//+------------------------------------------------------------------+
 class MATrain: public CTrainBlock
  {
   private:
    CrossEMA  trade_block;                   // торговый блок CrossEMA
   public: 
    void   GetTrainResults();                // получение оптимизированных параметров 
    void   FitnessFunction(int chromos);     //фитнес функция
    MATrain ();                              //конструктор класса
  };
  
  void MATrain::GetTrainResults(void)   //получение оптимизированных параметров 
   { 
 //--- промежуточное звено между колонией генов и оптимизируемыми параметрами
   int z;
 //  MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
 //  MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   
   trade_block.UpdateHandle(FAST_EMA,(int)MathRound(uGA.Chromosome[1]*MaxMAPeriod)+1);   //меняем хэндлы индикаторов
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(uGA.Chromosome[2]*MaxMAPeriod)+1);
   
   trade_block.UploadBuffers(from);  //запоняем буферы
   
// CopyBuffer(MAshort,0,from,count,ShortBuffer);
//   CopyBuffer(MAlong,0,from,count,LongBuffer);
//--- запоминаем лучшую пару
   z=(int)MathRound(uGA.Chromosome[uGA.UGAGetInteger(UGA_GENE_COUNT)-1]*12);
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
   optF=uGA.Chromosome[uGA.UGAGetInteger(UGA_GENE_COUNT)];
   }
   
  void MATrain::FitnessFunction(int chromos) //фитнесс функция
   {
   
   } 
  
  MATrain::MATrain(void)       //конструктор класса CTrainLib
   {
    cap=10000;           // Стартовый капитал
    optF=0.3;            // Оптимальное F
    OptParamCount=2;     // Кол-во оптимизируемых параметров
    MaxMAPeriod=250;     // Максимальный период скользящих средних
    depth=250;           // Глубина истории (по умолчанию - 250, если надо иное - поменять в Инициализаторе эксперта/скрипта)
    from=0;              // Откуда начинаем копировать (обязательно инициализировать перед каждым обращением к функции InitFirstLayer())
    count=2;             // Сколько за раз копируем (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
    ERROR=0.0;           // Средняя ошибка на ген (это для генетического оптимизатора, значение мне неизвестно)
   }