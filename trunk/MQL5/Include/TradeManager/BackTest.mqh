//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager/TradeManagerEnums.mqh>
#include <TradeManager/PositionArray.mqh>

//+------------------------------------------------------------------+
//| Класс для работы с бэктестом                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory;        ///массив истории виртуальных позиций

  public:
   //конструктор
   BackTest() { _positionsHistory = new CPositionArray(); };                             //конструктор класса
  ~BackTest() { delete _positionsHistory; };
   //методы бэктеста
   //методы вычисления количест трейдов в истории по символу
   uint   GetNTrades(string symbol);     //вычисляет количество трейдов по символу
   uint   GetNWinTrades(string symbol);  //вычисляет количество выйгрышных трейдов по символу
   uint   GetNLoseTrades(string symbol); //вычисляет количество убыточных трейдов по символу
   //знаки позиций по прибыли
  private:
   int    GetSPosition(uint index);  //вычисляет знак позиции 
  public:
   int    GetSignLastPosition(string symbol);  //возвращает знак последней позиции 
   int    GetSignPosition(string symbol,uint index);      //вычисляет знак позиции по индексу 
   //метод вычисления процентных соотношений
   double GetIntegerPercent(uint value1,uint value2);  //метод вычисления процентного соотношения value1 по отношению  к value2
   //методы вычисления максимальных и средних трейдов
   double GetMaxWinTrade(string symbol);  //вычисляет самый большой выйгрышный трейд по символу
   double GetMaxLoseTrade(string symbol); //вычисляет самый большой убыточный трейд по символу
   double GetMedWinTrade(string symbol);  //вычисляет средний выйгрышный трейд
   double GetMedLoseTrade(string symbol);  //вычисляет средний убыточный трейд   
   //методы вычисления количеств подряд идущих трейдов
   uint   GetMaxInARowWinTrades(string symbol);  //вычисляет максимальное количество подряд идущих выйгрышных трейдов по заданному символу
   uint   GetMaxInARowLoseTrades(string symbol);  //вычисляет максимальное количество подряд идущих убыточных трейдов по заданному символу   
   //методы вычисления максимальные непрерывные прибыль и убыток
   double GetMaxinARowProfit(string symbol);   //вычисляем максимальную непрерывную прибыль 
   double GetMaxinARowLose(string symbol);     //вычисляем максимальную непрерывный убыток    
   //методы вычисления просадки баланса
   double GetAbsDrawdown (string symbol);      //вычисляет абсолютную просадку баланса
   double GetRelDrawdown (string symbol);      //вычисляет относительную просадку баланса
   double GetMaxDrawdown (string symbol);      //вычисляет максимальную просадку баланса
   //прочие системные методы
   bool LoadHistoryFromFile(string file_url);   //загружает историю позиции из файла
   void GetHistoryExtra(CPositionArray *array); //получает историю позиций извне
   bool SaveBackTestToFile (string file_url);   //сохраняет результаты бэктеста
   
 };
//+------------------------------------------------------------------+
//| Вычисляет количество трейдов по символу                          |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   CPosition *pos;
   uint count=0; //количество позиций с данным символом   
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию
     if (pos.getSymbol() == symbol) //если символ позиции совпадает с переданным 
      {
       count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| Вычисляет количество выйгрышных трейдов по символу               |
//+------------------------------------------------------------------+
  uint BackTest::GetNWinTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint count=0; //количество позиций с данным символом
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию
     if (pos.getSymbol() == symbol && pos.getPosProfit() > 0) //если символ позиции совпадает с переданным и профит положительный
      {
       count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| Вычисляет количество убыточных трейдов по символу                |
//+------------------------------------------------------------------+
  uint BackTest::GetNLoseTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint count = 0; //количество позиций с данным символом
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию
     if (pos.getSymbol() == symbol && pos.getPosProfit() < 0) //если символ позиции совпадает с переданным и профит отрицательный
      {
      count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }  
//+------------------------------------------------------------------+
//| возвращает знак позиции                                          |  // протестить
//+------------------------------------------------------------------+  
 int BackTest::GetSPosition(uint index) 
  {
    CPosition * pos;
    double profit;
    pos = _positionsHistory.Position(index);  //получаем указатель на позицию
    profit = pos.getPosProfit();  //получаем профит позиции
    if (profit > 0) //если профит положительный
     return 1;
    else if (profit < 0) //если профит отрицательный
     return -1;
    return 0;  //если профита нет
  }  
//+------------------------------------------------------------------+
//| возвращает знак последней позиции                                |  //протестить
//+------------------------------------------------------------------+   
 int  BackTest::GetSignLastPosition(string symbol)
  {
   CPosition * pos;
   uint index = _positionsHistory.Total()-1;
   while (index>0)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      return index;
     index--;
    }
   return 0;
  }
    
//+------------------------------------------------------------------+
//| возвращает знак  позиции по индексу                              |   //допилить и протестить
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(string symbol,uint index)
  {
   CPosition * pos;
   uint index = 0;
   uint pos_index=0;
   uint total = _positionsHistory.Total();
   while (index<total)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      }
     index++;
    }
   return 0;
  }
//+------------------------------------------------------------------+
//| Вычисляет процентное соотношение value1 к value2                 |
//+------------------------------------------------------------------+  

 double BackTest::GetIntegerPercent(uint value1,uint value2)
  {
   return 1.0*value1/value2;
  }

//+------------------------------------------------------------------+
//| Вычисляет самый большой выйгрышный трейд по символу              |
//+------------------------------------------------------------------+    

double BackTest::GetMaxWinTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double maxTrade = 0;  //значение максимального трейда
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit() > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 
//+------------------------------------------------------------------+
//| Вычисляет самый большой убыточный трейд по символу               |
//+------------------------------------------------------------------+    

double BackTest::GetMaxLoseTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double minTrade = 0;  //значение максимального трейда
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit() < minTrade)
      {
       minTrade = pos.getPosProfit();
      }
    }  
    return minTrade;
 } 
 
//+------------------------------------------------------------------+
//| Вычисляет средний выйгрышный трейд                               |
//+------------------------------------------------------------------+

double BackTest::GetMedWinTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double tradeSum = 0;  //сумма трейдов 
   uint count = 0;       //количество посчитанных позиций
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit() > 0) //если смивол совпадает и профит положительный
      {
       count++; //увеличиваем счетчик позиций на единицу
       tradeSum = tradeSum + pos.getPosProfit(); //к общей сумме прибавляем трейд
      }
    }  
   return tradeSum/count; //возвращаем среднее
 }   
 
//+------------------------------------------------------------------+
//| Вычисляет средний убыточный трейд                                |
//+------------------------------------------------------------------+

double BackTest::GetMedLoseTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double tradeSum = 0;  //сумма трейдов 
   uint count = 0;       //количество посчитанных позиций
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit() < 0) //если смивол совпадает и профит отрицательный
      {
       count++; //увеличиваем счетчик позиций на единицу
       tradeSum = tradeSum + pos.getPosProfit(); //к общей сумме прибавляем трейд
      }
    }  
   return tradeSum/count; //возвращаем среднее
 }    
 
//+------------------------------------------------------------------+
//| Вычисляет макс. количество подряд идущих выйгрышных трейдов      |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowWinTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint max_count = 0; //максимальное количество подряд идущих трейдов
   uint count = 0;     //текущий счет позиций
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпадает 
      {
        if (pos.getPosProfit() > 0) //если профит положительный
         {
           count++; //увеличиваем количество
         }
        else
         {
          if (count>0)  //если предыдущая позиция прибыльная
           {
            if (count > max_count) //если текущее количество больше предыдущего
             {
              max_count = count; //сохранем текущее
             }
            count = 0;  //обнуляем счетчик
           }
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
//| Вычисляет макс. количество подряд идущих убыточных трейдов       |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowLoseTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint max_count = 0; //максимальное количество подряд идущих трейдов
   uint count = 0;         //текущий счет позиций
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпадает 
      {
        if (pos.getPosProfit() < 0) //если профит отрицательный
         {
           count++; //увеличиваем количество
         }
        else
         {
          if (count>0)  //если предыдущая позиция прибыльная
           {
            if (count > max_count) //если текущее количество больше предыдущего
             {
              max_count = count; //сохранем текущее
             }
            count = 0;  //обнуляем счетчик
           }
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
//| Вычисляет максимальную непрерывную прибыль                       |
//+------------------------------------------------------------------+

 double BackTest::GetMaxinARowProfit(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double tradeSum = 0;            //суммарное количество 
   double maxTrade = 0;        //максимальный непрерывный трейд
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпадает 
      {
        if (pos.getPosProfit() > 0) //если профит положительный
         {
           tradeSum = tradeSum + pos.getPosProfit();  //прибавляем профит позиции
         }
        else
         {
          if (tradeSum>0)  //если предыдущая позиция прибыльная
           {
            if (tradeSum > maxTrade) //если текущая прибыль больше предыдущей
             {
              maxTrade = tradeSum; //сохранем текущее
             }
            tradeSum = 0;
           }
         }
      }
    }   
            if (tradeSum > maxTrade)
             maxTrade = tradeSum;
    return maxTrade; 
  }  
//+-------------------------------------------------------------------+
//| Вычисляет максимальный непрерывный убыток                         |
//+-------------------------------------------------------------------+

 double BackTest::GetMaxinARowLose(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double tradeSum = 0;            //суммарное количество 
   double maxTrade = 0;        //максимальный непрерывный трейд
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпадает 
      {
        if (pos.getPosProfit() < 0) //если профит отрицательный
         {
           tradeSum = tradeSum + pos.getPosProfit();  //прибавляем профит позиции
         }
        else
         {
          if (tradeSum>0)  //если предыдущая позиция прибыльная
           {
            if (tradeSum < maxTrade) //если текущая прибыль меньше предыдущей
             {
              maxTrade = tradeSum; //сохранем текущее
             }
            tradeSum = 0;
           }
         }
      }
    }  
            if (tradeSum < maxTrade)
             maxTrade = tradeSum; 
    return maxTrade; 
  }  
  
//+-------------------------------------------------------------------+
//| Вычисляет максимальную просадку по балансу                        |
//+-------------------------------------------------------------------+  
double BackTest::GetMaxDrawdown (string symbol) //(сейчас для теста вместо баланса - прибыль)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double MaxBalance = 0;   //максимальный баланс на текущий момент (вместо нуля потом записать начальный баланс)
   double MaxDrawdown = 0;  //максимальная просадка баланса
   double balance = 0;          //статус баланса 
  
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпал с передаваемым символом
      {
       balance = balance + pos.getPosProfit(); //модернизируем текущий баланс
       if (balance > MaxBalance)  //если баланс превысил текущий максимальный баланс, то перезаписываем его
        {
          MaxBalance = balance;
        }
       else 
        {
         if ((MaxBalance-balance) > MaxDrawdown) //если обнаружена больше просадка, чем была
          {
            MaxDrawdown = MaxBalance-balance;  //то записываем новую просадку баланса
          }
        }
      }
    }  
   return MaxDrawdown; //возвращаем максимальную просадку по балансу
 }
  
//+-------------------------------------------------------------------+
//| Загружает историю позиций из файла                                |
//+-------------------------------------------------------------------+   
  
bool BackTest::LoadHistoryFromFile(string file_url)
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
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), file_url);
  return (false);
 }
 _positionsHistory.Clear();                   //очищаем массив
 _positionsHistory.ReadFromFile(file_handle); //загружаем данные из файла 
 FileClose(file_handle);          //закрывает файл  
 return (true);
 }  
 
//+-------------------------------------------------------------------+
//| Получает историю позиций извне                                    |
//+-------------------------------------------------------------------+

void BackTest::GetHistoryExtra(CPositionArray *array)
 {
  CPosition * pos;
  _positionsHistory = array;
  if (_positionsHistory.Total()) 
   {
  pos = array.At(0);
  Alert("Прибыль позиции = ",DoubleToString(pos.getPosProfit()));  
   }
 } 
 
//+-------------------------------------------------------------------+
//| Сохраняет результаты бэктеста в файл                              |
//+-------------------------------------------------------------------+

bool BackTest::SaveBackTestToFile(string file_url)
 {
uint   NTrades;      //количество позиций
uint   NWinTrades;   //количество выйгрышных сделок
uint   NLoseTrades;  //количество убыточных сделок
int    SignLastPosition; //знак последней позиции
int    SignPosition;     //знак позиции по индексу
double WinTradesPercent;  //процент выйгрышных позиций к общему числу
double LoseTradesPercent; //процент убыточных позиций к общему числу
double MaxWinTrade;  //самый большой выйгрышный трейд по символу
double MaxLoseTrade; //самый большой убыточный трейд по символу
double MedWinTrade;  //средний выйгрышный трейд
double MedLoseTrade; //средний убыточный трейд
uint   MaxInARowWinTrades; //вычисляет максимальное 
uint   MaxInARowLoseTrades;
double MaxInARowProfit;
double MaxInARowLose;
double MaxDrawdown;
 
NTrades             = GetNTrades(_Symbol);      //количество позиций
//NWinTrades          = GetNWinTrades(_Symbol);   //количество выйгрышных сделок
//NLoseTrades         = GetNLoseTrades(_Symbol);  //количество убыточных сделок
//SignLastPosition    = GetSignLastPosition(_Symbol); //знак последней позиции
//SignPosition        = GetSignPosition(_Symbol,2);     //знак позиции по индексу
//WinTradesPercent    = GetIntegerPercent(NWinTrades,NTrades);  //процент выйгрышных позиций к общему числу
//LoseTradesPercent   = GetIntegerPercent(NLoseTrades,NTrades); //процент убыточных позиций к общему числу
//MaxWinTrade         = GetMaxWinTrade(_Symbol);  //самый большой выйгрышный трейд по символу
//MaxLoseTrade        = GetMaxLoseTrade(_Symbol); //самый большой убыточный трейд по символу
//MedWinTrade         = GetMedWinTrade(_Symbol);  //средний выйгрышный трейд
//MedLoseTrade        = GetMedLoseTrade(_Symbol); //средний убыточный трейд
//MaxInARowWinTrades  = GetMaxInARowWinTrades(_Symbol); //вычисляет максимальное 
//MaxInARowLoseTrades = GetMaxInARowLoseTrades(_Symbol);
//MaxInARowProfit     = GetMaxinARowProfit(_Symbol);
//MaxInARowLose       = GetMaxinARowLose(_Symbol);
//MaxDrawdown         = GetMaxDrawdown(_Symbol);
 
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось открыть файл: %s", MakeFunctionPrefix(__FUNCTION__), file_url));
  return(false);
 }
 FileWrite(file_handle,"количество позиций = "+IntegerToString(NTrades));
 FileWrite(file_handle,"количество выйгрышных позиций = "+IntegerToString(NWinTrades));
 FileWrite(file_handle,"количество убыточных позиций = "+IntegerToString(NLoseTrades));
 FileWrite(file_handle,"знак последней позиции = "+IntegerToString(SignLastPosition));
 FileWrite(file_handle,"знак второй позиции = "+IntegerToString(SignPosition ));
 FileWrite(file_handle,"процент выйгрышных позиций = "+DoubleToString(WinTradesPercent));
 FileWrite(file_handle,"процент убыточных позиций = "+DoubleToString(LoseTradesPercent));
 FileWrite(file_handle,"максимальный выйгрышный трейд = "    +DoubleToString(MaxWinTrade ));
 FileWrite(file_handle,"максимальный убыточный трейд = "     +DoubleToString(MaxLoseTrade));  
 FileWrite(file_handle,"максимальный убыточный трейд = "     +DoubleToString(MaxLoseTrade));  
 FileWrite(file_handle,"максимум подряд идущих выйгрышных = "+IntegerToString(MaxInARowWinTrades));  
 FileWrite(file_handle,"максимум подряд идущих выйгрышных = "+IntegerToString(MaxInARowLoseTrades));  
 FileWrite(file_handle,"максимумальный непрерывный профит = " +DoubleToString(MaxInARowProfit));   
 FileWrite(file_handle,"максимальный непрерывный убыток = " +DoubleToString(MaxInARowLose));    
 FileWrite(file_handle,"Максимальная просадка по балансу = " +DoubleToString(MaxDrawdown));    
     
 FileClose(file_handle);
  return(true);  
 }
 
