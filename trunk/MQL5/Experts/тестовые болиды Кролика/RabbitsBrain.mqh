//+------------------------------------------------------------------+
//|                                                 RabbitsBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>               // сравнение вещественных чисел
#include <StringUtilities.mqh>              // строковое преобразование
#include <CLog.mqh>                         // для лога
#include <Chicken/ContainerBuffers(NoPBI).mqh> //контейнер буферов цен на всех ТФ (No PBI) - для запуска в ТС
#include <CTrendChannel.mqh>                // трендовый контейнер
#include <Rabbit/TimeFrame.mqh>
#include <TradeManager/TradeManager.mqh> // 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // открытие позиции на продажу
 BUY  = 1,      // открытие позиции на покупку
 NO_SIGNAL = 0, // для действий, когда сигнала на открытие позиции не было
 DISCORD = 2,   // сигнал противоречия, "разрыв шаблона"
};

class CRabbitsBrain
{
 private:
  static double const trendPercent;
  // поля, доступ к которым реализован через функции Get...()
  int _handle19Lines;
  int _posOpenedDirection;
  int _indexPosOpenedTF;
  CTimeframe *_posOpenedTF; // тф, на котором была совершена сделка
  string _symbol;
  CContainerBuffers *_conbuf;
  CArrayObj *_trends;         // массив буферов трендов (для каждого ТФ свой буфер)
  CArrayObj *_dataTFs;        // массив ТФ, для торговли на нескольких ТФ одновременно
  CTrendChannel *trend;
  CTimeframe *ctf;
  double atr_buf[1], open_buf[1];   // Для функции GetSignal
  int handleATR;
  int handleDE;
  int _sl;
  ENUM_TIMEFRAMES TFs[3]; 
                    CTimeframe *GetBottom(CTimeframe *curTF);
                    bool LastBarInChannel (CTimeframe *curTF);
                    bool TrendsDirection (CTimeframe *curTF, int direction);
                    bool FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss);
                    

 public:
                     CRabbitsBrain(string symbol, CContainerBuffers *conbuf, CArrayObj *trends, CArrayObj *dataTFs);
                    ~CRabbitsBrain();
                    
                    int GetSignal();
                    int GetTradeSignal(CTimeframe *TF);
                    bool UpdateBuffers();
                    bool UpdateTrendsOnHistory(int i);
                    bool UpdateOnEvent(long lparam, double dparam, string sparam, int countPos);
                    int  GetIndexTF(CTimeframe *curTF);
                    void OpenedPosition(int ctmTotal);

                    int GetSL() {return _sl;}

                    

};
const double CRabbitsBrain::trendPercent = 0.1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRabbitsBrain::CRabbitsBrain(string symbol, CContainerBuffers *conbuf, CArrayObj *trends, CArrayObj *dataTFs)
{
 _symbol = symbol;
 //----------- Обработка индикатора NineTeenLines----------
 _handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
 if (_handle19Lines == INVALID_HANDLE)
  Print("Не удалось создать хэндл индикатора NineTeenLines");
/*
 for(int i = 0; i < ArraySize(TFs); i++)
 { 
  handleDE = iCustom(_Symbol,TFs[i],"DrawExtremums");
  if (handleDE == INVALID_HANDLE)
   PrintFormat("Не удалось создать хэндл индикатора DrawExtremums на %s", PeriodToString(TFs[i]));
  handleATR = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30));
  if (handleATR == INVALID_HANDLE)
   PrintFormat("Не удалось создать хэндл индикатора ATR на %s", PeriodToString(TFs[i]));
  ctf = new CTimeframe(TFs[i],_Symbol, handleATR);
  trend = new CTrendChannel(0,_Symbol,TFs[i],handleDE,trendPercent);
 } */
  

 _conbuf = conbuf;
 _trends = trends;         
 _dataTFs = dataTFs;
 _posOpenedDirection = 0;
 _sl = 0;
 _indexPosOpenedTF = -1;
 
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRabbitsBrain::~CRabbitsBrain()
  {
  }
//+------------------------------------------------------------------+

int CRabbitsBrain::GetSignal()
{  
 int signalForTrade;
 for(int i = _dataTFs.Total()-1; i >= 0; i--) // проходя по каждому таймфрему, начиная со старшего
 { 
  trend = _trends.At(i);                   
  if(!trend.UploadOnHistory())  // обновить буфер трендов на текущем ТФ
   return DISCORD;
  ctf = _dataTFs.At(i);         // получить текущий ТФ
  if(ctf.IsThisNewBar()>0)      // если на нем пришел новый бар
  {
   signalForTrade = GetTradeSignal(ctf); // считать сигнал на этом ТФ
   if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
   { 
    _posOpenedTF = ctf;
    _posOpenedDirection = signalForTrade;         // сохранить направление по которому была открыта сделка
    _indexPosOpenedTF = GetIndexTF(_posOpenedTF); // сохранить индекс ТФ в массиве dataTFs, на котором была открыта сделка
   }
   return signalForTrade;
  }
 } 
 return   DISCORD;
}
//+------------------------------------------------------------------+

//функция получения торгового сигнала (возвращает тип сигнала на ТФ или противоречие DISCORT "разрыв шаблона") 
int CRabbitsBrain::GetTradeSignal(CTimeframe *TF)  
{
 int signalThis = 0;
 int signalYoungTF;
 _sl = 0;
 if(TF.GetPeriod() == PERIOD_M1) // проверка на противоречия на младшем ТФ
 {
  signalYoungTF = 0;
 }
 else 
 {
  CTimeframe *tf = GetBottom(TF);
  signalYoungTF = GetTradeSignal(GetBottom(TF));

  if(signalYoungTF == 2)   //было найдено противоречие на младших Тф
   return DISCORD;
 }
 if( CopyOpen(_Symbol,TF.GetPeriod(), 1, 1, open_buf) < 1 ||
     CopyBuffer(TF.GetHandleATR(), 0, 1, 1, atr_buf) <1 )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при копировании цены открытия последнего бара или значения ATR", MakeFunctionPrefix(__FUNCTION__)));
  return DISCORD;
 }
 // тело бара больше среднего*К ?
 if(GreatDoubles(MathAbs(open_buf[0] - _conbuf.GetClose(TF.GetPeriod()).buffer[1]), atr_buf[0]*(1 + TF.GetRatio())))
 {
  if(open_buf[0] - _conbuf.GetClose(TF.GetPeriod()).buffer[1] > 0) // вычисление направления бара
   signalThis = SELL;
  else 
   signalThis = BUY;
   
  bool barInChannel = true;
  if(!TrendsDirection(TF, signalThis))  // направление двух последних соноправлено движению ?
  {
   if(TF.IsThisTrendNow())              // если сейчас есть тренд
    barInChannel = LastBarInChannel(TF);// проверка : пердыдущий бар закрыля в границах канала?
   if (barInChannel)                    // вычисление сл, а также проверка на 19 линий
   {
    _sl = (MathAbs(_conbuf.GetClose(TF.GetPeriod()).buffer[1] - open_buf[0]))/2;
    if (FilterBy19Lines(signalThis, TF.GetPeriod(), _sl))
     if(signalThis != NO_SIGNAL && signalYoungTF != -signalThis)
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Получили сигнал SELL/BUY = %d", MakeFunctionPrefix(__FUNCTION__), signalThis));
      return signalThis;
     }
   }
  }
 }
 signalThis = NO_SIGNAL;
 return signalThis; //возвращаем торговый сигнал
}

// возвращает следующий объект для младшего ТФ
CTimeframe *CRabbitsBrain::GetBottom(CTimeframe *curTF)
{
 if(curTF.GetPeriod() == PERIOD_M1)
  return curTF;
 CTimeframe *tf;
 for(int i = _dataTFs.Total()-1; i >= 0 ;i--)
 {
  tf = _dataTFs.At(i);
  if(tf.GetPeriod() == curTF.GetPeriod())
  {
   tf = _dataTFs.At(i-1);
   return tf;
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("Ошибка: %s не получилось взять младший период для %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(curTF.GetPeriod())));
 return(curTF);
}

// функция возвращает true, если последние два тренда в одну сторону и сонаправлены direction
bool CRabbitsBrain::TrendsDirection (CTimeframe *curTF, int direction)
{
 int index = GetIndexTF(curTF);
 CTrendChannel *trendForTF;
 trendForTF = _trends.At(index);
 if(index!=-1)
 {
  if (trendForTF.GetTrendByIndex(0).GetDirection() == direction && trendForTF.GetTrendByIndex(1).GetDirection() == direction)
  {
   return (true); 
  }
  else
  {
   Print("Нет двух трендов");
   return false;
  }
 }
 Print("Что-то не то, может индекс = %d",index);
 return true; // возвращаем true, чтобы сломать шаблон при неверных вычислениях
}


// функция для проверки, что бар закрылся внутри канала
bool CRabbitsBrain::LastBarInChannel (CTimeframe *curTF) 
{
 CTrendChannel *trendTF;
 int index = GetIndexTF(curTF);
 //Print("index = ", index, "period = ",PeriodToString(curTF.GetPeriod()));
 trendTF = _trends.At(index);
 double priceLineUp;
 double priceLineDown;
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
 PrintFormat(" close = %f priceLineUp = %f priceLineDown = %f", _conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
 if ( LessOrEqualDoubles(_conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp) && GreatOrEqualDoubles(_conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineDown))
 { 
  PrintFormat("Закрытие в канале close = %f priceLineUp = %f priceLineDown = %f", _conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
  return (true);
 }
 return (false);
}

// возвращает true если расстоянеие до границы больше SL в 10 раз
bool CRabbitsBrain::FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss)
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
 
 if (CopyBuffer(_handle19Lines,bufferLevel3,0,1,level3) < 1 || 
     CopyBuffer(_handle19Lines,bufferLevel4,0,1,level4) < 1)
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

// функция возвращает индекс ТФ , хранимого в массиве
int CRabbitsBrain::GetIndexTF(CTimeframe *curTF)
{
 int i;
 CTimeframe *masTF;
 for( i = 0; i <= _dataTFs.Total(); i++)
 { 
  masTF = _dataTFs.At(i);
  if(curTF.GetPeriod() == masTF.GetPeriod())
   return i;
 }
 return -1;
}

bool CRabbitsBrain::UpdateBuffers()
{ 
 if(_conbuf.Update())
  return true;
 else
  return false;
}
/*
bool CRabbitsBrain::UpdateTrendsOnHistory(int i)
{
 trend = _trends.At(i);
 if(!trend.UploadOnHistory())
  return false;
 else
  return true;
}*/

bool CRabbitsBrain::UpdateOnEvent(long lparam, double dparam, string sparam, int countPos)
{
 // проверка на разрыв шаблона. 
 // Если был обнаружен тренд в противоположную сторону, закрыть позицию.
 int newDirection;  
 bool closePosition = false;
 for(int i = 0; i < _dataTFs.Total(); i++)
 {  
  trend = _trends.At(i);
  trend.UploadOnEvent(sparam, dparam, lparam);
  ctf = _dataTFs.At(i);
  ctf.SetTrendNow(trend.IsTrendNow());
  // если пришел новый тренд и мы используем фильтр закрытия позиции по приходу противоположного тренда
  if (ctf.IsThisTrendNow())
  {
   newDirection = trend.GetTrendByIndex(0).GetDirection();
   // если пришел противоположный направлению позиции тренд
   if (i >= _indexPosOpenedTF && _posOpenedDirection != NO_SIGNAL && newDirection == -_posOpenedDirection && countPos > 0 ) // && ctf.GetPeriod() == posOpenedTF
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Закрыли позицию на OnChartEvent по противоположному тренду", MakeFunctionPrefix(__FUNCTION__)));
    // закрываем позицию 
    _posOpenedDirection = NO_SIGNAL;
    _posOpenedTF = ctf; 
    closePosition =  true;
   }
  }
 } 
 return closePosition;
}

void CRabbitsBrain::OpenedPosition(int ctmTotal)
{
 if(ctmTotal==0)
 {
  _posOpenedDirection = NO_SIGNAL;
 }
}