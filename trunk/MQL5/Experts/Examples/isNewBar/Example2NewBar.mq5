//+------------------------------------------------------------------+
//|                                               Example2NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar current_chart; // экземпляр класса CisNewBar: текущий график

string          symbol;
ENUM_TIMEFRAMES period;

void OnInit()
  {
   current_chart.SetSymbol(Symbol());
   current_chart.SetPeriod(Period()); 

   symbol = current_chart.GetSymbol();
   period = current_chart.GetPeriod();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   string          comment;
//---
   int new_bars = current_chart.isNewBar();
   if(new_bars>0)
     {     
      comment=current_chart.GetComment();
      Print(symbol,GetPeriodName(period),comment);
      Print(symbol,GetPeriodName(period)," Количество новых баров=",new_bars," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
     }
  }

//+------------------------------------------------------------------+
//| возвращает строкое значение периода                              |
//+------------------------------------------------------------------+
string GetPeriodName(ENUM_TIMEFRAMES period)
  {
   if(period==PERIOD_CURRENT) period=Period();
//---
   switch(period)
     {
      case PERIOD_M1:  return(" M1 ");
      case PERIOD_M2:  return(" M2 ");
      case PERIOD_M3:  return(" M3 ");
      case PERIOD_M4:  return(" M4 ");
      case PERIOD_M5:  return(" M5 ");
      case PERIOD_M6:  return(" M6 ");
      case PERIOD_M10: return(" M10 ");
      case PERIOD_M12: return(" M12 ");
      case PERIOD_M15: return(" M15 ");
      case PERIOD_M20: return(" M20 ");
      case PERIOD_M30: return(" M30 ");
      case PERIOD_H1:  return(" H1 ");
      case PERIOD_H2:  return(" H2 ");
      case PERIOD_H3:  return(" H3 ");
      case PERIOD_H4:  return(" H4 ");
      case PERIOD_H6:  return(" H6 ");
      case PERIOD_H8:  return(" H8 ");
      case PERIOD_H12: return(" H12 ");
      case PERIOD_D1:  return(" Daily ");
      case PERIOD_W1:  return(" Weekly ");
      case PERIOD_MN1: return(" Monthly ");
     }
//---
   return("unknown period");
  }