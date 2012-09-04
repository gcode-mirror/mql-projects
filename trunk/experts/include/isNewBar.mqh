//+------------------------------------------------------------------+
//|                                                     isNewBar.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//===============================================================================
// Функция контроля нового бара
//===============================================================================
bool isNewBar(int timeframe, string symb = "")
 {
  int index;
  if (symb == "") symb = Symbol();
  switch(timeframe)
  {
   case PERIOD_D1:
       index = 0;
       break;
   case PERIOD_H4:
       index = 1;
       break;
   case PERIOD_H1:
       index = 2;
       break;
   case PERIOD_M30:
       index = 3;
       break;
   case PERIOD_M15:
       index = 4;
       break;
   case PERIOD_M5:
       index = 5;
       break;
   case PERIOD_M1:
       index = 6;
       break;
   default:
       Alert("isNewBar: Вы ошиблись с таймфреймом");
       return(false);
  }
  
    static int PrevTime[7];
    if (PrevTime[index]==iTime(symb,timeframe,0)) return(false);
    PrevTime[index]=iTime(symb,timeframe,0);
    return(true);
}