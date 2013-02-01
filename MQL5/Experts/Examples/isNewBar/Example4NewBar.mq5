//+------------------------------------------------------------------+
//|                                               Example4NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar current_chart;   // экземпляр класса CisNewBar: текущий график
CisNewBar gbpusd_M1_chart; // экземпляр класса CisNewBar: график gbpusd, период M1
CisNewBar usdjpy_M2_chart; // экземпляр класса CisNewBar: график usdjpy, период M2

datetime start_time;

void OnInit()
  {
   //--- инициализация членов класса для текущего графика:
   current_chart.SetSymbol(Symbol());
   current_chart.SetPeriod(Period()); 
   //--- инициализация членов класса для gbpusd, период M1:
   start_time=TimeCurrent();
   gbpusd_M1_chart.SetSymbol("GBPUSD");
   gbpusd_M1_chart.SetPeriod(PERIOD_M1); 
   //--- инициализация членов класса для usdjpy, период M2:
   usdjpy_M2_chart.SetSymbol("USDJPY");
   usdjpy_M2_chart.SetPeriod(PERIOD_M2); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   string          symbol;
   ENUM_TIMEFRAMES period;
   int             new_bars;
   string          comment;
//--- Исследуем экземпляр класса current_chart:
   symbol = current_chart.GetSymbol();       // Получаем имя символа графика, привязанного к данному экземпляру класса.
   period = current_chart.GetPeriod();       // Получаем период графика, привязанного к данному экземпляру класса.
   if(current_chart.isNewBar())              // Делаем запрос на обнаружение нового бара методом isNewBar(), привязанного к данному экземпляру класса
     {     
      comment=current_chart.GetComment();    // Получаем комментарий выполнения метода, который привязан к данному экземпляру класса.
      new_bars = current_chart.GetNewBars(); // Получаем количество обнаруженных новых баров, которые привязаны к данному экземпляру класса.
      Print(symbol,GetPeriodName(period),comment," Количество новых баров=",new_bars," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
      
      //--- Исследуем экземпляр класса gbpusd_M1_chart:
         symbol = gbpusd_M1_chart.GetSymbol();       // Получаем имя символа графика, привязанного к данному экземпляру класса.
         period = gbpusd_M1_chart.GetPeriod();       // Получаем период графика, привязанного к данному экземпляру класса.
         gbpusd_M1_chart.SetLastBarTime(start_time); // Инициализируем m_lastbar_time времененем старта советника
         if(gbpusd_M1_chart.isNewBar())              // Делаем запрос на обнаружение нового бара методом isNewBar(), привязанного к данному экземпляру класса
           {     
            new_bars = gbpusd_M1_chart.GetNewBars(); // Получаем количество обнаруженных новых баров, которые привязаны к данному экземпляру класса.
            Print(symbol,GetPeriodName(period)," Количество баров с момента старта советника=",new_bars," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }
      //---
      
      //--- Исследуем экземпляр класса gbpusd_M1_chart:
         symbol = usdjpy_M2_chart.GetSymbol();       // Получаем имя символа графика, привязанного к данному экземпляру класса.
         period = usdjpy_M2_chart.GetPeriod();       // Получаем период графика, привязанного к данному экземпляру класса.
         usdjpy_M2_chart.SetLastBarTime(0);          // Инициализируем m_lastbar_time нулевым значением, искусственно создаем ситуацию первого запуска
         if(usdjpy_M2_chart.isNewBar())              // Делаем запрос на обнаружение нового бара методом isNewBar(), привязанного к данному экземпляру класса
           {     
            new_bars = usdjpy_M2_chart.GetNewBars(); // Получаем количество обнаруженных новых баров, которые привязаны к данному экземпляру класса.
            Print(symbol,GetPeriodName(period)," Количество новых баров=",new_bars," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }     
         else
           {
            comment=usdjpy_M2_chart.GetComment();    // Получаем комментарий выполнения метода, который привязан к данному экземпляру класса.
            uint error=usdjpy_M2_chart.GetRetCode(); // Получаем номер ошибки, привязанный к данному экземпляру класса.
            Print(symbol,GetPeriodName(period),comment," Ошибка ",error," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }
     }
   else
     {
      uint error=current_chart.GetRetCode(); // Получаем номер ошибки, привязанный к данному экземпляру класса.
      if(error!=0)
        {
         comment=current_chart.GetComment();    // Получаем комментарий выполнения метода, который привязан к данному экземпляру класса.
         Print(symbol,GetPeriodName(period),comment," Ошибка ",error," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
        }
     }
  }

//+------------------------------------------------------------------+
//| возвращает строковое значение периода                            |
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
  
/*     else
     {
      uint error=current_chart.GetRetCode();
      if(error!=0)
        {
         Print(symbol,GetPeriodName(period),comment," Ошибка ",error," Время=",TimeToString(TimeCurrent(),TIME_SECONDS));
        }
     }*/