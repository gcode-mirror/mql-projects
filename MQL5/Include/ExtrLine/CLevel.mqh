//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CExtremum.mqh>
#include <CompareDoubles.mqh>

#define ATR_PERIOD 30

struct SLevel
{
 SExtremum extr;
 double channel;
};

// Класс для линии уровня в индикаторе NineteenLines
class CLevel: public CExtremum
{
 private:
 double channel[ARRAY_SIZE];
 int _period_ATR_channel;
 double _percentageATR_channel;
 
 public:
 CLevel(string symbol, ENUM_TIMEFRAMES tf, int handle_atr, int period_ATR_channel, double percentageATR_channel);
~CLevel();

 bool RecountLevel(datetime start_pos_time = __DATETIME__, bool now = true);
 SLevel getLevel(int i);
 void SetHandleATR(int handle);
};

CLevel::CLevel(string symbol, ENUM_TIMEFRAMES tf, int handle_atr, int period_atr_channel, double percentageATR_channel):
               _period_ATR_channel (period_atr_channel),
               _percentageATR_channel (percentageATR_channel)
               {
                _symbol = symbol;
                _tf_period = tf;
                _handle_ATR = handle_atr;
                 SetPercentageATR();
                _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
               }
CLevel::~CLevel()
                {
                  
                }             

//-----------------------------------------------------------------
// Функция проверяет наличие новых экстремумов и в случае появления высчитывает для них ширину канала
//-----------------------------------------------------------------
bool CLevel::RecountLevel(datetime start_pos_time = __DATETIME__, bool now = true)
{
 int count_new_extrs = RecountExtremum(start_pos_time, now);
 if (count_new_extrs < 0) return(false);
 
 double aveBar = AverageBar(start_pos_time);
 if (aveBar > 0) _averageATR = aveBar; 
 double level_channel = (_averageATR * _percentageATR_channel)/2;
 
 if(level_channel == 0) return(false); // если не удалось посчитать канал считаем вызов неуспешным
 
 if(count_new_extrs == 1)               // в случае когда появился один экстремум на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 1; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[0] = level_channel;
 }
 
 if(count_new_extrs == 2)                // в случае когда появилось два экстремума на одном баре
 {
  for(int j = ARRAY_SIZE-1; j >= 2; j--)
  {
   channel[j] = channel[j-1];     
  }
  channel[1] = level_channel;
  channel[0] = level_channel;
 }
 return(true);     
}

//-----------------------------------------------------------------
// возвращает уровень
//-----------------------------------------------------------------
SLevel CLevel::getLevel(int i)
{
 SLevel result = {{0, -1}, 0};
 if(i < 0 || i >= ARRAY_SIZE) 
  return(result);
  
 result.extr = extremums[i];
 result.channel = channel[i];
 return(result);
}

void CLevel::SetHandleATR(int handle)
{
 if(handle != INVALID_HANDLE)
  _handle_ATR = handle;
}