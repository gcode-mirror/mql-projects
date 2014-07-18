//Оптимизирует процентом капитала
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
//---
double          cap=10000;      // Стартовый капитал
double          optF=0.3;       // Оптимальное F
long            leverage;       // Плечо счета
double          contractSize;   // Размер контракта
double          dig;            // Кол-во знаков после запятой в котировке (для корректного прогноза кривой баланса на валютных парах с разным кол-вом знаков)
//--- для нейросети, использующей исторические данные:
int             depth=250;      // Глубина истории (по умолчанию - 250, если надо иное - поменять в Инициализаторе эксперта/скрипта)
int             from=0;         // Откуда начинаем копировать (обязательно инициализировать перед каждым обращением к функции InitFirstLayer())
int             count=2;        // Сколько за раз копируем (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
//--- 
double          a=2.5;          // Значения коэффициента функции активации (сигмоида) (если задавать иное, то при получении результата функции GetANNResult() сравнивать его уже не с 0.75)
int             layers=2;       // Слоев (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
int             neurons=2;      // Нейронов (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
double          ne[];           // Массив значений нейронов [слоев][нейронов в слое]
double          we[];           // Массив весов синапсов [слоев][нейронов в слое][синапсов у каждого нейрона]
double          ANNRes=0;       // Результат выхода нейросети

double          ERROR=0.0;      // Средняя ошибка на ген (это для генетического оптимизатора, значение мне неизвестно)
//+------------------------------------------------------------------+
//| InitArrays                                                       |
//| Обязательно вызывать в Инициализаторе эксперта/скрипта           |
//+------------------------------------------------------------------+
void InitArrays() 
  {
//--- массив нейронов
   ArrayResize(ne,layers*neurons);
//--- массив синапсов
   ArrayResize(we,(layers-1)*neurons*neurons+neurons);
//--- инициализируем массив нейронов
   ArrayInitialize(ne,0.5);
//--- инициализируем массив синапсов
   ArrayInitialize(we,0.5);
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
//| Результат выхода нейросети, перед вызовом                        |
//| этой функции обязательно вызывать функцию InitFirstLayer()       |
//+------------------------------------------------------------------+
double GetANNResult() //
  {
   double r;
   int    c1,c2,c3;
   for(c1=2;c1<=layers;c1++)
     {
      for(c2=1;c2<=neurons;c2++)
        {
         ne[(c1-1)*neurons+c2-1]=0;
         for(c3=1;c3<=neurons;c3++)
           {
            ne[(c1-1)*neurons+c2-1]=ne[(c1-1)*neurons+c2-1]+ne[(c1-2)*neurons+c3-1]*we[((c1-2)*neurons+c3-1)*neurons+c2-1];
           }
         ne[(c1-1)*neurons+c2-1]=1/(1+MathExp(-a*ne[(c1-1)*neurons+c2-1]));
        }
     }
   r=0;
   for(c2=1;c2<=neurons;c2++)
     {
      r=r+ne[(layers-1)*neurons+c2-1]*we[(layers-1)*neurons*neurons+c2-1];
     }
   r=1/(1+MathExp(-a*r));
   return(r);
  }
//+------------------------------------------------------------------+
//| Фитнесс-функция для генетического оптимизатора нейросети:        |
//| выбирает пару, optF, веса синапсов;                              |
//| можно оптимизировать что угодно,                                 |
//| но необходимо внимательно следить за количествами генов          |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos) 
  {
   int    c1;
   int    b;
//--- промежуточное звено между колонией генов и оптимизируемыми параметрами
   int    z;
//Текущий баланс
   double t=cap;                                                      
//Максимальный баланс
   double maxt=t;
//Абсолютная просадка
   double aDD=0;
//Относительная просадка
   double rDD=0.000001;
//Непосредственно фитнесс-функция
   double ff=0;
//ГА выбирает веса синапсов
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Colony[c1][chromos];
//ГА выбирает пару
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
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
   //--- ГА выбирает оптимальное F
   optF=Colony[GeneCount][chromos];                                   
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count,depth);
   //--- для нейросети, использующей исторические данные - откуда начинаем их копировать
   for(from=b;from>=1;from--) 
     {
      //--- инициализируем входной слой
      InitFirstLayer();                                                
      //--- получаем результат на выходе нейросети
      ANNRes=GetANNResult();
      if(t>0)
        {
         if(ANNRes<0.75) t=t+t*optF*leverage*(o[1]-c[1])*dig/contractSize;
         else            t=t+t*optF*leverage*(c[1]-o[1])*dig/contractSize;
        }
      else t=0;
      if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
      if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
     }
   if(rDD<=trainDD) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction()                                                |
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
   GeneCount      =(layers-1)*neurons*neurons+neurons+2;              
//--- кол-во хромосом в колонии
   ChromosomeCount=GeneCount*11;                                      
//--- минимум диапазона поиска
   RangeMinimum   =0.0;                                               
//--- максимум диапазона поиска
   RangeMaximum   =1.0;                                               
//--- шаг поиска
   Precision      =0.0001;                                            
//--- 1-минимум, любое другое-максимум
   OptimizeMethod =2;                                                 
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- кол-во эпох без улучшения
   Epoch          =100;                                               
//--- доля репликации, естественной мутации, искусственной мутации, заимствования генов, 
//--- кроссинговера, коэффициент смещения границ интервала, вероятность мутации каждого гена в %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);                                
  }
//+------------------------------------------------------------------+
//| GetTrainANNResults()                                             |
//| Получаем оптимизированные параметры нейросети                    |
//| и других переменных; всегда должно быть равно кол-ву генов       |
//+------------------------------------------------------------------+
void GetTrainANNResults()
  {
   int c1;
//--- промежуточное звено между колонией генов и оптимизируемыми параметрами
   int z;                                                            
//--- запоминаем лучшие веса синапсов
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Chromosome[c1];
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
