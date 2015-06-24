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

class CMoveContainer: public CObject
 {
  private:
   int    _handleDE; // хэндл индикатора DrawExtremums
   int    _chartID;  // ID графика
   int    _countMoves; // счетчик движений
   string _symbol;   // символ
   string _eventExtrUp;   // имя события прихода верхнего экстремума
   string _eventExtrDown; // имя события прихода нижнего экстремума
   string _trend_up_name; // имя верхней линии текущего тренда
   string _trend_down_name; // имя нижней линии текущего тренда
   double _percent; // процент рассчета тренда
   ENUM_TIMEFRAMES _period; // период
   int    _trendNow; // флаг того, что в данный момент есть или нет тренда
   bool   _isHistoryUploaded; // флаг того, что история была подгружена успешно
   CExtrContainer *_container; // контейнер экстремумов
   CArrayObj _bufferMove;// буфер для хранения движений
   CMove *_prevTrend; // указатель на предыдущий тренд
   CMove *_curTrend; // текущий тренд
   CChartObjectTrend _currentTrendLine; // объект класса линии текущего тренда
   // приватные методы класса
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
   string GenTrendLineName(string lineName) { return(lineName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
   void RemoveTrendLines (); // удаляет с графика трендовые музыки
   void DrawCurrentTrendLines (); // отображает лучи текущего тренда
  public:
   // публичные методы класса
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // конструктор класса
   ~CMoveContainer(); // деструктор класса
   // методы класса
   CMove *GetMoveByIndex (int index); // возвращает указатель на движение по индексу
   CMove *GetTrendByIndex (int index); // возвращает тренд по индексу
   CMove *GetLastTrend(void); // возвращает значение последнего тренда
   double GetPriceLineUp(datetime time); // возвращает цену на верхней линии по времени
   double GetPriceLineDown(datetime time); // возвращает цену на нижней линии по времени     
   bool IsTrendNow () { return (_trendNow); }; // возвращает true, если в текущий момент - тренд, false - если в текущий момент - нет тренд
   int  GetTotal () { return (_bufferMove.Total() ); }; // возвращает количество движений на текущий момент в буфере
   void RemoveAll (); // очищает буфер движений
   void UploadOnEvent (string sparam,double dparam,long lparam); // метод догружает экстремумы по событиям 
   bool UploadOnHistory (); // метод загружает тренды в буфер на истории 
 };
 
// кодирование приватных методов класса
void CMoveContainer::RemoveTrendLines(void) // метод удаления линий тренда
 {
  ObjectDelete(_chartID,_trend_up_name);
  ObjectDelete(_chartID,_trend_down_name);
 }

void CMoveContainer::DrawCurrentTrendLines(void) // метод отображает линии текущего тренда
 {
  CExtremum *high0,*high1; // верхние экстремумы текущего тренда
  CExtremum *low0,*low1; // нижние экстремумы текущего тренда
  CMove *lastMove;
  // получаем последнее движение
  lastMove = GetMoveByIndex(0);
  // если текущее движение - тренд
  if (lastMove.GetMoveType() == MOVE_TREND_UP || lastMove.GetMoveType() == MOVE_TREND_DOWN)
   {
    // получаем последние экстремумы из последнего движения
    high0 = lastMove.GetMoveExtremum(EXTR_HIGH_0);
    high1 = lastMove.GetMoveExtremum(EXTR_HIGH_1);
    low0  = lastMove.GetMoveExtremum(EXTR_LOW_0);
    low1  = lastMove.GetMoveExtremum(EXTR_LOW_1);            
    _currentTrendLine.Create(_chartID,_trend_up_name,0,high0.time,high0.price,high1.time,high1.price); // верхняя линия
    ObjectSetInteger(_chartID,_trend_up_name,OBJPROP_COLOR,clrViolet);
    ObjectSetInteger(_chartID,_trend_up_name,OBJPROP_RAY_LEFT,1);
    _currentTrendLine.Create(_chartID,_trend_down_name,0,low0.time,low0.price,low1.time,low1.price); // верхняя линия 
    ObjectSetInteger(_chartID,_trend_down_name,OBJPROP_COLOR,clrViolet);  
    ObjectSetInteger(_chartID,_trend_down_name,OBJPROP_RAY_LEFT,1);    
   }
 }
 
// кодирование методов класса CTrendChannel
CMoveContainer::CMoveContainer(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _countMoves = 0;
  _container = new CExtrContainer(handleDE,symbol,period);
  // формируем уникальные имена событий
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
  // формируем имена трендовых линий
  _trend_up_name = GenTrendLineName("CUR_TREND_UP");
  _trend_down_name = GenTrendLineName("CUR_TREND_DOWN");  
  _isHistoryUploaded = false;
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
 
double CMoveContainer::GetPriceLineUp(datetime time) // возвращает цену на верхней линии 
 {
  return (ObjectGetValueByTime(_chartID,_trend_up_name, time));
 } 
 
double CMoveContainer::GetPriceLineDown(datetime time) // возвращает цену на нижней линии
 {
  return (ObjectGetValueByTime(_chartID,_trend_down_name, time));
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
    if (move.GetMoveType() == MOVE_TREND_UP || move.GetMoveType() == MOVE_TREND_DOWN)
     countTrend++;
    // если нашли второй тренд
    if (countTrend == 2)
     {
      last_index = i-1;
      break;
     }
   }
  // Comment("количество удаленных объектов = ",last_index);
  // очищаем буфер движений до второго тренда
  _bufferMove.DeleteRange(0,last_index);
 }
 
// метод обновляет экстремум и тренд
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CMove *temparyMove; 
  CMove *temparyTrend;
  ENUM_PRICE_MOVE_TYPE move_type;  // 
  ENUM_PRICE_MOVE_TYPE prev_move_type;
  // догружаем экстремумы
  _container.UploadOnEvent(sparam,dparam,lparam);
  // если последний экстремум - нижний
  if (sparam == _eventExtrDown)
   {
    
     RemoveTrendLines ();
     // получаем значение текущего движения
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     
     // если удалось получить текущее движение
     if (temparyMove != NULL)
        {
         move_type = temparyMove.GetMoveType();
         // если словили тренд
         if (move_type == MOVE_TREND_UP || move_type == MOVE_TREND_DOWN)
          {
          
           // сохраняем текущий тренд
           _trendNow = temparyMove.GetMoveType();
           // то очищаем буфер
           RemoveAll();
           // и добавляем тренд в буфер
           _bufferMove.Add(temparyMove);
           // и отображаем лучи текущего тренда
           DrawCurrentTrendLines();
          }
         // иначе если  это флэт
         else if (move_type == MOVE_FLAT_A ||
                  move_type == MOVE_FLAT_B ||
                  move_type == MOVE_FLAT_C ||
                  move_type == MOVE_FLAT_D ||
                  move_type == MOVE_FLAT_E ||
                  move_type == MOVE_FLAT_F ||
                  move_type == MOVE_FLAT_G 
                 )
          {
          
           // если предыдущее движение  существует         
           if ( _bufferMove.Total() > 0 )
            {
             // получаем предыдущее движение
             temparyTrend = _bufferMove.At(0);
             // если предыдущее движение - тренд вверх или вниз
             if (temparyTrend.GetMoveType() != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {
               // то добавляем его в буфер
               _bufferMove.Add(temparyMove);

              }
             else
              {
               // если предыдущее движение всё же тренд, то проверяем, нет ли у него общих границ с текущим трендом
               if (temparyMove.GetMoveExtremum(EXTR_HIGH_0).time != temparyTrend.GetMoveExtremum(EXTR_HIGH_0).time &&
                   temparyMove.GetMoveExtremum(EXTR_LOW_0).time != temparyTrend.GetMoveExtremum(EXTR_LOW_0).time 
                  )
                   {
                    // до добавляем его в буфер 
                    _bufferMove.Add(temparyMove);
                   }
               else
                delete temparyMove;  // иначе удаляем 
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
     RemoveTrendLines ();
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     if (temparyMove != NULL)
        {
         // если словили тренд
         if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
          {
           // то очищаем буфер
           RemoveAll();          
           // и добавляем тренд в буфер
           _bufferMove.Add(temparyMove);
           // и отображаем лучи текущего тренда
           DrawCurrentTrendLines();           
          }
         // иначе если  это флэт
         else if (temparyMove.GetMoveType() == MOVE_FLAT_A || 
                  temparyMove.GetMoveType() == MOVE_FLAT_B || 
                  temparyMove.GetMoveType() == MOVE_FLAT_C || 
                  temparyMove.GetMoveType() == MOVE_FLAT_D || 
                  temparyMove.GetMoveType() == MOVE_FLAT_E || 
                  temparyMove.GetMoveType() == MOVE_FLAT_F || 
                  temparyMove.GetMoveType() == MOVE_FLAT_G 
                  )
          {
           // если есть предыдущее движение
           if (_bufferMove.Total() > 0)
            {   
             // получаем предыдущее движение
             temparyTrend = _bufferMove.At(0);
             // если предыдущее движение - не тренд    
             if (temparyTrend.GetMoveType () != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {         
               // то добавляем его в буфер
               _bufferMove.Add(temparyMove);
              }
             // если всё же тренд
             else
              {
               // если предыдущее движение всё же тренд, то проверяем, нет ли у него общих границ с текущим трендом
               if (temparyMove.GetMoveExtremum(EXTR_HIGH_0).time != temparyTrend.GetMoveExtremum(EXTR_HIGH_0).time &&
                   temparyMove.GetMoveExtremum(EXTR_LOW_0).time != temparyTrend.GetMoveExtremum(EXTR_LOW_0).time 
                  )
                   {
                    // до добавляем его в буфер 
                    _bufferMove.Add(temparyMove);
                   }
               else
                delete temparyMove;  // иначе удаляем 
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
  if(!_isHistoryUploaded || _bufferMove.Total()<=0)
  {
   int i; // для прохода по циклу
   int extrTotal; // количество экстремумов в контейнере экстремумов
   int dirLastExtr; // для направления последнего экстремума
   int highIndex=0; 
   int lowIndex=0;
   int countTrend=0; // счетчик трендов 
   bool jumper=true; 
   bool current_trend = false; // флаг, обозначающий что сейчас череда трендов
   ENUM_PRICE_MOVE_TYPE move_type; // тип текущего движения
   ENUM_PRICE_MOVE_TYPE prevMove = MOVE_UNKNOWN; // тип предыдущего движения   
   CMove *temparyMove;  // переменная для хранения предыдущего движения 
   CMove *moveForPrevTrend = NULL; // указатель для хранения предыдущего движения
   CMove *tempPrevTrend; // указатель на предыдущий тренд
   
   // загружаем экстремумы 
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
    Comment("extrTotal = ",extrTotal);
    // проходим по экстремумам и заполняем буфер движений
    for (i=0; i < extrTotal-4; i++)
    {
     // создаем объект движения
     temparyMove = new CMove("move"+_countMoves++,_chartID,_symbol,_period,_container.GetFormedExtrByIndex(highIndex,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(highIndex+1,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(lowIndex,EXTR_LOW),
                                                      _container.GetFormedExtrByIndex(lowIndex+1,EXTR_LOW),_percent );
                                                      
     // если удалось вычислить движение
     if (temparyMove != NULL)
     {
      // получаем тип текущего движения
      move_type = temparyMove.GetMoveType();
      // если обнаружили тренд вверх
      if (move_type == MOVE_TREND_UP)
      {
       Comment("Словили тренд вверх");
       // добавляем тренд в буфер
       _bufferMove.Add(temparyMove);     
       // если предыдущее движение - не тренд вверх, то значит это начало трендовой серии
       if (prevMove != MOVE_TREND_UP)
       {
        // увеличиваем количество трендовых серий
        countTrend ++;        
       }
       // если количество трендоых серий - 2, то выходим из подсчета движений на истории
       if (countTrend == 2)
       {
        _isHistoryUploaded = true;
        return (true);
       }
       // сохраняем тип предыдущего движения
       prevMove = MOVE_TREND_UP;
      }
      // если обнаружили тренд вниз
      else if (move_type == MOVE_TREND_DOWN)
      {
       Comment("Словили тренд вниз");
       // добавляем тренд в буфер
       _bufferMove.Add(temparyMove);     
       // если предыдущее движение - не тренд вниз, то значит это начало трендовой серии
       if (prevMove != MOVE_TREND_DOWN)
       {
        // увеличиваем количество трендовых серий
        countTrend ++;        
       }
       // если количество трендоых серий - 2, то выходим из подсчета движений на истории
       if (countTrend == 2)
       {
        _isHistoryUploaded = true;
        return (true);
       }
       // сохраняем тип предыдущего движения
       prevMove = MOVE_TREND_DOWN;
      }  
      // если обнаружили флэт    
      else if (move_type == MOVE_FLAT_A ||
               move_type == MOVE_FLAT_B ||
               move_type == MOVE_FLAT_C ||
               move_type == MOVE_FLAT_D ||
               move_type == MOVE_FLAT_E ||
               move_type == MOVE_FLAT_F ||
               move_type == MOVE_FLAT_G 
              )
      {
         // то просто добавляем его в буфер движений
         _bufferMove.Add(temparyMove);                
         prevMove = move_type;
      }      
     } // END 
     
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
     
    } // END FOR 
   
   }

  }
 _isHistoryUploaded = false;
 return (false);  
}