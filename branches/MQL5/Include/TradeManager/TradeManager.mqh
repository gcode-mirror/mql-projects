//+------------------------------------------------------------------+
//|                                                CTradeManager.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "CTMTradeFunctions.mqh"
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>

int error = 0;
//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CTradeManager
{
protected:
  CPosition *position;
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // Наименование звукового файла
  
  CPositionArray _positionsToReProcessing;
  CPositionArray _openPositions; ///< Array of open virtual orders for this VOM instance, also persisted as a file
  //CPositionArray _positionsHistory; ///< Array of closed virtual orders, also persisted as a file
  
public:
  void CTradeManager():  _useSound(true), _nameFileSound("expert.wav") 
  {
   _magic = MakeMagic(); 
   log_file.Write(LOG_DEBUG, "Создание объекта CTradeManager"); 
  };
  
  bool OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                    int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  bool ClosePosition(long ticket, color Color=CLR_NONE); // Закртыие позиции по тикету
  bool ClosePosition(int i,color Color=CLR_NONE);  // Закрытие позиции по индексу в массиве позиций 
  bool CloseReProcessingPosition(int i,color Color=CLR_NONE);
  long MakeMagic(string strSymbol = "");
  void DoTrailing();
//  int OnInit();
//  void OnDeinit();
  void OnTick();
  void OnTrade(datetime history_start);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 if (_positionsToReProcessing.Total() > 0) 
 {
  log_file.Write(LOG_DEBUG, "Невозможно открыть позицию так как еще есть позиции в positionsToReProcessing.");
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, Открываем позицию %s. Открытых позиций на данный момент: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, _openPositions.PrintToString());
 switch(type)
 {
  case OP_BUY:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на продажу
    {
     CPosition *pos = _openPositions.At(i);
     //PrintFormat("Выбрали %d-ю позицию символ=%s, магик=%d", i, pos.getSymbol(), pos.getMagic());
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_SELL || pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
      {
       ClosePosition(i);
      }
     }
    }
   }
   break;
  case OP_SELL:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на покупку
    {
     CPosition *pos = _openPositions.At(i);
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_BUY || pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
      {
       ClosePosition(i);
      }
     }
    }
   }
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 total = _openPositions.Total() + _positionsToReProcessing.Total();
 if (total <= 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s openPositions и positionsToReProcessing пусты - открываем новую позицию", MakeFunctionPrefix(__FUNCTION__)));
  position = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = position.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // удалось установить желаемую позицию
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.06f, tp=%.06f", MakeFunctionPrefix(__FUNCTION__),position.getMagic(), position.getSymbol(), GetNameOP(position.getType()), position.getPositionPrice(), position.getVolume(), position.getStopLossPrice(), position.getTakeProfitPrice()));
   _openPositions.Add(position);
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
   return(true); // Если удачно открыли позицию
  }
  else
  {
   error = GetLastError();
   _positionsToReProcessing.Add(position);
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось открыть позицию.Error{%d} = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error)));
   return(false); // Если открыть позицию не удалось
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s Осталось открытых позиций %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // Если остались открытые позиции, значит не надо открываться 
}
//+------------------------------------------------------------------+ 
// Функция вычисления параметров трейлинга
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()  //TO DO LIST : добавить логгирование
{
 int total = _openPositions.Total();
 ulong ticket = 0, slTicket = 0;
 long type = -1;
 double newSL = 0;

//--- пройдем в цикле по всем ордерам
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  pos.DoTrailing();
 } 
};
//+------------------------------------------------------------------+ 
// Функция модификации позиции
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
};

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start)
  {

  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CTradeManager::OnTick()
{
 MqlTick tick;
 ENUM_TM_POSITION_TYPE type; 
 for(int i = _openPositions.Total()-1; i>=0; i--) // по массиву НАШИХ позиций
 {
  position = _openPositions.At(i); // выберем позицию по ее индексу
  type = position.getType();    
  if (!OrderSelect(position.getStopLossTicket())) // Если мы не можем выбрать стоп по его тикету, значит он сработал
  {
   _openPositions.Delete(i);                         // удалить позицию из массива позиций 
   break;                                                // завершаем шаг цикла
  }
     
  if ((type == OP_BUY && tick.bid >= position.getTakeProfitPrice()) || (type == OP_SELL && tick.ask <= position.getTakeProfitPrice())) 
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s цена достигла уровня TakeProfit, закрываем позицию", MakeFunctionPrefix(__FUNCTION__)));
   if (position.ClosePosition())
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Получилось закрыть позицию, удаляем ее из массива openPositions [%d]", MakeFunctionPrefix(__FUNCTION__), i));
    _openPositions.Delete(i);                        // ... и удалить позицию из массива позиций 
   }
   else
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось закрыть StopLoss. Перемещаем позицию [%d] в positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
    _positionsToReProcessing.Add(_openPositions.Detach(i));
   }
   break;                                                // завершаем шаг цикла
  }
     
  if (position.getPositionStatus() == POSITION_STATUS_PENDING) // Если это позиция отложенным ордером...
  { 
   if (!OrderSelect(position.getPositionTicket())) // ... и мы не можем ее выбрать по ее тикету, значит она сработала
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Сработала позиция являющаяся отложенным ордером.Пытаемся установить StopLoss и TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
    if (position.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
     || position.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // попробуем установить стоплосс и тейкпрофит
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось установить StopLoss и/или TakeProfit. Перемещаем позицию [%d] в positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
     position.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // если не получилось, запомним, чтобы повторить позднее
     _positionsToReProcessing.Add(position); 
     break;
    }
    log_file.Write(LOG_DEBUG, StringFormat("%s Получилось установить StopLoss и/или TakeProfit. Перемещаем позицию [%d] в openPositions.", MakeFunctionPrefix(__FUNCTION__)));
    position.setPositionStatus(POSITION_STATUS_OPEN); // позиция открылась, стоп и тейк установлены
    _openPositions.Add(position);
   }
  }
 }
 
 for(int i = _positionsToReProcessing.Total()-1; i>=0; i--) // по массиву позиций на доработку
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s begin %s", MakeFunctionPrefix(__FUNCTION__), _positionsToReProcessing.PrintToString()));
  CPosition *pos = _positionsToReProcessing.Position(i);  // получаем из массива указатель на позицию по ее тикету
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Получилось удалить позицию [%d].Удаляем её из positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
    _positionsToReProcessing.Delete(i);
    break;
   }
  }
  
  if (/*pos.getTakeProfitStatus() == STOPLEVEL_STATUS_NOT_DELETED || */pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Удаляем StopLoss и TakeProfit", MakeFunctionPrefix(__FUNCTION__)));    
   CloseReProcessingPosition(i);
   break;
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED /*&& pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED*/)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Получилось установить StopLoss и TakeProfit у позиции [%d].Перемещаем её из positionsToReProcessing в openPositions.", MakeFunctionPrefix(__FUNCTION__), i));    
    pos.setPositionStatus(POSITION_STATUS_OPEN);
    _openPositions.Add(_positionsToReProcessing.Detach(i));
   }
  }
  log_file.Write(LOG_DEBUG, StringFormat("%s end %s", MakeFunctionPrefix(__FUNCTION__), _positionsToReProcessing.PrintToString()));
 }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
/*int OnInit()
{
 
 return(1);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnDeinit()
{
}  */
//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(long ticket, color Color=CLR_NONE)
{
 int index = _openPositions.TicketToIndex(ticket);
 return ClosePosition(index);
}

//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // получаем из массива указатель на позицию по ее индексу
 if (pos.ClosePosition())
 {
  _openPositions.Delete(i);  // удаляем позицию по индексу
  log_file.Write(LOG_DEBUG, StringFormat("%s Удалена позиция [%d]", MakeFunctionPrefix(__FUNCTION__), i));
  return(true);
 }
 else
 {
  error = GetLastError();
  _positionsToReProcessing.Add(_openPositions.Detach(i));
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить позицию [%d]. Позиция перемещена в массив positionsToReProcessing.Error{%d} = %s"
                                        , MakeFunctionPrefix(__FUNCTION__), i, error, ErrorDescription(error)));
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Delete a virtual position from "not_deleted".
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // получаем из массива указатель на позицию по ее индексу
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED) //&& pos.RemoveTakeProfit() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Удалили сработавший стоп-ордер", MakeFunctionPrefix(__FUNCTION__)));
  _positionsToReProcessing.Delete(i);  // удаляем позицию по индексу
  return(true);
 }
 return(false);
}
//+------------------------------------------------------------------+
/// Create magic numbar
/// \param [string] str       symbol
/// \return							generated magic number
//+------------------------------------------------------------------+
long CTradeManager::MakeMagic(string strSymbol = "")
{
 if(strSymbol == "") strSymbol = Symbol();
 string s = strSymbol + PeriodToString(Period()) + MQL5InfoString(MQL5_PROGRAM_NAME);
 ulong ulHash = 5381;
 for(int i = StringLen(s)-1; i >=0;i--)
 {
  ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(s,i);
 }
 return MathAbs((long)ulHash);
}
