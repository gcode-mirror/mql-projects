//+------------------------------------------------------------------+
//|                                         divergenceStochastic.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>                   // для сравнения вещественных чисел
#include <Constants.mqh>                        // библиотека констант
#include <Divergence/ExtrSTOCContainer.mqh>     // подключить класс контейнера
#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара

// константы сигналов
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//                 Класс CDivergenceSTOC предназначен для вычисления | 
//      стохастические расхождения/схождения на определенном участке |
//+------------------------------------------------------------------+

class CDivergenceSTOC       
{    
 private:
 int _handleSTOC;
 string _symbol;
 ENUM_TIMEFRAMES _timeframe;
 int _lastIndex;
 
 public:                       
 datetime timeExtrSTOC1;      // время появления первого экстремума стохастика
 datetime timeExtrSTOC2;      // время появления второго экстремума стохастика
 datetime timeExtrPrice1;     // время появления первого экстремума цены
 datetime timeExtrPrice2;     // время появления второго экстремума цены
 double   valueExtrSTOC1;     // значение первого экстремума стохастика
 double   valueExtrSTOC2;     // значение второго экстремума стохастика
 double   valueExtrPrice1;    // значение первого экстремума по ценам
 double   valueExtrPrice2;    // знечение второго экстремума по ценам
 double   closePrice;         // цена закрытия бара, на котором возник сигнал расхождения\схождения
 int      top_level;          // ограничительная зона "перекупленности"
 int      bottom_level;       // ограничительная зона "перепроданности"
 
 CExtrSTOCContainer *extrSTOC;                       // массив экстремумов STOC
 CisNewBar          isNewBar;                        // для проверки формирования нового бара

 
 CDivergenceSTOC();
 CDivergenceSTOC(int handleSTOC, string symbol, ENUM_TIMEFRAMES timeframe, int top_level, int bottom_level, int startIndex);
 ~CDivergenceSTOC();
 int countDivergence(int startIndex = 0, bool firstTimeUse = true);                   // основной функциональный модуль, высчитывющий расхождения             
 bool RecountExtremums(int startIndex, bool fill = false);
 void Reset(int startIndex);
};

CDivergenceSTOC:: CDivergenceSTOC(int handle, string symbol, ENUM_TIMEFRAMES timeframe, int _top_level, int _bottom_level, int startIndex)
{
 _handleSTOC   = handle;
 _symbol       = symbol;
 _timeframe    = timeframe;
 _lastIndex    = startIndex;
 top_level     = _top_level;
 bottom_level  = _bottom_level;
 isNewBar.isNewBar();
 extrSTOC = new CExtrSTOCContainer(_symbol, _timeframe, _handleSTOC, startIndex);
}
CDivergenceSTOC:: ~CDivergenceSTOC()
{
}

int CDivergenceSTOC::countDivergence(int startIndex = 0, bool ifirstTimeUse = true)
{                          
 double iHigh_buf[];
 double iLow_buf[];
 datetime date_buf[];
 int index_STOC_global_max;
 int index_Price_global_max;
 int index_STOC_global_min;
 int index_Price_global_min;
 int index_Price_local_max;
 int index_Price_local_min;
 
 ArrayResize(iHigh_buf, DEPTH_STOC);
 ArrayResize( iLow_buf, DEPTH_STOC);
 ArrayResize( date_buf, DEPTH_STOC);
 ArraySetAsSeries(iHigh_buf, true);
 ArraySetAsSeries( iLow_buf, true);
 ArraySetAsSeries( date_buf, true);
  
 
 int copiedHigh = -1;
 int copiedLow  = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedHigh = CopyHigh(_symbol, _timeframe, startIndex, DEPTH_STOC, iHigh_buf);
  copiedLow  = CopyLow(_symbol, _timeframe, startIndex, DEPTH_STOC, iLow_buf);
  copiedDate = CopyTime(_symbol, _timeframe, startIndex, DEPTH_STOC, date_buf); 
 }
 if ( copiedHigh != DEPTH_STOC || copiedLow != DEPTH_STOC || copiedDate != DEPTH_STOC)
 {
  Print(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", GetLastError());
  return(-2);
 }
 //-----------------------------------------------------------------------------------------------
 
 
  if(((isNewBar.isNewBar() > 0) && (startIndex ==0))||(startIndex > 0)) // Если пришел новый бар                    
  { 
  if(!extrSTOC.RecountExtremum(startIndex + 1, ifirstTimeUse)) // Пресчитаем экстремумы Стохастика
  {
   Print("Пересчет экстремумов неуспешен startIndex = ", startIndex);
   return(-2);
  }
  //if(date_buf[0] >= D'2015.01.27 00:00:00')
  //Print("value = ",(extrSTOC.getExtr(extrSTOC.getCount() - 1)).value , " index = ",extrSTOC.getExtr(extrSTOC.getCount() - 1).index, " time = ",extrSTOC.getExtr(extrSTOC.getCount() - 1).time, "startIndex ",startIndex, "date_buf[0] ", date_buf[0]); 
  
  }
  
  //--------------------------------------------------------------------------------------------
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 CExtremumSTOC *maxExtr = extrSTOC.maxExtr();

 index_Price_global_min = ArrayMinimum(iLow_buf, 0, WHOLE_ARRAY);
 CExtremumSTOC *minExtr = extrSTOC.minExtr();
 //------------------------РАСХОЖДЕНИЕ--------------------------------- 
 if(index_Price_global_max >= 0 && index_Price_global_max < BORDER_DEPTH)  
 { 
  //если максимум цены принадлежит последним трем барам
  if(maxExtr.value > top_level && maxExtr.index > BORDER_DEPTH)
  { //если максимум стохастика перешел границу "перекупленности" и находится в левой части
   for(int i = 0; extrSTOC.getExtr(i).index < maxExtr.index; i++)
   { //идем с права на лево в поисках мин. экстремума до maxExtr
    CExtremumSTOC *extr_temp = extrSTOC.getExtr(i);
    if(extr_temp.direction == 1 && extr_temp.value < top_level&& extr_temp.index <= BORDER_DEPTH)
    {// Если это экстремум максимума и он перешел границу перекупленности в обратном направлении
     // запоминаем и сохраняем индекс локального максимума цены
     index_STOC_global_max      =  extr_temp.index;
     index_Price_local_max      =  ArrayMaximum (iHigh_buf, BORDER_DEPTH, WHOLE_ARRAY);
     if (index_Price_local_max == BORDER_DEPTH) //|| maxExtr.index == BORDER_DEPTH)
     return (0);
     timeExtrPrice1   =  date_buf[index_Price_local_max];
     timeExtrPrice2   =  date_buf[index_Price_global_max];
     timeExtrSTOC1    =  date_buf[maxExtr.index];            //
     timeExtrSTOC2    =  date_buf[index_STOC_global_max];
     valueExtrPrice1  =  iHigh_buf[index_Price_local_max];
     valueExtrPrice2  =  iHigh_buf[index_Price_global_max];
     valueExtrSTOC1   =  maxExtr.value;                      //STOC_buf[maxExtr.index];
     valueExtrSTOC2   =  extr_temp.value;                    //iSTOC_buf[index_STOC_global_max];
     //Print("maxExtr.value = ", maxExtr.value, " maxExtr.index = ",maxExtr.index," maxExtr.time = ",maxExtr.time);
     delete maxExtr;
     delete minExtr;
     delete extr_temp;
     return(SELL);
    }   
   }
  }
 }

 //------------------------СХОЖДЕНИЕ--------------------------------- 

 if(index_Price_global_min >= 0 && index_Price_global_min < BORDER_DEPTH)  
 { 
  //если минимум цены принадлежит последним трем барам
  if(minExtr.value < bottom_level && minExtr.index > BORDER_DEPTH)
  { //если минимум стохастика перешел границу "перепроданности" и находится в левой части
   for(int i = 0; extrSTOC.getExtr(i).index < minExtr.index; i++)
   { //идем с права на лево в поисках мин. экстремума до minExtr
    CExtremumSTOC *extr_temp = extrSTOC.getExtr(i);
    if(extr_temp.direction == -1 && extr_temp.value > bottom_level && extr_temp.index <= BORDER_DEPTH)
    {// Если экстремум минимума и перешел границу перепроданности в обратном направлении
     // запоминаем и сохраняем индекс локального минимума цены
     index_STOC_global_min      =  extr_temp.index;
     index_Price_local_min      =  ArrayMinimum(iHigh_buf, BORDER_DEPTH, WHOLE_ARRAY);
     if (index_Price_local_min == BORDER_DEPTH) //|| minExtr.index == BORDER_DEPTH)
     return (0); // если локальный минимум найден на третьем баре (бывают оч короткие линии)
      
     timeExtrPrice1   =  date_buf[index_Price_local_min];
     timeExtrPrice2   =  date_buf[index_Price_global_min];
     timeExtrSTOC1    =  date_buf[minExtr.index];            //заменить на minExtr.time
     timeExtrSTOC2    =  date_buf[index_STOC_global_min];    //заменить на extr_temp.time
     valueExtrPrice1  =  iLow_buf[index_Price_local_min];
     valueExtrPrice2  =  iLow_buf[index_Price_global_min];
     valueExtrSTOC1   =  minExtr.value;                      //STOC_buf[maxExtr.index];
     valueExtrSTOC2   =  extr_temp.value;                    //iSTOC_buf[index_STOC_global_max];
     
     delete maxExtr;
     delete minExtr;
     delete extr_temp;        
     return(BUY);
    }   
   }
  }
 }
 return(0); 
}


//+----------------------------------------------------------------------------------------+
//|              RecountExtremums вызывает функцию RecountExtremums из массива экстремумов |                                                  |
//+----------------------------------------------------------------------------------------+
bool CDivergenceSTOC::RecountExtremums(int startIndex, bool fill = false)
{
 return (extrSTOC.RecountExtremum(startIndex, fill));
} 



//|    \              |
//|       \           |
//|           \       |
//|               \   |
//|                  \|
//|                   |  \
//|                   |
//|                   |
//|                   |   /
//|                   | /
//|                  /|
//|               /   |
//|            /      |
//|         /         |
//|      /            |
//|________local______|____globаl_

