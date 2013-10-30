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
input int      takeProfit=100;   //take profit
input int      stopLoss=100;     //stop loss
input double   orderVolume = 1;  //размер лота
input ulong    magic = 111222;   //магическое число
//буферы для хранения цен 
double price_high[];      // массив высоких цен  
double price_low[];       // массив низких цен  
datetime price_date[];    // массив времени 
//символ
string symbol=_Symbol;
//таймфрейм
ENUM_TIMEFRAMES timeFrame = _Period; 
//объекты классов
CTihiro       tihiro(bars); // объект класса CTihiro   
CisNewBar     newCisBar;    // для проверки на новый бар
CTradeManager ctm;          // объект класса TradeManager


int OnInit()
  {
  
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
   ctm.OnTick();
   //если сформирован новый бар
   if ( newCisBar.isNewBar() > 0 )
    {

     tihiro.OnNewBar(price_high,price_low);
    }
   //получаем сигнал 
   signal = tihiro.OnTick(symbol); 
   if (signal == BUY)
    ctm.OpenUniquePosition(symbol,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
   if (signal == SELL)
    ctm.OpenUniquePosition(symbol,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0); 
  }

