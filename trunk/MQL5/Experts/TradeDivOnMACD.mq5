//+------------------------------------------------------------------+
//|                                            UselessPersonMACD.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                                                  |
//|             Класс UselessPerson предназначен для открытия сделок | 
//|                                 по сигналу с индикатора smydMACD |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки

#define  SELL -1
#define  BUY 1

//----Входные данные---

//-------Объекты-------
SPositionInfo pos_inf;                          //инфорация о позиции
STrailing trailingR;                            //информация по trailingR
CTradeManager *ctm;                             //открытие позиции


//------Переменные-----
int handlesmydMACD;                             
int handlePriceBasedIndicator;
double signal_buf_smydMACD[];                   //массив сигналов расхождений (SELL/BUY)
double buf_type_candle[];                       //массив - тип движения цены i-ого бара
double current_price[];                         //<< можно сделать статическим с размером 1>> для хранения цены открытия позиции
            
int smydMACD_copied;
int type_candle_copied;
int price_copied;
double cur_price;
double slR;
int minProfitR;
bool trendContinue;                             //Неблагоприятный тренд является продолжением расхождения
int type_of_trade;                              //Тип расхождения, на котором был пойман последний сигнал
                                                //если type_of_trade=0 - не вступаем в сделки пока не будет нового расхождения
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 ctm = new CTradeManager(); 
 handlesmydMACD = iCustom(_Symbol, _Period, "smydMACD");
 if (handlesmydMACD == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта TradeDivOnMACD. Не удалось создать хэндл ShowMeYourDivMACD");
  return(INIT_FAILED);
 }
 handlePriceBasedIndicator = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePriceBasedIndicator == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта TradeDivOnMACD. Не удалось создать хэндл PriceBasedIndicator");
  return(INIT_FAILED);
 } 
 pos_inf.expiration = 0;                        //время жизни отложенного бара, 0- живет, пока сами не удалим
 pos_inf.volume = 1;                            //объем позициии
 type_of_trade = 0;
 trendContinue = false;
 trailingR.trailingType = TRAILING_TYPE_USUAL;
 trailingR.trailingStep = 10;
 
 return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 ArrayFree(signal_buf_smydMACD);
 ArrayFree(buf_type_candle);
 IndicatorRelease(handlesmydMACD);
 delete ctm;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
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
  if(trendContinue)                 
  {
   if(buf_type_candle[0] == 1)      //Если тренд вверх
     if(CopyCurrentHighPrice(0))    //Если копирование удачно
      slR = current_price[0];       //Запишем текущую цену в slR
     else 
      return;
   else
   trendContinue = false;
  }
  else
  {
   if(buf_type_candle[0] == 1)      //Если тренд вверх
   {
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 3 || buf_type_candle[0] == 6)//Если наблюдается коррекция или тренд вниз
    {
    Print("SELL: Обнаружен тренд вверх, открываем позицию!");
     //Заполнить и открыть позицию на SELL
     cur_price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     minProfitR = (int) MathAbs((slR - cur_price) / _Point);
     //заполнение SL  и minProfitR...  
     pos_inf.sl = minProfitR * 0.8;
     trailingR.minProfit = minProfitR;
     trailingR.trailingStop  = minProfitR;
     Print("cur_pice = ",cur_price);
     Print("SL = ", pos_inf.sl, " minProfitR = ", minProfitR);
     ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trailingR, 0);
     type_of_trade = 0;
    }
   }
  }
 }
 
 //------------------Если тип сигнала BUY-------------------
 if (type_of_trade == BUY)         
 {
  if(trendContinue)                 
  { 
   if(buf_type_candle[0] == 3)         //Если тренд вниз
    if(CopyCurrentLowPrice(0))         //Если копирование удачно    
     slR = current_price[0];           //Запишем текущую цену в slR
    else 
     return;
   else
   {
   trendContinue = false;              //Продолжение тренда закончилось
   }
  }
  else
  { 
   if(buf_type_candle[0] == 3)         //Если тренд вниз
   {
    Print("BUY: обнаружен тренд вниз обнуляем сигнал!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 1 || buf_type_candle[0] == 5)//Если наблюдается коррекция или тренд вверх
    {
     Print("BUY: Обнаружен тренд вверх, открываем позицию!");
     //Заполнить и открыть позицию на BUY
     cur_price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     minProfitR = (int) MathAbs((slR - cur_price) / _Point);  
     //заполнение SL  и minProfitR...  
     pos_inf.sl = minProfitR * 0.8;
     trailingR.trailingStop  = minProfitR; 
     trailingR.minProfit     = minProfitR;
     trailingR.trailingStop  = minProfitR;
     Print("cur_pice = ",cur_price);
     Print("SL = ", pos_inf.sl, " minProfitR = ", minProfitR);
     ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trailingR, 0);
     type_of_trade = 0;
    }
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
 //Как хочется сделать!  
 //int id1 = CatchEventfrom();
 //int id2 =
 
 //Копируем тип текущей свечи на случай если событие OnChartEvent() будет первее OnTick()
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
 if(type_candle_copied <= 0)
 {
  Print("Не удалось скопировать данные с индикатора PriceBasedIndicator");
  return;
 }
 //------------Если был пойман сигнал расхождения на SELL----------------
 if (sparam == "SELL")
 {
  type_of_trade = SELL;
  pos_inf.type = OP_SELL;
  if(buf_type_candle[0] == 1)       //если текущий бар продолжает быть в нарастающем тренде
  {
   Print("Поймали сигнал SELL и установили флаг trendContinue");
   trendContinue = true;
  }
  else
  {
   slR = dparam;                    //Запишем текущую цену в slR
   Print("BUY slR = ",slR);
  }
 }
 //------------Если был пойман сигнал расхождения на BUY----------------
 if (sparam == "BUY")
 {
  type_of_trade = BUY;
  pos_inf.type = OP_BUY;
  if(buf_type_candle[0] == 3)       //если текущий бар продолжает быть в нарастающем тренде
  {
   Print("Поймали сигнал BUY и установили флаг trendContinue");
   trendContinue = true;
  }
  else
  {
    slR = dparam;                   //Запишем текущую цену в slR
    Print("BUY slR = ",slR);
  }
 } 
}



bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, current_price);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, current_price);
 if(price_copied != 1)
 {
  Print("Ошибка! не удалось скопировать текущую цену High");  
  return false;
 }
 return true;
}
