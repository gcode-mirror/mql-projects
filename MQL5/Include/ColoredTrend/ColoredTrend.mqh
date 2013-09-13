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
  int _depth;
  ENUM_MOVE_TYPE enumMoveType[];
  SExtremum aExtremums[];
  int digits;
  int num0, num1, num2;  // номера последних экстремумов
  int lastOnTrend;       // последний экстремум текущего тренда
  double difToNewExtremum;
  double difToTrend;     // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
  int ATR_handle;
  double ATR_buf[];
  int _count;            // Количество баров для расчета индикатора 
  int _shift;            // Количество баров в истории
  
  int FillTimeSeries(MqlRates &_rates[], int count, int start_pos, ENUM_TF tfType = CURRENT_TF);
  int FillATRBuf(int count, int start_pos);
  bool isCorrectionEnds(MqlRates &cur_rates[], MqlRates &bot_rates[], int bar, ENUM_MOVE_TYPE move_type);
  bool isLastBarHuge(MqlRates &rates[]);
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  void CountMoveType(ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3) : _count(count), _shift(shift)
{
 ArraySetAsSeries(enumMoveType, true);
 ArraySetAsSeries(ATR_buf, true);
 if (shift < 3) shift = 3;
 _symbol = symbol;
 _period = period;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 //difToNewExtremum = 70;
 difToTrend = 2;  // Во столько раз новый бар должен превышать предыдущий экстремум, что бы начался тренд.
 
 //подключаем индикатор и получаем его хендл 
 ATR_handle = iATR(_symbol, _period, 100);
 if(ATR_handle == INVALID_HANDLE)                      //проверяем наличие хендла индикатора
 {
  Print("Не удалось получить хендл ATR");             //если хендл не получен, то выводим сообщение в лог об ошибке
  //return(-1);                                          //завершаем работу с ошибкой
 }
 // Получаем данные буфера в массив
 FillATRBuf(shift, count - 1);
 
 ArrayResize(aExtremums, shift);
 // Заполним массив с информацией о таймсериях
 MqlRates rates[];
 int rates_total = FillTimeSeries(rates, shift, count - 1); // получим размер заполненного массива 
 //Print("rates_total= ", rates_total);
 
 for(int bar = 1; bar < shift - 1 && !IsStopped(); bar++) // вычисляем экстремумы со сдвигом в историю
 { 
  difToNewExtremum = ATR_buf[bar] / 2;
  //Print("Constructor: ATR/2 = ", difToNewExtremum);
  aExtremums[bar] =  isExtremum(rates[bar - 1].close, rates[bar].close, rates[bar + 1].close);
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
  }
 }
}

//+------------------------------------------+
//| Функция вычисляет тип движения рынка     |
//+------------------------------------------+
void CColoredTrend::CountMoveType(ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 // Заполним массив с информацией о таймсериях
 MqlRates rates[];
 MqlRates bottomTF_rates[];
 int rates_total = FillTimeSeries(rates, _count + _shift); // получим размер заполненного массива
 FillTimeSeries(bottomTF_rates, _count + _shift, 0, BOTTOM_TF);
 FillATRBuf(_count + _shift);                              // заполним массив данными индикатора ATR
 // Выделим память под массивы цветов и экстремумов
 ArrayResize(enumMoveType, rates_total);
 ArrayResize(aExtremums, rates_total);
 
 for(int bar = _shift; bar < _count + _shift - 1 && !IsStopped(); bar++) // заполняем ценами заданное количество баров, кроме формирующегося
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  difToNewExtremum = ATR_buf[bar] / 2;
  //Print("ATR/2 = ", difToNewExtremum);
  /*
  PrintFormat("bar = %d, экстремумы num0=%.05f, num1=%.05f, num2=%.05f, num0 - num1 =%.05f, num0 - close=%.05f"
             , bar, aExtremums[num0].price, aExtremums[num1].price, aExtremums[num2].price
             , MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend, MathAbs(aExtremums[num0].price - rates[bar].close));
  */ 
            
  if (LessDoubles(MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num0].price - rates[bar].close), digits))
  {// Если разница между последним (0) и предпоследним (1) экстремумом в "difToTrend" раз меньше нового движения 
   //PrintFormat("bar = %d, движение больше последней разницы экстремумов", bar);
   if (LessDoubles(rates[bar].close, aExtremums[num0].price, digits)) // если текущее закрытие ниже последнего экстремума 
   {
    if (topTF_Movement == MOVE_TYPE_FLAT)
    {
     enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN;
    }
    else
    {
     //PrintFormat("bar = %d, начался тренд вниз, текущее закрытие=%.05f меньше последнего экстремума=%.05f", bar, rates[bar].close, aExtremums[num0].price);
     enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
     //continue;
    }
   }
   if (GreatDoubles(rates[bar].close, aExtremums[num0].price, digits)) // если текущее закрытие выше последнего экстремума 
   {
    if (topTF_Movement == MOVE_TYPE_FLAT)
    {
     enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN;
    }
    else
    {
     //PrintFormat("bar = %d, начался тренд вниз, текущее закрытие=%.05f меньше последнего экстремума=%.05f", bar, rates[bar].close, aExtremums[num0].price);
     enumMoveType[bar] = MOVE_TYPE_TREND_UP;
     //continue;
    }
   }
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
       LessDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
   lastOnTrend = num0;
  }
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
       GreatDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
   lastOnTrend = num0;
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
       isCorrectionEnds(rates, bottomTF_rates, bar, MOVE_TYPE_CORRECTION_UP))
  {
   if (topTF_Movement == MOVE_TYPE_FLAT)
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN;
   }
   else
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
   }
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
       isCorrectionEnds(rates, bottomTF_rates, bar, MOVE_TYPE_CORRECTION_DOWN))
  {
   if (topTF_Movement == MOVE_TYPE_FLAT)
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN;
   }
   else
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_UP;
   }
  }

  aExtremums[bar] =  isExtremum(rates[bar - 1].close, rates[bar].close, rates[bar + 1].close, num0);
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
   
   //PrintFormat("bar = %d, экстремумы num0 =%.05f, num1=%.05f, num2=%.05f", bar, aExtremums[num0].price, aExtremums[num1].price, aExtremums[num2].price);
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
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
   
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
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
  //PrintFormat("bar = %d, нет изменений, цвет предыдущего бара %s", bar, MoveTypeToColor(enumMoveType[bar - 1]));
  //if (enumMoveType[bar] == -1)
   //enumMoveType[bar] = enumMoveType[bar - 1];
  //else
   //PrintFormat("enumMoveType[%d]=%d",bar,enumMoveType[bar]);
 }
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
  && LessDoubles(aExtremums[last].price, vol2 - difToNewExtremum*Point(), 5))
 {
  res.direction = 1;// максимум в точке vol2
 } 
 return(res); // нет экстремума в точке vol2
}

//+-------------------------------------------------+
//| Функция заполняет массив экстремумов из истории |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(MqlRates &_rates[], int count, int start_pos = 0, ENUM_TF tfType = CURRENT_TF)
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
 while(attempts < 25 && (copied = CopyRates(_symbol, period, start_pos, count, _rates))<0) // справа налево от 0 до count, всего count элементов
 {
  Sleep(100);
  attempts++;
 }
//--- если не удалось скопировать достаточное количество баров
 if(copied != count)
 {
  string comm = StringFormat("Для символа %s удалось получить только %d баров из %d затребованных",
                             _symbol,
                             copied,
                             count
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  Comment(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
int CColoredTrend::FillATRBuf(int count, int start_pos = 0)
{
 //--- счетчик попыток
   int attempts = 0;
//--- сколько скопировано
   int copied = 0;
//--- делаем 25 попыток получить таймсерию по нужному символу
 while(attempts < 25 && (copied = CopyBuffer(ATR_handle, 0, start_pos, count, ATR_buf)) < 0) // справа налево от 0 до count, всего count элементов
 {
  Sleep(100);
  attempts++;
 }
//--- если не удалось скопировать достаточное количество баров
 if(copied != count)
 {
  string comm = StringFormat("Для символа %s удалось получить только %d баров из %d затребованных",
                             _symbol,
                             copied,
                             count
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  Comment(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| Функция заполняет массив индикатора ATR из истории |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(MqlRates &cur_rates[], MqlRates &bot_rates[], int bar, ENUM_MOVE_TYPE move_type)
{
 bool extremum_condition, bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(cur_rates[bar].close, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge(bot_rates);
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(cur_rates[bar].close, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge(bot_rates);
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge(MqlRates &rates[])
{
 double sum;
 for(int i = _shift; i < _count + _shift - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / _shift;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 return(GreatDoubles(lastBar, avgBar*2));
}