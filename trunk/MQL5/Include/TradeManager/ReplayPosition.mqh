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

//+------------------------------------------------------------------+
//|  ласс-контейнер дл€ хранени€ и работы с позици€ми                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 private:
  CTradeManager ctm;  //торговый класс 
  CPositionArray _posToReplay;   //динамический массив дл€ обработки позиций на отыгрыш
  /*
  int ATR_handle;
  double ATR_buf[];
  */
  datetime prevDate;  // дата последнего получени€ истории
 public: 
  void ReplayPosition();
  void ~ReplayPosition();
  
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //пробагает по массиву и измен€ет статусы позиций возвращает индекс позиции    
};
//+------------------------------------------------------------------+
//|  онструктор                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(void)
{
/*
 ATR_handle = iATR(_symbol, _period, 100);
 if(handleMACD == INVALID_HANDLE)                                  //провер€ем наличие хендла индикатора
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

//+------------------------------------------------------------------+
//| заполн€ет массив дл€ отыгрыша из внешнего массива                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 int total = array.Total();
 CPosition *pos;
 for(int i = 0; i < total; i++)
 {
  pos = new CPosition(array.At(i));
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   PrintFormat("%s [”быток], openTime=%s, closeTime=%s, profit=%.05f, close=%.05f"
               ,MakeFunctionPrefix(__FUNCTION__), TimeToString(pos.getOpenPosDT()), TimeToString(pos.getClosePosDT()), pos.getPosProfit(), pos.getPriceClose());
   _posToReplay.Add(pos);
   PrintFormat("%s , Total = %d", MakeFunctionPrefix(__FUNCTION__), _posToReplay.Total());
  }
 }
}
//+------------------------------------------------------------------+
//| пробегает по массиву позиций и провер€ет\мен€ет статусы          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 int direction = 0;
 int index;
 uint total = _posToReplay.Total();        //текуща€ длина массива
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                           //указатель на позицию 

 for (index = total - 1; index >= 0; index--)     //пробегаем по массиву позиций
 {
  pos = _posToReplay.At(index);

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
    //pos.setPositionStatus(POSITION_STATUS_ON_REPLAY);
    _posToReplay.Delete(index); //и удал€ем еЄ из массива  
   }      
  }
 }
 
 setArrayToReplay(ctm.GetPositionHistory(prevDate));
 prevDate = TimeCurrent();  
}
