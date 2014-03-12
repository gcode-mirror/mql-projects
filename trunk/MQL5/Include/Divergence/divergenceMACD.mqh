//+------------------------------------------------------------------+
//|                                                   divergence.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill 6263  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>

#define DEPTH_MACD 100
#define BORDER_DEPTH_MACD 15

struct PointDivMACD        
{                           
   datetime timeExtrMACD1;  // врем€ по€влени€ первого экстремума MACD
   datetime timeExtrMACD2;  // врем€ по€влени€ второго экстремума MACD
   datetime timeExtrPrice1; // врем€ по€влени€ первого экстремума цен
   datetime timeExtrPrice2; // врем€ по€влени€ второго экстремума цен
   double   valueExtrMACD1; // значение первого экстремума MACD
   double   valueExtrMACD2; // значение второго экстремума MACD
   double   valueExtrPrice1;// значение первого экстремума по ценам
   double   valueExtrPrice2;// знечение второго экстремума по ценам
   double   closePrice;     // цена закрыти€ бара (на котором возник сигнал схождени€\расхождени€)
   int      divconvIndex;   // индекс возникновени€ схождени€\расхождени€
};
PointDivMACD nullMACD = {0};

/////-------------------------------
/////-------------------------------
int isMACDExtremum(int handleMACD, int startIndex, int precision = 8, bool LOG = false)
{ 
 double iMACD_buf[5];
 
 int copied = 0; 
 for(int attemps = 0; attemps < 25 && (copied = CopyBuffer(handleMACD, 0, startIndex, 5, iMACD_buf)) < 0; attemps++)
 {
  Sleep(100);
 }
 if(copied != 5)
 {
  int err = GetLastError();
  Alert(__FUNCTION__, "Ќе удалось скопировать буффер полностью.", copied, "/5. Error = ", err);
  return(0);
 }

 if (LOG) Alert("0[", (startIndex-4), "]=", iMACD_buf[0], "; 1[", (startIndex-3), "]=", iMACD_buf[1], "; 2[", (startIndex-2), "]=",  iMACD_buf[2], "; 3[", (startIndex-1), "]=",  iMACD_buf[3]);

 if ( GreatDoubles(iMACD_buf[2], iMACD_buf[0], precision) && GreatDoubles(iMACD_buf[2], iMACD_buf[1], precision) &&
      GreatDoubles(iMACD_buf[2], iMACD_buf[3], precision) && GreatDoubles(iMACD_buf[2], 0, precision) )
 {
  if (LOG) Alert("Ќашли новый максимум на MACD. 0[", (startIndex-4), "]=", NormalizeDouble(iMACD_buf[0], 8), "; 1[", (startIndex-3), "]=", NormalizeDouble(iMACD_buf[1], 8), "; 2[", (startIndex-2), "]=",  NormalizeDouble(iMACD_buf[2], 8), "; 3[", (startIndex-1), "]=",  NormalizeDouble(iMACD_buf[3], 8));
  return(1);
 }
 else if ( LessDoubles(iMACD_buf[2], iMACD_buf[0], precision) && LessDoubles(iMACD_buf[2], iMACD_buf[1], precision) && 
           LessDoubles(iMACD_buf[2], iMACD_buf[3], precision) && LessDoubles(iMACD_buf[2], 0, precision)) 
      {
       if (LOG) Alert("Ќашли новый минимум на MACD. 1(", (startIndex+1), ")=", iMACD_buf[1], "; 2(", (startIndex+2), ")=", iMACD_buf[2], "; 3(", (startIndex+3), ")=",  iMACD_buf[3], "; 4(", (startIndex+4), ")=",  iMACD_buf[4]);
       return(-1);     
      }
 if (LOG) Alert("Ќе найдено экстремумов");
 return(0);
}
/////-------------------------------
/////-------------------------------
int divergenceMACD(int handleMACD, const string symbol, ENUM_TIMEFRAMES timeframe, PointDivMACD& div_point, int startIndex = 0, bool LOG = false)
{
 
 double iMACD_buf [DEPTH_MACD]  = {0};
 double iHigh_buf [DEPTH_MACD]  = {0};
 double iLow_buf  [DEPTH_MACD]  = {0};
 datetime date_buf[DEPTH_MACD]  = {0};
 double iClose_buf[DEPTH_MACD]  = {0};
 
 int index_MACD_global_max;
 int index_Price_global_max;
 int index_Price_local_max;
 int index_MACD_global_min;
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
  copiedMACD  = CopyBuffer(handleMACD, 0, startIndex, DEPTH_MACD, iMACD_buf);
  copiedHigh  = CopyHigh(symbol,       timeframe, startIndex, DEPTH_MACD, iHigh_buf);
  copiedLow   = CopyLow (symbol,       timeframe, startIndex, DEPTH_MACD, iLow_buf);
  copiedDate  = CopyTime(symbol,       timeframe, startIndex, DEPTH_MACD, date_buf); 
  copiedClose = CopyClose(symbol,      timeframe, startIndex, DEPTH_MACD, iClose_buf);
 }
 if (copiedMACD != DEPTH_MACD || copiedHigh != DEPTH_MACD || copiedLow != DEPTH_MACD || copiedDate != DEPTH_MACD || copiedClose != DEPTH_MACD)
 {
   int err;
   if (LOG)
    { 
     err = GetLastError();
     Print(__FUNCTION__, "Ќе удалось скопировать буффер полностью. Error = ", err);
    }
   return(-2);
 }
 
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_Price_global_min = ArrayMinimum(iLow_buf,  0, WHOLE_ARRAY);
 

 //PrintFormat("%d %s / %s", startIndex, TimeToString(date_buf[0]), TimeToString(date_buf[DEPTH_MACD-1]));
 if ((DEPTH_MACD-BORDER_DEPTH_MACD) <= index_Price_global_max && index_Price_global_max < (DEPTH_MACD-1)  )       //сама€ высока€ цены находитс€ в последних 15 барах
 {
  //PrintFormat("%d %s", startIndex, "сама€ высока€ цены находитс€ в последних 15 барах");
  if(isMACDExtremum(handleMACD, startIndex) == 1) //если в текущий момент есть экстремум
  {
   is_extr_exist = false;
   for (i = 2; i <= (DEPTH_MACD-BORDER_DEPTH_MACD); i++)           //будем искать после первого экстремума дл€ того что бы MACD_global_max был экстремумом
   {
    if (isMACDExtremum(handleMACD, ((DEPTH_MACD-1)-i)+startIndex) == 1) 
    {
     is_extr_exist = true;
     break; 
    }
   }  
   if (!is_extr_exist) 
    return(0);  //если на всей истории начина€ с DEPTH до последних 15 баров не было экстремума
   
   index_MACD_global_max = ArrayMaximum(iMACD_buf, i-2, WHOLE_ARRAY);  
   for(i = index_MACD_global_max; i < DEPTH_MACD; i++)  //ищем было ли прохождение через 0 и возвращение назад 
   {
    if(iMACD_buf[i] < 0) 
    {
     under_zero = true;
     break;
    }//не провер€ем на выход из 0 так как в текущий момент есть положительный экстремум
   }
   if(!under_zero)                       
    return(0); //если не было прохождени€ через 0 то нас данна€ ситуаци€ уже не интересует
   
   if(LessDoubles(iMACD_buf[DEPTH_MACD-1], iMACD_buf[index_MACD_global_max]))  //на MACD: экстремум в текущий момент меньше глобального
   {
    index_Price_local_max    = ArrayMaximum(iHigh_buf,0,DEPTH_MACD-BORDER_DEPTH_MACD);
    if (index_Price_local_max == 0 || index_Price_local_max == (DEPTH_MACD-BORDER_DEPTH_MACD-1) )
     return (0);
    div_point.timeExtrPrice1  = date_buf [index_Price_local_max];
    div_point.timeExtrPrice2  = date_buf [index_Price_global_max];    
    div_point.timeExtrMACD1   = date_buf [index_MACD_global_max];
    div_point.timeExtrMACD2   = date_buf [DEPTH_MACD-3];
    div_point.valueExtrMACD1  = iMACD_buf[index_MACD_global_max];
    div_point.valueExtrMACD2  = iMACD_buf[DEPTH_MACD-3];
    div_point.valueExtrPrice1 = iHigh_buf[index_Price_local_max];
    div_point.valueExtrPrice2 = iHigh_buf[index_Price_global_max];
    div_point.closePrice      = iClose_buf[index_Price_global_max];
    div_point.divconvIndex    = index_Price_global_max;
    /*PrintFormat("PriceExtr1 = %s; PriceExtr2 = %s; MACDExtr1 = %s; MACDExtr2 = %s", TimeToString(div_point.timeExtrPrice1),
                                                                                    TimeToString(div_point.timeExtrPrice2),
                                                                                    TimeToString(div_point.timeExtrMACD1),
                                                                                    TimeToString(div_point.timeExtrMACD2));
   */ return(1);
   }
  }
 // else
 //  return(0);
 }
 
 if ((DEPTH_MACD-BORDER_DEPTH_MACD) <= index_Price_global_min && index_Price_global_min < (DEPTH_MACD-1) )       //сама€ низка€ цены находитс€ в последних 15 барах
 {
  if(isMACDExtremum(handleMACD, startIndex) == -1) //если в текущий момент есть экстремум
  {
   is_extr_exist = false;
   for (i = 2; i <= (DEPTH_MACD-BORDER_DEPTH_MACD); i++)           //будем искать после первого экстремума дл€ того что бы MACD_global_max был экстремумом
   {
    if (isMACDExtremum(handleMACD, ((DEPTH_MACD-1)-i)+startIndex) == -1) 
    {
     is_extr_exist = true;
     break;
    }
   }
   if (!is_extr_exist) 
    return(0);  //если на всей истории начина€ с DEPTH до последних 15 баров не было экстремума
 
   index_MACD_global_min = ArrayMinimum(iMACD_buf, i-2, WHOLE_ARRAY);  
   for(i = index_MACD_global_min; i < DEPTH_MACD; i++)  //ищем было ли прохождение через 0 
   {
    if(iMACD_buf[i] > 0) 
    {
     over_zero = true;
     break;
    }
   }
   if(!over_zero)
    return(0); //если не было прохождени€ через 0 то нас данна€ ситуаци€ уже не интересует
 
   if(GreatDoubles(iMACD_buf[DEPTH_MACD-1], iMACD_buf[index_MACD_global_min]))  //на MACD: экстремум в текущий момент меньше глобального
   {
    index_Price_local_min    = ArrayMinimum(iLow_buf,0,DEPTH_MACD-BORDER_DEPTH_MACD);  
    if (index_Price_local_min == 0 || index_Price_local_min == (DEPTH_MACD-BORDER_DEPTH_MACD-1) )
     return (0);      
    div_point.timeExtrPrice1  = date_buf [index_Price_local_min];
    div_point.timeExtrPrice2  = date_buf [index_Price_global_min];    
    div_point.timeExtrMACD1   = date_buf [index_MACD_global_min];
    div_point.timeExtrMACD2   = date_buf [DEPTH_MACD-3];
    div_point.valueExtrMACD1  = iMACD_buf[index_MACD_global_min];
    div_point.valueExtrMACD2  = iMACD_buf[DEPTH_MACD-3];
    div_point.valueExtrPrice1 = iLow_buf [index_Price_local_min];
    div_point.valueExtrPrice2 = iLow_buf [index_Price_global_min];
    div_point.closePrice      = iClose_buf[index_Price_global_min];
    div_point.divconvIndex    = index_Price_global_min;
  /*  PrintFormat("PriceExtr1 = %s; PriceExtr2 = %s; MACDExtr1 = %s; MACDExtr2 = %s", TimeToString(div_point.timeExtrPrice1),
                                                                                    TimeToString(div_point.timeExtrPrice2),
                                                                                    TimeToString(div_point.timeExtrMACD1),
                                                                                    TimeToString(div_point.timeExtrMACD2));    
  */  return(-1);
   }
  }
 // else
 //  return(0);
 }
    
 return(0); 
}