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
#define ADD_TO_STOPLOSS 50 // добавочные пункты к стоп лоссу
#define DEPTH  1000        // глубина истории
#define SPREAD 30          // размер спреда
#define KO 3 //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс 
//вводимые пользователем параметры
input double lot = 1; // лот
input double percent = 0.1; // процент
input double M1_supremacyPercent  = 5;//процент, насколько бар M1 больше среднего значения
input double M5_supremacyPercent  = 3;//процент, насколько бар M5 больше среднего значения
input double M15_supremacyPercent = 1;//процент, насколько бар M15 больше среднего значения
input double profitPercent = 0.5;// процент прибыли                                            

input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;// Тип отложенного ордера                    
input int priceDifference = 50;//Price Difference
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
int handle_PBI;
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
int handleDE;
//параметры позиции и трейлинга
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //объем 

int signalM1;
int signalM5;
int signalM15;

//+------------------------------------------------------------------+
//| Инициализация эксперта                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //запомним время запуска эксперта для получения торговой истории
 // привязка индикатора DrawExtremums 
 handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
 if (handleDE == INVALID_HANDLE)
  {
   handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     Print("Не удалось создать хэндл индикатора DrawExtremums");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE);
  }     
 switch (pending_orders_type) //вычисление priceDifference
 {
  case USE_LIMIT_ORDERS: //useLimitsOrders = true;
  opBuy = OP_BUYLIMIT;
  opSell= OP_SELLLIMIT;
  break;
  case USE_STOP_ORDERS:
  opBuy = OP_BUYSTOP;
  opSell= OP_SELLSTOP;
  break;
  case USE_NO_ORDERS:
  opBuy = OP_BUY;
  opSell= OP_SELL;      
  break;
 }   
 //создаем объекты класса для обнаружения появления нового бара
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 isNewBarM5= new CisNewBar(_Symbol,PERIOD_M5);
 isNewBarM15=new CisNewBar(_Symbol,PERIOD_M15);
 // создаем объекты классов контейнеров трендов
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE,percent);
 trendM5 = new CTrendChannel(0,_Symbol,PERIOD_M5,handleDE,percent);
 trendM15 = new CTrendChannel(0,_Symbol,PERIOD_M15,handleDE,percent);  
 // создаем хэндл PriceBasedIndicator
 handle_PBI= iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");
 handle_aATR_M1=iMA(_Symbol,PERIOD_M1,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M1,30));
 handle_aATR_M5=iMA(_Symbol,PERIOD_M5,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M5,30)); 
 handle_aATR_M15=iMA(_Symbol,PERIOD_M15,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M15,30));      
 if(handle_PBI==INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s Не удалось получить хэндл одного из вспомогательных индикаторов", MakeFunctionPrefix(__FUNCTION__)));  
  return (INIT_FAILED);
 }       
    
 trailing.trailingType = TRAILING_TYPE_EASY_LOSSLESS;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
 {
  delete isNewBarM1;
  delete isNewBarM15;
  delete isNewBarM5;
  delete trendM1;
  delete trendM15;
  delete trendM5;
 }

void OnTick()
{
 ctm.OnTick();
   
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;
 signalM5  = 0;
 signalM15 = 0;
 /*
 if(isNewBarM1.isNewBar())
 {
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info); //свой коэффициент
  if (pos_info.type == opBuy)
   signalM1 = 1;
  else if (pos_info.type == opSell)
   signalM1 = -1; 
  else
   signalM1 = 0;   
 }
 */
 /*
 if(isNewBarM5.isNewBar())
 {
  GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
  if (pos_info.type == opBuy)
   signalM5 = 1;
  else if (pos_info.type == opSell)
   signalM5 = -1; 
  else
   signalM5 = 0;  
 }  
 */
 if(isNewBarM15.isNewBar())
 {
  GetTradeSignal(PERIOD_M15, handle_aATR_M15, M15_supremacyPercent, pos_info);
  if (pos_info.type == opBuy)
   signalM15 = 1;
  else if (pos_info.type == opSell)
   signalM15 = -1; 
  else
   signalM15 = 0;    
 }
 if( (pos_info.type == opBuy || pos_info.type == opSell ) && (InputFilter() || !checkFilter) )
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
   /*
   double price;
   // пришло событие "сформировался новых экстремум"
   if (sparam == eventExtrDownName || sparam == eventExtrUpName)
    {
     // удаляем линии с графика
     DeleteLines();
     // получаем новые значение экстремумов и смещаем
     UploadExtremums ();

     trend = IsTrendNow();
     if (trend)
      {  
       // перерисовываем линии
       DrawLines ();     
      }
       
    }
   */
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
 //если не удалось прогрузить буфер PBI  
 if(CopyBuffer(handle_PBI,4,1,1,pbi_buf) < 1)   
 {
  //то выводим сообщение в лог об ошибке
  log_file.Write(LOG_DEBUG,StringFormat("%s Не удалось скопировать данные из вспомогательного индикатора", MakeFunctionPrefix(__FUNCTION__)));   
  return; //и выходим из функции
 } 
 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
  {   

   pos.tp=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl=CountStoploss(-1);
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
   pos.sl = CountStoploss(1);
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
int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, DEPTH);
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6; //minimum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; //maximum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  direction = -1;
 }
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,DEPTH, bufferStopLoss);
 }
 if (copiedPBI < DEPTH)
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__)));  
  return(0);
 }
 for(int i=0;i<DEPTH;i++)
 {
  if(bufferStopLoss[i]>0)
  {
   if(LessDoubles(direction*bufferStopLoss[i],direction*priceAB))
   {
   // log_file.Write(LOG_DEBUG,StringFormat("%s price = %f; extr = %f",MakeFunctionPrefix(__FUNCTION__), priceAB, bufferStopLoss[i]));      
    stopLoss=(int)(MathAbs(bufferStopLoss[i] - priceAB)/Point());
    break;
   }
  }
 }
 if (stopLoss <= 0)  
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s Не поставили стоп лосс на экстремуме", MakeFunctionPrefix(__FUNCTION__)));   
  stopLoss = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)+ADD_TO_STOPLOSS;
 }
 return(stopLoss);
}

// фукция не пропускает противоречивые сигналы
bool  InputFilter ()
 {
  // если все сигналы не BUY (т.е. нет противоречий)
  if (signalM1!=1 && signalM5!=1 && signalM15!=1)
   return(true);
  // если все сигналы не SELL (т.е. нет противоречий)
  if (signalM1!=-1 && signalM5!=-1 && signalM15!=-1)
   return(true);
  return(false);
 }