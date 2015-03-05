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
   SExtremum       _bufferExtr[];            // буфер для хранения экстремумов  
   // приватные поля класса
   int             _handleDE;                // хэндл индикатора DrawExtremums
   string          _symbol;                  // символ
   ENUM_TIMEFRAMES _period;                  // период
   int             _countFormedExtr;         // количество сформированных экстремумов
   int             _countExtr;               // количество всего вычисленных экстремумов
   // приватные методы класса
   void         AddExtrToContainer(SExtremum &extr);                                                    // добавляет экстремум в контейнер
   SExtremum    MakeExtremum (double price, datetime time, int direction);                              // формирует из данных экстремума объект структуры экстремума
   
  public:
   CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                                   // конструктор класса контейнера экстремумов
  ~CExtrContainer();                                                                                    // деструктор класса контейнера экстремумов
   // методы класса
   SExtremum    GetExtremum       (int index);                                                          // получает экстремум по индексу
   bool         AddNewExtr        (datetime time);                                                      // добавляет новый экстремум с заданной даты
   int          GetCountFormedExtr() {  return (_countFormedExtr); };                                   // возвращает количество сформированных экстремумов  
   int          GetCountExtr      () {  return (_countExtr); };                                         // возвращает количество экстремумов 
 };
 
 // кодирование методов класса
 
 // кодирования приватных методов класса
 void CExtrContainer::AddExtrToContainer(SExtremum &extr)    // добавляет экстремум в контейнер
  {
   // если в контейнере еще не было экстремумов
   if (_countFormedExtr == 0)
    {
      _bufferExtr[0] = extr;
      _countFormedExtr++;
    }
   else
    {
     // если предыдущий экстремум был в том же направлении
     if (_bufferExtr[_countFormedExtr-1].direction == extr.direction)
      {
       // то просто обновляем экстремум в контейнере
       _bufferExtr[_countFormedExtr-1] = extr;
      }
     // если же он противоположный, то добавляем в конец
     else
      {
       _bufferExtr[_countFormedExtr] = extr;
       _countFormedExtr ++;
      }    
    }
  }
  
 // формирует из данных экстремума объект структуры экстремума
 SExtremum CExtrContainer::MakeExtremum (double price, datetime time, int direction)
  {
   SExtremum extr;
   extr.price = price;
   extr.time = time;
   extr.direction = direction;
   return (extr);
  }
 
 // кодирование публичных методок класса
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE/*,int sizeBuf*/)                     // конструктор класса
  {
   // сохраняем последнее время, по которое нужно догружать экстремумы
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
   _countFormedExtr = 0;
   _countExtr = 0;
   // задаем размер буфера экстремумов
   ArrayResize(_bufferExtr,10000);
  }

 CExtrContainer::~CExtrContainer() // деструктор класса
  {
   // освобождение буферов класса
   ArrayFree(_bufferExtr);
  }

 // метод возвращает экстремум по индексу 
 SExtremum CExtrContainer::GetExtremum(int index)
 {
  SExtremum nullExtr = {0,0,0};
  if (index < 0 || index >= _countFormedExtr)
    {
     Print("Ошибка метода GetExtrByIndex класса CExtrContainer. Индекс экстремума вне диапазона");
     return (nullExtr);
    }     
  return (_bufferExtr[_countFormedExtr - index - 1]);          
 }

 // метод добавляет новый экстремум по хэндлу индикатора по заданной дате
 bool CExtrContainer::AddNewExtr(datetime time)
  {
   double extrHigh[];
   double extrLow[];
   double extrHighTime[];
   double extrLowTime[];
   datetime timeHigh;
   datetime timeLow;
   if ( CopyBuffer(_handleDE,2,time,1,extrHigh)     < 1 || CopyBuffer(_handleDE,3,time,1,extrLow) < 1 || 
        CopyBuffer(_handleDE,4,time,1,extrHighTime) < 1 || CopyBuffer(_handleDE,5,time,1,extrLowTime) < 1 )
    {
     Print("Не удалось прогузить буфер экстремумов");
     return (false);
    }
   timeHigh = datetime(extrHighTime[0]);
   timeLow  = datetime(extrLowTime[0]);

   //если пришел только верхний экстремум
   if (extrHigh[0]>0 && extrLow[0]==0)
    {
     _countExtr++;
     AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));
    }
   //если пришел только нижний экстремум
   if (extrLow[0]>0 && extrHigh[0]==0)
    {
     _countExtr++;    
     AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));
    }
   //если пришло оба экстремума
   if (extrHigh[0]>0 && extrLow[0]>0)
    {
     _countExtr = _countExtr + 2;    
     // если верхний пришел раньше
     if (extrHighTime[0] < extrLowTime[0])
      {
       AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));
       AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));                                                    
      }
     // если нижний пришел раньше
     if (extrHighTime[0] > extrLowTime[0])
      {
       AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));       
       AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));             
      }      
    }     
   return (true);
  }