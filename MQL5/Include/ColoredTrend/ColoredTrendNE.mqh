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
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos);
  bool isLastBarHuge(int start_pos);
  int isNewTrend();
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR);
  SExtremum isExtremum(int start_index);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
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
bool CColoredTrend::CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 //PrintFormat("Вызов функции CountMoveType. i = %d, start_pos = %d", bar, start_pos);
 if(bar == 0) //на "нулевом" баре ничего происходить не будет и данная строчка избавит нас от лишних проверок в дальнейшем
  return true; 

 if(bar == ArraySize(enumMoveType))  // Выделим память под массив экстремумов
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, 3, start_pos, buffer_Rates) < 0) // получим размер заполненного массива
  return false; 
 if(FillATRBuf(2, start_pos) < 0) // заполним массив данными индикатора ATR
  return false;  
  
 enumMoveType[bar] = enumMoveType[bar - 1];
 difToNewExtremum = buffer_ATR[0] * _percentage_ATR;
 SExtremum current_bar = {0, -1};
 
 //if (num0.direction != current_bar.direction || num0.price != current_bar.price)
 //{
  current_bar = isExtremum(start_pos);   
  if (current_bar.direction != 0)
  {
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
  }
 //}
 
 if (num2.direction == 0 && num2.price == -1) //аналогично (num0 > 0 && num1 > 0 && num2 > 0) т.к. num2 не определится пока не определятся num0 и num1
 {
  //PrintFormat("Не высчитано 3 экстремума. i = %d; start_pos = %d; num0 = {%d, %f}; num1 = {%d, %f}; num2 = {%d, %f};", bar, start_pos, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  return true; 
 } 
  
 int newTrend = isNewTrend();        
 if (newTrend == -1)
 {// Если разница между последним (0) и предпоследним (1) экстремумом в "difToTrend" раз меньше нового движения
  PrintFormat("Выполнено условие isNewTrend DOWN на %d баре", bar); 
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  return true;
 }
 else if (newTrend == 1) // если текущее закрытие выше последнего экстремума 
 {
  PrintFormat("Выполнено условие isNewTrend UP на %d баре", bar);
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  return true;
 }
 else 
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   return true;
  }
 }
 
 //Начало коррекции вниз если цена закрытия меньше открытия предыдущего бара
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[1].close, buffer_Rates[0].open, digits))
 {
  PrintFormat("bar = %d, закончился тренд вверх(началась коррекция вниз), текущее закрытие=%.05f меньше предыдущего открытия=%.05f", bar, buffer_Rates[1].close, buffer_Rates[0].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  lastOnTrend = num0;
  return true;
 }
 //Начало коррекции вверх если цена закрытия больше открытия предыдущего бара
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[1].close, buffer_Rates[0].open, digits))
 {
  PrintFormat("bar = %d, закончился тренд вниз(началась коррекция вверх), текущее закрытие=%.05f больше предыдущего открытия=%.05f", bar, buffer_Rates[1].close, buffer_Rates[0].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  lastOnTrend = num0;
  return true;
 }
 
 //коррекция меняется на тренд вверх/вниз при наступлении условия isCorrectionEnds
 //если последняя цена меньше/больше последнего экстремум или на младшем тф "большой" бар
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[1].close, MOVE_TYPE_CORRECTION_UP, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  PrintFormat("bar = %d, закончилася коррекция вверх(начался тренд вниз), последняя цена=%.05f меньше последнего экстремума=%.05f", bar, buffer_Rates[1].close, lastOnTrend.price);
  return true;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[1].close, MOVE_TYPE_CORRECTION_DOWN, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  PrintFormat("bar = %d, закончилася коррекция вниз(начался тренд вверх), последняя цена=%.05f больше последнего экстремума=%.05f", bar, buffer_Rates[1].close, lastOnTrend.price);
  return true;
 }

 if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
   &&(current_bar.direction > 0)
   &&(LessDoubles(current_bar.price, num2.price, digits) // если новый максимум меньше предыдущего
    ||GreatDoubles( MathAbs(num2.price - num1.price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
                   ,MathAbs(num2.price - current_bar.price) // разница между максимумами(минимумами) меньше движения (разницы между противоположными)
                   ,digits)))   
 {
  PrintFormat("bar = %d, начался флэт, новый максимум меньше предыдущего num0 =%.05f < num2=%.05f или num2-num1=%.05f > num2-num0=%.05f", bar, current_bar.price, num2.price, (num2.price-num1.price), (num2.price-current_bar.price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  return true;
 }
 
 if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
   &&(current_bar.direction < 0)
   &&(GreatDoubles(current_bar.price, num2.price, digits)    // если новый минимум больше предыдущего
    ||GreatDoubles( MathAbs(num2.price - num1.price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
                   ,MathAbs(num2.price - current_bar.price) // разница между максимумами(минимумами) меньше движения (разницы между противоположными)
                   ,digits)))  // или новый минимум - больше
 { 
  PrintFormat("bar = %d, начался флэт, новый минимум больше предыдущего num0 =%.05f > num2=%.05f или num2-num1=%.05f > num2-num0=%.05f", bar, current_bar.price, num2.price, (num2.price-num1.price), (num2.price-current_bar.price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  return true;
 }
 
 return true;
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
 
 if (((num0.direction == 0) && (GreatDoubles(buffer[0].close, _startDayPrice + 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   || (num0.direction > 0 && (GreatDoubles(buffer[0].close, num0.price, digits)))
   || (num0.direction < 0 && (GreatDoubles(buffer[0].close, num0.price + difToNewExtremum, digits))))
 {
  result.direction = 1;
  result.price = buffer[0].close;
 }
 
 if (((num0.direction == 0) && (LessDoubles(buffer[0].close, _startDayPrice - 2*difToNewExtremum, digits))) // Если экстремумов еще нет и есть 2 шага от стартовой цены
   || (num0.direction < 0 && (LessDoubles(buffer[0].close, num0.price, digits)))
   || (num0.direction > 0 && (LessDoubles(buffer[0].close, num0.price - difToNewExtremum, digits))))
 {
  result.direction = -1;
  result.price = buffer[0].close;
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
 
 while(attempts < 25 && (copied = CopyRates(_symbol, period, start_pos, count, array))<0) // справа налево от 0 до count-1, всего count элементов
 {
  Sleep(100);
  attempts++;
 }
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
 bool extremum_condition, 
      bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, lastOnTrend.price, digits);
  bottomTF_condition = isLastBarHuge(start_pos);
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, lastOnTrend.price, digits);
  bottomTF_condition = isLastBarHuge(start_pos);
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge(int start_pos)
{
 double sum;
 MqlRates rates[];
 FillTimeSeries(BOTTOM_TF, _depth, start_pos, rates);
 for(int i = 0; i < _depth - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / _depth;
 double lastBar = MathAbs(rates[_depth-1].open - rates[_depth-1].close);
    
 return(GreatDoubles(lastBar, avgBar*2));
}

int CColoredTrend::isNewTrend()
{
 if (num1.direction < 0 && LessDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
  return(1);
 if (num1.direction > 0 && LessDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
  return(-1);
  
 return(0);
}

void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}
