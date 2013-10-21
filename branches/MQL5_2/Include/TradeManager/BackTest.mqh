//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager/TradeManagerEnums.mqh>
#include <TradeManager/PositionArray.mqh>
#define N_COLUMNS 17
//+------------------------------------------------------------------+
//| Класс для работы с бэктестом                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray _positionsHistory;        ///массив истории виртуальных позиций
  public:
   //поля для доступа к элементам
   uint nTrades;                            //количество трейдов
   uint nDeals;                             //количество сделок
   uint nWinTrades;            //количество выйгрышных трейдов
   uint nLoseTrades;           //количество убыточных трейдов
   double shortTradeWinPer;    //процент выйгрышных коротких сделок (от выйгрывших)
   double longTradeWinPer;     //процент выйгрышных длинных сделок (от выйгрывших)
   double profitTradesPer;     //процент прибыльный трейдов (от всех)
   double loseTradesPer;       //процент проигравших трейдов (от всех)
   double maxWinTrade;         //самый большой выйгравший трейд
   double maxLoseTrade;        //самый большой убыточный трейд
   double medWinTrade;         //средний выйгрышный трейд
   double medLoseTrade;        //средний сливший трейд
   uint maxWinTradesN;         //максимальное число непрерывных выйгрышей
   uint maxLoseTradesN;        //максимальное число непрерывных проигрышей  
   double maxWinTradeSum;      //максимальная непрерывная прибыль
   double maxLoseTradeSum;     //максимальный непрерывный убыток
  public:
   //методы бэктеста
   //методы вычисления количест трейдов в истории по символу
   uint GetNTrades(string symbol);     //вычисляет количество трейдов по символу
   uint GetNWinTrades(string symbol);  //вычисляет количество выйгрышных трейдов по символу
   uint GetNLoseTrades(string symbol); //вычисляет количество убыточных трейдов по символу
   //знаки позиций по прибыли
  private:
   int  GetSPosition(uint index);  //вычисляет знак позиции 
  public:
   int  GetSignFirstPosition(string symbol); //вычисляет знак первой позиции
   int  GetSignPosition(string symbol,uint index);      //вычисляет знак позиции по индексу 
   //методы вычисления процентных соотношений
   double GetIntegerPercent(uint value1,uint value2);  //метод вычисления процентного соотношения value1 по отношению  к value2
   double GetWinTradesPercent(string symbol,bool math=true);  //вычисляет процент выйгрышных трейдов к общему числу
   double GetLoseTradesPercent(string symbol,bool math=true); //вычисляет процент убыточных трейдов к общему числу 
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
   bool LoadHistoryFromFile(string historyUrl);   //загружает историю позиции из файла
 };
//+------------------------------------------------------------------+
//| Вычисляет количество трейдов по символу                          |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint count=0; //количество позиций с данным символом
   CPosition *pos;
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
   uint count=0; //количество позиций с данным символом
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
   uint max = _positionsHistory.Total();
   while (index<total)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      }
     index--;
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
//| Вычисляет процентное соотношение выйгрышных трейдов к общему     |
//+------------------------------------------------------------------+

 double BackTest::GetWinTradesPercent(string symbol,bool math=true)
  {
   if (math == true)
    return GetIntegerPercent(GetNWinTrades(symbol),GetNTrades(symbol));
   return GetIntegerPercent(nWinTrades,nTrades);
  }  
  
//+------------------------------------------------------------------+
//| Вычисляет процентное соотношение убыточных трейдов к общему      |
//+------------------------------------------------------------------+

 double BackTest::GetLoseTradesPercent(string symbol,bool math=true)
  {
   if (math == true)
    return GetIntegerPercent(GetNLoseTrades(symbol),GetNTrades(symbol));
   return GetIntegerPercent(nLoseTrades,nTrades);
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
  
  
 bool BackTest::LoadHistoryFromFile(string historyUrl)   //загружает историю позиции из файла
 {
  int file_handle;   //файловый хэндл
  int ind;
  bool read_flag;  //флаг считывания данных из файла
  CPosition *pos;  

     if (!FileIsExist(historyUrl,FILE_COMMON) ) //проверка существования файла истории 
      return false;   
   file_handle = FileOpen(historyUrl, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
   if (file_handle == INVALID_HANDLE) //не удалось открыть файл
    return false;
   _positionsHistory.Clear(); //очищаем массив истории позиций
   for(ind=0;ind<N_COLUMNS;ind++) //N_COLUMNS - количество столбцов 
    {
     FileReadString(file_handle);  //пропуск первой строки таблицы
    } 
   read_flag = true;      //как минимум одну строку мы должны попытаться считать

   while (read_flag)
    {
     pos = new CPosition(0,"",OP_UNKNOWN,0);    //выделяем память под новый элемент 
     read_flag = pos.ReadFromFile(file_handle); //считываем строку для одной позиции
     if (read_flag)                             //если удалось считать строку 
      _positionsHistory.Add(pos);               //то добавляем элемент в массив историй 
    }   
   FileClose(file_handle);  //закрывает файл истории позиций 
  return true;
 }