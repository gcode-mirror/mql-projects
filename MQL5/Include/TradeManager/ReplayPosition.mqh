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
//| Класс-контейнер для хранения и работы с позициями                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 #define PERIOD PERIOD_H1;
 private:
  CTradeManager ctm;  //торговый класс 
  CPositionArray aPositionsToReplay;         // массив убыточных позиций на отыгрыш
  CArrayLong aReplayingPositionsDT;          // массив позиций для отыгрыша убыточных позиций
  
  int ATR_handle, errATR;
  double ATR_buf[];
  double _ATRforReplay, _ATRforTrailing;
  ENUM_TRAILING_TYPE _trailingType;
  
  datetime prevDate;  // дата последнего получения истории
 public: 
  void ReplayPosition(string symbol, ENUM_TIMEFRAMES period, int ATRforReplay, int ATRforTrailing, ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_USUAL);
  void ~ReplayPosition();
  
  void OnTrade();
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //пробагает по массиву и изменяет статусы позиций возвращает индекс позиции    
  CPosition* CreatePositionToReplay(string symbol, ENUM_TM_POSITION_TYPE type, double volume, double priceOpen, double priceClose, double profit);
};
//+------------------------------------------------------------------+
//| Конструктор                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(string symbol, ENUM_TIMEFRAMES period, int ATRforReplay, int ATRforTrailing, ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_USUAL)
                    : _ATRforReplay(ATRforReplay/100), 
                      _ATRforTrailing(ATRforTrailing/100),
                      _trailingType(trailingType)
{
 if (period < PERIOD_H1) period = PERIOD_H1;
 ATR_handle = iATR(symbol, period, 100);
 if(ATR_handle == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось получить хендл ATR",MakeFunctionPrefix(__FUNCTION__)) );               //если хендл не получен, то выводим сообщение в лог об ошибке
 }
}

//+------------------------------------------------------------------+
//| Деструктор                                                       |
//+------------------------------------------------------------------+
void ReplayPosition::~ReplayPosition(void)
{
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReplayPosition::OnTrade()
{
 //PrintFormat("%s, total=%d, totalOnRep=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total());
 ctm.OnTrade();
 CPositionArray *array;
 CPosition *posFromHistory, *posToReplay;
 double profitToReplay, profitFromHistory;
 int index;
 
 if (prevDate != TimeCurrent())
 {
  array = ctm.GetPositionHistory(prevDate);
  prevDate = TimeCurrent() + 1;
 }
 else
 {
  return;
 }
   
 int totalReplayed = array.Total();
 int totalOnReplaying = aReplayingPositionsDT.Total();
 if (totalReplayed > 0) PrintFormat("%s Закрыто %d позиций открытых для отыгрыша", MakeFunctionPrefix(__FUNCTION__), totalReplayed);
 
 for (int i = 0; i < totalReplayed; i++)
 {
  posFromHistory = new CPosition(array.At(i));
  index = 0;
  while (index < totalOnReplaying && posFromHistory.getOpenPosDT() != aReplayingPositionsDT[index])
  {
   index++;
   log_file.Write(LOG_DEBUG, StringFormat("%s Из отыграных позиций выбираем сыгравшую: total=%d, totalOnRep=%d, index = %d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), totalOnReplaying, index) );
  }
  
  posToReplay = aPositionsToReplay.At(index);
  profitToReplay = posToReplay.getPosProfit();
  profitFromHistory = posFromHistory.getPosProfit();
  
  if (profitFromHistory > 0)
  {
   if (profitFromHistory >= profitToReplay)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Позиция на отыгрыш отыграла убыток: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index) );
    aPositionsToReplay.Delete(index);
    aReplayingPositionsDT.Delete(index);
   } 
   else
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Позиция на отыгрыш НЕ отыграла убыток: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index) );
    posToReplay.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
    aReplayingPositionsDT.Update(index, 0);
   }
  }
   
  if (posFromHistory.getPosProfit() < 0)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Позиция на отыгрыш закрыта с убытком: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index) );
   aPositionsToReplay.Add(
       CreatePositionToReplay(
                    posToReplay.getSymbol()
                  , posToReplay.getType()
                  , posToReplay.getVolume()
                  , profitFromHistory + profitToReplay
                  , posToReplay.getPriceOpen()
                  , posFromHistory.getPriceClose()));
                  
   aReplayingPositionsDT.Add(0);
   log_file.Write(LOG_DEBUG, StringFormat("%s добавили новую позицию: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index) );
   aPositionsToReplay.Delete(index);
   aReplayingPositionsDT.Delete(index);
   log_file.Write(LOG_DEBUG, StringFormat("%s Удалили старую позицию: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index) );
  }
  delete posFromHistory;
 }
 
}
//+------------------------------------------------------------------+
//| заполняет массив для отыгрыша из внешнего массива                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 //Print("Заполняем массив на отыгрыш total=", array.Total());
 int total, size;
 int n = array.Total();
 CPosition *pos;
 for(int i = 0; i < n; i++)
 {
  pos = new CPosition(array.At(i));
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   aPositionsToReplay.Add(pos);
   aReplayingPositionsDT.Add(0);
   log_file.Write(LOG_DEBUG, StringFormat("%s Добавили позицию closePrice=%.05f, Profit=%.05f, status=%s, total=%d, totalOnRep=%d"
              , MakeFunctionPrefix(__FUNCTION__), pos.getPriceClose(), pos.getPosProfit()
              , PositionStatusToStr(pos.getPositionStatus()), aPositionsToReplay.Total(), aReplayingPositionsDT.Total()) );
  }
  else
  {
   delete pos;
  }
 }
 //delete array;
}

//+------------------------------------------------------------------+
//| пробегает по массиву позиций и проверяет\меняет статусы          |
//+------------------------------------------------------------------+
CPosition* ReplayPosition::CreatePositionToReplay(string symbol, ENUM_TM_POSITION_TYPE type, double volume, double priceOpen, double priceClose, double profit)
{
 CPosition *posToAdd;
 posToAdd = new CPosition(symbol, PERIOD_H1, type, volume, priceOpen, priceClose, profit);
 posToAdd.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
 return posToAdd;
}
//+------------------------------------------------------------------+
//| пробегает по массиву позиций и проверяет\меняет статусы          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 ctm.OnTick();
 int direction = 0;
 int index;
 uint total = aPositionsToReplay.Total();        //текущая длина массива
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                                 //указатель на позицию 

 errATR = CopyBuffer(ATR_handle, 0, 1, 1, ATR_buf);
 if(errATR < 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось скопировать данные из индикаторного буфера", MakeFunctionPrefix(__FUNCTION__) ) ); 
  return; 
 }

 for (index = total - 1; index >= 0; index--)    //пробегаем по массиву позиций
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
  if (pos.getPositionStatus() == POSITION_STATUS_MUST_BE_REPLAYED)  //если позиция ожидает перевала за рубеж в Loss
  {
   //если цена перевалила за Loss
   if (direction*(closePrice - curPrice) > profit || direction*(closePrice - curPrice) > ATR_buf[0]*_ATRforReplay)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Позиция %d переведена в режим готовности к отыгрышу, type=%s, direction=%d, profit=%.05f, close=%.05f, current=%.05f, ATR=%.05f"
                ,MakeFunctionPrefix(__FUNCTION__), index, GetNameOP(pos.getType()), direction, profit, closePrice, curPrice, ATR_buf[0]*_ATRforReplay) );
                
    pos.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);  //переводим позицию в режим готовности к отыгрушу
   } 
  }
  else
  {
   if ((pos.getPositionStatus() == POSITION_STATUS_READY_TO_REPLAY)
      && (direction*(curPrice - closePrice) >= 0))//если позиция готова к отыгрышу и цена перевалила за зону цены закрытия позиции
   {
    tp = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL), (profit/_Point));
    sl = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL), (profit/_Point));
    int trailParam = ATR_buf[0]*_ATRforTrailing/_Point;
    
    SPositionInfo pos_info = pos.getPositionInfo();
    pos_info.sl = sl;
    pos_info.tp = tp;
    STrailing trailing;
    trailing.trailingType = _trailingType;
    trailing.minProfit = trailParam;
    trailing.trailingStop = trailParam;
    trailing.trailingStep = trailParam;
    trailing.handleForTrailing = 0;
    
    if (ctm.OpenMultiPosition(symbol, PERIOD_H1, pos_info, trailing)) //открываем позицию
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыли позицию для отыгрыша type=%s, profit=%.05f, sl=%d, tp=%d",MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos.getType()), NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp) );
     pos.setPositionStatus(POSITION_STATUS_ON_REPLAY);
     aReplayingPositionsDT.Update(index, TimeCurrent());
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось открыть позицию для отыгрыша profit=%.05f, sl=%d, tp=%d",MakeFunctionPrefix(__FUNCTION__),NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp) );
    }
   }      
  }
 }
}