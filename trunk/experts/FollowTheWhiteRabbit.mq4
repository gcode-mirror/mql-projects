//+------------------------------------------------------------------+
//|                                         FollowTheWhiteRabbit.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//------- Внешние параметры советника -----------------------------------------+
extern int _MagicNumber = 1122;
extern double StopLoss_1H_min = 400;
extern double StopLoss_1H_max = 500;
extern double TakeProfit_1H = 1600;
extern double MACD_channel_1H = 0.002;

extern bool useTrailing = true;
extern double MinProfit_1H = 300; // когда профит достигает указанное количество пунктов, трейлинг начинает работу
extern double TrailingStop_1H_min = 300; // Величина трала
extern double TrailingStop_1H_max = 300; // Величина трала
extern double TrailingStep_1H = 100; // Величина шага

extern int historyDepth = 6;
extern double supremacyPercent = 0.2;

extern bool useLimitOrders = false;
extern int priceDifference = 20;

extern bool uplot = true; // вкл/выкл изменение величины лота
extern int lastprofit = -1; // принимает значения -1/1. 
// -1 - увеличение лота после минусовой сделки до первой плюсовой
//  1 - увеличение лота после плюсовой сделки до первой минусовой
extern double lotmin = 0.1; // начальное значение 
//extern double lotmax = 0.5; // потолок
//extern double lotstep = 0.1; // приращение лота

//------- Глобальные переменные советника -------------------------------------+
string _symbol = "";
int timeframe = PERIOD_H1;

bool   gbDisabled    = False;          // Флаг блокировки советника
color  clOpenBuy = Red;                // Цвет значка открытия покупки
color  clOpenSell = Green;             // Цвет значка открытия продажи
color  clCloseBuy    = Blue;           // Цвет значка закрытия покупки
color  clCloseSell   = Blue;           // Цвет значка закрытия продажи
color  clDelete      = Black;          // Цвет значка отмены отложенного ордера
int    Slippage      = 3;              // Проскальзывание цены
int    NumberOfTry   = 5;              // Количество торговых попыток
bool   UseSound      = True;           // Использовать звуковой сигнал
string NameFileSound = "expert.wav";   // Наименование звукового файла
bool Debug = false;

int total;
int ticket;
int _GetLastError = 0;
double lots;

double StopLoss;
double StopLoss_min;
double StopLoss_max;
double TakeProfit;
int minProfit; 
double trailingStop;
int trailingStop_min;
int trailingStop_max; 
int trailingStep;

string openPlace;
int frameIndex;
int startTF = 1;
int finishTF = 2;

int wantToOpen[3][2];
int barsCountToBreak[3][2];

//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <DesepticonOpening.mqh>
#include <DesepticonTrailing.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
 {
  _symbol=Symbol(); 
  TakeProfit = TakeProfit_1H;
  StopLoss_min = StopLoss_1H_min;
  StopLoss_max = StopLoss_1H_max; 
  minProfit = MinProfit_1H; 
  trailingStop_min = TrailingStop_1H_min;
  trailingStop_max = TrailingStop_1H_max; 
  trailingStep = TrailingStep_1H;
  return(0);
 }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
 {
  Alert("сработала функция deinit");
  return(0);
 }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   int positionType;
   
   if( isNewBar(timeframe) ) // на каждом новом баре 
   {
    for(i = historyDepth; i > 1; i--)
    {
     sum = sum + iHigh(_symbol, timeframe, i) - iLow(_symbol, timeframe, i);  
    }
    avgBar = sum / historyDepth;
    lastBar = iHigh(_symbol, timeframe, 1) - iLow(_symbol, timeframe, 1);
    
    if(GreatDouble(lastBar, avgBar*(1 + supremacyPercent)) > 0)
    {
     Print("last bar = ", NormalizeDouble(lastBar,8), " avg Bar = ", NormalizeDouble(avgBar,8)*(1 + supremacyPercent));

     if(GreatDouble(iOpen(_symbol, timeframe, 1), iClose(_symbol, timeframe, 1)) > 0)
     {
      if (DesepticonOpening(-1, timeframe) > 0)
	   {
       Alert("открыли сделку, начали отсчет");
   //    isMinProfit = false; // сделка длится
   //    barNumber = 0;
      }
     }
     
     if(GreatDouble(iClose(_symbol, timeframe, 1), iOpen(_symbol, timeframe, 1)) > 0)
     {
      if (DesepticonOpening(1, timeframe) > 0)
      {
       Alert("открыли сделку, начали отсчет");
   //    isMinProfit = false; // сделка длится
   //    barNumber = 0;
      }
     }
    }
   }
//----
   if (useTrailing) DesepticonTrailing(NULL, timeframe);
   return(0);
  }
//+------------------------------------------------------------------+