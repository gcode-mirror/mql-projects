//+------------------------------------------------------------------+
//|                                                       UGALib.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| класс универсального генетического алгоритма                     |
//+------------------------------------------------------------------+

   enum  UGA_GS_DOUBLE  //перечисление для get\set double
    {
     UGA_RANGE_MINIMUM = 0,
     UGA_RANGE_MAXIMUM,
     UGA_PRECISION
    };
    
   enum  UGA_GS_INTEGER //перечисление для get\set int
    {
     UGA_CHROMOSOME_COUNT=0,
     UGA_TOTAL_OF_CHROMOSOMES,
     UGA_CHR_COUNT_IN_HISTORY,
     UGA_GENE_COUNT,
     UGA_OPTIMIZE_METHOD,
     UGA_POPUL_CHROMOS_COUNT,
     UGA_EPOCH,
     UGA_AMOUNT_STARTS_FF
    }; 
   
  
   class UGA
    {
     private:     
      int    ChromosomeCount;             //Максимально возможное количество хромосом в колонии
      int    TotalOfChromosomesInHistory; //Общее количество хромосом в истории
      int    ChrCountInHistory;           //Количество уникальных хромосом в базе хромосом
      int    GeneCount;                   //Количество генов в хромосоме
      int    OptimizeMethod;              //1-минимум, любое другое - максимум
      int    PopulChromosCount;           //Текущее количество хромосом в популяции
      int    Epoch;                       //Кол-во эпох без улучшения
      int    AmountStartsFF;              //Количество запусков функции приспособленности      
      double RangeMinimum;                //Минимум диапазона поиска
      double RangeMaximum;                //Максимум диапазона поиска
      double Precision;                   //Шаг поиска
     public:
      double Population   [][1000];       //Популяция
      double Colony       [][500];        //Колония потомков
      double Chromosome[];                //Набор оптимизируемых аргументов функции - генов    
      //методы интеграции
      double UGAGetDouble (UGA_GS_DOUBLE param);  //возвращает значение параметра типа double
      bool   UGASetDouble (UGA_GS_DOUBLE param,double value);  //сохраняет значение параметра типа double
      int    UGAGetInteger(UGA_GS_INTEGER param); //возвращает значение параметра типа integer
      bool   UGASetInteger (UGA_GS_INTEGER param,int value);  //сохраняет значение параметра типа integer      
      
      //методы работы с генетическим алгоритмом
      void RunUGA(
               double ReplicationPortion, //Доля Репликации.
               double NMutationPortion,   //Доля Естественной мутации.
               double ArtificialMutation, //Доля Искусственной мутации.
               double GenoMergingPortion, //Доля Заимствования генов.
               double CrossingOverPortion,//Доля Кроссинговера.
               double ReplicationOffset,  //Коэффициент смещения границ интервала
               double NMutationProbability//Вероятность мутации каждого гена в %
               );      
      void ProtopopulationBuilding(); //создание протопопуляции
      void GetFitness(double &historyHromosomes[][100000]); //получение приспособленности для каждой особи
      void CheckHistoryChromosomes(
                                   int  chromos,
                                   double &historyHromosomes[][100000]
                                   ); //проверка хромосомы по базе хромосом
      void CycleOfOperators(
                            double &historyHromosomes[][100000],
                            double ReplicationPortion, //Доля Репликации.
                            double NMutationPortion,   //Доля Естественной мутации.
                            double ArtificialMutation, //Доля Искусственной мутации.
                            double GenoMergingPortion, //Доля Заимствования генов.
                            double CrossingOverPortion,//Доля Кроссинговера.
                            double ReplicationOffset,  //Коэффициент смещения границ интервала
                            double NMutationProbability//Вероятность мутации каждого гена в %
                           ); //цикл операторов UGA
      void Replication(
                       double &child[],
                       double  ReplicationOffset
                      ); //репликация
      void NaturalMutation(
                           double &child[],
                           double  NMutationProbability
                          ); //естественная мутация
      void ArtificialMutation(
                              double &child[],
                              double  ReplicationOffset
                             ); //искуственная мутация
      void GenoMerging(double &child[]); //заимствование генов
      void CrossingOver(double &child[]); //кроссинговер
      void SelectTwoParents(
                            int &address_mama,
                            int &address_papa
                           ); //отбор двух особей
      void SelectOneParent(int &address); //отбор одного родителя
      int NaturalSelection(); //естественный отбор
      void RemovalDuplicates(); //удаление дубликатов с сортировкой по VFF
      void PopulationRanking(); //ранжирование популяции

      double RNDfromCI(double Minimum,double Maximum);  //генератор случайных чисел из заданного интервала
      double SelectInDiscreteSpace(
                                   double In, 
                                   double InMin, 
                                   double InMax, 
                                   double step, 
                                   int    RoundMode
                                  ); //выбор в дискретном пространстве
     };
     
  //описание методов интеграции
  
  double UGA::UGAGetDouble(UGA_GS_DOUBLE param) //получает значение double параметра
   {
    switch ( param )
     {
      case UGA_RANGE_MINIMUM:
       return RangeMinimum;
      break;
      case UGA_RANGE_MAXIMUM:
       return RangeMaximum;
      break;      
      case UGA_PRECISION:
       return Precision;
      break;         
      default:
       return -1;
      break; 
     }
   }
   
   bool UGA::UGASetDouble(UGA_GS_DOUBLE param,double value) //сохраняет значение double параметра
    {
    switch ( param )
     {
      case UGA_RANGE_MINIMUM:
       RangeMinimum = value;
      break;
      case UGA_RANGE_MAXIMUM:
       RangeMaximum = value;
      break;      
      case UGA_PRECISION:
       Precision = value;
      break;         
      default:
       return false;
      break;
     }     
     return true;
    }
    
    int UGA::UGAGetInteger(UGA_GS_INTEGER param) //получает значение integer параметра
     {
      switch ( param )
       {
        case UGA_CHROMOSOME_COUNT:
         return ChromosomeCount;
        break;
        case UGA_TOTAL_OF_CHROMOSOMES:
         return TotalOfChromosomesInHistory;
        break;  
        case UGA_CHR_COUNT_IN_HISTORY:
         return ChrCountInHistory;
        break; 
        case UGA_GENE_COUNT:
         return GeneCount;
        break;  
        case UGA_OPTIMIZE_METHOD:
         return OptimizeMethod;
        break;    
        case UGA_POPUL_CHROMOS_COUNT:
         return PopulChromosCount;
        break; 
        case UGA_EPOCH:
         return Epoch;
        break;     
        case UGA_AMOUNT_STARTS_FF:
         return AmountStartsFF;
        break;                                                             
        default:
         return -1;
        break; 
       }      
     }
     
   bool UGA::UGASetInteger(UGA_GS_INTEGER param,int value)  //сохраняет integer параметр
    {
       switch ( param )
       {
        case UGA_CHROMOSOME_COUNT:
         ChromosomeCount = value;
        break;
        case UGA_TOTAL_OF_CHROMOSOMES:
         TotalOfChromosomesInHistory = value;
        break;  
        case UGA_CHR_COUNT_IN_HISTORY:
         ChrCountInHistory = value;
        break; 
        case UGA_GENE_COUNT:
         GeneCount = value;
        break;  
        case UGA_OPTIMIZE_METHOD:
         OptimizeMethod = value;
        break;    
        case UGA_POPUL_CHROMOS_COUNT:
         PopulChromosCount = value;
        break; 
        case UGA_EPOCH:
         Epoch = value;
        break;     
        case UGA_AMOUNT_STARTS_FF:
         AmountStartsFF = value;
        break;                                                             
        default:
         return false;
        break; 
       }   
       return true;    
    }
    
  //методы работы генетического алгоритма
  
  void UGA::RunUGA
                  (
                   double ReplicationPortion, //Доля Репликации.
                   double NMutationPortion,   //Доля Естественной мутации.
                   double ArtificialMutation, //Доля Искусственной мутации.
                   double GenoMergingPortion, //Доля Заимствования генов.
                   double CrossingOverPortion,//Доля Кроссинговера.
                   double ReplicationOffset,  //Коэффициент смещения границ интервала
                   double NMutationProbability//Вероятность мутации каждого гена в %
                  )
{ 
  //сброс генератора, производится только один раз
  MathSrand((int)TimeLocal());
  //-----------------------Переменные-------------------------------------
  int    chromos=0, gene  =0;//индексы хромосом и генов
  int    resetCounterFF   =1;//счетчик сбросов "Эпох без улучшений"
  int    currentEpoch     =1;//номер текущей эпохи
  int    SumOfCurrentEpoch=0;//сумма "Эпох без улучшений"
  int    MinOfCurrentEpoch=Epoch;//минимальное "Эпох без улучшений"
  int    MaxOfCurrentEpoch=0;//максимальное "Эпох без улучшений"
  int    epochGlob        =0;//общее количество эпох
  // Колония [количество признаков(генов)][количество особей в колонии]
  ArrayResize    (Population,GeneCount+1);
  ArrayInitialize(Population,0.0);
  // Колония потомков [количество признаков(генов)][количество особей в колонии]
  ArrayResize    (Colony,GeneCount+1);
  ArrayInitialize(Colony,0.0);
  // Банк хромосом
  // [количество признаков(генов)][количество хромосом в банке]
  double          historyHromosomes[][100000];
  ArrayResize    (historyHromosomes,GeneCount+1);
  ArrayInitialize(historyHromosomes,0.0);
  //----------------------------------------------------------------------
  //--------------Проверка корректности входных параметров----------------
  //...количество хромосом должно быть не меньше 2
  if (ChromosomeCount<=1)  ChromosomeCount=2;
  if (ChromosomeCount>500) ChromosomeCount=500;
  //----------------------------------------------------------------------
  //======================================================================
  // 1) Создать протопопуляцию                                     —————1)
  ProtopopulationBuilding ();
  //======================================================================
  // 2) Определить приспособленность каждой особи                  —————2)
  //Для 1-ой колонии
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=0;chromos<ChromosomeCount;chromos++)
    Population[0][chromos]=Colony[0][chromos];

  //Для 2-ой колонии
  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos-ChromosomeCount]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    Population[0][chromos]=Colony[0][chromos-ChromosomeCount];
  //======================================================================
  // 3) Подготовить популяцию к размножению                         ————3)
  RemovalDuplicates();
  //======================================================================
  // 4) Выделить эталонную хромосому                               —————4)
  for (gene=0;gene<=GeneCount;gene++)
    Chromosome[gene]=Population[gene][0];
  //======================================================================
  //ServiceFunction();

  //Основной цикл генетического алгоритма с 5 по 6
  while (currentEpoch<=Epoch)
  {
    //====================================================================
    // 5) Операторы UGA                                            —————5)
    CycleOfOperators
    (
    historyHromosomes,
    //---
    ReplicationPortion, //Доля Репликации.
    NMutationPortion,   //Доля Естественной мутации.
    ArtificialMutation, //Доля Искусственной мутации.
    GenoMergingPortion, //Доля Заимствования генов.
    CrossingOverPortion,//Доля Кроссинговера.
    //---
    ReplicationOffset,  //Коэффициент смещения границ интервала
    NMutationProbability//Вероятность мутации каждого гена в %
    );
    //====================================================================
    // 6) Сравнить гены лучшего потомка с генами эталонной хромосомы. 
    // Если хромосома лучшего потомка лучше эталонной,
    // заменить эталонную.                                         —————6)
    //Если режим оптимизации - минимизация
    if (OptimizeMethod==1)
    {
      //Если лучшая хромосома популяции лучше эталонной
      if (Population[0][0]<Chromosome[0])
      {
        //Заменим эталонную хромосому
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
      //  ServiceFunction();
        //Сбросим счетчик "эпох без улучшений"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //Если режим оптимизации - максимизация
    else
    {
      //Если лучшая хромосома популяции лучше эталонной
      if (Population[0][0]>Chromosome[0])
      {
        //Заменим эталонную хромосому
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
     //   ServiceFunction();
        //Сбросим счетчик "эпох без улучшений"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //====================================================================
    //Прошла ещё одна эпоха....
    epochGlob++;
  }

}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Создание протопопуляции
void UGA::ProtopopulationBuilding()
{ 
  PopulChromosCount=ChromosomeCount*2;
  //Заполнить популяцию хромосомами со случайными
  //...генами в диапазоне RangeMinimum...RangeMaximum
  for (int chromos=0;chromos<PopulChromosCount;chromos++)
  {
    //начиная с 1-го индекса (0-ой -зарезервирован для VFF) 
    for (int gene=1;gene<=GeneCount;gene++)
      Population[gene][chromos]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    TotalOfChromosomesInHistory++;
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Получение приспособленности для каждой особи.
void UGA::GetFitness
(
double &historyHromosomes[][100000]
)
{ 
  for (int chromos=0;chromos<ChromosomeCount;chromos++)
    CheckHistoryChromosomes(chromos,historyHromosomes);
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Проверка хромосомы по базе хромосом.
void UGA::CheckHistoryChromosomes
(
int     chromos,
double &historyHromosomes[][100000]
)
{ 
  //-----------------------Переменные-------------------------------------
  int   Ch1=0;  //Индекс хромосомы из базы
  int   Ge =0;  //Индекс гена
  int   cnt=0;  //Счетчик уникальных генов. Если хоть один ген отличается 
                //- хромосома признается уникальной
  //----------------------------------------------------------------------
  //Если в базе хранится хоть одна хромосома
  if (ChrCountInHistory>0)
  {
    //Переберем хромосомы в базе, чтобы найти такую же
    for (Ch1=0;Ch1<ChrCountInHistory && cnt<GeneCount;Ch1++)
    {
      cnt=0;
      //Сверяем гены, пока индекс гена меньше кол-ва генов и пока попадаются одинаковые гены
      for (Ge=1;Ge<=GeneCount;Ge++)
      {
        if (Colony[Ge][chromos]!=historyHromosomes[Ge][Ch1])
          break;
        cnt++;
      }
    }
    //Если набралось одинаковых генов столько же, можно взять готовое решение из базы
    if (cnt==GeneCount)
      Colony[0][chromos]=historyHromosomes[0][Ch1-1];
    //Если нет такой же хромосомы в базе, то рассчитаем для неё FF...
    else
    {
    
      //FitnessFunction(chromos);
      //.. и если есть место в базе сохраним
      if (ChrCountInHistory<100000)
      {
        for (Ge=0;Ge<=GeneCount;Ge++)
          historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
        ChrCountInHistory++;
      }
    }
  }
  //Если база пустая, рассчитаем для неё FF и сохраним её в базе
  else
  {
    //FitnessFunction(chromos);
    for (Ge=0;Ge<=GeneCount;Ge++)
      historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
    ChrCountInHistory++;
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Цикл операторов UGA
void UGA::CycleOfOperators
(
double &historyHromosomes[][100000],
//---
double    ReplicationPortion, //Доля Репликации.
double    NMutationPortion,   //Доля Естественной мутации.
double    ArtificialMutation, //Доля Искусственной мутации.
double    GenoMergingPortion, //Доля Заимствования генов.
double    CrossingOverPortion,//Доля Кроссинговера.
//---
double    ReplicationOffset,  //Коэффициент смещения границ интервала
double    NMutationProbability//Вероятность мутации каждого гена в %
)
{
  //-----------------------Переменные-------------------------------------
  double          child[];
  ArrayResize    (child,GeneCount+1);
  ArrayInitialize(child,0.0);

  int gene=0,chromos=0, border=0;
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,6);
  ArrayInitialize(fit,0.0);

  //Счетчик посадочных мест в новой популяции.
  int T=0;
  //----------------------------------------------------------------------

  //Зададим долю операторов UGA
  double portion[6];
  portion[0]=ReplicationPortion; //Доля Репликации.
  portion[1]=NMutationPortion;   //Доля Естественной мутации.
  portion[2]=ArtificialMutation; //Доля Искусственной мутации.
  portion[3]=GenoMergingPortion; //Доля Заимствования генов.
  portion[4]=CrossingOverPortion;//Доля Кроссинговера.
  portion[5]=0.0;
  //----------------------------
  if (NMutationProbability<0.0)
    NMutationProbability=0.0;
  if (NMutationProbability>100.0)
    NMutationProbability=100.0;
  //----------------------------
  //------------------------Цикл операторов UGA---------
  //Заполняем новую колонию потомками 
  while (T<ChromosomeCount)
  {
    //============================
    for (i=0;i<6;i++)
    {
      fit[i][0]=start;
      fit[i][1]=start+MathAbs(portion[i]-portion[5]);
      start=fit[i][1];
    }
    p=RNDfromCI(fit[0][0],fit[4][1]);
    for (u=0;u<5;u++)
    {
      if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
        break;
    }
    //============================
    switch (u)
    {
    //---------------------
    case 0:
      //------------------------Репликация--------------------------------
      //Если есть место в новой колонии, создадим новую особь
      if (T<ChromosomeCount)
      {
        Replication(child,ReplicationOffset);
        //Поселим новую особь в новую колонию
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Одно место заняли, счетчик перемотаем вперед
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 1:
      //---------------------Естественная мутация-------------------------
      //Если есть место в новой колонии, создадим новую особь
      if (T<ChromosomeCount)
      {
        NaturalMutation(child,NMutationProbability);
        //Поселим новую особь в новую колонию
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Одно место заняли, счетчик перемотаем вперед
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 2:
      //----------------------Искусственная мутация-----------------------
      //Если есть место в новой колонии, создадим новую особь
      if (T<ChromosomeCount)
      {
        ArtificialMutation(child,ReplicationOffset);
        //Поселим новую особь в новую  колонию
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Одно место заняли, счетчик перемотаем вперед
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 3:
      //-------------Образование особи с заимствованными генами-----------
      //Если есть место в новой колонии, создадим новую особь
      if (T<ChromosomeCount)
      {
        GenoMerging(child);
        //Поселим новую особь в новую колонию 
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Одно место заняли, счетчик перемотаем вперед
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    default:
      //---------------------------Кроссинговер---------------------------
      //Если есть место в новой колонии, создадим новую особь
      if (T<ChromosomeCount)
      {
        CrossingOver(child);
        //Поселим новую особь в новую  колонию
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Одно место заняли, счетчик перемотаем вперед
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------

      break;
      //---------------------
    }
  }//Конец цикла операторов UGA--

  //Определим приспособленность каждой особи в колонии потомков
  GetFitness(historyHromosomes);

  //Поселим потомков в основную популяцию
  if (PopulChromosCount>=ChromosomeCount)
  {
    border=ChromosomeCount;
    PopulChromosCount=ChromosomeCount*2;
  }
  else
  {
    border=PopulChromosCount;
    PopulChromosCount+=ChromosomeCount;
  }
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=0;gene<=GeneCount;gene++)
      Population[gene][chromos+border]=Colony[gene][chromos];

  //Подготовим популяцию к следующему размножению
  RemovalDuplicates();
}//конец ф-ии
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Репликация
void UGA::Replication
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------Переменные-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  SelectTwoParents(address_mama,address_papa);
  //-------------------Цикл перебора генов--------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----определим откуда мать и отец --------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------
    
    //------------------------------------------------------------------
    //....определим наибольший и наименьший из них,
    //если С1>C2, поменяем их местами
    if (C1>C2)
    {
      temp = C1; C1=C2; C2 = temp;
    }
    //--------------------------------------------
    if (C2-C1<Precision)
    {
      child[i]=C1; continue;
    }
    //--------------------------------------------
    //Назначим границы создания нового гена
    Minimum = C1-((C2-C1)*ReplicationOffset);
    Maximum = C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //Обязательная проверка, что бы поиск не вышел из заданного диапазона
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    temp=RNDfromCI(Minimum,Maximum);
    child[i]=
    SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Естественная мутация.
void UGA::NaturalMutation
(
double &child[],
double  NMutationProbability
)
{
  //-----------------------Переменные-------------------------------------
  int    address=0;
  //----------------------------------------------------------------------
  
  //-----------------Отбор родителя------------------------
  SelectOneParent(address);
  //---------------------------------------
  for (int i=1;i<=GeneCount;i++)
    if (RNDfromCI(0.0,100.0)<=NMutationProbability)
      child[i]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    else
      child[i]=Population[i][address];
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Искусственная мутация.
void UGA::ArtificialMutation
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------Переменные-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0,p=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------Отбор родителей------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //-------------------Цикл перебора генов------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----определим откуда мать и отец --------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------
    
    //------------------------------------------------------------------
    //....определим наибольший и наименьший из них,
    //если С1>C2, поменяем их местами
    if (C1>C2)
    {
      temp=C1; C1=C2; C2=temp;
    }
    //--------------------------------------------
    //Назначим границы создания нового гена
    Minimum=C1-((C2-C1)*ReplicationOffset);
    Maximum=C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //Обязательная проверка, что бы поиск не вышел из заданного диапазона
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    p=MathRand();
    if (p<16383.5)
    {
      temp=RNDfromCI(RangeMinimum,Minimum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
    else
    {
      temp=RNDfromCI(Maximum,RangeMaximum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Заимствование генов.
void UGA::GenoMerging
(
double &child[]
)
{
  //-----------------------Переменные-------------------------------------
  int  address=0;
  //----------------------------------------------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //-----------------Отбор родителя------------------------
    SelectOneParent(address);
    //--------------------------------------------------------
    child[i]=Population[i][address];
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Кроссинговер.
void UGA::CrossingOver
(
double &child[]
)
{
  //-----------------------Переменные-------------------------------------
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------Отбор родителей------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //Определим точку разрыва
  int address_of_gene=(int)MathFloor((GeneCount-1)*(MathRand()/32767.5));

  for (int i=1;i<=GeneCount;i++)
  {
    //----копируем гены матери--------
    if (i<=address_of_gene+1)
      child[i]=Population[i][address_mama];
    //----копируем гены отца--------
    else
      child[i]=Population[i][address_papa];
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Отбор двух родителей.
void UGA::SelectTwoParents
(
int &address_mama,
int &address_papa
)
{
  //-----------------------Переменные-------------------------------------
  int cnt=1;
  address_mama=0;//адрес материнской особи в популяции
  address_papa=0;//адрес отцовской особи в популяции
  //----------------------------------------------------------------------
  //----------------------------Отбор родителей--------------------------
  //Десять попыток выбрать разных родителей.
  while (cnt<=10)
  {
    //Для материнской особи
    address_mama=NaturalSelection();
    //Для отцовской особи
    address_papa=NaturalSelection();
    if (address_mama!=address_papa)
      break;
    cnt++;
  }
  //---------------------------------------------------------------------
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Отбор одного родителя.
void UGA::SelectOneParent
(
int &address//адрес родительской особи в популяции
)
{
  //-----------------------Переменные-------------------------------------
  address=0;
  //----------------------------------------------------------------------
  //----------------------------Отбор родителя--------------------------
  address=NaturalSelection();
  //---------------------------------------------------------------------
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Естественный отбор.
int UGA::NaturalSelection()
{
  //-----------------------Переменные-------------------------------------
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,PopulChromosCount);
  ArrayInitialize(fit,0.0);
  double delta=(Population[0][0]-Population[0][PopulChromosCount-1])*0.01-Population[0][PopulChromosCount-1];
  //----------------------------------------------------------------------

  for (i=0;i<PopulChromosCount;i++)
  {
    fit[i][0]=start;
    fit[i][1]=start+MathAbs(Population[0][i]+delta);
    start=fit[i][1];
  }
  p=RNDfromCI(fit[0][0],fit[PopulChromosCount-1][1]);

  for (u=0;u<PopulChromosCount;u++)
    if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
      break;

  return(u);
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Удаление дубликатов с сортировкой по VFF
void UGA::RemovalDuplicates()
{
  //-----------------------Переменные-------------------------------------
  int             chromosomeUnique[1000];//Массив хранит признак уникальности 
                                         //каждой хромосомы: 0-дубликат, 1-уникальная
  ArrayInitialize(chromosomeUnique,1);   //Предположим, что дубликатов нет
  double          PopulationTemp[][1000];
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int Ge =0;                             //Индекс гена
  int Ch =0;                             //Индекс хромосомы
  int Ch2=0;                             //Индекс второй хромосомы
  int cnt=0;                             //Счетчик
  //----------------------------------------------------------------------

  //----------------------Удалим дубликаты---------------------------1
  //Выбираем первый из пары для сравнения...
  for (Ch=0;Ch<PopulChromosCount-1;Ch++)
  {
    //Если не дубликат...
    if (chromosomeUnique[Ch]!=0)
    {
      //Выбираем второй из пары...
      for (Ch2=Ch+1;Ch2<PopulChromosCount;Ch2++)
      {
        if (chromosomeUnique[Ch2]!=0)
        {
          //Обнулим счетчик количества идентичных генов
          cnt=0;
          //Сверяем гены, пока попадаются одинаковые гены
          for (Ge=1;Ge<=GeneCount;Ge++)
          {
            if (Population[Ge][Ch]!=Population[Ge][Ch2])
              break;
            else
              cnt++;
          }
          //Если набралось одинаковых генов столько же, сколько всего генов
          //..хромосома признается дубликатом
          if (cnt==GeneCount)
            chromosomeUnique[Ch2]=0;
        }
      }
    }
  }
  //Счетчик посчитает количество уникальных хромосом
  cnt=0;
  //Скопируем уникальные хромосомы во временный масив
  for (Ch=0;Ch<PopulChromosCount;Ch++)
  {
    //Если хромосома уникальна, скопируем её, если нет, перейдем к следующей
    if (chromosomeUnique[Ch]==1)
    {
      for (Ge=0;Ge<=GeneCount;Ge++)
        PopulationTemp[Ge][cnt]=Population[Ge][Ch];
      cnt++;
    }
  }
  //Назначим переменной "Всего хромосом" значение счетчика уникальных хромосом
  PopulChromosCount=cnt;
  //Вернем уникальные хромосомы обратно в массив для временного хранения 
  //..обьединяемых популяций 
  for (Ch=0;Ch<PopulChromosCount;Ch++)
    for (Ge=0;Ge<=GeneCount;Ge++)
      Population[Ge][Ch]=PopulationTemp[Ge][Ch];
  //=================================================================1

  //----------------Ранжирование популяции---------------------------2
  PopulationRanking();
  //=================================================================2
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Ранжирование популяции.
void UGA::PopulationRanking()
{
  //-----------------------Переменные-------------------------------------
  int cnt=1, i = 0, u = 0;
  double          PopulationTemp[][1000];           //Временная популяция 
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int             Indexes[];                        //Индексы хромосом
  ArrayResize    (Indexes,PopulChromosCount);
  ArrayInitialize(Indexes,0);
  int    t0=0;
  double          ValueOnIndexes[];                 //VFF соответствующих
                                                    //..индексов хромосом
  ArrayResize    (ValueOnIndexes,PopulChromosCount);
  ArrayInitialize(ValueOnIndexes,0.0); double t1=0.0;
  //----------------------------------------------------------------------

  //Проставим индексы во временном массиве temp2 и 
  //...скопируем первую строку из сортируемого массива
  for (i=0;i<PopulChromosCount;i++)
  {
    Indexes[i] = i;
    ValueOnIndexes[i] = Population[0][i];
  }
  if (OptimizeMethod==1)
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]>ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  else
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]<ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  //Создадим отсортированный массив по полученным индексам
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      PopulationTemp[i][u]=Population[i][Indexes[u]];
  //Скопируем отсортированный массив обратно
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      Population[i][u]=PopulationTemp[i][u];
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Генератор случайных чисел из заданного интервала.
double UGA::RNDfromCI(double Minimum,double Maximum) 
{ return(Minimum+((Maximum-Minimum)*MathRand()/32767.5));}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Выбор в дискретном пространстве.
//Режимы:
//1-ближайшее снизу
//2-ближайшее сверху 
//любое-до ближайшего
double UGA::SelectInDiscreteSpace
(
double In, 
double InMin, 
double InMax, 
double step, 
int    RoundMode
)
{
  if (step==0.0)
    return(In);
  // обеспечим правильность границ
  if ( InMax < InMin )
  {
    double temp = InMax; InMax = InMin; InMin = temp;
  }
  // при нарушении - вернем нарушенную границу
  if ( In < InMin ) return( InMin );
  if ( In > InMax ) return( InMax );
  if ( InMax == InMin || step <= 0.0 ) return( InMin );
  // приведем к заданному масштабу
  step = (InMax - InMin) / MathCeil ( (InMax - InMin) / step );
  switch ( RoundMode )
  {
  case 1:  return( InMin + step * MathFloor ( ( In - InMin ) / step ) );
  case 2:  return( InMin + step * MathCeil  ( ( In - InMin ) / step ) );
  default: return( InMin + step * MathRound ( ( In - InMin ) / step ) );
  }
}