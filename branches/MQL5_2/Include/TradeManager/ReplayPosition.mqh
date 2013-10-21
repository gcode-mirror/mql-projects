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
//| Класс-контейнер для хранения и работы с позициями                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 private:
  CTradeManager ctm;  //торговый класс 
  CPositionArray _posToReplay;   //динамический массив для обработки позиций на отыгрыш
  /*
  int ATR_handle;
  double ATR_buf[];
  */
  datetime prevDate;  // дата последнего получения истории
 public: 
  void ReplayPosition();
  void ~ReplayPosition();
  
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //пробагает по массиву и изменяет статусы позиций возвращает индекс позиции    
};
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(void)
{
/*
 ATR_handle = iATR(_symbol, _period, 100);
 if(handleMACD == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
 {
  Print("Не удалось получить хендл ATR");               //если хендл не получен, то выводим сообщение в лог об ошибке
 }
 */
}

//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
void ReplayPosition::~ReplayPosition(void)
{
 
}

//+------------------------------------------------------------------+
//| заполняет массив для отыгрыша из внешнего массива                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 int total = array.Total();
 CPosition *pos;
 for(int i = 0; i < total; i++)
 {
  pos = array.At(i);
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   Alert("[Позиция убыточна]",
           " время открытия  = ",TimeToString(pos.getOpenPosDT()),
           " время закрытия = ",TimeToString(pos.getClosePosDT())
   );
   _posToReplay.Add(pos);
  }
 }
}
//+------------------------------------------------------------------+
//| пробегает по массиву позиций и проверяет\меняет статусы          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 int direction = 0;
 uint index;
 uint total = _posToReplay.Total();        //текущая длина массива
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                           //указатель на позицию 

 for (index=0; index < total; index++)     //пробегаем по массиву позиций
 {

  pos = _posToReplay.At(index);

  symbol = pos.getSymbol();
  profit = pos.getPosProfit();
  openPrice = pos.getPriceOpen();
  closePrice = pos.getPriceClose();
  
  if (pos.Type() == OP_BUY)
  {
   direction = 1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
  }
  if (pos.Type() == OP_SELL)
  {
   direction = -1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_BID);         
  }
  if (pos.getPositionStatus() == POSITION_STATUS_MUST_BE_REPLAYED)  //если позиция ожидает перевала за рубеж в Loss
  {
  
   //если цена перевалила за Loss
   if (direction*(curPrice - closePrice) < profit)
   {
    pos.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);  //переводим позицию в режим готовности к отыгрушу
       /*Comment(
           "[Позиция готова к отыгрышу] ",
           "тип = ", GetNameOP(pos.getType()), 
           "; цена открытия = ", openPrice, 
           " цена закрытия = ", closePrice,
           " профит позиции = ",profit,
           " дата и время = ", TimeToString(TimeCurrent())
          );*/
   } 
  }
  else
  {
   if ((pos.getPositionStatus() == POSITION_STATUS_READY_TO_REPLAY)
      && (direction*curPrice >= closePrice))//если позиция готова к отыгрышу и цена перевалила за зону цены закрытия позиции
   {
    tp = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
    sl = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));              
   ctm.OpenMultiPosition(symbol, pos.getType(), pos.getVolume(), sl, tp, 0, 0, 0); //открываем позицию
   pos.setPositionStatus(POSITION_STATUS_OPEN);
         /* Comment(
           "[Позиция открыта на отыгрыш] ",
           "тип = ", GetNameOP(pos.getType()), 
           "; цена открытия = ", openPrice, 
           " цена закрытия = ", closePrice,
           " профит позиции = ",profit,
           " дата и время = ", TimeToString(TimeCurrent())
          );*/
   
   // _posToReplay.Delete(index); //и удаляем её из массива  

   }      
  }
 }
 
 setArrayToReplay(ctm.GetPositionHistory(prevDate));
 prevDate = TimeCurrent();  
}
