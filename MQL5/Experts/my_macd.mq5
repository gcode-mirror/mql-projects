//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
/*подключение необходимых библиотек*/
#include <CompareDoubles.mqh>    //для сравнения действительных переменных
#include <Lib CisNewBar.mqh>     //для проверки баров
#include<TradeManager/TradeManager.mqh>

/*основные параметры для ввода пользователем*/
input int      TakeProfit=100;   //take profit
input int      StopLoss=100;     //stop loss
input double   orderVolume = 1;  //объем ордера
input ulong    magic = 111222;   //магическое число
input uint MACDSlowPeriod = 26;  //ввод периода медленного EMA
input uint MACDFastPeriod = 12;  //ввод периода быстрого ЕМА
/*параметры для ввода пользователем дополнительных параметров рассчета*/
input uint N=20;                 //большой промежуток
input uint n=5;                  //малый промежуток

/*динамические массивы для хранения  iMA, которые юзаются при вычислении MACD*/
double _macd[];                  //массив MACD
/*динамические массивы высоких и низких цен*/
double high[];                   //высокие цены
double low[];                    //низкие цены
datetime date_buffer[];          //буфер времени
/*хэндл MACD*/
int imacd;
/*классы для работы с программой*/
CisNewBar newCisBar;             //класс для проверки баров 
CTrade newTrade;                 //класс для работы с позициями
/*системные переменные*/
int takeProfit;                  //стоп лосс
int stopLoss;                    //тейк профит
int tN;                          //действительный N
int tn;                          //действительный n
double point = _Point;           //размер пункта
string sym = _Symbol;            //текущий символ
ENUM_TIMEFRAMES timeFrame=_Period;   //таймфрейм
/*переменные для хранения позиций экстремумов*/
uint index_maxhigh; //максимальное высокое в n промежутке
uint index_minlow;  //минимальное низкое в n промежутке
uint index_maxMACD_1; //максимальное MACD в n промежутке
uint index_minMACD_1; //минимальное MACD в n промежутке
/*прочие глобальные переменные*/
uint index;     //счетчик 
uint minus_zone; //изменение знака для high
uint plus_zone; //изменение знака для low
int mode;
CTradeManager new_trade; //класс продажи

uint slowper; //медленный период
uint fastper; //быстрый период
uint elem[2]={0,0};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*unum*/

enum SCAN_EXTR_TYPE {
MAX_EXTR=0,
MIN_EXTR
};

/*дополнительные функции*/

void PrintDeal(SCAN_EXTR_TYPE mytype) //выводит все основные показатели при совершении сделки
  {
  if (mytype == MAX_EXTR)
   {
   Print("Max = ",high[index_maxhigh]);
   Print("индекс максимума = ",index_maxhigh);
   PrintFormat("Правый Max MACD = %.06f",_macd[elem[0]]);
   Print("индекс правого MAX MACD = ",elem[0]);
   PrintFormat("Левый Мax MACD = %.06f",_macd[elem[1]]);
   Print("индекс левого MAX MACD = ",elem[1]);               
    }
   if (mytype == MIN_EXTR)
    {
   Print("Min = ",low[index_minlow]);
   Print("индекс минимума = ",index_minlow);
   PrintFormat("Правый Min MACD = %.06f",_macd[elem[0]]);
   Print("индекс правого MIN MACD = ",elem[0]);
   PrintFormat("Левый Мin MACD = %.06f",_macd[elem[1]]);
   Print("индекс левого MIN MACD = ",elem[1]);               
    }    
  }  

uint SearchForExtra (SCAN_EXTR_TYPE scanType,uint current_index)
  {
  switch (scanType)
  {
   case MAX_EXTR:
    if(GreatDoubles(_macd[current_index],_macd[current_index-1]) && GreatDoubles(_macd[current_index],_macd[current_index+1]) && _macd[current_index]>0)
     return  current_index; 
     break;
   case MIN_EXTR:
    if(GreatDoubles(_macd[current_index-1],_macd[current_index]) && GreatDoubles(_macd[current_index+1],_macd[current_index]) && _macd[current_index]<0)
     return current_index; 
     break;              
  }
    return elem[0];
  }
////////
//--------
/////////
bool WhatIsLarger (SCAN_EXTR_TYPE mytype,double val1,double val2) 
 {
 switch (mytype)
  {
   case MAX_EXTR:
    if(GreatDoubles(val1,val2))
     return false;
   break;
   case MIN_EXTR:
    if (GreatDoubles(val2,val1))
     return false;
   break;
  }
  return true;
 }
 


uint  GetDiscrepancy (SCAN_EXTR_TYPE scanType,uint top_index) //проверка на схождение
 {
  bool sign=false;        //знак промежуточной области
  elem[0] = 0;
  elem[1] = 0;     
  if (top_index<tn)  //если индекс максимальной или минимальной цены попал в n 
    {       
    for(index=1;index<tn && (elem[0]=SearchForExtra(scanType,index))==0;)
     index++;
           //ищем экстремум в n            
  if (elem[0]) //если экстремум найден в n
    {
    for(index=index+1; index<(tN-1) && (WhatIsLarger (scanType,_macd[SearchForExtra(scanType,index)],_macd[elem[0]]) ||  !sign) ;index++)
     {    
      if (scanType == MAX_EXTR && _macd[index]<0) sign=true;
      if (scanType == MIN_EXTR &&_macd[index]>0) sign=true; 
     }   
   if (index<(tN-1) && sign) 
     { 
     elem[1] = index;
     PrintDeal(scanType);                
     return index;
     }
  } 
}   
  return 0;
}  

/*функция открытия позиции */

  
//+------------------------------------------------------------------+
//|/*функция инициализации*/                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
/*проверка начальных параметров на действительность*/
 new_trade.Initialization(); //инициализация 
 
  if ( MACDSlowPeriod <= MACDFastPeriod || MACDFastPeriod < 3 )
   {
      Alert("Некорректно введены периоды! Выставлены по умолчанию 26 и 12 ");   
      slowper = 26;
      fastper = 12;
   }
  else 
   {
      slowper = MACDSlowPeriod;
      fastper = MACDFastPeriod;   
   } 

   if(n>=N || N<6) //если малый промежуток больше или равен всему промежутку
     {
      tn=5;
      tN=20;
      Alert("Некорректно введены N и n! N должна быть больше n. N=20 и n=5 по умолчанию");
     }
   else
     {
      tn=n;
      tN=N;
     }
/*инициализации индикатора MACD*/
   imacd=iMACD(sym,timeFrame,fastper,slowper,9,PRICE_CLOSE);
   if(imacd<0)
      return INIT_FAILED;

/*переворачивание массивов*/
   ArraySetAsSeries(_macd,true);       //переворачивается массив iMA(26) 
   ArraySetAsSeries(high, true);         //переворачивается массив high
   ArraySetAsSeries(low, true);          //переворачивается массив low
   ArraySetAsSeries(date_buffer,true);
/*объявления системных переменных*/

   stopLoss=StopLoss;
   takeProfit=TakeProfit;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| /*функция деинициализации*/                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
/*освобождение памяти под динамические массивы*/
   ArrayFree(_macd);
   ArrayFree(high);
   ArrayFree(low);
   ArrayFree(date_buffer);
     new_trade.Deinitialization();
  }


//+------------------------------------------------------------------+
//|/*функция,вызываемая при изменении котировки*/                    |
//+------------------------------------------------------------------+
void OnTick()
  {
 uint tmp_val;
 if(Bars(sym,timeFrame)>=tN && newCisBar.isNewBar()>0) //если количество баром больше N и создан новый бар
  {        
   if (CopyBuffer(imacd,0,1,tN,_macd)<=0 ) 
     {
      Alert("Не возможно скопировать буфер MACD");
      return;
     }
   if (CopyHigh(sym,0,1,tN,high)<=0 ) 
     {
      Alert("Не возможно скопировать буфер HIGH");
      return;
     }      
    if (CopyLow(sym,0,1,tN,low)<=0 ) 
     {
      Alert("Не возможно скопировать буфер LOW");
      return;
     }      
    if (CopyTime(sym,0,1,tN,date_buffer)<=0 ) 
     {
      Alert("Не возможно скопировать буфер даты и времени");
      return;
     }                  
/*начальные присвоения*/
  index_maxhigh=0; //максимальное высокое в n промежутке
  index_minlow=0;  //минимальное низкое в n промежутке
  index_maxMACD_1=0; //максимальное MACD в n промежутке
  index_minMACD_1=0; //минимальное MACD в n промежутке 
      // Цикл вычисляет максимальные значения цены
  for(index=1;index<tN;index++) //поиск индексов максимума и минимума
   {
    if(GreatDoubles(high[index],high[index_maxhigh]))index_maxhigh=index;
    if(GreatDoubles(low[index_minlow],low[index])) index_minlow=index; 
   }     
    //поиск экстремума максимума и минимума MACD     
     index_maxMACD_1 = GetDiscrepancy(MAX_EXTR,index_maxhigh);
     index_minMACD_1 = GetDiscrepancy(MIN_EXTR,index_minlow);         
    if (index_maxMACD_1>0 && index_minMACD_1>0)
      {
      if(index_maxMACD_1<index_minMACD_1)
       new_trade.OpenPosition(sym,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0);
    else
       new_trade.OpenPosition(sym,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
      }
    else if (index_maxMACD_1>0) 
      {
       new_trade.OpenPosition(sym,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
      }
    else if (index_minMACD_1>0)
      {
       new_trade.OpenPosition(sym,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0);
      } 
     }
  }
//+------------------------------------------------------------------+
