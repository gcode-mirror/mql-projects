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
#include <StringUtilities.mqh>
#include <CompareDoubles.mqh>              // для сравнения вещественных чисел
#include <DrawExtremums/CExtremum.mqh>     // для массива эктсремумов
#include <Arrays\ArrayObj.mqh>

// перечисление типов эктсремумов
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

class CExtrContainer 
{
 private:
 // буферы класса
 double   _extrHigh[];    // буфер высоких экстремумов
 double   _extrLow [];    // буфер низких эксремумов
 double   _lastExtrSignal[];    // буфер последнего сформированного экстремума экстремума
 double   _prevExtrSignal[];    // буфер формирующегося экстремума
 double   _extrBufferHighTime[];// буффер времени экстремумов
 double   _extrBufferLowTime[]; // буффер времени экстремумов
 string   _symbol;
 ENUM_TIMEFRAMES _period;
 
 CArrayObj       _bufferExtr;       // массив для хранения экстремумов  
 CExtremum       *extrTemp;         
 // приватные поля класса
 int      _handleDE;                // хэндл индикатора DrawExtremums
 int      _historyDepth;            // глубина истории
 int      _countHigh;
 int      _countLow;
 public:
 CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period);          // конструктор класса контейнера экстремумов
 ~CExtrContainer();                                                                   // деструктор класса контейнера экстремумов
  
 // методы класса
 int          GetCountByType(ENUM_EXTR_USE extr_use);                          // возвращает количесво нижних/верхних экстремумов в контейнере
 CExtremum    *GetExtrByTime(datetime time);
 void         AddExtrToContainer(CExtremum *extr);                            // добавляет экстремум в контейнер
 CExtremum    *MakeExtremum (double price, datetime time, int direction, STATE_OF_EXTR state);
 CExtremum    *GetExtremum (int index);
 bool         Upload();
 bool         UploadOnEvent(string sparam);
 int          GetCountFormedExtr() {return (_bufferExtr.Total()-1);};         // возвращает количество сформированных экстремумов
 CExtremum    *GetExtrByIndex(int index, ENUM_EXTR_USE extr_use);             // возвращает экстремум по индексу, при учете extr_use   
};
 
 // кодирование методов класса
//+------------------------------------------------------------------+
// добавляет экстремум в контейнер
//+------------------------------------------------------------------+
void CExtrContainer::AddExtrToContainer(CExtremum *extr)    
{
 // если в контейнере еще не было экстремумов
 if (_bufferExtr.Total() == 0)
 {
  _bufferExtr.Add(extr);
  if(extr.direction == 1)
  _countHigh++;
  if(extr.direction == -1)
   _countLow++;
 }
 else
 {
  CExtremum *tempExtr;
  tempExtr = _bufferExtr.At(0);
  //if(extr.price == 0)
  // Print("Попытка добавить пустой экстремум время последнего = ", tempExtr.time);
  // если предыдущий экстремум был в том же направлении
  if (tempExtr.direction == extr.direction)
  {
   // то просто обновляем экстремум в контейнере
   _bufferExtr.Update(0,extr);
    delete tempExtr;
  }
  // если же он противоположный, то добавляем в начало
  else
  {
   //изменяем статус последнего экстремума на сформированный
   tempExtr.state = EXTR_FORMED; //рассчитывая на то, что он изменит состояние элемента, находящегося в массиве
   // сохраняем текущее значение
   _bufferExtr.Insert(extr,0);  
   if(extr.direction == 1)
    _countHigh++;
   if(extr.direction == -1)
    _countLow++;    
  }
 }    
}
//+------------------------------------------------------------------+  
// формирует из данных экстремума объект структуры экстремума        |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::MakeExtremum (double price, datetime time, int direction, STATE_OF_EXTR state) 
{
 CExtremum *extr = new CExtremum(direction, price, time, state);
 return (extr);
}

//+------------------------------------------------------------------+
// Конструктор                                                       |
//+------------------------------------------------------------------+
 CExtrContainer::CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period)                     // конструктор класса
  {
   _handleDE = handleExtremums;
   _symbol = symbol;            
   _period = period;
   _countHigh = 0;
   _countLow = 0;
   Upload();
   //если баров на истории меньше тысячи, скопировать то, что есть
  }

//+------------------------------------------------------------------+
// Деструктор                                                       |
//+------------------------------------------------------------------+
CExtrContainer::~CExtrContainer() // деструктор класса
{
 _bufferExtr.Clear();
 delete extrTemp;
}


//+------------------------------------------------------------------+
// метод возвращает экстремум по индексу                             |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtremum(int index)
{   
 if (index < 0 || index >= _bufferExtr.Total())
 {
  CExtremum *nullExtr  = new CExtremum(0,-1, 0, EXTR_NO_TYPE);    //удалить!!!
  Print("Ошибка метода GetExtrByIndex класса CExtrContainer. Индекс экстремума вне диапазона");
  return (nullExtr);
 }  
 CExtremum *extr = _bufferExtr.At(index);
 return (extr);          
}
 
 
//+------------------------------------------------------------------+
// обновляет данные экстремумов по всей истории                      |
//+------------------------------------------------------------------+
bool CExtrContainer::Upload()       
{
 int bars = Bars(_symbol,_period);
 //bars = 420;
 _historyDepth = bars;
 int copiedHigh     = _historyDepth;
 int copiedLow      = _historyDepth;
 int copiedHighTime = _historyDepth;
 int copiedLowTime  = _historyDepth;
 Sleep(10000);
 if ( CopyBuffer(_handleDE, 2, 0, 1, _lastExtrSignal) < 1
   || CopyBuffer(_handleDE, 3, 0, 1, _prevExtrSignal) < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буфер индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);           
 }
            
 copiedHigh       = CopyBuffer(_handleDE, 0, 0, _historyDepth, _extrHigh);   
 copiedHighTime   = CopyBuffer(_handleDE, 4, 0, _historyDepth, _extrBufferHighTime);     
 copiedLow        = CopyBuffer(_handleDE, 1, 0, _historyDepth, _extrLow);
 copiedHighTime   = CopyBuffer(_handleDE, 5, 0, _historyDepth, _extrBufferLowTime); 
 
 if (copiedHigh     != _historyDepth || copiedLow != _historyDepth ||
     copiedHighTime != _historyDepth || copiedLowTime != _historyDepth)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буферы индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);
 }
 else
 {
  ArraySetAsSeries(_extrHigh, true);
  ArraySetAsSeries(_extrLow, true);
  ArraySetAsSeries(_extrBufferHighTime, true);
  ArraySetAsSeries(_extrBufferLowTime, true);
  //Заполняем контейнер экстремумов с истории historyDepth
  for(int i = _historyDepth - 1; i >=  0; i--)
  {
   //Если на i-ом баре было обнаружено оба экстремума
   if(_extrHigh[i]!=0 && _extrLow[i]!=0)
   {
    // если верхний пришел раньше
    if (_extrBufferHighTime[i] < _extrBufferLowTime[i])
    {
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));                                                    
    }
    // если нижний пришел раньше
    if (_extrBufferHighTime[i] > _extrBufferLowTime[i])
    {
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));       
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));             
    }
   } 
   //Если обнаружен один из экстремумов 
   else
   {  
    if(_extrHigh[i]!=0) //если это верхний экстремум
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));
    if(_extrLow[i]!=0)  //если это нижний экстремум
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));
   }
  }
  //проверим есть ли формирующийся экстремум?

  if(_lastExtrSignal[0] != 0)
   AddExtrToContainer(MakeExtremum(_lastExtrSignal[0], _extrBufferHighTime[0], 1, EXTR_FORMING));
  if(_prevExtrSignal[0] != 0)
   AddExtrToContainer(MakeExtremum(_prevExtrSignal[0], _extrBufferLowTime[0], -1, EXTR_FORMING));
 }
 return (true);
}



//+------------------------------------------------------------------+
// Добавляет новый эктсремум по событию                              |
//+------------------------------------------------------------------+
bool  CExtrContainer::UploadOnEvent(string sparam)
{
 int copied;
 int copiedTime;
 //загрузим цену из буфера сформированных экстремумов High
 if(sparam == "EXTR_UP"||sparam == "EXTR_UP_FORMED")
 {
  copied       = CopyBuffer(_handleDE, 2, 0, 1, _extrHigh);
  copiedTime   = CopyBuffer(_handleDE, 4, 0, 1, _extrBufferHighTime);  
  if(copied < 0 || copiedTime < 0)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буферы индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
   return (false);
  }
  if(_extrHigh[0]!=0)
  AddExtrToContainer(MakeExtremum(_extrHigh[0], datetime(_extrBufferHighTime[0]), 1, EXTR_FORMING));
  if(_extrHigh[0] == 0)
  Print("Попытка добавить пустой экстремум   ", _extrHigh[0]);
 }
 if(sparam == "EXTR_DOWN"||sparam == "EXTR_DOWN_FORMED")
 {
  copied       = CopyBuffer(_handleDE, 3, 0, 1, _extrLow);
  copiedTime   = CopyBuffer(_handleDE, 5, 0, 1, _extrBufferLowTime);  
  if(copied < 0 || copiedTime < 0)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буферы индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
   return (false);
  }
  if(_extrLow[0]!=0)
  AddExtrToContainer(MakeExtremum(_extrLow[0], datetime(_extrBufferLowTime[0]), -1, EXTR_FORMING));
 }
 return true;
} 

//+------------------------------------------------------------------+
// Возвращяает экстремум по индексу и типу                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByIndex(int index, ENUM_EXTR_USE extr_use)
{
 CExtremum *extrERROR = new CExtremum(0,-1,0,EXTR_NO_TYPE);
 int k = 0;             //количество экстремумов соответствующего направления
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  Print(" Индекс вне границ массива _bufferExtr.Total = ", _bufferExtr.Total());
  return extrERROR;
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
   return(GetExtremum(index));
  break;
  case EXTR_HIGH:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return GetExtremum(i);
     }
     k++;
    }
   }
   return extrERROR;
  break;
  case EXTR_LOW:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return GetExtremum(i);
     }
     k++;
    }
   }
   return extrERROR;
  break;
  default:
  return extrERROR;
  break;
 }
}


//+------------------------------------------------------------------+
// Возвращает экстремум по времени                                   |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByTime(datetime time)
{
 CExtremum *extr;
 CExtremum *errorExtr = new CExtremum(0, -1, 0, 2);
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return extr;
  }
 }
 return errorExtr;
}


//+------------------------------------------------------------------+
// метод возвращает количество элементов по типу                     |
//+------------------------------------------------------------------+
int CExtrContainer::GetCountByType(ENUM_EXTR_USE extr_use)
{
 switch (extr_use)
 {
  case EXTR_BOTH:
   return _bufferExtr.Total();
  break;
  case EXTR_HIGH:
   return _countHigh;
  break;
  case EXTR_LOW:
   return _countLow;
  break;
  default:
   return -1;
  break;
 }
}