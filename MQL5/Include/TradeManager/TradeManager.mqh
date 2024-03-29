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
#include <BlowInfoFromExtremums.mqh>

#define RISK 0.01
int error = 0;

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
  double _current_balance;    // ������� ������� ��������� � �������
  double _current_drawdown;   // ������� �������� �������
  double _max_drawdown;       // ����������� ���������� ��������
  double _max_balance;        // ������������ ������
  CPosition *_SelectedPosition;
  
  bool   _historyChanged;     // ���� ��������� �������
  
  double CalcVolume(string symbol);
  bool   CloseReProcessingPosition(int i,color Color=CLR_NONE);
  string CreateFilename(ENUM_FILENAME filename);
  bool   FindHistoryTicket(long ticket);
  bool   LoadArrayFromFile(string file_url,CPositionArray *array);
  bool   SaveArrayToFile(string file_url,CPositionArray *array);  
  void   CheckOpenedPositions(string symbol, ENUM_TM_POSITION_TYPE type, long magic = 0);
  bool   OpenPosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing);
  bool   ValidSelectedPosition();
  
protected:
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  string rescueDataFileName, historyDataFileName;
  datetime _historyStart;
  CPositionArray *_positionsToReProcessing; ///������ �������, ����������� � ��������
  CPositionArray *_openPositions;           ///������ ������� �������� �������
  CPositionArray *_positionsHistory;        ///������ ������� ����������� �������
  
public:
  void CTradeManager();
  void ~CTradeManager(void);
    
  // GET
  double GetCurrentDrawdown() { return(_current_drawdown);};   // ���������� ������� �������� �� �������  
  double GetCurrentProfit()   { return(_current_balance);};    // ���������� ������� �������
  long   GetHistoryDepth();                                   // ���������� ������� �������
  double GetMaxDrawdown()     { return(_max_drawdown); };      // ���������� ������������ �������� �� �������
  double GetMaxProfit()       { return(_max_balance);};        // ���������� ������������ �������
  int    GetPositionCount()   { return (_openPositions.Total() + _positionsToReProcessing.Total());}; 
  int    GetPositionCount(long magic);
  CPositionArray* GetPositionHistory(datetime fromDate, datetime toDate = 0); //���������� ������ ������� �� ������� 
  //int    GetPositionPointsProfit(int i, ENUM_SELECT_TYPE type);
  long   GetPositionMagic()   {return _SelectedPosition.getMagic();}; // ���������� ���� ��������� ������� 
  int    GetPositionPointsProfit(string symbol, long magic = 0);
  double GetPositionPrice() {return _SelectedPosition.getPositionPrice();};                                   // ���������� ���� ��������� �������
  double GetPositionPrice(string symbol, long magic = 0);      // ���������� ���� ������� �� �������� �������
  double GetPositionStopLoss() {return _SelectedPosition.getStopLossPrice();};                                // ���������� ���� ���� ��������� �������
  double GetPositionStopLoss(string symbol, long magic = 0);   // ���������� ������� ���� ���� ������� �� �������
  double GetPositionTakeProfit() {return _SelectedPosition.getTakeProfitPrice();}; // ���������� ���� ������ ��������� �������
  double GetPositionTakeProfit(string symbol, long magic = 0); // ���������� ������� ���� ������ ������� �� �������
  ENUM_TM_POSITION_TYPE GetPositionType();                     // ���������� ��� ��������� �������
  ENUM_TM_POSITION_TYPE GetPositionType(string symbol, long magic = 0);       // ���������� ��� ������� �� ������� � �������
  double GetPositionVolume(string symbol, long magic = 0);     // ���������� ����� ������� �� ������� � �������
  
  bool ClosePendingPosition(string symbol, long magic = 0, color Color=CLR_NONE);      // �������� ���������� ������� �� �������
  bool ClosePosition(string symbol, color Color = CLR_NONE);             // �������� ������� �� �������
  bool ClosePosition(long ticket, color Color = CLR_NONE);             // �������� ������� �� ������
  bool ClosePosition(int i, color Color = CLR_NONE);                   // �������� ������� �� ������� � ������� �������
  bool ClosePosition(CPosition *pos, color Color = CLR_NONE);          // �������� ������� �� ��������� � ������� �������
  bool CloseSelectedPosition(color Color=CLR_NONE);                    // �������� ��������� ������� 
  void DoTrailing(int handleExtr = 0);                                 // ����� ������
  bool isMinProfit();
  bool isMinProfit(string symbol);
  bool isHistoryChanged() {return (_historyChanged);};        // ���������� ������ ��������� ������� 
  long MakeMagic(string strSymbol = "", ENUM_TIMEFRAMES period = PERIOD_CURRENT);
  void ModifyPosition(string symbol, long magic = 0, double sl = 0, double tp = 0); // �������� ������� �� �������
  void OnTick();
  void OnTrade(datetime history_start);
  bool OpenUniquePosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, int maxSpread = 0);
  bool OpenPairPosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, double volume_percent, int maxSpread = 0);
  bool OpenMultiPosition (string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, int maxSpread = 0);
  bool PositionChangeSize(double additionalVolume);
  bool PositionChangeSize(string strSymbol, double additionalVolume, long magic = 0);
  bool PositionSelect(long index, ENUM_SELECT_TYPE type, ENUM_SELECT_MODE pool = MODE_TRADES);
  void UpdateData(CPositionArray *positionsHistory = NULL);
};

//+---------------------------------
// �����������
//+---------------------------------
void CTradeManager::CTradeManager(): 
                    _useSound(true), 
                    _nameFileSound("expert.wav") 
{
 _positionsToReProcessing = new CPositionArray();
 _openPositions           = new CPositionArray();
 _positionsHistory        = new CPositionArray();
 
 //_magic = MakeMagic();
 _historyStart = TimeCurrent(); 
 
 _historyChanged = false;  
 
 rescueDataFileName  = CreateFilename(FILENAME_RESCUE);
 historyDataFileName = CreateFilename(FILENAME_HISTORY);
 LoadArrayFromFile(rescueDataFileName ,_openPositions);
 LoadArrayFromFile(historyDataFileName,_positionsHistory);
};

//+---------------------------------
// ����������
//+---------------------------------
void CTradeManager::~CTradeManager(void)
{
 log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ������� ���������������.", MakeFunctionPrefix(__FUNCTION__)));
 //PrintFormat( "%s ������� ������� ���������������.", MakeFunctionPrefix(__FUNCTION__));
 int size = _openPositions.Total();
 int attempts = 0;
 while (attempts < 25)
 {
  for(int i = size - 1; i>=0; i--) // �� ������� ����� �������
  {
   ClosePosition(i);
  }
  size = _openPositions.Total(); 
  if(size == 0) break;
  attempts++;
 }
 
 delete _positionsToReProcessing;
 delete _openPositions;
 delete _positionsHistory;
 //log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ��������������� ��������.", MakeFunctionPrefix(__FUNCTION__)));
 if(!FileDelete(rescueDataFileName, FILE_COMMON))
 log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� ������� rescue-����: %s", MakeFunctionPrefix(__FUNCTION__), rescueDataFileName)); 
 // Alert(StringFormat("�� ������� ������� rescue-����: %s", rescueDataFileName));
};

//+----------------------------------------------------
//| ���������� ������� �������
//+----------------------------------------------------
long CTradeManager::GetHistoryDepth() 
{
 return _positionsHistory.Total();
}

//+----------------------------------------------------
//| ���������� ���������� ������� � �������� ��������
//+----------------------------------------------------
int CTradeManager::GetPositionCount(long magic)
{
 int total = _openPositions.Total();
 int count = 0;
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getMagic() == magic)
  {
   count++;
  }
 }
 return(count); 
}

//+----------------------------------------------------
//  ������ ��� ������ � Replay Position
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
  if (posTime < fromDate) continue;   // ������� � ������ ����� - ����������
  if (posTime > toDate) break;        // ��������� �� ������� � ������� ����� - �������
  
  resultArray.Add(pos);               // ��������� ������ ��������� � ����� �������� � ������ ���������
 }
 //Print("resultTotal=", resultArray.Total());
 return resultArray;
} 

//+------------------------------------------------------------------+
//|  ������ ������� �� ������� � �������                             |
//+------------------------------------------------------------------+
int CTradeManager::GetPositionPointsProfit(string symbol, long magic = 0)
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
//|  ������� ���� ������� �� ������� ������                          |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionPrice(string symbol, long magic = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic || magic == 0)
   {
    return(pos.getPositionPrice());
   }
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
//|  ���������� ������� ���� ���� ������� �� �������                 |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionStopLoss(string symbol, long magic = 0 )
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic || magic == 0)
   {
    return(pos.getStopLossPrice());
   }
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
//|  ���������� ������� ���� ������ ������� �� ������� � �������     |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionTakeProfit(string symbol, long magic = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic || magic == 0)
   {
    return(pos.getTakeProfitPrice());
   }
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
/// Return current position type
/// \param [string] symbol     symbol to search
/// \param [long] magic        magic number to search
/// \return                    selected position type
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType()
{
 if (ValidSelectedPosition())
  return(_SelectedPosition.getType());
 return (OP_UNKNOWN);
}

//+------------------------------------------------------------------+
/// Return current position type
/// \param [string] symbol     symbol to search
/// \param [long] magic        magic number to search
/// \return                    current position type
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType(string symbol, long magic = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic || magic == 0)
   {
    return(pos.getType());
   }
  }
 }
 return OP_UNKNOWN;
}

//+------------------------------------------------------------------+
/// Return current position volume
/// \param [string] symbol     symbol to search
/// \param [long] magic        magic number to search
/// \return                    current position volume
//+------------------------------------------------------------------+
double CTradeManager::GetPositionVolume(string symbol, long magic = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic || magic == 0)
   {
    return(pos.getVolume());
   }
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
  for (i = total - 1; i >= 0; i--) // ���������� ��� ������ ��� ������� 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (ClosePosition(i)) 
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ������� �������", MakeFunctionPrefix(__FUNCTION__)));
       return (true);
      }
     else
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������ ������� �������", MakeFunctionPrefix(__FUNCTION__)));      
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
bool CTradeManager::ClosePendingPosition(string symbol, long magic = 0, color Color=CLR_NONE)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // ���������� ��� ������ ��� ������� 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (pos.getMagic() == magic || magic == 0)
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
 CPosition *pos = _openPositions.AtTicket(ticket);
 return ClosePosition(pos);
}

//+------------------------------------------------------------------+
/// Close a virtual position by index.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i, color Color = CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 return ClosePosition(pos);
}

//+------------------------------------------------------------------+
/// Close a virtual position by handle.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(CPosition *pos,color Color=CLR_NONE)
{
 int i = _openPositions.TicketToIndex(pos.getTMTicket());
 if (pos.ClosePosition())
 {
  PrintFormat("%s ������� ������� %d",MakeFunctionPrefix(__FUNCTION__),i);
  _positionsHistory.Add(_openPositions.Detach(i)); //��������� ������� � ������� � ������� �� ������� �������� �������
  _historyChanged = true;                          // ������ ����, ��� ������� ����������� 
  SaveArrayToFile(historyDataFileName,_positionsHistory); 
  SaveArrayToFile(rescueDataFileName,_openPositions);   
  log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__),i ) );     
  return(true);
 }
 else
 {
  error = GetLastError();
  _positionsToReProcessing.Add(_openPositions.Detach(i));
  log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� ������� ������� [%d]. ������� ���������� � ������ positionsToReProcessing.Error{%d} = %s"
                                        , MakeFunctionPrefix(__FUNCTION__), i, error, ErrorDescription(error)));
 }
 return(false);
}


//+------------------------------------------------------------------+
/// Close the selected virtual position.
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseSelectedPosition(color Color=CLR_NONE)
{
 bool res = false;
 if (ValidSelectedPosition())
  if (ClosePosition(_SelectedPosition)) res = true;
 return (res);
}

//+------------------------------------------------------------------+
/// Trailing with all virtual positions.
/// \param [in] handleExtr 	
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing(int handleExtr = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
//--- �� ������� �������� �������
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // ������� ������� �� �� �������
  if (pos.getPositionInfo().type == OP_BUY || pos.getPositionInfo().type == OP_SELL)
  {
   if(handleExtr != 0) pos.setTrailingHandle(handleExtr);
   pos.DoTrailing();
  }
 }
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
/// Create magic number
/// \param [string] str       symbol
/// \return							generated magic number
//+------------------------------------------------------------------+
long CTradeManager::MakeMagic(string strSymbol = "", ENUM_TIMEFRAMES period = PERIOD_CURRENT)
{
 if(strSymbol == "") strSymbol = Symbol();
 string s = strSymbol + PeriodToString(period) + MQL5InfoString(MQL5_PROGRAM_NAME);
 ulong ulHash = 5381;
 for(int i = StringLen(s) - 1; i >= 0; i--)
 {
  ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(s,i);
 }
 return MathAbs((long)ulHash);
}

//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(string symbol, long magic = 0, double sl = 0, double tp = 0)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if(pos.getSymbol() == symbol)
  {
   if (pos.getMagic() == magic|| magic == 0)
   {
    if(sl > 0)
     pos.ModifySL(sl);
    if(tp > 0)
     pos.ModifyTP(tp);
   }
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
//--- ������� ���������� ������������� �������
 int total = _positionsToReProcessing.Total();
 for(int i = total - 1; i>=0; i--) // �� ������� ������� �� ���������
 {
  CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� [%d].������� � �� positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
    _positionsHistory.Add(_positionsToReProcessing.Detach(i)); //��������� ��������� ������� � ������
    _historyChanged = true; // ������ ����, ��� ������� �����������
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
   log_file.Write(LOG_CRITICAL, StringFormat("%s ������� StopLoss � TakeProfit", MakeFunctionPrefix(__FUNCTION__)));    
   CloseReProcessingPosition(i);
   break;
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
   {
    log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ���������� StopLoss � TakeProfit � ������� [%d].���������� � �� positionsToReProcessing � openPositions.", MakeFunctionPrefix(__FUNCTION__), i));    
    pos.setPositionStatus(POSITION_STATUS_OPEN);
    
    _openPositions.Add(_positionsToReProcessing.Detach(i));    
    SaveArrayToFile(rescueDataFileName,_openPositions);    
   }
  }
 } 

//--- ���������� �������
 if(!HistorySelect(_historyStart, TimeCurrent()))
 {
  //log_file.Write(LOG_CRITICAL, StringFormat("%s �� ���������� ������� ������� � %s �� %s", MakeFunctionPrefix(__FUNCTION__), _historyStart, TimeCurrent())); 
  return;
 }

//--- ���� ������� ������������, �������� � �������� ���������  
 total = _openPositions.Total();
 CPosition *pos;
//--- �� ������� ����� �������
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // ������� ������� �� �� �������
  ENUM_TM_POSITION_TYPE type = pos.getType();
  
  if (!OrderSelect(pos.getStopLossTicket()) && pos.getPositionStatus() != POSITION_STATUS_PENDING && pos.getStopLossStatus() != STOPLEVEL_STATUS_NOT_DEFINED) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s ����-���� ����� = %d, ������ ������� = %s, ������ ����-����� = %s"
                , MakeFunctionPrefix(__FUNCTION__)
                    , pos.getStopLossTicket()
                                         , PositionStatusToStr(pos.getPositionStatus())
                                                              , StoplevelStatusToStr(pos.getStopLossStatus()))  );
   log_file.Write(LOG_CRITICAL, StringFormat("%s ��� ������-StopLoss, ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   pos.setPositionStatus(POSITION_STATUS_CLOSED);
   ClosePosition(i);
   break;                          
  }
  
  if (pos.CheckTakeProfit())    //��������� ������� ���������� TP
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s ���� ����� �� ������ TP, ��������� ������� type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice()) );
   ClosePosition(i);
   break;             
  }
     
  if (pos.getPositionStatus() == POSITION_STATUS_PENDING) // ���� ��� ������� ���������� �������...
  {
   if (!OrderSelect(pos.getOrderTicket())) // ���� �� �� ����� ������� �� �� ������
   {
    ulong ticket = pos.getOrderTicket();
    if(!FindHistoryTicket(ticket))            // ��������� ����� ���� ����� � �������
    {
     log_file.Write(LOG_CRITICAL, StringFormat("%s � ������� ������� �� ������ ����� � ������� %d", MakeFunctionPrefix(__FUNCTION__), ticket));
     return;
    }
    
    long state;
    if (HistoryOrderGetInteger(ticket, ORDER_STATE, state)) // ������� ������ ������ �� �������
    {
     switch ((int)state)
     {
      case ORDER_STATE_FILLED:
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ��������� ������� ���������� ���������� �������.�������� ���������� StopLoss � TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP) pos.setType(OP_BUY);
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP) pos.setType(OP_SELL);
       
       if (pos.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || pos.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // ��������� ���������� �������� � ����������
       {
        log_file.Write(LOG_CRITICAL, StringFormat("%s �� ���������� ���������� StopLoss �/��� TakeProfit. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
        pos.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // ���� �� ����������, ��������, ����� ��������� �������
        _positionsToReProcessing.Add(_openPositions.Detach(i)); 
        break;
       }
       
       log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ���������� StopLoss �/��� TakeProfit. �������� ������� [%d] � openPositions.", MakeFunctionPrefix(__FUNCTION__)));
       pos.setPositionStatus(POSITION_STATUS_OPEN); // ������� ���������, ���� � ���� �����������
       log_file.Write(LOG_CRITICAL, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
       
       SaveArrayToFile(rescueDataFileName,_openPositions);       
       break;
      }
      case ORDER_STATE_CANCELED:
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ����� ������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = true; // ������ ����, ��� ������� �����������  
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
       break;
      }
      case ORDER_STATE_EXPIRED:
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ������ ����� �������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = true; // ������ ����, ��� ������� �����������
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
       break;
      }
      
      default:
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ������ ������ ������� ��� ����������� � �������: %s; ����� ������: %d", MakeFunctionPrefix(__FUNCTION__), EnumToString((ENUM_ORDER_STATE)state), ticket));
       break;
      }
     }
    }
    else
    {
     log_file.Write(LOG_CRITICAL, StringFormat("%s �� ���������� ������� ����� �� ������ %d �� �������", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
     log_file.Write(LOG_CRITICAL, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(GetLastError())));
     string str;
     int historyTotal = HistoryOrdersTotal();
     for(int j = historyTotal - 1; j >= 0; j--)
     {
      str += IntegerToString(HistoryOrderGetTicket(j)) + " ";
     }
     log_file.Write(LOG_CRITICAL, StringFormat("%s ������ ������� �� �������: %s", MakeFunctionPrefix(__FUNCTION__), str));
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
 // ���������� ���� ��������� ������� 
 if (_historyChanged)
  {
   _historyChanged = false;
  }
}

//+------------------------------------------------------------------+
//| ��������� ������������ �������                                   |
//| ���� ���������� ����� �� ������� - �������� �� �����             |
//| ���� ���������� ��������������� ������� - ��� ����� �������      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenUniquePosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, int maxSpread = 0)
{
 if (maxSpread > 0 && SymbolInfoInteger(symbol, SYMBOL_SPREAD) > maxSpread)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� ��� ��� ����� �������� ������������ ��������", MakeFunctionPrefix(__FUNCTION__)));
  return false;  
 }
 if (_positionsToReProcessing.OrderCount(symbol, pos_info.magic) > 0) 
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� ��� ��� ��� ���� ������� � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }

 bool result = true;
 log_file.Write(LOG_CRITICAL, StringFormat("%s ��������� ������� %s. �������� ������� �� ������ ������: %d", MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos_info.type), _openPositions.Total()));
 log_file.Write(LOG_CRITICAL, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // ���������� ���� ������� �� ������� _openPositions
 
 CheckOpenedPositions(symbol, pos_info.type);
 
 int total = _openPositions.OrderCount(symbol, pos_info.magic) + _positionsToReProcessing.OrderCount(symbol, pos_info.magic);
 if (total <= 0)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__)));
  
  if(pos_info.volume < 0)
  {
   pos_info.volume = CalcVolume(symbol);  // �������� - ���� ��������
  }
  
  this.OpenPosition(symbol, timeframe, pos_info, trailing);
 }
 return(result); // ���� �������� �������� �������, ������ �� ���� ����������� 
}


//+------------------------------------------------------------------+
//| ��������� ������������ �������                                   |
//| ���� ���������� ����� �� ������� - �������� �� �����             |
//| ���� ���������� ��������������� ������� - ��� ����� �������      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenPairPosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, double volume_percent, int maxSpread = 0)
{
 if (maxSpread > 0 && SymbolInfoInteger(symbol, SYMBOL_SPREAD) > maxSpread)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� ��� ��� ����� �������� ������������ ��������", MakeFunctionPrefix(__FUNCTION__)));
  return false;  
 }
 if (_positionsToReProcessing.OrderCount(symbol, pos_info.magic) > 0) 
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� ��� ��� ��� ���� ������� � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }
 
 bool result = true;
 SPositionInfo pos_info_tp, pos_info_give;
 log_file.Write(LOG_CRITICAL, StringFormat("%s ��������� ������� %s. �������� ������� �� ������ ������: %d", MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos_info.type), _openPositions.Total()));
 log_file.Write(LOG_CRITICAL, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // ���������� ���� ������� �� ������� _openPositions

 CheckOpenedPositions(symbol, pos_info.type);  
 
 int total = _openPositions.OrderCount(symbol, pos_info.magic) + _positionsToReProcessing.OrderCount(symbol, pos_info.magic);
 if (total <= 0)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__)));
  
  if(pos_info.volume < 0)
  {
   pos_info.volume = CalcVolume(symbol); // �������� - ���� ��������
  }
  
  pos_info_tp = pos_info;
  pos_info_give = pos_info;
  pos_info_tp.tp = pos_info.tp;
  pos_info_tp.volume = volume_percent * pos_info.volume;
  pos_info_give.tp = 0;
  pos_info_give.volume = pos_info.volume - pos_info_tp.volume;
  
  result = OpenPosition(symbol, timeframe, pos_info_tp, trailing) && 
           OpenPosition(symbol, timeframe, pos_info_give, trailing);
 }
 return(result); // ���� �������� �������� �������, ������ �� ���� ����������� 
}

//+------------------------------------------------------------------+
//| ��������� �������                                                |
//+------------------------------------------------------------------+
bool CTradeManager::OpenMultiPosition(string symbol, ENUM_TIMEFRAMES timeframe, SPositionInfo& pos_info, STrailing& trailing, int maxSpread = 0)
{
 if (maxSpread > 0 && SymbolInfoInteger(symbol, SYMBOL_SPREAD) > maxSpread)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���������� ������� ������� ��� ��� ����� �������� ������������ ��������", MakeFunctionPrefix(__FUNCTION__)));
  return false;  
 }
 log_file.Write(LOG_CRITICAL, StringFormat("%s, ��������� ������-������� %s. �������� ������� �� ������ ������: %d", MakeFunctionPrefix(__FUNCTION__), GetNameOP(pos_info.type), _openPositions.Total()) ); 
 
 //this.CheckOpenedPositions(symbol, pos_info.type);
 if(pos_info.volume < 0)
 {
  pos_info.volume = CalcVolume(symbol); // �������� - ���� ��������
 }

 bool result = OpenPosition(symbol, timeframe, pos_info, trailing);
 return(result); 
}

//+------------------------------------------------------------------+ 
// ������� ��������� ������ ��������� �������
//+------------------------------------------------------------------+
bool CTradeManager::PositionChangeSize(double additionalVolume)
{
 if (_SelectedPosition.getVolume() + additionalVolume != 0)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ����� ������� �������", MakeFunctionPrefix(__FUNCTION__)) );
  if (_SelectedPosition.ChangeSize(additionalVolume))
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s ����� ������� ������� �������", MakeFunctionPrefix(__FUNCTION__)) );
   return (true);
  }
  else
  {
   if (_SelectedPosition.getPositionStatus() == POSITION_STATUS_NOT_CHANGED)
   {
    log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� �������� ����-���� ��� ��������� ������ �������", MakeFunctionPrefix(__FUNCTION__)) );
    _positionsToReProcessing.Add(_openPositions.Detach(_openPositions.TicketToIndex(_SelectedPosition.getTMTicket())));
   }
  }
 }
 else
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ��������� �������. �������� ����� ����� 0, ��������� �������", MakeFunctionPrefix(__FUNCTION__)) );
  if (ClosePosition(_SelectedPosition)) return (true);
 }
 return (false);
}

//+------------------------------------------------------------------+ 
// ������� ��������� ������ �������
//+------------------------------------------------------------------+
bool CTradeManager::PositionChangeSize(string symbol, double additionalVolume, long magic = 0)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // ���������� ��� ������ ��� ������� 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (pos.getMagic() == magic || magic == 0)
    {
     if (pos.getVolume() + additionalVolume != 0)
     {
      log_file.Write(LOG_CRITICAL, StringFormat("%s ������� ����� ������� �������", MakeFunctionPrefix(__FUNCTION__)) );
      if (pos.ChangeSize(additionalVolume))
      {
       log_file.Write(LOG_CRITICAL, StringFormat("%s ����� ������� ������� �������", MakeFunctionPrefix(__FUNCTION__)) );
       return (true);
      }
      else
      {
       if (pos.getPositionStatus() == POSITION_STATUS_NOT_CHANGED)
       {
        log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� �������� ����-���� ��� ��������� ������ �������", MakeFunctionPrefix(__FUNCTION__)) );
        _positionsToReProcessing.Add(_openPositions.Detach(i));
       }
      }
     }
    }
    else
    {
     log_file.Write(LOG_CRITICAL, StringFormat("%s ��������� �������. �������� ����� ����� 0, ��������� �������", MakeFunctionPrefix(__FUNCTION__)) );
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
    case MODE_TRADES: _SelectedPosition = _openPositions.Position((int)index); return(true);
    case MODE_HISTORY: _SelectedPosition = _positionsHistory.Position((int)index); return(true);
    default:
     log_file.Write(LOG_CRITICAL, StringFormat("%s error: Unknown pool id %s", MakeFunctionPrefix(__FUNCTION__),(string)pool));
     return(false);
   }
   break;
  case SELECT_BY_TICKET:
   switch(pool)
   {
    case MODE_TRADES: _SelectedPosition = _openPositions.AtTicket(index); return(true);
    case MODE_HISTORY: _SelectedPosition = _positionsHistory.AtTicket(index); return(true);
    default:
     log_file.Write(LOG_CRITICAL, StringFormat("%s error: Unknown pool id %s", MakeFunctionPrefix(__FUNCTION__),(string)pool));
     return(false);
   }
   break;
  default:
     log_file.Write(LOG_CRITICAL, StringFormat("%s error: Unknown type %s", MakeFunctionPrefix(__FUNCTION__),(string)type));
   return(false);
 }
}

//+------------------------------------------------------------------+
//|  ��������� ������ � ������� ������� � ��������                   |
//+------------------------------------------------------------------+
void CTradeManager::UpdateData(CPositionArray *positionsHistory = NULL)
{
 if (positionsHistory == NULL) positionsHistory = _positionsHistory;
 int index;  // ������ ������� �� �����
 int length = positionsHistory.Total(); // ����� ����������� ������� �������
 CPosition *pos; // ��������� �� ������� �������
 // �������� �� ���� ������� � ��������� ������� �������
    
 for (index = 0; index < length; index++)
 {
  // ��������� ��������� �� ������� ������� �� �������
  pos = positionsHistory.At(index);
  // �������� ������� ������� 
  _current_balance = _current_balance + pos.getPosProfit();
  //���� ������ �������� ������� ������������ ������
  if (_current_balance > _max_balance)  
  {
   // �� �������������� ���
   _max_balance = _current_balance;
  }
  else 
  {
   //���� ���������� ������ ��������, ��� ����
   if ((_max_balance-_current_balance) > _current_drawdown) 
   {
    //�� ���������� ����� �������� �������
    _current_drawdown = _max_balance-_current_balance;  
   }
  }  
 }
}

//---------------PRIVATE-----------------------------

//+------------------------------------------------------------------+
/// Volume calculation.
/// \return							position volume
//+------------------------------------------------------------------+
double CTradeManager::CalcVolume(string symbol)
{
 double balance = AccountInfoDouble(ACCOUNT_BALANCE);
 double volume_risk = (balance * RISK) / (SymbolInfoDouble(symbol, SYMBOL_BID));
 return 0.0;
}

//+------------------------------------------------------------------+
/// Delete a virtual pos from "not_deleted".
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����������� ����-�����", MakeFunctionPrefix(__FUNCTION__)));
  _positionsHistory.Add(_positionsToReProcessing.Detach(i));
  _historyChanged = 1; // ������ ����, ��� ������� �����������  
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
//  �������� �� ����� ������� �������                 
//+----------------------------------------------------
bool CTradeManager::LoadArrayFromFile(string file_url,CPositionArray *array)
{
 if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
 {
  FileDelete(file_url);
  return(true);
 }
 
 int file_handle;   //�������� �����  
 if (!FileIsExist(file_url, FILE_COMMON) ) //�������� ������������� ����� ������� 
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ���� %s �� ����������", MakeFunctionPrefix(__FUNCTION__),file_url) );
  return (true);
 }  
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
 if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
 {
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), historyDataFileName);
  return (false);
 }
 
 array.Clear();                   //������� ������
 array.ReadFromFile(file_handle); //��������� ������ �� ����� 
 FileClose(file_handle);          //��������� ����  
 return (true);
} 

//+----------------------------------------------------
//  ���������� � ���� ������� �������                 |
//+----------------------------------------------------
bool CTradeManager::SaveArrayToFile(string file_url, CPositionArray *array)
{
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s �� ���������� ������� ����: %s", MakeFunctionPrefix(__FUNCTION__), file_url));
  return(false);
 }
 array.WriteToFile(file_handle);  //��������� ������ � ����
 FileClose(file_handle);
 return(true);
}

//+----------------------------------------------------
// ���� � ��������� ������� ���������������� ����
//+----------------------------------------------------
void CTradeManager::CheckOpenedPositions(string symbol, ENUM_TM_POSITION_TYPE type, long magic = 0)
{
 CPosition *pos;
 int i = 0;
 int total = _openPositions.Total();
 ENUM_TM_POSITION_TYPE usual = OP_UNKNOWN;
 ENUM_TM_POSITION_TYPE limit = OP_UNKNOWN;
 ENUM_TM_POSITION_TYPE stop  = OP_UNKNOWN;
 
 switch(type)
 {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
   usual = OP_SELL;
   limit = OP_SELLLIMIT;
   stop = OP_SELLSTOP;
   break;
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   usual = OP_BUY;
   limit = OP_BUYLIMIT;
   stop = OP_BUYSTOP;
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol && (pos.getMagic() == magic || magic == 0))
   {
    if (pos.getType() == usual)
    {
     ClosePosition(i);
     continue;
    }
    if (pos.getType() == limit || pos.getType() == stop)
    {
     ResetLastError();
     if (OrderSelect(pos.getOrderTicket()))
     {
      ClosePosition(i);
     }
     else
     {
      log_file.Write(LOG_CRITICAL ,StringFormat("%s, �������� ������� �� �������: �� ������ ����� � ������� %d. ������ %d - %s"
                    , MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()
                    , GetLastError(), ErrorDescription(GetLastError())));
     // ��������� ������� ������ � �������
      if (FindHistoryTicket(pos.getOrderTicket()))
      {
      // ��������� ������ ������� � �������
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = true; // ������ ����, ��� ������� �����������  
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
      }
     }
    }
   }
  }
 }
}

//+----------------------------------------------------
// ������� ������ �������, �������� ������ �� ��������, ��������� ������� � ������
//+----------------------------------------------------
bool CTradeManager::OpenPosition(string symbol,ENUM_TIMEFRAMES timeframe,SPositionInfo &pos_info, STrailing &trailing)
{
 bool result = true;
 ResetLastError();
 CPosition *pos = new CPosition(symbol, timeframe, pos_info, trailing);
 ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
 if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                         , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));
  _openPositions.Add(pos);  // ��������� �������� ������� � ������ �������� �������
  SaveArrayToFile(rescueDataFileName ,_openPositions);
  log_file.Write(LOG_CRITICAL, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
 }
 else
 {
  error = GetLastError();
  if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
  log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� ������� �������. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
  result = false; // ���� ������� ������� �� �������
 }
 return result; 
}

//+----------------------------------------------------
// Checks that the selected position pointer is valid
//+----------------------------------------------------
bool CTradeManager::ValidSelectedPosition()
{
 if(CheckPointer(_SelectedPosition)==POINTER_INVALID)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s Error: _SelectedPosition pointer is not valid", MakeFunctionPrefix(__FUNCTION__)));
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









