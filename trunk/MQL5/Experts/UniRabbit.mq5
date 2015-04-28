//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+---------------------------------////////////////////////////---------------------------------+
//| Эксперт FollowWhiteRabbit                                        |
//+------------------------------------------------------------------+
//подключение необходимых библиотек
#include <Lib CIsNewBar.mqh>
#include <TradeManager/TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // трендовый контейнер
//константы
#define KO 3 //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30 // размер спреда 
//вводимые пользователем параметры
input string base_param = ""; // БАЗОВЫЕ ПАРАМЕТРЫ
input double lot = 1; // лот
input double percent = 0.1; // процент
input bool useM1 = true; // использовать M1
input bool useM5 = true; // использовать M5
input bool useM15 = true; // использовать M15 
input double M1_supremacyPercent  = 5;//процент, насколько бар M1 больше среднего значения
input double M5_supremacyPercent  = 3;//процент, насколько бар M5 больше среднего значения
input double M15_supremacyPercent  = 1;//процент, насколько бар M15 больше среднего значения
input double profitPercent = 0.5;// процент прибыли                                                          
input int priceDifference = 50;//Price Difference
input string filters_param = ""; // ФИЛЬТРЫ
input bool useTwoTrends = true; // по двум последним трендам
input bool useChannel = true; // закрытие внутри канала
input bool useClose = true; // закрытие позиции в противоположном тренде
input bool use19Lines = true; // 19 линий
input bool checkFilter = true; // фильтр входных сигналов 


// переменные робота 
datetime history_start;
//торговый класс
CTradeManager ctm;          
//массивы
double ave_atr_buf[1],close_buf[1],open_buf[1],pbi_buf[1];

ENUM_TM_POSITION_TYPE opBuy,opSell;
// объекты классов прихода новых баров
CisNewBar *isNewBarM1;
CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
// объекты контейнеров трендов
CTrendChannel *trendM1;
CTrendChannel *trendM5;
CTrendChannel *trendM15;
//хэндлы индикаторов
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
int handleDE_M1;
int handleDE_M5;
int handleDE_M15;
int handle19Lines; 
//параметры позиции и трейлинга
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //объем 
// переменные для получения сигналов
int signalM1;
int signalM5;
int signalM15;
// флаги текущего тренда 
bool trendM1Now = false;
bool trendM5Now = false;
bool trendM15Now = false;
// направление открытия позиции
int posOpenedDirection = 0;
// флаги первых загрузок трендов
bool firstUploadedM1 = false; 
bool firstUploadedM5 = false;
bool firstUploadedM15 = false;
// периоды старших ТФ 
ENUM_TIMEFRAMES eldPeriodForM1 = GetTopTimeframe(PERIOD_M1); 
ENUM_TIMEFRAMES eldPeriodForM5 = GetTopTimeframe(PERIOD_M5); 
ENUM_TIMEFRAMES eldPeriodForM15 = GetTopTimeframe(PERIOD_M15); 

//+------------------------------------------------------------------+
//| Инициализация эксперта                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //запомним время запуска эксперта для получения торговой истории
 
 //----------- Обработка индикаторов DrawExtremums
 
 // привязка индикатора DrawExtremums M1
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
    
 // привязка индикатора DrawExtremums M5
 handleDE_M5 = DoesIndicatorExist(_Symbol,PERIOD_M5,"DrawExtremums");
 if (handleDE_M5 == INVALID_HANDLE)
  {
   handleDE_M5 = iCustom(_Symbol,PERIOD_M5,"DrawExtremums");
   if (handleDE_M5 == INVALID_HANDLE)
    {
     Print("Не удалось создать хэндл индикатора DrawExtremums на M5");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M5);
  }    
  
 // привязка индикатора DrawExtremums M15
 handleDE_M15 = DoesIndicatorExist(_Symbol,PERIOD_M15,"DrawExtremums");
 if (handleDE_M15 == INVALID_HANDLE)
  {
   handleDE_M15 = iCustom(_Symbol,PERIOD_M15,"DrawExtremums");
   if (handleDE_M15 == INVALID_HANDLE)
    {
     Print("Не удалось создать хэндл индикатора DrawExtremums на M15");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M15);
  }    
  //----------- Конец обработки индикатора DrawExtremums
        
  //----------- Обработка индикатора NineTeenLines
  handle19Lines = DoesIndicatorExist(_Symbol,_Period,"NineTeenLines");
  if (handle19Lines == INVALID_HANDLE)
   {
    handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
    if (handle19Lines == INVALID_HANDLE)
     {
      Print("Не удалось создать хэндл индикатора NineTeenLines");
      return (INIT_FAILED);
     }
    SetIndicatorByHandle(_Symbol,_Period,handle19Lines);
   } 
  //---------- Конец обработки NineTeenLines
   
  opBuy = OP_BUY;
  opSell= OP_SELL;
  
 //----------- создаем объекты класса для обнаружения появления нового бара
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 isNewBarM5= new CisNewBar(_Symbol,PERIOD_M5);
 isNewBarM15= new CisNewBar(_Symbol,PERIOD_M15);  
 
 //----------- создаем объекты классов контейнеров трендов
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE_M1,percent);
 trendM5 = new CTrendChannel(0,_Symbol,PERIOD_M5,handleDE_M5,percent);
 trendM15 = new CTrendChannel(0,_Symbol,PERIOD_M15,handleDE_M15,percent);  
 // первая попытка прогрузить историю трендов
 firstUploadedM1 = trendM1.UploadOnHistory();
 firstUploadedM5 = trendM5.UploadOnHistory();
 firstUploadedM15 = trendM15.UploadOnHistory();  
 
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
  delete isNewBarM5;
  delete isNewBarM15;
  delete trendM1;
  delete trendM5;
  delete trendM15;
 }

void OnTick()
{
 int tempPosDirection=0;
 ctm.OnTick();
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;
 signalM5  = 0;
 signalM15 = 0;
 // если не открыта ни одна позиция
 if (ctm.GetPositionCount() == 0)
  posOpenedDirection = 0;

 // если еще не загружены экстремумы на M1
 if (!firstUploadedM1)
  firstUploadedM1 = trendM1.UploadOnHistory();
  
 // если еще не загружены экстремумы на M5
 if (!firstUploadedM5)
  firstUploadedM5 = trendM5.UploadOnHistory();  
  
 // если не все тренды на всех таймфреймах прогружены, то ретёрним
 if (!firstUploadedM1 || !firstUploadedM5)
  return;  
  
 // обработка сигналов на M1
 if(isNewBarM1.isNewBar()>0)
 {
  // получаем сигнал на M1 
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info);
  
  // если два последних тренда существуют
  if (trendM1.GetTrendByIndex(0)!=NULL && trendM1.GetTrendByIndex(1)!=NULL)
   { 
    // если существует тренд в текущий момент и два последних тренда в противоположную сторону
    if (pos_info.type == opBuy  )
     {
      tempPosDirection = 1;
      signalM1 = 1;
      // обрабатываем фильтры
      if (trendM1.IsTrendNow() && TestTrendsDirection(0,1) && useTwoTrends) // фильтр двух последних трендов при условии наличия текущего тренда
       signalM1 = 0;
      if (trendM1.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M1) && useChannel) // фильтр закрытия большого бара внутри канала
       signalM1 = 0;
      if (!FilterBy19Lines(1,PERIOD_M1,0) && use19Lines)
       signalM1 = 0;
     }
    else if (pos_info.type == opSell )
     {
      tempPosDirection = -1;
      signalM1 = -1;
      // обрабатываем фильтры
      if (trendM1.IsTrendNow() && TestTrendsDirection(0,-1) && useTwoTrends) // фильтр двух последних трендов при условии наличия текущего тренда
       signalM1 = 0; 
      if (trendM1.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M1) && useChannel) // фильтр закрытия большого бара внутри канала
       signalM1 = 0;       
      if (!FilterBy19Lines(-1,PERIOD_M1,0) && use19Lines)
       signalM1 = 0;
     }
    else
     {
      tempPosDirection = 0;
      signalM1 = 0;  
     }
       
   }
 }
 
 // обработка сигналов на M5
 if(isNewBarM5.isNewBar()>0)
 {
  // получаем сигнал на M5 
  GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
  
  // если два последних тренда существуют
  if (trendM5.GetTrendByIndex(0)!=NULL && trendM5.GetTrendByIndex(1)!=NULL)
   { 
    // если существует тренд в текущий момент и два последних тренда в противоположную сторону
    if (pos_info.type == opBuy  )
     {
      tempPosDirection = 1;
      signalM5 = 1;
      // обрабатываем фильтры
      if (trendM5.IsTrendNow() && TestTrendsDirection(1,1) && useTwoTrends) // фильтр двух последних трендов при условии наличия текущего тренда
       signalM5 = 0;
      if (trendM5.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M5) && useChannel) // фильтр закрытия большого бара внутри канала
       signalM5 = 0;
      if (!FilterBy19Lines(1,PERIOD_M5,0) && use19Lines)
       signalM5 = 0;
     }
    else if (pos_info.type == opSell )
     {
      tempPosDirection = -1;
      signalM5 = -1;
      // обрабатываем фильтры
      if (trendM5.IsTrendNow() && TestTrendsDirection(1,-1) && useTwoTrends) // фильтр двух последних трендов при условии наличия текущего тренда
       signalM5 = 0; 
      if (trendM5.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M5) && useChannel) // фильтр закрытия большого бара внутри канала
       signalM5 = 0;       
      if (!FilterBy19Lines(-1,PERIOD_M5,0) && use19Lines)
       signalM5 = 0;
     }
    else
     {
      tempPosDirection = 0;
      signalM5 = 0;  
     }
       
   }
 } 
 
 if( ( useM1 && (signalM1 == 1 || signalM1 == -1) || useM5 && (signalM5 == 1 || signalM5 == -1) ) && (InputFilter() || !checkFilter) )
 {
  posOpenedDirection = tempPosDirection;
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
   int newDirection;
   trendM1.UploadOnEvent(sparam,dparam,lparam);
   trendM1Now = trendM1.IsTrendNow();
   
   // если пришел новый тренд и мы используем фильтр закрытия позиции по приходу противоположного тренда
   if (trendM1Now && useClose )
    {
     newDirection = trendM1.GetTrendByIndex(0).GetDirection();
     // если пришел противоположный направлению позиции тренд
     if (posOpenedDirection !=0 && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 )
      {
       // закрываем позицию
       ctm.ClosePosition(0);
       posOpenedDirection = 0;
      }
    }
    
   trendM5.UploadOnEvent(sparam,dparam,lparam);
   trendM5Now = trendM5.IsTrendNow();
   
   // если пришел новый тренд и мы используем фильтр закрытия позиции по приходу противоположного тренда
   if (trendM5Now && useClose )
    {
     newDirection = trendM5.GetTrendByIndex(0).GetDirection();
     // если пришел противоположный направлению позиции тренд
     if (posOpenedDirection !=0 && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 )
      {
       // закрываем позицию
       ctm.ClosePosition(0);
       posOpenedDirection = 0;
      }
    }    
    
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
 if (CopyRates(_Symbol,period,1,1,rates) < 1)
  {
   return (0);
  }
 // если нужно открываться вверх
 if (point == 1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  }
 // если нужно открыться вниз
 if (point == -1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  }
 //PrintFormat("price = %.05f open = %.05f close = %.05f",price,rates[0].open,rates[0].close);
      
 return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );
}

// фильтры

// функция возвращает true, если последние два тренда в одну сторону
bool TestTrendsDirection (int type,int direction)
 {
  switch (type)
   {
    // M1
    case 0:
     if (trendM1.GetTrendByIndex(0).GetDirection() == direction && trendM1.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break; 
    // M5
    case 1:
     if (trendM5.GetTrendByIndex(0).GetDirection() == direction && trendM5.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break; 
    // M15
    case 2:
     if (trendM15.GetTrendByIndex(0).GetDirection() == direction && trendM15.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break;         
   }
  return (false);
 }

// функция для проверки, что бар закрылся внутри канала
bool TestLargeBarOnChannel (ENUM_TIMEFRAMES period) // функция тестирует 
 {
  double priceLineUp;
  double priceLineDown;
  double closeLargeBar[];
  datetime timeBuffer[];
  if (CopyClose(_Symbol,period,1,1,closeLargeBar) < 1 || CopyTime(_Symbol,period,1,1,timeBuffer) < 1) 
   {
    Print("Не удалось прогрузить буфер цены закрытия предыдущего бара");
    return (false);
   }
  priceLineUp = trendM1.GetTrendByIndex(0).GetPriceLineUp(timeBuffer[0]);
  priceLineDown = trendM1.GetTrendByIndex(0).GetPriceLineDown(timeBuffer[0]);
  if ( LessOrEqualDoubles( closeLargeBar[0],priceLineUp) && GreatOrEqualDoubles(closeLargeBar[0],priceLineDown) )
   return (true);
  return (false);
 }
 
bool FilterBy19Lines (int direction,ENUM_TIMEFRAMES period,int stopLoss)
 {
  
  double currentPrice;
  double lenPrice3;
  double lenPrice4;
  double level3[];
  double level4[];
  int bufferLevel3;
  int bufferLevel4;  
  // если нам нужны линии для M1
  if (period == PERIOD_M1)
   {
    bufferLevel3 = 34;
    bufferLevel4 = 35;
   }
  // если нам нужны линии для M5
  if (period == PERIOD_M5)
   {
    bufferLevel3 = 34;
    bufferLevel4 = 35;
   }   
  // если нам нужны линии для M15
  if (period == PERIOD_M15)
   {
    bufferLevel3 = 26;
    bufferLevel4 = 27;
   }   
  
  if (direction == 1)
   {
    currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   }
   
  if (direction == -1)
   {
    currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
   }
   
  if (CopyBuffer(handle19Lines,bufferLevel3,0,1,level3) < 1 || 
      CopyBuffer(handle19Lines,bufferLevel4,0,1,level4) < 1)
       {
        Print("Не удалось скопировать буферы уровней 19Lines");
        return (false);
       }
  // вычисляем расстояния от текущей цены до уровней
  lenPrice3 = MathAbs(level3[0] - currentPrice);
  lenPrice4 = MathAbs(level4[0] - currentPrice);
  if (direction == 1)
   {
    if (GreatDoubles(level3[0],level4[0]) && GreatDoubles(lenPrice3,10*lenPrice4))
     return (true);
    if (GreatDoubles(level4[0],level3[0]) && GreatDoubles(lenPrice4,10*lenPrice3))
     return (true);     
   }
  if (direction == -1)
   {
    if (GreatDoubles(level3[0],level4[0]) && GreatDoubles(lenPrice4,10*lenPrice3))
     return (true);
    if (GreatDoubles(level4[0],level3[0]) && GreatDoubles(lenPrice3,10*lenPrice4))
     return (true);      
   }
  return (false);
 }
 
// фукция не пропускает противоречивые сигналы
bool  InputFilter ()
 {
  // если все сигналы не BUY (т.е. нет противоречий)
  if (signalM1!=1 && signalM5!=1)
   return(true);
  // если все сигналы не SELL (т.е. нет противоречий)
  if (signalM1!=-1 && signalM5!=-1)
   return(true);
  return(false);
 } 