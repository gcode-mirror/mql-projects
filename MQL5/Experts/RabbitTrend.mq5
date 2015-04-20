//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт FollowWhiteRabbit                                        |
//+------------------------------------------------------------------+
//подключение необходимых библиотек
#include <Lib CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <CTrendChannel.mqh> // трендовый контейнер
//константы
#define KO 3 //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30 // размер спреда 
//вводимые пользователем параметры
input double lot = 1; // лот
input double percent = 0.1; // процент
input double M1_supremacyPercent  = 5;//процент, насколько бар M1 больше среднего значения
input double profitPercent = 0.5;// процент прибыли                                                          
input int priceDifference = 50;//Price Difference

// переменные робота 
datetime history_start;
//торговый класс
CTradeManager ctm;          
//массивы
double ave_atr_buf[1],close_buf[1],open_buf[1],pbi_buf[1];

ENUM_TM_POSITION_TYPE opBuy,opSell;
// объекты классов прихода новых баров
CisNewBar *isNewBarM1;
// объекты контейнеров трендов
CTrendChannel *trendM1;
//хэндлы индикаторов
int handle_aATR_M1;
int handleDE_M1;
//параметры позиции и трейлинга
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //объем 

int signalM1;

bool trendM1Now = false;

bool firstUploadedM1 = false; // флаг первой загрузки трендов

//+------------------------------------------------------------------+
//| Инициализация эксперта                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //запомним время запуска эксперта для получения торговой истории
 // привязка индикатора DrawExtremums M15
 handleDE_M1 = DoesIndicatorExist(_Symbol,PERIOD_M1,"DrawExtremums");
 if (handleDE_M1 == INVALID_HANDLE)
  {
   handleDE_M1 = iCustom(_Symbol,PERIOD_M1,"DrawExtremums");
   if (handleDE_M1 == INVALID_HANDLE)
    {
     Print("Не удалось создать хэндл индикатора DrawExtremums на M1");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M1);
  }        
  
  opBuy = OP_BUY;
  opSell= OP_SELL;
  
 //создаем объекты класса для обнаружения появления нового бара
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 // создаем объекты классов контейнеров трендов
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE_M1,percent);
 // первая попытка прогрузить историю трендов
 firstUploadedM1 = trendM1.UploadOnHistory();
 
 handle_aATR_M1=iMA(_Symbol,PERIOD_M1,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M1,30));        
 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
 {
  delete isNewBarM1;
  delete trendM1;
 }

void OnTick()
{
 ctm.OnTick();
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;

 // если еще не загружены экстремумы
 if (!firstUploadedM1)
  firstUploadedM1 = trendM1.UploadOnHistory();
  
 // если не все тренды на всех таймфреймах прогружены, то ретёрним
 if (!firstUploadedM1)
  return;  

 if(isNewBarM1.isNewBar())
 {
  // получаем сигнал на M1 
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info);
  // если два последних тренда существуют
  if (trendM1.GetTrendByIndex(0)!=NULL && trendM1.GetTrendByIndex(1)!=NULL)
   { 
    // если существует тренд в текущий момент и два последних тренда в противоположную сторону
    if (pos_info.type == opBuy && trendM1Now &&  trendM1.GetTrendByIndex(0).GetDirection() == 1/* && trendM1.GetTrendByIndex(1).GetDirection() == -1*/ )
     signalM1 = 1;
    else if (pos_info.type == opSell  && trendM1Now &&  trendM1.GetTrendByIndex(0).GetDirection() == -1 /*&& trendM1.GetTrendByIndex(1).GetDirection() == 1*/ )
     signalM1 = -1; 
    else
     signalM1 = 0;    
   }
 }
 if( (signalM1 == 1 || signalM1 == -1 ) )
 {
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,SPREAD);   
 }
 
}

void OnTrade()
{
 ctm.OnTrade();
 if(history_start != TimeCurrent())
 {
  history_start = TimeCurrent() + 1;
 }
}

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   trendM1.UploadOnEvent(sparam,dparam,lparam);
   trendM1Now = trendM1.IsTrendNow();
  } 

//функция получения торгового сигнала (возвращает заполненную структуру позиции) 
void GetTradeSignal(ENUM_TIMEFRAMES tf, int handle_atr, double supremacyPercent, SPositionInfo &pos)
{   
 //если не удалось прогрузить все буферы 
 if (CopyClose(_Symbol,tf,1,1,close_buf)<1 ||
     CopyOpen(_Symbol,tf,1,1,open_buf)<1 ||
     CopyBuffer(handle_atr,0,0,1,ave_atr_buf)<1)
 {
  //то выводим сообщение в лог об ошибке
  log_file.Write(LOG_DEBUG,StringFormat("%s Не удалось скопировать данные из буфера ценового графика", MakeFunctionPrefix(__FUNCTION__)));    
  return;//и выходим из функции
 }

 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
  {   
   
   pos.tp=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl=CountStoploss(tf,-1);
   
   //если вычисленный тейк профит в kp раза или более раз больше, чем вычисленный стоп лосс
   if(pos.tp >= KO*pos.sl)
    pos.type = opSell;
   else
   {
    pos.type = OP_UNKNOWN;
    return;
   }   
  }
  if(GreatDoubles(close_buf[0], open_buf[0]))
  { 
      
   pos.tp = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl = CountStoploss(tf,1);
   // если вычисленный тейк профит в kp раза или более раз больше, чем вычисленный стоп лосс
   if(pos.tp >= KO*pos.sl)
    pos.type = opBuy;
   else
   {
    pos.type = OP_UNKNOWN;
    return;
   }
  }
  pos.expiration = 0; 
  pos.expiration_time = 0;
  pos.volume = volume;
  pos.priceDifference = priceDifference; 
  // выставляем minProfit как два стоп лосса
  trailing.minProfit = pos.sl*2;
 }
 ArrayInitialize(ave_atr_buf,EMPTY_VALUE);
 ArrayInitialize(close_buf,EMPTY_VALUE);
 ArrayInitialize(open_buf,EMPTY_VALUE);
 ArrayInitialize(pbi_buf,EMPTY_VALUE);
 return;
} 
// функция вычисляет стоп лосс
int CountStoploss(ENUM_TIMEFRAMES period,int point)
{
 MqlRates rates[];
 double price;
 if (CopyRates(_Symbol,period,0,1,rates) < 1)
  {
   return (0);
  }
 // если нужно открываться вверх
 if (point == 1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  }
 // если нужно открыться вниз
 if (point == -1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  }
 return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );
}