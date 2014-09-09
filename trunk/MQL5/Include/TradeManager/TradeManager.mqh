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
#include <TrailingStop\TrailingStop.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>
#include <BlowInfoFromExtremums.mqh>
int error = 0;

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
  double _current_balance;    // текущая прибыль советника в пунктах
  double _current_drawdown;   // текущая просадка баланса
  double _max_drawdown;       // максимально допустимая просадка
  double _max_balance;        // максимальный баланс
  CPosition *_SelectedPosition;
  CTrailingStop *_trailingStop;
  
  bool   _historyChanged;     // флаг изменения истории

  bool   CloseReProcessingPosition(int i,color Color=CLR_NONE);
  string CreateFilename(ENUM_FILENAME filename);
  bool   FindHistoryTicket(long ticket);
  long   MakeMagic(string strSymbol = "");
  bool   LoadArrayFromFile(string file_url,CPositionArray *array);
  bool   SaveArrayToFile(string file_url,CPositionArray *array);  
  bool   ValidSelectedPosition();
  
protected:
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // Наименование звукового файла
  string rescueDataFileName, historyDataFileName;
  datetime _historyStart;
  CPositionArray *_positionsToReProcessing; ///массив позиций, находящихся в процессе
  CPositionArray *_openPositions;           ///массив текущих открытых позиций
  CPositionArray *_positionsHistory;        ///массив истории виртуальных позиций
  
public:
  void CTradeManager();
  void ~CTradeManager(void);
    
  // GET
  double GetCurrentDrawdown() {return(_current_drawdown); };  // возвращает текущую просадку по балансу  
  double GetCurrentProfit()   {return(_current_balance);};    // возвращает текущую прибыль
  long   GetHistoryDepth();                                   // возвращает глубину истории
  double GetMaxDrawdown()     {return(_max_drawdown); };      // возвращает максимальную просадку по балансу
  double GetMaxProfit()       {return(_max_balance);};        // возвращает максимальную прибыль
  int    GetPositionCount()   {return (_openPositions.Total() + _positionsToReProcessing.Total());};  
  CPositionArray* GetPositionHistory(datetime fromDate, datetime toDate = 0); //возвращает массив позиций из истории 
  int    GetPositionPointsProfit(int i, ENUM_SELECT_TYPE type);
  int    GetPositionPointsProfit(string symbol);
  double GetPositionPrice (string symbol);                    // возвращает цену позицию по текущему символу
  double GetPositionStopLoss(string symbol);                  // возвращает текущий стоп лосс позиции по символу
  double GetPositionTakeProfit(string symbol);                // возвращает текущий тейк профит позиции по символу
  ENUM_TM_POSITION_TYPE GetPositionType();
  ENUM_TM_POSITION_TYPE GetPositionType(string symbol);
  
  bool ClosePendingPosition(string symbol, color Color=CLR_NONE); // Закрытие отложенной позиции по символу
  bool ClosePosition(string symbol, color Color=CLR_NONE);    // Закртыие позиции по символу
  bool ClosePosition(long ticket, color Color = CLR_NONE);    // Закртыие позиции по тикету
  bool ClosePosition(int i, color Color = CLR_NONE);          // Закрытие позиции по индексу в массиве позиций
  bool DoTrailing(CBlowInfoFromExtremums *blowInfo=NULL);     // Вызов трейла
  bool isMinProfit();
  bool isMinProfit(string symbol);
  bool isHistoryChanged() {return (_historyChanged);};        // возвращает сигнал изменения истории 
  void ModifyPosition(int sl = 0, int tp = 0);                // Изменяет заранее выбранную позицию
  void ModifyPosition(string symbol, double sl = 0, double tp = 0); // Изменяет заранее выбранную позицию
  void OnTick();
  void OnTrade(datetime history_start);
  bool OpenUniquePosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing,int maxSpread = 0);
  bool OpenMultiPosition (string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing);
  bool PositionChangeSize(string strSymbol, double additionalVolume);
  bool PositionSelect(long index, ENUM_SELECT_TYPE type, ENUM_SELECT_MODE pool = MODE_TRADES);
  void UpdateData(CPositionArray *positionsHistory = NULL);
};

//+---------------------------------
// Конструктор
//+---------------------------------
void CTradeManager::CTradeManager(): 
                    _useSound(true), 
                    _nameFileSound("expert.wav") 
{
 _trailingStop = new CTrailingStop();
 _positionsToReProcessing = new CPositionArray();
 _openPositions           = new CPositionArray();
 _positionsHistory        = new CPositionArray();
 
 _magic = MakeMagic();
 _historyStart = TimeCurrent(); 
 
 _historyChanged = false;  
 
 rescueDataFileName  = CreateFilename(FILENAME_RESCUE);
 historyDataFileName = CreateFilename(FILENAME_HISTORY);
 LoadArrayFromFile(rescueDataFileName ,_openPositions);
 LoadArrayFromFile(historyDataFileName,_positionsHistory);
};

//+---------------------------------
// Деструктор
//+---------------------------------
void CTradeManager::~CTradeManager(void)
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Запущен процесс деинициализации.", MakeFunctionPrefix(__FUNCTION__)));
 //PrintFormat( "%s Запущен процесс деинициализации.", MakeFunctionPrefix(__FUNCTION__));
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
 
 delete _trailingStop;
 delete _positionsToReProcessing;
 delete _openPositions;
 delete _positionsHistory;
 //log_file.Write(LOG_DEBUG, StringFormat("%s Процесс деинициализации завершен.", MakeFunctionPrefix(__FUNCTION__)));
 if(!FileDelete(rescueDataFileName, FILE_COMMON))
 log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить rescue-файл: %s", MakeFunctionPrefix(__FUNCTION__), rescueDataFileName)); 
 // Alert(StringFormat("Не удалось удалить rescue-файл: %s", rescueDataFileName));
};

//+----------------------------------------------------
//| Возвращает грубину истории
//+----------------------------------------------------
long CTradeManager::GetHistoryDepth() 
{
 return _positionsHistory.Total();
}

//+----------------------------------------------------
//  методы для работы с Replay Position
//+----------------------------------------------------
CPositionArray* CTradeManager::GetPositionHistory(datetime fromDate, datetime toDate = 0)
{
 CPositionArray *resultArray;
 resultArray = new CPositionArray(); 
 CPosition *pos;
 datetime posTime;
 int total = _positionsHistory.Total();
 //Print("historyTotal=", _positionsHistory.Total());
 if (toDate == 0) toDate = TimeCurrent();
 
 for(int i = 0; i < total; i++)
 {
  pos = _positionsHistory.At(i);
  posTime = pos.getClosePosDT();
  //PrintFormat("posCloseDate=%s, fromDate=%s, toDate=%s", TimeToString(posTime), TimeToString(fromDate), TimeToString(toDate));
  if (posTime < fromDate) continue;   // Позиции с ранней датой - пропускаем
  if (posTime > toDate) break;        // Добрались до позиций с поздней датой - выходим
  
  resultArray.Add(pos);               // Заполняем массив позициями с датой закрытия в нужном диапазоне
 }
 //Print("resultTotal=", resultArray.Total());
 return resultArray;
} 

//+------------------------------------------------------------------+
//|  Профит позиции на символе в пунктах                             |
//+------------------------------------------------------------------+
int CTradeManager::GetPositionPointsProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   int profit = pos.getPositionPointsProfit();
   return(profit);
  }
 }
 return(0);
}


//+------------------------------------------------------------------+
//|  Средняя цена позиции на текущий момент                          |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionPrice(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
  double price = pos.getPositionPrice();
   return(price);
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
//|  Возвращает текущий стоп лосс позиции по символу                 |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionStopLoss(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.getStopLossPrice());
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
//|  Возвращает текущий тейк профит позиции по символу                 |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionTakeProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.getTakeProfitPrice());
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
/// Return current position type
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType()
{
 if (ValidSelectedPosition())
  return(_SelectedPosition.getType());
 return (OP_UNKNOWN);
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

//+------------------------------------------------------------------+
/// Close a virtual position by symbol.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(string symbol, color Color=CLR_NONE)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // перебираем все ордера или позиции 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (ClosePosition(i)) 
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Успешно закрыта позиция", MakeFunctionPrefix(__FUNCTION__)));
       return (true);
      }
     else
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Не удачно закрыта позиция", MakeFunctionPrefix(__FUNCTION__)));      
       return (false);
      }
   }
  }
 }
 return (true);
}

//+------------------------------------------------------------------+
/// Close a virtual pending position by symbol.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePendingPosition(string symbol, color Color=CLR_NONE)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // перебираем все ордера или позиции 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if(pos.getType() == OP_SELLSTOP || pos.getType() == OP_SELLLIMIT ||
       pos.getType() == OP_BUYSTOP  || pos.getType() == OP_BUYLIMIT )
    {
     if (ClosePosition(i)) return (true);
     else return (false);
    }
   }
  }
 }
 return (true);
}

//+------------------------------------------------------------------+
/// Close a virtual position by ticket.
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
/// Close a virtual position by index.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // получаем из массива указатель на позицию по ее индексу
 //PrintFormat("%s получаем из массива указатель на позицию по ее индексу", MakeFunctionPrefix(__FUNCTION__));
 if (pos.ClosePosition())
 {
  //Print("Перемещаем позицию в хистори");
  _positionsHistory.Add(_openPositions.Detach(i)); //добавляем позицию в историю и удаляем из массива открытых позиций
  _historyChanged = true;                          // меняем флаг, что история увеличилась 
  SaveArrayToFile(historyDataFileName,_positionsHistory); 
  SaveArrayToFile(rescueDataFileName,_openPositions);   
  //log_file.Write(LOG_DEBUG, StringFormat("%s Удалена позиция [%d]", MakeFunctionPrefix(__FUNCTION__), i));
 // PrintFormat("%s Удалена позиция [%d]", MakeFunctionPrefix(__FUNCTION__), i);
  log_file.Write(LOG_DEBUG, StringFormat("%s Удалена позиция [%d]", MakeFunctionPrefix(__FUNCTION__),i ) );     
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

bool CTradeManager::DoTrailing(CBlowInfoFromExtremums *blowInfo=NULL)
{
 int total = _openPositions.Total();
 double sl = 0;
 CPosition *pos;
//--- по массиву открытых позиций
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // выберем позицию по ее индексу
  if (pos.getPositionInfo().type == OP_BUY || pos.getPositionInfo().type == OP_SELL)
  {
   switch(pos.getTrailingType())
   {
    case TRAILING_TYPE_USUAL :
     sl =  _trailingStop.UsualTrailing(pos.getSymbol(), pos.getType(), pos.getPositionPrice(), pos.getStopLossPrice(), pos.getMinProfit(), pos.getTrailingStop(), pos.getTrailingStep());  
     break;
    case TRAILING_TYPE_LOSSLESS :
     sl = _trailingStop.LosslessTrailing(pos.getSymbol(), pos.getType(), pos.getPositionPrice(), pos.getStopLossPrice(), pos.getMinProfit(), pos.getTrailingStop(), pos.getTrailingStep());  
     break;
    case TRAILING_TYPE_PBI :
     sl = _trailingStop.PBITrailing(pos.getType(), pos.getStopLossPrice(), pos.getHandlePBI());  
     break;
    case TRAILING_TYPE_EXTREMUMS :
     if (blowInfo != NULL) sl = _trailingStop.ExtremumsTrailing(pos.getSymbol(), pos.getType(), pos.getStopLossPrice(), pos.getPositionPrice(),blowInfo);
     break;
    case TRAILING_TYPE_NONE :
    default:
     break;
   }
  }
  if (sl > 0) pos.ModifyPosition(sl, 0);
 }
 return (true);
}

//+------------------------------------------------------------------+
/// returns if minProfit achieved
//+------------------------------------------------------------------+
bool CTradeManager::isMinProfit()
{
 if (ValidSelectedPosition())
  return(_SelectedPosition.isMinProfit());
 return (false);
}

//+------------------------------------------------------------------+
/// returns if minProfit achieved 
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
// Функция модификации позиции
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(int sl = 0, int tp = 0)
{
 if (sl > 0){}
 if (tp > 0){}
}

//+------------------------------------------------------------------+ 
// Функция модификации позиции
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(string symbol, double sl = 0, double tp = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if(sl > 0)
    pos.ModifyPosition(sl, tp);
  }
 }
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
    _positionsHistory.Add(_positionsToReProcessing.Detach(i)); //добавляем удаляемую позицию в массив
    _historyChanged = true; // меняем флаг, что история увеличилась
    SaveArrayToFile(historyDataFileName,_positionsHistory);                    
    break;
   }
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_CHANGED)
  {
   if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
   {
    pos.ChangeStopLossVolume();
   }
   if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_PLACED)
   {
    pos.setStopLoss();
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
    SaveArrayToFile(rescueDataFileName,_openPositions);    
   }
  }
 } 

//--- Подгружаем историю
 if(!HistorySelect(_historyStart, TimeCurrent()))
 {
  //log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось выбрать историю с %s по %s", MakeFunctionPrefix(__FUNCTION__), _historyStart, TimeCurrent())); 
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
   log_file.Write(LOG_DEBUG, StringFormat("%s Стоп-лосс тикет = %d, Статус позиции = %s, Статус стоп-лосса = %s"
                , MakeFunctionPrefix(__FUNCTION__)
                    , pos.getStopLossTicket()
                                         , PositionStatusToStr(pos.getPositionStatus())
                                                              , StoplevelStatusToStr(pos.getStopLossStatus()))  );
   log_file.Write(LOG_DEBUG, StringFormat("%s Нет ордера-StopLoss, удаляем позицию [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   pos.setPositionStatus(POSITION_STATUS_CLOSED);
   ClosePosition(i);
   break;                          
  }
  
  if (pos.CheckTakeProfit())    //проверяем условие выполнения TP
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Цена дошла до уровня TP, закрываем позицию type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice()) );
   ClosePosition(i);
   break;             
  }
     
  if (pos.getPositionStatus() == POSITION_STATUS_PENDING) // Если это позиция отложенным ордером...
  {
   if (!OrderSelect(pos.getOrderTicket())) // Если мы не можем выбрать ее по тикету
   {
    long ticket = pos.getOrderTicket();
    if(!FindHistoryTicket(ticket))            // Попробуем найти этот тикет в истории
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s В массиве историй не найден ордер с тикетом %d", MakeFunctionPrefix(__FUNCTION__), ticket));
     return;
    }
    
    long state;
    if (HistoryOrderGetInteger(ticket, ORDER_STATE, state)) // Получим статус ордера из истории
    {
     switch ((int)state)
     {
      case ORDER_STATE_FILLED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Сработала позиция являющаяся отложенным ордером.Пытаемся установить StopLoss и TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP) pos.setType(OP_BUY);
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP) pos.setType(OP_SELL);
       
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
       log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
       
       SaveArrayToFile(rescueDataFileName,_openPositions);       
       break;
      }
      case ORDER_STATE_CANCELED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ордер отменен %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = true; // меняем флаг, что история увеличилась  
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
       break;
      }
      case ORDER_STATE_EXPIRED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s прошло время ожидания %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = true; // меняем флаг, что история увеличилась
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
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
     log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось выбрать ордер по тикету %d из истории", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
     log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(GetLastError())));
     string str;
     int historyTotal = HistoryOrdersTotal();
     for(int j = historyTotal - 1; j >= 0; j--)
     {
      str += IntegerToString(HistoryOrderGetTicket(j)) + " ";
     }
     log_file.Write(LOG_DEBUG, StringFormat("%s Тикеты ордеров из истории: %s", MakeFunctionPrefix(__FUNCTION__), str));
    } 
   }
  }
 }
}

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Include the folowing in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start=0)
{
 // возвращаем флаг изменения истории 
 if (_historyChanged)
  {
   _historyChanged = false;
  }
}

//+------------------------------------------------------------------+
//| Открывает единственную позицию                                   |
//| если существует такая же позиция - открытия не будет             |
//| если существует противоположная позиция - она будет закрыта      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenUniquePosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing,int maxSpread = 0)
{
 if ( SymbolInfoInteger(symbol,SYMBOL_SPREAD) > maxSpread)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Невозможно открыть позицию так как спред превысил максимальное значение", MakeFunctionPrefix(__FUNCTION__)));
  return false;  
 }
 if (_positionsToReProcessing.OrderCount(symbol, _magic) > 0) 
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Невозможно открыть позицию так как еще есть позиции в positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 log_file.Write(LOG_DEBUG, StringFormat("%s, Открываем позицию %s. Открытых позиций на данный момент: %d", MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos_info.type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // Распечатка всех позиций из массива _openPositions
 switch(pos_info.type)
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
        if(OrderSelect(pos.getOrderTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, Закрытие позиции не удалось: Не выбран ордер с тикетом %d. Ошибка %d - %s"
                       , MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()
                       , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось выбрать позицию по тикету %d", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
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
        if(OrderSelect(pos.getOrderTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, Закрытие позиции не удалось: Не выбран ордер с тикетом %d. Ошибка %d - %s"
                        , MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()
                        , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось выбрать позицию по тикету %d", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
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
 // PrintFormat("%s openPositions и positionsToReProcessing пусты - открываем новую позицию", MakeFunctionPrefix(__FUNCTION__));
  
  pos = new CPosition(_magic, symbol, timeframe, pos_info, trailing);
  ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // удалось установить желаемую позицию
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                          , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));


   _openPositions.Add(pos);  // добавляем открытую позицию в массив открытых позиций
   SaveArrayToFile(rescueDataFileName ,_openPositions);
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
bool CTradeManager::OpenMultiPosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 //log_file.Write(LOG_DEBUG
 //             ,StringFormat("%s, Открываем позицию %s. Открытых позиций на данный момент: %d"
 //                           , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s, Открываем мульти-позицию %s. Открытых позиций на данный момент: %d", MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos_info.type), total) ); 
// log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // Распечатка всех позиций из массива _openPositions
 
 pos = new CPosition(_magic, symbol, timeframe, pos_info, trailing);
 ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
 //Print("openingResult=", PositionStatusToStr(openingResult));
 if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // удалось установить желаемую позицию
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                         , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));
  _openPositions.Add(pos);  // добавляем открутую позицию в массив открытых позиций

  SaveArrayToFile(rescueDataFileName ,_openPositions);  
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
// Функция изменения объема позиции
//+------------------------------------------------------------------+
bool CTradeManager::PositionChangeSize(string symbol, double additionalVolume)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // перебираем все ордера или позиции 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (pos.getVolume() + additionalVolume != 0)
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Изменим объем текущей позиции", MakeFunctionPrefix(__FUNCTION__)) );
     if (pos.ChangeSize(additionalVolume))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Объем позиции успешно изменен", MakeFunctionPrefix(__FUNCTION__)) );
      return (true);
     }
     else
     {
      if (pos.getPositionStatus() == POSITION_STATUS_NOT_CHANGED)
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось изменить стоп-лосс при изменении объема позиции", MakeFunctionPrefix(__FUNCTION__)) );
       _positionsToReProcessing.Add(_openPositions.Detach(i));
      }
     }
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Изменение позиции. Итоговый объем равен 0, закрываем позицию", MakeFunctionPrefix(__FUNCTION__)) );
     if (ClosePosition(i)) return (true);
    }
   }
  }
 }
 return (false);
}

//+------------------------------------------------------------------+
/// Select an open virtual position.
/// \param [in] i			Either index or ticket
/// \param [in] type		Either SELECT_BY_POS or SELECT_BY_TICKET		
/// \param [in] pool		Either MODE_TRADES (default) or MODE_HISTORY
/// \return					True if successful, false otherwise
//+------------------------------------------------------------------+
bool CTradeManager::PositionSelect(long index, ENUM_SELECT_TYPE type, ENUM_SELECT_MODE pool = MODE_TRADES)
{
 switch(type)
 {
  case SELECT_BY_POS:
   switch(pool)
   {
    case MODE_TRADES: _SelectedPosition = _openPositions.At((int)index); return(true);
    case MODE_HISTORY: _SelectedPosition = _positionsHistory.At((int)index); return(true);
    default:
     log_file.Write(LOG_DEBUG, StringFormat("%s error: Unknown pool id %s", MakeFunctionPrefix(__FUNCTION__),(string)pool));
     return(false);
   }
   break;
  case SELECT_BY_TICKET:
   switch(pool)
   {
    case MODE_TRADES: _SelectedPosition = _openPositions.AtTicket(index); return(true);
    case MODE_HISTORY: _SelectedPosition = _positionsHistory.AtTicket(index); return(true);
    default:
     log_file.Write(LOG_DEBUG, StringFormat("%s error: Unknown pool id %s", MakeFunctionPrefix(__FUNCTION__),(string)pool));
     return(false);
   }
   break;
  default:
     log_file.Write(LOG_DEBUG, StringFormat("%s error: Unknown type %s", MakeFunctionPrefix(__FUNCTION__),(string)type));
   return(false);
 }
}

//+------------------------------------------------------------------+
//|  Обновляет данные о текущей прибыли и просадке                   |
//+------------------------------------------------------------------+
void CTradeManager::UpdateData(CPositionArray *positionsHistory = NULL)
{
 if (positionsHistory == NULL) positionsHistory = _positionsHistory;
 int index;  // индекс прохода по циклу
 int length = positionsHistory.Total(); // длина переданного массива истории
 CPosition *pos; // указатель на текущую позицию
 // проходим по всем массиву и вычисляем текущую прибыль
    
 for (index = 0; index < length; index++)
 {
  // извлекаем указатель на текущую позицию по индексу
  pos = positionsHistory.At(index);
  // изменяем текущую прибыль 
  _current_balance = _current_balance + pos.getPosProfit();
  //если баланс превысил текущий максимальный баланс
  if (_current_balance > _max_balance)  
  {
   // то перезаписываем его
   _max_balance = _current_balance;
  }
  else 
  {
   //если обнаружена больше просадка, чем была
   if ((_max_balance-_current_balance) > _current_drawdown) 
   {
    //то записываем новую просадку баланса
    _current_drawdown = _max_balance-_current_balance;  
   }
  }  
 }
}

//---------------PRIVATE-----------------------------

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
  _positionsHistory.Add(_positionsToReProcessing.Detach(i));
  _historyChanged = 1; // меняем флаг, что история увеличилась  
  SaveArrayToFile(historyDataFileName,_positionsHistory);  
  return(true);
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Create file name
/// \return							generated string
//+------------------------------------------------------------------+
string CTradeManager::CreateFilename (ENUM_FILENAME filename)
{
 string name, result;
 switch(filename)
   {
    case FILENAME_RESCUE :
      name = "RescueData";
      break;
    case FILENAME_HISTORY :
      name = "History";
      break;
    default:
      break;
   }
 result = StringFormat("%s\\%s\\%s_%s_%s.csv", MQL5InfoString(MQL5_PROGRAM_NAME), name, MQL5InfoString(MQL5_PROGRAM_NAME), StringSubstr(Symbol(),0,6), PeriodToString(Period()));
 return(result);
}

//+----------------------------------------------------
//  Загрузка из файла массива позиций                 
//+----------------------------------------------------
bool CTradeManager::LoadArrayFromFile(string file_url,CPositionArray *array)
{
 if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
 {
  FileDelete(file_url);
  return(true);
 }
 
 int file_handle;   //файловый хэндл  
 if (!FileIsExist(file_url, FILE_COMMON) ) //проверка существования файла истории 
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Файл %s не существует", MakeFunctionPrefix(__FUNCTION__),file_url) );
  return (true);
 }  
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), historyDataFileName);
  return (false);
 }
 
 array.Clear();                   //очищаем массив
 array.ReadFromFile(file_handle); //загружаем данные из файла 
 FileClose(file_handle);          //закрывает файл  
 return (true);
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

//+----------------------------------------------------
//  Сохранение в файл массива позиций                 |
//+----------------------------------------------------
bool CTradeManager::SaveArrayToFile(string file_url, CPositionArray *array)
{
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Не получилось открыть файл: %s", MakeFunctionPrefix(__FUNCTION__), file_url));
  return(false);
 }
 array.WriteToFile(file_handle);  //сохраняем массив в файл
 FileClose(file_handle);
 return(true);
}

//+----------------------------------------------------
// Checks that the selected position pointer is valid
//+----------------------------------------------------
bool CTradeManager::ValidSelectedPosition()
{
 if(CheckPointer(_SelectedPosition)==POINTER_INVALID)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Error: _SelectedPosition pointer is not valid", MakeFunctionPrefix(__FUNCTION__)));
  return(false);
 }
 else
 {
  return(true);
 }
}

//+------------------------------------------------------------------+
/// Search for ticket in History
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::FindHistoryTicket(long ticket)
{
 int total = HistoryOrdersTotal();
 for(int i = 0; i < total; i++)
 {
  if(ticket == HistoryOrderGetTicket(i)) return (true);  
 }
 return (false);
}









