//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "ChartObjectsTradeLines.mqh"
#include "TradeManagerConfig.mqh"
#include <Trade\Trade.mqh> //подключаем библиотеку для совершения торговых операций
#include <CompareDoubles.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPosition : public CObject
  {
private:
   CSymbolInfo SymbInfo;
   CTrade *trade;
   CConfig config;
   ulong _magic;
   ulong _posTicket;
   double _posPrice;
   string _symbol;
   double _lots;
   ulong _slTicket;
   double _slPrice;
   ulong _tpTicket;
   double _tpPrice;
   int _sl, _tp;
   int _minProfit, _trailingStop, _trailingStep;
   ENUM_POSITION_TYPE _type;
   ENUM_POSITION_STATUS _status;
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;
   //CGlobalVirtualStopList m_GlobalVirtualStopList;
public:
  void CPosition(ulong magic, string symbol, ENUM_POSITION_TYPE type, double volume
                ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0)
             : _magic(magic), _symbol(symbol), _type(type), _lots(volume)
             , _sl(sl), _tp(tp), _minProfit(minProfit), _trailingStop(trailingStop), _trailingStep(trailingStep){};
             
   ulong getMagic() {return (_magic);};
   void setMagic(ulong magic) {_magic = magic;};
   ulong getPositionTicket() {return(_posTicket);};
   void setPositionTicket(ulong ticket) {_posTicket = ticket;};
   double getPositionPrice() {return(_posPrice);};
   string getSymbol() {return (_symbol);};
   void setSymbol(string symbol) {_symbol = symbol;};
   double getLots() {return (_lots);};
   void setLots(double lots) {_lots = lots;};
   ulong getStopLossTicket() {return (_slTicket);};
   void setStopLossTicket(ulong ticket) {_slTicket = ticket;};
   double getStopLossPrice() {return(_slPrice);};
   ulong getTakeProfitTicket() {return (_tpTicket);};
   void setTakeProfitTicket(ulong ticket) {_tpTicket = ticket;};
   double getTakeProfitPrice() {return(_tpPrice);};
   double getMinProfit() {return(_minProfit);};
   double getTrailingStop() {return(_trailingStop);};
   double getTrailingStep() {return(_trailingStep);};
   ENUM_POSITION_TYPE getType() {return (_type);};
   void setType(ENUM_POSITION_TYPE type) {_type = type;};
   
   bool UpdateSymbolInfo();        // Получение актуальной информации по торговому инструменту 
   double pricetype(int type);     // вычисляет уровень открытия в зависимости от типа 
   double SLtype(int type);        // вычисляет уровень стоп-лосса в зависимости от типа
   double TPtype(int type);        // вычисляет уровень тейк-профита в зависимости от типа
   void OpenPosition();
   void ClosePosition();
   void DoTrailing();
   bool ReadFromFile (int handle);
   void WriteToFile (int handle,bool bHeader/*=false*/);
 };
 
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+
bool CPosition::UpdateSymbolInfo()
  {
   SymbInfo.Name(_symbol);
   if(SymbInfo.Select() && SymbInfo.RefreshRates())
   {
    return(true);
   }
   return(false);
  }  
 
//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CPosition::pricetype(int type)
{
 UpdateSymbolInfo();
 if(type == 0)return(SymbInfo.Ask());
 if(type == 1)return(SymbInfo.Bid());
 return(-1);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double CPosition::SLtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Bid()-_sl*SymbInfo.Point());
 if(type==1)return(SymbInfo.Ask()+_sl*SymbInfo.Point());
 return(0);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double CPosition::TPtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Ask()+_tp*SymbInfo.Point());
 if(type==1)return(SymbInfo.Bid()-_tp*SymbInfo.Point());
 return(0);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CPosition::OpenPosition()
{
  Print("=> ",__FUNCTION__," at ",TimeToString(TimeCurrent(),TIME_SECONDS));
 trade = new CTrade();
 if (_type == POSITION_TYPE_BUY)
 {
  trade.Buy(_lots, _symbol, pricetype((int)_type));
  _posTicket = trade.ResultDeal();
  _posPrice = pricetype((int)_type);
  trade.SellLimit(_lots, TPtype((int)_type), _symbol);
  _tpTicket = trade.ResultOrder();
  _tpPrice = TPtype((int)_type);
  trade.SellStop(_lots, SLtype((int)_type), _symbol);
  _slTicket = trade.ResultOrder();
  _slPrice = SLtype((int)_type);
 }
 else if(_type == POSITION_TYPE_SELL)
      {
       trade.Sell(_lots, _symbol, pricetype((int)_type));
       _posTicket = trade.ResultDeal();
       _posPrice = pricetype((int)_type);
       trade.BuyLimit(_lots, TPtype((int)_type), _symbol);
       _tpTicket = trade.ResultOrder();
       _tpPrice = TPtype((int)_type);
       trade.BuyStop(_lots, SLtype((int)_type), _symbol);
       _slTicket = trade.ResultOrder();
       _slPrice = SLtype((int)_type);
      }
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CPosition::ClosePosition()
{
 trade.PositionClose(_symbol, config.Deviation);
 trade.OrderDelete(_slTicket);
 trade.OrderDelete(_tpTicket);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CPosition::DoTrailing(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 int digits = SymbInfo.Digits();
 double newSL = 0;
 
 if (getType() == POSITION_TYPE_BUY)
 {
  if (LessDoubles(_posPrice, bid - _minProfit*point))
  {
   if (LessDoubles(_slPrice, bid - (_trailingStop+_trailingStep-1)*point) || _slPrice == 0)
   {
    newSL = NormalizeDouble(bid - _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
    } 
   }
  }
 }
 
 if (getType() == POSITION_TYPE_SELL)
 {
  if (GreatDoubles(_posPrice - ask, _minProfit*point))
  {
   if (GreatDoubles(_slPrice, ask+(_trailingStop+_trailingStep-1)*point) || _slPrice == 0) 
   {
    newSL = NormalizeDouble(ask + _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
    }
   }
  }
 }
}

//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CPosition::ReadFromFile(int handle)
{
 if(handle<=0)
 {
  //LogFile.Log(LOG_PRINT,__FUNCTION__," error: file handle is not valid, returning false");
  return(false);
 }
 _status=StringToPositionStatus(FileReadString(handle));
 if(FileIsEnding(handle)) return(false);
 _symbol=FileReadString(handle);
 _type=StringToPositionType(FileReadString(handle));
 _lots=FileReadNumber(handle);
 /*
 m_dblOpenPrice=FileReadNumber(handle);
 m_dtOpenTime=StringToTime(FileReadString(handle));
 m_dblStopLoss=FileReadNumber(handle);
 m_dblTakeProfit=FileReadNumber(handle);
 m_nTimeStopBars=(int)FileReadNumber(handle);
 m_strComment=FileReadString(handle);
 m_lMagic=StringToInteger(FileReadString(handle));
 m_dblClosePrice=FileReadNumber(handle);
 m_dtCloseTime=StringToTime(FileReadString(handle));
 m_dtExpiration=StringToTime(FileReadString(handle));
 */
 _posTicket=StringToInteger(FileReadString(handle));
/*
 if(!SelfCheck())
 {
  LogFile.Log(LOG_PRINT,__FUNCTION__," error - virtual order read from file is not valid, returning false");
  return(false);
 }
*/
 return(true);
}

//+------------------------------------------------------------------+
/// Writes order as a line to an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle	handle of the CSV file
/// \param [in] bHeader 
//+------------------------------------------------------------------+
void CPosition::WriteToFile(int handle,bool bHeader/*=false*/)
  {/*
   if(bHeader)
      FileWrite(handle,
                "Status",
                "Symbol",
                "Type",
                "Lots",
                "OpenPrice",
                "OpenTime",
                "StopLoss",
                "TakeProfit",
                "TimeStopBars"
                "Comment",
                "MagicNumber",
                "ClosePrice",
                "CloseTime",
                "Expiration",
                "Ticket"
                );
   else
     {
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__," ",TableRow());
      FileWrite(handle,
                ::PositionStatusToStr(Status()),
                Symbol(),
                ::PositionTypeToStr(OrderType()),
                _lots(),
                OpenPrice(),
                TimeToString(OpenTime(),TIME_DATE|TIME_SECONDS),
                StopLoss(),
                TakeProfit(),
                TimeStopBars(),
                Comment(),
                MagicNumber(),
                ClosePrice(),
                TimeToString(CloseTime(),TIME_DATE|TIME_SECONDS),
                TimeToString(Expiration(),TIME_DATE|TIME_SECONDS),
                Ticket()
                );
     }*/
  }