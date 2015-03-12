//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TIHIRO\CTihiro.mqh>              //класс CTihiro
#include <Lib CisNewBar.mqh>               //для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh>   //подключаем библиотеку TradeManager

//+------------------------------------------------------------------+
//| TIHIRO эксперт                                                   |
//+------------------------------------------------------------------+

//внешние, задаваемые пользователем параметры эксперта
input uint              bars=500;                   //количество баров истории
input double            orderVolume = 1;            //размер лота
input TAKE_PROFIT_MODE  takeprofitMode = TPM_HIGH;  //режим вычисления тейк профита
input double            takeprofitFactor = 1.0;     //коэффициент тейк профита  
input int               priceDifferent=10;          //разница цен для поиска экстремумов
//символ
string symbol=_Symbol;
//таймфрейм
ENUM_TIMEFRAMES timeFrame = _Period; 
//пункт
double point = _Point;
//объекты классов
CTihiro       tihiro(symbol,timeFrame,point,bars,takeprofitMode,takeprofitFactor,priceDifferent); // объект класса CTihiro   
CisNewBar     isNewBar;                            // для проверки на новый бар
CTradeManager ctm;                                 // объект класса TradeManager
int handle;                                        // хэндл индикатора
bool allow_continue = true;                        // флаг продолжения 
ENUM_TM_POSITION_TYPE signal;                      // переменная для хранения торгового сигнала

SPositionInfo pos_info;
STrailing trailing;
int OnInit()
{
 iCustom(_Symbol,_Period,"TihiroIndicator");
 pos_info.tp = 0;
 pos_info.volume = 1.0;
 pos_info.expiration = 0;
 pos_info.priceDifference = 0;
 pos_info.sl = 0;
 pos_info.tp = 0;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.minProfit    = 0;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing    = 0;
 
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
        // ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
         pos_info.type = signal;
         ctm.OpenUniquePosition(symbol,timeFrame,pos_info,trailing,0);
        }
      }
    }
  }