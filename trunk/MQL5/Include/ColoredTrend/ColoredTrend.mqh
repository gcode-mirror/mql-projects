//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
// подключение библиотек
#include <CLog.mqh>                             // для ведения лога
#include <CompareDoubles.mqh>                   // для сравнения действительных чисел
#include <DrawExtremums/CExtrContainer.mqh>     // контейнер экстремумов
#include <StringUtilities.mqh>                  // константы и перечисления 
#include "ColoredTrendUtilities.mqh"            // константы и перечиселения для класса CColoredTrend


//------------------------------------------------------------------+
// Класс занимающийся расчетом типа движения на рынке               |
//------------------------------------------------------------------+
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  ENUM_MOVE_TYPE previous_move_type;
  int      _digits;                        // количество цифр после запятой для сравнения вещественных чисел
  int      _newTrend;                      // переменная для хранения тренда
  int      _depth;                         // количество баров для расчета индикатора
  double   _difToTrend;                    // во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.   
  // буферы 
  double   buffer_ATR[];                   // буфер ATR
  MqlRates buffer_Rates[];                 // буфер котировок
  datetime time_buffer[];                  // буфер времени
  // экстремумы для определения движения
  
  CExtremum *_extr0, *_extr1,*_extr2;
  CExtremum *lastOnTrend;                  // последний экстремум текущего тренда
  CExtremum *firstOnTrend;                 // цена начала тренда и его направление 
  // объекты классов
  CExtrContainer *_extrContainer;          // контейнер экстремумов
      
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[]);
  
  bool isCorrectionEnds  (double price, ENUM_MOVE_TYPE move_type, datetime start_time);
  bool isCorrectionWrong (int i);
  int  isLastBarHuge     (datetime start_time);
  int  isEndTrend();     
  

  
public:
  void CountTrend ();    // метод рассчета тренда
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period,  int handle_atr, int depth,CExtrContainer *extrContainer);
  void ~CColoredTrend();
  bool FindExtremumInHistory(int depth);
  bool CountMoveType (int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);    // метод вычисляет ценовое движение на истории  
  bool CountMoveTypeA(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);   // метод вычисляет ценовое движение в реальном времени
  ENUM_MOVE_TYPE GetMoveType(int i);
  void Zeros();
  int UpdateExtremums ();     // метод обновляет значения последних трех экстремумов (now = true - для реального времени, now = false - для рассчета на истории) 
  // временные методы
  CExtremum *GetExtr (int n);
  
  void ZeroTrend() { _newTrend = 0; };
  
  void PrintExtrInRealTime ();
  
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int handle_atr, int depth,CExtrContainer *extrContainer) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   previous_move_type(MOVE_TYPE_UNKNOWN),
                   _extrContainer(extrContainer)
{
 _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 firstOnTrend = new CExtremum(0,-1);
 lastOnTrend  = new CExtremum(0,-1);
 _difToTrend = SetDiffToTrend(period);
 _extr0 = new CExtremum(0,-1);
 _extr1 = new CExtremum(0,-1);
 _extr2 = new CExtremum(0,-1);
 ArrayResize(enumMoveType, depth);
 Zeros();  
 
}
void CColoredTrend::~CColoredTrend()
{
 delete _extr0;
 delete _extr1;
 delete _extr2;
 delete firstOnTrend;
 delete lastOnTrend;
}
//+-------------------------------------------------+
//| Функция вычисляет тип движения рынка на истории |
//+-------------------------------------------------+
bool  CColoredTrend::CountMoveType(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{ 
 int UpdateExtrCode;
 if(bar == 0) //на "нулевом" баре ничего происходить не будет и данная строчка избавит нас от лишних проверок в дальнейшем
  {
   return (true); 
  }
 
 if(bar == ArraySize(enumMoveType))  // Если массив движений заполнен увеличим его в два раза
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // получим размер заполненного массива
  { 
   return (false);
  } 
 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // текущее движение равно предыдущему движению
 
 _newTrend = 0;  // обнуляем значение тренда

 // пытаемся обновить экстремумы
 UpdateExtrCode = UpdateExtremums();
 
 // если не удалось прогрузить экстремумы
 if (UpdateExtrCode == 0)
  {
   //Print("Не удалось получить последние 3 экстремума");
   return (true);
  }
 // если удалось обновить экстремумы
 if (UpdateExtrCode == 1)
  {
   CountTrend();   // если появились новые экстремумы, проверяем не воявился ли новый тренд  
                                          
  }
 //проверяем тренд на запрещенность каждый раз, так как движения на старшем таймфрейма меняются так же в течение бара 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // Определяем только начало тренда так как иначе мы просто не дойдем до проверок на остальные типы движений
 if (_newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (_newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else // раскраска может начинаться только с тренда или флэта (просто потому что коррекции без тренда не бывает)
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 //если коррекрция "переросла" тренд то она превращается во флэт
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (1);
 }
 
 //Начало коррекции вниз если у предыдущего бара цена закрытия меньше цены открытия и при этом тренд продолжается с предыдущего бара 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) && // движение на предыдущем баре
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) && // текущее движение
     (previous_move_type  != MOVE_TYPE_FLAT)                                                              // предыдущее движение (может быть предыдущим движением текущего бара)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))  // предыдущий бар закрыт против тренда
      &&
     ((buffer_Rates[0].high < buffer_Rates[1].high)))                                                     // последний high меньше предпоследнего
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;

  if (_extr0.direction > 0)  
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  } 
  else
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction; 
  } 
  
  previous_move_type = enumMoveType[bar];
  return (true);
 }
//Начало коррекции вверх если у предыдущего бара цена закрытия больше цены открытия и при этом тренд продолжается с предыдущего бара 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // движение на предыдущем баре
     (enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN || enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // текущее движение
     (previous_move_type != MOVE_TYPE_FLAT)                                                                   // предыдущее движение (может быть предыдущим движением текущего бара)
      &&
     (GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // предыдущий бар закрыт против тренда
      &&
     ((buffer_Rates[0].low > buffer_Rates[1].low)))                                                           // последний low больше предпоследнего
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;

  if (_extr0.direction < 0) 
  { 
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }  
  else 
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction; 
  }
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //коррекция меняется на тренд вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //коррекция меняется на тренд вверх при наступлении условия isCorrectionEnds
 //если последняя цена больше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }

 // разница между первым и вторым экстремумом меньше разницы между вторым и третьим*коэфицент тренда
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_TREND_DOWN_FORBIDEN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_TREND_UP_FORBIDEN   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }

 return (true);
}

//+------------------------------------------------------+
//| Функция, рассчитывающая движение в реальном времени  |
//+------------------------------------------------------+ 
bool CColoredTrend::CountMoveTypeA(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if (bar == 0)
  {
   return (true);
  }
 if(bar == ArraySize(enumMoveType))  // Если массив движений заполнен увеличим его в два раза
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);

 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // получим размер заполненного массива
  {
   log_file.Write(LOG_DEBUG,StringFormat("_count = %i Не получили размер заполненного массива",_count) ) ;  
   return (false);
  } 

 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // текущее движение равно предыдущему движению

 //проверяем тренд на запрещенность каждый раз, так как движения на старшем таймфрейма меняются так же в течение бара 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // Определяем только начало тренда так как иначе мы просто не дойдем до проверок на остальные типы движений
 if (_newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (_newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else // раскраска может начинаться только с тренда или флэта (просто потому что коррекции без тренда не бывает)
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //если коррекрция "переросла" тренд то она превращается во флэт
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //Начало коррекции вниз если у предыдущего бара цена закрытия меньше цены открытия и при этом тренд продолжается с предыдущего бара 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) &&    // движение на предыдущем баре
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) &&    // текущее движение
     (previous_move_type  != MOVE_TYPE_FLAT)                                                                 // предыдущее движение (может быть предыдущим движением текущего бара)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // предыдущий бар закрыт против тренда
      &&
     ( buffer_Rates[0].high < buffer_Rates[1].high ))                                                        // последний high меньше предпоследнего
 {
  /*
  Comment("Попали в вычисление коррекции вниз, время = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );
  */
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;

  if (_extr0.direction > 0)                  
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }
  else
  { 
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction;
  }
  
  previous_move_type = enumMoveType[bar];
  return (true);
 }
//Начало коррекции вверх если у предыдущего бара цена закрытия больше цены открытия и при этом тренд продолжается с предыдущего бара 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // движение на предыдущем баре
     (enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN || enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // текущее движение
     (previous_move_type != MOVE_TYPE_FLAT)                                                                   // предыдущее движение (может быть предыдущим движением текущего бара)
      &&
     (GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // предыдущий бар закрыт против тренда
      &&
     (buffer_Rates[0].low > buffer_Rates[1].low ))                                                            // последний low больше предпоследнего
 {
  /*
  Comment("Попали в вычисление коррекции вверх, время = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );
  */ 
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  
  if (_extr0.direction < 0)    
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }
  else 
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction;
  }
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //коррекция меняется на тренд вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //коррекция меняется на тренд вверх при наступлении условия isCorrectionEnds
 //если последняя цена больше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 // разница между первым и вторым экстремумом меньше разницы между вторым и третьим*коэфицент тренда
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_TREND_DOWN_FORBIDEN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_TREND_UP_FORBIDEN   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 return (true);
} 
 
//+----------------------------------------------------+
//| Функция получает значние из массива типов движения |
//+----------------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 if(i < 0 || i >= ArraySize(enumMoveType))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Запрашиваемый индекс вне границ массива i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
  Print(StringFormat("%s Запрашиваемый индекс вне границ массива i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
 }
 return(enumMoveType[i]);
}

//+-------------------------------------------------+
//| Функция заполняет массив цен из истории         |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[])
{
 if(count > _depth) count = _depth;
//--- сколько скопировано
 int copied = 0;
 ENUM_TIMEFRAMES period;
 switch (tfType)
 {
  case BOTTOM_TF: 
   period = GetBottomTimeframe(_period);
   break;
  case CURRENT_TF:
   period = _period;
   break;
  case TOP_TF:
   period = GetTopTimeframe(_period);
   break;
 }
 
 copied = CopyRates(_symbol, period, start_time, count, array); // справа налево от 0 до count-1, всего count элементов
//--- если не удалось скопировать достаточное количество баров
 if(copied < count)
 {
  //--- Получим кол-во рассчитанных значений индикатора
  //--- Получим первую дату данных текущего периода в терминале
  datetime firstdate_terminal=(datetime)SeriesInfoInteger(_symbol ,Period(), SERIES_TERMINAL_FIRSTDATE);
  //--- Получим количество доступных баров от указанной даты
  int available_bars=Bars(_symbol,Period(),firstdate_terminal,TimeCurrent());
  string comm = StringFormat("%s Для символа %s получено %d баров из %d затребованных Rates. Period = %s. Error = %d | first date = %s, available = %d, start = %s, count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)period),
                             GetLastError(),
                             TimeToString(firstdate_terminal, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             available_bars,
                             TimeToString(start_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             count
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  log_file.Write(LOG_DEBUG, comm);
 }
 ArraySetAsSeries(array, true);
 return(copied);
}

//+------------------------------------------------------------------------+
//| Функция проверяет условия выхода из коррекции и продолжения тренда     |
//+------------------------------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_time)
{
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  if(LessDoubles(price, lastOnTrend.price, _digits))  // цена ушла ниже последнего экстремума на тренде
  {
   //Comment("цена ушла ниже последнего экстремума на тренде");
   return(true);
  }
  if(isLastBarHuge(start_time) > 0)                    // появление большого бара на младшем тф. большой бар - такой что он превышает размер среднего бара за некоторый промежуток времени
  {
   //Comment("появление большого бара на младшем тф. большой бар");
   return(true);
  }
 }
 else if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(GreatDoubles(price, lastOnTrend.price, _digits)) // цена ушла выше последнего экстремума на тренд
  {
   //Comment("цена ушла ниже последнего экстремума на тренде");
   return(true);
  }
  if(isLastBarHuge(start_time) < 0)                   // появление большого бара на младшем тф. большой бар - такой что он превышает размер среднего бара за некоторый промежуток времени
  {
   //Comment("появление большого бара на младшем тф. большой бар");  
   return(true);
  }
 }
 else
  PrintFormat("%s %s Неверный тип движения!", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period));
 
 return (false);
}

//+----------------------------------------------------------+
//| Функция проверяет условия выхода из коррекции во флэт.   |
//+----------------------------------------------------------+
bool CColoredTrend::isCorrectionWrong(int i)
{
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_UP)
 {
  if(buffer_Rates[0].close > firstOnTrend.price && firstOnTrend.direction == -1) 
  {
   return(true);
  }
 }
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(buffer_Rates[0].close < firstOnTrend.price && firstOnTrend.direction == 1) 
  {
   return(true);
  }
 }
 
 return(false);
}

//+----------------------------------------------------------------+
//| Функция определяет является ли бар "большим" и его направление |
//+----------------------------------------------------------------+
int CColoredTrend::isLastBarHuge(datetime start_time)
{
 double sum = 0;
 MqlRates rates[];
 datetime buffer_date[];
 CopyTime(_symbol, GetBottomTimeframe(_period),  start_time-PeriodSeconds(GetBottomTimeframe(_period)), AMOUNT_BARS_FOR_HUGE, buffer_date);
 if(FillTimeSeries(BOTTOM_TF, AMOUNT_BARS_FOR_HUGE, start_time-PeriodSeconds(GetBottomTimeframe(_period)), rates) < AMOUNT_BARS_FOR_HUGE) return(0);

 for(int i = 0; i < AMOUNT_BARS_FOR_HUGE - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / AMOUNT_BARS_FOR_HUGE;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 if(GreatDoubles(lastBar, avgBar*FACTOR_OF_SUPERIORITY))
 {
  if(GreatDoubles(rates[0].open, rates[0].close, _digits))
   return(1);
  if(LessDoubles(rates[0].open, rates[0].close, _digits))
   return(-1);
 }
 return(0);
}

//+----------------------------------------------------+
//| Функция определяет начало тренда                   |
//+----------------------------------------------------+
void CColoredTrend::CountTrend()
{
 //Comment("_extr0 ",_extr0.price," ",TimeToString(_extr0.time)," ",_extr0.direction );
 
 if (_extr1.direction < 0 && 
     LessDoubles((_extr2.price - _extr1.price)*_difToTrend,
                 (_extr0.price - _extr1.price), 
                 _digits))
 {
  _newTrend = 1;
  return;
 }
 
 if (_extr1.direction > 0 && 
     LessDoubles((_extr1.price - _extr2.price)*_difToTrend, 
                 (_extr1.price - _extr0.price), 
                 _digits))
 {
  _newTrend = -1;
  return;
 }
 
 _newTrend = 0;
}
//+----------------------------------------------------------+
//| Функция определяет конец тренда/коррекции (начало флэта) |
//+----------------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (_extr1.direction < 0 && 
     GreatDoubles((_extr2.price - _extr1.price)*_difToTrend ,(_extr0.price - _extr1.price), _digits))
 {
  return(1);
 }
 if (_extr1.direction > 0 && GreatDoubles((_extr1.price - _extr2.price)*_difToTrend ,(_extr1.price - _extr0.price), _digits))
 {
  return(-1);
 }
 return(0);
}
//+-------------------------------------------------------------+
//| Функция заполняет массив типов движения дефолтным элементом |
//+-------------------------------------------------------------+
void CColoredTrend::Zeros()
{
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}

//+-------------------------------------------------------------+
//| Функция обновляет значения последних трех экстремумов       |
//+-------------------------------------------------------------+
int CColoredTrend::UpdateExtremums()
{
 CExtremum *extr0Temp,*extr1Temp,*extr2Temp;

 // получаем последние 3 экстремума
 extr0Temp = _extrContainer.GetExtrByIndex(0,EXTR_BOTH);
 extr1Temp = _extrContainer.GetExtrByIndex(1,EXTR_BOTH);
 extr2Temp = _extrContainer.GetExtrByIndex(2,EXTR_BOTH);
  

 if (extr0Temp.direction == 0 || extr1Temp.direction == 0 || extr2Temp.direction == 0)
  return (0);
  
 /*Print("extr0Temp = ",DoubleToString(extr0Temp.price),
       "\nextr1 = ",DoubleToString(extr1Temp.price),
       "\nextr2 = ",DoubleToString(extr2Temp.price)
      );
 */
 // если обновился экстремум 
 if (extr0Temp.price != _extr0.price)
  {
   _extr0.price = extr0Temp.price;
   _extr0.time  = extr0Temp.time;
   _extr0.direction = extr0Temp.direction;
   
   _extr1.price = extr1Temp.price;
   _extr1.time  = extr1Temp.time;
   _extr1.direction = extr1Temp.direction;
   
   _extr2.price = extr2Temp.price;
   _extr2.time  = extr2Temp.time;
   _extr2.direction = extr2Temp.direction;   
   return (1);
  }
 return (-1);
}

CExtremum *CColoredTrend::GetExtr(int n)
 {
  if (n == 0)
   return (_extr0);
  if (n == 1)
   return (_extr1);
  if (n == 2)
   return (_extr2);
  return (_extr0);
 }
 
void CColoredTrend::PrintExtrInRealTime(void)
 {
  Comment("Попали в вычисление коррекции вверх, время = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );  
 }