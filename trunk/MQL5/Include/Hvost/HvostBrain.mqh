//+------------------------------------------------------------------+
//|                                                   HvostBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>               // для сравнения действительных чисел
#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include <CLog.mqh>                         // для лога
#include <ContainerBuffers.mqh>     // контейнер буферов данных там же CisNewBar

#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define K 0.5
#define _channelDepth 3 // глубина канала
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class CHvostBrain : public CArrayObj
{
 private:
  // внешние параметры
  //bool _skipLastBar;     // пропустить последний бар при рассчете
  int  _tailDepth;         // =20 глубина определения хвоста (изменить на OnInit())
  string _symbol;
  ENUM_TIMEFRAMES _period;
  CContainerBuffers *_conbuf;
  int opened_position;     // флаг открытой позиции (0 - нет позиции, 1 - buy, (-1) - sell)
  double h;                // ширина канала
  double price_bid;        // текущая цена bid
  double price_ask;        // текущая цена ask
  double prev_price_bid;   // предыдущая цена bid
  double prev_price_ask;   // предыдущая цена ask 
  double max_price;        // максимальная цена канала
  double min_price;        // минимальная цена канала
  bool wait_for_sell;      // флаг ожидания условия открытия на SELL
  bool wait_for_buy;       // флаг ожидания условия открытия на BUY
  CisNewBar *isNewBarEld;  // для вычисления формирования нового бара на старшем ТФ
  // переменные для хранения времени движения цены
  datetime signal_time;        // время получения сигнала пробития ценой уровня на расстояние H  
  ENUM_TIMEFRAMES periodEld;   // период старшего таймфрейма
  double average_price;        // (ЧЁ?) значение средней цены на момент получения сигнала о скачке (присваивание переменных wait_for_sell или wait_for_buy)
 public:
                     CHvostBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf);
                    ~CHvostBrain();
                     int  GetSignal();
                     bool IsBeatenBars (int type);
                     bool IsBeatenExtremum (int type);
                     bool TestEldPeriod (int type);
                     int  GetLastTrend();
                     bool IsFlatNow();
                     int  GetOpenedPosition()   {return opened_position;}
                     double GetPriceBid()       { return price_bid;}
                     double GetPriceAsk()       { return price_ask;}
                     double GetMaxChannelPrice(){ return max_price;}
                     double GetMinChannelPrice(){ return min_price;}
                     ENUM_TIMEFRAMES GetPeriod(){ return _period;}
                     void SetOpenedPosition(int p){opened_position = p;}
                     bool CountChannel();
                     
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CHvostBrain::CHvostBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf)
{
 _tailDepth = 20;
 _symbol = symbol;
 _period = period;
 _conbuf =  conbuf;
 opened_position = 0;
 prev_price_bid = 0;    
 prev_price_ask = 0;     
 wait_for_sell = false;    
 wait_for_buy= false;   
 // заменить на функцию, которая определяет старший ТФ по отношению к текущему
 periodEld = GetTopTimeframe(_period);   // заменить на функцию, которая определяет старший ТФ по отношению к текущему
 // если удалось вычислить параметры канала движения на старшем ТФ
 if (CountChannel()) 
  average_price = (max_price + min_price)/2;            
 // сохраняем период страшего таймфрейма 
 isNewBarEld = new CisNewBar(_symbol, periodEld);
 // создаем хэндл индикатора PriceBasedIndicator
}
 //+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CHvostBrain::~CHvostBrain()
{
 delete isNewBarEld;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CHvostBrain::GetSignal()
{
 // сохраняем предыдущие значения цен
 prev_price_ask = price_ask;
 prev_price_bid = price_bid;
 // получаем текущее значение цен 
 price_bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
 price_ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 if (isNewBarEld.isNewBar() > 0)
 {
  // то перевычисляем параметры канала 
  CountChannel();
  wait_for_buy = false;
  wait_for_sell = false;
 }  
 log_file.Write(LOG_DEBUG, StringFormat("Для периода = %s", PeriodToString(_period)));
 // если цена bid отошла вверх и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
 log_file.Write(LOG_DEBUG, StringFormat("(pBid(%f)-pAsk(%f))(%f) > K*h(%f)=(%f) && wait_for_sell(%s) && opened_position(%s)!=-1", price_bid, max_price, (price_bid-max_price), h, K*h, BoolToString(wait_for_sell), BoolToString(opened_position)));
 if ( GreatDoubles(price_bid-max_price,K*h) && !wait_for_sell && opened_position!=-1 )
 {      
  log_file.Write(LOG_DEBUG, " Цена bid отошла вверх и расстояние от нее до уровня в 2 раза больше чем ширина канала");
  // то переходим в режим отскока для открытия на SELL 
  wait_for_sell = true;   
  log_file.Write(LOG_DEBUG, "Режим ожидания отбития для открытия позиции на SELL");
  wait_for_buy = false;
  //countBars = 0;
  // сохраняем время получения сигнала пробития уровня движения цены
  signal_time = TimeCurrent(); 
 }
 // если цена ask отошла вниз и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
 if ( GreatDoubles(min_price-price_ask, K*h) && !wait_for_buy && opened_position!=1 )
 {     
  log_file.Write(LOG_DEBUG, " Цена ask отошла вверх и расстояние от нее до уровня в 2 раза больше чем ширина канала");    
  // то переходим в режим отскока для открытия на BUY
  wait_for_buy = true; 
  wait_for_sell = false;
  log_file.Write(LOG_DEBUG, "Режим ожидания отбития для открытия позиции на BUY");
  //countBars = 0;    
  // сохраняем время получения сигнала пробития уровня движения цены
  signal_time = TimeCurrent();           
 }   
 // если перешли в режим ожидания отбития для открытия позиции на SELL
 if (wait_for_sell)
 {  
  
  // если удалось пробить последние два бара 
  if (IsBeatenBars(-1))
  {
   // если на старшем ТФ слева нет тел баров
   if (TestEldPeriod(-1) /*&& IsFlatNow ()GetLastTrend ()!=1*/)
   {
    opened_position = -1;
    wait_for_sell = false;     
    wait_for_buy = false;
    log_file.Write(LOG_DEBUG, "Режим ожидания сброшен");
    return SELL;       
   }
  }
 } 
 // если перешли в режим ожидания отбития для открытия позиции на BUY
 if (wait_for_buy)
 {
  // если удалось пробить последние два бара 
  if (IsBeatenBars(1))
  {
   log_file.Write(LOG_DEBUG, "Пробил последние два бара на IsBeatenBars(1)");
   // от текущей цены на старших ТФ нет тел свечей
   if (TestEldPeriod(1) /*&& IsFlatNow ()&& GetLastTrend ()!=-1*/)
   {
    log_file.Write(LOG_DEBUG, " Открываемся! от текущей цены на старших ТФ нет тел свечей TestEldPeriod(1)");
    opened_position = 1;
    wait_for_buy = false;
    wait_for_sell = false;
    return BUY;
   }
  }
 }  
 return NO_POSITION;
}
//+------------------------------------------------------------------+
// функция вычисляет параметры канала на старшем таймфрейме  
bool CHvostBrain::CountChannel()
{
 int startIndex = 2;//(_skipLastBar)?2:1;
 int indexMax = 0;
 int indexMin = 0;
 // Находим ндексы максимального и минимального элементов на глубине _channelDepth
 indexMax = ArrayMaximum(_conbuf.GetHigh(periodEld).buffer, startIndex, _channelDepth);
 indexMin = ArrayMinimum(_conbuf.GetLow(periodEld).buffer, startIndex, _channelDepth);
 if(indexMax < 0 || indexMin < 0)
 return (false);
 max_price = _conbuf.GetHigh(periodEld).buffer[indexMax];
 min_price = _conbuf.GetLow(periodEld).buffer[indexMin];
 log_file.Write(LOG_DEBUG, StringFormat("Был взят max_price = %f для периода %s на старшем периоде = %s", max_price, PeriodToString(_period), PeriodToString(periodEld)));

 h = max_price - min_price;
 return (true);
}  



// функция подсчета пробития последних двух баров
bool  CHvostBrain::IsBeatenBars (int type)
{
 //Print ("Count = ", _);
 double prices[];
 if (type == 1)  // если нужно проверить пробитие на BUY
 {
  if (GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[1]) 
   && GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[2]))
  {
   return (true);  // говорим, что успешно пробили последние два максимума
  }     
 }
 if (type == -1)  // если нужно проверить пробитие на SELL
 {
  if(LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[1]) 
  && LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[2]))
  {
   return (true);  // говорим, что успешно пробили последние два максимума
  }
 }
 return (false);  // ничего не пробили
}

// функция для закрытия позиции по экстремуму
bool  CHvostBrain::IsBeatenExtremum (int type)
{

 if (type == 1)
 {
  // условие закрытие позиции BUY
  if(LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[1]) 
  && LessDoubles(price_ask,_conbuf.GetLow(_period).buffer[0])
  && GreatDoubles(_conbuf.GetHigh(_period).buffer[1], _conbuf.GetHigh(_period).buffer[0])
  && GreatDoubles(_conbuf.GetHigh(_period).buffer[1], _conbuf.GetHigh(_period).buffer[2]))
  {
   return (true);
  } 
 }
 if (type == -1)
 {
  // условие закрытие позиции SELL 
  if(GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[1]) 
  && GreatDoubles(price_bid,_conbuf.GetHigh(_period).buffer[0])
  && LessDoubles(_conbuf.GetLow(_period).buffer[1], _conbuf.GetLow(_period).buffer[0])
  && LessDoubles(_conbuf.GetLow(_period).buffer[1], _conbuf.GetLow(_period).buffer[2]))
  {
   return (true);
  }    
 }
 return (false);
} 

// функция смотрит на старший ТФ и проверяет
bool  CHvostBrain::TestEldPeriod (int type)
{
 MqlRates eldPriceBuf[];  
 int copied_rates = -1;
 int startIndex = 2; //(_skipLastBar)?2:1;
 for (int attempts=0; attempts<25; attempts++)
 {
  copied_rates = CopyRates(_symbol, periodEld, startIndex, _tailDepth, eldPriceBuf);
  Sleep(100);
 }
 if (copied_rates < _tailDepth)
 {
  log_file.Write(LOG_DEBUG, "Не удалось прогрузить буферы цен");
  //Print("Не удалось прогрузить все котировки");
  return (false);
 }
 // проходим по скопированным барам и проверяем, чтобы не попадались тела баров
 for (int ind = 0; ind < _tailDepth + 1 - startIndex; ind++)
 { 
  // если нужно открываться на Buy, но на пути попалось тело бара
  if (type == 1  &&  ( GreatDoubles(price_ask,eldPriceBuf[ind].open) || GreatDoubles(price_ask,eldPriceBuf[ind].close) ) )
   return (false);
  // если нужно открываться на Sell, но на пути попалось тело бара
  if (type == -1 &&  ( LessDoubles(price_bid,eldPriceBuf[ind].open)  || LessDoubles(price_bid,eldPriceBuf[ind].close) ) )
   return (false);      
 }
 return (true);
} 

// функция возвращает тип последнего тренда
int  CHvostBrain::GetLastTrend ()
{
 int bars = Bars(_symbol,_period);
 for (int ind = 1; ind < bars;)
 {
  // если нашли трендовое движение вверх
  if (_conbuf.GetPBI(periodEld).buffer[ind] == 1.0 
   || _conbuf.GetPBI(periodEld).buffer[ind] == 2.0)
   return (1);
  // если нашли трендовое движение вниз
  if (_conbuf.GetPBI(periodEld).buffer[ind] == 3.0 
   || _conbuf.GetPBI(periodEld).buffer[ind] == 4.0)
   return (-1);
  ind++;
 }
 return (0);
}
 
// функция возвращает true, если в данный момент - флэт
bool  CHvostBrain::IsFlatNow ()
{
 if (_conbuf.GetPBI(periodEld).buffer[0] == 7.0)
  return (true);
 return (false);
}