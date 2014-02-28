//+------------------------------------------------------------------+
//|                                         divergenceStochastic.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>

//#define DEPTH_STOC 10
//#define ALLOW_DEPTH_FOR_PRICE_EXTR 3

struct PointDiv        
{                           
   datetime timeExtrSTOC1;  // время появления первого экстремума стохастика
   datetime timeExtrSTOC2;  // время появления второго экстремума стохастика
   datetime timeExtrPrice1; // время появления первого экстремума цен
   datetime timeExtrPrice2; // время появления второго экстремума цен
   double   valueExtrSTOC1; // значение первого экстремума стохастика
   double   valueExtrSTOC2; // значение второго экстремума стохастика
   double   valueExtrPrice1;// значение первого экстремума по ценам
   double   valueExtrPrice2;// знечение второго экстремума по ценам
};

PointDiv null = {0};

int divergenceSTOC(int handleSTOC, const string symbol, ENUM_TIMEFRAMES timeframe, int top_level, int bottom_level,int DEPTH_STOC,int ALLOW_DEPTH_FOR_PRICE_EXTR, PointDiv& div_point, int startIndex = 0)
{
 double iSTOC_buf[];                         
 double iHigh_buf[];
 double iLow_buf[];
 datetime date_buf[];
 int index_STOC_global_max;
 int index_Price_global_max;
 int index_STOC_global_min;
 int index_Price_global_min;
 int index_Price_local_max;
 int index_Price_local_min;
 
 ArrayResize(iSTOC_buf, DEPTH_STOC);
 ArrayResize(iHigh_buf, DEPTH_STOC);
 ArrayResize( iLow_buf, DEPTH_STOC);
 ArrayResize( date_buf, DEPTH_STOC);
 ArraySetAsSeries(iSTOC_buf, true);
 ArraySetAsSeries(iHigh_buf, true);
 ArraySetAsSeries( iLow_buf, true);
 ArraySetAsSeries( date_buf, true);

 int copiedSTOC = -1;
 int copiedHigh = -1;
 int copiedLow  = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedSTOC < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(handleSTOC, 0, startIndex, DEPTH_STOC, iSTOC_buf);
  copiedHigh = CopyHigh(symbol, timeframe, startIndex, DEPTH_STOC, iHigh_buf);
  copiedLow  =  CopyLow(symbol, timeframe, startIndex, DEPTH_STOC, iLow_buf);
  copiedDate = CopyTime(symbol, timeframe, startIndex, DEPTH_STOC, date_buf); 
 }
 if (copiedSTOC != DEPTH_STOC || copiedHigh != DEPTH_STOC || copiedLow != DEPTH_STOC || copiedDate != DEPTH_STOC)
 {
   Print(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", GetLastError());
   return(0);
 }
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_STOC_global_max =  ArrayMaximum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 index_Price_global_min = ArrayMinimum( iLow_buf, 0, WHOLE_ARRAY);
 index_STOC_global_min =  ArrayMinimum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 if(index_Price_global_max > 0 && index_Price_global_max < ALLOW_DEPTH_FOR_PRICE_EXTR)  
 { //если максимум цены принадлежит последним трем барам
  if(index_STOC_global_max > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_max-1)+startIndex) == 1 && iSTOC_buf[index_STOC_global_max] > top_level)
  { //если максимальное значение стохастика является экстремумом и лежит выше top_level
   for(int i = index_STOC_global_max - 3; i > 0; i--)
   { //идем начиная с глобального экстремума(-3 что бы найденный не совпал с глобальным)
     // Alert("ЕСТЬ ЭКСТРЕМУМ СТОХАСТИКА РАСХОЖДЕНИЯ - ",iSTOC_buf[i+1]," TOP LEVEL = ",top_level);
    if(isSTOCExtremum(handleSTOC, i+startIndex) == 1 && iSTOC_buf[i+1] < top_level)
    { //ища локальный ниже уровня top_level(+1 потому что isSTOCExtremum возваращет значение для предидущего бара)
    
     /*Alert("BEGIN: ", date_buf[DEPTH_STOC-1]);
     Alert(__FUNCTION__, ": Найдено РАСХОЖДЕНИЕ");
     Alert("index_global_Stoc = ", index_STOC_global_max, "time = ", date_buf[index_STOC_global_max], "; value = ", iSTOC_buf[index_STOC_global_max]);
     Alert("index_cur_extr = ", i, "time = ", date_buf[i]);
     Alert("index_global_price = ", index_Price_global_max, "; time = ", date_buf[index_Price_global_max], "; value = ", iHigh_buf[index_Price_global_max]);
     Alert("END: ", date_buf[0]);*/
     
  //   Alert("НАЙДЕНО РАСХОЖДЕНИЕ");
    
     // вычисляем второй экстремум локального максимума стохастика
     index_Price_local_max      =  ArrayMaximum (iHigh_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);
     if (index_Price_local_max == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_max == (DEPTH_STOC-1) )
      return 0;
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_max];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_max];
     div_point.timeExtrSTOC1    =  date_buf[index_STOC_global_max];
     div_point.timeExtrSTOC2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iHigh_buf[index_Price_global_max];
     div_point.valueExtrPrice2  =  iHigh_buf[index_Price_local_max];
     div_point.valueExtrSTOC1   =  iSTOC_buf[index_STOC_global_max];
     div_point.valueExtrSTOC2   =  iSTOC_buf[i+1];      
     
     return(1);
    }   
   }
  }
 }
 
 if(index_Price_global_min > 0 && index_Price_global_min < ALLOW_DEPTH_FOR_PRICE_EXTR)
 { //если минимум цены принадлежит последним трем барам
  if(index_STOC_global_min > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_min-1)+startIndex) == -1 && iSTOC_buf[index_STOC_global_min] < bottom_level)
  { //если максимальное значение стохастика является экстремумом и лежит ниже bottom_level
   for(int i = index_STOC_global_min - 3; i > 0; i--)
   { //идем начиная с глобального экстремума(-3 что бы найденный не совпал с глобальным)
    // Alert("ЕСТЬ ЭКСТРЕМУМ СТОХАСТИКА СХОЖДЕНИЯ - ",iSTOC_buf[i+1]," BOTTOM_LEVEL = ",bottom_level);   
    if(isSTOCExtremum(handleSTOC, i+startIndex) == -1 && iSTOC_buf[i+1] > bottom_level)
    { //ища локальный ниже уровня top_level(+1 потому что isSTOCExtremum возваращет значение для предидущего бара)
    
     /*Alert("BEGIN: ", date_buf[DEPTH_STOC-1]);
     Alert(__FUNCTION__, ": Найдено СХОЖДЕНИЕ");
     Alert("index_global_Stoc = ", index_STOC_global_min, "time = ", date_buf[index_STOC_global_min], "; value = ", iSTOC_buf[index_STOC_global_min]);
     Alert("index_cur_extr = ", i, "time = ", date_buf[i]);
     Alert("index_global_price = ", index_Price_global_min, "; time = ", date_buf[index_Price_global_min], "; value = ", iHigh_buf[index_Price_global_min]);
     Alert("END: ", date_buf[0]);*/
     
   //  Alert("НАЙДЕНО СХОЖДЕНИЕ");     
     
     // вычисляем второй экстремум локального минимума стохастика
     index_Price_local_min      =  ArrayMinimum (iLow_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);     
     if (index_Price_local_min == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_min == (DEPTH_STOC-1) )
      return 0;    
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_min];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_min];
     div_point.timeExtrSTOC1    =  date_buf[index_STOC_global_min];
     div_point.timeExtrSTOC2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iLow_buf[index_Price_global_min];
     div_point.valueExtrPrice2  =  iLow_buf[index_Price_local_min];
     div_point.valueExtrSTOC1   =  iSTOC_buf[index_STOC_global_min];
     div_point.valueExtrSTOC2   =  iSTOC_buf[i+1];  
     return(-1);
    }
   }
  }
 }   
 return(0); 
}

/////-------------------------------
/////-------------------------------
int isSTOCExtremum(int handleSTOC, int startIndex = 0, int precision = 6, bool LOG = false)
{
 //StartIndex >= 1, т.е. работает только с сформировавшимися барами
 if (startIndex < 1) return 0;
 double iSTOC_buf[3];
 datetime date_buffer[3];
 ArraySetAsSeries(iSTOC_buf, false);
 ArraySetAsSeries(date_buffer, false);
 int copiedSTOC = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedSTOC < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(handleSTOC, 0, startIndex, 3, iSTOC_buf);
  copiedDate = CopyTime(Symbol(), Period(), startIndex, 3, date_buffer);
 }
 if (copiedSTOC != 3 || copiedDate != 3)
 {
   Alert(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", GetLastError());
   return(0);
 }
 
 if (GreatDoubles(iSTOC_buf[1], iSTOC_buf[0], precision) && GreatDoubles(iSTOC_buf[1], iSTOC_buf[2], precision))
 {
  //Alert(StringFormat("#1 [0/%s] = %f; [1/%s] = %f; [2/%s] = %f", TimeToString(date_buffer[0]), iSTOC_buf[0], TimeToString(date_buffer[1]), iSTOC_buf[1], TimeToString(date_buffer[2]), iSTOC_buf[2]));
  return 1;
 }
 else if (LessDoubles(iSTOC_buf[1], iSTOC_buf[0], precision) && LessDoubles(iSTOC_buf[1], iSTOC_buf[2], precision))
 {
  //Alert(StringFormat("#-1 [0/%s] = %f; [1/%s] = %f; [2/%s] = %f", TimeToString(date_buffer[0]), iSTOC_buf[0], TimeToString(date_buffer[1]), iSTOC_buf[1], TimeToString(date_buffer[2]), iSTOC_buf[2]));
  return -1;
 }
 
 return 0;
}