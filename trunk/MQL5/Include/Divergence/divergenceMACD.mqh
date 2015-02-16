//+------------------------------------------------------------------+
//|                                               CDivergenceMACD.mqh |
//|                                              Copyright 2013, GIA |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>                // для сравнения вещественных переменных
#include <Constants.mqh>                     // подключаем библиотеку констант
#include <Divergence/ExtrMACDContainer.mqh>  // подключить класс контейнера



#define _Buy 1
#define _Sell -1

//+------------------------------------------------------------------+
//                 Класс CDivergenceMACD предназначен для вычисления | 
//                расхождения/схождения MACD на определенном участке |
//+------------------------------------------------------------------+

class CDivergenceMACD
{
   
private:
   CExtrMACDContainer *extremumsMACD; 
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   int _handleMACD;
public:
   datetime timeExtrMACD1;  // время появления первого экстремума MACD
   datetime timeExtrMACD2;  // время появления второго экстремума MACD
   datetime timeExtrPrice1; // время появления первого экстремума цен
   datetime timeExtrPrice2; // время появления второго экстремума цен
   double   valueExtrMACD1; // значение первого экстремума MACD
   double   valueExtrMACD2; // значение второго экстремума MACD
   double   valueExtrPrice1;// значение первого экстремума по ценам
   double   valueExtrPrice2;// знечение второго экстремума по ценам
   double   closePrice;     // цена закрытия бара (на котором возник сигнал схождения\расхождения)
   int      divconvIndex;   // индекс возникновения схождения\расхождения

   CDivergenceMACD();
   CDivergenceMACD(const string symbol, ENUM_TIMEFRAMES timeframe, int handleMACD, int startIndex, int depth);
   ~CDivergenceMACD();
   int countDivergence(int startIndex = 0);
   bool RecountExtremums(int startIndex, bool fill = false);
   datetime getLastExtrMaxTime();
   datetime getLastExtrMinTime();  
   datetime getLastExtrTime();   
};

CDivergenceMACD::CDivergenceMACD(const string symbol, ENUM_TIMEFRAMES timeframe, int handle, int startIndex, int depth)
{
 _timeframe = timeframe;
 _symbol = symbol;
 _handleMACD = handle;
 extremumsMACD = new CExtrMACDContainer(_symbol, _timeframe, _handleMACD, startIndex);  //создает контейнер экстремумов MACD
}
CDivergenceMACD::~CDivergenceMACD()
{
 delete extremumsMACD;
}

//+---------------------------------------------------------------------------------------------------------+
//                                     Вычисление наличия рассхождения/схождения с помощью countDivergence. | 
//    Расхождение считается на участке в 130 баров, разделенного в свою очередь на участки в 115 и 15 баров |
//                  Алгоритм ищет наличие верхних/нижних экстремумов для цены и MACD на каждом из участков, |
//                      при выполнении условий расхождения/схождения возвращает _Sell / _Buy соответсвенно. |
//+---------------------------------------------------------------------------------------------------------+

int CDivergenceMACD::countDivergence(int startIndex = 0)
{
 //отладка
 double iMACD_buf [DEPTH_MACD]  = {0};
 double iHigh_buf [DEPTH_MACD]  = {0};
 double iLow_buf  [DEPTH_MACD]  = {0};
 datetime date_buf[DEPTH_MACD]  = {0};
 double iClose_buf[DEPTH_MACD]  = {0};
 
 int index_MACD_global_max;
 int index_MACD_local_max;
 int index_Price_global_max;
 int index_Price_local_max;
 int index_MACD_global_min;
 int index_MACD_local_min;
 int index_Price_global_min;
 int index_Price_local_min;
 
 bool under_zero = false;
 bool over_zero = false;
 bool is_extr_exist = false;
 int i;
 
 int copiedMACD  = -1;
 int copiedHigh  = -1;
 int copiedLow   = -1;
 int copiedDate  = -1;
 int copiedClose = -1;
 
 for(int attemps = 0; attemps < 25 && copiedMACD < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedMACD  = CopyBuffer(_handleMACD, 0, startIndex, DEPTH_MACD, iMACD_buf);
  copiedHigh  = CopyHigh(_symbol, _timeframe, startIndex, DEPTH_MACD, iHigh_buf);
  copiedLow   = CopyLow (_symbol, _timeframe, startIndex, DEPTH_MACD, iLow_buf);
  copiedDate  = CopyTime(_symbol, _timeframe, startIndex, DEPTH_MACD, date_buf); 
  copiedClose = CopyClose(_symbol, _timeframe, startIndex, DEPTH_MACD, iClose_buf);
 }
 if (copiedMACD != DEPTH_MACD || copiedHigh != DEPTH_MACD || copiedLow != DEPTH_MACD || copiedDate != DEPTH_MACD || copiedClose != DEPTH_MACD)
 {
  int err;
  err = GetLastError();        
  Print(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", err);
  return(-2);
 } 
  
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);   //Вычисления индекса максимальной цены на участке
 index_Price_global_min = ArrayMinimum(iLow_buf,  0, WHOLE_ARRAY);   //Вычисления индекса минимальной цены на участке
 CExtremumMACD *extr_local_max = extremumsMACD.maxExtr();
 CExtremumMACD *extr_local_min = extremumsMACD.minExtr();
 //Comment("maxPrice = ", index_Price_global_max, " minPrice=",index_Price_global_min);
//+----------------------------------------------------------------------------+
//|                         *** РАСХОЖДЕНИЕ ***                                |                   
//+----------------------------------------------------------------------------+ 

 i = 0;
 if(index_Price_global_max >= REMAINS_MACD)  //Если индекс максимальной цены на последних 15 барах
 {
  if(extr_local_max.index > BORDER_DEPTH_MACD) //Если индекс максимального MACD на участке REMAINS
  {
   CExtremumMACD *tmpExtr;
   //сохранить индекс максимального MACD как индекс локального максимума MACD
   index_MACD_local_max = extr_local_max.index;
   for (is_extr_exist = false; i < extremumsMACD.getCount() || is_extr_exist; i++)   //Среди всех экстремумов MACD 
   {  
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == 1 && tmpExtr.index <= BORDER_DEPTH_MACD)  //Ищем экстремум MACD на последних 15 барах
    {
     //сохраняем индекс MACD как индекс глобального экстремума
     index_MACD_global_max = tmpExtr.index;
     is_extr_exist = true;
     i++;                  
     break;
    }
   }
      
   if(!is_extr_exist) return(0);            //если на последних 15 барах нет верхнего экстремума MACD
   
   for(under_zero = false; tmpExtr.index < index_MACD_local_max; i++) //Ищем нижний экстремум MACD между локальным и глобальным по индексу
   {
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == -1)
    {
     under_zero = true;
     break;
    }
   }
   if(!under_zero) return(0);      // если нет перехода на нижний экстремум
   
   for(int j = DEPTH_MACD - 1; j > DEPTH_MACD - 1 - index_MACD_global_max; j--)
   {
    if(iMACD_buf[j] >= extr_local_max.value)
    return (0);
   }
   
   //сохраняем индекс локального максимума цены
   index_Price_local_max = ArrayMaximum(iHigh_buf, 0, REMAINS_MACD); 
   //отображение индекса на массив date_buf   
   index_MACD_local_max = DEPTH_MACD - 1 - index_MACD_local_max;
   index_MACD_global_max = DEPTH_MACD - 1 - index_MACD_global_max;  
    
   //заполняем поля класса CDivergenceMACD
   timeExtrPrice1  = date_buf [index_Price_local_max];
   timeExtrPrice2  = date_buf [index_Price_global_max];    
   timeExtrMACD1   = date_buf [index_MACD_local_max];
   timeExtrMACD2   = date_buf [index_MACD_global_max];          
   valueExtrMACD1  = iMACD_buf[index_MACD_local_max];
   valueExtrMACD2  = iMACD_buf[index_MACD_global_max];
   valueExtrPrice1 = iHigh_buf[index_Price_local_max];
   valueExtrPrice2 = iHigh_buf[index_Price_global_max];
   closePrice      = iClose_buf[index_Price_global_max];
   divconvIndex    = index_Price_global_max;
   /*
   if(startIndex == 0)
   {
   Print("-------------------------РАСХОЖДЕНИЕ НА Sell-------------------- ");
   Print("---------------------------------Price-------------------------- ");
   Print("Время Price1 = ", timeExtrPrice1, "   где индекс этой цены = ", index_Price_local_max);
   Print("Цена Price1 = ", valueExtrPrice1);
   Print("Время Price2 = ", timeExtrPrice2, "   где индекс этой цены = ", index_Price_global_max);
   Print("Цена Price2 = ", valueExtrPrice2);
   Print("-----------------------------------MACD------------------------ ");
   Print("Время MACD1 = ", timeExtrMACD1 , "   индекс MACD1 = ", index_MACD_local_max);
   Print("Значение MACD1 = ", DoubleToString(valueExtrMACD1,5));
   Print("Время MACD2 = ", timeExtrMACD2 , "   индекс MACD2 = ", index_MACD_global_max);
   Print("Значение MACD2 = ", DoubleToString(valueExtrMACD2,5));
   Print("startIndex = ", startIndex);
   }*/
   return(_Sell);
  }
 }
 
// +----------------------------------------------------------------------------+
// |                         *** СХОЖДЕНИЕ ***                                  |                   
// +----------------------------------------------------------------------------+ 
 
 i = 0;
 if(index_Price_global_min >= REMAINS_MACD)  //Если индекс минимальной цены на последних 15 барах
 {
  if(extr_local_min.index > BORDER_DEPTH_MACD) //Если индекс минимальной MACD на участке REMAINS
  {
   CExtremumMACD *tmpExtr;
   //сохранить индекс локального минимума MACD
   index_MACD_local_min = extr_local_min.index;
   for (is_extr_exist = false; i < extremumsMACD.getCount() || is_extr_exist; i++)   //Ищем нижний экстремум MACD на участке от 0 до 15 
   {  
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == -1 && tmpExtr.index <= BORDER_DEPTH_MACD)  //Если нашли экстремум на последних 15 барах
    {
    //сохраняем индекс MACD как индекс глобального экстремума
    index_MACD_global_min = tmpExtr.index;
    is_extr_exist = true;
    i++;              
    break;
   }
  }
     
  if(!is_extr_exist) return(0);    //если на последних 15 барах нет нижнего экстремума 

  for(under_zero = false; tmpExtr.index < index_MACD_local_min; i++) //Ищем верхний экстремум MACD между локальным и глобальным по индексу
  {
   tmpExtr = extremumsMACD.getExtr(i);
   if(tmpExtr.direction == 1)
   {
    under_zero = true;
    break;
   }
  }
  if(!under_zero) return(0);  // если нет перехода на верхний экстремум
  
  for(int j = DEPTH_MACD - 1; j > DEPTH_MACD - 1 - index_MACD_global_min; j--)
  {
   if(iMACD_buf[j] <= extr_local_min.value)
   return (0);
  }    
  //сохраняем индекс локального минимума цены
  index_Price_local_min = ArrayMinimum(iLow_buf, 0, REMAINS_MACD); 
  
  //отображение индекса на массив date_buf    
  index_MACD_local_min = DEPTH_MACD - 1 - index_MACD_local_min;
  index_MACD_global_min = DEPTH_MACD - 1 - index_MACD_global_min;   
  
  //заполняем поля класса CDivergenceMACD
  timeExtrPrice1  = date_buf [index_Price_local_min];
  timeExtrPrice2  = date_buf [index_Price_global_min];    
  timeExtrMACD1   = date_buf [index_MACD_local_min];
  timeExtrMACD2   = date_buf [index_MACD_global_min];        
  valueExtrMACD1  = iMACD_buf[index_MACD_local_min];
  valueExtrMACD2  = iMACD_buf[index_MACD_global_min];
  valueExtrPrice1 = iLow_buf[index_Price_local_min];
  valueExtrPrice2 = iLow_buf[index_Price_global_min];
  closePrice      = iClose_buf[index_Price_global_min];
  divconvIndex    = index_Price_global_min;
  /*
   PrintFormat("PriceExtr1 = %s; PriceExtr2 = %s; MACDExtr1 = %s; MACDExtr2 = %s", TimeToString(div_point.timeExtrPrice1),
                                                                                   TimeToString(div_point.timeExtrPrice2),
                                                                                   TimeToString(div_point.timeExtrMACD1),
                                                                                   TimeToString(div_point.timeExtrMACD2));
                                                                                   */
    /*                                                                               
   if(startIndex == 0)
   {
   Print("----------------------РАСХОЖДЕНИЕ НА Buy----------------------- ");
   Print("----------------------------Price----------------------------- ");
   Print("Время Price1 = ", timeExtrPrice1, " где индекс этой цены = ", index_Price_local_min);
   Print("Цена Price1 = ", valueExtrPrice1);
   Print("Время Price2 = ", timeExtrPrice2, " где индекс этой цены = ", index_Price_global_min);
   Print("Цена Price2 = ", valueExtrPrice2);
   Print("----------------------------MACD---------------------------------- ");
   Print("Время MACD1 = ", timeExtrMACD1 , " индекс MACD1 = ", index_MACD_local_min);
   Print("Значение MACD1 = ", DoubleToString(valueExtrMACD1,5));
   Print("Время MACD2 = ", timeExtrMACD2 , " индекс MACD2 = ", index_MACD_global_min);
   Print("Значение MACD2 = ", DoubleToString(valueExtrMACD2,5));
   Print("startIndex = ", startIndex);
   }*/
  return(_Buy);
 }
}
 return(0); 
}
//+----------------------------------------------------------------------------------------+
//|              RecountExtremums вызывает функцию RecountExtremums из массива экстремумов |                                                  |
//+----------------------------------------------------------------------------------------+

bool CDivergenceMACD::RecountExtremums(int startIndex, bool fill = false)
{
 return (extremumsMACD.RecountExtremum(startIndex, fill));
} 

datetime CDivergenceMACD::getLastExtrMaxTime()
{
 datetime time = 0;
 if (extremumsMACD.getCount() > 0)
 {
   for(int i = 0; i < extremumsMACD.getCount(); i++)
   {
    CExtremumMACD *tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.value >= 0)
    {
    time = tmpExtr.time;
    return time;
    }
   } 
 }
 return(time);
}

datetime CDivergenceMACD::getLastExtrMinTime()
{
 datetime time = 0;
 if (extremumsMACD.getCount() > 0)
 {
   for(int i = 0; i < extremumsMACD.getCount(); i++)
   {
    CExtremumMACD *tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.value <= 0.0)
    {
    time = tmpExtr.time;
    return time;
    }
   } 
 }
 return(time);
}
datetime CDivergenceMACD::getLastExtrTime()
{
 datetime time = 0;
 if (extremumsMACD.getCount() > 0)
 {
  CExtremumMACD *tmpExtr = extremumsMACD.getExtr(0);
  time = tmpExtr.time;
  return time; 
 }
 return(time);
}