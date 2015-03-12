//+------------------------------------------------------------------+
//|                                              UselessPersonMA.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки
#include <CompareDoubles.mqh>                   // для проверки соотношения  цен

#define SELL -1
#define BUY 1
//----------------Константы--------------
int const upBorderRSI   = 50;
int const downBorderRSI = 50;

//---------------Объекты----------------
CisNewBar      *isNewBar;
CTradeManager  *ctm;
SPositionInfo  pos_inf;
STrailing      trail;                            

//---------------Переменные-------------
int      ihandleMA_fast;
int      ihandleMA_slow;
int      ihandleDE;
int      ihandleRSI;
int      ihandleATR;
int      bars;
int      price_copied;
int      copied_DE_low;
int      copied_DE_high;
int      copied_RSI;
int      openedPosition;
double   buf_MA_fast[];
double   buf_MA_slow[];
double   curRSI[];
double   lastMaxExtrPrice[];
double   lastMinExtrPrice[];
double   lastExtrPrice[];
double   last_extrem_low = 0;
double   last_extrem_high = 0;


int OnInit()
{
 ihandleMA_slow   = iMA(_Symbol,_Period, 70, 0, MODE_SMA, PRICE_CLOSE);
 ihandleMA_fast   = iMA(_Symbol,_Period, 50, 0, MODE_SMA, PRICE_CLOSE);
 ihandleDE        = iCustom(_Symbol, _Period, "DrawExtremums");
 ihandleRSI       = iRSI(_Symbol, _Period, 7, PRICE_CLOSE);
 ihandleATR       = iATR(_Symbol,_Period, 25);
 if(ihandleMA_slow == INVALID_HANDLE || ihandleMA_fast == INVALID_HANDLE)
 {
  Print("Не удалось создать хэндл индикатора iMA ");
  return(INIT_FAILED);
 }
 if(ihandleDE == INVALID_HANDLE)
 {
  Print("Не удалось создать хэндл индикатора DrawExtremums ");
  return(INIT_FAILED);
 }
 if(ihandleRSI == INVALID_HANDLE)
 {
  Print("Не удалось создать хэндл RSI ");
  return(INIT_FAILED);
 }
 //----------------Заполним буфер эктсремумов-------------------
 bars = Bars(_Symbol, _Period);
 if(bars > 1000)
  bars = 1000;
 for (int attempts=0; attempts < 25; attempts++)
  {
   copied_DE_high = CopyBuffer(ihandleDE,2,0,bars,lastMaxExtrPrice);
   copied_DE_low  = CopyBuffer(ihandleDE,3,0,bars,lastMinExtrPrice); 
   Sleep(100);
  }
 if(copied_DE_high != bars || copied_DE_low != bars)
 {
  Print("Не удалось скопировать буфер экстремумов ");
  return(INIT_FAILED);
 }
 for(int i = bars - 1; i >= 0; i--)
 {
  if(lastMaxExtrPrice[i] != 0)
   last_extrem_high = lastMaxExtrPrice[i]; 
  if(lastMinExtrPrice[i] != 0)
   last_extrem_low = lastMinExtrPrice[i]; 
  if(last_extrem_low != 0 && last_extrem_high != 0)
   break; 
 }
 //--------------Инициализвция переменных-----------------------
 isNewBar = new CisNewBar();
 ctm      = new CTradeManager();
 trail.trailingType = TRAILING_TYPE_ATR;
 trail.handleForTrailing = ihandleATR;
 pos_inf.volume = 1;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
 delete isNewBar;  
 IndicatorRelease(ihandleDE);
 IndicatorRelease(ihandleMA_fast);
 IndicatorRelease(ihandleMA_slow);
 IndicatorRelease(ihandleRSI);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();
 UpdateExtremums();
 ctm.DoTrailing();
 if(bars >= 300 && isNewBar.isNewBar())  //если пришел новый бар и история загружена достаточно, чтобы вычислить на ней экстремумы
 {
  if(!(CopyBuffer(ihandleMA_slow,0,1,2,buf_MA_slow) && CopyBuffer(ihandleMA_fast,0,1,2,buf_MA_fast)))
  {
   Print("Не удалось сопировать буферы МА");
   return;
  }
  if(GreatDoubles(buf_MA_fast[0],buf_MA_slow[0]) && LessDoubles(buf_MA_fast[1], buf_MA_slow[1])) //Зафиксировано пересечение средних
  {
   if(CopyCurrentHighPrice(1)) //Копируем High последнего сформированного бара
   { 
    if(lastExtrPrice[0] > buf_MA_slow[1]) //Если High находится выше пересечения
    {
     copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // копируем значение RSI на предыдущем баре
    if(copied_RSI != 1)
     {
      Print("Не удалось скопировать буфер экстремумов ");
      return;
     }
     // если RSI больше upborderRSI 
     if(curRSI[0] > upBorderRSI)
     {
      // открываем позицию на продажу
      openedPosition = SELL;
      pos_inf.type = OP_SELL;
      pos_inf.sl = GetStopLoss(openedPosition);
      trail.minProfit = pos_inf.sl; 
      ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
     }
    }
   }
  }
  if(LessDoubles(buf_MA_fast[0], buf_MA_slow[0]) && GreatDoubles(buf_MA_fast[1],buf_MA_slow[1])) //Зафиксировано пересечение средних
  {
   
   if(CopyCurrentLowPrice(1)) //Копируем Low последнего сформированного бара
   {
    if(lastExtrPrice[0] < buf_MA_slow[1]) //Если Low находится ниже пересечения
    {
     copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // копируем значение RSI на предыдущем баре
     if(copied_RSI != 1)
     {
      Print("Не удалось скопировать буфер экстремумов ");
      return;
     }
     // если RSI меньше downborderRSI 
     if(curRSI[0] < downBorderRSI)
     {
      // открываем позицию на покупку
      openedPosition = BUY;
      pos_inf.type = OP_BUY;
      pos_inf.sl = GetStopLoss(openedPosition);             //получить sl
      trail.minProfit = pos_inf.sl;                        //minProfit  = sl
      ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
     }
    }
   }
  }
 } 
}



//---------------------CopyCurrentHighPrice---------------------------+
//-----------------Копрует high цены по индексу------------------------
bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, lastExtrPrice);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}


//---------------------CopyCurrentLowPrice---------------------------+
//--------------- Копрует low цены по индексу -----------------------+
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, lastExtrPrice);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}


//-----------------------UpdateExtremums-----------------------------+
//--------------- Обновляет последние экстремумы --------------------+
void UpdateExtremums()
{
 copied_DE_high = CopyBuffer(ihandleDE,2,0,1,lastMaxExtrPrice);
 copied_DE_low  = CopyBuffer(ihandleDE,3,0,1,lastMinExtrPrice);
 if(copied_DE_high != 1 || copied_DE_low != 1)
 {
  Print("Не удалось скопировать буфер экстремумов ");
  return;
 }
 if(lastMaxExtrPrice[0] != 0)
  last_extrem_high = lastMaxExtrPrice[0];
 if(lastMinExtrPrice[0] != 0)
  last_extrem_low = lastMinExtrPrice[0];
 return;
}


//-----------------------GetStopLoss-----------------------------+
//--------------- Рассчитывает и возвращает StopLoss ------------+
int GetStopLoss(int openedPos)
{
 int slValue = 0;      // значение стоп лосса
 int stopLevel;        // стоп левел
 double openPrice;
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);  // получаем стоп левел
 switch(openedPos)
 {
  case BUY:
   openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   slValue = (int)MathAbs((last_extrem_low - openPrice) / _Point);
   break;
  case SELL:
   openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   slValue = (int)MathAbs((last_extrem_high - openPrice) / _Point);
  break;
 }Print("last_extrem_low = ", last_extrem_low, " openPrice = ", openPrice , " slValue = ", slValue, " stopLevel = ", stopLevel);
 if (slValue > stopLevel)
  return (slValue);
 else
  return (stopLevel + 1);   
}


//-----------------------IsSuitRSI------------------------------------+
//------ Возвращает разрешение открытия сделки по фильтру RSI --------+
//---------------------Не используется в коде!------------------------+
bool IsSuitRSI(int borderRSI, int tradeType)
{
 int copied_RSI;
 copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // копируем значение RSI на предыдущем баре
 if(copied_RSI != 1)
 {
  Print("Не удалось скопировать буфер экстремумов ");
  return false;
 }
 // если RSI , больше borderRSI при tradeType = SELL
 if(curRSI[0] > borderRSI && tradeType == SELL)
 return true;
 // если RSI , больше borderRSI при tradeType = SELL
 if(curRSI[0] > borderRSI && tradeType == BUY)
 return true;
 return false;
}