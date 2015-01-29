//+------------------------------------------------------------------+
//|                                               CExtrContainer.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Класс-контейнер экстремумов                                      |
//+------------------------------------------------------------------+

// подключаем необходимые библиотеки
#include "SExtremum.mqh"      // структура экстремумов
#include <CLog.mqh>           // для лога
#include <CompareDoubles.mqh> // для сравнения вещественных чисел

class CExtrContainer 
 {
  private:
   // буфер экстремумов
   SExtremum       _bufferFormedExtr[];      // буфер для хранения сформированных экстремумов
   SExtremum       _bufferExtr[];            // буфер для хранения всех экстремумов в истории   
   SExtremum       _lastExtr;                // последний формирующийся экстремум
   // приватные поля класса
   int             _handleDE;                // хэндл индикатора DrawExtremums
   datetime        _lastTimeUploadedFormed;  // последнее время загрузки сформированных экстремумов
   datetime        _lastTimeUploaded;        // последнее время загрузки экстремумов в контейнер
   string          _symbol;                  // символ
   ENUM_TIMEFRAMES _period;                  // период
   int             _countFormedExtr;         // количество сформированных экстремумов
   int             _countExtr;               // количество всего вычисленных экстремумов
   int             _prevBars;                // предыдущее количество скопированных баров
  public:
   CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                                   // конструктор класса контейнера экстремумов
  ~CExtrContainer();                                                                                    // деструктор класса контейнера экстремумов
   // методы класса
   bool         UploadFormedExtremums   (bool useIndi=false);                                           // метод догружает новые сформированные экстремумы
   bool         UploadExtremums         (bool useIndi=false);                                           // метод догружает новые экстремумы
   SExtremum    GetExtremum             (int index,bool useFormedExtr=true);                            // получает экстремум по индексу
   SExtremum    GetExtremumClean        (int startRealIndex,int index);                                 // метод для чистого доступа к экстремумам по индексу
   SExtremum    GetLastExtremum   () { return (_bufferExtr[_countExtr-1]); };                           // получает значения последнего формирующегося экстремума
   void         AddNewExtr        (double price,datetime time, int direction,bool useFormedExtr=true);  // добавляет новый экстремум в конец контейнера
   void         UpdateLastExtr    (double price,datetime time, int direction);                          // обновляет последний формирующийся экстремум
   int          GetIndexByTime    (datetime time,bool useFormedExtr=true);                              // возвращает индекс экстремума в буфере по дате 
   int          GetCountFormedExtr() { return (_countFormedExtr); };                                    // возвращает количество сформированных экстремумов  
   int          GetCountExtr      () { return (_countExtr); };                                          // возвращает количество экстремумов
   void         PrintExtremums ();
 };
 
 // кодирование методов класса
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE)                     // конструктор класса
  {
   // сохраняем последнее время, по которое нужно догружать экстремумы
   _lastTimeUploadedFormed = 0;
   _lastTimeUploaded = 0;
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
   _countFormedExtr = 0;
   _countExtr = 0;
   _prevBars = 0;
  }
  
 CExtrContainer::~CExtrContainer() // деструктор класса
  {
   // освобождение буферов класса
   ArrayFree(_bufferFormedExtr);
   ArrayFree(_bufferExtr);
  }
  
 bool CExtrContainer::UploadFormedExtremums(bool useIndi=false)  // метод догружает новые сформированные экстремумы
  {
   double bufHigh[];         // буфер верхних экстремумов
   double bufLow[];          // буфер нижних экстремумов
   double bufTimeHigh[];     // буфер времени верхних экстремумов
   double bufTimeLow[];      // буфер времени нижних экстремумов
   int attempts;             // количество попыток загрузки индикаторных буферов
   int copiedHigh,copiedLow,copiedTimeHigh,copiedTimeLow; // количество скопированных элементов буфера
   int ind;                  // счетчик прохода по циклам
   int bars;
   if (useIndi)
    attempts = 1;
   else
    attempts = 25; 
   bars = Bars(_symbol,_period);
   for (ind=0;ind<attempts;ind++)
    {
     copiedHigh      =  CopyBuffer(_handleDE,0,0,bars,bufHigh);
     copiedLow       =  CopyBuffer(_handleDE,1,0,bars,bufLow);
     copiedTimeHigh  =  CopyBuffer(_handleDE,4,0,bars,bufTimeHigh);
     copiedTimeLow   =  CopyBuffer(_handleDE,5,0,bars,bufTimeLow);
     Sleep(1000);
    }
   if (copiedHigh < bars || copiedLow < bars || copiedTimeHigh < bars || copiedTimeLow < bars)
    {
     Print("Ошибка класса CExtrContainer. Не удалось прогрузить все буферы");
     return (false);
    }
    // проходим по циклу и заполняем массив экстремумов
   for (ind=0;ind<bars;ind++)
    {
     // если найден верхний экстремум
     if (bufHigh[ind] != 0 && bufLow[ind] == 0)
      {
       ArrayResize(_bufferFormedExtr,_countExtr+1);
       _bufferFormedExtr[_countFormedExtr].price = bufHigh[ind];
       _bufferFormedExtr[_countFormedExtr].time  = bufTimeHigh[ind];
       _bufferFormedExtr[_countFormedExtr].direction = 1;
       _countFormedExtr ++;   
      }
     // если найден нижний экстремум
     if (bufLow[ind] != 0 && bufHigh[ind] == 0)
      {
       ArrayResize(_bufferFormedExtr,_countFormedExtr+1);
       _bufferFormedExtr[_countFormedExtr].price = bufLow[ind];
       _bufferFormedExtr[_countFormedExtr].time  = bufTimeLow[ind];
       _bufferFormedExtr[_countFormedExtr].direction = -1;
       _countFormedExtr ++;   
      }  
     // если найден верхний и нижний экстремумы на одном баре
     if (bufHigh[ind] != 0 && bufLow[ind] != 0)
      {
       // выделяем память под два экстремума
       ArrayResize(_bufferFormedExtr,_countFormedExtr+2);
       // если High пришел раньше Low
       if (bufTimeHigh[ind] < bufTimeLow[ind])
        { 
         _bufferFormedExtr[_countFormedExtr].price = bufHigh[ind];
         _bufferFormedExtr[_countFormedExtr].time  = bufTimeHigh[ind];
         _bufferFormedExtr[_countFormedExtr].direction  = 1;
         _bufferFormedExtr[_countFormedExtr+1].price = bufLow[ind];
         _bufferFormedExtr[_countFormedExtr+1].time  = bufTimeLow[ind];
         _bufferFormedExtr[_countFormedExtr+1].direction  = -1;         
        }   
       // если Low пришел раньше High
       if (bufTimeHigh[ind] > bufTimeLow[ind])
        { 
         _bufferFormedExtr[_countFormedExtr].price = bufLow[ind];
         _bufferFormedExtr[_countFormedExtr].time  = bufTimeLow[ind];
         _bufferFormedExtr[_countFormedExtr].direction  = -1;
         _bufferFormedExtr[_countFormedExtr+1].price = bufHigh[ind];
         _bufferFormedExtr[_countFormedExtr+1].time  = bufTimeHigh[ind];
         _bufferFormedExtr[_countFormedExtr+1].direction  = 1;         
        }      
       _countFormedExtr = _countFormedExtr + 2;     
      }        
    }
   // сохраняем послднее время
   _lastTimeUploadedFormed = TimeCurrent();
   return (true);
  }
  
 bool CExtrContainer::UploadExtremums(bool useIndi=false)  // метод догружает новые экстремумы
  {
   double bufHigh[];         // буфер верхних экстремумов
   double bufLow[];          // буфер нижних экстремумов
   double bufTimeHigh[];     // буфер времени верхних экстремумов
   double bufTimeLow[];      // буфер времени нижних экстремумов
   int copiedHigh;           // количество скопированных элементов High
   int copiedLow;            // количество скопированных элементов Low
   int copiedTimeHigh;       // количество скопированных элементов времени верхних экстремумов
   int copiedTimeLow;        // количество скопированных элементов времени нижних экстремумов
   int ind;                  // счетчик прохода по циклам
   int bars;                 // количество баров в истории
   int needToCopyBars;       // количество, которое нужно скопировать
   // получаем количество баров всего в истории
   bars = Bars(_symbol,_period);           
   // получаем количество баров, которое нужно скопировать в эту итерацию
   needToCopyBars = bars - _prevBars;
   // изменяем размеры массивов
   ArrayResize(_bufferExtr,bars*2);
   // копируем буферы 
   copiedHigh      =  CopyBuffer(_handleDE,2,0,needToCopyBars,bufHigh);
   copiedLow       =  CopyBuffer(_handleDE,3,0,needToCopyBars,bufLow);
   copiedTimeHigh  =  CopyBuffer(_handleDE,4,0,needToCopyBars,bufTimeHigh);
   copiedTimeLow   =  CopyBuffer(_handleDE,5,0,needToCopyBars,bufTimeLow);
   if (copiedHigh < needToCopyBars || copiedLow < needToCopyBars || copiedTimeHigh < needToCopyBars || copiedTimeLow < needToCopyBars)
    {
     Print("Ошибка класса CExtrContainer. Не удалось прогрузить все буферы");
     return (false);
    }
    // проходим по циклу и заполняем массив экстремумов
   for (ind=0;ind<needToCopyBars;ind++)
    {
     
     // если найден верхний экстремум
     if ( bufHigh[ind]!=0.0 && bufLow[ind]==0.0 )
      {
       _bufferExtr[_countExtr].price = bufHigh[ind];
       _bufferExtr[_countExtr].time  = bufTimeHigh[ind];
       _bufferExtr[_countExtr].direction = 1;    
       _countExtr ++;   
      }
     // если найден нижний экстремум
     else if (bufLow[ind]!=0.0 && bufHigh[ind]==0.0)
      {
       _bufferExtr[_countExtr].price = bufLow[ind];
       _bufferExtr[_countExtr].time  = bufTimeLow[ind];
       _bufferExtr[_countExtr].direction = -1;       
       _countExtr ++;   

      }  
     // если найден верхний и нижний экстремумы на одном баре
     else if ( bufHigh[ind]!=0.0 && bufLow[ind]!=0.0 )
      {
       // если High пришел раньше Low
       if (bufTimeHigh[ind] < bufTimeLow[ind])
        { 
         _bufferExtr[_countExtr].price = bufHigh[ind];
         
         _bufferExtr[_countExtr].time  = bufTimeHigh[ind];
         _bufferExtr[_countExtr].direction  = 1;
         _bufferExtr[_countExtr+1].price = bufLow[ind];
         _bufferExtr[_countExtr+1].time  = bufTimeLow[ind];
         _bufferExtr[_countExtr+1].direction  = -1;           
        }   
       // если Low пришел раньше High
       if (bufTimeHigh[ind] > bufTimeLow[ind])
        { 
         _bufferExtr[_countExtr].price = bufLow[ind];
         _bufferExtr[_countExtr].time  = bufTimeLow[ind];
         _bufferExtr[_countExtr].direction  = -1;
         _bufferExtr[_countExtr+1].price = bufHigh[ind];
         _bufferExtr[_countExtr+1].time  = bufTimeHigh[ind];
         _bufferExtr[_countExtr+1].direction  = 1;                      
        }      
       _countExtr = _countExtr + 2;     
      }        
    }
   // сохраняем послднее время
   _lastTimeUploaded = TimeCurrent();
   // сохраняем послденее значение скопированных баров
   _prevBars = bars;
   return (true);
  }  
  
 // метод возвращает экстремум по индексу 
 SExtremum CExtrContainer::GetExtremum(int index,bool useFormedExtr=true)
  {
    SExtremum nullExtr = {0,0,0};
    // если используются только сформированные экстремумы
    if (useFormedExtr)
     {
      if (index < 0 || index >= _countFormedExtr)
       {
        Print("Ошибка метода GetExtrByIndex класса CExtrContainer. Индекс экстремума вне диапазона");
        return (nullExtr);
       }     
      return (_bufferFormedExtr[_countFormedExtr - index - 1]);
     }
    // если используются все экстремумы
    else
     {
      if (index < 0 || index >= _countExtr)
       {
        Print("Ошибка метода GetExtrByIndex класса CExtrContainer. Индекс экстремума вне диапазона");
        return (nullExtr);
       }     
      return (_bufferExtr[_countExtr - index - 1]);     
     }
   return (nullExtr); 
  }
  
 // метод для чистого доступа к экстремумам по индексу
 SExtremum CExtrContainer::GetExtremumClean(int startRealIndex,int index)
  {
   int ind;
   int countIndex = 0;
   int direction; 
   //Print("_countExtr = ",_countExtr," startRealIndex = ",startRealIndex," ArraySize = ",ArraySize(_bufferExtr) );
   direction = _bufferExtr[_countExtr-startRealIndex-1].direction;
   SExtremum nullExtr = {0,0,0};
   if (index == 0)
    return (_bufferExtr[_countExtr-startRealIndex-1]);
   // проходим по циклу и ищем экстремум по индексу
   for (ind=startRealIndex;ind<_countExtr;ind++)
    {
     // если найден экстремум с противоположным знаком 
     if (_bufferExtr[_countExtr-ind-1].direction != direction)
      {
       direction = _bufferExtr[_countExtr-ind-1].direction;        // сохраняем текущий знак
       countIndex ++;                                 // увеличиваем счетчик экстремумов
       // если мы нашли экстремум по заданному индексу
       if (index == countIndex)
        {
         return (_bufferExtr[_countExtr-ind-1]);                   // возвращаем экстремум по индексу
        }
      }
    }
   // возвращаем нулевой экстремум
   return (nullExtr);
  } 
  
 // метод добавляет новый экстремум в конец контейнера
 void CExtrContainer::AddNewExtr(double price,datetime time,int direction,bool useFormedExtr=true)
  {
   // если используются только сформированные экстремумы
   if (useFormedExtr)
    {
     // увеличиваем размер контейнера
     ArrayResize(_bufferFormedExtr,_countFormedExtr+1);
     _bufferFormedExtr[_countFormedExtr].price = price;
     _bufferFormedExtr[_countFormedExtr].time = time;
     _bufferFormedExtr[_countFormedExtr].direction = direction;
     _countFormedExtr ++;
    }
   // если используются все экстремумы
   else
    {
     // увеличиваем размер контейнера
     ArrayResize(_bufferExtr,_countExtr+1);
     _bufferExtr[_countExtr].price = price;
     _bufferExtr[_countExtr].time = time;
     _bufferExtr[_countExtr].direction = direction;
     _countExtr ++;    
    }
  }
  
  // метод обновляет последний формирующийся экстремум
  void CExtrContainer::UpdateLastExtr(double price,datetime time,int direction)
   {
    _lastExtr.price = price;
    _lastExtr.time  = time;
    _lastExtr.direction  = direction;
   }
  
  // метод возвращает индекс экстремума в буфере по времен
  int CExtrContainer::GetIndexByTime(datetime time,bool useFormedExtr=true)
   {
    int ind;
    // если используются только сформированные экстремумы
    if (useFormedExtr)
     {
      // проходим от конца контейнера и ищем экстремум, чья дата меньше или равна заданной
      for (ind=_countFormedExtr-1;ind>=0;ind--)
       { 
        // если нашли дату, которая меньше или равна текущему времени
        if (_bufferFormedExtr[ind].time <= time)
         break;
       }
      // если дату так и нашли
      if (ind<0)
       return (-1);
      // если дату всё же нашли
      return (_countFormedExtr - ind - 1); 
     }  
    // если используются все экстремумы
    else
     {
      // проходим от конца контейнера и ищем экстремум, чья дата меньше или равна заданной
      for (ind=_countExtr-1;ind>=0;ind--)
       { 
      //  Print("время _CountExtr = ",_countExtr," = ",TimeToString(_bufferExtr[ind].time) );
        // если нашли дату, которая меньше или равна текущему времени
        if (_bufferExtr[ind].time <= time)
         break;
       }
      // если дату так и нашли
      if (ind<0)
       return (-1);
      // если дату всё же нашли
      return (_countExtr - ind - 1); 
     }       
    // если дату всё же нашли
    return (-1);
   }
   
void CExtrContainer::PrintExtremums(void)
 {
  for (int ind=_countExtr-1;ind>0;ind--)
   {
    log_file.Write(LOG_DEBUG,StringFormat("Экстремум %i (%s,%s)",ind,DoubleToString(_bufferExtr[ind].price),TimeToString(_bufferExtr[ind].time)  ) )  ;      
   }
 }