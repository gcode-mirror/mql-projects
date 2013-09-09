//+------------------------------------------------------------------+
//|                                                 PositionEnum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//библиотека перечисления параметрова позиции
struct position_properties
  {
   uint              total_deals;      // Количество сделок
   bool              exists;           // Признак наличия/отсутствия открытой позиции
   string            symbol;           // Символ
   long              magic;            // Магический номер
   string            comment;          // Комментарий
   double            swap;             // Своп
   double            commission;       // Комиссия   
   double            first_deal_price; // Цена первой сделки позиции
   double            price;            // Текущая цена позиции
   double            current_price;    // Текущая цена символа позиции      
   double            last_deal_price;  // Цена последней сделки позиции
   double            profit;           // Прибыль/убыток позиции
   double            volume;           // Текущий объём позиции
   double            initial_volume;   // Начальный объём позиции
   double            sl;               // Stop Loss позиции
   double            tp;               // Take Profit позиции
   datetime          time;             // Время открытия позиции
   ulong             duration;         // Длительность позиции в секундах
   long              id;               // Идентификатор позиции
   ENUM_POSITION_TYPE type;            // Tип позиции
  };
  //--- Перечисление свойств позиции
enum ENUM_POSITION_PROPERTIES
  {
   P_TOTAL_DEALS     = 0,
   P_SYMBOL          = 1,
   P_MAGIC           = 2,
   P_COMMENT         = 3,
   P_SWAP            = 4,
   P_COMMISSION      = 5,
   P_PRICE_FIRST_DEAL= 6,
   P_PRICE_OPEN      = 7,
   P_PRICE_CURRENT   = 8,
   P_PRICE_LAST_DEAL = 9,
   P_PROFIT          = 10,
   P_VOLUME          = 11,
   P_INITIAL_VOLUME  = 12,
   P_SL              = 13,
   P_TP              = 14,
   P_TIME            = 15,
   P_DURATION        = 16,
   P_ID              = 17,
   P_TYPE            = 18,
   P_ALL             = 19
  };
  //--- Длительность позиции
enum ENUM_POSITION_DURATION
  {
   DAYS     = 0, // Дни
   HOURS    = 1, // Часы
   MINUTES  = 2, // Минуты
   SECONDS  = 3  // Секунды
  };
  
