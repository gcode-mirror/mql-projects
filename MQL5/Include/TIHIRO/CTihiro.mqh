//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 

//+------------------------------------------------------------------+
//| Класс для эксперта TIHIRO                                        |
//+------------------------------------------------------------------+

class CTihiro 
 {
    //приватные поля класса
   private:
    //буферы 
    double   price_high[];      // массив высоких цен  
    double   price_low[];       // массив низких цен  
    datetime price_date[];      // массив времени 
    //символ
    string _symbol;
    //таймфрейм
    ENUM_TIMEFRAMES _timeFrame;
    //режим обработки тиков
    TIHIRO_MODE _mode;
    //количество баров истории
    uint   _bars;  
    //тангенс линий тренда
    double _tg;
    //расстояние от линии тренда до последнего экстремума
    double _range;
    //цена, на которой была открыта позиция
    double _open_price;
    //экстремум предыдущий
    Extrem _extr_up_past,_extr_down_past;
    //экстремум последующий
    Extrem _extr_up_present,extr_down_present;
    //экстремум последний
    Extrem _extr_up_last,_extr_down_last;
    //приватные методы класса
   private:
    //получает значение тангенса угла наклона линии тренда   
    void    GetTan();  
    //возвращает расстояние от экстремума до линии тренда
    void    GetRange();
    //ищет TD точки для тренд линии
    void    GetTDPoints();
    //проверяет, выше или ниже линии тренда находится текущая точка
    short   TestPointLocate(datetime cur_time,double cur_price);
    //проверяет, что цена зашла за линию тренда
    short   TestCrossTrendLine(string symbol);
    //проверяет, что цена зашла за зону range
    short   TestReachRange(string symbol);
   public:
   //конструктор класса 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,uint bars):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    { 
     //порядок как в таймсерии
     ArraySetAsSeries(price_high,true);
     ArraySetAsSeries(price_low, true);   
     ArraySetAsSeries(price_date,true);        
    }; 
   //деструктор класса
   ~CTihiro()
    {
     //удаляем массивы из динамической памяти
     ArrayFree(price_high);
     ArrayFree(price_low);
     ArrayFree(price_date);
    };
   // -----------------------------------------------------------------------------
   //получает от эксперта указатели на массивы максимальных и минимальных цен баров
   //и вычисляет все необходимые значения по ним
   //а имеено - экстремумы, тангенс трендовой линии, расстояние от линии тренда до последнего экстремума 
   void   OnNewBar(datetime &price_time[],double &price_high[],double &price_low[]);
   //на каждом тике проверяет, перешла ли цена за тренд линию  
   //возвращает торговый сигнал 
   //0 - UNKNOWN, 1 - BUY, 2 - SELL
   short  OnTick(string symbol);
 };

//+------------------------------------------------------------------+
//| Описание приватных методов                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//получает значение тангенса угла наклона линии тренда
 {
  _tg =  (_extr_present.price-_extr_past.price)/(_extr_present.time - _extr_past.time);
 }
 
void CTihiro::GetRange()
//вычисляет расстояние от экстремума до линии тренда
 {
  datetime L=_extr_present.time-_extr_past.time;  
  double H=_extr_present.price-_extr_past.price;
  _range=H-_tg*L;
 }
 
bool CTihiro::GetTDPoints()
//ищет TD точки для тренд линий
 {
   short i; 
   bool flag_down = false;
   bool
   //проходим по циклу и вычисляем экстремумы
   for(i = 1; i < _bars; i++)
    {
     //если текущая high цена больше high цен последующей и предыдущей
     if (price_high[i] > price_high[i-1] && price_high[i] > price_high[i+1])
      {
       if (flag_down == false)
        {
         //сохраняем правый экстремум
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down = true; 
        }
       else 
        {
         if(price_high[i] > point_down_right.price)
          {
          //сохраняем левый экстремум
          point_down_left.SetExtrem(time[i],high[i]);               
          return true;
          }
        }            
      }  //нисходящий тренд
//если текущая low цена меньше low цен последующей и предыдущей
     if (low[i] < low[i-1] && low[i] < low[i+1] && flag_up < 2 )
      {
       if (flag_up == 0)
        {
         //сохраняем правый экстремум
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up++; 
        }
       else 
        {
         if(low[i] < point_up_right.price)
          {
          //сохраняем левый экстремум
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up++;
          }
        }            
      }  //восходящий тренд               
     }
   return false; //не найдены оба экстремума
 } 
 
short CTihiro::TestPointLocate(datetime cur_time,double cur_price)
//проверяет, выше или ниже линии трейда находится текущая точка
 {
   double line_level=_extr_past.price+(cur_time-_extr_past.time)*_tg;  //значение  линии тренда в данной точке 
   if (cur_price>line_level)
    return 1;  //точка находится выше линии тренда
   if (cur_price<line_level)
    return -1; //точка находится ниже линии тренда
   return 0;   //точка находится на линии тренда
 }
 
short CTihiro::TestCrossTrendLine(string symbol)
//проверяет, что цена зашла за линию тренда 
 {
 datetime time;   //текущее время
 double   price;  //текущая цена
  //если тренд восходящий 
 if (_tg > 0) 
   {
    //сохраняем текущее время
    time = TimeCurrent();
    //сохраняем цену BID, как низкую
    price = SymbolInfoDouble(symbol,SYMBOL_BID);
    //если цена перевалила за линию тренда
    if (TestPointLocate(time,price)<=0)
     {
      //переводим в режим ожидания достижения уровня range
      _mode = TM_REACH_THE_RANGE;
      return SELL;
     }
   }
  //если тренд нисходящий
  if (_tg < 0) 
   {
    //сохраняем текущее время
    time = TimeCurrent();   
    //сохраняем цену ASK, как высокую
    price = SymbolInfoDouble(symbol,SYMBOL_ASK);
    //если цена перевалила за линию тренда
    if (TestPointLocate(time,price)>=0)
     {
      //переводим в режим ожидания достижения уровня range
      _mode = TM_REACH_THE_RANGE;     
      return BUY;
     }    
   }  
  return UNKNOWN;  
 }
  
short CTihiro::TestReachRange(string symbol)
//проверяет, что цена зашла за зону range
 {
  double cur_price;
  double abs;
  //если тренд восходящий
  if (_tg > 0)
   {
     cur_price = SymbolInfoDouble(symbol,SYMBOL_BID);
     abs=_open_price-cur_price;
     if (abs>_range) 
      {
       //переводим в режим ожидания пересечения с линией тренда
       _mode = TM_WAIT_FOR_CROSS;      
       return BUY;
      }
   }
  //если тренд нисходящий
  if (_tg < 0)
   {
     cur_price = SymbolInfoDouble(symbol,SYMBOL_ASK);   
     abs=cur_price-_open_price;
     if (abs>_range) 
      {
       //переводим в режим ожидания пересечения с линией тренда
       _mode = TM_WAIT_FOR_CROSS;            
       return SELL;
      }
   }  
  return UNKNOWN;
 }
 
//+------------------------------------------------------------------+
//| Описание публичных методов                                       |
//+------------------------------------------------------------------+ 

void CTihiro::OnNewBar(string symbol)
//вычисляет все необходимые значения по массивам максимальных и минимальных цен баров
 {
   if(CopyHigh(symbol, 0, 1, _bars, price_high) <= 0 ||
      CopyLow (symbol, 0, 1, _bars, price_low) <= 0 ||
      CopyTime(symbol,0,1,_bars,price_date)<=0) 
       {
        Print("Не удалось загрузить бары из истории");
        return;
       }
  //если режим ожидания пересечения цены с линией тренда
  if (_mode==TM_WAIT_FOR_CROSS)
  {
  //вычисляем экстремумы
  // ---- здесь будет вычисление экстремумов
  
  //если экстремумы вычислены - распознать тип ситуации (один из двух)
  //если ситуация распознана, то
  
  //вычисляем тангенс линии тренда
  GetTan();
  //вычисляем range
  GetRange();
  }
 }
 
short CTihiro::OnTick(string symbol)
//на каждом тике проверяет, перешла ли цена за тренд линию  
{
  //режим обработки тиков
 switch (_mode)
 {
 //ожидание пересечения линии тренда
 case TM_WAIT_FOR_CROSS:   
  return TestCrossTrendLine(symbol); 
 break;
 //режим ожидания достижения уровня range
 case TM_REACH_THE_RANGE:
  return TestReachRange(symbol);
 break; 
 } //switch
 return UNKNOWN;
}