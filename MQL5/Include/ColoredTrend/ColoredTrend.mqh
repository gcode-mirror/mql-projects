//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"

#include <CLog.mqh>
#include <CompareDoubles.mqh>
#include <CExtremum.mqh>
#include "ColoredTrendUtilities.mqh"
#include <StringUtilities.mqh>

#define AMOUNT_OF_PRICE 2           // количество баров с которых нам нужно знать цены. для вычисления типа движения нам интересны цены с текущего и последнего бара.
#define AMOUNT_BARS_FOR_HUGE 100    // количество баров по которым считается средний бар на младшем таймфрейме
#define DEFAULT_DIFF_TO_TREND 1.5   // значение коэфицента роста движения по умолчанию
#define FACTOR_OF_SUPERIORITY 2     // во сколько раз бар должен быть больше среднего чтобы быть большим
//CLog log_output(OUT_COMMENT, LOG_NONE, 50, "PBI", 30);

//------------------------------------------------------------------
// Класс занимающийся расчетом типа движения на рынке
//------------------------------------------------------------------
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  ENUM_MOVE_TYPE previous_move_type;
  int _digits;
  CExtremum *extremums;
  SExtremum lastOnTrend;       // последний экстремум текущего тренда
  SExtremum firstOnTrend;      // цена начала тренда и его направление  
  double _difToTrend;          // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
  int _depth;                  // Количество баров для расчета индикатора 
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  datetime time_buffer[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[]);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_time);
  bool isCorrectionWrong(int i);
  int isLastBarHuge(datetime start_time);
  int isNewTrend();
  int isEndTrend();
  void SetDiffToTrend();
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period,  int handle_atr, int depth);
  //SExtremum isExtremum(datetime start_index, bool now);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, datetime start_time, bool now, SExtremum &extremum[], ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  void Zeros();
  void PrintExtr();
  void PrintEvent(ENUM_MOVE_TYPE mt, ENUM_MOVE_TYPE mt_old, double price, string opinion);
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int handle_atr, int depth) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   previous_move_type(MOVE_TYPE_UNKNOWN)
{
 _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 
 extremums = new CExtremum(_symbol, _period, handle_atr);
 
 firstOnTrend.direction = 0;
 firstOnTrend.price = -1;
 lastOnTrend.direction = 0;
 lastOnTrend.price = -1;
 SetDiffToTrend();
 
 PrintFormat("%s %s; precentage ATR = %.02f, diff to trend = %.02f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), extremums.getPercentageATR(), _difToTrend);
 ArrayResize(enumMoveType, depth);
 Zeros();
 //log_output.Write(LOG_DEBUG, StringFormat("%s Конструктор класса CColoredTrend", EnumToString(_period)));
}

//+--------------------------------------+
//| Функция вычисляет тип движения рынка |
//+--------------------------------------+
bool CColoredTrend::CountMoveType(int bar, datetime start_time, bool now, SExtremum &ret_extremums[], ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if(bar == 0) //на "нулевом" баре ничего происходить не будет и данная строчка избавит нас от лишних проверок в дальнейшем
  return (true); 

 if(bar == ArraySize(enumMoveType))  // Если массив движений заполнен увеличим его в два раза
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // получим размер заполненного массива
  return (false);
 
 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // текущее движение равно предыдущему движению
 
 int newTrend = 0;
 int count_new_extrs = extremums.RecountExtremum(start_time, now);
 
 if (extremums.ExtrCount() < 3) // Проверка на наличие 3х экстремумов. Если нет трех экстремумов то не сможем определить ни одно из возможных движений
  return (true);

 if (count_new_extrs > 0)
 {                          // В массиве возвращаемых экструмумов на 0 месте стоит max, на месте 1 стоит min  (*)
  if(count_new_extrs == 1)  // если появился только один новый экстремум
  {
   if(extremums.getExtr(0).direction == 1)       ret_extremums[0] = extremums.getExtr(0);
   else if(extremums.getExtr(0).direction == -1) ret_extremums[1] = extremums.getExtr(0); 
  }
  
  if(count_new_extrs == 2)  // если появились два новых экстремумов. возвращаем с учетом (*)
  {
   if(extremums.getExtr(0).direction == 1)       { ret_extremums[0] = extremums.getExtr(0); ret_extremums[1] = extremums.getExtr(1); }
   else if(extremums.getExtr(0).direction == -1) { ret_extremums[0] = extremums.getExtr(1); ret_extremums[1] = extremums.getExtr(0); }
  }
  
  newTrend = isNewTrend();  // если появились новые экстремумы проверяем не появился ли новый тренд     
 }
 
 //проверяем тренд на запрещенность каждый раз, так как движения на старшем таймфрейма меняются так же в течение бара 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // Определяем только начало тренда так как иначе мы просто не дойдем до проверок на остальные типы движений
 if (newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = -1");
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = 1");
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
   //PrintEvent(enumMoveType[bar], previous_move_type, 0, "MOVE_TYPE_UNKNOWN");
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //если коррекрция "переросла" тренд то она превращается во флэт
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, StringFormat("Corr опустилась ниже цены first on trend (%.05f;%s)", firstOnTrend.price, TimeToString(firstOnTrend.time)));
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //Начало коррекции вниз если у предыдущего бара цена закрытия меньше цены открытия и при этом тренд продолжается с предыдущего бара 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) && // движение на предыдущем баре
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) && // текущее движение
     (previous_move_type  != MOVE_TYPE_FLAT)                                                              // предыдущее движение (может быть предыдущим движением текущего бара)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))  // предыдущий бар закрыт против тренда
      &&
     ((now) || (buffer_Rates[0].high < buffer_Rates[1].high)))                                            // последний high меньше предпоследнего
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;цена закрытия меньше цены предыдущего открытия %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
  if (extremums.getExtr(0).direction > 0) 
   lastOnTrend = extremums.getExtr(0); 
  else 
   lastOnTrend = extremums.getExtr(1);
  
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
     ((now) || (buffer_Rates[0].low > buffer_Rates[1].low)))                                                  // последний low больше предпоследнего
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;цена закрытия больше открытия предыдущего бара %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
  if (extremums.getExtr(0).direction < 0) 
   lastOnTrend = extremums.getExtr(0); 
  else 
   lastOnTrend = extremums.getExtr(1);
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //коррекция меняется на тренд вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
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
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
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
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isEndTrend");
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
  Alert(StringFormat("%s i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
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
  //calculated_values=BarsCalculated(symbol_handles[s]);
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
   //if(extremum_condition) log_file.Write(LOG_DEBUG, StringFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price));
   return(true);
  }
  if(isLastBarHuge(start_time) > 0)                    // появление большого бара на младшем тф. большой бар - такой что он превышает размер среднего бара за некоторый промежуток времени
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
   return(true);
  }
 }
 else if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(GreatDoubles(price, lastOnTrend.price, _digits)) // цена ушла выше последнего экстремума на тренд
  {
   //if(extremum_condition) PrintFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price);
   return(true);
  }
  if(isLastBarHuge(start_time) < 0)                   // появление большого бара на младшем тф. большой бар - такой что он превышает размер среднего бара за некоторый промежуток времени
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
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
 //PrintFormat("%s: price = %.05f @ firstOnTrend = %.05f [%d; %s]", __FUNCTION__,price, firstOnTrend.price, firstOnTrend.direction, TimeToString(firstOnTrend.time));
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_UP)
 {
  if(buffer_Rates[0].close > firstOnTrend.price && firstOnTrend.direction == -1) 
  {
   return(true);
   //PrintFormat("CORR_UP : %.05f > %.05f", price, firstOnTrend.price);
  }
 }
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(buffer_Rates[0].close < firstOnTrend.price && firstOnTrend.direction == 1) 
  {
   return(true);
   //PrintFormat("CORR_DOWN : %.05f < %.05f", price, firstOnTrend.price);
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
int CColoredTrend::isNewTrend()
{
 if (extremums.getExtr(1).direction < 0 && 
     LessDoubles((extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend,
                 (extremums.getExtr(0).price - extremums.getExtr(1).price), 
                 _digits))
 {
  //PrintFormat("IS_NEW_TREND %s MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f < (num0-num1) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend, (extremums.getExtr(0).price - extremums.getExtr(1).price), _difToTrend);
  return(1);
 }
 if (extremums.getExtr(1).direction > 0 && 
     LessDoubles((extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, 
                 (extremums.getExtr(1).price - extremums.getExtr(0).price), 
                 _digits))
 {
  //PrintFormat("IS_NEW_TREND %s MIN: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num1-num2)*k = %.05f < (num1-num0) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, (extremums.getExtr(1).price - extremums.getExtr(0).price), _difToTrend);
  return(-1);
 }
 return(0);
}

//+----------------------------------------------------------+
//| Функция определяет конец тренда/коррекции (начало флэта) |
//+----------------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (extremums.getExtr(1).direction < 0 && GreatDoubles((extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend ,(extremums.getExtr(0).price - extremums.getExtr(1).price), _digits))
 {
  //PrintFormat("IS_END_TREND %s MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f > (num0-num1) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend, (extremums.getExtr(0).price - extremums.getExtr(1).price), _difToTrend);
  return(1);
 }
 if (extremums.getExtr(1).direction > 0 && GreatDoubles((extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend ,(extremums.getExtr(1).price - extremums.getExtr(0).price), _digits))
 {
  //PrintFormat("IS_END_TREND %s MIN: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num1-num2)*k = %.05f > (num1-num0) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, (extremums.getExtr(1).price - extremums.getExtr(0).price), _difToTrend);
  return(-1);
 }
 return(0);
}

//+-------------------------------------------------------------+
//| Функция заполняет массив типов движения дефолтным элементом |
//+-------------------------------------------------------------+
void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}

void CColoredTrend::SetDiffToTrend()
{
 switch(_period)
 {
   case(PERIOD_M5):
      _difToTrend = 1.5;
      break;
   case(PERIOD_M15):
      _difToTrend = 1.3;
      break;
   case(PERIOD_H1):
      _difToTrend = 1.3;
      break;
   case(PERIOD_H4):
      _difToTrend = 1.3;
      break;
   case(PERIOD_D1):
      _difToTrend = 0.8;
      break;
   case(PERIOD_W1):
      _difToTrend = 0.8;
      break;
   case(PERIOD_MN1):
      _difToTrend = 0.8;
      break;
   default:
      _difToTrend = DEFAULT_DIFF_TO_TREND;
      break;
 }
}
 
void CColoredTrend::PrintExtr(void)
{
 extremums.PrintExtremums();
}

void CColoredTrend::PrintEvent(ENUM_MOVE_TYPE mt, ENUM_MOVE_TYPE mt_old, double price, string opinion)
{
 PrintFormat("%s Случилось движение %s. Предыдущее движение %s. Цена - %.05f. Основание %s", EnumToString((ENUM_TIMEFRAMES)_period), MoveTypeToString(mt), MoveTypeToString(mt_old), price, opinion);
 extremums.PrintExtremums();
}