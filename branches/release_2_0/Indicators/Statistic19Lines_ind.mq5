//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <ExtrLine/CExtremumCalc.mqh>
#include <Lib CisNewBar.mqh>

 enum LevelType
 {
  EXTR_MN, 
  EXTR_W1,
  EXTR_D1,
  EXTR_H4,
  EXTR_H1
 };
 
 input int epsilon = 25;          //Погрешность для поиска экстремумов
 input int depth = 25;            //Глубина поиска трех экстремумов
 input int period_ATR = 100;      //Период ATR
 input double percent_ATR = 0.03; //Ширина канала уровня в процентах от ATR 

 input LevelType level  = EXTR_H4;
 input color     color_level = clrRed;

 CExtremumCalc calc(epsilon, depth);

 SExtremum estruct[3];
 
 CisNewBar NewBarLevel(Symbol());
 CisNewBar NewBarCurr (Symbol(), Period());

 string symbol = Symbol();
 ENUM_TIMEFRAMES period_current = Period();
 ENUM_TIMEFRAMES period_level;
 int handle_ATR;
 double buffer_ATR [];
 
 bool level_one_UD   = false;
 bool level_one_DU   = false;
 bool level_two_UD   = false;
 bool level_two_DU   = false;
 bool level_three_UD = false;
 bool level_three_DU = false;
 
 int count_DUU = 0;
 int count_DUD = 0;
 int count_UDD = 0;
 int count_UDU = 0;
 
 bool first = true;
 //+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 period_level = GetTFbyLevel(level);
 if(depth < 10) return(INIT_PARAMETERS_INCORRECT);
 handle_ATR = iATR(symbol, period_level, period_ATR);
 NewBarLevel.SetPeriod(period_level);

 //SetInfoTabel();

//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 PrintFormat("DUU = %d; DUD = %d; UDU = %d; UDD = %d", __FUNCTION__, count_DUU, count_DUD, count_UDU, count_UDD);
 //SavePorabolistic("STATISTIC_19LINES.txt");
 IndicatorRelease(handle_ATR);
 ArrayFree(buffer_ATR);
 //DeleteExtrLines(GetTFbyLevel(level));
 //DeleteInfoTabel();
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   bool load = FillATRbuffer();
 
   if(load)
   {
    if(first)
    {
     FillThreeExtr(symbol, period_level, calc, estruct, buffer_ATR, TimeCurrent());
     PrintFormat("%s one = %f; two = %f; three = %f", TimeToString(TimeCurrent()), estruct[0].price, estruct[1].price, estruct[2].price);
     CreateExtrLines(estruct, period_level, color_level);
     first = false;
    }//end first
    
    if(NewBarLevel.isNewBar() > 0)
    {
      FillThreeExtr(symbol, period_level, calc, estruct, buffer_ATR, TimeCurrent());
      PrintFormat("%s one = %f; two = %f; three = %f", TimeToString(TimeCurrent()), estruct[0].price, estruct[1].price, estruct[2].price);
      MoveExtrLines(estruct, period_level);
      PrintFormat("DUU = %d; DUD = %d; UDU = %d; UDD = %d", count_DUU, count_DUD, count_UDU, count_UDD);
    }
    if(NewBarCurr.isNewBar() > 0)
    {
     CalcStatistic();
    }
    
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID графика
                 const string          name="HLine",      // имя линии
                 const int             sub_window=0,      // номер подокна
                 double                price=0,           // цена линии
                 const color           clr=clrRed,        // цвет линии
                 const int             width=1,           // толщина линии
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линии
                 const bool            back=true          // на заднем плане
                )      
{
//--- если цена не задана, то установим ее на уровне текущей цены Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
 ResetLastError();
//--- создадим горизонтальную линию
 if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
 {
  Print(__FUNCTION__, ": не удалось создать горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- установим цвет линии
 ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- установим стиль отображения линии
 ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- установим толщину линии
 ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- отобразим на переднем (false) или заднем (true) плане
 ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- успешное выполнение
 return(true);
}

bool HLineMove(const long   chart_ID=0,   // ID графика
               const string name="HLine", // имя линии
               double       price=0)      // цена линии
{
//--- если цена линии не задана, то перемещаем ее на уровень текущей цены Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- сбросим значение ошибки
 ResetLastError();
//--- переместим горизонтальную линию
 if(!ObjectMove(chart_ID,name,0,0,price))
 {
  Print(__FUNCTION__, ": не удалось переместить горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

bool HLineDelete(const long   chart_ID=0,   // ID графика
                 const string name="HLine") // имя линии
{
//--- сбросим значение ошибки
 ResetLastError();
//--- удалим горизонтальную линию
 if(!ObjectDelete(chart_ID,name))
 {
  Print(__FUNCTION__, ": не удалось удалить горизонтальную линию! Код ошибки = ",GetLastError());
  return(false);
 }
//--- успешное выполнение
 return(true);
}

void FillThreeExtr (string symbol, ENUM_TIMEFRAMES tf, CExtremumCalc &extrcalc, SExtremum &resArray[], double &buffer_ATR[], datetime start_pos_time)
{
 extrcalc.FillExtremumsArray(symbol, tf, start_pos_time);
 if (extrcalc.NumberOfExtr() < 3)
 {
  Alert(__FUNCTION__, "Не удалось рассчитать три экстремума на таймфрейме ", EnumToString((ENUM_TIMEFRAMES)tf));
  return;
 }
  
 int count = 0;
 for(int i = 0; i < depth && count < 3; i++)
 {
  if(extrcalc.getExtr(i).price > 0)
  {
   resArray[count] = extrcalc.getExtr(i);
   resArray[count].channel = (buffer_ATR[i]*percent_ATR)/2;
   count++;
  }
 }
}

void CreateExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";
 //PrintFormat("");
 HLineCreate(0, name+"one"   , 0, te[0].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"one+"  , 0, te[0].price+te[0].channel, clr, 2);
 HLineCreate(0, name+"one-"  , 0, te[0].price-te[0].channel, clr, 2);
 HLineCreate(0, name+"two"   , 0, te[1].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"two+"  , 0, te[1].price+te[1].channel, clr, 2);
 HLineCreate(0, name+"two-"  , 0, te[1].price-te[1].channel, clr, 2);
 HLineCreate(0, name+"three" , 0, te[2].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"three+", 0, te[2].price+te[2].channel, clr, 2);
 HLineCreate(0, name+"three-", 0, te[2].price-te[2].channel, clr, 2);
}

void MoveExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   , te[0].price);
 HLineMove(0, name+"one+"  , te[0].price+te[0].channel);
 HLineMove(0, name+"one-"  , te[0].price-te[0].channel);
 HLineMove(0, name+"two"   , te[1].price);
 HLineMove(0, name+"two+"  , te[1].price+te[1].channel);
 HLineMove(0, name+"two-"  , te[1].price-te[1].channel);
 HLineMove(0, name+"three" , te[2].price);
 HLineMove(0, name+"three+", te[2].price+te[2].channel);
 HLineMove(0, name+"three-", te[2].price-te[2].channel);
}

void DeleteExtrLines(ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"one");
 HLineDelete(0, name+"one+");
 HLineDelete(0, name+"one-");
 HLineDelete(0, name+"two");
 HLineDelete(0, name+"two+");
 HLineDelete(0, name+"two-");
 HLineDelete(0, name+"three");
 HLineDelete(0, name+"three+");
 HLineDelete(0, name+"three-");
}

bool FillATRbuffer()
{
   if(handle_ATR != INVALID_HANDLE)
   {
    int copiedATR = CopyBuffer(handle_ATR, 0, 1, depth, buffer_ATR); 
    
    if (copiedATR != depth) 
    {
     Print(__FUNCTION__, "Не удалось полностью скопировать буффер ATR. Error = ", GetLastError());
     if(GetLastError() == 4401) 
      Print(__FUNCTION__, "Подождите некоторое время или подгрузите историю вручную.");
     return false;
    }
    return true;
   }
  return false;
}
  
ENUM_TIMEFRAMES GetTFbyLevel(LevelType lt)
{
 ENUM_TIMEFRAMES result = Period();
 if(lt == EXTR_MN) result = PERIOD_MN1;
 if(lt == EXTR_W1) result = PERIOD_W1;
 if(lt == EXTR_D1) result = PERIOD_D1;
 if(lt == EXTR_H4) result = PERIOD_H4;
 if(lt == EXTR_H1) result = PERIOD_H4;
 
 return(result);
}


void CalcStatistic ()
{
 MqlRates price[1];
 CopyRates(Symbol(), Period(), 1, 1, price);
//---------------ПЕРВЫЙ-УРОВЕНЬ------------------------------------
//проверка первого уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_one_DU && price[0].open < estruct[0].price - estruct[0].channel && price[0].close > estruct[0].price - estruct[0].channel)
 {
  level_one_DU = true;
  PrintFormat("I DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_one_DU)
 {
  if(price[0].open < estruct[0].price + estruct[0].channel && price[0].close > estruct[0].price + estruct[0].channel)
  {
   count_DUU++;
   level_one_DU = false;
   PrintFormat("I DU Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[0].price - estruct[0].channel && price[0].close < estruct[0].price - estruct[0].channel)
  {
   count_DUD++;
   level_one_DU = false;
   PrintFormat("I DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_one_UD && price[0].open > estruct[0].price + estruct[0].channel && price[0].close < estruct[0].price + estruct[0].channel)
 {
  level_one_UD = true;
  PrintFormat("I UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_one_UD)
 {
  if(price[0].open < estruct[0].price + estruct[0].channel && price[0].close > estruct[0].price + estruct[0].channel)
  {
   count_UDU++;
   level_one_UD = false;
   PrintFormat("I UD Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[0].price - estruct[0].channel && price[0].close < estruct[0].price - estruct[0].channel)
  {
   count_UDD++;
   level_one_UD = false;
   PrintFormat("I UD Цена вышла из коридора уровня снизу");
  } 
 }

//---------------ВТОРОЙ-УРОВЕНЬ------------------------------------
//проверка второго уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_two_DU && price[0].open < estruct[1].price - estruct[1].channel && price[0].close > estruct[1].price - estruct[1].channel)
 {
  level_two_DU = true;
  PrintFormat("II DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_two_DU)
 {
  if(price[0].open < estruct[1].price + estruct[1].channel && price[0].close > estruct[1].price + estruct[1].channel)
  {
   count_DUU++;
   level_two_DU = false;
   PrintFormat("II DU Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[1].price - estruct[1].channel && price[0].close < estruct[1].price - estruct[1].channel)
  {
   count_DUD++;
   level_two_DU = false;
   PrintFormat("II DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_two_UD && price[0].open > estruct[1].price + estruct[1].channel && price[0].close < estruct[1].price + estruct[1].channel)
 {
  level_two_UD = true;
  PrintFormat("II UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_two_UD)
 {
  if(price[0].open < estruct[1].price + estruct[1].channel && price[0].close > estruct[1].price + estruct[1].channel)
  {
   count_UDU++;
   level_two_UD = false;
   PrintFormat("II UD Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[1].price - estruct[1].channel && price[0].close < estruct[1].price - estruct[1].channel)
  {
   count_UDD++;
   level_two_UD = false;
   PrintFormat("II UD Цена вышла из коридора уровня снизу");
  } 
 }

//---------------ТРЕТИЙ-УРОВЕНЬ------------------------------------
//проверка третьего уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_three_DU && price[0].open < estruct[2].price - estruct[2].channel && price[0].close > estruct[2].price - estruct[2].channel)
 {
  level_three_DU = true;
  PrintFormat("III DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_three_DU)
 {
  if(price[0].open < estruct[2].price + estruct[2].channel && price[0].close > estruct[2].price + estruct[2].channel)
  {
   count_DUU++;
   level_three_DU = false;
   PrintFormat("III DU Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[2].price - estruct[2].channel && price[0].close < estruct[2].price - estruct[2].channel)
  {
   count_DUD++;
   level_three_DU = false;
   PrintFormat("III DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_three_UD && price[0].open > estruct[2].price + estruct[2].channel && price[0].close < estruct[2].price + estruct[2].channel)
 {
  level_three_UD = true;
  PrintFormat("III UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_three_UD)
 {
  if(price[0].open < estruct[2].price + estruct[2].channel && price[0].close > estruct[2].price + estruct[2].channel)
  {
   count_UDU++;
   level_three_UD = false;
   PrintFormat("III UD Цена вышла из коридора уровня сверху");
  }
  else if(price[0].open > estruct[2].price - estruct[2].channel && price[0].close < estruct[2].price - estruct[2].channel)
  {
   count_UDD++;
   level_three_UD = false;
   PrintFormat("III UD Цена вышла из коридора уровня снизу");
  } 
 }
}

void SavePorabolistic(string filename)
{
 int file_handle = FileOpen(filename, FILE_WRITE|FILE_ANSI|FILE_TXT|FILE_COMMON);
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  Alert("Ошибка открытия файла");
  return;
 }
 
 FileWriteString(file_handle, StringFormat("%s %s %s %s\r\n", __FILE__, EnumToString(Period()), Symbol(), TimeToString(TimeCurrent())));
 FileWriteString(file_handle, StringFormat("Parametrs: level = %s\r\n", EnumToString((ENUM_TIMEFRAMES)GetTFbyLevel(level))));
 //FileWriteString(file_handle, StringFormat("    TOP TF: percentage ATR = %.03f, ATR ma period = %d, dif to trend = %.03f\r\n", percentage_ATR_top, ATR_ma_period_top, difToTrend_top));
 FileWriteString(file_handle, "Возможные ситуации как цена проходит через уровень: \r\n");
 FileWriteString(file_handle, StringFormat("Цена идет снизу вверх, а после:вверх = %f, вниз = %f \r\n", count_DUU, count_DUD));
 FileWriteString(file_handle, StringFormat("Цена идет сверху вниз, а после:вверх = %f, вниз = %f \r\n", count_UDU, count_UDD));
 FileWriteString(file_handle, "Процентное соотношение ситуация когда цена продолжает идти в том же направлении после прохождения уровня:\r\n");
 FileWriteString(file_handle, StringFormat("Если идет снизву вверх %.02f % и сверху вниз %.02f \r\n", 100*(count_DUU)/(count_DUU + count_UDD), 100*(count_UDD)/(count_DUU + count_UDD)));
 FileWriteString(file_handle, "Процентное соотношение ситуация когда цена продолжает идти в противоположном направлении после прохождения уровня:\r\n");
 FileWriteString(file_handle, StringFormat("Если идет снизву вверх %.02f % и сверху вниз %.02f \r\n", 100*(count_DUD)/(count_DUD + count_UDU), 100*(count_UDU)/(count_DUD + count_UDU)));

 FileClose(file_handle); 
}
