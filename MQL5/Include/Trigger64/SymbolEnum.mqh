//+------------------------------------------------------------------+
//|                                                   SymbolEnum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| структура перечисления параметров символа                        |
//+------------------------------------------------------------------+
struct symbol_properties
  {
   int               digits;        // Количество знаков в цене после запятой
   int               spread;        // Размер спреда в пунктах
   int               stops_level;   // Ограничитель установки Stop ордеров
   double            point;         // Значение одного пункта
   double            ask;           // Цена ask
   double            bid;           // Цена bid
   double            volume_min;    // Минимальный объем для заключения сделки
   double            volume_max;    // Максимальный объем для заключения сделки
   double            volume_limit;  // Максимально допустимый объем для позиции и ордеров в одном направлении
   double            volume_step;   // Минимальный шаг изменения объема для заключения сделки
   double            offset;        // Отступ от максимально возможной цены для операции
   double            up_level;      // Цена верхнего уровня stop level
   double            down_level;    // Цена нижнего уровня stop level
  };
//+------------------------------------------------------------------+
//| перечисление свойств символа                                     |
//+------------------------------------------------------------------+
enum ENUM_SYMBOL_PROPERTIES
  {
   S_DIGITS       = 0,
   S_SPREAD       = 1,
   S_STOPSLEVEL   = 2,
   S_POINT        = 3,
   S_ASK          = 4,
   S_BID          = 5,
   S_VOLUME_MIN   = 6,
   S_VOLUME_MAX   = 7,
   S_VOLUME_LIMIT = 8,
   S_VOLUME_STEP  = 9,
   S_FILTER       = 10,
   S_UP_LEVEL     = 11,
   S_DOWN_LEVEL   = 12,
   S_ALL          = 13
  };