//+------------------------------------------------------------------+
//|                                                      HAYASHI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>  // торговая библиотека
#include <CompareDoubles.mqh>             // для сравнения вещественных чисел
#include <Lib CisNewBar.mqh>              // для формирования нового бара

input double lot              = 0.1;      // начальный размер лота
input int    stop_loss        = 60;       // стоп лосс
input int    size_of_series   = 5;        // средний размер серии сделок
input double lot_d            = 1.5;      // коэффициент увеличения лота


//+------------------------------------------------------------------+
//| Эксперт Хаяcи                                                    |
//+------------------------------------------------------------------+


CTradeManager ctm(); 
bool   openedPosition = false;            // флаг окрытия позиции
bool   isNormalPos    = false;            // флаг закрытия нормальной позиции
bool   was_a_part     = false;            // флаг подсчета серии
double openPrice;                         // цена открытия
//double lot_d          = 1.5;              // единица изменения лота
double current_lot    = lot;              // текущий лот
int    count_long     = 0;                // счетчик длины серии
datetime history_start;



void   ModifyLot (bool mode)              // функция изменяет размер лота
 {
  if (mode == true)
   current_lot = current_lot * lot_d;     // модифицируем лот
  else
   current_lot = lot;                     // возобновляем изначальный лот 
 }

int OnInit()
  {
   history_start=TimeCurrent();  
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

int cnt=0;

void OnTick()
  {
    static CisNewBar isNewBar(_Symbol, _Period);   // для проверки формирования нового бара
    double currentPrice;                           // текущая цена
    double spread;                                 // спред
   
    //Comment("ТЕКУЩИЙ РАЗМЕР СЕРИИ = ",count_long);
    // если сформирован новый бар  
    
    
    
    cnt++;
    if(isNewBar.isNewBar() > 0)
     {
      if (isNormalPos == false)  // если на предыдущем баре позиция не закрылась, как нужно
       {
         was_a_part  = false;
         count_long  = 0; 
         current_lot = lot;      // возвращаем лот назад  
       //  Comment("Позиция закрылась не по правилу");          
       }
      else
         Alert("Позиция закрылась по правилу");
      isNormalPos = false;
      if (openedPosition == false)
       { // если до этого момента еще не была открыта позиция
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, current_lot,stop_loss) ) // пытаемся открыться на BUY 
           {
             Comment("ЛОТ = "+current_lot);
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // сохраняем цену открытия позиции
             openedPosition = true;                            // флаг открытия позиции выставляем в true
             was_a_part     = true;                            // выставляем флаг продолжения серии в true
           }  
       }
      else
       {
         // если уже есть открытая позиция
         openPrice   = SymbolInfoDouble(_Symbol,SYMBOL_ASK);   // то сохраняем текущую цену открытия 
       }
     }
    else
     { // если бар не сформирован
       if (openedPosition == true)
        { // если была открыта позиция
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // получаем текущую цену
          spread       = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice; // вычисляем уровень спреда
 //         Comment ("СПРЕД = ",spread);
          if ((currentPrice - openPrice) > spread)
           { // если текущая цена превысила цену открытия
             ctm.ClosePosition(_Symbol); // закрываем позицию
             openedPosition = false;     // выставляем флаг открытия позиции в false
             isNormalPos    = true;      // значит, по позицию закрылась по нормальному
             if (was_a_part == true)     // если не было изменения цены позиции
              {
                if (count_long < size_of_series)
                 {
                   ModifyLot (true); // модифицируем лот
                 }
                else
                 {
                  ModifyLot (false); // ставим лот в изначальное состоние
                  count_long = 0;
                 }
                count_long ++;   // увеличиваем длину серии
              }

           }
        }
     }
  }
  
  
  void OnTrade ()
   {
    ctm.OnTrade(history_start);
   }