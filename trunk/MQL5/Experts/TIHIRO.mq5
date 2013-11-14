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
input uint     bars=150;          //количество баров истории
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
CisNewBar     isNewBar;                            // для проверки на новый бар
CTradeManager ctm;                                 // объект класса TradeManager
int handle;                                        // хэндл индикатора
bool allow_continue = true;                        // флаг продолжения 
ENUM_TM_POSITION_TYPE signal;                      // переменная для хранения торгового сигнала
int errTrendDown, errTrendUp;                      // переменные для отчета об ошибках

int OnInit()
{
 //загружаем хэндл индикатора Tihiro
 //handle = iCustom(symbol, timeFrame, "TihiroIndicator",timeFrame); 
 //вычисляем торговую ситуацию в самом начале работы эксперта
 //allow_continue = tihiro.OnNewBar(); 
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| TIHIRO деинициализация эксперта                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //если есть позволение продолжать торговать
   if (allow_continue) 
    {

     ctm.OnTick();
     //если сформирован новый бар
     if ( isNewBar.isNewBar() > 0 )
      {  
       allow_continue = tihiro.OnNewBar();
      }
     //получаем сигнал 
     if (allow_continue)
      {
       signal = tihiro.GetSignal();   
       if (signal != OP_UNKNOWN)
        {      
         Print(" ТЕЙК ПРОФИТ = ", tihiro.GetTakeProfit());
         ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
        }
      }
    }
  }