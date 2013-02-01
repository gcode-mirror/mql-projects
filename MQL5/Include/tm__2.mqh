//+------------------------------------------------------------------+
//|                                                           TM.mqh |
//|                                       Copyright 2010, KTS Group. |
//|                                               http://www.koss.su |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, KTS Group."
#property link      "http://www.koss.su"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

#define  UNKNOW    0

//---Execution mode consts
#define  REQUEST   1
#define  INSTANT   2
#define  MARKET    3

//---Trade mode consts
#define  TRADE_DISABLED  1
#define  TRADE_FULL      2
#define  TRADE_LONGONLY  3
#define  TRADE_SHORTONLY 4
#define  TRADE_CLOSEONLY 5
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTradingManager
  {
protected:
   CPositionInfo     PosInfo;
   CSymbolInfo       SymbInfo;
   string            Name;
   int               digits;
   int               Spread;
   double            point;
   int               StopLevel;
   int               FreezeLevel;
   double            Bid;
   double            Ask;
protected:
   ushort            CorrectStops(ushort Step);
   uchar             Execution();
   uchar             TradeMode();
   bool              UpdateSymbolInfo(string Symb);
   double            GetIndicatorValue(int handle);
   double            PartLot(string Symb,double CurrentLot,uchar VolumePercent,uint &IterationCount,double &rests);
   bool              PositionIsFrozen(ENUM_POSITION_TYPE OPEN_POSITION,double SL,double TP);
   bool              StopsIsInvalid(ENUM_POSITION_TYPE OPEN_POSITION,double SL=0,double TP=0);
   bool              StopsIsInvalid(ENUM_ORDER_TYPE OPEN_ORDER,double OpenPrice=0,double SL=0,double TP=0,double StopPrice=0);
   bool              SendRequest(bool &ContinueRequest);
   bool              CheckCoincidence(ENUM_ORDER_TYPE OrderType,ENUM_POSITION_TYPE PositionType);
protected:
   MqlTradeRequest   Trade_request;
   MqlTradeResult    Trade_result;
   MqlTradeCheckResult Check_result;
   ulong             m_deviation;
   ulong             m_magic;
private:
   struct PositionInfo
     {
      ENUM_POSITION_TYPE Type;
      double            OpenPrice;
      double            StopLossPrice;
      double            TakeProfitPrice;
      double            Volume;
      double            Profit;
     };
public:
   void              SimpleTrailing(string Symb,int BuyStep,int SellStep,int Deviation=0,ulong Magic=0);
   void              TATrailing(int handle,string Symb,ENUM_TIMEFRAMES SFrame=PERIOD_CURRENT,ulong Magic=0);
   bool              ModifyPosition(string Symb,double SL=0,double TP=0,ulong Magic=0);
   bool              OpenPosition(string Symb,ENUM_ORDER_TYPE Type,double Lot,double SL=0,double TP=0,string Comm="");
   void              SetTraderInfo(ulong mn,ulong Slippage=1);
   bool              CheckOpenPositions(string Symb,ulong Magic=0);
   bool              ClosePosition(string Symb,uchar VolumePercent,ulong deviation=ULONG_MAX);
   PositionInfo      CurrentPosition;
   bool              OpenOrder(string Symb,ENUM_ORDER_TYPE Type,ENUM_ORDER_TYPE_TIME TTime,datetime Expiration,
                               double Lot,double OpenPrice,double SL=0,double TP=0,double StopPrice=0,string Comm="");
  };
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+

bool CTradingManager::UpdateSymbolInfo(string Symb)
  {
   SymbInfo.Name(Symb);
   if(SymbInfo.Select() && SymbInfo.RefreshRates())
     {
      Name       =SymbInfo.Name();
      digits     =SymbInfo.Digits();
      point      =SymbInfo.Point();
      StopLevel  =SymbInfo.StopsLevel();
      FreezeLevel=SymbInfo.FreezeLevel();
      Bid        =SymbInfo.Bid();
      Ask        =SymbInfo.Ask();
      Spread     =SymbInfo.Spread();
      return(true);
     }
   return(NULL);
  }
//+------------------------------------------------------------------+
//|Режим заключения сделок                                           |
//+------------------------------------------------------------------+

uchar CTradingManager::Execution()
  {
   switch(SymbInfo.TradeExecution())
     {
      case SYMBOL_TRADE_EXECUTION_REQUEST: return(REQUEST);
      case SYMBOL_TRADE_EXECUTION_INSTANT: return(INSTANT);
      case SYMBOL_TRADE_EXECUTION_MARKET:  return(MARKET);
      default: return(UNKNOW);
     }
  }
//+------------------------------------------------------------------+
//|Режим торговли                                                    |
//+------------------------------------------------------------------+

uchar CTradingManager::TradeMode()
  {
   switch(SymbInfo.TradeMode())
     {
      case SYMBOL_TRADE_MODE_DISABLED:     return(TRADE_DISABLED);
      case SYMBOL_TRADE_MODE_LONGONLY:     return(TRADE_LONGONLY);
      case SYMBOL_TRADE_MODE_SHORTONLY:    return(TRADE_SHORTONLY);
      case SYMBOL_TRADE_MODE_CLOSEONLY:    return(TRADE_CLOSEONLY);
      case SYMBOL_TRADE_MODE_FULL:         return(TRADE_FULL);
      default:                             return(UNKNOW);
     }
  }
//+------------------------------------------------------------------+
//|Проверка и корректировка дистанции                                |
//+------------------------------------------------------------------+
ushort CTradingManager::CorrectStops(ushort Step)
  {
   ushort new_step=ushort(StopLevel);
   ushort res=(Step<new_step)?new_step:Step;
   return(res);
  }
//+------------------------------------------------------------------+
//|Проверка минимальной дистанции StopsLevel при модификации StopLoss|
//|и/или TakeProfit ордеров у открытых позиций                       |
//| Параметры:                                                       |
//|  -тип позиции                                                    |
//|  -новая цена ордера StopLoss                                     |
//|  -новая цена ордера TakeProfit                                   |
//+------------------------------------------------------------------+  

bool  CTradingManager::StopsIsInvalid(ENUM_POSITION_TYPE OPEN_POSITION,double SL=0,double TP=0)
  {
   bool IsInvalid=NULL;
   switch(OPEN_POSITION)
     {
      case POSITION_TYPE_BUY:
         IsInvalid=((SL!=0 && NormalizeDouble(Bid-SL,digits)/point<StopLevel) || (TP!=0 && NormalizeDouble(TP-Bid,digits)/point<StopLevel));
         break;

      case POSITION_TYPE_SELL:
         IsInvalid=((SL!=0 && NormalizeDouble(SL-Ask,digits)/point<StopLevel) || (TP!=0 && NormalizeDouble(Ask-TP,digits)/point<StopLevel));
         break;
     }
   return(IsInvalid);
  }
//+------------------------------------------------------------------+
//|Проверка минимальной дистанции StopsLevel при открытии Sell/Buy   |
//|и установке различных отложеных ордеров                           |
//|Параметры:                                                        |
//|  - тип ордера                                                    |
//|  - цена открытия                                                 |
//|  - цена StopLoss ордера                                          |
//|  - цена TakeProfit ордера                                        |
//|  - цена при достижении которой,будут выставлены отложеные ордера |
//|    StopLimit или BuyLimit по указанной цене OpenPrice(StopLimit) |
//+------------------------------------------------------------------+  

bool  CTradingManager::StopsIsInvalid(ENUM_ORDER_TYPE OPEN_ORDER,double OpenPrice=0,double SL=0,double TP=0,double StopPrice=0)
  {
   bool IsInvalid=NULL;
   switch(OPEN_ORDER)
     {
      case ORDER_TYPE_BUY:
        {
         IsInvalid=((SL!=0 && SL < StopLevel) || 
                    (TP!=0 && TP < StopLevel));
         if (IsInvalid)
         {
          Print("Invalid stops SL =", SL, " TP=", TP, " StopLevel=", StopLevel);
         }
        }
      break;

      case ORDER_TYPE_BUY_LIMIT:
        {
         IsInvalid=(NormalizeDouble(Ask-OpenPrice,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(OpenPrice-SL,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(TP-OpenPrice,digits)/point<StopLevel));
        }
      break;

      case ORDER_TYPE_BUY_STOP:
        {
         IsInvalid=(NormalizeDouble(OpenPrice-Ask,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(OpenPrice-SL,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(TP-OpenPrice,digits)/point<StopLevel));
        }
      break;

      case ORDER_TYPE_BUY_STOP_LIMIT:
        {
         IsInvalid=(NormalizeDouble(StopPrice-Ask,digits)/point<StopLevel || 
                    NormalizeDouble(StopPrice-OpenPrice,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(OpenPrice-SL,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(TP-OpenPrice,digits)/point<StopLevel));
        }
      break;

      case ORDER_TYPE_SELL:
        {
         IsInvalid=((SL!=0 && SL < StopLevel) || 
                    (TP!=0 && TP < StopLevel));
         if (IsInvalid)
         {
          Print("Invalid stops SL =", SL, " TP=", TP, " StopLevel=", StopLevel);
         }        }
      break;

      case ORDER_TYPE_SELL_LIMIT:
        {
         IsInvalid=(NormalizeDouble(OpenPrice-Bid,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(SL-OpenPrice,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(OpenPrice-TP,digits)/point<StopLevel));
        }
      break;

      case ORDER_TYPE_SELL_STOP:
        {
         IsInvalid=(NormalizeDouble(Bid-OpenPrice,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(SL-OpenPrice,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(OpenPrice-TP,digits)/point<StopLevel));
        }
      break;

      case ORDER_TYPE_SELL_STOP_LIMIT:
        {
         IsInvalid=(NormalizeDouble(Bid-StopPrice,digits)/point<StopLevel || 
                    NormalizeDouble(OpenPrice-StopPrice,digits)/point<StopLevel || 
                    (SL!=0 && NormalizeDouble(SL-OpenPrice,digits)/point<StopLevel) ||
                    (TP!=0 && NormalizeDouble(OpenPrice-TP,digits)/point<StopLevel));
        }
      break;
     }
   return(IsInvalid);
  }
//+------------------------------------------------------------------+
//|Проверка дистанции заморозки открытых позиций                     |
//+------------------------------------------------------------------+

bool CTradingManager::PositionIsFrozen(ENUM_POSITION_TYPE OPEN_POSITION,double SL,double TP)
  {
   bool Frozen=NULL;
   switch(OPEN_POSITION)
     {
      case POSITION_TYPE_BUY:
         Frozen=((TP!=0 && NormalizeDouble(TP-Bid,digits)/point<FreezeLevel) || 
                 (SL!=0 && NormalizeDouble(Bid-SL,digits)/point<FreezeLevel));
      break;

      case POSITION_TYPE_SELL:
         Frozen=((TP!=0 && NormalizeDouble(Ask-TP,digits)/point<FreezeLevel) || 
                 (SL!=0 && NormalizeDouble(SL-Ask,digits)/point<FreezeLevel));
      break;
     }

   return(Frozen);
  }
//+------------------------------------------------------------------+
//|Обыкновенный трейлинг-стоп                                        |
//+------------------------------------------------------------------+

void CTradingManager::SimpleTrailing(string Symb,int BuyStep,int SellStep,int Deviation=0,ulong Magic=0)
  {
   if(CheckOpenPositions(Symb,Magic))
     {
      static uint Timer=0;
      uint Now=GetTickCount();
      if(Now-Timer>10000)                // ограничение: не чаще, чем раз в 10сек.  
        {
         if(UpdateSymbolInfo(Symb))
           {
            bool   Modified=NULL;
            double sl=CurrentPosition.StopLossPrice;
            double tp=CurrentPosition.TakeProfitPrice;
            double op=CurrentPosition.OpenPrice;
            double new_sl=NULL;

            switch(CurrentPosition.Type)
              {
               case POSITION_TYPE_BUY:
                 {
                  if(NormalizeDouble(Bid - op - BuyStep*point, digits) > 0)
                    {
                     if(NormalizeDouble(sl - Bid + (BuyStep+Deviation)*point, digits) < 0)
                       {
                        Alert("Trailing started");
                        new_sl=NormalizeDouble(Bid-BuyStep*point,digits);
                        Modified=(!PositionIsFrozen(POSITION_TYPE_BUY,sl,tp));
                       }
                    }
                 }
               break;

               case POSITION_TYPE_SELL:
                 {
                  if(NormalizeDouble(op - Ask - SellStep*point, digits) > 0)
                    {
                     if(NormalizeDouble(sl - Ask+(SellStep+Deviation)*point, digits) > 0)
                       {
                        Alert("Trailing started");
                        new_sl=NormalizeDouble(Ask+SellStep*point,digits);
                        Modified=(!PositionIsFrozen(POSITION_TYPE_SELL,sl,tp));
                       }
                    }
                 }
               break;
              }

            if(Modified && ModifyPosition(Name,new_sl,tp,Magic))
              {
               Timer=GetTickCount();
               Print("StopLoss was modified-",DoubleToString(new_sl,digits));
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|Получение значения технического индикатора                        |
//+------------------------------------------------------------------+

double CTradingManager::GetIndicatorValue(int handle)
  {
   double buffer[];
   if(handle!=INVALID_HANDLE)
     {
      if(CopyBuffer(handle,0,1,1,buffer)<0) return(0);
      else return(buffer[0]);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|Индикаторный трейлинг-стоп (SAR,MA....)                           |
//| желательно использовать при появлении нового бара                |
//| Параметры:                                                       |
//|  handle - хэндл индикатора                                       |
//|  Symb   - инструмент                                             |
//|  SFrame - период(текущий по умолчанию)                           | 
//|  Magic  - магический номер(если используется)                    |
//+------------------------------------------------------------------+

void CTradingManager::TATrailing(int handle,string Symb,ENUM_TIMEFRAMES SFrame=PERIOD_CURRENT,ulong Magic=0)
  {
   if(CheckOpenPositions(Symb,Magic))
     {
      if(UpdateSymbolInfo(Symb))
        {
         double new_sl=NormalizeDouble(GetIndicatorValue(handle),digits);
         if(new_sl!=0)
           {
            double High[];
            double Low[];
            double tp=CurrentPosition.TakeProfitPrice;
            double sl=CurrentPosition.StopLossPrice;
            bool   Modified=NULL;

            switch(CurrentPosition.Type)
              {
               case POSITION_TYPE_BUY:
                  if(CopyLow(Name,SFrame,1,1,Low)>0)
                    {
                     if(new_sl<Low[0] && sl>0 && new_sl>sl)
                       {
                        Modified=(!StopsIsInvalid(POSITION_TYPE_BUY,new_sl) && !PositionIsFrozen(POSITION_TYPE_BUY,sl,tp));
                       }
                    }
                  break;

               case POSITION_TYPE_SELL:
                  if(CopyHigh(Name,SFrame,1,1,High)>0)
                    {
                     if(new_sl>High[0] && sl>0 && new_sl<sl)
                       {
                        Modified=(!StopsIsInvalid(POSITION_TYPE_SELL,new_sl) && !PositionIsFrozen(POSITION_TYPE_SELL,sl,tp));
                       }
                    }
                  break;
              }

            if(Modified && ModifyPosition(Name,new_sl,tp,Magic))
              {
               Print("StopLoss was modified-",DoubleToString(new_sl,digits));
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|Установкаа магика и величины проскальзывания                      |
//+------------------------------------------------------------------+

void  CTradingManager::SetTraderInfo(ulong mn,ulong Slippage=1)
  {
   m_deviation=Slippage*Spread;
   m_magic=mn;
  }
//+------------------------------------------------------------------+
//|Проверка наличия открытых позиций                                 |
//+------------------------------------------------------------------+
bool CTradingManager::CheckOpenPositions(string Symb,ulong Magic=0)
  {
   if(PosInfo.Select(Symb))
     {
      if(PosInfo.Magic()==Magic || Magic==0)
        {
         CurrentPosition.Type = PosInfo.PositionType();
         CurrentPosition.OpenPrice = PosInfo.PriceOpen();
         CurrentPosition.StopLossPrice = PosInfo.StopLoss();
         CurrentPosition.TakeProfitPrice = PosInfo.TakeProfit();
         CurrentPosition.Volume = PosInfo.Volume();
         CurrentPosition.Profit = PosInfo.Profit();
         return(true);
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|Модификация рыночных позиций                                      |
//+------------------------------------------------------------------+

bool CTradingManager::ModifyPosition(string Symb,double SL=0,double TP=0,ulong Magic=0)
  {
   bool Done=NULL;

   if(PosInfo.Select(Symb))
     {
      if(PosInfo.Magic()==Magic || Magic==0)
        {
         do
           {
            bool RequestDone=NULL;
            bool Continue=NULL;

            Trade_request.action    =TRADE_ACTION_SLTP;
            Trade_request.symbol    =Symb;
            Trade_request.sl        =SL;
            Trade_request.tp        =TP;
            Trade_request.deviation =m_deviation;

            RequestDone=SendRequest(Continue);
            if(RequestDone) Done=true;
            else
              {
               if(Continue) Done=NULL;
               else return(NULL);
              }
           }
         while(!Done);
        }
     }
   return(Done);
  }
//+------------------------------------------------------------------+
//|Проверка на совпадение направления                                |
//+------------------------------------------------------------------+

bool CTradingManager::CheckCoincidence(ENUM_ORDER_TYPE OrderType,ENUM_POSITION_TYPE PositionType)
  {
   bool coincide=NULL;
   coincide=((PositionType==POSITION_TYPE_SELL && (OrderType==ORDER_TYPE_SELL || OrderType==ORDER_TYPE_SELL_LIMIT || OrderType==ORDER_TYPE_SELL_STOP || OrderType==ORDER_TYPE_SELL_STOP_LIMIT)) || 
             (PositionType==POSITION_TYPE_BUY && (OrderType==ORDER_TYPE_BUY || OrderType==ORDER_TYPE_BUY_LIMIT || OrderType==ORDER_TYPE_BUY_STOP || OrderType==ORDER_TYPE_BUY_STOP_LIMIT)));
   return(coincide);
  }
//+------------------------------------------------------------------+
//|Открытие рыночной позиции                                         |
//+------------------------------------------------------------------+

bool CTradingManager::OpenPosition(string Symb,ENUM_ORDER_TYPE Type,double Lot,double SL=0,double TP=0,string Comm="")
  {
   bool   Done=NULL;
   double Volume=Lot;

   if(Type!=ORDER_TYPE_BUY && Type!=ORDER_TYPE_SELL) return(Done);

   if(UpdateSymbolInfo(Symb))
     {
      switch(TradeMode()) //-- режим торговли
        {
         case TRADE_DISABLED:
            Print(Name+": Trading symbol on the disabled!");
            return(Done);

         case TRADE_CLOSEONLY:
           {
            Print(Name+": Allowed only close positions!");
            if(CheckOpenPositions(Symb,m_magic)) // если есть открытая позиция
              {
               if(CheckCoincidence(Type,CurrentPosition.Type))  return(Done);               // если открываемая позиция совпадает с сушествующей, то ничего не открываем
               else                                                                         // иначе сравниваем объемы
                 {
                  Volume=(CurrentPosition.Volume<Volume) ? CurrentPosition.Volume : Volume;  // если объем текущей позиции меньше,то открываем позицию с таким же объемом
                 }
              }
            else return(Done);
           }
         break;

         case TRADE_LONGONLY:
           {
            if(Type!=ORDER_TYPE_BUY)
              {
               Print(Name+": Allowed only long positions!");
               return(Done);
              }
           }
         break;

         case TRADE_SHORTONLY:
           {
            if(Type!=ORDER_TYPE_SELL)
              {
               Print(Name+": Allowed only short positions!");
               return(Done);
              }
           }
         break;

         default: break;
        }

      bool   NeedModify=NULL;
      //--- checking stopslevel
      if(!StopsIsInvalid(Type, 0, SL, TP))
        {
         uchar  EM=Execution();  //--тип исполнения
         do
           {
            double OpenPrice = (Type==ORDER_TYPE_BUY) ? Ask : Bid;
            SL = (Type==ORDER_TYPE_BUY) ? SL : -SL;
            TP = (Type==ORDER_TYPE_BUY) ? TP : -TP;
            switch(EM)
              {
               case MARKET:
                 {
                  NeedModify=(SL!=0 || TP!=0);
                 }
               break;

               case REQUEST:
               case INSTANT:
                 {
                  Trade_request.price       =OpenPrice;
                  Trade_request.sl          =OpenPrice-SL*_Point;
                  Trade_request.tp          =OpenPrice+TP*_Point;
                  Trade_request.deviation   =m_deviation;
                 }
               break;

               case UNKNOW:  return(Done);
              }

            bool RequestDone=NULL;
            bool Continue=NULL;

            //--- setting request
            Trade_request.action       =TRADE_ACTION_DEAL;
            Trade_request.type         =Type;
            Trade_request.symbol       =Name;
            Trade_request.volume       =Volume;
            Trade_request.type_filling =ORDER_FILLING_FOK;
            Trade_request.magic        =m_magic;
            Trade_request.comment      =Comm;
            //---
            RequestDone=SendRequest(Continue);

            if(RequestDone) Done=true;
            else
              {
               if(Continue) Done=false;
               else return(false);
              }
           }
         while(!Done);
        }
      else Print("Invalid stops!");
      if(Done && NeedModify)
        {
         // возможно здесь нужен Sleep(10000)
         if(PosInfo.Select(Symb)) ModifyPosition(Symb,SL,TP,m_magic);
        }

     }
   return(Done);
  }
//+------------------------------------------------------------------+
//|Расчет объема лота необходимого для закрытия                      |
//+------------------------------------------------------------------+

double  CTradingManager::PartLot(string Symb,double Lot,uchar VolumePercent,uint &IterationCount,double &rests)
  {
   double LotMin=SymbolInfoDouble(Symb,SYMBOL_VOLUME_MIN);
   double LotMax=SymbolInfoDouble(Symb,SYMBOL_VOLUME_MAX);
   double LotStep=SymbolInfoDouble(Symb,SYMBOL_VOLUME_STEP);

   if(Lot==LotMin) return(Lot);

   double k=NULL;
   double NeedVolume=NULL;
   double part=NULL;
   uchar  Percent=VolumePercent;

   if(Percent==0 || Percent>100) Percent=100;      // полностью закрыть

   if(LotMin==0) LotMin=0.1;
   if(LotMax==0) LotMax=100;
   if(LotStep>0) k=1/LotStep; else k=1/LotMin;

   part=(Lot*Percent)/100;
   NeedVolume=MathFloor(part*k)/k;

   if(NeedVolume<LotMin || Lot-NeedVolume<LotMin) return(Lot);

   if(NeedVolume>LotMax)
     {
      rests=NeedVolume-LotMax;
      IterationCount=(int)MathCeil(NeedVolume/LotMax);
      Print("Position on "+Symb+" will be closed by parts.");
      return(LotMax);
     }
   return(NeedVolume);
  }
//+------------------------------------------------------------------+
//|Закрытие позиции                                                  |
//+------------------------------------------------------------------+

bool CTradingManager::ClosePosition(string Symb,uchar VolumePercent,ulong deviation=ULONG_MAX)
  {

   bool   Closed=NULL;
   uint   i=NULL;

   if(PosInfo.Select(Symb))
     {
      if(UpdateSymbolInfo(Symb))
        {
         if(!PositionIsFrozen(PosInfo.PositionType(),PosInfo.StopLoss(),PosInfo.TakeProfit()))
           {
            double VolumeForClose=NULL;
            double CurrentVolume=PosInfo.Volume();
            static double rests=NULL;                  // остаток объема, если объем при закрытия привышает SYMBOL_VOLUME_MAX
            uint   attempts=NULL;                      // счетчик удачных попыток закрытия
            bool   RequestDone=NULL;
            bool   Continue=NULL;
            do
              {
               VolumeForClose=(rests==0) ? PartLot(Symb,CurrentVolume,VolumePercent,i,rests) : PartLot(Symb,rests,100,i,rests);
               if(PosInfo.Type()==POSITION_TYPE_BUY)
                 {
                  Trade_request.type=ORDER_TYPE_SELL;
                  Trade_request.price=Bid;
                 }
               else
                 {
                  //--- prepare query for close SELL position
                  Trade_request.type =ORDER_TYPE_BUY;
                  Trade_request.price=Ask;
                 }
               //--- setting request
               Trade_request.action       =TRADE_ACTION_DEAL;
               Trade_request.symbol       =Name;
               Trade_request.volume       =VolumeForClose;
               Trade_request.sl           =0.0;
               Trade_request.tp           =0.0;
               Trade_request.deviation    =(deviation==ULONG_MAX) ? m_deviation : deviation;
               Trade_request.type_filling =ORDER_FILLING_FOK;
               //---
               RequestDone=SendRequest(Continue);
               if(RequestDone)
                 {
                  if(i>0)
                    {
                     i--;
                     attempts++;
                    }
                  Closed=true;
                 }
               else
                 {
                  if(Continue)
                    {
                     if(i>0)
                       {
                        if(attempts==0) rests=NULL;
                       }
                     else i++;
                    }
                  else break;
                 }
              }
            while(i>0);
           }
        }
     }
   return(Closed);
  }
//+------------------------------------------------------------------+
//|Установка отложенных ордеров                                      |
//+------------------------------------------------------------------+

bool CTradingManager::OpenOrder(string Symb,
                                ENUM_ORDER_TYPE Type,
                                ENUM_ORDER_TYPE_TIME TTime,
                                datetime Expiration,
                                double Lot,
                                double OpenPrice,//  цена установки ордеров,для ордеров типа ...STOP_LIMIT цена установки Limit ордеров,
                                double SL=0,
                                double TP=0,
                                double StopPrice=0,//  цена при достижении которой выствляются ...Limit ордера
                                string Comm="")
  {

   bool Done=NULL;

   if(Type==ORDER_TYPE_BUY && Type==ORDER_TYPE_SELL) return(Done);

   double Volume=Lot;

   if(UpdateSymbolInfo(Symb))
     {
      switch(TradeMode()) //-- режим торговли
        {
         case TRADE_DISABLED:
            Print(Name+": Trading symbol on the disabled!");
            return(Done);

         case TRADE_CLOSEONLY:
           {
            Print(Name+": Allowed only close positions!");
            if(CheckOpenPositions(Symb,m_magic)) // если есть открытая позиция
              {
               if(CheckCoincidence(Type,CurrentPosition.Type))  return(Done);               // если тип открываемого ордера совпадает с сушествующей позицией, то ничего не устанавливаем
               else                                                                         // иначе сравниваем объемы
                 {
                  Volume=(CurrentPosition.Volume<Volume) ? CurrentPosition.Volume : Volume;  // если объем текущей позиции меньше,то устанавливаем ордер с таким же объемом
                 }
              }
            else return(Done);
           }
         break;

         case TRADE_LONGONLY:
           {
            if(Type!=ORDER_TYPE_BUY)
              {
               Print(Name+": Allowed only long positions!");
               return(Done);
              }
           }
         break;

         case TRADE_SHORTONLY:
           {
            if(Type!=ORDER_TYPE_SELL)
              {
               Print(Name+": Allowed only short positions!");
               return(Done);
              }
           }
         break;

         default: break;
        }
      //--- checking stopslevel
      if(!StopsIsInvalid(Type,OpenPrice,SL,TP,StopPrice))
        {
         do
           {
            bool RequestDone=NULL;
            bool Continue=NULL;
            //--- setting request
            Trade_request.action       =TRADE_ACTION_PENDING;
            Trade_request.type         =Type;
            Trade_request.symbol       =Name;
            Trade_request.volume       =Volume;
            Trade_request.price        =OpenPrice;
            Trade_request.stoplimit    =StopPrice;
            Trade_request.sl           =SL;
            Trade_request.tp           =TP;
            Trade_request.type_filling =ORDER_FILLING_FOK;
            Trade_request.magic        =m_magic;
            Trade_request.type_time    =TTime;
            Trade_request.expiration   =Expiration;
            Trade_request.comment      =Comm;
            //---
            RequestDone=SendRequest(Continue);

            if(RequestDone) Done=true;
            else
              {
               if(Continue) Done=false;
               else return(false);
              }
           }
         while(!Done);
        }
      else Print("Invalid stops!");
     }
   return(Done);
  }
//+------------------------------------------------------------------+
//|Отправка запроса на торговый сервер                               |
//+------------------------------------------------------------------+

bool CTradingManager::SendRequest(bool &ContinueRequest)
  {
   uint   CheckRetCode=NULL;
   bool   Done        =NULL;
   
   //Print(OrderCheck(Trade_request,Check_result));
   if(OrderCheck(Trade_request,Check_result)) // проверим правильность заполнения структуры торгового запроса
     {
      OrderSend(Trade_request,Trade_result);
      switch(Trade_result.retcode)
        {
         //---удачное выполнение операции
         case TRADE_RETCODE_PLACED:
         case TRADE_RETCODE_DONE:
         case TRADE_RETCODE_DONE_PARTIAL:
           {
            Done=true;
           }
         break;

         //---цены изменились
         case TRADE_RETCODE_PRICE_CHANGED:
            //---реквота
            case TRADE_RETCODE_REQUOTE:
              {
               Bid=Trade_result.bid;
               Ask=Trade_result.ask;
               ContinueRequest=true;            // повторим запрос
              }
            break;

            //---нет котировок
         case TRADE_RETCODE_PRICE_OFF:
           {
            Print("No quotes for query processing!");
           }
         break;

         //--Рынок закрыт
         case TRADE_RETCODE_MARKET_CLOSED:
           {
            Print("Market closed!");
           }
         break;

        }
     }
   else
     {
      Print("Result - ", Check_result.retcode);
      switch(Check_result.retcode)
        {
         case TRADE_RETCODE_INVALID_STOPS:
         {
          Print("TRADE_RETCODE_INVALID_STOPS");
          Print("request.sl = ",Trade_request.sl," request.tp = ",Trade_request.tp);
         }
         break;
         case TRADE_RETCODE_INVALID_VOLUME:
         {
          Print("Invalid volume!");
         }
         break;
         case TRADE_RETCODE_INVALID_PRICE:
         {
          Print("Invalid price!");
         }
         break;
        }
     }
   return(Done);
  }
//+------------------------------------------------------------------+
