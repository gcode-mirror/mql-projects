//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 
#include <TradeManager\TradeManagerEnums.mqh>
#include <CompareDoubles.mqh>  



//+------------------------------------------------------------------+
//| Класс для эксперта TIHIRO                                        |
//+------------------------------------------------------------------+


class CTihiro 
 {
    //приватные поля класса
   private:
    //буферы 
    double   _price_high[];      // массив высоких цен  
    double   _price_low[];       // массив низких цен  
    datetime _price_time[];      // массив времени 
    //символ
    string  _symbol;
    //таймфрейм
    ENUM_TIMEFRAMES _timeFrame;
    //пункт
    double  _point;
    //количество баров истории
    uint    _bars;  
    //тангенс линий тренда
    double  _tg;
    //расстояние от линии тренда до последнего экстремума
    double  _range;
    //тейк профит
    int  _takeProfit;
    //стоп лосс
    int  _stopLoss;
    //цена, на которой была открыта позиция
    double  _open_price;
    //экстремум предыдущий
    Extrem  _extr_up_past,_extr_down_past;
    //экстремум последующий
    Extrem  _extr_up_present,_extr_down_present;
    //флаги нахождения экстремумов
    short   _flag_up,_flag_down;
    //тип ситуации
    short   _trend_type;
    //расположение точки относительно линии тренда на предыдущем тике
    short   _prev_locate;
    //приватные методы класса
   private:
    //получает значение тангенса угла наклона линии тренда   
    void    GetTan();  
    //возвращает расстояние от экстремума до линии тренда
    void    GetRange();
    //ищет TD точки для тренд линии
    void    GetTDPoints();
    //распознает ситуацию
    void    RecognizeSituation();
    //проверяет, выше или ниже линии тренда находится текущая точка
    short   TestPointLocate(datetime cur_time,double cur_price);
   public:
   //конструктор класса 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,double point,uint bars):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _point(point),
     _bars(bars)
    { 
     //порядок как в таймсерии
     ArraySetAsSeries(_price_high,true);
     ArraySetAsSeries(_price_low, true);   
     ArraySetAsSeries(_price_time,true);        
    }; 
   //деструктор класса
   ~CTihiro()
    {
     //удаляем массивы из динамической памяти
     ArrayFree(_price_high);
     ArrayFree(_price_low);
     ArrayFree(_price_time);
    };
   // -----------------------------------------------------------------------------
   //возвращает торговый сигнал
   ENUM_TM_POSITION_TYPE   GetSignal();   
   //возвращает тейкпрофит
   int    GetTakeProfit() { return (_takeProfit); };
   //возвращает стоп лосс
   int    GetStopLoss()   { return (_stopLoss); };
   //получает от эксперта указатели на массивы максимальных и минимальных цен баров
   //и вычисляет все необходимые значения по ним
   //а имеено - экстремумы, тангенс трендовой линии, расстояние от линии тренда до последнего экстремума 
   bool    OnNewBar();

 };

//+------------------------------------------------------------------+
//| Описание приватных методов                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//получает значение тангенса угла наклона линии тренда
 {
  if (_trend_type == TREND_DOWN)
   {  
    _tg =  (_extr_down_present.price-_extr_down_past.price)/(_extr_down_present.time - _extr_down_past.time);
   }
  if (_trend_type == TREND_UP)
   {  
    _tg =  (_extr_up_present.price-_extr_up_past.price)/(_extr_up_present.time - _extr_up_past.time);
   }   
 }
 
void CTihiro::GetRange(void)
//вычисляет тейк профит
 {
  datetime L;
  double H;
  if (_trend_type == TREND_DOWN)
   {
    L=_extr_up_present.time-_extr_down_past.time;  
    H=_extr_up_present.price-_extr_down_past.price;
   }
  if (_trend_type == TREND_UP)
   {
    L=_extr_down_present.time-_extr_up_past.time;  
    H=_extr_down_present.price-_extr_up_past.price;
   }   
  _range=MathAbs(H-_tg*L);
 }
 
void CTihiro::GetTDPoints()
//ищет TD точки для тренд линий
 {
   short i; 
   _flag_down = 0;
   _flag_up   = 0;
   //проходим по циклу и вычисляем экстремумы
   for(i = 1; i < (_bars-1) && (_flag_down<2||_flag_up<2); i++)
    {
     //если текущая high цена больше high цен последующей и предыдущей
     if ( GreatDoubles(_price_high[i],_price_high[i-1]) && GreatDoubles(_price_high[i],_price_high[i+1]) && _flag_down < 2 )     
      {
       if (_flag_down == 0)
        {
         //сохраняем правый экстремум
         _extr_down_present.SetExtrem(_price_time[i+1],_price_high[i]);
         _flag_down = 1; 
        }
       else 
        {
         if( GreatDoubles(_price_high[i],_extr_down_present.price) )
          {
          //сохраняем левый экстремум
          _extr_down_past.SetExtrem(_price_time[i+1],_price_high[i]);               
          _flag_down = 2;
          }
        }            
      }  //нисходящий тренд
//если текущая low цена меньше low цен последующей и предыдущей
     if ( LessDoubles(_price_low[i],_price_low[i-1]) && LessDoubles(_price_low[i],_price_low[i+1])&&_flag_up < 2)     
      {
       if (_flag_up == 0)
        {
         //сохраняем правый экстремум
         _extr_up_present.SetExtrem(_price_time[i+1],_price_low[i]);
         _flag_up = 1; 
        }
       else 
        {
         if(LessDoubles(_price_low[i],_extr_up_present.price))         
          {
          //сохраняем левый экстремум
          _extr_up_past.SetExtrem(_price_time[i+1],_price_low[i]);        
          _flag_up = 2;
          }
        }            
      }  //восходящий тренд               
     }
 } 
 
void  CTihiro::RecognizeSituation(void)
//возвращает ситуацию 
 {
   _trend_type = NOTREND; //нет тренда
   if (_flag_down == 2) //если нисходящий тренд найден
    {
     if (_flag_up > 0) //если хоть один экстремум найден
      {
       if (_extr_up_present.time > _extr_down_present.time)  //если нижний экстремум позднее линии тренда
        {
         //расположение текущей цены относительно линии тренда
         _prev_locate = TestPointLocate(TimeCurrent(),SymbolInfoDouble(_symbol,SYMBOL_ASK));
         //сохраним, что тренд нисходящий
         _trend_type = TREND_DOWN; 
         return;
        } 
      }
    }
   if (_flag_up == 2) //если восходящий тренд найден
    {
     if (_flag_down > 0) //если хоть один экстремум найден
      {
       if (_extr_down_present.time > _extr_up_present.time)  //если верхний экстремум позднее линии тренда
        {
         //расположение текущей цены относительно линии тренда
         _prev_locate = TestPointLocate(TimeCurrent(),SymbolInfoDouble(_symbol,SYMBOL_BID));        
         //сохраним, что тренд восходящий
         _trend_type = TREND_UP; 
         return;
        } 
      }
    }      
 }
 
short CTihiro::TestPointLocate(datetime cur_time,double cur_price)
//проверяет, выше или ниже линии трейда находится текущая точка
 {
   datetime time;
   double price;
   double line_level;
   if (_trend_type == TREND_DOWN)
    {
     line_level = _extr_down_past.price+(_price_time[0]-_extr_down_past.time)*_tg;  //значение  линии тренда в данной точке 
     //Comment("ЗНАЧЕНИЕ ТРЕНДА DOWN = ",DoubleToString(line_level));
    }
   if (_trend_type == TREND_UP)
    {
     line_level = _extr_up_past.price+(_price_time[0]-_extr_up_past.time)*_tg;  //значение  линии тренда в данной точке 
     //Comment("ЗНАЧЕНИЕ ТРЕНДА UP = ",DoubleToString(line_level));     
    }    
   if (cur_price>line_level)
    {
   // Comment("ВЫШЕ");
    return 1;  //точка находится выше линии тренда
    }
   if (cur_price<line_level)
    {
   // Comment("НИЖЕ");
    return -1; //точка находится ниже линии тренда
    }
  //  Comment("НА ЛИНИИ");
   return 0;   //точка находится на линии тренда
 }
 
//+------------------------------------------------------------------+
//| Описание публичных методов                                       |
//+------------------------------------------------------------------+  
 
ENUM_TM_POSITION_TYPE CTihiro::GetSignal()
//возвращает торговый сигнал
 {
 datetime time;   //текущее время
 double   price;  //текущая цена
 short    locate; //положение точки относительно тренда
  //если тренд восходящий 
 if (_trend_type == TREND_UP) 
   {
    //сохраняем текущее время
    time = TimeCurrent();
    //сохраняем цену BID, как низкую
    price = SymbolInfoDouble(_symbol,SYMBOL_BID);
    //сохраняем в локальную переменную положение цены относительно линии тренда
    locate  = TestPointLocate(time,price);
    //если цена перевалила за линию тренда сверху вниз
    if (_prev_locate > 0 && locate<=0)
     {
     //вычисляем тейк профит
      _takeProfit = _range/_point;  
    
      //выставляем стоп лосс
      _stopLoss   =  (_extr_down_present.price-price)/_point;   
      Print("ПЕРЕСЕЧЕНИЕ");       
      _prev_locate = locate; 
      return OP_SELL;
     }
    _prev_locate = locate;     
   }
  //если тренд нисходящий
  if (_trend_type == TREND_DOWN) 
   {
    //сохраняем текущее время
    time = TimeCurrent();   
    //сохраняем цену ASK, как высокую
    price = SymbolInfoDouble(_symbol,SYMBOL_ASK);
    //сохраняем в локальную переменную положение цены относительно линии тренда
    locate  = TestPointLocate(time,price);    
    //если цена перевалила за линию тренда снизу вверх
    if (_prev_locate < 0 && locate >= 0)
     { 
      //вычисляем тейк профит
      _takeProfit = _range/_point; 
 
      //выставляем стоп лосс
      _stopLoss   = (price-_extr_up_present.price)/_point;
     
      Print("ПЕРЕСЕЧЕНИЕ");       
      
      _prev_locate = locate;       
      return OP_BUY;
     }    
    _prev_locate = locate;
   }  
  return OP_UNKNOWN;  
 }


bool CTihiro::OnNewBar()
//вычисляет все необходимые значения по массивам максимальных и минимальных цен баров
 {
  //загружаем буферы 
  if(CopyHigh(_symbol, _timeFrame, 1, _bars, _price_high) <= 0 ||
     CopyLow (_symbol, _timeFrame, 1, _bars, _price_low)  <= 0 ||
     CopyTime(_symbol, _timeFrame, 0, _bars+1, _price_time) <= 0  ) 
      {
       Print("Не удалось загрузить бары из истории");
       return false;
      }
  // вычисляем экстремумы (TD-точки линии тренда)
  GetTDPoints();  
  //Comment("ВНИЗ (",TimeToString(_extr_up_past.time),";",DoubleToString(_extr_up_past.price),") (",TimeToString(_extr_up_present.time),";",DoubleToString(_extr_up_present.price),")");
  // вычисляем тип тренда (ситуацию)
  RecognizeSituation();
  
  
       if (_trend_type == TREND_DOWN)
      Comment("ТИП ВНИЗ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);
     if (_trend_type == TREND_UP)
      Comment("ТИП ВВЕРХ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);
     if (_trend_type == NOTREND)
      Comment("НЕТ ТОРГОВОЙ СИТУАЦИИ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);     
  
  
  // вычисляем тангенс тренд линии
  GetTan();
     Print("ТАНГЕНС = ",DoubleToString(_tg));
  // вычисляем расстояние от экстремума до линии тренда
  GetRange();
  if (_trend_type==TREND_DOWN)
   PrintFormat("Расстояние от экстремума до линии тренда DOWN = %s",DoubleToString(_range));
  if (_trend_type==TREND_UP)
   PrintFormat("Расстояние от экстремума до линии тренда UP = %s",DoubleToString(_range));  
  return true; 
 }
 
