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

int ATR_handle;
double buffer_ATR[];
MqlRates buffer_Rates[];
MqlRates buffer_TopRates[];
MqlRates buffer_BottomRates[];

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
  SExtremum aExtremums[];
  int digits;
  int num0, num1, num2;  // номера последних экстремумов
  int lastOnTrend;       // последний экстремум текущего тренда
  double _percentage_ATR;
  double difToNewExtremum;
  double difToTrend;     // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
  int _depth;            // Количество баров для расчета индикатора 
  int _shift;            // Количество баров в истории
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type);
  bool isLastBarHuge();
  bool isNewTrend(double price);
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  int CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR) : 
                   _depth(depth), 
                   _shift(40)
{

 _symbol = symbol;
 _period = period;
 ATR_handle = iATR(_symbol, _period, 100);
 _percentage_ATR = percentage_ATR;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, 1024);
 ArrayResize(  aExtremums, 1024);
 ArrayInitialize(enumMoveType, 0);
 SExtremum zero = {0, 0};
 for(int i = 0; i < 1024; i++)
 {
  aExtremums[i] = zero;
 }
 difToTrend = 2;  // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
}

//+------------------------------------------+
//| Функция вычисляет тип движения рынка     |
//+------------------------------------------+
int CColoredTrend::CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if(FillTimeSeries(CURRENT_TF, 4, start_pos, buffer_Rates) < 0) 
 {
  //Print("Не удалось загрузить rates");
  return (-1); // получим размер заполненного массива
 }
 if(FillATRBuf(4, start_pos) < 0) 
 {
  //Print("Не удалось загрузить atr");
  return (-1);                              // заполним массив данными индикатора ATR
 }
 // Выделим память под массивы цветов и экстремумов
 if(bar == ArraySize(enumMoveType)) ArrayResize (enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
 if(bar == ArraySize(aExtremums)  ) ArrayResize (  aExtremums, ArraySize(  aExtremums)*2, ArraySize(  aExtremums)*2);
 difToNewExtremum =  buffer_ATR[1] * _percentage_ATR;
 if (bar != 0) 
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  //PrintFormat("enumMoveType[%d] = %s, enumMoveType[%d] = %s", bar, MoveTypeToString(enumMoveType[bar]), bar - 1, MoveTypeToString(enumMoveType[bar - 1]));
 }
 
 bool newTrend = isNewTrend(buffer_Rates[3].close);
           
 if (newTrend)
 {// Если разница между последним (0) и предпоследним (1) экстремумом в "difToTrend" раз меньше нового движения 
  if (LessDoubles(buffer_Rates[3].close, aExtremums[num0].price, digits)) // если текущее закрытие ниже последнего экстремума 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
   //PrintFormat("bar = %d, начался тренд вниз, текущее закрытие=%.05f меньше последнего экстремума=%.05f", bar, buffer_Rates[3].close, aExtremums[num0].price);
  }
  if (GreatDoubles(buffer_Rates[3].close, aExtremums[num0].price, digits)) // если текущее закрытие выше последнего экстремума 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
   //PrintFormat("bar = %d, начался тренд вниз, текущее закрытие=%.05f меньше последнего экстремума=%.05f", bar, buffer_Rates[3].close, aExtremums[num0].price);
  }
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[3].close, buffer_Rates[2].open, digits))
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  lastOnTrend = num0;
 }
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[3].close, buffer_Rates[2].open, digits))
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  lastOnTrend = num0;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[3].close, MOVE_TYPE_CORRECTION_UP))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[3].close, MOVE_TYPE_CORRECTION_DOWN))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
 }
 // Проверяем наличие экстремума на текущем баре
 aExtremums[bar] =  isExtremum(buffer_Rates[0].close, buffer_Rates[1].close, buffer_Rates[2].close, num0);
 if (aExtremums[bar].direction != 0)
 {
  if (aExtremums[bar].direction == aExtremums[num0].direction) // если новый экстремум в том же напрвлении, что старый
  {
   aExtremums[num0].direction = 0;
   num0 = bar;
  }
  else
  {
   num2 = num1;
   num1 = num0;
   num0 = bar;
  }
  //PrintFormat("bar = %d, экстремумы num0=%d=%.05f, num1=%d=%.05f, num2=%d=%.05f", bar, num0, aExtremums[num0].price, num1, aExtremums[num1].price, num2, aExtremums[num2].price);
  if ( bar != 0
    &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
    &&(aExtremums[bar].direction > 0)
    &&(
       LessDoubles(aExtremums[bar].price, aExtremums[num2].price, digits) // если новый максимум меньше предыдущего
     ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
                    ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // разница между максимумами(минимумами) меньше движения (разницы между противоположными)
                    ,digits)))   
  {
   //PrintFormat("bar = %d, начался флэт, новый максимум меньше предыдущего num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
   enumMoveType[bar] = MOVE_TYPE_FLAT;
  }
  
  if ( bar != 0
    &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
    &&(aExtremums[bar].direction < 0)
    &&(
       GreatDoubles(aExtremums[bar].price, aExtremums[num2].price, digits)
     ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
                    ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // разница между максимумами(минимумами) меньше движения (разницы между противоположными)
                    ,digits)))  // или новый минимум - больше
  { 
   //PrintFormat("bar = %d, начался флэт, новый минимум больше предыдущего num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
   enumMoveType[bar] = MOVE_TYPE_FLAT;
  }
 }
 return 0;
}

//+------------------------------------------+
//| Функция получает значние из массива      |
//+------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 return (enumMoveType[i]);
}

//+------------------------------------------+
//| Функция получает значние из массива      |
//+------------------------------------------+
double CColoredTrend::GetExtremum(int i)
{
 if (aExtremums[i].direction > 0)
 {
  return (aExtremums[i].price + 50*Point());
 }
 if (aExtremums[i].direction < 0)
 {
  return (aExtremums[i].price - 50*Point());
 }
 return (0.0);
}

//+------------------------------------------+
//| Функция получает значние из массива      |
//+------------------------------------------+
int CColoredTrend::GetExtremumDirection(int i)
{
 return (aExtremums[i].direction);
}
//+--------------------------------------------------------------------+
//| Функция возвращает направление и значение экстремума в точке vol2  |
//+--------------------------------------------------------------------+
SExtremum CColoredTrend::isExtremum(double vol1, double vol2, double vol3, int last = 0)
{
 //PrintFormat("%f %f %f", vol1, vol2, vol3);
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 SExtremum res;
 res.direction = 0;
 res.price = vol2;
 if (GreatDoubles(vol1, vol2, digits)
  && LessDoubles (vol2, vol3, digits)
  && GreatDoubles(aExtremums[last].price, vol2 + difToNewExtremum, 5))
 {
  res.direction = -1;// минимум в точке vol2
 }
 
 if (LessDoubles(vol1, vol2, digits)
  && GreatDoubles(vol2, vol3, digits)
  && LessDoubles(aExtremums[last].price, vol2 - difToNewExtremum, 5))
 {
  res.direction = 1;// максимум в точке vol2
 } 
 return(res); // нет экстремума в точке vol2
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
  string comm = StringFormat("Для символа %s удалось получить только %d баров из %d затребованных Rates. Error = %d | start = %d count = %d",
                             _symbol,
                             copied,
                             count,
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
  Alert("Не удалось получить хендл ATR");             //если хендл не получен, то выводим сообщение в лог об ошибке
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
  string comm = StringFormat("Для символа %s удалось получить только %d баров из %d затребованных ATR. Error = %d | start = %d count = %d handke %d",
                             _symbol,
                             copied,
                             count,
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
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type)
{
 bool extremum_condition, 
      bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge();
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge();
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge()
{
 double sum;
 MqlRates rates[];
 FillTimeSeries(BOTTOM_TF, _depth, 0, rates);
 for(int i = 0; i < _depth - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / _depth;
 double lastBar = MathAbs(rates[_depth-1].open - rates[_depth-1].close);
    
 return(GreatDoubles(lastBar, avgBar*2));
}

bool CColoredTrend::isNewTrend(double price)
{
 // Здесь проверяются разные случаи начала тренда. Два варианта, когда цена пошла в сторону предпоследнего экстремума и когда цена пошла в сторону последнего экстремума
 bool newTrend = false;
 if ((aExtremums[num1].price < aExtremums[num0].price && aExtremums[num0].price < price) ||
     (aExtremums[num1].price > aExtremums[num0].price && aExtremums[num0].price > price))
 {
  if (LessDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num1].price - price), digits))
  {
   newTrend = true;
  }
 }
 else
 {
  if (LessDoubles(MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num0].price - price), digits))
  {
   newTrend = true;
  }
 }
 return(newTrend);
}
