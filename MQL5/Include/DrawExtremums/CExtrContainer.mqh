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
#include <StringUtilities.mqh>             // строковые константы
#include <CompareDoubles.mqh>              // для сравнения вещественных чисел
#include <DrawExtremums/CExtremum.mqh>     // для массива эктсремумов
#include <Arrays\ArrayObj.mqh>             // класс динамических массивов

// перечисление типов эктсремумов
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

class CExtrContainer  : public CObject
{
 private:
 // буферы класса
 double   _extrHigh[];          // буфер высоких экстремумов
 double   _extrLow [];          // буфер низких эксремумов
 double   _lastExtrSignal[];    // буфер последнего сформированного экстремума экстремума
 double   _prevExtrSignal[];    // буфер формирующегося экстремума
 double   _extrBufferHighTime[];// буфер времени экстремумов
 double   _extrBufferLowTime[]; // буфер времени экстремумов
 string   _symbol;              // символ, на котром был создан контейнер
 string   _eventExtrUp;         // имя подходящего события для добавления верхнего экстремума     
 string   _eventExtrDown;       // имя подходящего события для добавления нижнего экстремума 
 ENUM_TIMEFRAMES _period;
 bool    _iUploaded;
 
 CArrayObj       _bufferExtr;       // массив для хранения экстремумов  
 CExtremum       *extrTemp;         
 // приватные поля класса
 int      _handleDE;                // хэндл индикатора DrawExtremums
 int      _historyDepth;            // глубина истории
 int      _countHigh;
 int      _countLow;
 int      _historyLengh;            // Количество баров на истории которые необходимо прогрузить 
  
 // приватные методы класса
 string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
 public:
 CExtrContainer(int handleExtremums, string symbol, 
               ENUM_TIMEFRAMES period, int history_lengh = -1);               // конструктор класса контейнера экстремумов
 ~CExtrContainer();                                                           // деструктор класса контейнера экстремумов
  
 // методы класса
 int          GetCountByType(ENUM_EXTR_USE extr_use);                         // возвращает количесво нижних/верхних экстремумов в контейнере
 int          GetExtrIndexByTime (datetime time);                             // возвращает индекс экстремума 
 CExtremum    *GetExtrByTime(datetime time);                                  // возвращает индекс экстремума согласно времении или более ранний
 void         AddExtrToContainer(CExtremum *extr);                            // добавляет экстремум в контейнер
 bool         AddNewExtrByTime(datetime time);                                // добавляет экстремум по времени
 bool         Upload(int bars = -1);
 bool         UploadOnEvent(string sparam,double dparam,long lparam);   
 bool         isUploaded();      
 int          GetCountFormedExtr() {return (_bufferExtr.Total()-1);};         // возвращает количество сформированных экстремумов
 CExtremum    *GetExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH); // возвращает экстремум по индексу, при учете extr_use
 CExtremum    *GetLastFormedExtr(ENUM_EXTR_USE extr_use);                     // возвращает последний сформированный по типу
 CExtremum    *GetLastFormingExtr();                                          // возвращает последний формирующийся
 CExtremum    *GetFormedExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH);
 ENUM_EXTR_USE GetPrevExtrType(void);
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
// Конструктор                                                       |
//+------------------------------------------------------------------+
CExtrContainer::CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period, int history_lengh = -1)                     // конструктор класса
{
 _handleDE = handleExtremums;                 
 _symbol = symbol;            
 _period = period;
 _countHigh = 0;
 _countLow = 0;
 _iUploaded = false;
 _historyDepth = history_lengh;    
 _eventExtrUp =  GenEventName("EXTR_UP");
 _eventExtrDown = GenEventName("EXTR_DOWN");
 if(!Upload(_historyDepth))
  StringFormat("%s Не удалось обновить контейнер!", MakeFunctionPrefix(__FUNCTION__));
}

//+------------------------------------------------------------------+
// Деструктор                                                        |
//+------------------------------------------------------------------+
CExtrContainer::~CExtrContainer() // деструктор класса
{ 
 Print(__FUNCTION__," Очищение буфера.");
 
 for(int i = _bufferExtr.Total()-1; i >= 0; i--)
  delete _bufferExtr.At(i);
 _bufferExtr.Clear();
 delete extrTemp;
}

  
//+--------------------------------------------------------------------------+
// Возвращает состояние после последней загрузки, (если загружен - true)     |
// Стоит использовать данную проверку перед использованием контейнера        |
//                                         например на OnTick()/OnCalculate()|
//+--------------------------------------------------------------------------+
bool CExtrContainer::isUploaded()
{
 if(!_iUploaded || _bufferExtr.Total() < 1)
 { 
  Upload(_historyDepth);
  //Print ("Произошла перезаугрцзка Upload() Количество элементов в массиве ", _bufferExtr.Total(), "_iUploaded = ", _iUploaded);
 }
 if(_iUploaded)
  return true;
 else 
  return false;
}

  
//+------------------------------------------------------------------+
// обновляет данные экстремумов по всей истории                      |
//+------------------------------------------------------------------+
bool CExtrContainer::Upload(int bars = -1)       
{
 //if(isUploaded())
 _bufferExtr.Clear();
 if(bars == -1)
 {
   bars = Bars(_symbol,_period);
  _historyDepth = bars;
 }
 int copiedHigh     = _historyDepth;
 int copiedLow      = _historyDepth;
 int copiedHighTime = _historyDepth;
 int copiedLowTime  = _historyDepth;
 if ( CopyBuffer(_handleDE, 2, 0, 1, _lastExtrSignal) < 1
   || CopyBuffer(_handleDE, 3, 0, 1, _prevExtrSignal) < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буферы формирующихся экстремумов индикатора DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
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
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));                                                    
    }
    // если нижний пришел раньше
    if (_extrBufferHighTime[i] > _extrBufferLowTime[i])
    {   
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));       
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));             
    }
   } 
   //Если обнаружен один из экстремумов 
   else
   {  
    if(_extrHigh[i]!=0) //если это верхний экстремум  
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));
    if(_extrLow[i]!=0)  //если это нижний экстремум
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));
   }
  }
  //проверим есть ли формирующийся экстремум?
  if(_lastExtrSignal[0] != 0)
   AddExtrToContainer(new CExtremum(1, _lastExtrSignal[0],datetime(_extrBufferHighTime[0]),EXTR_FORMING));
  if(_prevExtrSignal[0] != 0)
   AddExtrToContainer(new CExtremum(-1, _prevExtrSignal[0],datetime(_extrBufferLowTime[0]),EXTR_FORMING));
 }
 Print("Контейнер эктремумов на ",PeriodToString(_period)," обновлен. Всего: ",_bufferExtr.Total());
 _iUploaded = true;
 return (true);
}

//+------------------------------------------------------------------+
// Добавляет новый экстремум по событию                              |
//+------------------------------------------------------------------+
bool  CExtrContainer::UploadOnEvent(string sparam,double dparam,long lparam)
{
 CExtremum *lastExtr;
 // если пришел новый экстремум High
 if (sparam == _eventExtrUp)
  {
   lastExtr =  new CExtremum(1, dparam, datetime(lparam), EXTR_FORMING); 
   if (lastExtr == NULL)
    {
     delete lastExtr;
     return false;
    }
   AddExtrToContainer(lastExtr);
    return true;
  } 
 // если пришел новый экстремум Low
 if (sparam == _eventExtrDown)
  {
   lastExtr = new CExtremum(-1, dparam, datetime(lparam), EXTR_FORMING); 
   if (lastExtr == NULL)
   {
    delete lastExtr;
    return false;
   }
   AddExtrToContainer(lastExtr);
    return true;
  }  
 return false;
} 

//+------------------------------------------------------------------+
// Возвращяает экстремум по индексу и типу                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH)
{
 int k = 0;             //количество экстремумов соответствующего направления
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
    return(_bufferExtr.At(index));
  break;
  case EXTR_HIGH:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  case EXTR_LOW:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  default:
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
 }
}


//+------------------------------------------------------------------+
// Возвращяае только сформированный экстремум по индексу и типу                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetFormedExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH)
{
 int k = 0;             //количество экстремумов соответствующего направления
 int in_index = index + 1;
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
   return(_bufferExtr.At(in_index));
  break;
  case EXTR_HIGH:
   for(int i = 1; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  case EXTR_LOW:
   for(int i = 1; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  default:
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
 }
}

//+------------------------------------------------------------------+
// Возвращает индекс экстремума по времени                           |
//+------------------------------------------------------------------+
int CExtrContainer::GetExtrIndexByTime(datetime time)
{
 CExtremum *extr;
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return i;
  }
 }
 return -1;
}

//+------------------------------------------------------------------+
// Возвращает экстремум по времени                                   |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByTime(datetime time)
{
 CExtremum *extr;
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return extr;
  }
 }
 return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
}


//+-----------------------------------------------------------------------+
// Метод добавляет новый экстремум по хэндлу индикатора по заданной дате  |
//+-----------------------------------------------------------------------+
bool CExtrContainer::AddNewExtrByTime(datetime time)
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
  log_file.Write(LOG_DEBUG, 
  StringFormat("%s Не удалось прогузить буфер экстремумов. Всего = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return (false);
 } 
  
 timeHigh = datetime(extrHighTime[0]);
 timeLow  = datetime(extrLowTime[0]);
 //если пришел только верхний экстремум
 if (extrHigh[0]>0 && extrLow[0]==0)
 {
  AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));   
 }
 //если пришел только нижний экстремум
 if (extrLow[0]>0 && extrHigh[0]==0)
 { 
  AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));
 }
 //если пришло оба экстремума
 if (extrHigh[0]>0 && extrLow[0]>0)
 { 
  // если верхний пришел раньше
  if (extrHighTime[0] < extrLowTime[0])
  {
   AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));
   AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));                                                    
  }
  // если нижний пришел раньше
  if (extrHighTime[0] > extrLowTime[0])
  {      
   AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));       
   AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));             
  }      
 }     
 return (true);
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
 
 
//+------------------------------------------------------------------+  
// Определение типа последнего сформированного экстремума            |
//+------------------------------------------------------------------+
ENUM_EXTR_USE CExtrContainer::GetPrevExtrType(void)
{
 if(_bufferExtr.Total()!= 0)
 {
  CExtremum *extr = _bufferExtr.At(1);
  switch ( int(extr.direction) )
  {
   case 1:
    return EXTR_HIGH;
   case -1:
    return EXTR_LOW;
  }
 }
 return EXTR_NO;
}

//+------------------------------------------------------------------+
// Получить последний сформированный экстремум                       |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetLastFormedExtr(ENUM_EXTR_USE extr_use)
{
 if(_bufferExtr.Total() < 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s В контейнере недостаточно элементов чтобы обратиться к сформированному. Всего = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
 }     
 switch (extr_use)
 {
  case EXTR_BOTH:
   return _bufferExtr.At(1);
  break;
  case EXTR_HIGH:
   if(GetPrevExtrType() == EXTR_HIGH)   //Если последний экстремум HIGH. значит он формирующийся
    return GetExtrByIndex(1, EXTR_HIGH);//Возвращаем последний свформированный HIGH
   if(GetPrevExtrType() == EXTR_LOW)    //Если последний экстремум LOW. значит последний HIGH сформированный
    return GetExtrByIndex(0, EXTR_HIGH);
   return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
  break;
  case EXTR_LOW:
   if(GetPrevExtrType() == EXTR_LOW)    //Если последний экстремум LOW. значит он формирующийся
    return GetExtrByIndex(1, EXTR_LOW); //Возвращаем последний свформированный LOW
   if(GetPrevExtrType() == EXTR_HIGH)   //Если последний экстремум HIGH. значит последний LOW сформированный
    return GetExtrByIndex(0, EXTR_LOW);
   return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
  break;
 }
 return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
}
CExtremum *CExtrContainer::GetLastFormingExtr()
{
 if(_bufferExtr.Total() == 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s В контейнере недостаточно элементов чтобы обратиться формирующемуся экстремуму. Всего = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
 }     
 return _bufferExtr.At(0);
}