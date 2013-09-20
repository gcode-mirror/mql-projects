//+------------------------------------------------------------------+
//|                                            ColoredTrendEnums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
enum ENUM_TF
  {
   BOTTOM_TF,
   CURRENT_TF,
   TOP_TF
  };
  
enum ENUM_MOVE_TYPE      // Тип движения
  {
   MOVE_TYPE_UNKNOWN = 0,
   MOVE_TYPE_TREND_UP,            // Тренд вверх - синий
   MOVE_TYPE_TREND_UP_FORBIDEN,   // Тренд вверх, запрещенный верхним ТФ - фиолетовый
   MOVE_TYPE_TREND_DOWN,          // Тренд вниз - красный
   MOVE_TYPE_TREND_DOWN_FORBIDEN, // Тренд вниз, запрещенный верхним ТФ - коричневый
   MOVE_TYPE_CORRECTION_UP,       // Коррекция вверх, корректируется тренд вниз - розовый
   MOVE_TYPE_CORRECTION_DOWN,     // Коррекция вниз, корректируется тренд вверх - голубой
   MOVE_TYPE_FLAT,                // Флэт - желтый
  };
  
string MoveTypeToString(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("движение не определено");
      case MOVE_TYPE_TREND_UP: return("тренд вверх");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("тренд вверх запрещен со старшего ТФ");
      case MOVE_TYPE_TREND_DOWN: return("тренд вниз");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("тренд вниз запрещен со старшего ТФ");
      case MOVE_TYPE_CORRECTION_UP: return("коррекция вверх");
      case MOVE_TYPE_CORRECTION_DOWN: return("коррекция вниз");
      case MOVE_TYPE_FLAT: return("флэт");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }
  
string MoveTypeToColor(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("цвет не определен");
      case MOVE_TYPE_TREND_UP: return("синий");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("фиолетовый");
      case MOVE_TYPE_TREND_DOWN: return("красный");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("коричневый");
      case MOVE_TYPE_CORRECTION_UP: return("розовый");
      case MOVE_TYPE_CORRECTION_DOWN: return("голубой");
      case MOVE_TYPE_FLAT: return("желтый");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }

ENUM_TIMEFRAMES GetTopTimeframe(ENUM_TIMEFRAMES timeframe)
{
 switch(timeframe)
 {
      case PERIOD_M1: return(PERIOD_M5);
      case PERIOD_M2: return(PERIOD_M5);
      case PERIOD_M3: return(PERIOD_M15);
      case PERIOD_M4: return(PERIOD_M15);
      case PERIOD_M5: return(PERIOD_M15);
      case PERIOD_M6: return(PERIOD_M15);
      case PERIOD_M10: return(PERIOD_H1);
      case PERIOD_M12: return(PERIOD_H1);
      case PERIOD_M15: return(PERIOD_H1);
      case PERIOD_M20: return(PERIOD_H1);
      case PERIOD_M30: return(PERIOD_H4);
      case PERIOD_H1: return(PERIOD_H4);
      case PERIOD_H2: return(PERIOD_D1);
      case PERIOD_H3: return(PERIOD_D1);
      case PERIOD_H4: return(PERIOD_D1);
      case PERIOD_H6: return(PERIOD_D1);
      case PERIOD_H8: return(PERIOD_D1);
      case PERIOD_D1: return(PERIOD_W1);
      case PERIOD_W1: return(PERIOD_MN1);
      case PERIOD_MN1: return(PERIOD_MN1);
      default: return("Error: unknown period "+(string)timeframe);
 }
}

ENUM_TIMEFRAMES GetBottomTimeframe(ENUM_TIMEFRAMES timeframe)
{
 switch(timeframe)
 {
      case PERIOD_M1: return(PERIOD_M1);
      case PERIOD_M2: return(PERIOD_M1);
      case PERIOD_M3: return(PERIOD_M1);
      case PERIOD_M4: return(PERIOD_M1);
      case PERIOD_M5: return(PERIOD_M1);
      case PERIOD_M6: return(PERIOD_M1);
      case PERIOD_M10: return(PERIOD_M1);
      case PERIOD_M12: return(PERIOD_M1);
      case PERIOD_M15: return(PERIOD_M5);
      case PERIOD_M20: return(PERIOD_M5);
      case PERIOD_M30: return(PERIOD_M5);
      case PERIOD_H1: return(PERIOD_M15);
      case PERIOD_H2: return(PERIOD_M15);
      case PERIOD_H3: return(PERIOD_M15);
      case PERIOD_H4: return(PERIOD_H1);
      case PERIOD_H6: return(PERIOD_H1);
      case PERIOD_H8: return(PERIOD_H1);
      case PERIOD_D1: return(PERIOD_H4);
      case PERIOD_W1: return(PERIOD_D1);
      case PERIOD_MN1: return(PERIOD_W1);
      default: return("Error: unknown period "+(string)timeframe);
 }
}