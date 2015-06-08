//+------------------------------------------------------------------+
//|                                                CTrendChannel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Класс трендовых линий и каналов                                  |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <DrawExtremums/CExtremum.mqh> // класс экстремумов
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <Arrays\ArrayObj.mqh> // класс динамических массивов
#include <StringUtilities.mqh> // строковые утилиты
#include "CMove.mqh" // класс движения

class CMoveContainer
 {
  private:
   int    _handleDE; // хэндл индикатора DrawExtremums
   int    _chartID;  // ID графика
   string _symbol;   // символ
   string _eventExtrUp;   // имя события прихода верхнего экстремума
   string _eventExtrDown; // имя события прихода нижнего экстремума 
   double _percent; // процент рассчета тренда
   ENUM_TIMEFRAMES _period; // период
   int    _trendNow; // флаг того, что в данный момент есть или нет тренда
   CExtrContainer *_container; // контейнер экстремумов
   CArrayObj _bufferMove;// буфер для хранения движений
   CMove *_prevTrend; // указатель на предыдущий тренд
   CMove *_curTrend; // текущий тренд
   // приватные методы класса
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
  public:
   // публичные методы класса
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // конструктор класса
   ~CMoveContainer(); // деструктор класса
   // методы класса
   CMove *GetMoveByIndex (int index); // возвращает указатель на движение по индексу
   CMove *GetTrendByIndex (int index); // возвращает тренд по индексу
   CMove *GetLastTrend(void); // возвращает значение последнего тренда
   bool IsTrendNow () { return (_trendNow); }; // возвращает true, если в текущий момент - тренд, false - если в текущий момент - нет тренд
   int  GetTotal () { return (_bufferMove.Total() ); }; // возвращает количество движений на текущий момент в буфере
   void RemoveAll (); // очищает буфер движений
   void UploadOnEvent (string sparam,double dparam,long lparam); // метод догружает экстремумы по событиям 
   bool UploadOnHistory (); // метод загружает тренды в буфер на истории 
 };

// кодирование методов класса CTrendChannel
CMoveContainer::CMoveContainer(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _container = new CExtrContainer(handleDE,symbol,period);
  // формируем уникальные имена событий
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
 } 
  
// деструктор класса
CMoveContainer::~CMoveContainer()
 {
  _bufferMove.Clear();
  delete _container;
 }
 
// возвращает указатель на тренд по индексу
CMove * CMoveContainer::GetMoveByIndex(int index)
 {
  CMove *curTrend = _bufferMove.At(_bufferMove.Total()-1-index);
  if (curTrend == NULL)
   PrintFormat("%s не нулевой индекс i=%d, total=%d", MakeFunctionPrefix(__FUNCTION__), index, _bufferMove.Total());
  return (curTrend);
 }
 
// возвращает тренд по индексу
CMove * CMoveContainer::GetTrendByIndex(int index)
 {
  if (index == 0) // если надо вернуть указатель на последний тренд
   {
    return (_curTrend);
   }
  if (index == 1) // если надо вернуть указатель на предыдущий тренд
   {
    return (_prevTrend); 
   }
  return NULL;
 }

// возвращает указатель на последний тренд
CMove * CMoveContainer::GetLastTrend(void)
 {
  int total = _bufferMove.Total();
  CMove *tempMove;
  for (int i=0;i<total;i++)
   {
    tempMove = _bufferMove.At(i);
    if (tempMove.GetMoveType() == MOVE_TREND_DOWN || tempMove.GetMoveType() == MOVE_TREND_UP)
     {             
      return (tempMove); 
     }
   }
  return (NULL);
 } 
 
// метод очищает буфер движений
void CMoveContainer::RemoveAll(void)
 {
  int countTrend=0; // количество найденных трендов  
  int last_index; // индекс второго тренда
  CMove *move;
  // проходим от конца буфера движений и удаляем всё до предыдущего тренда
  for(int i=0;i<_bufferMove.Total();i++)
   {
    move = _bufferMove.At(i);
    // если нашли тренд
    if (move.GetMoveType() == 1 || move.GetMoveType() == -1)
     countTrend++;
    // если нашли второй тренд
    if (countTrend == 2)
     {
      last_index = i-1;
      break;
     }
   }
  // очищаем буфер движений до второго тренда
  _bufferMove.DeleteRange(0,last_index);
 }
 
// метод обновляет экстремум и тренд
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CMove *temparyMove;
  CMove *lastTrend;
  datetime trendHighTime,trendLowTime;
  datetime flatHighTime,flatLowTime;
  
  // догружаем экстремумы
  _container.UploadOnEvent(sparam,dparam,lparam);
  // если последний экстремум - нижний
  if (sparam == _eventExtrDown)
   {
     // получаем значение текущего движения
     temparyMove = new CMove(_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     // если удалось получить текущее движение
     if (temparyMove != NULL)
        {
         // если словили тренд
         if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
          {
           // сохраняем текущий тренд
           _trendNow = temparyMove.GetMoveType();
           // то очищаем буфер
           RemoveAll();
           // и добавляем тренд в буфер
           _bufferMove.Add(temparyMove);
          }
         // иначе если  это флэт
         else if (temparyMove.GetMoveType() > 1)
          {
           // получаем значение последнего тренда
           lastTrend = GetLastTrend();
           if (lastTrend != NULL)
            {
             // сохраняем времена экстремумов
             trendHighTime = lastTrend.GetMoveExtremum(EXTR_HIGH_1).time;
             trendLowTime = lastTrend.GetMoveExtremum(EXTR_LOW_1).time;
             flatHighTime = temparyMove.GetMoveExtremum(EXTR_HIGH_1).time;
             flatLowTime = temparyMove.GetMoveExtremum(EXTR_LOW_1).time;
             // если ни один экстремум тренда не совпадает с экстремумами флэта
             if (trendHighTime != flatHighTime && trendLowTime != flatLowTime)
              {
               // то добавляем его в буфер
               _bufferMove.Add(temparyMove);
              }
             else
              {
               delete temparyMove;
              }
            }
           else
            {
             _bufferMove.Add(temparyMove);
            }
          }
        }     
   }
  // если последний экстремум - верхний
  if (sparam == _eventExtrUp)
   {
     temparyMove = new CMove(_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     if (temparyMove != NULL)
        {
         // если словили тренд
         if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
          {
           // то очищаем буфер
           RemoveAll();          
           // и добавляем тренд в буфер
           _bufferMove.Add(temparyMove);
          }
         // иначе если  это флэт
         else if (temparyMove.GetMoveType() > 1)
          {
           // получаем значение последнего тренда
           lastTrend = GetLastTrend();
           if (lastTrend != NULL)
            {
             // сохраняем времена экстремумов
             trendHighTime = lastTrend.GetMoveExtremum(EXTR_HIGH_1).time;
             trendLowTime = lastTrend.GetMoveExtremum(EXTR_LOW_1).time;
             flatHighTime = temparyMove.GetMoveExtremum(EXTR_HIGH_1).time;
             flatLowTime = temparyMove.GetMoveExtremum(EXTR_LOW_1).time;          
             // если ни один экстремум тренда не совпадает с экстремумами флэта
             if (trendHighTime != flatHighTime && trendLowTime != flatLowTime)
              {
               // то добавляем его в буфер
               _bufferMove.Add(temparyMove);
              }
             else
              {
               delete temparyMove;
              }
            }
           else
            {
             // то добавляем его в буфер
             _bufferMove.Add(temparyMove);
            }
            
          }
        }   
   }
 }
 
// метод загружает тренды на истории
bool CMoveContainer::UploadOnHistory(void)
 { 
   int i;
   int extrTotal;
   int dirLastExtr;
   int highIndex=0;
   int lowIndex=0;
   int countTrend=0; // счетчик трендов 
   bool jumper=true;
   CMove *temparyMove; 
   CMove *moveForPrevTrend = NULL; // указатель для хранения предыдущего движения
    // загружаем тренды 
    for (int attempts=0;attempts<25;attempts++)
     {
      _container.Upload(0);
      Sleep(100);
     }
    // если удалось прогрузить все экстремумы на истории
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // получаем количество экстремумов
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // получаем последнее значение экстремума
      // проходим по экстремумам и заполняем буфер движений
      for (i=0; i < extrTotal-4; i++)
       {
        // создаем объект движения
        temparyMove = new CMove(_chartID,_symbol,_period,_container.GetFormedExtrByIndex(highIndex,EXTR_HIGH),
                                                         _container.GetFormedExtrByIndex(highIndex+1,EXTR_HIGH),
                                                         _container.GetFormedExtrByIndex(lowIndex,EXTR_LOW),
                                                         _container.GetFormedExtrByIndex(lowIndex+1,EXTR_LOW),_percent );
        if (temparyMove != NULL)
           {
            // если обнаружили тренд
            if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
               {
                // добавляем тренд в буфер
                _bufferMove.Add(temparyMove);
                countTrend ++;
                // если количество трендов - 1
                if (countTrend == 1)
                 {
                  _prevTrend = temparyMove;
                 }
                // если количество трендов - 2
                if (countTrend == 2)
                 {
                  _curTrend = temparyMove;
                  return (true);
                 }
               }
            // если это флэт
            else if (temparyMove.GetMoveType() > 1 )
               {
                if (moveForPrevTrend == NULL)
                 {
                 // то просто добавляем его в буфер движений
                 _bufferMove.Add(temparyMove);
                 }
                else
                 {
                  if (moveForPrevTrend.GetMoveType() != 1 && moveForPrevTrend.GetMoveType() != -1)
                   {
                    // то просто добавляем его в буфер движений
                    _bufferMove.Add(temparyMove);                   
                   }
                 }
               }
            }                                                         
                                                         
        // если последний экстремум верхний
        if (dirLastExtr == 1)
         {
          // если jumper == true, то увеличивать индекс 
          if (jumper)
           {
            highIndex++;
           }
          else
           {
            lowIndex++;
           }
           jumper = !jumper;
         }
        // если последний экстремум нижний
        if (dirLastExtr == -1)
         {
          // если jumper == true, то увеличивать индекс 
          if (jumper)
           {
            lowIndex++;
           }
          else
           {
            highIndex++;
           }
           jumper = !jumper;
         }        
        moveForPrevTrend = temparyMove; // сохраняем предыдущее движение
       }
      }
     return (false); 
    }