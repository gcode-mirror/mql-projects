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
#include <CLog.mqh>                        // для лога
#include <CompareDoubles.mqh>              // для сравнения вещественных чисел
#include <DrawExtremums/CExtremum.mqh>  // для массива эктсремумов
#include <Arrays\ArrayObj.mqh>

class CExtrContainer 
{
 private:
 // буфер экстремумов
 CArrayObj       _bufferExtr;              // массив для хранения экстремумов           
 // приватные поля класса
 int             _handleDE;                // хэндл индикатора DrawExtremums
 string          _symbol;                  // символ
 ENUM_TIMEFRAMES _period;                  // период

 
 public:
 CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                  // конструктор класса контейнера экстремумов
 ~CExtrContainer();                                                                   // деструктор класса контейнера экстремумов
  
 // методы класса
 void         AddExtrToContainer(CExtremum *extr);                            // добавляет экстремум в контейнер
 void         AddExtrToContainer(int direction,double price,datetime time);   // добавляет экстремум в контейнер по направлению экстремума, цене и времени 
 CExtremum    *MakeExtremum (double price, datetime time, int direction);
 CExtremum    *GetExtremum (int index);
 bool         AddNewExtr (datetime time);                                     // добавляет новый экстремум с заданной даты
 int          GetCountFormedExtr() {return (_bufferExtr.Total());};              // возвращает количество сформированных экстремумов  
};
 
 // кодирование методов класса
 
 // кодирования приватных методов класса
 void CExtrContainer::AddExtrToContainer(CExtremum *extr)    // добавляет экстремум в контейнер
  {
   // если в контейнере еще не было экстремумов
   if (_bufferExtr.Total() == 0)
    {
      _bufferExtr.Add(extr);
    }
   else
    {
     CExtremum *tempExtr;
     tempExtr = _bufferExtr.At(0);
     // если предыдущий экстремум был в том же направлении
     if (tempExtr.direction == extr.direction)
      {
       // то просто обновляем экстремум в контейнере
       _bufferExtr.Update(0,extr);
      }
     // если же он противоположный, то добавляем в конец
     else
      {
       // сохраняем текущее значение
       _bufferExtr.Insert(extr,0);         
     }
   }    
  }
  
 void CExtrContainer::AddExtrToContainer(int direction,double price,datetime time)  // добавляет экстремум в контейнер
  {
    CExtremum *tempExtr;
    tempExtr = _bufferExtr.At(0);
   // если напрвление нового экстремума совпадает с направлением последнего экстремума
   if (direction == tempExtr.direction)
    {
     // то просто перезаписываем экстремум
     tempExtr.price = price;
     tempExtr.time = time;
     _bufferExtr.Update(0,tempExtr);
    }
   else
    {
     // иначе записываем новый экстремум в начало
     tempExtr.price = price;
     tempExtr.time = time;
     tempExtr.direction = direction;
     _bufferExtr.Insert(tempExtr,0);
    }
  }
  
 // формирует из данных экстремума объект структуры экстремума
 CExtremum *CExtrContainer::MakeExtremum (double price, datetime time, int direction)
  {
   CExtremum *extr = new CExtremum(direction, price, time);
   return (extr);
  }
 
 // кодирование публичных методок класса
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE/*,int sizeBuf*/)                     // конструктор класса
  {
   // сохраняем последнее время, по которое нужно догружать экстремумы
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
  }

 CExtrContainer::~CExtrContainer() // деструктор класса
  {

  }

 // метод возвращает экстремум по индексу 
 CExtremum *CExtrContainer::GetExtremum(int index)
 {
     
  if (index < 0 || index >= _bufferExtr.Total())
    {
     CExtremum *nullExtr  = new CExtremum(0,-1);    //удалить!!!
     Print("Ошибка метода GetExtrByIndex класса CExtrContainer. Индекс экстремума вне диапазона");
     return (nullExtr);
    }  
    CExtremum *extr = _bufferExtr.At(index);
  return (_bufferExtr.At(index));          
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
     AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));
    }
   //если пришел только нижний экстремум
   if (extrLow[0]>0 && extrHigh[0]==0)
    { 
     AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));
    }
   //если пришло оба экстремума
   if (extrHigh[0]>0 && extrLow[0]>0)
    { 
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