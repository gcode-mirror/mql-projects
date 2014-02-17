//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"//---


#include <TradeManager/TradeManagerEnums.mqh>  
#include <TradeManager/PositionArray.mqh>
#include <StringUtilities.mqh> 
#include <kernel32.mqh>
#include <Constants.mqh>  

//+------------------------------------------------------------------+
//| Константы для работы с бэктестом                                 |
//+------------------------------------------------------------------+

#define BT_COUNTWINS      0x1     // количество  выйгрышных позиций
#define BT_COUNTLOSS      0x2     // количество  убыточных позиций
#define BT_COUNTTOTAL     0x4     // количество позиций всего
#define BT_MAXWINPOS      0x8     // максимальная прибыльная позиция
#define BT_MINLOSEPOS     0x10    // минимальная убыточная позиция
#define BT_MAXPROFIT      0x20    // максимальная непрерывная прибыль
#define BT_MAXLOSS        0x40    // максимальный непрерывный убыток
#define BT_MAXCOUNTWIN    0x80    // максимальное количество непрерывных прибыльных позиций
#define BT_MAXCOUNTLOSE   0x100   // максимальное количество непрерывных убыточных позиций
#define BT_AVERAGEPROFIT  0x200   // средняя прибыльная позиция
#define BT_AVERAGELOSS    0x400   // средняя убыточная позиция
#define BT_CLEANPROFIT    0x800   // чистая прибыль
#define BT_GROSSPROFIT    0x1000  // общая прибыль 
#define BT_GROSSLOSS      0x2000  // общий убыток
#define BT_PROFITFACTOR   0x4000  // фактор прибыльности
#define BT_RECOVERYFACTOR 0x8000  // фактор востановления
#define BT_MATHAWAITING   0x10000 // мат ожидание сделки
#define BT_ABSDRAWDOWN    0x20000 // абсолютная просадка
#define BT_MAXDRAWDOWN    0x40000 // максимальная просадка
   
//+------------------------------------------------------------------+
//| Класс для работы с бэктестом                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory; // массив истории виртуальных позиций
   // системные поля класса отчетности
   double   _balance;                 // баланс
   datetime _start,_finish;           // периоды загрузки истории
   string   _symbol;                  // символ
   double   _max_balance;             // максимальный уровень баланса
   double   _min_balance;             // минимальный уровень баланса
   double   _deposit;                 // депозит
   ENUM_TIMEFRAMES _timeFrame;        // таймфрейм
   string   _expertName;              // имя эксперта      
   // результаты отчетности   
   int    _countwins;       // количество  выйгрышных позиций
   int    _countloss;       // количество  убыточных позиций
   int    _counttotal;      // количество позиций всего
   double _maxwinpos;       // максимальная прибыльная позиция
   double _minlosepos;      // минимальная убыточная позиция
   double _maxprofit;       // максимальная непрерывная прибыль
   double _maxloss;         // максимальный непрерывный убыток
   int    _maxcountwin;     // максимальное количество непрерывных прибыльных позиций
   int    _maxcountlose;    // максимальное количество непрерывных убыточных позиций
   double _averageprofit;   // средняя прибыльная позиция
   double _averageloss;     // средняя убыточная позиция
   double _cleanprofit;     // чистая прибыль
   double _grossprofit;     // общая прибыль 
   double _grossloss;       // общий убыток
   double _profitfactor;    // фактор прибыльности
   double _recoveryfactor;  // фактор востановления
   double _mathawaiting;    // мат ожидание сделки
   double _absdrawdown;     // абсолютная просадка
   double _maxdrawdown;     // максимальная просадка  
   
  public:
   // Get-методы 
   int    GetCountWins () { return (_countwins); };
   int    GetCountLoss () { return (_countloss); };
   int    GetCountTotal() { return (_counttotal);};
   double GetMaxWinPos() { return (_maxwinpos); };
   double GetMinLossPos() { return (_minlosepos); };
   double GetMaxProfit() { return (_maxprofit); };
   double GetMaxLoss() { return (_maxloss); };   
   int    GetMaxCountWin () { return (_maxcountwin); };
   int    GetMaxCountLose () { return (_maxcountlose); };     
   double GetAverageProfit() { return (_averageprofit); };       
   double GetAverageLoss() { return (_averageloss); };  
   double GetCleanProfit() { return (_cleanprofit); };
   double GetGrossProfit() { return (_grossprofit); };
   double GetGrossLoss() { return (_grossloss); };
   double GetProfitFactor() { return (_profitfactor); };
   double GetRecoveryFactor() { return (_recoveryfactor); };
   double GetMathAwaiting() { return (_mathawaiting); };
   double GetAbsDrawdown() { return (_absdrawdown); };
   double GetMaxDrawDown() { return (_maxdrawdown); };                               
   //конструкторы
   BackTest() { _positionsHistory = new CPositionArray(); };  
   BackTest(string file_url,datetime start,datetime finish)
    { 
     _positionsHistory = new CPositionArray(); 
     LoadHistoryFromFile(file_url,start,finish); 
    }; 
   // деструктор
  ~BackTest() { delete _positionsHistory; };
   //методы бэктеста
   bool  MakeBackTest (long mode);  // метод 
   
   
   //метод возвращения индекса позиции в массиве позиций по времени
   int   GetIndexByDate(datetime dt,bool type);
   //методы вычисления количест трейдов в истории по символу
   uint   GetNTrades();     //вычисляет количество трейдов по символу
   uint   GetNSignTrades(int sign);  //вычисляет количество выйгрышных трейдов по символу
   //вычисление прибылей
   void GetProfits();           
   //знаки позиций по прибыли
   int    GetSignPosition(uint index);    //вычисляет знак позиции по индексу 
   //метод вычисления процентных соотношений
   double GetIntegerPercent(uint value1,uint value2);   //метод вычисления процентного соотношения value1 по отношению  к value2
   //методы вычисления максимальных и средних трейдов
   double GetMaxTrade(int sign);          //вычисляет самый большой  трейд по символу
   double GetAverageTrade(int sign);      //вычисляет средний  трейд
   //методы вычисления количеств подряд идущих трейдов
   uint   GetMaxInARowTrades(int sign); 
   //методы вычисления максимальные непрерывные прибыль и убыток
   double GetMaxInARow(int sign);  
   //методы вычисления просадки баланса
   double GetAbsDrawdown ();              //вычисляет абсолютную просадку баланса
   double GetRelDrawdown ();              //вычисляет относительную просадку баланса
   double GetMaxDrawdown ();              //вычисляет максимальную просадку баланса
   //метод вычисления конечной прибыли 
   double GetTotalProfit ();  
   //метод вычисляет максимальный и минимальный баланс
   void   GetBalances ();   
   //метод сохраняет график баланса
   void   SaveBalanceToFile (int file_handle);
   //прочие системные методы
   bool LoadHistoryFromFile(string file_url,datetime start,datetime finish);          //загружает историю позиции из файла
   void GetHistoryExtra(CPositionArray *array);        //получает историю позиций извне
 //  void Save
   bool SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName); //сохраняет результаты бэктеста
   //дополнительный методы
   string SignToString (int sign);                     //переводит знак позиции в строку
   //сохраняет строку в файл 
 };

//+------------------------------------------------------------------+
//| Возвращает индекс по дате                                        |
//+------------------------------------------------------------------+

 int BackTest::GetIndexByDate(datetime dt,bool type)
  {
   int index;
   CPosition *pos;
   switch (type)
    {
     //если нужно найти первую позицию, позднее заданной даты
     case true:
      index = 0;
      //проходим по массиву позиций
      do 
       {
        pos = _positionsHistory.Position(index);
        index++;
       }
      while (index < _positionsHistory.Total() && pos.getOpenPosDT() < dt );
      //если позиция найдена, то вернем её индекс
      if (index <_positionsHistory.Total())
       return index;
     break; 
     //если нужно найти первую позицию перед заданной датой
     case false:
      index = _positionsHistory.Total();
      //проходим по массиву позиций
      do 
       {
        index--;
        pos = _positionsHistory.Position(index);
       }
      while (index >= 0 && pos.getOpenPosDT() > dt );
      //если позиция найдена, то вернем её индекс
      if (index >=  0)
       return index;     
     break;
    }
   return -1;  //если позиция не найдена
  } 
 
 
//+------------------------------------------------------------------+
//| Вычисляет количество позиций в истории                           |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades()
  {
   return _positionsHistory.Total();  //размер массива
  }
//+------------------------------------------------------------------+
//| Вычисляет количество позиций по знаку                            |
//+------------------------------------------------------------------+
  uint BackTest::GetNSignTrades(int sign) // (1) - прибыльные трейды (-1) - убыточные
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint count=0; //количество позиций с данным символом
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию
     if (pos.getPosProfit()*sign > 0) //если символ позиции совпадает с переданным и профит положительный
      {
       count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }

//+------------------------------------------------------------------+
//| вычисляет прибыли                                                | 
//+------------------------------------------------------------------+

 void BackTest::GetProfits(void)
  {
   CPosition * pos;
   int length = _positionsHistory.Total(); 
   int index;
   // выставляем по умолчанию прибыли
   _clean_profit = 0;
   _gross_profit = 0;
   _gross_loss   = 0;
   for (index=0;index<length;index++)
    {
     pos = _positionsHistory.At(index);
     // модифицируем чистую прибыль
     if (pos.getPosProfit()>=0)
      _gross_profit = _gross_profit + pos.getPosProfit();
     else
      _gross_loss   = _gross_loss + pos.getPosProfit();
     
    }
    _clean_profit = _gross_profit + _gross_loss;
  } 

    
//+------------------------------------------------------------------+
//| возвращает знак  позиции по индексу                              |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(uint index)
  {
   CPosition * pos;
   double profit;
     pos = _positionsHistory.Position(index);
     profit = pos.getPosProfit();
      if (profit>0)
        return 1;
      if (profit<0)
        return -1;
       return 0;
  }
//+------------------------------------------------------------------+
//| Вычисляет процентное соотношение value1 к value2                 |
//+------------------------------------------------------------------+  

 double BackTest::GetIntegerPercent(uint value1,uint value2)
  {
   if (value2)
   return 1.0*value1/value2;
   return -1;
   
  }

//+------------------------------------------------------------------+
//| Вычисляет самую большую по знаку                                 |
//+------------------------------------------------------------------+    

double BackTest::GetMaxTrade(int sign) //sign = 1 - самый большой прибыльный, (-1) - самый большой убыточный
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double maxTrade = 0;  //значение максимального трейда
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getPosProfit()*sign > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 

 
//+------------------------------------------------------------------+
//| Вычисляет среднюю позицию                                        |
//+------------------------------------------------------------------+

double BackTest::GetAverageTrade(int sign) // (1) - средний выйгрышный, (-1) - средний убыточный, (0) - средний по всем
 {
   uint index;
   uint total = _positionsHistory.Total();    //размер массива
   double tradeSum = 0;                       //сумма трейдов 
   uint count = 0;                            //количество посчитанных позиций
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (sign != 0)
      {
       if ( pos.getPosProfit()*sign > 0 ) 
        {
         count++; //увеличиваем счетчик позиций на единицу
         tradeSum = tradeSum + pos.getPosProfit(); //к общей сумме прибавляем трейд
        }
      }
      else
      {
         count++; //увеличиваем счетчик позиций на единицу
         tradeSum = tradeSum + pos.getPosProfit(); //к общей сумме прибавляем трейд
      }  
     }
   if (count)
    return tradeSum/count; //возвращаем среднее
   return -1;
 }   
   
 
//+------------------------------------------------------------------+
//| Вычисляет макс. количество подряд идущих позиций по знаку        |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowTrades(int sign) //sign 1 - прибыльные трейды, (-1) - убыточные трейды 
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint max_count = 0; //максимальное количество подряд идущих трейдов
   uint count = 0;     //текущий счет позиций
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
       if (pos.getPosProfit()*sign > 0) 
         {
           count++; //увеличиваем количество
         }
        else
         {
          if (count>0)  
           {
            if (count > max_count) //если текущее количество больше предыдущего
             {
              max_count = count;   //сохранем текущее
             }
            count = 0;             //обнуляем счетчик
           }
         }   
    }   
    if (count>max_count)
    {
     max_count = count;
    }      
    return max_count; 
  }
  
  
//+------------------------------------------------------------------+
//| Вычисляет максимальную непрерывную прибыль (1) или убыток (-1)   |
//+------------------------------------------------------------------+

 double BackTest::GetMaxInARow(int sign)  //sign: 1 - по прибыльным, (-1) - по убыточным
  {
   uint index;
   uint total = _positionsHistory.Total();            //размер массива
   double tradeSum = 0;                               //суммарное количество 
   double maxTrade = 0;                               //максимальный непрерывный трейд
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);         //получаем указатель на позицию 
        if (pos.getPosProfit()*sign > 0)              
         {
           tradeSum = tradeSum + pos.getPosProfit();  //прибавляем профит позиции
         }
        else
         {
          if (tradeSum*sign>0)  
           {
            if (tradeSum*sign > maxTrade*sign)        
             {
              maxTrade = tradeSum; 
             }
            tradeSum = 0;
           }
         }
    }   
            if (tradeSum*sign > maxTrade*sign)
             maxTrade = tradeSum;
    return maxTrade; 
  }  

 
//+-------------------------------------------------------------------+
//| Вычисляет абсолютную просадку по балансу                          |
//+-------------------------------------------------------------------+

double BackTest::GetAbsDrawdown(void)
 {
   if (_min_balance < 0)
    return -_min_balance; 
   return 0; 
 }

  
//+-------------------------------------------------------------------+
//| Вычисляет максимальную просадку по балансу                        |
//+-------------------------------------------------------------------+  
double BackTest::GetMaxDrawdown () //(сейчас для теста вместо баланса - прибыль)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double MaxBalance = 0;   //максимальный баланс на текущий момент (вместо нуля потом записать начальный баланс)
   double MaxDrawdown = 0;  //максимальная просадка баланса
  
   CPosition * pos;
   _balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
       _balance = _balance + pos.getPosProfit(); //модернизируем текущий баланс
       if (_balance > MaxBalance)  //если баланс превысил текущий максимальный баланс, то перезаписываем его
        {
          MaxBalance = _balance;
        }
       else 
        {
         if ((MaxBalance-_balance) > MaxDrawdown) //если обнаружена больше просадка, чем была
          {
            MaxDrawdown = MaxBalance-_balance;  //то записываем новую просадку баланса
          }
        }
    }  
   return MaxDrawdown; //возвращаем максимальную просадку по балансу
 }
 
//+-------------------------------------------------------------------+
//| Возвращает конечный баланс                                        |
//+-------------------------------------------------------------------+

double BackTest::GetTotalProfit()
 {
  return _balance;
 }  
 
//+-------------------------------------------------------------------+
//| Вычисляет максимальный и минимальный балансы                      |
//+-------------------------------------------------------------------+

void  BackTest::GetBalances()
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double balance  = 0;                     //максимальный баланс на текущий момент (вместо нуля потом записать начальный баланс)
   double sizeOfLot;   
   CPosition * pos;                         //указатель на позицию                                  
   //обнуляем баланс
   _max_balance = 0;
   _min_balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);   //получаем указатель на позицию 
     sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();     
        balance = balance + pos.getPosProfit()*sizeOfLot; // модицифируем баланс
        if (balance > _max_balance)  
         _max_balance = balance;
        if (balance < _min_balance)
         _min_balance = balance;
    }

 } 
 
//+-------------------------------------------------------------------+
//| Сохраняет в файл отчетности график баланса                        |
//+-------------------------------------------------------------------+ 

void BackTest::SaveBalanceToFile(int file_handle)
 {
  int    total = _positionsHistory.Total();                      // всего количество позиций в истории
  double current_balance = 0;                                    // текущий баланс
  CPosition *pos;                                                // указатель на позицию  
  double sizeOfLot;   
  WriteTo  (file_handle,DoubleToString(current_balance)+" ");    // сохраняем изначальный баланс  
  for (int index=0;index<total;index++)
   {
    // получаем указатель на позицию
    pos = _positionsHistory.Position(index);
    sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();
    current_balance = current_balance + pos.getPosProfit()*sizeOfLot; // вычисляем  баланс в данной точке, прибавляя к балансу прибыль по позиции
    WriteTo  (file_handle,DoubleToString(current_balance)+" "); 
   }
 }
  
//+-------------------------------------------------------------------+
//| Загружает историю позиций из файла                                |
//+-------------------------------------------------------------------+   
  
bool BackTest::LoadHistoryFromFile(string file_url,datetime start,datetime finish)
{

 if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
 {
  FileDelete(file_url);
  return(true);
 }
 int file_handle;   //файловый хэндл  
 if (!FileIsExist(file_url, FILE_COMMON) ) //проверка существования файла истории 
 {

  PrintFormat("%s File %s doesn't exist", MakeFunctionPrefix(__FUNCTION__),file_url);
  return (false);
 }  
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV, ";");
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  FileClose(file_handle);
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), file_url);
  return (false);
 }

 _positionsHistory.Clear();                   //очищаем массив
 _positionsHistory.ReadFromFile(file_handle,start,finish); //загружаем данные из файла 
 
 _start = start;
 _finish   = finish;
 
 FileClose(file_handle);                      //закрывает файл  
 return (true);
}  
  
  
//+-------------------------------------------------------------------+
//| Получает историю позиций извне                                    |
//+-------------------------------------------------------------------+

void BackTest::GetHistoryExtra(CPositionArray *array)
 {
  _positionsHistory = array;
 } 
 
//+-------------------------------------------------------------------+
//| Сохраняет вычисленные параметры бэктеста                          |
//+-------------------------------------------------------------------+
bool BackTest::SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName)
 {
  double current_balance;
  double sizeOfLot;      // размер лота
  CPosition *pos;
  uint total = _positionsHistory.Total();  //всего количество позиций в истории
  //открываем файл для рез-тов бэктеста на запись
  int file_handle = CreateFileW(file_name, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
  //если не удалось создать файл
  if(file_handle <= 0 )
   {
    Alert("Не возможно создать файл результатов бэктеста");
    return(false);
   }
  // сохраняем параметры сохранения отчетности
  _timeFrame  = timeFrame;
  _expertName = expertName;
  _symbol     = symbol;
  // сохраняем стандартный размер лота по символу
  pos = _positionsHistory.Position(0);
  // размер лота по символу
  sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();
  //переменные для хранения параметров бэктеста
  uint    n_trades           =  GetNTrades();                     //количество позиций
  uint    n_win_trades       =  GetNSignTrades(1);                //количество выйгрышных трейдов
  uint    n_lose_trades      =  GetNSignTrades(-1);               //количество выйгрышных трейдов
  int     sign_last_pos      =  GetSignPosition(_positionsHistory.Total()-1); //знак последней позиции
  double  max_trade          =  GetMaxTrade(1)*sizeOfLot;                     //самый большой трейд по символу
  double  min_trade          =  GetMaxTrade(-1)*sizeOfLot;        //самый маленький трейд по символу
  double  aver_profit_trade  =  GetAverageTrade(1)*sizeOfLot;     //средний прибыльный трейд 
  double  aver_lose_trade    =  GetAverageTrade(-1)*sizeOfLot;    //средний убыточный трейд   
  uint    maxPositiveTrades  =  GetMaxInARowTrades(1);            //максимальное количество подряд идущих положительных трейдов
  uint    maxNegativeTrades  =  GetMaxInARowTrades(-1);           //максимальное количество подряд идущих отрицательных трейдов
  double  maxProfitRange     =  GetMaxInARow(1)*sizeOfLot;        //максимальный профит
  double  maxLoseRange       =  GetMaxInARow(-1)*sizeOfLot;       //максимальный убыток
  double  maxDrawDown        =  GetMaxDrawdown()*sizeOfLot;       //максимальная просадка
  double  absDrawDown;                                            //абсолютная просадка
  double  profitFactor;                                           //фактор профита
  double  recoveryFactor;                                         //отношение чистой прибыли к процентной максимальной просадке
  double  mathAwaiting;                                           //матожидание сделки
   
  GetBalances();  // вычисляем максимальный и минимальный баланс
  
  GetProfits ();  // вычисляем прибыли
  
  _clean_profit  = _clean_profit * sizeOfLot;
  _gross_loss    = _gross_loss * sizeOfLot;
  _gross_profit  = _gross_profit * sizeOfLot;
  profitFactor   = _gross_profit / _gross_loss;
  recoveryFactor = _clean_profit / maxDrawDown;
  mathAwaiting   = GetAverageTrade(0) * sizeOfLot;
  absDrawDown    = GetAbsDrawdown();
  
  //сохраняем в файл данные об эксперте , таймфрейме и прочем
  WriteTo  (file_handle,_expertName+" ");                  // сохраняем имя эксперта
  WriteTo  (file_handle,_symbol+" ");                      // сохраняем символ
  WriteTo  (file_handle,IntegerToString(ArraySearchString(symArray,_symbol) )+" ");    // сохраняем символ (код символа)
  WriteTo  (file_handle,PeriodToString(_timeFrame)+" ");   // сохраняем таймфрейм  
  pos = _positionsHistory.Position(_positionsHistory.Total()-1);         //получаем указатель на первую позицию   
  WriteTo  (file_handle,IntegerToString(pos.getOpenPosDT())+" ");      // сохраняем время начала считывания истории в Unix Time
  pos = _positionsHistory.Position(0);         //получаем указатель на последнюю позицию    
  WriteTo  (file_handle,IntegerToString(pos.getOpenPosDT())+" ");     // сохраняем время конца считывания истории в Unix Time
  WriteTo  (file_handle,DoubleToString(_max_balance)+" "); // максимальный баланс
  WriteTo  (file_handle,DoubleToString(_min_balance)+" "); // минимальный баланс
  
  //сохраняем файл параметров вычисления бэктеста
  WriteTo  (file_handle,IntegerToString(n_trades+1)+" ");
  WriteTo  (file_handle,IntegerToString(n_win_trades)+" ");
  WriteTo  (file_handle,IntegerToString(n_lose_trades+1)+" ");
  WriteTo  (file_handle,IntegerToString(sign_last_pos)+" ");
  WriteTo  (file_handle,DoubleToString(max_trade)+" ");
  WriteTo  (file_handle,DoubleToString(min_trade)+" ");   
  WriteTo  (file_handle,DoubleToString(maxProfitRange)+" "); 
  WriteTo  (file_handle,DoubleToString(maxLoseRange)+" ");
  WriteTo  (file_handle,IntegerToString(maxPositiveTrades)+" ");  
  WriteTo  (file_handle,IntegerToString(maxNegativeTrades)+" ");
  WriteTo  (file_handle,DoubleToString(aver_profit_trade)+" ");
  WriteTo  (file_handle,DoubleToString(aver_lose_trade)+" ");    
  WriteTo  (file_handle,DoubleToString(maxDrawDown)+" ");
  WriteTo  (file_handle,DoubleToString(absDrawDown)+" ");
  WriteTo  (file_handle,DoubleToString(_clean_profit)+" ");
  WriteTo  (file_handle,DoubleToString(_gross_profit)+" ");
  WriteTo  (file_handle,DoubleToString(_gross_loss)+" ");
  WriteTo  (file_handle,DoubleToString(profitFactor)+" ");
  WriteTo  (file_handle,DoubleToString(recoveryFactor)+" ");  
  WriteTo  (file_handle,DoubleToString(mathAwaiting)+" "); 
                                         
  //сохраняем точки графиков (баланса, маржи)
  SaveBalanceToFile(file_handle);
  //закрываем файл
  CloseHandle(file_handle);
 return (true);
 }

//+-------------------------------------------------------------------+
//| Дополнительные методы                                             |
//+-------------------------------------------------------------------+

string BackTest::SignToString(int sign)
 //переводит знак позиции в строку
 {
   if (sign == 1)
    return "positive";
   if (sign == -1)
    return "negative";
   return "no sign";
 }