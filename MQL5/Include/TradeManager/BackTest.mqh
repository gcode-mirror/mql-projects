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

//+------------------------------------------------------------------+
//| Импорт WIN API библиотеки                                        |
//+------------------------------------------------------------------+

#import "kernel32.dll"

  bool CloseHandle                // Закрытие объекта
       ( int hObject );                  // Хэндл объекта
       
  int CreateFileW                 // Создание открытие объекта
      ( string lpFileName,               // Полный путь доступа к объекту
        int    dwDesiredAccess,          // Тип доступа к объекту
        int    dwShareMode,              // Флаги общего доступа
        int    lpSecurityAttributes,     // Описатель безопасности
        int    dwCreationDisposition,    // Описатель действия
        int    dwFlagsAndAttributes,     // Флаги аттрибутов
        int    hTemplateFile );      
          
  bool WriteFile                  // Запись данных в файл
       ( int    hFile,                   // handle to file to write to
         char    &dBuffer[],             // pointer to data to write to file
         int    nNumberOfBytesToWrite,   // number of bytes to write
         int&   lpNumberOfBytesWritten[],// pointer to number of bytes written
         int    lpOverlapped );          // pointer to structure needed for overlapped I/O    
  
  int  RtlGetLastWin32Error();
  
  int  RtlSetLastWin32Error (int dwErrCode);       
    
#import

//+------------------------------------------------------------------+
//| Необходимые константы                                            |
//+------------------------------------------------------------------+

// Тип доступа к объекту
#define _GENERIC_WRITE_      0x40000000
// Флаги общего доступа
#define _FILE_SHARE_WRITE_   0x00000002
// Описатель действия
#define _CREATE_ALWAYS_      2

//+------------------------------------------------------------------+
//| Класс для работы с бэктестом                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory; // массив истории виртуальных позиций
   double  _balance;                  // баланс
   datetime _start,_finish;           // периоды загрузки истории
   string   _symbol;                  // символ
   double   _max_balance;             // максимальный уровень баланса
   double   _min_balance;             // минимальный уровень баланса
   double   _deposit;                 // депозит
   ENUM_TIMEFRAMES _timeFrame;        // таймфрейм
   string   _expertName;              // имя эксперта   
  public:
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
   //метод возвращения индекса позиции в массиве позиций по времени
   int   GetIndexByDate(datetime dt,bool type);
   //методы вычисления количест трейдов в истории по символу
   uint   GetNTrades(string symbol);     //вычисляет количество трейдов по символу
   uint   GetNSignTrades(string symbol,int sign);  //вычисляет количество выйгрышных трейдов по символу
   //знаки позиций по прибыли
   int    GetSignLastPosition(string symbol);           //возвращает знак последней позиции 
   int    GetSignPosition(string symbol,uint index);    //вычисляет знак позиции по индексу 
   //метод вычисления процентных соотношений
   double GetIntegerPercent(uint value1,uint value2);   //метод вычисления процентного соотношения value1 по отношению  к value2
   //методы вычисления максимальных и средних трейдов
   double GetMaxTrade(string symbol,int sign);          //вычисляет самый большой  трейд по символу
   double GetAverageTrade(string symbol,int sign);      //вычисляет средний  трейд
   //методы вычисления количеств подряд идущих трейдов
   uint   GetMaxInARowTrades(string symbol,int sign); 
   //методы вычисления максимальные непрерывные прибыль и убыток
   double GetMaxInARow(string symbol,int sign);  
   //методы вычисления просадки баланса
   double GetAbsDrawdown (string symbol);              //вычисляет абсолютную просадку баланса
   double GetRelDrawdown (string symbol);              //вычисляет относительную просадку баланса
   double GetMaxDrawdown (string symbol);              //вычисляет максимальную просадку баланса
   //метод вычисления конечной прибыли 
   double GetTotalProfit (string symbol);  
   //метод вычисляет максимальный и минимальный баланс
   void   GetBalances (string symbol);   
   //метод сохраняет график баланса
   void   SaveBalanceToFile (int file_handle);
   //прочие системные методы
   bool LoadHistoryFromFile(string file_url,datetime start,datetime finish);          //загружает историю позиции из файла
   void DeleteHistory ();   // удаляет массив истории 
   void GetHistoryExtra(CPositionArray *array);        //получает историю позиций извне
 //  void Save
   bool SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName); //сохраняет результаты бэктеста
   void WriteTo (int handle,string buffer);            // сохраняет в файл строку по заданному хэндлу
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
    // pos = _positionsHistory.Position(index); //получаем указатель на позицию
     pos = _positionsHistory.At(index);
  //   Alert("<SYMBOL> ",pos.getSymbol());
     if (pos.getSymbol() == symbol) //если символ позиции совпадает с переданным 
      {
       count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| Вычисляет количество  трейдов по символу                         |
//+------------------------------------------------------------------+
  uint BackTest::GetNSignTrades(string symbol,int sign) // (1) - прибыльные трейды (-1) - убыточные
  {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   uint count=0; //количество позиций с данным символом
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > 0) //если символ позиции совпадает с переданным и профит положительный
      {
       count++; //увеличиваем количество посчитанных позиций на единицу
      }
    }
    return count;
  }


//+------------------------------------------------------------------+
//| возвращает знак последней позиции                                |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignLastPosition(string symbol)
  {
   CPosition * pos;
   double profit;
   int index = _positionsHistory.Total()-1;
   
   while (index>=0)
    {
     pos = _positionsHistory.At(index);
     if (pos.getSymbol() == symbol)
      {
       profit = pos.getPosProfit();
       if (profit>0)
        return 1;
       if (profit<0)
        return -1;
       return 0;
      }
     index--;
    }
   return 2;
  }
    
//+------------------------------------------------------------------+
//| возвращает знак  позиции по индексу                              |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(string symbol,uint index)
  {
   CPosition * pos;
   uint ind = 0;
   uint pos_index=-1;
   double profit;
   uint total = _positionsHistory.Total();
   while (ind<total)
    {
     pos = _positionsHistory.Position(ind);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      if (pos_index == index)
       {
        profit = pos.getPosProfit();
        if (profit>0)
         return 1;
        if (profit<0)
         return -1;
        return 0;
       }
      }
     ind++;
    }
   return 2;
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
//| Вычисляет самый большой  трейд по символу                        |
//+------------------------------------------------------------------+    

double BackTest::GetMaxTrade(string symbol,int sign) //sign = 1 - самый большой прибыльный, (-1) - самый большой убыточный
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double maxTrade = 0;  //значение максимального трейда
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 

 
//+------------------------------------------------------------------+
//| Вычисляет средний  трейд                                         |
//+------------------------------------------------------------------+

double BackTest::GetAverageTrade(string symbol,int sign) // (1) - средний выйгрышный, (-1) - средний убыточный
 {
   uint index;
   uint total = _positionsHistory.Total();    //размер массива
   double tradeSum = 0;                       //сумма трейдов 
   uint count = 0;                            //количество посчитанных позиций
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > 0) 
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
//| Вычисляет макс. количество подряд идущих  трейдов                |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowTrades(string symbol,int sign) //sign 1 - прибыльные трейды, (-1) - убыточные трейды 
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

 double BackTest::GetMaxInARow(string symbol,int sign)  //sign: 1 - по прибыльным, (-1) - по убыточным
  {
   uint index;
   uint total = _positionsHistory.Total();            //размер массива
   double tradeSum = 0;                               //суммарное количество 
   double maxTrade = 0;                               //максимальный непрерывный трейд
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);         //получаем указатель на позицию 
     if (pos.getSymbol() == symbol)                   //если символ совпадает 
      {
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
    }   
            if (tradeSum*sign > maxTrade*sign)
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
  
   CPosition * pos;
   _balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпал с передаваемым символом
      {
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
    }  
   return MaxDrawdown; //возвращаем максимальную просадку по балансу
 }
 
//+-------------------------------------------------------------------+
//| Возвращает конечный баланс                                        |
//+-------------------------------------------------------------------+

double BackTest::GetTotalProfit(string symbol)
 {
  return _balance;
 }  
 
//+-------------------------------------------------------------------+
//| Вычисляет максимальный и минимальный балансы                      |
//+-------------------------------------------------------------------+

void  BackTest::GetBalances(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //размер массива
   double balance  = 0;                     //максимальный баланс на текущий момент (вместо нуля потом записать начальный баланс)
   CPosition * pos;                         //указатель на позицию
                                            //обнуляем баланс
   _max_balance = 0;
   _min_balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //получаем указатель на позицию 
     if (pos.getSymbol() == symbol) //если символ совпал с передаваемым символом
      {
        balance = balance + pos.getPosProfit(); // модицифируем баланс
        if (balance > _max_balance)  
         _max_balance = balance;
        if (balance < _min_balance)
         _min_balance = balance;
      }
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
  WriteTo  (file_handle,DoubleToString(current_balance)+" ");    // сохраняем изначальный баланс  
  for (int index=0;index<total;index++)
   {
    // получаем указатель на позицию
    pos = _positionsHistory.Position(index);
    current_balance = current_balance + pos.getPosProfit(); // вычисляем  баланс в данной точке, прибавляя к балансу прибыль по позиции
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
//| Удаляет массив истории                                            |
//+-------------------------------------------------------------------+ 

void BackTest::DeleteHistory(void)
 {
   // очищаем массив
   _positionsHistory.Clear();
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
  //переменные для хранения параметров бэктеста
  uint    n_trades           =  GetNTrades(symbol);            //количество трейдов 
  uint    n_win_trades       =  GetNSignTrades(symbol,1);      //количество выйгрышных трейдов
  uint    n_lose_trades      =  GetNSignTrades(symbol,-1);     //количество выйгрышных трейдов
  int     sign_last_pos      =  GetSignLastPosition(symbol);   //знак последней позиции
  double  max_trade          =  GetMaxTrade(symbol,1);         //самый большой трейд по символу
  double  min_trade          =  GetMaxTrade(symbol,-1);        //самый маленький трейд по символу
  double  aver_profit_trade  =  GetAverageTrade(symbol,1);     //средний прибыльный трейд 
  double  aver_lose_trade    =  GetAverageTrade(symbol,-1);    //средний убыточный трейд   
  uint    maxPositiveTrades  =  GetMaxInARowTrades(symbol,1);  //максимальное количество подряд идущих положительных трейдов
  uint    maxNegativeTrades  =  GetMaxInARowTrades(symbol,-1); //максимальное количество подряд идущих отрицательных трейдов
  double  maxProfitRange     =  GetMaxInARow(symbol,1);        //максимальный профит
  double  maxLoseRange       =  GetMaxInARow(symbol,-1);       //максимальный убыток
  double  maxDrawDown        =  GetMaxDrawdown(symbol);        //максимальная просадка
  double  absDrawDown        =  0;                             //абсолютная просадка
  double  relDrawDown        =  0;                             //относительная просадка 
  
    Alert("ВОТ ТАК ВОТ ФАЙЛ ИСТОРИИ = ",file_name);
  
  GetBalances(symbol);  // вычисляем максимальный и минимальный баланс
  
  //сохраняем в файл данные об эксперте , таймфрейме и прочем
  WriteTo  (file_handle,_expertName+" ");                  // сохраняем имя эксперта
  WriteTo  (file_handle,_symbol+" ");                      // сохраняем символ
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
  WriteTo  (file_handle,DoubleToString(relDrawDown)+" ");   
  

                                         
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
 
 
   // сохраняет строку в файл
void BackTest::WriteTo(int handle, string buffer) 
{
  int    nBytesRead[1]={1};
  char   buff[]; 
  StringToCharArray(buffer,buff);
  if(handle>0) 
  {
    Comment(" ");
    WriteFile(handle, buff, StringLen(buffer), nBytesRead, NULL);
    
  } 
  else
   Print("неудача. плохой хэндл для файла SPEAKER");
}