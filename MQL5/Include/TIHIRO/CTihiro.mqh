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
    //режим 
    TIHIRO_MODE _mode;
    //количество баров истории
    uint   _bars;  
    //тангенс линии тренда
    double _tg;
    //расстояние от линии тренда до последнего экстремума
    double _range;
    //цена, на которой была открыта позиция
    double _open_price;
    //экстремум предыдущий
    Extrem _extr_past;
    //экстремум последующий
    Extrem _extr_present;
    //экстремум последний
    Extrem _extr_last;
    //приватные методы класса
   private:
    //получает значение тангенса угла наклона линии тренда   
    void    GetTan();  
    //возвращает расстояние от экстремума до линии тренда
    void    GetRange();
    //проверяет, выше или ниже линии тренда находится текущая точка
    short   TestPointLocate(datetime cur_time,double cur_price);
    //проверяет, что цена зашла за линию тренда
    short   TestCrossTrendLine(string symbol);
    //проверяет, что цена зашла за зону range
    short   TestReachRange(string symbol);
   public:
   //конструктор класса 
   CTihiro(uint bars):
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    {
    
    }; 
   //получает от эксперта указатели на массивы максимальных и минимальных цен баров
   //и вычисляет все необходимые значения по ним
   //а имеено - экстремумы, тангенс трендовой линии, расстояние от линии тренда до последнего экстремума 
   void   OnNewBar(double  &price_max[],double  &price_min[]);
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

void CTihiro::OnNewBar(double &price_high[],double &price_low[])
//вычисляет все необходимые значения по массивам максимальных и минимальных цен баров
 {
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