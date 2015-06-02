//+------------------------------------------------------------------+
//|                                             ContainerBuffers.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#define DEPTH_MAX 25
#define DEPTH_MIN 4


#include <Lib CisNewBarDD.mqh>
#include <CLog.mqh>                   // для лога
#include <StringUtilities.mqh>

class CBufferTF : public CObject      // не лучше ли добавить handle сюда?
{
 private:
 ENUM_TIMEFRAMES  tf;               // таймфрейм хранимого буфера данных
 bool             dataAvailable;    // информации о достоверности последнего копирования (отладка)

 public:
         double   buffer[];         // буфер данных (может быть стоит использовать статический)
         CBufferTF(ENUM_TIMEFRAMES period, bool dAvailable = true){tf = period; dataAvailable = dAvailable;}
         ENUM_TIMEFRAMES GetTF()  {return tf;}
         bool isAvailable()       {return dataAvailable;}   // отладка
         void SetAvailable(bool value){dataAvailable = value;}
         
};
//+------------------------------------------------------------------------------------------------+
//|    Класс  ContainerBuffers предназанчен для хранения актуальных данных по таким буферам как:   |
//|      bufferHigh                                                                                |
//|         bufferLow                                                                              |
//|            bufferPBI                                                                           |
//|               bufferClose                                                                      |
//|    Для использования контейнера, необходимо его объявить в роботе, для каждого тф              |
//|                                                и обновлять на каждом тике с помощью Update().  |
//|        ВАЖНО: Копирование буферов HIGH и LOW производится на глубину  DEPTH_MAX                |
//|               Копирование буферов CLOSE и PBI производится на глубину  DEPTH_MIN               |
//|               Если используется верхний тф не забыть передать его вместе с остальными          |
//|        Копирвание всех значений производится на каждом новом баре для каждого таймфрейма       |
//|      Обновление значений на текущем баре производится на каждом тике                           |
//                                                                                                 |      
//+------------------------------------------------------------------------------------------------+
class CContainerBuffers
{
 private: 
 CArrayObj  *_bufferHigh; // массив буферов High на всех таймфреймах
 CArrayObj  *_bufferLow;  // массив буферов Low на всех таймфреймах
 CArrayObj  *_bufferPBI;  // массив буферов PBI на всех таймфреймах
// CArrayObj  *_bufferATR;// массив буферов ATR на всех таймфреймах
 CArrayObj  *_bufferClose;// массив буферов Close на всех таймфреймах
 CArrayObj  *_allNewBars; // массив newbars для каждого Тф
 
 int     _handlePBI[];    // массив хэндлов PBI
// int     _handleATR[];  // массив хэндлов ATR
 int     _tfCount;        // количесвто Тф
 
 bool    _handleAvailable[];
 double  tempBuffer[];
 bool    recalculate;
 
 ENUM_TIMEFRAMES _TFs[];
 
 public:
                     CContainerBuffers(ENUM_TIMEFRAMES &TFs[]);
                    ~CContainerBuffers();
               
               bool Update();
               bool isAvailable(ENUM_TIMEFRAMES period);     
               CBufferTF *GetHigh (ENUM_TIMEFRAMES period);
               CBufferTF *GetLow  (ENUM_TIMEFRAMES period);
               CBufferTF *GetClose(ENUM_TIMEFRAMES period);
               CBufferTF *GetPBI  (ENUM_TIMEFRAMES period);
               CBufferTF *GetATR  (ENUM_TIMEFRAMES period);   // пока не используется ATR, коментарии + isAvailable
               CisNewBar *GetNewBar(ENUM_TIMEFRAMES period);
                
};
//+------------------------------------------------------------------+
//|      Класс                                                            |
//+------------------------------------------------------------------+
CContainerBuffers::CContainerBuffers(ENUM_TIMEFRAMES &TFs[])
{
 ArrayCopy(_TFs, TFs);           //не особо нужно пока
 _tfCount =  ArraySize(TFs);
 _bufferHigh  = new CArrayObj();
 _bufferLow   = new CArrayObj();
 _bufferPBI   = new CArrayObj();
// _bufferATR   = new CArrayObj();
 _bufferClose = new CArrayObj();
 _allNewBars  = new CArrayObj();
 ArrayResize(_handlePBI,_tfCount);
// ArrayResize(_handleATR,_tfCount);
 ArrayResize(_handleAvailable,_tfCount);
 for(int i = 0; i < _tfCount; i++)
 {
  _bufferHigh.Add(new CBufferTF(TFs[i]));
  _bufferLow.Add (new CBufferTF(TFs[i]));
  _bufferPBI.Add (new CBufferTF(TFs[i]));
//  _bufferATR.Add (new CBufferTF(TFs[i]));
  _bufferClose.Add(new CBufferTF(TFs[i]));
  _allNewBars.Add(new CisNewBar(_Symbol,_TFs[i]));
   GetNewBar(TFs[i]).isNewBar();
  _handleAvailable[i] = true;
  _handlePBI[i] = iCustom(_Symbol, TFs[i], "PriceBasedIndicator");
  if (_handlePBI[i] == INVALID_HANDLE)
  {
   log_file.Write(LOG_DEBUG, "Не удалось создать хэндл индикатора PriceBasedIndicator");
   Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
   _handleAvailable[i] = false;
  }
  /* _handleATR[i] = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30));
  if (_handleATR[i] == INVALID_HANDLE)
  {
   log_file.Write(LOG_DEBUG, "Не удалось создать хэндл индикатора ATR");
   Print("Не удалось создать хэндл индикатора ATR");
   _handleAvailable[i] = false;
  }*/
 }
 recalculate = true;
 Update();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CContainerBuffers::~CContainerBuffers()
{
 for(int i = 0; i < _tfCount; i++)
 {
  delete GetClose(_TFs[i]);
  delete GetHigh(_TFs[i]);
  delete GetLow(_TFs[i]);
  delete GetPBI(_TFs[i]);
  //delete GetATR(_TFs[i]);
  delete GetNewBar(_TFs[i]);
  IndicatorRelease(_handlePBI[i]);
  //IndicatorRelease(_handleATR[i]);
 }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CContainerBuffers::Update()
{
 for(int i = 0; i < _tfCount; i++)
 { 
  if(_handleAvailable[i])
  {
   CBufferTF *bufferHigh =  _bufferHigh.At(i);
   CBufferTF *bufferLow  =  _bufferLow.At(i);
   CBufferTF *bufferPBI  =  _bufferPBI.At(i);
// CBufferTF *bufferATR  =  _bufferATR.At(i);
   CBufferTF *bufferClose = _bufferClose.At(i);
   ArraySetAsSeries(bufferHigh.buffer, true);
   ArraySetAsSeries(bufferLow.buffer, true);
   ArraySetAsSeries(bufferPBI.buffer, true);
// ArraySetAsSeries(bufferATR.buffer, true);
   ArraySetAsSeries(bufferClose.buffer, true); 
   if(GetNewBar(_TFs[i]).isNewBar()||recalculate)
   { 
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 0, DEPTH_MAX, bufferHigh.buffer)   < DEPTH_MAX) // цена закрытия последнего сформированного бара
    {
     bufferHigh.SetAvailable(false); 
     log_file.Write(LOG_DEBUG,StringFormat("%s Ошибка при копировании буфера High на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF())));
     PrintFormat("%s Ошибка при копировании буфера High на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF()));
     return false;
    } 
    if(CopyLow(_Symbol, bufferLow.GetTF(), 0, DEPTH_MAX, bufferLow.buffer) < DEPTH_MAX )     // буфер максимальных цен всех сформированных баров на заданую глубину
    {
     bufferLow.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s Ошибка при копировании буфера Low на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF())));
     PrintFormat("%s Ошибка при копировании буфера Low на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF()));
     return false;
    }   
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, DEPTH_MIN, bufferClose.buffer)   < DEPTH_MIN)     // буфер минимальных цен всех сформированных баров на заданую глубину
    {
     bufferClose.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s Ошибка при копировании буфера Close на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF())));
     PrintFormat("%s Ошибка при копировании буфера Close на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF()));
     return false;
    }   
    if(CopyBuffer(_handlePBI[i], 4, 0, DEPTH_MIN, bufferPBI.buffer)      < DEPTH_MIN)          // последнее полученное движение
    {
     bufferPBI.SetAvailable(false);
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при копировании буфера PBI на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF())));
     PrintFormat("%s Ошибка при копировании буфера PBI на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF()));
     return false;
    }
     bufferHigh.SetAvailable(true);
      bufferLow.SetAvailable(true);
       bufferClose.SetAvailable(true);
        bufferPBI.SetAvailable(true);
    /*if(CopyBuffer(_handleATR[i], 4, 1, 1, bufferATR.buffer)      < 1)   // значение ATR
    {
     bufferATR.SetAvailable(false);
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при копировании буфера ATR на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferATR.GetTF())));
     PrintFormat("%s Ошибка при копировании буфера ATR на периоде %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferATR.GetTF()));
     return false;
    }*/
   }
   else
   {
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 0, 1, tempBuffer) == 1)
     bufferHigh.buffer[0] = tempBuffer[0];
    if(CopyLow(_Symbol, bufferLow.GetTF(), 0, 1, tempBuffer))
     bufferLow.buffer[0] = tempBuffer[0];
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, 1, tempBuffer))
     bufferClose.buffer[0] = tempBuffer[0];
    if(CopyBuffer(_handlePBI[i], 4, 0, 1, tempBuffer))
     bufferPBI.buffer[0] = tempBuffer[0];
    /*if(CopyBuffer(_handleATR[i], 4, 0, 1, tempBuffer))
     bufferATR.buffer[0] = tempBuffer[0];*/
   }
  }
  else 
  {
   _handlePBI[i] = iCustom(_Symbol, _TFs[i], "PriceBasedIndicator");
   if (_handlePBI[i] == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, "Не удалось создать хэндл индикатора PriceBasedIndicator");
    Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
    recalculate = true;
    return false;
   }
   /*else if (_handleATR[i] == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, "Не удалось создать хэндл индикатора ATR");
    Print("Не удалось создать хэндл индикатора ATR");
    recalculate = true;
    return false;
   }*/
   else
   {
    _handleAvailable[i] = true;
    recalculate = false;
    return false;
   }
  }
 }
 recalculate = false;
 return true;
}


//+-------------------------------------------------------+
//| Удалить метод и dataAvailable, при корректной работе  |
//|  контейнера на роботе с Update()                      |
//+-------------------------------------------------------+
bool CContainerBuffers::isAvailable(ENUM_TIMEFRAMES period)
{
 bool result;
 CBufferTF *btf;
 for ( int i = 0; i < _tfCount; i++)
 { 
  if(_TFs[i] == period)
  {
   btf = _bufferHigh.At(i);
   result = btf.isAvailable();
   btf = _bufferLow.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferClose.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferPBI.At(i);
   result = (result && btf.isAvailable());
   return result;
  }
 }
 return false;
}

CBufferTF *CContainerBuffers::GetHigh (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferHigh.At(i);
   return btf;
  }
 }
 PrintFormat("Не удалось получить данные с GetHigh  на %s", PeriodToString(period));
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetLow  (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferLow.At(i);
   return btf;
  }
 }
 PrintFormat("Не удалось получить данные с GetLow  на %s", PeriodToString(period));  
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetClose(ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferClose.At(i);
   return btf;
  }
 }
 PrintFormat("Не удалось получить данные с GetClose  на %s", PeriodToString(period)); 
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetPBI (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferPBI.At(i);
   return btf;
  }
 }
 PrintFormat("Не удалось получить данные с GetPBI  на %s", PeriodToString(period));
 return new CBufferTF(period, false);
}

/*CBufferTF *CContainerBuffers::GetATR (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferATR.At(i);
   return btf;
  }
 }
 PrintFormat("Не удалось получить данные с GetPBI  на %s", PeriodToString(period));
 return new CBufferTF(period, false);
}*/

CisNewBar *CContainerBuffers::GetNewBar(ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
   return _allNewBars.At(i);
 }
 PrintFormat("Не удалось получить данные с GetNewBar  на %s", PeriodToString(period));
 return new CisNewBar(_Symbol, period);
}