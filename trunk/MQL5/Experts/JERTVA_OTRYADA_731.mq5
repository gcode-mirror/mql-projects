//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <JAPAN\jExperts\CTihiro.mqh>      //класс CTihiro
#include <Lib CisNewBar.mqh>               //для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh>   //подключаем библиотеку TradeManager
#include <TradeManager\BackTest.mqh>       //бэктест
#include <TradeManager\GetBackTest.mqh>

#include <TradeManager\TradeBreak.mqh>     //блокатор торговли

#import "kernel32.dll"
int      WinExec(uchar &NameEx[], int dwFlags);
#import

//+------------------------------------------------------------------+
//| Торговый робот для экспериментирования                           |
//| По совместительству - сестра-близнец TIHIRO                      |
//+------------------------------------------------------------------+

//внешние, задаваемые пользователем параметры эксперта
input uint              bars=500;                   //количество баров истории
input double            orderVolume = 1;            //размер лота
input TAKE_PROFIT_MODE  takeprofitMode = TPM_HIGH;  //режим вычисления тейк профита
input double            takeprofitFactor = 1.0;     //коэффициент тейк профита  
input int               priceDifferent=10;          //разница цен для поиска экстремумов
input double            min_profit=-0.002;          //минимальный уровень прибыли
input double            max_drawdown=3;             //максимальный уровень просадки
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
TradeBreak  * tb  = new TradeBreak (min_profit,max_drawdown);  // объет класса TradeBreak
int handle;                                        // хэндл индикатора
bool allow_continue = true;                        // флаг продолжения 
ENUM_TM_POSITION_TYPE signal;                      // переменная для хранения торгового сигнала

datetime  currentTime;                             // текущее время 
long depth;                                         // глубина истории позиций

int OnInit()
{

 //вычисляем торговую ситуацию в самом начале работы эксперта
 //WBackTest * wBackTest = new WBackTest("backtest","ВЫЧИСЛЕНИЕ БЭКТЕСТА",5,12,200,50,0,0,CORNER_LEFT_UPPER,0);
 currentTime = TimeCurrent();
 depth = ctm.GetHistoryDepth();
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
  {

  }



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
         ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
        }
      }
    }
  }
  
 void OnTrade()
  {
     // если текущая глубина истории позиций больше предыдущей глубины истории
     if (ctm.GetHistoryDepth() > depth)
      {
      if ( tb.UpdateData(ctm.GetPositionHistory(currentTime,TimeCurrent()) ) )
       {
      //  Comment("Время тогда = ",TimeToString(currentTime)," время теперь = ",TimeToString(TimeCurrent()) );
        currentTime = TimeCurrent()+1;
        depth = ctm.GetHistoryDepth();
       }
      else
       Alert("ОСТАНАВЛИВАЕМ РОБОТА");
       _StopFlag = true;
      }
      
  Comment (" ТЕКУЩИЙ БАЛАНС = ",tb.GetCurrentProfit()," МИН. ПРОФИТ = ",min_profit);
  }
  