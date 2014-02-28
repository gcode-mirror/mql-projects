//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include "ColoredTrendUtilities.mqh"

//+------------------------------------------------------------------+
//| Структура для хранения информации об экстремуме                  |
//+------------------------------------------------------------------+
struct SExtremum
{
 int direction;
 double price;
};

//+------------------------------------------------------------------+
//| Вспомогательный класс для индикатора ColoredTrend                |
//+------------------------------------------------------------------+
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  int digits;
  SExtremum num0, 
            num1, 
            num2;  // номера последних экстремумов
  SExtremum lastOnTrend;       // последний экстремум текущего тренда  
  double _percentage_ATR;
  double _startDayPrice;
  double difToNewExtremum;
  double difToTrend;     // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
  int _depth;            // Количество баров для расчета индикатора 
  int ATR_handle;
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  datetime time_buffer[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos);
  int isLastBarHuge(int start_pos);
  int isNewTrend();
  int isEndTrend();
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR);
  SExtremum isExtremum(int start_index);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, int start_pos, SExtremum& extremum, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  int TrendDirection();
  void Zeros();
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   _percentage_ATR(percentage_ATR)
{
 num0.direction = 0;
 num1.direction = 0;
 num2.direction = 0;
 num0.price = -1;
 num1.price = -1;
 num2.price = -1;
 
 MqlRates buffer[1];
 CopyRates(_symbol, _period, _depth, 1, buffer);
 CopyTime(_symbol, _period, _depth, 1, time_buffer);
 _startDayPrice = buffer[0].close;
 ATR_handle = iATR(_symbol, _period, 100);
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, depth);
 ArrayInitialize(enumMoveType, 0);
 difToTrend = 2;  // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
}

//+-----------------------------------------------------+
//| Функция вычисляет тип движения рынка на истории     |
//+-----------------------------------------------------+
bool CColoredTrend::CountMoveType(int bar, int start_pos, SExtremum& extremum, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 //PrintFormat("Вызов функции CountMoveType. i = %d, start_pos = %d", bar, start_pos);
 if(bar == 0) //на "нулевом" баре ничего происходить не будет и данная строчка избавит нас от лишних проверок в дальнейшем
  return (true); 

 if(bar == ArraySize(enumMoveType))  // Выделим память под массив экстремумов
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
   
 if(FillTimeSeries(CURRENT_TF, 3, start_pos, buffer_Rates) < 0) // получим размер заполненного массива
  return (false); 
 if(FillATRBuf(2, start_pos) < 0) // заполним массив данными индикатора ATR
  return (false);  
 
 CopyTime(_symbol, _period, start_pos, 1, time_buffer);  
 enumMoveType[bar] = enumMoveType[bar - 1];
 difToNewExtremum = buffer_ATR[0] * _percentage_ATR;
 SExtremum current_bar = {0, -1};
 
 current_bar = isExtremum(start_pos);   
 if (current_bar.direction != 0)
 {
  extremum = current_bar;
  if (current_bar.direction == num0.direction) // если новый экстремум в том же напрвлении, что старый
  {
   num0.price = current_bar.price;
  }
  else
  {
   num2 = num1;
   num1 = num0;
   num0 = current_bar;
  }
  PrintFormat("%s ATR = %.05f;  num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), difToNewExtremum, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price); 
 }
 
 if (num2.direction == 0 && num2.price == -1) //аналогично (num0 > 0 && num1 > 0 && num2 > 0) т.к. num2 не определится пока не определятся num0 и num1
 {
  //PrintFormat("Не высчитано 3 экстремума. i = %d; start_pos = %d; num0 = {%d, %f}; num1 = {%d, %f}; num2 = {%d, %f};", bar, start_pos, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  return (true); 
 } 
  
 int newTrend = isNewTrend();        
 if (newTrend == -1)
 {// Если разница между последним (0) и предпоследним (1) экстремумом в "difToTrend" раз меньше нового движения
  PrintFormat("%s Выполнено условие isNewTrend DOWN на %d баре", TimeToString(time_buffer[0]), bar);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  //PrintFormat("На старшем ТФ движение %s", MoveTypeToString(topTF_Movement)); 
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  return (true);
 }
 else if (newTrend == 1) // если текущее закрытие выше последнего экстремума 
 {
  PrintFormat("%s Выполнено условие isNewTrend UP на %d баре", TimeToString(time_buffer[0]), bar);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  //PrintFormat("На старшем ТФ движение %s", MoveTypeToString(topTF_Movement)); 
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  return (true);
 }
 else 
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   PrintFormat("%s Предыдущее движение не было определено. Сейчас FLAT", TimeToString(time_buffer[0]));
   //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   return (true);
  }
 }
 
 //Начало коррекции вниз если цена закрытия меньше открытия предыдущего бара
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[2].close, buffer_Rates[2].open, digits))
 {
  PrintFormat("%s bar = %d, закончился тренд вверх(началась коррекция вниз), текущее закрытие=%.05f; текущее открытия=%.05f", TimeToString(time_buffer[0]), bar, buffer_Rates[2].close, buffer_Rates[2].open);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  if (num0.direction > 0) 
   lastOnTrend = num0; 
  else 
   lastOnTrend = num1;
  return (true);
 }
 //Начало коррекции вверх если цена закрытия больше открытия предыдущего бара
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[2].close, buffer_Rates[2].open, digits))
 {
  PrintFormat("%s bar = %d, закончился тренд вниз(началась коррекция вверх), текущее закрытие=%.05f; текущее открытия=%.05f", TimeToString(time_buffer[0]), bar, buffer_Rates[2].close, buffer_Rates[2].open);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  if (num0.direction < 0) 
   lastOnTrend = num0; 
  else 
   lastOnTrend = num1;
  return (true);
 }
 
 //коррекция меняется на тренд вверх/вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше/больше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[2].close, enumMoveType[bar], start_pos))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintFormat("%s", MoveTypeToString(enumMoveType[bar]));
  PrintFormat("%s bar = %d, закончилася коррекция вверх(начался тренд вниз), последняя цена=%.05f меньше последнего экстремума=%.05f", TimeToString(time_buffer[0]), bar, buffer_Rates[2].close, lastOnTrend.price);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  //PrintFormat("%s", MoveTypeToString(enumMoveType[bar]));
  PrintFormat("bar = %d, закончилася коррекция вверх(начался тренд вниз), последняя цена=%.05f меньше последнего экстремума=%.05f", bar, buffer_Rates[2].close, lastOnTrend.price);
  return (true);
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[2].close, enumMoveType[bar], start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintFormat("%s", MoveTypeToString(enumMoveType[bar]));
  PrintFormat("%s bar = %d, закончилася коррекция вниз(начался тренд вверх), последняя цена=%.05f больше последнего экстремума=%.05f", TimeToString(time_buffer[0]), bar, buffer_Rates[2].close, lastOnTrend.price);
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  //PrintFormat("%s", MoveTypeToString(enumMoveType[bar]));
  PrintFormat("bar = %d, закончилася коррекция вниз(начался тренд вверх), последняя цена=%.05f больше последнего экстремума=%.05f", bar, buffer_Rates[2].close, lastOnTrend.price);
  return (true);
 }

 if (((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1) || 
     ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP   || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() == 1))   
 {
  if(num1.direction < 0) PrintFormat("%s bar = %d, начался флэт, новое движение меньше удвоенного предыдущего num2-num1=%.05f*2 > num0-num1=%.05f",  TimeToString(time_buffer[0]), bar, (num2.price-num1.price), (num0.price-num1.price));
  if(num1.direction > 0) PrintFormat("%s bar = %d, начался флэт, новое движение меньше удвоенного предыдущего num1-num2=%.05f*2 > num0-num1=%.05f",  TimeToString(time_buffer[0]), bar, (num1.price-num2.price), (num1.price-num0.price));
  //PrintFormat("%s num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", TimeToString(time_buffer[0]), num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  return (true);
 }
 
 return (true);
}

//+------------------------------------------+
//| Функция получает значние из массива      |
//+------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 return (enumMoveType[i]);
}
//+--------------------------------------------------------------------+
//| Функция возвращает направление и значение экстремума в точке vol2  |
//+--------------------------------------------------------------------+
SExtremum CColoredTrend::isExtremum(int start_index)
{
 SExtremum result = {0,0};
 MqlRates buffer[1];
 CopyRates(_symbol, _period, start_index, 1, buffer);
 
 if (((num0.direction == 0) && (GreatDoubles(buffer[0].high, _startDayPrice + 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   || (num0.direction > 0 && (GreatDoubles(buffer[0].high, num0.price, digits)))
   || (num0.direction < 0 && (GreatDoubles(buffer[0].high, num0.price + difToNewExtremum, digits))))
 {
  result.direction = 1;
  result.price = buffer[0].high;
 }
 
 if (((num0.direction == 0) && (LessDoubles(buffer[0].low, _startDayPrice - 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   || (num0.direction < 0 && (LessDoubles(buffer[0].low, num0.price, digits)))
   || (num0.direction > 0 && (LessDoubles(buffer[0].low, num0.price - difToNewExtremum, digits))))
 {
  result.direction = -1;
  result.price = buffer[0].low;
 }
 
 //PrintFormat("start_pos = %d; num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", start_index, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
 return(result);
}


//+-------------------------------------------------+
//| Функция заполняет массив экстремумов из истории |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[])
{
 //--- счетчик попыток
 int attempts = 0;
//--- сколько скопировано
 int copied = 0;
//--- делаем 25 попыток получить таймсерию по нужному символу
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
 if(tfType == BOTTOM_TF)
 { 
  datetime date[1];
  CopyTime(_symbol, _period, start_pos, 1, date);
  datetime start_date = date[0];
  datetime end_date = start_date - _depth*PeriodSeconds(_period);
  copied = CopyRates(_symbol, period, start_date, end_date, array); // справа налево от 0 до count-1, всего count элементов
 }
 else
  copied = CopyRates(_symbol, period, start_pos, count, array); // справа налево от 0 до count-1, всего count элементов
//--- если не удалось скопировать достаточное количество баров
 if(copied != count)
 {
  string comm = StringFormat("Для символа %s получено %d баров из %d затребованных Rates. Period = %s. Error = %d | start = %d count = %d",
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
 return(copied);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
int CColoredTrend::FillATRBuf(int count, int start_pos = 0)
{
 if(ATR_handle == INVALID_HANDLE)                      //проверяем наличие хендла индикатора
 {
  Print("Не удалось получить хендл ATR");             //если хендл не получен, то выводим сообщение в лог об ошибке
 }
 //--- счетчик попыток
   int attempts = 0;
//--- сколько скопировано
   int copied = 0;
//--- делаем 25 попыток получить таймсерию по нужному символу
 while(attempts < 250 && (copied = CopyBuffer(ATR_handle, 0, start_pos, count, buffer_ATR)) < 0) // справа налево от 0 до count, всего count элементов
 {
  Sleep(100);
  attempts++;
 }
//--- если не удалось скопировать достаточное количество баров
 if(copied != count)
 {
  string comm = StringFormat("Для символа %s получено %d баров из %d затребованных ATR. Period = %s.  Error = %d | start = %d count = %d bars_calculated = %d",
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)_period),
                             GetLastError(),
                             start_pos,
                             count,
                             BarsCalculated(ATR_handle)
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  Print(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos)
{
 bool extremum_condition = false, 
      bottomTF_condition = false;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, lastOnTrend.price, digits);
  if(isLastBarHuge(start_pos) > 0) bottomTF_condition = true;
  if(extremum_condition) {PrintFormat("%.05f %s UP Extremum condition success: %.05f < %.05f", price, TimeToString(time_buffer[0]), price, lastOnTrend.price);}
  if(bottomTF_condition) {PrintFormat("%.05f %s UP BottomTF condition success", price, TimeToString(time_buffer[0]));}
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, lastOnTrend.price, digits);
  if(isLastBarHuge(start_pos) < 0) bottomTF_condition = true;
  if(extremum_condition) {PrintFormat("%.05f %s DOWN Extremum condition success: %.05f > %.05f", price, TimeToString(time_buffer[0]), price, lastOnTrend.price);}
  if(bottomTF_condition) {PrintFormat("%.05f %s DOWN BottomTF condition success", price, TimeToString(time_buffer[0]));}
  if(extremum_condition) {PrintFormat("%.05f %s DOWN Extremum condition success", price, TimeToString(time_buffer[0]));}
  if(bottomTF_condition) {PrintFormat("%.05f %s DOWN BottomTF condition success", price, TimeToString(time_buffer[0]));}
 }
 
 return ((extremum_condition) || (bottomTF_condition));
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
int CColoredTrend::isLastBarHuge(int start_pos)
{
 double sum = 0;
 MqlRates rates[];
 FillTimeSeries(BOTTOM_TF, _depth, start_pos, rates);
 int size = ArraySize(rates);
 for(int i = 0; i < size - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / size;
 double lastBar = MathAbs(rates[size-1].open - rates[size-1].close);
    
 if(GreatDoubles(lastBar, avgBar*2))
 {
  if(GreatDoubles(rates[size-1].open, rates[size-1].close, digits))
  {
   PrintFormat("avgBar = %.05f ; lastBar = %.05f; openLB = %.05f", avgBar, lastBar, rates[_depth-1].open);
   PrintFormat("open = %.05f, close = %.05f", rates[_depth-1].open, rates[_depth-1].close);
   return(1);
  }
  if(LessDoubles(rates[size-1].open, rates[size-1].close, digits))
  {
   PrintFormat("avgBar = %.05f ; lastBar = %.05f; openLB = %.05f", avgBar, lastBar, rates[_depth-1].open);
   PrintFormat("open = %.05f, close = %.05f", rates[_depth-1].open, rates[_depth-1].close);
   return(-1);
  }
  
 }
 return(0);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
int CColoredTrend::isNewTrend()
{
 if (num1.direction < 0 && LessDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
  return(1);
 if (num1.direction > 0 && LessDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
  return(-1);
  
 return(0);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (num1.direction < 0 && GreatDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
  return(1);
 if (num1.direction > 0 && GreatDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
  return(-1);
  
 return(0);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}
