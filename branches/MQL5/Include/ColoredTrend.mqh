//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>

//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
enum ENUM_MOVE_TYPE      // Тип движения
  {
   MOVE_TYPE_UNKNOWN = 0,
   MOVE_TYPE_TREND_UP,        // Тренд вверх - синий
   MOVE_TYPE_TREND_UP_FORBIDEN,   // Тренд вверх, запрещенный верхним ТФ - фиолетовый
   MOVE_TYPE_TREND_DOWN,          // Тренд вниз - красный
   MOVE_TYPE_TREND_DOWN_FORBIDEN, // Тренд вниз, запрещенный верхним ТФ - коричневый
   MOVE_TYPE_CORRECTION_UP,       // Коррекция вверх, корректируется тренд вниз - розовый
   MOVE_TYPE_CORRECTION_DOWN,     // Коррекция вниз, корректируется тренд вверх - голубой
   MOVE_TYPE_FLAT,                // Флэт - желтый
  };
  
string MoveTypeToString(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("движение не определено");
      case MOVE_TYPE_TREND_UP: return("тренд вверх");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("тренд вверх запрещен со старшего ТФ");
      case MOVE_TYPE_TREND_DOWN: return("тренд вниз");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("тренд вниз запрещен со старшего ТФ");
      case MOVE_TYPE_CORRECTION_UP: return("коррекция вверх");
      case MOVE_TYPE_CORRECTION_DOWN: return("коррекция вниз");
      case MOVE_TYPE_FLAT: return("флэт");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }
  
string MoveTypeToColor(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("цвет не определен");
      case MOVE_TYPE_TREND_UP: return("синий");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("фиолетовый");
      case MOVE_TYPE_TREND_DOWN: return("красный");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("коричневый");
      case MOVE_TYPE_CORRECTION_UP: return("розовый");
      case MOVE_TYPE_CORRECTION_DOWN: return("голубой");
      case MOVE_TYPE_FLAT: return("желтый");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }//+------------------------------------------------------------------+
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
  int FillTimeSeries(MqlRates &_rates[], int count, int start_pos);
  int difToNewExtremum;
  double difToTrend;
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  void CountMoveType(int count, int shift = 1);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
};

//+-----------------------------------------+
//| Конструктор                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3)
{
 ArraySetAsSeries(enumMoveType, true);
 if (shift < 3) shift = 3;
 _symbol = symbol;
 _period = period;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 difToNewExtremum = 70;
 difToTrend = 2;
  
 ArrayResize(aExtremums, shift);
 // Заполним массив с информацией о таймсериях
 MqlRates rates[];
 int rates_total = FillTimeSeries(rates, shift, count - 1); // получим размер заполненного массива 
 Print("rates_total= ", rates_total);
 
 for(int bar = 1; bar < shift - 1 && !IsStopped(); bar++) // вычисляем экстремумы со сдвигом в историю
 { 
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
void CColoredTrend::CountMoveType(int count, int shift = 1)
{
 // Заполним массив с информацией о таймсериях
 MqlRates rates[];
 int rates_total = FillTimeSeries(rates, count + shift); // получим размер заполненного массива
 // Выделим память под массивы цветов и экстремумов
 ArrayResize(enumMoveType, rates_total);
 ArrayResize(aExtremums, rates_total);
 
 for(int bar = shift; bar < count + shift - 1 && !IsStopped(); bar++) // заполняем ценами заданное количество баров, кроме формирующегося
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  
  /*
  PrintFormat("bar = %d, экстремумы num0=%.05f, num1=%.05f, num2=%.05f, num0 - num1 =%.05f, num0 - close=%.05f"
             , bar, aExtremums[num0].price, aExtremums[num1].price, aExtremums[num2].price
             , MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend, MathAbs(aExtremums[num0].price - rates[bar].close));
  */ 
            
  if (LessDoubles(MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num0].price - rates[bar].close), digits))
  {// Если разница между последним (0) и предпоследним (1) экстремумом в "difToTrend" раз меньше нового движения 
   PrintFormat("bar = %d, движение больше последней разницы экстремумов", bar);
   if (LessDoubles(rates[bar].close, aExtremums[num0].price, digits)) // если текущее закрытие ниже последнего экстремума 
   {
    //PrintFormat("bar = %d, начался тренд вниз, текущее закрытие=%.05f меньше последнего экстремума=%.05f", bar, rates[bar].close, aExtremums[num0].price);
    enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
    //continue;
   }
   if (GreatDoubles(rates[bar].close, aExtremums[num0].price, digits)) // если текущее закрытие выше последнего экстремума 
   {
    //PrintFormat("bar = %d, начался тренд вверх, текущее закрытие=%.05f больше последнего экстремума=%.05f", bar, rates[bar].close, aExtremums[num0].price);
    enumMoveType[bar] = MOVE_TYPE_TREND_UP;
    //continue;
   }
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP) && LessDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
   lastOnTrend = num0;
  }
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN) && GreatDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
   lastOnTrend = num0;
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && LessDoubles(rates[bar].close, aExtremums[lastOnTrend].price, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && GreatDoubles(rates[bar].close, aExtremums[lastOnTrend].price, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_TREND_UP;
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
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP) && (aExtremums[bar].direction > 0) &&
       (LessDoubles(aExtremums[bar].price, aExtremums[num2].price, digits) // если новый максимум меньше предыдущего
        || GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
                       ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // разница между максимумами(минимумами) меньше движения (разницы между противоположными)
                       ,digits)))   
   {
    //PrintFormat("bar = %d, начался флэт, новый максимум меньше предыдущего num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
    enumMoveType[bar] = MOVE_TYPE_FLAT;
   }
   
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN) && (aExtremums[bar].direction < 0) &&
        (GreatDoubles(aExtremums[bar].price, aExtremums[num2].price, digits)
         || GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // или РАЗНИЦА между вторым и первым БОЛЬШЕ РАЗНИЦЫ между вторым и нулевым 
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
  && GreatDoubles(aExtremums[last].price, vol2 + difToNewExtremum*Point(), 5))
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
int CColoredTrend::FillTimeSeries(MqlRates &_rates[], int count, int start_pos = 0)
{
 //--- счетчик попыток
   int attempts = 0;
//--- сколько скопировано
   int copied = 0;
//--- делаем 25 попыток получить таймсерию по нужному символу
 while(attempts < 25 && (copied = CopyRates(_symbol, _period, start_pos, count, _rates))<0) // справа налево от 0 до count, всего count элементов
 {
  Sleep(100);
  attempts++;
  //if(messages) PrintFormat("%s CopyRates(%s) attempts=%d", __FUNCTION__, name, attempts);
 }
//--- если не удалось скопировать достаточное количество баров
 if(copied != count)
 {
 //--- сформируем строку сообщения
  string comm = StringFormat("Для символа %s удалось получить только %d баров из %d затребованных",
                             _symbol,
                             copied,
                             count
                            );
  //--- выведем сообщение в комментарий на главное окно графика
  Comment(comm);
  //--- выводим сообщения
  //if(messages) Print(comm);
 }
 return(copied);
}
