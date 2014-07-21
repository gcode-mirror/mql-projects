//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"

//#include <CLog.mqh>
#include <CompareDoubles.mqh>
#include <CExtremum.mqh>
#include "ColoredTrendUtilities.mqh"
#include <StringUtilities.mqh>

#define AMOUNT_OF_PRICE 2
#define AMOUNT_BARS_FOR_HUGE 100
#define DEFAULT_DIFF_TO_TREND 1.5

#define FACTOR_OF_SUPERIORITY 2
//CLog log_output(OUT_COMMENT, LOG_NONE, 50, "PBI", 30);

//+------------------------------------------------------------------+
//| Вспомогательный класс для индикатора ColoredTrend                |
//+------------------------------------------------------------------+
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
  double _difToTrend;     // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
  int _depth;            // Количество баров для расчета индикатора 
  int ATR_handle;
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  datetime time_buffer[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_pos, MqlRates &array[]);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_pos);
  bool isCorrectionWrong(double price, ENUM_MOVE_TYPE move_type, datetime start_pos);
  int isLastBarHuge(datetime start_pos);
  int isNewTrend();
  int isEndTrend();
  void SetDiffToTrend();
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period,  int handle_atr, int depth);
  SExtremum isExtremum(datetime start_index, bool now);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, datetime start_pos, bool now, SExtremum &extremum[]);
  ENUM_MOVE_TYPE GetMoveType(int i);
  int TrendDirection();
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
bool CColoredTrend::CountMoveType(int bar, datetime start_pos, bool now, SExtremum &ret_extremums[])
{
 if(bar == 0) //на "нулевом" баре ничего происходить не будет и данная строчка избавит нас от лишних проверок в дальнейшем
  return (true); 

 if(bar == ArraySize(enumMoveType))  // Выделим память под массив экстремумов
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_pos, buffer_Rates) < 0) // получим размер заполненного массива
  return (false);
 
 CopyTime(_symbol, _period, start_pos, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;
 
 int newTrend = 0;
 int count_new_extrs = extremums.RecountExtremum(start_pos, now);

 if (count_new_extrs > 0)
 {//В массиве возвращаемых экструмумов на 0 месте стоит max, на месте 1 стоит min
  if(count_new_extrs == 1)  
  {
   if(extremums.getExtr(0).direction == 1)       ret_extremums[0] = extremums.getExtr(0);
   else if(extremums.getExtr(0).direction == -1) ret_extremums[1] = extremums.getExtr(0);
  }
  
  if(count_new_extrs == 2) 
  {
   if(extremums.getExtr(0).direction == 1)       { ret_extremums[0] = extremums.getExtr(0); ret_extremums[1] = extremums.getExtr(1); }
   else if(extremums.getExtr(0).direction == -1) { ret_extremums[0] = extremums.getExtr(1); ret_extremums[1] = extremums.getExtr(0); }
  }
  
  newTrend = isNewTrend();       
 }
 
 // Проверка на наличие 3х экстремумов. Выход если нет трех экстремумов
 if (extremums.ExtrCount() < 3)
 {
  //PrintFormat("%s Еще нет 3 экстремумов", __FUNCTION__);
  return (true);
 }

 
 if (newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {// Если разница между последним (0) и предпоследним (1) экстремумом в "_difToTrend" раз меньше нового движения
  enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = -1");
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP) // если текущее закрытие выше последнего экстремума 
 {
  enumMoveType[bar] = MOVE_TYPE_TREND_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = 1");
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else 
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   ////PrintEvent(enumMoveType[bar], previous_move_type, 0, "MOVE_TYPE_UNKNOWN");
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //если коррекрция "переросла" тренд то она превращается во флэт
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP)  && 
      isCorrectionWrong(buffer_Rates[0].close, enumMoveType[bar], start_pos))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, StringFormat("Corr опустилась ниже цены first on trend (%.05f;%s)", firstOnTrend.price, TimeToString(firstOnTrend.time)));
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //Начало коррекции вниз если цена предыдущего бара закрытия меньше цены открытия 
 if (enumMoveType[bar-1] == MOVE_TYPE_TREND_UP && enumMoveType[bar] == MOVE_TYPE_TREND_UP &&
     previous_move_type != MOVE_TYPE_FLAT)
 {
  if(LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
   //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;цена закрытия меньше цены предыдущего открытия %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
   if (extremums.getExtr(0).direction > 0) 
    lastOnTrend = extremums.getExtr(0); 
   else 
    lastOnTrend = extremums.getExtr(1);
  
   previous_move_type = enumMoveType[bar];
  }
  return (true);
 }
 //Начало коррекции вверх если цена предыдущего бара закрытия больше открытия  бара
 if (enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN && enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN && 
     previous_move_type != MOVE_TYPE_FLAT)
 {
  if(GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
   //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;цена закрытия больше открытия предыдущего бара %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
   if (extremums.getExtr(0).direction < 0) 
    lastOnTrend = extremums.getExtr(0); 
   else 
    lastOnTrend = extremums.getExtr(1);
    
   previous_move_type = enumMoveType[bar];
  }
  return(true);
 }
 
 //коррекция меняется на тренд вверх/вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше/больше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_pos))                       
 {
  enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_pos))
 {
  enumMoveType[bar] = MOVE_TYPE_TREND_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
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
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, datetime start_pos, MqlRates &array[])
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
 
 copied = CopyRates(_symbol, period, start_pos, count, array); // справа налево от 0 до count-1, всего count элементов
//--- если не удалось скопировать достаточное количество баров
 if(copied < count)
 {
  string comm = StringFormat("%s Для символа %s получено %d баров из %d затребованных Rates. Period = %s. Error = %d | start = %d count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)period),
                             GetLastError(),
                             start_pos,
                             count
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  Print(comm);
 }
 ArraySetAsSeries(array, true);
 return(copied);
}

//+----------------------------------------------------+
//| Функция проверяет условия выхода из коррекции      |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_pos)
{
 bool extremum_condition = false, 
      bottomTF_condition = false,
      newTrend_condition = false;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, lastOnTrend.price, _digits);
  //if(extremum_condition) PrintFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price);
  if(isLastBarHuge(start_pos) > 0) 
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
   bottomTF_condition = true;
  }
  if(extremums.getExtr(2).price == lastOnTrend.price && isNewTrend() == -1) 
  {
   //PrintFormat("newTrend : коррекция вверх заканчивается трендом вниз");  
   newTrend_condition = true;
  } 
 }
 else if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, lastOnTrend.price, _digits);
  //if(extremum_condition) PrintFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price);
  if(isLastBarHuge(start_pos) < 0) 
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
   bottomTF_condition = true;
  }
  if(extremums.getExtr(2).price == lastOnTrend.price && isNewTrend() == 1) 
  {
   //PrintFormat("newTrend : коррекция вниз заканчивается трендом вверх"); 
   newTrend_condition = true;
  }
 }
 else
  PrintFormat("%s %s Неверный тип движения!", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period));
 
 return ((extremum_condition) || (bottomTF_condition) || (newTrend_condition) );
}

//+----------------------------------------------------+
//| Функция проверяет условия выхода из коррекции      |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionWrong(double price, ENUM_MOVE_TYPE move_type, datetime start_pos)
{
 bool big_corr_condition = false;
 //PrintFormat("%s: price = %.05f @ firstOnTrend = %.05f [%d; %s]", __FUNCTION__,price, firstOnTrend.price, firstOnTrend.direction, TimeToString(firstOnTrend.time));
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  if(price > firstOnTrend.price && firstOnTrend.direction == -1) 
  {
   big_corr_condition = true;
   //PrintFormat("CORR_UP : %.05f > %.05f", price, firstOnTrend.price);
  }
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(price < firstOnTrend.price && firstOnTrend.direction == 1) 
  {
   big_corr_condition = true;
   //PrintFormat("CORR_DOWN : %.05f < %.05f", price, firstOnTrend.price);
  }
 }
 
 return(big_corr_condition);
}

//+----------------------------------------------------------------+
//| Функция определяет является ли бар "большим" и его направление |
//+----------------------------------------------------------------+
int CColoredTrend::isLastBarHuge(datetime start_pos)
{
 double sum = 0;
 MqlRates rates[];
 datetime buffer_date[];
 CopyTime(_symbol, GetBottomTimeframe(_period),  start_pos-PeriodSeconds(GetBottomTimeframe(_period)), AMOUNT_BARS_FOR_HUGE, buffer_date);
 if(FillTimeSeries(BOTTOM_TF, AMOUNT_BARS_FOR_HUGE, start_pos-PeriodSeconds(GetBottomTimeframe(_period)), rates) < AMOUNT_BARS_FOR_HUGE) return(0);
 //PrintFormat("сейчас %s; бары загружаю с %s", TimeToString(buffer_date[0]), TimeToString(buffer_date[0]-PeriodSeconds(GetBottomTimeframe(_period))));
 for(int i = 0; i < AMOUNT_BARS_FOR_HUGE - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / AMOUNT_BARS_FOR_HUGE;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 if(GreatDoubles(lastBar, avgBar*FACTOR_OF_SUPERIORITY))
 {
  if(GreatDoubles(rates[0].open, rates[0].close, _digits))
  {
   //PrintFormat("Я БООООЛЬШОООЙ БАР! 1 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[AMOUNT_BARS_FOR_HUGE-1].open, rates[AMOUNT_BARS_FOR_HUGE-1].close);
   return(1);
  }
  if(LessDoubles(rates[0].open, rates[0].close, _digits))
  {
   ///PrintFormat("Я БООООЛЬШОООЙ БАР! -1 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[AMOUNT_BARS_FOR_HUGE-1].open, rates[AMOUNT_BARS_FOR_HUGE-1].close);
   return(-1);
  }
 }
 //PrintFormat("Я БООООЛЬШОООЙ БАР! 0 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[size-1].open, rates[size-1].close);
 return(0);
}

//+----------------------------------------------------+
//| Функция определяет начало тренда                   |
//+----------------------------------------------------+
int CColoredTrend::isNewTrend()
{
 if (extremums.getExtr(1).direction < 0 && LessDoubles((extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend ,(extremums.getExtr(0).price - extremums.getExtr(1).price), _digits))
 {
  //PrintFormat("IS_NEW_TREND %s MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f < (num0-num1) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend, (extremums.getExtr(0).price - extremums.getExtr(1).price), _difToTrend);
  return(1);
 }
 if (extremums.getExtr(1).direction > 0 && LessDoubles((extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend ,(extremums.getExtr(1).price - extremums.getExtr(0).price), _digits))
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
   case(PERIOD_M15):
      _difToTrend = 1.0;
      break;
   case(PERIOD_H1):
      _difToTrend = 1.0;
      break;
   case(PERIOD_H4):
      _difToTrend = 1.0;
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