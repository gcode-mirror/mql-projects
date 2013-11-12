//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TIHIRO\CTihiro.mqh>           //класс CTihiro
#include <Lib CisNewBar.mqh>            //для проверки формирования нового бара
#include <TradeManager/TradeManager.mqh> //подключаем библиотеку TradeManager

//+------------------------------------------------------------------+
//| TIHIRO эксперт                                                   |
//+------------------------------------------------------------------+
//внешние, задаваемые пользователем параметры эксперта
input uint     bars=50;          //количество баров истории
input double   orderVolume = 1;  //размер лота
//буферы для хранения цен 
double price_high[];      // массив высоких цен  
double price_low[];       // массив низких цен  
datetime price_date[];    // массив времени 
//символ
string symbol=_Symbol;
//таймфрейм
ENUM_TIMEFRAMES timeFrame = _Period; 
//пункт
double point = _Point;
//объекты классов
CTihiro       tihiro(symbol,timeFrame,point,bars); // объект класса CTihiro   
CisNewBar     isNewBar;                           // для проверки на новый бар
CTradeManager ctm;                                 // объект класса TradeManager
int handle;
bool first_load = false;

int OnInit()
{
 handle = iCustom(symbol, timeFrame, "TihiroIndicator",50); //загружаем хэндл индикатора Tihiro
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| TIHITO деинициализация эксперта                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ENUM_TM_POSITION_TYPE signal;
   int errTrendDown, errTrendUp;
   bool allow_continue = true;   //флаг продолжения 
   ctm.OnTick();
   //если сформирован новый бар
   
   if ( isNewBar.isNewBar() > 0 && first_load)
   {  
    allow_continue = tihiro.OnNewBar();
   }
   
   if (first_load == false)
   {
     allow_continue = tihiro.OnNewBar();
     first_load = true;
   }
   
   //получаем сигнал 
   if (allow_continue)
   {
    signal = tihiro.GetSignal();   
    if (signal != OP_UNKNOWN)
    {      
     Print("Стоп Лосс = ",tihiro.GetStopLoss(), " ТЕЙК ПРОФИТ = ", tihiro.GetTakeProfit()," ПОИНТ = ",DoubleToString(_Point));
     ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
    }
   }
  }