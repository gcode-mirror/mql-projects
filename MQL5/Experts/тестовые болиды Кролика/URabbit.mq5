//+------------------------------------------------------------------+
//|                                                      URabbit.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек
#include <TradeManager/TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // трендовый контейнер
#include <Chicken/ContainerBuffers(NoPBI).mqh> //контейнер буферов цен на всех ТФ (No PBI) - для запуска в ТС
#include <Rabbit/TimeFrame.mqh>

//константы
#define KO 3            //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30       // размер спреда 

enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // открытие позиции на продажу
 BUY  = 1,      // открытие позиции на покупку
 NO_SIGNAL = 0, // для действий, когда сигнала на открытие позиции не было
 DISCORD = 2,   // сигнал противоречия, "разрыв шаблона"
};
//---------------------Добавить---------------------------------+
// ENUM для сигнала
// входные параметры для процента supremacyPercent
// нужно ли в конбуф запихнуть данные индикатора АТР, а цену открытия?
//--------------------------------------------------------------+

//-------вводимые пользователем параметры-------------
input string base_param = ""; // БАЗОВЫЕ ПАРАМЕТРЫ
input double lot = 1;         // лот
input double percent = 0.1;   // процент
input double M1_Ratio  = 5;   //процент, насколько бар M1 больше среднего значения
input double M5_Ratio  = 3;   //процент, насколько бар M1 больше среднего значения
input double M15_Ratio  = 1;  //процент, насколько бар M1 больше среднего значения
input double profitPercent = 0.5;// процент прибыли                                                          
input int priceDifference = 50;  // Price Difference
input string filters_param = ""; // ФИЛЬТРЫ
input bool useTwoTrends = true;  // по двум последним трендам
input bool useChannel = true;    // закрытие внутри канала
input bool useClose = true;      // закрытие позиции в противоположном тренде
input bool use19Lines = true;    // 19 линий

// ---------переменные робота------------------
CTrendChannel *trend;      // буфер трендов
CTimeframe *ctf;           // данные по ТФ
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
CArrayObj *dataTFs;        // массив ТФ, для торговли на нескольких ТФ одновременно
CArrayObj *trends;         // массив буферов трендов (для каждого ТФ свой буфер)

CTradeManager ctm;         //торговый класс 
     
datetime history_start;    // время для получения торговой истории                           
double atr_buf[1], open_buf[1];

ENUM_TM_POSITION_TYPE opBuy, opSell;
int handle19Lines; 
int handleATR;
int handleDE;

double Ks[3]; // массив коэффициентов для каждого ТФ от М1 до М15

//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //объем  

// направление открытия позиции
int posOpenedDirection = 0;
int signalForTrade;
int SL, TP;
long magic;
ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
ENUM_TIMEFRAMES posOpenedTF;  // период на котором была открыта позиция

int indexPosOpenedTF;         // удалить елсли закрытие позиции по условию любого тренда или на том же тчо и была открыта

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 Ks[0] = M1_Ratio;
 Ks[1] = M5_Ratio;
 Ks[2] = M15_Ratio;
 history_start = TimeCurrent(); //запомним время запуска эксперта для получения торговой истории
 dataTFs = new CArrayObj();
 trends = new CArrayObj();
 //заполним каждый таймфрейм 
 for(int i = 0; i < ArraySize(TFs); i++)
 {
  handleDE = iCustom(_Symbol,TFs[i],"DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   PrintFormat("Не удалось создать хэндл индикатора DrawExtremums на %s", PeriodToString(TFs[i]));
   return (INIT_FAILED);
  }
  handleATR = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30));
  if (handleATR == INVALID_HANDLE)
  {
   PrintFormat("Не удалось создать хэндл индикатора ATR на %s", PeriodToString(TFs[i]));
   return (INIT_FAILED);
  } 
  ctf = new CTimeframe(TFs[i],_Symbol, handleATR, handleDE); // создадим ТФ
  ctf.SetRatio(Ks[i]);                                       // установим коэффициент
  ctf.IsThisNewBar();                                        // добавим счетчик по новому бару
  dataTFs.Add(ctf);                                          // добавим в буффер ТФ dataTFs
  // создать контейнер трендов для каждого периода
  trend = new CTrendChannel(0, _Symbol, TFs[i], handleDE, percent);
  trend.UploadOnHistory();
  trends.Add(trend);
  log_file.Write(LOG_DEBUG, StringFormat(" Загрузка ТФ = %s прошла успешно", PeriodToString(TFs[i])));
 }
 
 //----------- Обработка индикатора NineTeenLines----------
 handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
 if (handle19Lines == INVALID_HANDLE)
 {
  Print("Не удалось создать хэндл индикатора NineTeenLines");
  return (INIT_FAILED);
 }
 
 //---------- Конец обработки NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 opBuy  = OP_BUY;  // так было. Зачем?
 opSell = OP_SELL;
 
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete trend;
 delete conbuf;
 dataTFs.Clear();
 delete dataTFs;
 trends.Clear();
 delete trends;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();    
 conbuf.Update();             // потиковое обновление данных о цене
 pos_info.type = OP_UNKNOWN;  // сброс струтуры позиции
 signalForTrade = NO_SIGNAL;  // обнулим екущий сигнал

 if (ctm.GetPositionCount() == 0) // если нет открытых позиций
  posOpenedDirection = NO_SIGNAL; // напарвление открытой позиции NO_SIGNAL (0)
  
 for(int i = ArraySize(TFs)-1; i >= 0; i--) // проходя по каждому таймфрему, начиная со старшего
 { 
  trend = trends.At(i);                     
  if(!trend.UploadOnHistory()) // обновить буфер трендов на текущем ТФ
   return;
  ctf = dataTFs.At(i);         // получить текущий ТФ
  if(ctf.IsThisNewBar() > 0)   // если на нем пришел новый бар
  {
   signalForTrade = GetTradeSignal(ctf); // считать сигнал на этом ТФ
   pos_info.sl = SL;                     // установить рассчитанный SL
   pos_info.tp = 10 * SL;                
   if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
   {
    if(signalForTrade == BUY)
     pos_info.type = opBuy;
    else 
     pos_info.type = opSell;
    posOpenedDirection = signalForTrade;  // сохранить направление по которому была открыта сделка
    posOpenedTF = TFs[i];                 // сохранить ТФ, на котором была открыта сделка
    indexPosOpenedTF = i;                 // сохранить индекс ТФ в массиве dataTFs, на котором была открыта сделка
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, SPREAD);   // открыть позицию
   }
  }
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
 // проверка на разрыв шаблона. 
 // Если был обнаружен тренд в противоположную сторону, закрыть позицию
 int newDirection;  
 for(int i = 0; i < ArraySize(TFs); i++)
 {
  trend = trends.At(i);
  trend.UploadOnEvent(sparam, dparam, lparam);
  ctf = dataTFs.At(i);
  ctf.SetTrendNow(trend.IsTrendNow());
  // если пришел новый тренд и мы используем фильтр закрытия позиции по приходу противоположного тренда
  if (ctf.IsThisTrendNow() && useClose)
  {
   newDirection = trend.GetTrendByIndex(0).GetDirection();
   // если пришел противоположный направлению позиции тренд
   if (i >= indexPosOpenedTF && posOpenedDirection != NO_SIGNAL && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 ) // && ctf.GetPeriod() == posOpenedTF
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Закрыли позицию на OnChartEvent по противоположному тренду", MakeFunctionPrefix(__FUNCTION__)));
    // закрываем позицию 
    ctm.ClosePosition(0);
    posOpenedDirection = NO_SIGNAL;
   }
  }
 } 
}
//функция получения торгового сигнала (возвращает заполненную структуру позиции) 
int GetTradeSignal(CTimeframe *TF)  
{
 int signalThis = 0;
 int signalYoungTF;
 SL = 0;
 if(TF.GetPeriod() == PERIOD_M1)
 {
  signalYoungTF = 0;
 }
 else 
 {
  CTimeframe *tf = GetBottom(TF);
  signalYoungTF = GetTradeSignal(GetBottom(TF));

  if(signalYoungTF == 2)   //было найдено противоречие на младших Тф
   return 2;
 }
 if( CopyOpen(_Symbol,TF.GetPeriod(), 1, 1, open_buf) < 1 ||
     CopyBuffer(TF.GetHandleATR(), 0, 1, 1, atr_buf) <1 )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при копировании цены открытия последнего бара или значения ATR", MakeFunctionPrefix(__FUNCTION__)));
  return 2;
 }
 //условие пройдено
 if(GreatDoubles(MathAbs(open_buf[0] - conbuf.GetClose(TF.GetPeriod()).buffer[1]), atr_buf[0]*(1 + TF.GetRatio())))
 {
  if(open_buf[0] - conbuf.GetClose(TF.GetPeriod()).buffer[1] > 0)
  {
   signalThis = SELL;
   Print("сигнал SELL");
  }
  else 
  {
   signalThis = BUY;
   Print("сигнал BUY");
  }
  bool barInChannel = true;
  if(!TrendsDirection(TF, signalThis))
  {
   if(TF.IsThisTrendNow())
   { 
    barInChannel = LastBarInChannel(TF);
    Print("Сейчас есть тренд!");
   }
   if (barInChannel)
   {
    SL = (MathAbs(conbuf.GetClose(TF.GetPeriod()).buffer[1] - open_buf[0]))/2;
    if (FilterBy19Lines(signalThis, TF.GetPeriod(), SL))
     if(signalThis != NO_SIGNAL && signalYoungTF != -signalThis)
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Получили сигнал SELL/BUY = %d", MakeFunctionPrefix(__FUNCTION__), signalThis));
      return signalThis;
     }
   }
  }
 }
 signalThis = NO_SIGNAL;
 return signalThis;
}

// возвращает следующий объект для младшего ТФ
CTimeframe *GetBottom(CTimeframe *curTF)
{
 if(curTF.GetPeriod()==PERIOD_M1)
  return curTF;
 CTimeframe *ctf;
 for(int i = dataTFs.Total()-1; i >= 0 ;i--)
 {
  ctf = dataTFs.At(i);
  if(ctf.GetPeriod() == curTF.GetPeriod())
  {
   ctf = dataTFs.At(i-1);
   return ctf;
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("Ошибка: %s не получилось взять младший период для %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(curTF.GetPeriod())));
 return(curTF);
}


// функция возвращает true, если последние два тренда в одну сторону и сонаправлены direction
bool TrendsDirection (CTimeframe *curTF, int direction)
{
 int index = GetIndexTF(curTF);
 CTrendChannel *trendForTF;
 trendForTF = trends.At(index);
 if(index!=-1)
 {
  if (trendForTF.GetTrendByIndex(0).GetDirection() == direction && trendForTF.GetTrendByIndex(1).GetDirection() == direction)
  {
   return (true); 
  }
  else
  {
   //Print("Нет двух трендов");
   return false;
  }
 }
 //Print("Что-то не то, может индекс = %d",index);
 return true; // возвращаем true, чтобы сломать шаблон при неверных вычислениях
}

// функция возвращает индекс ТФ , хранимого в массиве
int GetIndexTF(CTimeframe *curTF)
{
 int i;
 CTimeframe *masTF;
 for( i = 0; i <= dataTFs.Total(); i++)
 { 
  masTF = dataTFs.At(i);
  if(curTF.GetPeriod() == masTF.GetPeriod())
   return i;
 }
 return -1;
}

// функция для проверки, что бар закрылся внутри канала
bool LastBarInChannel (CTimeframe *curTF) 
{
 CTrendChannel *trendTF;
 int index = GetIndexTF(curTF);
 Print("index = ", index, "period = ",PeriodToString(curTF.GetPeriod()));
 trendTF = trends.At(index);
 double priceLineUp;
 double priceLineDown;
 double closePrice;
 datetime timeBuffer[];
 if (CopyTime(_Symbol, curTF.GetPeriod(), 1 , 1, timeBuffer) < 1) 
 {
  Print("Не удалось прогрузить буфер timeBuffer");
  log_file.Write(LOG_DEBUG, "Не удалось прогрузить буфер timeBuffer");
  return (false);
 }
 priceLineUp = trendTF.GetTrendByIndex(0).GetPriceLineUp(timeBuffer[0]);
 priceLineDown = trendTF.GetTrendByIndex(0).GetPriceLineDown(timeBuffer[0]);
 Print(" time = ", TimeToString(timeBuffer[0]));
 PrintFormat(" close = %f priceLineUp = %f priceLineDown = %f", conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
 if ( LessOrEqualDoubles(conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp) && GreatOrEqualDoubles(conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineDown))
 { 
  PrintFormat("Закрытие в канале close = %f priceLineUp = %f priceLineDown = %f", conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
  return (true);
 }
 return (false);
}

// возвращает true если расстоянеие до границы больше SL в 10 раз
bool FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss)
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
  log_file.Write(LOG_DEBUG, "Не удалось скопировать буферы уровней 19Lines");
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