//+------------------------------------------------------------------+
//|                                            UselessPersonSTOC.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки

#define  SELL -1
#define  BUY   1

int const sl_border = 130;                      //константа для вычисления SL с помощью формул
//------------Входные данные------------

//---------------Функции----------------

//---------------Объекты----------------

CisNewBar      *isNewBar;
SPositionInfo  pos_inf;                          // инфорация о позиции
STrailing      trail;                            // информация по trail
CTradeManager  *ctm;                             // открытие позиции

//---------------Переменные-------------
int    handlesmydSTOC;                             
int    handlePriceBasedIndicator;
double signal_buf[];                            // массив сигналов расхождений (SELL/BUY)
double buf_type_candle[];                       // массив - тип движения цены i-ого бара
double cur_price[];                             // массив - цена последнего расхождения 
            

int    signal_buf_copied;
int    type_candle_copied;
int    price_copied;

double open_price;                              // цена открытия позиции
double divPrice;                                // цена последнего расхождения 
double stL;                                     // stopLoss - <<-Не понадобился пока что->>
int    minProf;                                 // minProfit
int    type_of_trade;                           // тип расхождения, на котором был пойман последний сигнал
                                                // если type_of_trade = 0 - не вступаем в сделки пока не будет нового расхождения
bool   trendContinue;                           // неблагоприятный тренд является продолжением расхождения


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 //---
 ctm = new CTradeManager(); 
 handlesmydSTOC = iCustom(_Symbol, _Period, "smydSTOC");
 if (handlesmydSTOC == INVALID_HANDLE)
 {
  Print("Ошибка при инициализации эксперта UselessPercon. Не удалось создать хэндл ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }
 handlePriceBasedIndicator = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePriceBasedIndicator == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта UselessPercon. Не удалось создать хэндл PriceBasedIndicator");
  return(INIT_FAILED);
 }
 isNewBar = new CisNewBar();
 //---------------УТОЧНИТЬ ПАРАМЕТРЫ!!!!!------------------------------------------------
 pos_inf.expiration = 0;   //время жизни отложенного бара, 0- живет, пока сами не удалим
 pos_inf.volume = 1;       //объем позициии
 type_of_trade = 0;
 trendContinue = false;
 trail.trailingType = TRAILING_TYPE_USUAL;
 trail.trailingStep = 10;
 //---
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 ArrayFree(signal_buf);
 ArrayFree(buf_type_candle);
 IndicatorRelease(handlesmydSTOC);
 IndicatorRelease(handlePriceBasedIndicator);
 delete ctm;  
 delete isNewBar; 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();                            //<<ГДЕ ЛУЧШЕ OnTick И DoTrailing>>
 signal_buf_copied  = CopyBuffer(handlesmydSTOC, 2, 0, 1, signal_buf);
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
 if(signal_buf_copied <= 0)
 {
  Print("Не удалось скопировать данные с индикатора smydMACD");
  return;
 }
  if(type_candle_copied <= 0)
 {
  Print("Не удалось скопировать данные с индикатора PriceBasedIndicator");
  return;
 }
 ctm.DoTrailing();
 
 //--------------Проверка сигналов и открытие позиций------------
 //--------------------Если тип сигнала SELL---------------------
 if (type_of_trade == SELL)         
 {
  if(!CopyCurrentHighPrice(0))return;
  if(trendContinue)                 
  { Print("SELL: тренд продолжается!!");
    //Если копирование удачно и продолжается рост цены или сопутствующего тренда
    if(buf_type_candle[0] == 1|| divPrice <= cur_price[0]) 
      divPrice = cur_price[0];               //Запишем текущую цену 
    else 
     trendContinue = false;
     return;
  }
  else
  {
   if(buf_type_candle[0] == 1 || cur_price[0] > divPrice)               //Если тренд вверх
   { Print("SELL: обнаружен тренд вверх обнуляем сигнал!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 2 || buf_type_candle[0] == 4)//Если текущий бар запрещенный
     return;
    open_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    minProf    = (int) MathAbs((divPrice - open_price) / _Point);
    if(minProf <= sl_border)
     minProf = (int)(minProf + (sl_border - minProf) * 0.8);
    else
     minProf = (int)(minProf/((minProf - sl_border)/10+10));
    Print("SELL: Обнаружен тренд вверх, открываем позицию!");
    //Заполнить и открыть позицию на SELL 
    pos_inf.sl          = minProf;
    pos_inf.tp          = minProf * 1.4;  
    trail.minProfit     = minProf * 0.8;
    trail.trailingStop  = minProf;
    Print("SL = ", pos_inf.sl, " minProf = ", minProf, "divPrice = ", divPrice, "open_price = ", open_price);
    ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
    type_of_trade = 0;
   }
  }
 }

 //------------------Если тип сигнала BUY-------------------
 if (type_of_trade == BUY)         
 {
  if(!CopyCurrentLowPrice(0))return;    
  if(trendContinue)                 
  { Print("BUY: тренд продолжается!!");
   //Если копирование удачно и продолжается рост цены или сопутствующего тренда
   if(buf_type_candle[0] == 3|| divPrice >= cur_price[0]) 
    divPrice = cur_price[0];              //Запишем текущую цену 
   else 
    trendContinue = false;                //Продолжение тренда закончилось
  }
  else
  { 
   if(buf_type_candle[0] == 3|| cur_price[0] <= divPrice)            //Если тренд вниз
   {
    Print("BUY: обнаружен тренд вниз обнуляем сигнал!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 2 || buf_type_candle[0] == 4)//Если текущий бар запрещенный
     return;    
    //Заполнить и открыть позицию на BUY
    open_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    Print("BUY: Обнаружен тренд вверх, открываем позицию!");
    minProf    = (int) MathAbs((divPrice - open_price) / _Point);
    if(minProf <= sl_border)
     minProf = (int)(minProf + (sl_border - minProf) * 0.8);
    else
     minProf = (int)(minProf /((minProf - sl_border)/10+10));//(int)minProf * 0.9; 
    pos_inf.sl          = minProf;
    trail.minProfit     = minProf * 0.8;
    trail.trailingStop  = minProf;
    pos_inf.tp          = minProf * 1.4;  
    Print("open_price = ", open_price);
    Print("SL = ", pos_inf.sl, " minProf = ", minProf);
    ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
    type_of_trade = 0;
   }
  }
 } 
}

void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
{
 //------------Если был пойман сигнал расхождения на SELL----------------
 if (sparam == "SELL")
 {
  type_of_trade = SELL;                       //сохраняем полученный сигнал
  pos_inf.type = OP_SELL;
  Print("Поймали сигнал BUY и установили флаг trendContinue");
  trendContinue = true;
  divPrice = dparam;                 //Запишем текущую цену в slR
  Print("divPrice = ", divPrice);
 }
 //------------Если был пойман сигнал расхождения на BUY----------------
 if (sparam == "BUY")
 {
  type_of_trade = BUY;                       //сохраняем полученный сигнал
  pos_inf.type = OP_BUY;
  Print("Поймали сигнал BUY и установили флаг trendContinue");
  trendContinue = true;
  divPrice = dparam;                 
  Print("divPrice = ", divPrice);
 }
}

//---------------------CopyCurrentHighPrice--------------------------+
//-------------------------------------------------------------------+
bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, cur_price);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}


//---------------------CopyCurrentLowPrice---------------------------+
//-------------------------------------------------------------------+
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, cur_price);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}