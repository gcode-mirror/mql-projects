//+------------------------------------------------------------------+
//|                                               ReplayPosition.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "TradeManager.mqh"
#include <Arrays/ArrayLong.mqh>

//+------------------------------------------------------------------+
//|  ласс-контейнер дл€ хранени€ и работы с позици€ми                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 private:
  CTradeManager ctm;  //торговый класс 
  CPositionArray aPositionsToReplay;         // массив убыточных позиций на отыгрыш
  CArrayLong aReplayingPositionsDT;  // массив позиций дл€ отыгрыша убыточных позиций
  
  int ATR_handle;
  double ATR_buf[];
  
  datetime prevDate;  // дата последнего получени€ истории
 public: 
  void ReplayPosition(string symbol, ENUM_TIMEFRAMES period);
  void ~ReplayPosition();
  
  void OnTrade();
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //пробагает по массиву и измен€ет статусы позиций возвращает индекс позиции    
};
//+------------------------------------------------------------------+
//|  онструктор                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(string symbol, ENUM_TIMEFRAMES period)
{
/*
 ATR_handle = iATR(symbol, period, 100);
 if(ATR_handle == INVALID_HANDLE)                                  //провер€ем наличие хендла индикатора
 {
  Print("Ќе удалось получить хендл ATR");               //если хендл не получен, то выводим сообщение в лог об ошибке
 }
 */
}

//+------------------------------------------------------------------+
//| ƒеструктор                                                       |
//+------------------------------------------------------------------+
void ReplayPosition::~ReplayPosition(void)
{
}

void ReplayPosition::OnTrade()
{
 PrintFormat("total=%d", aPositionsToReplay.Total());
 ctm.OnTrade();
 CPositionArray *array;
 CPosition *posFromHistory, *posToReplay;
 array = ctm.GetPositionHistory(prevDate);
 prevDate = TimeCurrent();
 
 setArrayToReplay(array);
 int totalReplayed = array.Total();
 int totalOnReplaying = aReplayingPositionsDT.Total();
 int index;
 
 for (int i = 0; i < totalReplayed; i++)
 {
  posFromHistory = new CPosition(array.At(i));
  index = 0;
  while (index < totalOnReplaying && posFromHistory.getOpenPosDT() != aReplayingPositionsDT[index])
  {
   index++;
  }
  
  if (posFromHistory.getPosProfit() > 0)
  {
   aPositionsToReplay.Delete(index);
   aReplayingPositionsDT.Delete(index);
  } 

  if (posFromHistory.getPosProfit() < 0)
  {
   posToReplay = aPositionsToReplay.At(index);
   posToReplay.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);
   aReplayingPositionsDT.Update(index, 0);
  }
 }
}
//+------------------------------------------------------------------+
//| заполн€ет массив дл€ отыгрыша из внешнего массива                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 int total, size;
 int n = array.Total();
 CPosition *pos;
 for(int i = 0; i < n; i++)
 {
  pos = new CPosition(array.At(i));
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   //PrintFormat("%s [”быток], openTime=%s, closeTime=%s, profit=%.05f, close=%.05f"
   //            ,MakeFunctionPrefix(__FUNCTION__), TimeToString(pos.getOpenPosDT()), TimeToString(pos.getClosePosDT()), pos.getPosProfit(), pos.getPriceClose());
   aPositionsToReplay.Add(pos);
   aReplayingPositionsDT.Add(0);
  }
 }
}
//+------------------------------------------------------------------+
//| пробегает по массиву позиций и провер€ет\мен€ет статусы          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 ctm.OnTick();
 int direction = 0;
 int index;
 uint total = aPositionsToReplay.Total();        //текуща€ длина массива
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                           //указатель на позицию 

 for (index = total - 1; index >= 0; index--)     //пробегаем по массиву позиций
 {
  pos = aPositionsToReplay.At(index);

  symbol = pos.getSymbol();
  profit = MathAbs(pos.getPosProfit());
  openPrice = pos.getPriceOpen();
  closePrice = pos.getPriceClose();
  
  if (pos.getType() == OP_BUY)
  {
   direction = 1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
  }
  if (pos.getType() == OP_SELL)
  {
   direction = -1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_BID);         
  }
  if (pos.getPositionStatus() == POSITION_STATUS_MUST_BE_REPLAYED)  //если позици€ ожидает перевала за рубеж в Loss
  {
   //если цена перевалила за Loss
   if (direction*(closePrice - curPrice) > profit)
   {
    PrintFormat("ѕозици€ %d переведена в режим готовности к отыгрышу, type=%s, direction=%d, profit=%.05f, close=%.05f, current=%.05f"
                , index, GetNameOP(pos.getType()), direction, profit, closePrice, curPrice);
    pos.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);  //переводим позицию в режим готовности к отыгрушу
   } 
  }
  else
  {
   if ((pos.getPositionStatus() == POSITION_STATUS_READY_TO_REPLAY)
      && (direction*(curPrice - closePrice) >= 0))//если позици€ готова к отыгрышу и цена перевалила за зону цены закрыти€ позиции
   {
    tp = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
    sl = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));   
    PrintFormat("”далили позицию из массива отыгрышей profit=%.05f, sl=%d, tp=%d",NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp);
    ctm.OpenMultiPosition(symbol, pos.getType(), pos.getVolume(), sl, tp, 0, 0, 0); //открываем позицию
    pos.setPositionStatus(POSITION_STATUS_ON_REPLAY);
    aReplayingPositionsDT.Update(index, TimeCurrent());
    //aPositionsToReplay.Delete(index); //и удал€ем еЄ из массива  
   }      
  }
 }
}
