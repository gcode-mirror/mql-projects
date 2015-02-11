//+------------------------------------------------------------------+
//|                                                CExtremum.mqh     |
//|                        Copyright 2014, Dmitry Onodera            |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""
#property version   "1.01"
// класс для вычисления экстремумов

// подключение необходимых библиотек
#include <CompareDoubles.mqh> // для сравнения действительных чисел
#include "SExtremum.mqh"      // стркутура экстремумов

#define DEFAULT_PERCENTAGE_ATR 1.0   // по умолчанию новый экстремум появляется когда разница больше среднего бара

// класс для вычисления послених экстремумов
class CExtremum
  {
   protected:
    string _symbol;             // символ
    int    _digits;             // количество знаков после запятой для сравнения действительных чисел
    ENUM_TIMEFRAMES _tf_period; // период
    int    _handle_ATR;         // хэндл ATR
    double _averageATR;         // среднее значение бара
    double _percentage_ATR;     // коэфициент отвечающий за то во сколько раз движение цены должно превысить средний бар что бы появился новый экстремум  
   public:
    CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr);  // конструктор класса
   // основные методы класса
   bool isExtremum(SExtremum &extrHigh,SExtremum &extrLow, datetime start_pos_time = __DATETIME__,  bool now = true);  // есть ли экстремум на данном баре   
   double AverageBar (datetime start_pos); // возвращает средний размер бара   
  };
  
// кодирование методов класса вычисения экстремумов


// конструктор класса
CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr)
 {
  // сохраняем поля класса
  _symbol = symbol;
  _tf_period = period;
  _handle_ATR = handle_atr;
  _digits = 8;
  // вычисляем среднее значение ATR по 
  switch(_tf_period)
  {
   case(PERIOD_M1):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M5):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M15):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H4):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_D1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_W1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_MN1):
      _percentage_ATR = 2.2;
      break;
   default:
      _percentage_ATR = DEFAULT_PERCENTAGE_ATR;
      break;
  }  
  // вычисление среднего значения бара
  _averageATR = AverageBar(TimeCurrent());
 }
 
// метод вычисления экстремума на текущем баре
bool CExtremum::isExtremum(SExtremum &extrHigh,SExtremum &extrLow,datetime start_pos_time=__DATETIME__,bool now=true)
 {
 double high = 0, low = 0;       // временная переменная в которой будет хранится цена для расчета max и min соответственно
 double averageBarNow;           // для хранения среднего размера бара
 double difToNewExtremum;        // для хранения минимального расстояния между экстремумами
 datetime extrHighTime = 0;      // время прихода верхнего экстремума 
 datetime extrLowTime = 0;       // время прихода нижнего экстремума
 MqlRates bufferRates[1];
 //Comment("Время = ",TimeToString(start_pos_time) );
 if(CopyRates(_symbol, _tf_period, start_pos_time, 1, bufferRates) < 1)
 {
  Print("Ошибка CExtremum::isExtremum. Не удалось скопировать котировки");
  return(false); 
 }
 // вычисляем средний размер бара
 averageBarNow = AverageBar(start_pos_time);
 // если удалось вычислить среднее значение и
 if (averageBarNow > 0)
  _averageATR = averageBarNow; 
 // вычисляем минимальное расстояние между экстремумами
 difToNewExtremum = _averageATR * _percentage_ATR;  
 
 if (extrHigh.time > extrLow.time && bufferRates[0].time < extrHigh.time && !now) return (false); 
 if (extrHigh.time < extrLow.time && bufferRates[0].time < extrLow.time && !now) return (false); 
 
 if (now) // за время жизни бара цена close проходит все его значения от low до high
 {        // соответсвено если на данном баре есть верхний экстремум то он будет достигнут когда close будет max  и наоборот с low
  high = bufferRates[0].close;
  low  = bufferRates[0].close;
 }
 else    // во время работы на истории мы смотрим на бар один раз соотвественно нам сразу нужно узнать его максимум и минимум
 {
  high = bufferRates[0].high;
  low = bufferRates[0].low;
 }
 
 if ( (extrHigh.direction == 0  && extrLow.direction == 0)                                                  // Если экстремумов еще нет то говорим что сейчас экстремум
   || ((extrHigh.time > extrLow.time) && (GreatDoubles(high, extrHigh.price,_digits) ) )                    // Если последний экстремум - High, и цена пробила экстремум в ту же сторону 
   || ((extrHigh.time < extrLow.time) && (GreatDoubles(high,extrLow.price + difToNewExtremum,_digits) ) ) ) // Если последний экстремум - Low, и цена отошла от экстремума на мин. расстояние в обратную сторону   
 {
  // сохраняем время прихода верхнего экстремума
  if (now) // если экстремумы вычисляются в реальном времени
   extrHighTime = TimeCurrent();
  else  // если экстремумы вычисляются на истории
   extrHighTime = bufferRates[0].time;
 }
 
 if ( ( extrLow.direction == 0 && extrHigh.direction == 0)                                                  // Если экстремумов еще нет то говорим что сейчас экстремум
   || ((extrLow.time > extrHigh.time) && (LessDoubles(low,extrLow.price,_digits) ) )                        // Если последний экстремум - Low, и цена пробила экстремум в ту же сторону
   || ((extrLow.time < extrHigh.time) && (LessDoubles(low,extrHigh.price - difToNewExtremum,_digits) ) ) )  // Если последний экстремум - High, и цена отошла от экстремума на мин. расстояние в обратную сторону
 {
  // если на этом баре пришел верхний экстремум
  if (extrHighTime > 0)
   {
    // если close ниже open, то говорим, что верхний экстремум пришел раньше нижнего
    if(bufferRates[0].close <= bufferRates[0].open) 
     {
      extrLowTime = bufferRates[0].time + datetime(100);
     }
    else // иначе полагаем, что нижний пришел раньше верхнего
     {
      extrHighTime = bufferRates[0].time + datetime(100);
      extrLowTime  = bufferRates[0].time;
     }
   }
  else // иначе просто сохраняем время прихода нижнего экстремума
   {
    if (now) // если экстремумы вычисляются в реальном времени
     extrLowTime = TimeCurrent();
    else // если экстремумы вычисляются на истории
     extrLowTime = bufferRates[0].time;
   }
 }
 
 // заполняем поля структур экстремумов
 
 // если пришел новый верхний экстремум
 if (extrHighTime > 0)
  {
   // заполняем поля экстремума
   extrHigh.direction = 1;
   extrHigh.price = high;
   extrHigh.time = extrHighTime;
  }
 // если пришел новый нижний экстремум
 if (extrLowTime > 0)
  {
   // заполняем поля экстремума
   extrLow.direction = -1;
   extrLow.price = low;
   extrLow.time = extrLowTime;
  }  
  /*if ( now)
   Print("Время High = ",TimeToString(extrHighTime)," Время Low = ",TimeToString(extrLowTime) );*/
   return (true);
 }
 
// метод вычисления среднего размера бара
double CExtremum::AverageBar(datetime start_pos)
 {
  int copied = 0;
  double buffer_average_atr[1];
  if (_handle_ATR == INVALID_HANDLE)
   {
    PrintFormat("%s ERROR. I have INVALID HANDLE = %d, %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period));
    return (-1);
   }
  copied = CopyBuffer(_handle_ATR, 0, start_pos, 1, buffer_average_atr);
  if (copied < 1) 
   {
    PrintFormat("%s ERROR. I have this error = %d, %s. copied = %d, calculated = %d, buf_num = %d start_pos = %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period), copied, BarsCalculated(_handle_ATR), _handle_ATR,TimeToString(start_pos));
    return(0);
   }
  return (buffer_average_atr[0]);
 }