//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager\TradeManagerEnums.mqh>
#include <CompareDoubles.mqh>  
//+------------------------------------------------------------------+
//| Класс для эксперта TIHIRO                                        |
//+------------------------------------------------------------------+

//константы 
#define UNKNOWN    0
#define BUY        1
#define SELL       2
#define TREND_UP   3
#define TREND_DOWN 4
#define NOTREND    5

//класс экстремумов
class Extrem
  {
   public:
   datetime time;   //временное положение экстремума
   uint n_bar;      //номер бара 
   double price;    //ценовое положение экстремума
   void SetExtrem(uint n,double p){ n_bar=n; price=p; };    //сохраняет экстремум
   void SetExtrem(datetime t,double p){ time=t; price=p; };    //сохраняет экстремум   
   Extrem(datetime t=0,double p=0):time(t),price(p){};      //конструктор
  };
  
//перечисление режимов вычисления тейк профита
enum TAKE_PROFIT_MODE
 {
  TPM_HIGH=0, //высокие цены
  TPM_CLOSE,  //цены закрытия
 };

class CTihiro 
 {
    //приватные поля класса
   private:
    //буферы 
    double   _price_high[];      // массив высоких цен  
    double   _price_low[];       // массив низких цен  
    double   _price_close[];     // массив цен закрытия
    double   _parabolic[];       // значение индикатора Parabolic SAR
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
    //цены на предыдущем тике
    double   _prev_bid;
    double   _prev_ask;
    //хэндл индикатора Parabolic SAR
    int _handle_parabolic;
    //режим вычисления тейк профита
    TAKE_PROFIT_MODE _takeProfitMode;
    //коэффициент вычисления тейк профита
    double _takeProfitFactor;
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
    short   TestPointLocate(double cur_price);
    //вычисляет тейк профит согласно заданным пользователем параметрами
    void    CalculateTakeProfit();
   public:
   //конструктор класса 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,double point,uint bars,TAKE_PROFIT_MODE takeProfitMode,double takeProfitFactor):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _point(point),
     _bars(bars),
     _takeProfitMode(takeProfitMode),
     _takeProfitFactor(takeProfitFactor)
    { 
     //порядок как в таймсерии
     ArraySetAsSeries(_price_high,true);
     ArraySetAsSeries(_price_low, true);  
     ArraySetAsSeries(_price_close,true);
     _handle_parabolic = iSAR(_symbol,_timeFrame,0.02,0.2);      
     _prev_ask = -1;
     _prev_bid = -1;     
    }; 
   //деструктор класса
   ~CTihiro()
    {
     //удаляем массивы из динамической памяти
     ArrayFree(_price_high);
     ArrayFree(_price_low);
     ArrayFree(_price_close);
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
    _tg =  (_extr_down_present.price-_extr_down_past.price)/( _extr_down_past.n_bar - _extr_down_present.n_bar);
   }
  if (_trend_type == TREND_UP)
   {  
    _tg =  (_extr_up_present.price-_extr_up_past.price)/(_extr_up_past.n_bar - _extr_up_present.n_bar);
   }   
 }
 
void CTihiro::GetRange(void)
//вычисляет тейк профит
 {
  datetime L;
  double H;
  if (_trend_type == TREND_DOWN)
   {
    L=_extr_down_past.n_bar-_extr_up_present.n_bar;  
    
    switch (_takeProfitMode)
     {
      case TPM_HIGH:
      H=_price_close[_extr_up_present.n_bar]-_extr_down_past.price;
      break;
     }
   }
  if (_trend_type == TREND_UP)
   {
    L=_extr_up_past.n_bar-_extr_down_present.n_bar;  
    
    switch (_takeProfitMode)
     {
      H=_price_close[_extr_down_present.n_bar]-_extr_up_past.price;
     }
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
         _extr_down_present.SetExtrem(i+1,_price_high[i]);
         _flag_down = 1; 
        }
       else 
        {
         if( GreatDoubles(_price_high[i],_extr_down_present.price) )
          {
          //сохраняем левый экстремум
          _extr_down_past.SetExtrem(i+1,_price_high[i]);               
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
         _extr_up_present.SetExtrem(i+1,_price_low[i]);
         _flag_up = 1; 
        }
       else 
        {
         if(LessDoubles(_price_low[i],_extr_up_present.price))         
          {
          //сохраняем левый экстремум
          _extr_up_past.SetExtrem(i+1,_price_low[i]);        
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
       if (_extr_up_present.n_bar < _extr_down_present.n_bar)  //если нижний экстремум позднее линии тренда
        {
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
       if (_extr_down_present.n_bar < _extr_up_present.n_bar)  //если верхний экстремум позднее линии тренда
        {      
         //сохраним, что тренд восходящий
         _trend_type = TREND_UP; 
         return;
        } 
      }
    }      
 }
 
short CTihiro::TestPointLocate(double cur_price)
//проверяет, выше или ниже линии трейда находится текущая точка
 {
   datetime time;
   double price;
   double line_level;
   if (_trend_type == TREND_DOWN)
    {
     line_level = _extr_down_past.price+_extr_down_past.n_bar*_tg;  //значение  линии тренда в данной точке 
    }
   if (_trend_type == TREND_UP)
    {
     line_level = _extr_up_past.price+_extr_up_past.n_bar*_tg;  //значение  линии тренда в данной точке     
    }    
   if (cur_price>line_level)
    {
     return 1;  //точка находится выше линии тренда
    }
   if (cur_price<line_level)
    {
     return -1; //точка находится ниже линии тренда
    }
   return 0;   //точка находится на линии тренда
 }
 
void CTihiro::CalculateTakeProfit(void)
//вычисляет тейк профит согласно заданным пользователем параметрами
 {
 
 } 
 
//+------------------------------------------------------------------+
//| Описание публичных методов                                       |
//+------------------------------------------------------------------+  
 
ENUM_TM_POSITION_TYPE CTihiro::GetSignal()
//возвращает торговый сигнал
 {
 //текущие цены по BID и ASK 
 double   price_bid = SymbolInfoDouble(_symbol,SYMBOL_BID);
 double   price_ask = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 if (_prev_ask==-1)
  {
   _prev_ask = price_ask;
   _prev_bid = price_bid;
  }
 //текущее положение цены относительно линии тренда
 short    locate_now;
 //предыдущее положение цены относительно линии тренда
 short    locate_prev;
  //если тренд восходящий 
 if (_trend_type == TREND_UP) 
   {
    //вычисляем текущее положение цены относительно линии тренда
    locate_now = TestPointLocate(price_bid);
    //вычисляем положение предыдующей цену относительно линии тренда
    locate_prev = TestPointLocate(_prev_bid);    
    //если цена перевалила за линию тренда сверху вниз
    if (locate_prev > 0 && locate_now<=0)
     {
     //вычисляем тейк профит
      _takeProfit = _range/_point;  
    
      //выставляем стоп лосс
      _stopLoss   =  (_extr_down_present.price-price_bid)/_point;   
     // _stopLoss   =  (_parabolic[0]-price_bid)/_point;  
      
      _prev_bid   = price_bid;
      _prev_ask   = price_ask; 
      return OP_SELL;
     }  
   }
  //если тренд нисходящий
  if (_trend_type == TREND_DOWN) 
   {   
    //вычисляем текущее положение цены относительно линии тренда
    locate_now = TestPointLocate(price_ask);
    //вычисляем положение предыдующей цену относительно линии тренда
    locate_prev = TestPointLocate(_prev_ask);      
    //если цена перевалила за линию тренда снизу вверх
    if (locate_prev < 0 && locate_now >= 0)
     { 
      //вычисляем тейк профит
      _takeProfit = _range/_point; 
 
      //выставляем стоп лосс
      _stopLoss   = (price_ask-_extr_up_present.price)/_point;
     // _stopLoss   = (price_ask-_parabolic[0])/_point;

      _prev_bid = price_bid;
      _prev_ask = price_ask;       
      return OP_BUY;
     }    
   
   }  
      _prev_bid = price_bid;
      _prev_ask = price_ask; 
  return OP_UNKNOWN;  
 }


bool CTihiro::OnNewBar()
//вычисляет все необходимые значения по массивам максимальных и минимальных цен баров
 {
  //загружаем буферы 
  if(CopyHigh (_symbol, _timeFrame, 1, _bars, _price_high)  <= 0 ||
     CopyLow  (_symbol, _timeFrame, 1, _bars, _price_low)   <= 0 ||
     CopyClose(_symbol, _timeFrame, 1, _bars, _price_close) <= 0 ||
     CopyBuffer(_handle_parabolic,  0, 0, 1, _parabolic)    <  0 ) 
      {
       Print("Не удалось загрузить бары из истории");
       return false;
      }
    
  
  // вычисляем экстремумы (TD-точки линии тренда)
  GetTDPoints();  
  // вычисляем тип тренда (ситуацию)
  RecognizeSituation();
   /* 
       if (_trend_type == TREND_DOWN)
      Comment("ТИП ВНИЗ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);
     if (_trend_type == TREND_UP)
      Comment("ТИП ВВЕРХ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);
     if (_trend_type == NOTREND)
      Comment("НЕТ ТОРГОВОЙ СИТУАЦИИ: FLAGDOWN = ",_flag_down," FLAGUP = ",_flag_up);     
  */
  // вычисляем тангенс тренд линии
  GetTan();
  // вычисляем расстояние от экстремума до линии тренда
  GetRange();
  return true; 
 }
 
