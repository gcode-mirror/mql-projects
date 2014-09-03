//+------------------------------------------------------------------+
//|                                                 TrailingStop.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <TradeManager\TradeManagerEnums.mqh>
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#include <BlowInfoFromExtremums.mqh>

#define DEPTH_PBI 100

//+------------------------------------------------------------------+
//| Класс для управления стоп-лоссом                                 |
//+------------------------------------------------------------------+
class CTrailingStop
  {
private:
   CSymbolInfo SymbInfo;
   bool UpdateSymbolInfo(string symbol);
   double _previewPriceAsk;
   double _previewPriceBid;
   double PBI_colors[], PBI_Extrems[];
   
public:
   CTrailingStop();
   ~CTrailingStop();
   
   double UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
                       
   double LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
   double PBITrailing(ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI);
   double ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl,double priceOpen, CBlowInfoFromExtremums *blowInfo=NULL);                    
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::CTrailingStop()
  {
   ArraySetAsSeries(PBI_colors, true);
   ArraySetAsSeries(PBI_Extrems, true);
   _previewPriceAsk = 0;
   _previewPriceBid = 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::~CTrailingStop()
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Обычный трейлинг
//+------------------------------------------------------------------+
double CTrailingStop::UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                                   , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double ask = SymbInfo.Ask();
  double bid = SymbInfo.Bid();
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (type == OP_BUY &&
      LessDoubles(openPrice, bid - minProfit*point) &&
      (LessDoubles(sl, bid - (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   //Print("UsualTrailing");   
   newSL = NormalizeDouble(bid - trailingStop*point, digits);
  }
 
  if (type == OP_SELL &&
      GreatDoubles(openPrice, ask + minProfit*point) &&
      (GreatDoubles(sl, ask + (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   //Print("UsualTrailing");
   newSL = NormalizeDouble(ask + trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// Трейлинг с выходом на безубыток
//+------------------------------------------------------------------+
double CTrailingStop::LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double price;
  int direction;
  if (type == OP_BUY)
  {
   price = SymbInfo.Bid();
   direction = -1;
  }
  else if (type == OP_SELL)
       {
        price = SymbInfo.Ask();
        direction = 1; 
       }
       else return true;
  
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (GreatDoubles(direction*openPrice, direction*price + minProfit*point)) // Если достигнут минпрофит 
  {
   newSL = openPrice*point;                                                  // переносим СЛ в безубыток 
  }
  if ((GreatDoubles(direction*openPrice, direction*price + minProfit*point)
     && GreatDoubles(direction*sl, direction*price + (trailingStop+trailingStep-1)*point)) || sl == 0)
  {
   newSL = NormalizeDouble(price + direction*trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// Трейлинг по индикатору PBI
//+------------------------------------------------------------------+
double CTrailingStop::PBITrailing(ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI)
{
 int buffer_num;
 int direction;
 int mainTrend, forbidenTrend;
 
 //GetTopTimeframe(timeframe
 
 switch(type)
 {
  case OP_SELL:
   //Print("PBI_Trailing, позиция СЕЛЛ, тип движения ", PBI_colors[0]);
   buffer_num = 5; // номер буфера максимумов
   direction = 1;
   mainTrend = 3;
   forbidenTrend = 4;
   break;
  case OP_BUY:
   //Print("PBI_Trailing, позиция БАЙ, тип движения ", PBI_colors[0]);
   buffer_num = 6; // номер буферов минимумов
   direction = -1;
   mainTrend = 1;
   forbidenTrend = 2;
   break;
  default:
   //log_file.Write(LOG_DEBUG, StringFormat("%s Неверный тип позиции для трейлинга %s", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type)));
   return(0.0);
 }
 
 int errcolors = CopyBuffer(handle_PBI, 4, 0, DEPTH_PBI, PBI_colors);
 int errextrems = CopyBuffer(handle_PBI, buffer_num, 0, DEPTH_PBI, PBI_Extrems);
 if(errcolors < DEPTH_PBI || errextrems < DEPTH_PBI)
 {
  //PrintFormat("%s Не удалось скопировать данные из индикаторного буфера", MakeFunctionPrefix(__FUNCTION__)); 
  log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось скопировать данные из индикаторного буфера. Errcolors = %d(%d); Errextrems = %d(%d);", MakeFunctionPrefix(__FUNCTION__), errcolors, DEPTH_PBI, errextrems, DEPTH_PBI));     
  return(0.0); 
 }
 
 double newExtr = 0;
 int index;
 if (PBI_colors[0] == mainTrend || PBI_colors[0] == forbidenTrend)
 {
//  PrintFormat("Текущее движение %s. time = %s", MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[0]), TimeToString(buffer_date[0]));
  for (index = 0; index < DEPTH_PBI; index++)
  { 
   if (PBI_Extrems[index] > 0)
   {
    if (PBI_colors[index] == 5 || PBI_colors[index] == 6 || PBI_colors[index] == 7)
    {
     newExtr = PBI_Extrems[index];
     //Print("последний экстремум ", newExtr);
     break;
    } 
   }
  }
 }
 
 if (newExtr > 0 && GreatDoubles(direction * sl, direction * (newExtr + direction * 50.0*Point()), 5))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s currentMoving = %s, extremum_from_last_coor_or_trend = %s, oldSL = %.05f, newSL = %.05f", MakeFunctionPrefix(__FUNCTION__), MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[0]), MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[index]), sl, (newExtr + direction*50.0*Point())) );
  return (newExtr + direction*50.0*Point());
 }
 return(0.0);
};


// трейлинг по экстремумам
double CTrailingStop::ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl,double priceOpen, CBlowInfoFromExtremums *blowInfo=NULL)
{
 double stopLoss = 0;                                            // переменная для хранения нового стоп лосса 
 double currentPriceBid = SymbolInfoDouble(symbol, SYMBOL_BID);  // текущая цена BID
 double currentPriceAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);  // текущая цена ASK
 double tmpPrevBid;                                              // предыдущая цена BID
 double tmpPrevAsk;                                              // предыдущая цена ASK
 double lastExtrHigh;                                            // цена последнего экстремума по HIGH
 double lastExtrLow;                                             // цена последнего экстремума по LOW
 double stopLevel;                                               // размер стоп левела
 ENUM_EXTR_USE last_extr;                                        // переменная для хранения последнего экстремума
 tmpPrevAsk = _previewPriceAsk;
 tmpPrevBid = _previewPriceBid;
 // сохраняем текущую цену в качестве предыдущей
 _previewPriceAsk = currentPriceAsk;
 _previewPriceBid = currentPriceBid;
 if (tmpPrevAsk == 0 || tmpPrevBid == 0)
  return (0.0);
 // пытаемся обновить данные об экстремумах
 if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )     
  {
   // получаем тип последнего экстремума
   last_extr = blowInfo.GetLastExtrType();
   if (last_extr == EXTR_NO)
    return (0.0);
   // сохраняем стоп левел
   stopLevel = NormalizeDouble(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point,_Digits);//+0.0005;
   if (type == OP_BUY)
    {
     // если последним экстремумов является LOW
     if (last_extr == EXTR_LOW)
      {
       lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0).price;     // получаем последний верхний экстремум HIGH для пробития
       lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0).price;      // получаем последний нижний экстремум LOW для stopLoss
       // если текущая цена пробила последний значимый HIGH экстремум  
       if ( GreatDoubles(currentPriceBid,lastExtrHigh) &&
            LessDoubles (tmpPrevBid,lastExtrHigh) )
          {
           // если расстояние от цены до нового стоп лосса больше стоп левела
           if ( GreatDoubles(currentPriceBid-lastExtrLow,stopLevel) )
             {
               // если новый стоп лосс больше предыдущего и мы в безубытке
               if ( GreatDoubles(lastExtrLow,sl))// && GreatDoubles(lastExtrLow,priceOpen) )
                  stopLoss = lastExtrLow;        
             }
          else
             {               
               // если новый стоп лосс больше предыдущего
               if ( GreatDoubles(currentPriceBid-stopLevel,sl) )
                  stopLoss = currentPriceBid - stopLevel;
             }
          } 
       }
    }
   if (type == OP_SELL)
    {
     // если последним экстремумов является HIGH
     if (last_extr == EXTR_HIGH)
      {
       lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0).price;     // получаем последний верхний экстремум HIGH для stopLoss
       lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0).price;      // получаем последний нижний экстремум LOW для пробития
       // если текущая цена пробила последний значимый LOW экстремум  
       if ( LessDoubles(currentPriceAsk,lastExtrLow) &&
            GreatDoubles (tmpPrevAsk,lastExtrLow) )
          {
           // если расстояние от цены до нового стоп лосса больше стоп левела
           if ( GreatDoubles(lastExtrHigh - currentPriceAsk,stopLevel) )
             {             
               // если новый стоп лосс меньше предыдущего и мы в безубытке
               if ( LessDoubles(lastExtrHigh,sl))// && LessDoubles(lastExtrHigh,priceOpen) )
                  stopLoss = lastExtrHigh;        
             }
          else
             {                               
               // если новый стоп лосс меньше предыдущего
               if ( LessDoubles(currentPriceAsk+stopLevel ,sl) )
                  stopLoss = currentPriceAsk + stopLevel ;
             }
          } 
      }    
   }
  }
 return (stopLoss);
}
 
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+
bool CTrailingStop::UpdateSymbolInfo(string symbol)
{
 SymbInfo.Name(symbol);
 if(SymbInfo.Select() && SymbInfo.RefreshRates())
 {
  return(true);
 }
 return(false);
}