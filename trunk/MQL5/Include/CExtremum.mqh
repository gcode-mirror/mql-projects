//+------------------------------------------------------------------+
//|                                                CExtremum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""
#property version   "1.01"

#include <CompareDoubles.mqh>
#include <Lib CisNewBarDD.mqh>

#define ARRAY_SIZE 4                 // количество хранимых экстремумов
#define DEFAULT_PERCENTAGE_ATR 1.0   // по умолчанию новый экстремум появляется когда разница больше среднего бара

struct SExtremum
{
 int direction;                      // направление экстремума: 1 - max; -1 -min; 0 - null
 double price;                       // цена экстремума: для max - high; для min - low
 datetime time;                      // время бара на котором возникает экстремум
};

// Класс который хранит и вычисляет последние ARRAY_SIZE экстремумов
class CExtremum
{
 protected:
 string _symbol;
 int _digits;
 ENUM_TIMEFRAMES _tf_period;
 //--параметры ATR для difToNewExtremum-----
 int _handle_ATR;
 double _percentage_ATR;   // коэфициент отвечающий за то во сколько раз движение цены должно превысить средний бар что бы появился новый экстремум
 //-----------------------------------------
 SExtremum extremums[ARRAY_SIZE];
 
 public:
 CExtremum();
 CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr);
~CExtremum();

 int isExtremum(SExtremum& extr_array[], datetime start_pos_time = __DATETIME__,  bool now = true);  // есть ли экстремум на данном баре
 int RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true);                       // обновить массив экстремумов
 double AverageBar (datetime start_pos);
 SExtremum getExtr(int i);
 void PrintExtremums();
 int  ExtrCount();
 double getPercentageATR() { return(_percentage_ATR); }
 void SetSymbol(string symb) { _symbol = symb; }
 void SetPeriod(ENUM_TIMEFRAMES tf) { _tf_period = tf; }
 void SetDigits(int digits) { _digits = digits; }
 void SetPercentageATR();
};

CExtremum::CExtremum(void)
           { // так как _handle_ATR не определен то экстремумы будут еа каждом баре
             // рекомендуется использовать конструктор с параметрами!
            _symbol = Symbol();
            _tf_period = Period();
            SetPercentageATR();
            _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
           }

CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr):
            _symbol (symbol),
            _tf_period (period),
            _handle_ATR(handle_atr)
            {
             SetPercentageATR();
             _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
            }
CExtremum::~CExtremum()
           {
           }             

//-----------------------------------------------------------------
// функция возвращает количество новых экстремумов на данном баре
// параметры
// SExtremum& extr_array [] - массив в который записываются новые экстремумы в порядке их появления
// datetime start_pos_time  - время бара на котором ищем экстремумы
// bool now - флаг для того что бы отличать работает мы на истории или в реальном времени(на истории на один бар заходим только один раз)
//-----------------------------------------------------------------
int CExtremum::isExtremum(SExtremum& extr_array [], datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum result1 = {0, -1}; // временная переменная для записи max если он есть
 SExtremum result2 = {0, -1}; // временная переменная для записи min если он есть
 int count = 0;               // считаем сколько появилось экстремумов
 MqlRates buffer[1];

 if(CopyRates(_symbol, _tf_period, start_pos_time, 1, buffer) < 1)
  PrintFormat("%s %s Rates buffer: error = %d, calculated = %d, start_index = %s", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), GetLastError(), Bars(_symbol, _tf_period), TimeToString(start_pos_time));
 double difToNewExtremum = AverageBar(start_pos_time) * _percentage_ATR;  // расчет минимального расстояние между экстремумами
 double high = 0, low = 0;
 
 if(extremums[0].time == buffer[0].time && !now) return(0); //исключаем повторное определение экстремумов на истории
 
 if (now) // за время жизни бара цена close проходит все его значения от low до high
 {        // соответсвено если на данном баре есть верхний экстремум то он будет достигнут когда close будет max  и наоборот с low
  high = buffer[0].close;
  low = buffer[0].close;
 }
 else    // во время работы на истории мы смотрим на бар один раз соотвественно нам сразу нужно узнать его максимум и минимум
 {
  high = buffer[0].high;
  low = buffer[0].low;
 }
 
 if ((extremums[0].direction == 0 ) // Если экстремумов еще нет то говорим что сейчас экстремум
   ||(extremums[0].direction >  0 && (GreatDoubles(high, extremums[0].price, _digits))) // Если цена пробила экстремум 
   ||(extremums[0].direction <  0 && (GreatDoubles(high, extremums[0].price + difToNewExtremum, _digits)))) // Если цена отошла от экстремума на минимальное расстояние
 {
  result1.direction = 1;       // запоминаем направление, цену и время появления экстремума
  result1.price = high;
  result1.time = buffer[0].time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), high);
 }
 
 if ((extremums[0].direction == 0 ) // Если экстремумов еще нет то говорим что сейчас экстремум
   ||(extremums[0].direction <  0 && (LessDoubles(low, extremums[0].price, _digits))) //Если цена пробила экстремумо                    
   ||(extremums[0].direction >  0 && (LessDoubles(low, extremums[0].price - difToNewExtremum, _digits)))) // Если цена отошла от экстремума на минимальное расстояние
 {
  result2.direction = -1;     // запоминаем направление, цену и время появления экстремума
  result2.price = low;
  result2.time = buffer[0].time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), low);
 }
 
 if(buffer[0].close <= buffer[0].open) //если close ниже open то сначала пишем max потом min
 {
  extr_array[0] = result1;
  extr_array[1] = result2;
 }
 else                                  //если close выше open то сначала пишем min потом max
 {
  extr_array[0] = result2;
  extr_array[1] = result1;
 }  
 
 return(count);
}

//-------------------------------------------------------------------------------------
// функция проверяет есть на данном баре экстремумы и если есть добавляет в массив экстремумов
// по принципу стэка 
//-------------------------------------------------------------------------------------
int CExtremum::RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum new_extr[2] = {{0, -1}, {0, -1}}; //временная переменная в которую isExtremum запишет те экстремумы что у него появились
 int count_new_extrs = isExtremum(new_extr, start_pos_time, now);
 
 if(count_new_extrs > 0)   // если появились новые экстремумы
 {
  for(int i = 0; i < 2; i++) // идем по массиву экстремумов
  {
   if (new_extr[i].direction != 0)
   {
    if (new_extr[i].direction == extremums[0].direction) // если новый экстремум в том же напрвлении, что и последний, то обновляем
    {
     extremums[0] = new_extr[i];
    }
    else                                                 // если новый экстремум в противоположном напрвлении, от последнего, сдвигаем все и добавляем новый
    {
     for(int j = ARRAY_SIZE-1; j >= 1; j--)
     {
      extremums[j] = extremums[j-1];     
     }
     extremums[0] = new_extr[i];
    }       
   }
  }
 }
 return(count_new_extrs);
}

//-------------------------------------------------------------------------------------
// возвращает значение среднего бара для данного бара
//-------------------------------------------------------------------------------------
double CExtremum::AverageBar (datetime start_pos)  // подгружаем значения с индикатора
{
 double buffer_average_atr[1];
 if (_handle_ATR == INVALID_HANDLE)
 {
  PrintFormat("%s ERROR. I have INVALID HANDLE = %d, %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period));
 }
 if(CopyBuffer(_handle_ATR, 0, start_pos, 1, buffer_average_atr) == 1) 
  return(buffer_average_atr[0]);
 else
 {
  PrintFormat("%s ERROR. I have this error = %d, %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period));
  return(0);
 }
}

//-------------------------------------------------------------------------------------
// возвращает количество сохраненных экстремумов
//-------------------------------------------------------------------------------------
int CExtremum::ExtrCount()      
{
 int count = 0;
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  if(extremums[i].direction != 0) 
    count++;      // если у элемента массива экстремумов ненулевое направление значит это сохраненный экстремум
 }
 return(count);
}

//-------------------------------------------------------------------------------------
// возвращает экстремум по его порядковому номеру
//-------------------------------------------------------------------------------------
SExtremum CExtremum::getExtr(int i)
{
 SExtremum zero = {0, 0};
 if(i < 0 || i >= ARRAY_SIZE)
  return zero;     // в случае неверного индекса вовзвращаем дефолтный элемент
 return(extremums[i]);
}

//-------------------------------------------------------------------------------------
// печатает информацию по всем хранимым экстремумам
//-------------------------------------------------------------------------------------
void CExtremum::PrintExtremums()
{
 string result = "";
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  StringConcatenate(result, result, StringFormat("num%d = {%d %.05f %s ,(%.05f)}; ", i, extremums[i].direction, extremums[i].price, TimeToString(extremums[i].time), AverageBar(extremums[i].time)*_percentage_ATR));
 }
 PrintFormat("%s %s %s %s", __FUNCTION__, TimeToString(TimeCurrent()),EnumToString((ENUM_TIMEFRAMES)_tf_period), result);
}


//-------------------------------------------------------------------------------------
// устанавливает нужное значение коэфицента в зависимости от выбранного таймфрейма
//-------------------------------------------------------------------------------------
void CExtremum::SetPercentageATR()
{
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
}