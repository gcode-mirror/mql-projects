//+------------------------------------------------------------------+
//|                                                    CTrainLib.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <cUGA/UGALib.mqh>     //подключаем класс универсального генетического алгоритма
//+------------------------------------------------------------------+
//| класс CTrainLib                                                  |
//+------------------------------------------------------------------+

 class CTrainBlock
  {
   protected:
    double          cap;                     // Стартовый капитал
    double          optF;                    // Оптимальное F
    double          contractSize;            // Размер контракта
    double          dig;                     // Кол-во знаков после запятой в котировке (для корректного прогноза кривой баланса на валютных парах с разным кол-вом знаков)    
    double          ERROR;                   // Средняя ошибка на ген (это для генетического оптимизатора, значение мне неизвестно)
    double          traindd; 
    //-------------------------------------------
    long            leverage;                // Плечо счета
    int             OptParamCount;           // Кол-во оптимизируемых параметров
    int             MaxMAPeriod;             // Максимальный период скользящих средних
    int             depth;                   // Глубина истории (по умолчанию - 250, если надо иное - поменять в Инициализаторе эксперта/скрипта)
    int             from;                    // Откуда начинаем копировать (обязательно инициализировать перед каждым обращением к функции InitFirstLayer())
    int             count;                   // Сколько за раз копируем (по умолчанию - 2, если надо иное - поменять в Инициализаторе эксперта/скрипта)
    UGA             uGA;                     // универсальный генетический алгоритм
    
    string              fn;                  // Имя файла
    int                 handle;              // Ссылка на открываемый файл
    string              f;                   // Лог-строка, записываемая в файл
    string              s;                   // Пара
    ENUM_TIMEFRAMES     tf;                  // Таймфрейм
    MqlDateTime         dt;                  // Дата-время в виде структуры, а не сплошным int-числом
    datetime            d[];                 // Дата-время int-числом
    double              o[];                 // Открытия
    double              h[];                 // Максимумы
    double              l[];                 // Минимумы
    double              c[];                 // Закрытия
    long                v[];                 // Реальные объемы
    datetime            prevBT[1],curBT[1];  // Время начала бара в формате числа
    MqlDateTime         prevT,curT;          // Время начала бара в формате структуры
    MqlTradeRequest     request;             // Торговый запрос
    MqlTradeCheckResult check;               // Проверка торгового запроса 
    MqlTradeResult      result;              // Результат торгового запроса
    double              maxBalance;          // Максимальный баланс
   public:
    void   InitRelDD();                      // 
    double GetRelDD();                       // 
    double GetPossibleLots();                // 
    //------------------------------------------- 
    void   InitArrays();                     // инициализация массивов
    void   GA();                             // подготовка и вызов генетического оптимизатора
    void   GetTrainResults();                // получение оптимизированных параметров (для каждого своя)
    void   FitnessFunction(int chromos);     // фитнес функция (для каждого своя)                 
  };
  
 void CTrainBlock::InitRelDD(void)   
   {
    ulong DealTicket;
    double curBalance;
    prevBT[0]=D'2000.01.01 00:00:00';
    TimeToStruct(prevBT[0],prevT);
    curBalance=AccountInfoDouble(ACCOUNT_BALANCE);
    maxBalance=curBalance;
    HistorySelect(D'2000.01.01 00:00:00',TimeCurrent());
    for(int i=HistoryDealsTotal();i>0;i--)
      {
       DealTicket=HistoryDealGetTicket(i);
       curBalance=curBalance+HistoryDealGetDouble(DealTicket,DEAL_PROFIT);
       if(curBalance>maxBalance) maxBalance=curBalance;
      }   
   }
  double CTrainBlock::GetRelDD(void)
   {
    if(AccountInfoDouble(ACCOUNT_BALANCE)>maxBalance) maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     return((maxBalance-AccountInfoDouble(ACCOUNT_BALANCE))/maxBalance);  
   }
   
  double CTrainBlock::GetPossibleLots(void)
   {
    request.volume=1.0;
    if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
     OrderCheck(request,check);
    return(NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)/check.margin,2));   
   }
        
  void CTrainBlock::InitArrays(void)  //инициализация массивов
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
   
  void CTrainBlock::GA(void)    //подготовка и вызов генетического алгоритма
   {
//--- кол-во генов (равно кол-ву оптимизируемых переменных, 
//--- всех их необходимо не забывать упомянуть в FitnessFunction())
//>>>   GeneCount=OptParamCount+2;
   uGA.UGASetInteger(UGA_GENE_COUNT,OptParamCount+2);
//--- кол-во хромосом в колонии
//>>>   ChromosomeCount=GeneCount*11;
   uGA.UGASetInteger(UGA_CHROMOSOME_COUNT,uGA.UGAGetInteger(UGA_GENE_COUNT)*11);
//--- минимум диапазона поиска
//>>>   RangeMinimum=0.0;
   uGA.UGASetDouble(UGA_RANGE_MINIMUM,0.0);
//--- максимум диапазона поиска
//>>>   RangeMaximum=1.0;
   uGA.UGASetDouble(UGA_RANGE_MAXIMUM,1.0);
//--- шаг поиска
//>>>   Precision=0.0001;
   uGA.UGASetDouble(UGA_PRECISION,0.0001);
//--- 1-минимум, любое другое-максимум
//>>>   OptimizeMethod=2;
   uGA.UGASetInteger(UGA_OPTIMIZE_METHOD,2);
   
   ArrayResize(uGA.Chromosome,uGA.UGAGetInteger(UGA_GENE_COUNT)+1);
   ArrayInitialize(uGA.Chromosome,0);
//--- кол-во эпох без улучшения
//>>>   Epoch=100;
   uGA.UGASetInteger(UGA_EPOCH,100);
//--- доля Репликации, естественной мутации, искусственной мутации, заимствования генов, 
//--- кроссинговера, коэффициент смещения границ интервала, вероятность мутации каждого гена в %
   uGA.RunUGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);   
   } 
    
