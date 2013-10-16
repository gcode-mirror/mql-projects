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
private:
  bool CloseReProcessingPosition(int i,color Color=CLR_NONE);
  long MakeMagic(string strSymbol = "");
  void SaveSituationToFile();  
  
protected:
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // Наименование звукового файла
  datetime _historyStart;
  
  CPositionArray _positionsToReProcessing;
  CPositionArray _openPositions; ///< Array of open virtual orders for this VOM instance, also persisted as a file
  //CPositionArray _positionsHistory; ///< Array of closed virtual orders, also persisted as a file
  
public:
  void CTradeManager():  _useSound(true), _nameFileSound("expert.wav") 
  {
   _magic = MakeMagic();
   _historyStart = TimeCurrent(); 
   log_file.Write(LOG_DEBUG, StringFormat("%s Создание объекта CTradeManager", MakeFunctionPrefix(__FUNCTION__)));
   log_file.Write(LOG_DEBUG, StringFormat("%s History start: %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_historyStart))); 
  };
  
  bool OpenMultiPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                    int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
  bool OpenUniquePosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                    int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  bool ClosePosition(long ticket, color Color=CLR_NONE);     // Закртыие позиции по тикету
  bool ClosePosition(int i,color Color=CLR_NONE);            // Закрытие позиции по индексу в массиве позиций
  bool ClosePosition(string symbol, color Color=CLR_NONE);   // Закрытие позиции по символу 
  void DoTrailing();
  void Initialization();
  void Deinitialization();
  void OnTick();
  void OnTrade(datetime history_start);
  bool isMinProfit(string symbol);
  ENUM_TM_POSITION_TYPE GetPositionType(string symbol);
  
    //методы по работе с ReplayPosition
  
  ReplayPos* GetReplayPosition(long index); //извлекает свойства позиции 
  long GetHistoryDepth();  //возвращает глубину истории
};

//+------------------------------------------------------------------+
//| Открывает единственную позицию                                   |
//| если существует такая же позиция - открытия не будет             |
//| если существует противоположная позиция - она будет закрыта      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenUniquePosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 if (_positionsToReProcessing.OrderCount(symbol, _magic) > 0) 
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Невозможно открыть позицию так как еще есть позиции в positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, Открываем позицию %s. Открытых позиций на данный момент: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // Распечатка всех позиций из массива _openPositions
 switch(type)
 {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на продажу
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_SELL)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getPositionTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, Закрытие позиции не удалось: Не выбран ордер с тикетом %d. Ошибка %d - %s"
                       , MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()
                       , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось выбрать позицию по тикету %d", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()));
       }
      }
     }
    }
   }
   break;
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на покупку
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_BUY)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getPositionTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, Закрытие позиции не удалось: Не выбран ордер с тикетом %d. Ошибка %d - %s"
                        , MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()
                        , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось выбрать позицию по тикету %d", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()));
       }
      }
     }
    }
   }
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 total = _openPositions.OrderCount(symbol, _magic) + _positionsToReProcessing.OrderCount(symbol, _magic);
 if (total <= 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s openPositions и positionsToReProcessing пусты - открываем новую позицию", MakeFunctionPrefix(__FUNCTION__)));
  pos = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // удалось установить желаемую позицию
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                          , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));
   _openPositions.Add(pos);  // добавляем открутую позицию в массив открытых позиций
   SaveSituationToFile();
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
   return(true); // Если удачно открыли позицию
  }
  else
  {
   error = GetLastError();
   if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось открыть позицию. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
   return(false); // Если открыть позицию не удалось
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s Осталось открытых позиций %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // Если остались открытые позиции, значит не надо открываться 
}

//+------------------------------------------------------------------+
//| Открывает позицию                                   |
//| если существует такая же позиция - открытия не будет             |
//| если существует противоположная позиция - она будет закрыта      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenMultiPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, Открываем позицию %s. Открытых позиций на данный момент: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // Распечатка всех позиций из массива _openPositions
 
 pos = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
 ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
 if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // удалось установить желаемую позицию
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                         , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));
  _openPositions.Add(pos);  // добавляем открутую позицию в массив открытых позиций
  SaveSituationToFile();
  log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  return(true); // Если удачно открыли позицию
 }
 else
 {
  error = GetLastError();
  if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось открыть позицию. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
  return(false); // Если открыть позицию не удалось
 }

 log_file.Write(LOG_DEBUG, StringFormat("%s Осталось открытых позиций %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // Если остались открытые позиции, значит не надо открываться 
}

//+------------------------------------------------------------------+ 
// Функция вычисления параметров трейлинга
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()
{
 int total = _openPositions.Total();
//--- пройдем в цикле по всем ордерам
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  if(pos.DoTrailing())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Изменился SL позиции [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  }
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
/// Include the folowing in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start)
{
}

//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual positions 
/// Include the folowing in each EA that uses TradeManage
//+------------------------------------------------------------------+
void CTradeManager::OnTick()
{
//--- Сначала обработаем незавершенные позиции
 int total = _positionsToReProcessing.Total();
 for(int i = total - 1; i>=0; i--) // по массиву позиций на доработку
 {
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
  
  if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Удаляем StopLoss и TakeProfit", MakeFunctionPrefix(__FUNCTION__)));    
   CloseReProcessingPosition(i);
   break;
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Получилось установить StopLoss и TakeProfit у позиции [%d].Перемещаем её из positionsToReProcessing в openPositions.", MakeFunctionPrefix(__FUNCTION__), i));    
    pos.setPositionStatus(POSITION_STATUS_OPEN);
    _openPositions.Add(_positionsToReProcessing.Detach(i));
    SaveSituationToFile();
   }
  }
 } 
 
//--- Подгружаем историю
 if(!HistorySelect(_historyStart, TimeCurrent()))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось выбрать историю с %s по %s", MakeFunctionPrefix(__FUNCTION__), _historyStart, TimeCurrent())); 
  return;
 }

//--- Если история подгрузилась, работаем с текущими позициями  
 total = _openPositions.Total();
 CPosition *pos;
//--- по массиву НАШИХ позиций
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // выберем позицию по ее индексу
  ENUM_TM_POSITION_TYPE type = pos.getType();
  
  if (!OrderSelect(pos.getStopLossTicket()) && pos.getPositionStatus() != POSITION_STATUS_PENDING && pos.getStopLossStatus() != STOPLEVEL_STATUS_NOT_DEFINED) // Если мы не можем выбрать стоп по его тикету, значит он сработал
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Нет ордера-StopLoss, удаляем позицию [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   _openPositions.Delete(i);            // удалить позицию из массива позиций


   SaveSituationToFile();               // Переписать файл состояния
   break;                          
  }
  
  if (pos.CheckTakeProfit())    //проверяем условие выполнения TP
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Цена дошла до уровня TP, закрываем позицию type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice()));
   ClosePosition(i);
   break;             
  }
     
  if (pos.getPositionStatus() == POSITION_STATUS_PENDING) // Если это позиция отложенным ордером...
  {
   if (!OrderSelect(pos.getPositionTicket())) // Если мы не можем выбрать ее по тикету
   {
    long ticket = pos.getPositionTicket();
    if(!FindHistoryTicket(ticket))            // Попробуем найти этот тикет в истории
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s В массиве историй не найден ордер с тикетом %d", MakeFunctionPrefix(__FUNCTION__), ticket));
     return;
    }
    
    long state;
    if (HistoryOrderGetInteger(ticket, ORDER_STATE, state)) // Получим статус ордера из истории
    {
     switch (state)
     {
      case ORDER_STATE_FILLED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Сработала позиция являющаяся отложенным ордером.Пытаемся установить StopLoss и TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       
       if (pos.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || pos.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // попробуем установить стоплосс и тейкпрофит
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось установить StopLoss и/или TakeProfit. Перемещаем позицию [%d] в positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
        pos.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // если не получилось, запомним, чтобы повторить позднее
        _positionsToReProcessing.Add(_openPositions.Detach(i)); 
        break;
       }
       
       log_file.Write(LOG_DEBUG, StringFormat("%s Получилось установить StopLoss и/или TakeProfit. Изменяем позицию [%d] в openPositions.", MakeFunctionPrefix(__FUNCTION__)));
       pos.setPositionStatus(POSITION_STATUS_OPEN); // позиция открылась, стоп и тейк установлены
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP) pos.setType(OP_BUY);
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP) pos.setType(OP_SELL);
       log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
       SaveSituationToFile();
       break;
      }
      case ORDER_STATE_CANCELED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ордер отменен %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getPositionTicket(), ORDER_STATE))));
       _openPositions.Delete(i);
       break;
      }
      case ORDER_STATE_EXPIRED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s прошло время ожидания %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getPositionTicket(), ORDER_STATE))));
       _openPositions.Delete(i);
       break;
      }
      
      default:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Плохой статус оредера при перемещении в историю: %s; тикет ордера: %d", MakeFunctionPrefix(__FUNCTION__), EnumToString((ENUM_ORDER_STATE)state), ticket));
       break;
      }
     }
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось выбрать ордер по тикету %d из истории", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()));
     log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(GetLastError())));
     string str;
     int total = HistoryOrdersTotal();
     for(int i = total-1; i >= 0; i--)
     {
      str += HistoryOrderGetTicket(i) + " ";
     }
     log_file.Write(LOG_DEBUG, StringFormat("%s Тикеты ордеров из истории: %s", MakeFunctionPrefix(__FUNCTION__), str));
    } 
   }
  }
 }
}

//+------------------------------------------------------------------+
//
//+------------------------------------------------------------------+
void CTradeManager::Initialization()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Запущен процесс инициализации.", MakeFunctionPrefix(__FUNCTION__)));
 int file_handle = FileOpen(CreateRDFilename(), FILE_READ|FILE_CSV|FILE_COMMON, ";");
 if (file_handle != INVALID_HANDLE)
 {
  if(FileReadDatetime(file_handle) < TimeCurrent())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Существует файл состояния. Считываем данные из него.", MakeFunctionPrefix(__FUNCTION__)));
   _openPositions.ReadFromFile(file_handle);
   FileClose(CreateRDFilename());
   log_file.Write(LOG_DEBUG, StringFormat("%s Скопировали данные из файла состояния.", MakeFunctionPrefix(__FUNCTION__)));
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  }
  else
   log_file.Write(LOG_DEBUG, StringFormat("%s Файл состояния не является актуальным.Игнорируем.", MakeFunctionPrefix(__FUNCTION__)));
 }
 else
  log_file.Write(LOG_DEBUG, StringFormat("%s Файл состояния отсутствует.Предыдущее завершенее программы было корректным.", MakeFunctionPrefix(__FUNCTION__)));
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CTradeManager::Deinitialization()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Запущен процесс деинициализации.", MakeFunctionPrefix(__FUNCTION__)));
 int size = _openPositions.Total();
 int attempts = 0;
 while (attempts < 25)
 {
  for(int i = size - 1; i>=0; i--) // по массиву НАШИХ позиций
  {
   ClosePosition(i);
  }
  size = _openPositions.Total();
  if(size == 0) break;
  attempts++;
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s Процесс деинициализации завершен.", MakeFunctionPrefix(__FUNCTION__)));
 FileDelete(CreateRDFilename(), FILE_COMMON);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CTradeManager::isMinProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.isMinProfit());
  }
 }
 return false;
}
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
/// \param [in] symbol			current symbol
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(string symbol, color Color=CLR_NONE)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(ClosePosition(i));
  }
 }
 return false;
}

//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // получаем из массива указатель на позицию по ее индексу
 if (pos.ClosePosition())
 {
  //_positionsHistory.Add(_openPositions.Detach(i)); //добавляем позицию в историю и удаляем из массива открытых позиций
   
  SaveSituationToFile();
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
/// Delete a virtual pos from "not_deleted".
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // получаем из массива указатель на позицию по ее индексу
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Удалили сработавший стоп-ордер", MakeFunctionPrefix(__FUNCTION__)));
  _positionsToReProcessing.Delete(i);  // удаляем позицию по индексу
  return(true);
 }
 return(false);
}
//+------------------------------------------------------------------+
/// Create magic number
/// \param [string] str       symbol
/// \return							generated magic number
//+------------------------------------------------------------------+
long CTradeManager::MakeMagic(string strSymbol = "")
{
 if(strSymbol == "") strSymbol = Symbol();
 string s = strSymbol + PeriodToString(Period()) + MQL5InfoString(MQL5_PROGRAM_NAME);
 ulong ulHash = 5381;
 for(int i = StringLen(s) - 1; i >= 0; i--)
 {
  ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(s,i);
 }
 return MathAbs((long)ulHash);
}

//+------------------------------------------------------------------+
/// Create file name
/// \param [bool] debug       if want to debug
/// \return							generated string
//+------------------------------------------------------------------+
string CreateRDFilename ()
{
 string result;
 result = StringFormat("%s\\RescueData\\%s_%s_%s_rd.csv", MQL5InfoString(MQL5_PROGRAM_NAME), MQL5InfoString(MQL5_PROGRAM_NAME), StringSubstr(Symbol(),0,6), PeriodToString(Period()));
 return(result);
}

//+------------------------------------------------------------------+
/// Save position array to file
/// \param [bool] debug       if want to debug
//+------------------------------------------------------------------+
void CTradeManager::SaveSituationToFile()
{
 int file_handle = FileOpen(CreateRDFilename(), FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось открыть файл: %s", MakeFunctionPrefix(__FUNCTION__), CreateRDFilename()));
  return;
 }
 _openPositions.WriteToFile(file_handle);
 FileClose(file_handle);
}

//+------------------------------------------------------------------+
/// Search for ticket in History
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
bool FindHistoryTicket(long ticket)
{
 int total = HistoryOrdersTotal();
 for(int i = 0; i < total; i++)
 {
  if(ticket == HistoryOrderGetTicket(i)) return true;  
 }
 return false;
}
//+------------------------------------------------------------------+
/// Return current position type
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType(string symbol)
{
  int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.getType());
  }
 }
 return OP_UNKNOWN;
}

 //методы работы с Replay Position
 
/* 
ReplayPos* CTradeManager::GetReplayPosition(long index)
 { 
  ReplayPos *rep_pos;
  CPosition *pos;
  pos = _positionsHistory.Position(index);
  if (pos != NULL) //если позиция с данным индексом существует
   {
    if (pos.getPosProfit() < 0)  //если позиция в убытке
    {
     rep_pos = new ReplayPos();
     rep_pos.price_close = pos.getPriceClose();         //сохраняем цену закрытия
     rep_pos.price_open  = pos.getPriceOpen();          //сохраняем цену открытия
     rep_pos.status = POSITION_STATUS_MUST_BE_REPLAYED; //позиция должна отыграться
     rep_pos.symbol = pos.getSymbol();                  //сохраняем символа
     rep_pos.type = pos.getType();                      //сохраняем тип позиции  
     rep_pos.profit = pos.getPosProfit();               //профит позиции
    }                       
   }
         
   return rep_pos;
 } 
 

long CTradeManager::GetHistoryDepth() //возвращает грубину истории
 {
  return _positionsHistory.Total();
 }*/