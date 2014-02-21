//+------------------------------------------------------------------+
//|                                                    Utilities.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

enum DELTA_STEP
{
 ONE = 1,
 TWO = 2,
 FOUR = 4,
 FIVE = 5,
 TEN = 10,
 TWENTY = 20,
 TWENTY_FIVE = 25,
 FIFTY = 50,
 HUNDRED = 100
};


enum ENUM_PERIOD
{
 Day,
 Month
};

struct SExtremum
{
 int direction;
 double price;
};

enum ENUM_LEVELS
{
 LEVEL_MINIMUM,
 LEVEL_AVEMIN,
 LEVEL_START,
 LEVEL_AVEMAX,
 LEVEL_MAXIMUM
};

string LevelToString(ENUM_LEVELS level)
{
 string res;
 switch (level)
 {
  case LEVEL_MAXIMUM:
   res = "level maximum";
   break;
  case LEVEL_MINIMUM:
   res = "level minimum";
   break;
  case LEVEL_AVEMAX:
   res = "level ave_max";
   break;
  case LEVEL_AVEMIN:
   res = "level ave_min";
   break;
  case LEVEL_START:
   res = "level start";
   break;
 }
 return res;
}