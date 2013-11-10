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
input int      takeProfit=0;   //take profit
input int      stopLoss=0;     //stop loss
input double   orderVolume = 1;  //размер лота
input ulong    magic = 111222;   //магическое число
input bool     trailing = false;     //трейлинг
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

double trendLineDown[];
double trendLineUp[];
int handle;

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
   short signal;
   int errTrendDown, errTrendUp;
   ctm.OnTick();
   //если сформирован новый бар
   
   if ( isNewBar.isNewBar() > 0 )
   {  
    tihiro.OnNewBar();
   }
   //получаем сигнал 
   signal = tihiro.GetSignal(); 
   if (signal == BUY)
    {
    //Comment("ТЕЙК ПРОФИТ = ",tihiro.GetTakeProfit()*_Point);
    ctm.OpenUniquePosition(symbol,OP_BUY,orderVolume,0,tihiro.GetTakeProfit(),0,0,0);
    }
   if (signal == SELL)
    {
    //Comment("ТЕЙК ПРОФИТ = ",tihiro.GetTakeProfit()*_Point);    
    ctm.OpenUniquePosition(symbol,OP_SELL,orderVolume,0,tihiro.GetTakeProfit(),0,0,0); 
    }
    
   if (trailing)
   {
    ctm.DoTrailing();
   }
  }