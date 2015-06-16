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


// перечисление типов движений
enum ENUM_PRICE_MOVE_TYPE
 {
  MOVE_UNKNOWN = 0,
  MOVE_TREND_UP,
  MOVE_TREND_DOWN,
  MOVE_FLAT_A,
  MOVE_FLAT_B,
  MOVE_FLAT_C,
  MOVE_FLAT_D,
  MOVE_FLAT_E,
  MOVE_FLAT_F,
  MOVE_FLAT_G
 };
 
// перечисление типов экстремумов
enum ENUM_EXTR_TYPE
 {
  EXTR_HIGH_0 = 0,
  EXTR_HIGH_1,
  EXTR_LOW_0,
  EXTR_LOW_1
 };
 
// класс движения цены
class CMove : public CObject
 {
  private:
   CChartObjectTrend _moveLine; // объект класса линии
   long _chartID;  // ID графика
   string _symbol; // символ
   ENUM_TIMEFRAMES _period; // период
   string _lineUpName; // уникальное имя трендовой верхней линии
   string _lineDownName; // уникальное имя трендовой нижней линии
   string _moveName; // имя движения (для генерации уникального имени линий)
   double _percent; // процент рассчета тренда
   // переменные для хранения данных движения
   ENUM_PRICE_MOVE_TYPE _moveType; // тип движения
   double _height; // ширина канала движения
   // приватные методы класса
   void GenUniqName (); // генерирует уникальное имя трендового канала
   void CountHeight (); // вычисляет ширину канала
   void CountMoveType (); // вычисляет тип движения
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
   CExtremum *_extrUp0,*_extrUp1; // экстремумы верхней линии
   CExtremum *_extrDown0,*_extrDown1; // экстремумы нижней линии  
   CMove(string move_name,int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // конструктор класса по экстр
  ~CMove(); // деструктор класса
   // методы класса для получения свойств движения
   double GetHeight () { return(_height); }; // возвращает ширину канала
   ENUM_PRICE_MOVE_TYPE  GetMoveType () { return(_moveType); }; // возвращает тип движения
   int GetDirection (); // возвращает тип тренда, если движение - тренд
   CExtremum  *GetMoveExtremum (ENUM_EXTR_TYPE extr_type); // возвращает экстремум движения
 };

// кодирование методов класса ценовых движений

/////////приватные методы класса

void CMove::GenUniqName(void) // генерирует уникальное имя трендового канала
 {
  // генерит уникальные имена трендовых линий исходя из символа, периода и времени первого экстремума
  _lineUpName = _moveName+"up"+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time)+"."+TimeToString(_extrUp1.time);
  _lineDownName = _moveName+"down"+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time)+"."+TimeToString(_extrDown1.time);
 }
 
void CMove::CountHeight(void)
 {
  _height = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
 }
 
int CMove::IsItTrend(void) // проверяет, является ли данный канал трендовым
 {
  double h1,h2;
  double H1,H2;
  // если тренд вверх 
  if ( GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
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
    
    // если последний экстремум - вверх
    if (_extrDown0.time < _extrUp0.time)
     {
      H1 = _extrUp1.price - _extrDown0.price;
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrDown0.price - _extrDown1.price);
      h2 = MathAbs(_extrUp0.price - _extrUp1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )
       return (1);
     }
      
   }
  // если тренд вниз
  if ( LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    
    // если  последний экстремум - вверх
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = _extrUp1.price - _extrDown0.price;    
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )    
       return (-1);
     }
    
    // если последний экстремум - вниз
    else if (_extrUp0.time < _extrDown0.time)
     {
      H1 = _extrUp0.price - _extrDown1.price;    
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h2,H1*_percent) && GreatDoubles(h1,H2*_percent) )    
       return (-1);
     }
    
   }   
   
  return (0);
 }

// кодирование методов вычисления типов ценового движения

// функции обработки типов флэтов


int CMove::IsFlatA ()  // флэт А  
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*_height) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 } 

 int CMove::IsFlatB () // флэт B
 {
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatC () // флэт C
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 } 
 
int CMove::IsFlatD () // флэт D
 {
  if ( GreatOrEqualDoubles (_extrUp1.price - _extrUp0.price,_percent*_height) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatE () // флэт E
 {
  if ( GreatOrEqualDoubles (_extrUp0.price-_extrUp1.price,_percent*_height) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatF () // флэт F
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price), _percent*_height) &&
       GreatOrEqualDoubles (_extrDown1.price -_extrDown0.price , _percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }  
 
int CMove::IsFlatG () // флэт G
 {
  if ( GreatOrEqualDoubles (_extrUp0.price - _extrUp1.price, _percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price), _percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }       
 

///////////// публичные методы класса

CMove::CMove(string move_name,int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  int tempDir; // временная переменная для сохранения текущего движения
  // сохраняем поля класса
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _moveType = 0;
  _moveName = move_name;
  // создаем объекты экстремумов для трендовых линий
  _extrUp0   = extrUp0;
  _extrUp1   = extrUp1;
  _extrDown0 = extrDown0;
  _extrDown1 = extrDown1;
  
  // генерируем уникальные имена трендовых линий
  GenUniqName();
  // вычисляем ширину канала движения
  CountHeight();
  // обрабатываем типы движений
  tempDir = IsItTrend ();
  if (tempDir == MOVE_TREND_UP)  // если найден тренд вверх
    _moveType = 1;
  if (tempDir == -1) // если найден тренд вниз
    _moveType = MOVE_TREND_DOWN;   
  if (IsFlatA())     // если найден флэт А
     _moveType = MOVE_FLAT_A;
  if (IsFlatB())     // если найден флэт B
     _moveType = MOVE_FLAT_B;
  if (IsFlatC())     // если найден флэт C
     _moveType = MOVE_FLAT_C;
  if (IsFlatD())     // если найден флэт D
     _moveType = MOVE_FLAT_D;               
  if (IsFlatE())     // если найден флэт E
     _moveType = MOVE_FLAT_E;
  if (IsFlatF())     // если найден флэт F
     _moveType = MOVE_FLAT_F;
  if (IsFlatG())     // если найден флэт G
     _moveType = MOVE_FLAT_G;            
 
  // если мы нашли движение 
  if (_moveType == MOVE_TREND_UP || _moveType == MOVE_TREND_DOWN)  // если словили трендовое движение
   {
    
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // верхняя линия
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrLightBlue);  
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // верхняя линия 
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrLightBlue);        
   }
  else if (_moveType == MOVE_FLAT_A ||
           _moveType == MOVE_FLAT_B ||
           _moveType == MOVE_FLAT_C ||
           _moveType == MOVE_FLAT_D ||
           _moveType == MOVE_FLAT_E ||
           _moveType == MOVE_FLAT_F ||
           _moveType == MOVE_FLAT_G                                                       
           ) // если словили флэтовое движение
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // верхняя линия
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrYellow);      
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // верхняя линия     
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrYellow);      
   } 
 }
 
// деструктор класса
CMove::~CMove()
 {
  ObjectDelete(_chartID,_lineDownName);
  ObjectDelete(_chartID,_lineUpName);
 }

 
 // возвращает тип тренда, если сейчас - тренд
 int CMove::GetDirection(void)
  {
   if (_moveType == MOVE_TREND_DOWN)
    return (-1);
   if (_moveType == MOVE_TREND_UP)
    return (1);
   return (0);
  }
 
 CExtremum  *CMove::GetMoveExtremum(ENUM_EXTR_TYPE extr_type=EXTR_HIGH_0)
  {
   switch (extr_type)
    {
     case EXTR_HIGH_0:
      return (_extrUp0);
     break;
     case EXTR_HIGH_1:
      return (_extrUp1);
     break;
     case EXTR_LOW_0:
      return (_extrDown0);
     break;
     case EXTR_LOW_1:
      return (_extrDown1);
     break;               
    }
   return (_extrUp0);
  }