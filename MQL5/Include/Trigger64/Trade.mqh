//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//библиотека класса по работе со сделками
#include <Trade/Trade.mqh>
#include <TradeManager/TradeManager.mqh>
#include "PositionSys.mqh"
#include "SymbolSys.mqh"
#include "Graph.mqh"

 class  HisTrade //класс совершения сделок
  {
   private:
    datetime new_bar;  //--- Переменная для времени открытия текущего бара
    datetime time_last_bar[1]; //--- Массив для получения времени открытия текущего бара
   int  AllowedNumberOfBars;   
   CTrade trade;   
   double      close_price[]; // Close (цены закрытия бара)
   double      open_price[];  // Open (цены открытия бара)
   double      high_price[];  // High (цены максимума бара)
   double      low_price[];   // Open (цены минимума бара)
   
   long        MagicNumber;     // Магический номер
   int         Deviation;        // Проскальзывание
   int         NumberOfBars;      // Кол-во Бычьих/Медвежьих баров для покупки/продажи
   double      Lot;             // Лот
   double      VolumeIncrease;  // Приращение объема позиции
   double      StopLoss;         // Стоп Лосс
   double      TakeProfit;      // Тейк Профит
   double      TrailingStop;     // Трейлинг Стоп
   bool        Reverse;        // Разворот позиции
   bool        ShowInfoPanel;  // Показ информационной панели
   
   public:
   CTradeManager new_trade;
   PositionSys my_pos; 
   SymbolSys   my_sym;
   GraphModule my_graph;   
   bool CheckNewBar();  //проверяет формирование нового бара
   string TimeframeToString(ENUM_TIMEFRAMES timeframe);  //преобразует таймфрейм в строку
   void GetBarsData();  //
   ENUM_ORDER_TYPE GetTradingSignal(); //получает сигнал торговли
   void OpenPosition(double lot,
                  ENUM_ORDER_TYPE order_type,
                  double price,
                  double sl,
                  double tp,
                  string comment);  //открывает позицию 
   int UploadInputs (long        _MagicNumber,   //метод загрузки параметров из внешних инпутов в класс торговли 
                     int         _Deviation,
                     int         _NumberOfBars,
                     double      _Lot,
                     double      _VolumeIncrease,
                     double      _StopLoss,
                     double      _TakeProfit,
                     double      _TrailingStop,
                     bool        _Reverse,
                     bool        _ShowInfoPanel                
                     );  //загрузка из внешних констант параметров в торговый класс               
   void TradingBlock();  //торговый блок  
   double CalculateLot(double lot);  //подсчитывает лот
   double CalculateTakeProfit(ENUM_ORDER_TYPE order_type); //вычисляет тейк профит
   double CalculateStopLoss(ENUM_ORDER_TYPE order_type); //вычисляет стоп лосс
   double CalculateTrailingStop(ENUM_POSITION_TYPE position_type); //вычисляет трейлинг стоп
   void ModifyTrailingStop();  //модифицирует трейлинг стоп                  
   HisTrade(); //конструктор класса
  ~HisTrade(); //деструктор класса  
  };
  
  bool HisTrade::CheckNewBar()
  {
//--- Получим время открытия текущего бара
//    Если возникла ошибка при получении, сообщим об этом
   if(CopyTime(_Symbol,Period(),0,1,time_last_bar)==-1)
     { Print(__FUNCTION__,": Ошибка копирования времени открытия бара: "+IntegerToString(GetLastError())+""); }
//--- Если это первый вызов функции
   if(new_bar==NULL)
     {
      // Установим время
      new_bar=time_last_bar[0];
      Print(__FUNCTION__,": Инициализация ["+_Symbol+"][TF: "+TimeframeToString(Period())+"]["
            +TimeToString(time_last_bar[0],TIME_DATE|TIME_MINUTES|TIME_SECONDS)+"]");
      return(false); // Вернём false и выйдем 
     }
//--- Если время отличается
   if(new_bar!=time_last_bar[0])
     {
      new_bar=time_last_bar[0]; // Установим время и выйдем 
      return(true); // Запомним время и вернем true
     }
//--- Дошли до этого места - значит бар не новый, вернем false
   return(false);
  }
//+------------------------------------------------------------------+
//| Преобразует таймфрейм в строку                                   |
//+------------------------------------------------------------------+
string HisTrade::TimeframeToString(ENUM_TIMEFRAMES timeframe)
  {
   string str="";
//--- Если переданное значение некорректно, берем таймфрейм текущего графика
   if(timeframe==WRONG_VALUE|| timeframe== NULL)
      timeframe= Period();
   switch(timeframe)
     {
      case PERIOD_M1  : str="M1";  break;
      case PERIOD_M2  : str="M2";  break;
      case PERIOD_M3  : str="M3";  break;
      case PERIOD_M4  : str="M4";  break;
      case PERIOD_M5  : str="M5";  break;
      case PERIOD_M6  : str="M6";  break;
      case PERIOD_M10 : str="M10"; break;
      case PERIOD_M12 : str="M12"; break;
      case PERIOD_M15 : str="M15"; break;
      case PERIOD_M20 : str="M20"; break;
      case PERIOD_M30 : str="M30"; break;
      case PERIOD_H1  : str="H1";  break;
      case PERIOD_H2  : str="H2";  break;
      case PERIOD_H3  : str="H3";  break;
      case PERIOD_H4  : str="H4";  break;
      case PERIOD_H6  : str="H6";  break;
      case PERIOD_H8  : str="H8";  break;
      case PERIOD_H12 : str="H12"; break;
      case PERIOD_D1  : str="D1";  break;
      case PERIOD_W1  : str="W1";  break;
      case PERIOD_MN1 : str="MN1"; break;
     }
//---
   return(str);
  }
//+------------------------------------------------------------------+
//| Получает значения баров                                          |
//+------------------------------------------------------------------+
void HisTrade::GetBarsData()
  {
//--- Скорректируем значение количества баров для условия открытия позиции
   if(NumberOfBars<=1)
      AllowedNumberOfBars=2;              // Нужно не менее двух баров
   if(NumberOfBars>=5)
      AllowedNumberOfBars=5;              // и не более 5
   else
      AllowedNumberOfBars=NumberOfBars+1; // и всегда на один больше
//--- Установим обратный порядок индексации (... 3 2 1 0)
   ArraySetAsSeries(close_price,true);
   ArraySetAsSeries(open_price,true);
   ArraySetAsSeries(high_price,true);
   ArraySetAsSeries(low_price,true);
//--- Получим цену закрытия бара
//    Если полученных значений меньше, чем запрошено, вывести сообщение об этом
   if(CopyClose(_Symbol,Period(),0,AllowedNumberOfBars,close_price)<AllowedNumberOfBars)
     {
      Print("Не удалось скопировать значения ("
            +_Symbol+", "+TimeframeToString(Period())+") в массив цен Close! "
            "Ошибка "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- Получим цену открытия бара
//    Если полученных значений меньше, чем запрошено, вывести сообщение об этом
   if(CopyOpen(_Symbol,Period(),0,AllowedNumberOfBars,open_price)<AllowedNumberOfBars)
     {
      Print("Не удалось скопировать значения ("
            +_Symbol+", "+TimeframeToString(Period())+") в массив цен Open! "
            "Ошибка "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- Получим цену максимума бара
//    Если полученных значений меньше, чем запрошено, вывести сообщение об этом
   if(CopyHigh(_Symbol,Period(),0,AllowedNumberOfBars,high_price)<AllowedNumberOfBars)
     {
      Print("Не удалось скопировать значения ("
            +_Symbol+", "+TimeframeToString(Period())+") в массив цен High! "
            "Ошибка "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- Получим цену максимума бара
//    Если полученных значений меньше, чем запрошено, вывести сообщение об этом
   if(CopyLow(_Symbol,Period(),0,AllowedNumberOfBars,low_price)<AllowedNumberOfBars)
     {
      Print("Не удалось скопировать значения ("
            +_Symbol+", "+TimeframeToString(Period())+") в массив цен Low! "
            "Ошибка "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
  }
//+------------------------------------------------------------------+
//| Определяет торговые сигналы                                      |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE HisTrade::GetTradingSignal()
  {
//--- Сигнал на покупку (ORDER_TYPE_BUY) :
   if(AllowedNumberOfBars==2 && 
      close_price[1]>open_price[1])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==3 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==4 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==5 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3] && 
      close_price[4]>open_price[4])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars>=6 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3] && 
      close_price[4]>open_price[4] && 
      close_price[5]>open_price[5])
      return(ORDER_TYPE_BUY);
//--- Сигнал на продажу (ORDER_TYPE_SELL) :
   if(AllowedNumberOfBars==2 && 
      close_price[1]<open_price[1])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==3 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==4 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==5 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3] && 
      close_price[4]<open_price[4])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars>=6 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3] && 
      close_price[4]<open_price[4] && 
      close_price[5]<open_price[5])
      return(ORDER_TYPE_SELL);
//--- Отсутствие сигнала (WRONG_VALUE):
   return(WRONG_VALUE);
  }
  
   int HisTrade::UploadInputs (long        _MagicNumber,   //метод загрузки параметров из внешних инпутов в класс торговли 
                     int         _Deviation,
                     int         _NumberOfBars,
                     double      _Lot,
                     double      _VolumeIncrease,
                     double      _StopLoss,
                     double      _TakeProfit,
                     double      _TrailingStop,
                     bool        _Reverse,
                     bool        _ShowInfoPanel                
                     )
       {
         MagicNumber = _MagicNumber;
         Deviation = _Deviation;
         NumberOfBars = _NumberOfBars;
         Lot = _Lot;
         VolumeIncrease = _VolumeIncrease;
         StopLoss = _StopLoss;
         TakeProfit = _TakeProfit;
         TrailingStop = _TrailingStop;
         Reverse = _Reverse;
         ShowInfoPanel = _ShowInfoPanel;
         return 1;
       }                 
//+------------------------------------------------------------------+
//| Открывает позицию                                                |
//+------------------------------------------------------------------+
void HisTrade::OpenPosition(double lot,
                  ENUM_ORDER_TYPE order_type,
                  double price,
                  double sl,
                  double tp,
                  string comment)
  {
   ENUM_TM_POSITION_TYPE getOrder;
   //trade.SetExpertMagicNumber(MagicNumber); // Установим номер мэджика в торговую структуру
  // trade.SetDeviationInPoints(my_sym.CorrectValueBySymbolDigits(Deviation)); // Установим размер проскальзывания в пунктах
   
   new_trade.MakeMagic(MagicNumber); //устанавливаем магическое число
   
//--- Если позиция не открылась, вывести сообщение об этом
   
   if (order_type == ORDER_TYPE_BUY)
      getOrder = OP_BUY;
   if (order_type == ORDER_TYPE_SELL)
      getOrder = OP_SELL;
      
      // if(!trade.PositionOpen(_Symbol,order_type,lot,price,sl,tp,comment))
      
   if (!new_trade.OpenPosition(_Symbol,getOrder,lot,sl,tp,0,0,0) )
     { Print("Ошибка при открытии позиции: ",GetLastError()," - ",ErrorDescription(GetLastError())); }
  }
//+------------------------------------------------------------------+
//| Торговый блок                                                    |
//+------------------------------------------------------------------+
void HisTrade::TradingBlock()
  {
   ENUM_ORDER_TYPE      signal=WRONG_VALUE;                 // Переменная для приема сигнала
   string               comment="hello :)";                 // Комментарий для позиции
   double               tp=0.0;                             // Take Profit
   double               sl=0.0;                             // Stop Loss
   double               lot=0.0;                            // Объем для расчета позиции в случае переворота позиции
   double               position_open_price=0.0;            // Цена открытия позиции
   ENUM_ORDER_TYPE      order_type=WRONG_VALUE;             // Тип ордера для открытия позиции
   ENUM_POSITION_TYPE   opposite_position_type=WRONG_VALUE; // Противоположный тип позиции
//--- Получим сигнал
   signal=GetTradingSignal();
//--- Если сигнала нет, выходим
   if(signal==WRONG_VALUE)
      return;
//--- Узнаем, есть ли позиция
   my_pos.pos.exists=PositionSelect(_Symbol);
//--- Получим все свойства символа
   my_sym.GetSymbolProperties("1111111111111111111");
//--- Определим значения торговым переменным
   switch(signal)
     {
      //--- Присвоим переменным значения для BUY
      case ORDER_TYPE_BUY  :
         position_open_price=my_sym.symb.ask;
         order_type=ORDER_TYPE_BUY;
         opposite_position_type=POSITION_TYPE_SELL;
         break;
         //--- Присвоим переменным значения для SELL
      case ORDER_TYPE_SELL :
         position_open_price=my_sym.symb.bid;
         order_type=ORDER_TYPE_SELL;
         opposite_position_type=POSITION_TYPE_BUY;
         break;
     }
//--- Рассчитаем уровни Take Profit и Stop Loss
   sl=CalculateStopLoss(order_type);
  
   tp=CalculateTakeProfit(order_type);
//--- Если позиции нет
   if(!my_pos.pos.exists)
     {
      //--- Скорректируем объем
      lot=CalculateLot(Lot);
      //--- Откроем позицию
      OpenPosition(lot,order_type,position_open_price,sl,tp,comment);
     }
//--- Если позиция есть
   else
     {
      //--- Получим тип позиции
      my_pos.GetPositionProperties("1111111111111111111");
      //--- Если позиция противоположна сигналу и включен переворот позиции
      if(my_pos.pos.type==opposite_position_type && Reverse)
        {
         //--- Получим объём позиции
         my_pos.GetPositionProperties("1111111111111111111");
         //--- Скорректируем объем
         lot=my_pos.pos.volume+CalculateLot(Lot);
         //--- Перевернем позицию
         OpenPosition(lot,order_type,position_open_price,sl,tp,comment);
         return;
        }
      //--- Если сигнал по направлению позиции и включено наращивание объема, увеличим объём позиции
      if(!(my_pos.pos.type==opposite_position_type) && VolumeIncrease>0)
        {
         //--- Получим Stop Loss текущей позиции
         my_pos.GetPositionProperties("1111111111111111111");
         //--- Получим Take Profit текущей позиции
         my_pos.GetPositionProperties("1111111111111111111");
         //--- Скорректируем объем
         lot=CalculateLot(VolumeIncrease);
         //--- Увеличим объем позиции
         OpenPosition(lot,order_type,position_open_price,my_pos.pos.sl,my_pos.pos.tp,comment);
         return;
        }
     }
//---
   return;
  }
  
  //+------------------------------------------------------------------+
//| Рассчитывает объем для позиции                                   |
//+------------------------------------------------------------------+
double HisTrade::CalculateLot(double lot)
  {
//--- Для корректировки с учетом шага
   double corrected_lot=0.0;
   
//---
   my_sym.GetSymbolProperties("1111111111111111111");  // Получим минимально возможный лот
   my_sym.GetSymbolProperties("1111111111111111111");  // Получим максимально возможный лот
   my_sym.GetSymbolProperties("1111111111111111111"); // Получим шаг увеличения/уменьшения лота
//--- Скорректируем с учетом шага лота
   corrected_lot=MathRound(lot/my_sym.symb.volume_step)*my_sym.symb.volume_step;
//--- Если меньше минимального, вернем минимальный
   if(corrected_lot<my_sym.symb.volume_min)
      return(NormalizeDouble(my_sym.symb.volume_min,2));
//--- Если больше максимального, вернем максимальный
   if(corrected_lot>my_sym.symb.volume_max)
      return(NormalizeDouble(my_sym.symb.volume_max,2));
//---
   return(NormalizeDouble(corrected_lot,2));
  }
//+------------------------------------------------------------------+
//| Рассчитывает уровень Take Profit                                 |
//+------------------------------------------------------------------+
double HisTrade::CalculateTakeProfit(ENUM_ORDER_TYPE order_type)
  {
//--- Если Take Profit нужен
   if(TakeProfit>0)
     {
      //--- Для рассчитанного значения Take Profit
      double tp=0.0;
      //--- Если нужно рассчитать значение для позиции SELL
      if(order_type==ORDER_TYPE_SELL)
        {
         //--- Рассчитаем уровень
         tp=NormalizeDouble(my_sym.symb.bid-my_sym.CorrectValueBySymbolDigits(TakeProfit*my_sym.symb.point),my_sym.symb.digits);
         //--- Вернем рассчитанное значение, если оно ниже нижней границы stops level
         //    Если значение выше или равно, вернем скорректированное значение
         return(tp<my_sym.symb.down_level ? tp : my_sym.symb.down_level-my_sym.symb.offset);
        }
      //--- Если нужно рассчитать значение для позиции BUY
      if(order_type==ORDER_TYPE_BUY)
        {
         //--- Рассчитаем уровень
         tp=NormalizeDouble(my_sym.symb.ask+my_sym.CorrectValueBySymbolDigits(TakeProfit*my_sym.symb.point),my_sym.symb.digits);
         //--- Вернем рассчитанное значение, если оно выше верхней границы stops level
         //    Если значение ниже или равно, вернем скорректированное значение
         return(tp>my_sym.symb.up_level ? tp : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Рассчитывает уровень Stop Loss                                   |
//+------------------------------------------------------------------+
double HisTrade::CalculateStopLoss(ENUM_ORDER_TYPE order_type)
  {
//--- Если Stop Loss нужен
   if(StopLoss>0)
     {
      //--- Для рассчитанного значения Stop Loss
      double sl=0.0;
      //--- Если нужно рассчитать значение для позиции BUY
      if(order_type==ORDER_TYPE_BUY)
        {
         // Рассчитаем уровень
         sl=NormalizeDouble(my_sym.symb.ask-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- Вернем рассчитанное значение, если оно ниже нижней границы stops level
         //    Если значение выше или равно, вернем скорректированное значение
         return(sl<my_sym.symb.down_level ? sl : my_sym.symb.down_level-my_sym.symb.offset);
        }
      //--- Если нужно рассчитать значение для позиции SELL
      if(order_type==ORDER_TYPE_SELL)
        {
         //--- Рассчитаем уровень
         sl=NormalizeDouble(my_sym.symb.bid+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- Вернем рассчитанное значение, если оно выше верхней границы stops level
         //    Если значение ниже или равно, вернем скорректированное значение
         return(sl>my_sym.symb.up_level ? sl : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Рассчитывает уровень Trailing Stop                               |
//+------------------------------------------------------------------+
/*
double HisTrade::CalculateTrailingStop(ENUM_POSITION_TYPE position_type)
  {
//--- Переменные для расчётов
   double            level       =0.0;
   double            buy_point   =low_price[1];    // Значение Low для Buy
   double            sell_point  =high_price[1];   // Значение High для Sell
//--- Рассчитаем уровень для позиции BUY
   if(position_type==POSITION_TYPE_BUY)
     {
      //--- Минимум бара минус указанное количество пунктов
      level=NormalizeDouble(buy_point-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
      //--- Если рассчитанный уровень ниже, чем нижний уровень ограничения (stops level), 
      //    то расчет закончен, вернем текущее значение уровня
      if(level<my_sym.symb.down_level)
         return(level);
      //--- Если же не ниже, то попробуем рассчитать от цены bid
      else
        {
         level=NormalizeDouble(my_sym.symb.bid-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- Если рассчитанный уровень ниже ограничителя, вернем текущее значение уровня
         //    Иначе установим максимально возможный близкий
         return(level<my_sym.symb.down_level ? level : my_sym.symb.down_level-my_sym.symb.offset);
        }
     }
//--- Рассчитаем уровень для позиции SELL
   if(position_type==POSITION_TYPE_SELL)
     {
      // Максимум бара плюс указанное кол-во пунктов
      level=NormalizeDouble(sell_point+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
      //--- Если рассчитанный уровень выше, чем верхний уровень ограничения (stops level), 
      //    то расчёт закончен, вернем текущее значение уровня
      if(level>my_sym.symb.up_level)
         return(level);
      //--- Если же не выше, то попробуем рассчитать от цены ask
      else
        {
         level=NormalizeDouble(my_sym.symb.ask+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- Если рассчитанный уровень выше ограничителя, вернем текущее значение уровня
         //    Иначе установим максимально возможный близкий
         return(level>my_sym.symb.up_level ? level : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Изменяет уровень Trailing Stop                                   |
//+------------------------------------------------------------------+
void HisTrade::ModifyTrailingStop()
  {
//--- Если включен трейлинг и StopLoss
   if(TrailingStop>0 && StopLoss>0)
     {
      double         new_sl=0.0;       // Для расчета нового уровня Stop loss
      bool           condition=false;  // Для проверки условия на модификацию
      //--- Получим флаг наличия/отсутствия позиции
      my_pos.pos.exists=PositionSelect(_Symbol);
      //--- Если есть позиция
      if(my_pos.pos.exists)
        {
         //--- Получим свойства символа
         my_sym.GetSymbolProperties("1111111111111111111");
         //--- Получим свойства позиции
         my_pos.GetPositionProperties("1111111111111111111");
         //--- Получим уровень для Stop Loss
         new_sl=CalculateTrailingStop(my_pos.pos.type);
         //--- В зависимости от типа позиции проверим соответствующее условие на модификацию Trailing Stop
         switch(my_pos.pos.type)
           {
            case POSITION_TYPE_BUY  :
               //--- Если новое значение для Stop Loss выше,
               //    чем текущее значение плюс установленный шаг
               condition=new_sl>my_pos.pos.sl+my_sym.CorrectValueBySymbolDigits(TrailingStop*my_sym.symb.point);
               break;
            case POSITION_TYPE_SELL :
               //--- Если новое значение для Stop Loss ниже,
               //    чем текущее значение минус установленный шаг
               condition=new_sl<my_pos.pos.sl-my_sym.CorrectValueBySymbolDigits(TrailingStop*my_sym.symb.point);
               break;
           }
         //--- Если Stop Loss есть, то сравним значения перед модификацией
         if(my_pos.pos.sl>0)
           {
            //--- Если выполняется условие на модификацию ордера, т.е. новое значение ниже/выше, 
            //    чем текущее, модифицируем защитный уровень позиции
            if(condition)
              {
               if(!trade.PositionModify(_Symbol,new_sl,my_pos.pos.tp))
                  Print("Ошибка при модификации позиции: ",GetLastError()," - ",ErrorDescription(GetLastError()));
              }
           }
         //--- Если Stop Loss нет, то просто установим его
         if(my_pos.pos.sl==0)
           {
            if(!trade.PositionModify(_Symbol,new_sl,my_pos.pos.tp))
               Print("Ошибка при модификации позиции: ",GetLastError()," - ",ErrorDescription(GetLastError()));
           }
        }
     }
  }
  */
  HisTrade::HisTrade(void) //конструктор класса
   {
 new_trade.Initialization();
   }
  
  HisTrade::~HisTrade(void) //деструктор класса
   {
   
   }