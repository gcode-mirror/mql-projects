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

// класс движения цены
class CPriceMovement : public CObject
 {
  private:
   CExtremum *_extrUp0,*_extrUp1; // экстремумы верхней линии
   CExtremum *_extrDown0,*_extrDown1; // экстремумы нижней линии
   CChartObjectTrend _moveLine; // объект класса линии
   int _moveType; // тип движения 
   long _chartID;  // ID графика
   string _symbol; // символ
   ENUM_TIMEFRAMES _period; // период
   string _lineUpName; // уникальное имя трендовой верхней линии
   string _lineDownName; // уникальное имя трендовой нижней линии
   double _percent; // процент рассчета тренда
   
   // приватные методы класса
   void GenUniqName (); // генерирует уникальное имя трендового канала
   // методы вычисления типа движения
   int IsItTrend(); // если текущее движение тренд
   int IsFlatA();   // тип флэта А
   int IsFlatB();   // тип флэта B
   int IsFlatC();   // тип флэта C
   int IsFlatD();   // тип флэта D
   int IsFlatE();   // тип флэта E
   int IsFlatF();   // тип флэта F
   int IsFlatG();   // тип флэта G
  public:
   CPriceMovement(int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // конструктор класса по экстр
  ~CPriceMovement(); // деструктор класса
   // методы класса
   int    GetMoveType () { return (_moveType); }; // возвращает тип движения 
   double GetPriceLineUp(datetime time); // возвращает цену на верхней линии по времени
   double GetPriceLineDown(datetime time); // возвращает цену на нижней линии по времени
 };

// кодирование методов класса ценовых движений

/////////приватные методы класса

void CPriceMovement::GenUniqName(void) // генерирует уникальное имя трендового канала
 {
  // генерит уникальные имена трендовых линий исходя из символа, периода и времени первого экстремума
  _lineUpName = "moveLineUp."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time);
  _lineDownName = "moveLineDown."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time);
 }
 
int CPriceMovement::IsItTrend(void) // проверяет, является ли данный канал трендовым
 {
  double h1,h2;
  double H1,H2;
  // если тренд вверх 
  if (GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
   {
    // если последний экстремум - вниз
    if (_extrDown0.time > _extrUp0.time)
     {
      H1 = _extrUp0.price - _extrDown1.price;
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrDown0.price - _extrDown1.price);
      h2 = MathAbs(_extrUp0.price - _extrUp1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )
       return (1);
     }
   
   }
  // если тренд вниз
  if (LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    
    // если  последний экстремум - вверх
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = _extrDown0.price - _extrUp1.price;    
      H2 = _extrDown1.price - _extrUp1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )    
       return (-1);
     }

   }   
   
  return (0);
 }

// кодирование методов вычисления типов ценового движения

// функции обработки типов флэтов

int CPriceMovement::IsFlatA ()  // флэт А  
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*H) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

int CPriceMovement::IsFlatB () // флэт B
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

int CPriceMovement::IsFlatC () // флэт C
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatD () // флэт D
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*H) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatE () // флэт E
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp0.price-_extrUp1.price,_percent*H) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatF () // флэт F
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price), _percent*H) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price , _percent*H)
     )
    {
     return (true);
    }
  return (false);
 } 

int CPriceMovement::IsFlatG () // флэт G
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp0.price - _extrUp1.price, _percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price), _percent*H)
     )
    {
     return (true);
    }
  return (false);
 }  

///////////// публичные методы класса

CPriceMovement::CPriceMovement(int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  int tempDir; // временная переменная для сохранения текущего движения
  // сохраняем поля класса
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _moveType = 0;
  // создаем объекты экстремумов для трендовых линий
  _extrUp0   = extrUp0;
  _extrUp1   = extrUp1;
  _extrDown0 = extrDown0;
  _extrDown1 = extrDown1;
  // генерируем уникальные имена трендовых линий
  GenUniqName();
  // обрабатываем типы движений
  tempDir = IsItTrend ();
  if (tempDir == 1)  // если найден тренд вверх
    _moveType = 1;
  if (tempDir == -1) // если найден тренд вниз
    _moveType = -1; 
  if (IsFlatA())     // если найден флэт А
    _moveType = 2;
  if (IsFlatB())     // если найден флэт B
    _moveType = 3;
  if (IsFlatC())     // если найден флэт C
    _moveType = 4;  
  if (IsFlatD())     // если найден флэт D
    _moveType = 5;
  if (IsFlatE())     // если найден флэт E
    _moveType = 6;
  if (IsFlatF())     // если найден флэт F
    _moveType = 7;
  if (IsFlatG())     // если найден флэт G
    _moveType = 8;  
  // если мы нашли движение 
  if (_moveType == 1 || _moveType == -1)  // если словили трендовое движение
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // верхняя линия
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrRed);
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // верхняя линия 
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrRed);     
    Print("Тренд = ",TimeToString(TimeCurrent()));         
   }
  else if (_moveType > 1) // если словили флэтовое движение
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // верхняя линия
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrYellow);      
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // верхняя линия     
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrYellow);      
   } 
 }
 
// деструктор класса
CPriceMovement::~CPriceMovement()
 {
  ObjectDelete(_chartID,_lineDownName);
  ObjectDelete(_chartID,_lineUpName);
 }
 
double CPriceMovement::GetPriceLineUp(datetime time) // возвращает цену на верхней линии 
 {
  return (ObjectGetValueByTime(_chartID,_lineUpName,time));
 } 
 
double CPriceMovement::GetPriceLineDown(datetime time) // возвращает цену на нижней линии
 {
  return (ObjectGetValueByTime(_chartID,_lineDownName,time));
 }

class CMoveContainer 
 {
  private:
   int _handleDE; // хэндл индикатора DrawExtremums
   int _chartID; //ID графика
   
   string _symbol; // символ
   string _eventExtrUp; // имя события прихода верхнего экстремума
   string _eventExtrDown; // имя события прихода нижнего экстремума 
   double _percent; // процент рассчета тренда
   ENUM_TIMEFRAMES _period; // период
   int    _trendNow; // флаг того, что в данный момент есть или нет тренда
   CExtrContainer *_container; // контейнер экстремумов
   CArrayObj _bufferMove;// буфер для хранения движений
   // приватные методы класса
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
  public:
   // публичные методы класса
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // конструктор класса
   ~CMoveContainer(); // деструктор класса
   // методы класса
   CPriceMovement *GetMoveByIndex (int index); // возвращает указатель на тренд по индексу
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
CPriceMovement * CMoveContainer::GetMoveByIndex(int index)
 {
  CPriceMovement *curTrend = _bufferMove.At(_bufferMove.Total()-1-index);
  if (curTrend == NULL)
   PrintFormat("%s не нулевой индекс i=%d, total=%d", MakeFunctionPrefix(__FUNCTION__), index, _bufferMove.Total());
  return (curTrend);
 }
 
// метод очищает буфер движений
void CMoveContainer::RemoveAll(void)
 {  
  _bufferMove.Clear();
 }
 
// метод обновляет экстремум и тренд
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CPriceMovement *temparyMove;
  CPriceMovement *previewMove;
  
  // догружаем экстремумы
  _container.UploadOnEvent(sparam,dparam,lparam);
  previewMove = GetMoveByIndex(0);
  // если последний экстремум - нижний
  if (sparam == _eventExtrDown)
   {
     // получаем значение текущего движения
     temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_percent );     
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
           // то добавляем его в буфер
           _bufferMove.Add(temparyMove);
          }
        }     
   }
  // если последний экстремум - верхний
  if (sparam == _eventExtrUp)
   {
     temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_percent );
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
           // то добавляем его в буфер
           _bufferMove.Add(temparyMove);
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
   CPriceMovement *temparyMove; 
    // загружаем тренды 
    _container.Upload(0);
    // если удалось прогрузить все экстремумы на истории
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // получаем количество экстремумов
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // получаем последнее значение экстремума
      // проходим по экстремумам и заполняем буфер движений
      for (i=0; i < extrTotal-4; i++)
       {
        // если последнее направление экстремума - вверх
        if (dirLastExtr == 1)
         {
           temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_percent );
           if (temparyMove != NULL)
            {
             // если обнаружили тренд
             if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
              {
               // добавляем тренд в буфер
               _bufferMove.Add(temparyMove);
               // и возвращаем true
               Print("таки нашли тренд 1");
               return (true);
              }
             // если это флэт
             else if (temparyMove.GetMoveType() > 1)
              {
               // то просто добавляем его в буфер движений
               _bufferMove.Add(temparyMove);
               Print("Таки нашли флэт 1");
              }
            }
         }
        // если последнее направление экстремума - вниз
        if (dirLastExtr == -1)
         {
           temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_percent );         
           if (temparyMove != NULL)
            {
             // если словили тренд
             if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
              {
                // то добавляем тренд в буфер
                _bufferMove.Add(temparyMove);
                Print("таки нашли тренд 2");
                // и возвращаем true
                return (true);
              }
             else if (temparyMove.GetMoveType() > 1)
              { 
               // то просто добавляем движение в буфер движения
               _bufferMove.Add(temparyMove);
               Print("таки нашли флэт 2");
              }
              
            }
         }
        dirLastExtr = -dirLastExtr; 
       }
      return (true);
     }
   return (false);
 }