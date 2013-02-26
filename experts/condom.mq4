//+------------------------------------------------------------------+
//|                                                       condom.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//------- Внешние параметры советника -----------------------------------------+
extern int _MagicNumber = 1122;
extern int SL = 150;
extern int TP = 500;
extern int historyDepth = 40;
extern int timeframe = PERIOD_M1;
extern bool useTrailing = false;
extern int minProfit = 250;
extern int trailingStop_min = 100;
extern int trailingStop_max = 110;
extern int trailingStep = 5;
extern bool tradeOnTrend = false;
extern int fastMACDPeriod = 12;
extern int slowMACDPeriod = 26;
extern int signalPeriod = 9;
extern double levelMACD = 0.02;
extern bool uplot = false; // вкл/выкл изменение величины лота
extern double lotmin = 0.1; // начальное значение 
extern int lastprofit = -1; // принимает значения -1/1. 

//------- Глобальные переменные советника -------------------------------------+
string _symbol = "";
int startTF = 1;
int finishTF = 2;

bool   gbDisabled    = False;          // Флаг блокировки советника
color  clOpenBuy = Red;                // Цвет значка открытия покупки
color  clOpenSell = Green;             // Цвет значка открытия продажи
color  clCloseBuy    = Blue;           // Цвет значка закрытия покупки
color  clCloseSell   = Blue;            // Цвет значка закрытия продажи
int    Slippage      = 3;              // Проскальзывание цены
int    NumberOfTry   = 5;              // Количество торговых попыток
bool   UseSound      = True;           // Использовать звуковой сигнал
string NameFileSound = "expert.wav";   // Наименование звукового файла
bool Debug = false;

int _GetLastError = 0;

int total;
int ticket;
string openPlace;
double Lots;

double StopLoss;
double TakeProfit;
double trailingStop;
int frameIndex;

bool waitForSell = false;
bool waitForBuy = false;
//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <DesepticonTrailing.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
 {
  _symbol=Symbol(); 
  StopLoss = SL;
  TakeProfit = TP;
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
   if( isNewBar(timeframe) ) // на каждом новом баре 
   {
    double globalMax = iHigh(_symbol, timeframe, iHighest(_symbol, timeframe, MODE_HIGH, historyDepth, 2));
    double globalMin = iLow(_symbol, timeframe, iLowest(_symbol, timeframe, MODE_LOW, historyDepth, 2));
        
    if(GreatDouble(globalMin, iClose(_symbol, timeframe, 1)) > 0)
    {
     waitForSell = false;
     waitForBuy = true;
     //Alert("WTB");
    }
    
    if(GreatDouble(iClose(_symbol, timeframe, 1), globalMax) > 0)
    {
     waitForBuy = false;
     waitForSell = true;
     //Alert("WTS");
    }
   }
   
   if (tradeOnTrend) // смотрим на тренд
   {
    double currentMACD = iMACD(_symbol, timeframe, fastMACDPeriod, slowMACDPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
    if (GreatDouble(currentMACD, levelMACD) > 0 || GreatDouble(-levelMACD, currentMACD) > 0) // не торгуем на тренде
    {
     if (useTrailing) DesepticonTrailing(_symbol, timeframe);
     return;
    }
   }
   
   if (waitForBuy)
   { 
    if (Ask > iClose(_symbol, timeframe, 1) && Ask > iClose(_symbol, timeframe, 2))
    {
     if (DesepticonBreakthrough2(1, timeframe) > 0)
     {
      Alert("открыли сделку, сбросили счетчики");
      waitForBuy = false;
      waitForSell = false;
     }
    } 
   }
   if (waitForSell)
   { 
    if (Bid < iClose(_symbol, timeframe, 1) && Bid < iClose(_symbol, timeframe, 2))
    {
     if (DesepticonBreakthrough2(-1, timeframe) > 0)
     {
      Alert("открыли сделку, сбросили счетчики");
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
   
//----
   if (useTrailing) DesepticonTrailing(_symbol, timeframe);
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                      DesepticonBreakthrough2.mq4 |
//|                                            Copyright © 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
//|  Версия   : 25.02.2013                                           |
//|  Описание : открывает позицию в заданном направлении             |
//+------------------------------------------------------------------+
//|  Параметры:                                                      |
//|    iDirection - направление                                      |
//|    timeframe - таймфрейм                                         |
//+------------------------------------------------------------------+ 
int DesepticonBreakthrough2(int iDirection, int timeframe)
{
 int i;
 total=OrdersTotal();
 
 if (iDirection < 0)
 {
  // Продаем по Bid
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  {
   //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
   if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
   {
    return (1);
   }  
   else // ошибка открытия
    return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
      {
       ClosePosBySelect(Bid); // закрываем позицию BUY
       Alert("DesepticonBreakthrough2: Закрыли ордер BUY" );
       if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
       {
        return (1);
       }  
       else // ошибка открытия
        return(-1);
      }
     }
    } 
   } 
  }
 }
      
 if (iDirection > 0)
 {
  // Покупаем по Ask
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  { 
   //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
    if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
    {
     return (1);
    }
    else // ошибка открытия
     return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
      {
       ClosePosBySelect(Ask); // закрываем позицию SELL
       Alert("DesepticonBreakthrough2: Закрыли ордер SELL" );
        if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
        {
         return (1);
        }
        else // ошибка открытия
         return(-1);
      }
     }
    }
   }  
  }
 }
 return (0);
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 21.03.2008                                                     |
//|  Описание : Открывает позицию и возвращает её тикет.                       |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    symb - наименование инструмента   (NULL или "" - текущий символ)          |
//|    operation - операция                                                           |
//|    Lots - лот                                                                |
//|    sl - уровень стоп                                                       |
//|    tp - уровень тейк                                                       |
//|    mn - MagicNumber                                                        |
//+----------------------------------------------------------------------------+
int OpenPosition(string symb, int operation, string openPlace, int timeframe, double sl=0, double tp=0, int mn=0, string lsComm="")
 {
  color op_color;
  datetime ot;
  double   price, pAsk, pBid, vol, addPrice;
  int      dg, err, it, ticket=0;

  Lots = GetLots();
   
  if (symb=="" || symb=="0") symb=Symbol();
  if (lsComm=="" || lsComm=="0") lsComm=WindowExpertName()+" "+GetNameTF(Period()) + " " + openPlace;
  dg=MarketInfo(symb, MODE_DIGITS);
  vol=MathPow(10.0,dg);
  addPrice=0.0003*vol;
  
  if (operation == OP_BUY)
  {
   price = Ask;
   //StopLoss = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 4, 0)) + addPrice*Point; //(мин_цена - тек.покупка + 30п.)
   sl = Bid-StopLoss*Point;
   tp = Ask+TakeProfit*Point;
   op_color = clOpenBuy;
  }
  
  if (operation == OP_SELL)
  {
   price = Bid;
   //StopLoss = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 4, 0)) - Bid + addPrice*Point; //(макс_цена - тек.продажа + 30п.)
   sl = Ask+StopLoss*Point;
   tp = Bid-TakeProfit*Point;
   op_color = clOpenSell;
  }
  
  for (it=1; it<=NumberOfTry; it++)
  {
   if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
   {
     Print("OpenPosition(): Остановка работы функции");
     break;
   }
   while (!IsTradeAllowed()) Sleep(5000);
   RefreshRates();
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   if (operation==OP_BUY) price=pAsk; else price=pBid;
   price=NormalizeDouble(price, dg);
   ot=TimeCurrent();
   Alert (openPlace, " открываемся на ", timeframe, "-минутном ТФ ",  " _MagicNumber ", mn);
   Print (openPlace);
   ticket=OrderSend(symb, operation, Lots, price, Slippage, 0, 0, lsComm, mn, 0, op_color);
   if (ticket>0)
   {
    if (UseSound) PlaySound("expert.wav");
    if(tp != 0 || sl != 0)
     if(OrderSelect(ticket, SELECT_BY_TICKET))
      ModifyOrder(-1, sl, tp);
    for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
    {
     //wantToOpen[frameIndex][0] = 0;
     //wantToOpen[frameIndex][1] = 0;
     //barsCountToBreak[frameIndex][0] = 0;
     //barsCountToBreak[frameIndex][1] = 0;
    }
    break;
   }
   else
   {
    err=GetLastError();
    if (pAsk==0 && pBid==0) Message("Проверьте в Обзоре рынка наличие символа "+symb);
    // Вывод сообщения об ошибке
    Print("Error(",err,") opening position: ",ErrorDescription(err),", try ",it);
    Print("Ask=",pAsk," Bid=",pBid," symb=",symb," Lots=",Lots," operation=",GetNameOP(operation),
          " price=",price," sl=",sl," tp=",tp," mn=",mn);
    // Блокировка работы советника
    if (err==2 || err==64 || err==65 || err==133) {
      gbDisabled=True; break;
    }
    // Длительная пауза
    if (err==4 || err==131 || err==132) {
      Sleep(1000*300); break;
    }
    if (err==128 || err==142 || err==143) {
      Sleep(1000*66.666);
      if (ExistPositions(symb, operation, mn, ot)) {
        if (UseSound) PlaySound("expert.wav"); break;
      }
    }
    if (err==140 || err==148 || err==4110 || err==4111) break;
    if (err==141) Sleep(1000*100);
    if (err==145) Sleep(1000*17);
    if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
    if (err!=135) Sleep(1000*7.7);
   }
  } // close for
  return(ticket);
}