//+------------------------------------------------------------------+
//|                                              StringUtilities.mqh |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
/// Converts Return codes to string.
/// \param [in]   Return code from trade request
/// \return       Desciption of return code
//+------------------------------------------------------------------+
string ReturnCodeDescription(uint retcode)
  {
   switch(retcode)
     {
     // updated 20/11/2011
      case TRADE_RETCODE_REQUOTE: return("Requote");
      case TRADE_RETCODE_REJECT: return("Request rejected");
      case TRADE_RETCODE_CANCEL: return("Request canceled by trader");
      case TRADE_RETCODE_PLACED: return("Order placed");
      case TRADE_RETCODE_DONE: return("Request completed");
      case TRADE_RETCODE_DONE_PARTIAL: return("Only part of the request was completed");
      case TRADE_RETCODE_ERROR: return("Request processing error");
      case TRADE_RETCODE_TIMEOUT: return("Request canceled by timeout");
      case TRADE_RETCODE_INVALID: return("Invalid request");
      case TRADE_RETCODE_INVALID_VOLUME: return("Invalid volume in the request");
      case TRADE_RETCODE_INVALID_PRICE: return("Invalid price in the request");
      case TRADE_RETCODE_INVALID_STOPS: return("Invalid stops in the request");
      case TRADE_RETCODE_TRADE_DISABLED: return("Trade is disabled");
      case TRADE_RETCODE_MARKET_CLOSED: return("Market is closed");
      case TRADE_RETCODE_NO_MONEY: return("There is not enough money to complete the request");
      case TRADE_RETCODE_PRICE_CHANGED: return("Prices changed");
      case TRADE_RETCODE_PRICE_OFF: return("There are no quotes to process the request");
      case TRADE_RETCODE_INVALID_EXPIRATION: return("Invalid order expiration date in the request");
      case TRADE_RETCODE_ORDER_CHANGED: return("Order state changed");
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return("Too frequent requests");
      case TRADE_RETCODE_NO_CHANGES: return("No changes in request");
      case TRADE_RETCODE_SERVER_DISABLES_AT: return("Autotrading disabled by server");
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return("Autotrading disabled by client terminal");
      case TRADE_RETCODE_LOCKED: return("Request locked for processing");
      case TRADE_RETCODE_FROZEN: return("Order or position frozen");
      case TRADE_RETCODE_INVALID_FILL: return("Invalid order filling type");
      case TRADE_RETCODE_CONNECTION: return("No connection with the trade server");
      case TRADE_RETCODE_ONLY_REAL: return("Operation is allowed only for live accounts");
      case TRADE_RETCODE_LIMIT_ORDERS: return("The number of pending orders has reached the limit");
      case TRADE_RETCODE_LIMIT_VOLUME: return("The volume of orders and positions for the symbol has reached the limit");
      default: return("Error: unknown retcode "+(string)retcode);
     }
  }
//+------------------------------------------------------------------+
/// Converts Errors to string.
/// \param [in]   error, usually from GetLastError()
/// \return       Description of error
//+------------------------------------------------------------------+
string ErrorDescription(int nError)
  {
   if(nError>ERR_USER_ERROR_FIRST) return("User defined error");
   switch(nError)
     {
     // updated 20/11/2011
      case ERR_SUCCESS: return("The operation completed successfully");
      case ERR_INTERNAL_ERROR: return("Unexpected internal error");
      case ERR_WRONG_INTERNAL_PARAMETER: return("Wrong parameter in the inner call of the client terminal function");
      case ERR_INVALID_PARAMETER: return("Wrong parameter when calling the system function");
      case ERR_NOT_ENOUGH_MEMORY: return("Not enough memory to perform the system function");
      case ERR_STRUCT_WITHOBJECTS_ORCLASS: return("The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes");
      case ERR_INVALID_ARRAY: return("Array of a wrong type, wrong size, or a damaged object of a dynamic array");
      case ERR_ARRAY_RESIZE_ERROR: return("Not enough memory for the relocation of an array, or an attempt to change the size of a static array");
      case ERR_STRING_RESIZE_ERROR: return("Not enough memory for the relocation of string");
      case ERR_NOTINITIALIZED_STRING: return("Not initialized string");
      case ERR_INVALID_DATETIME: return("Invalid date and/or time");
      case ERR_ARRAY_BAD_SIZE: return("Requested array size exceeds 2 GB");
      case ERR_INVALID_POINTER: return("Wrong pointer");
      case ERR_INVALID_POINTER_TYPE: return("Wrong type of pointer");
      case ERR_FUNCTION_NOT_ALLOWED: return("System function is not allowed to call");

      // Charts
      case ERR_CHART_WRONG_ID: return("Wrong chart ID");
      case ERR_CHART_NO_REPLY: return("Chart does not respond");
      case ERR_CHART_NOT_FOUND: return("Chart not found");
      case ERR_CHART_NO_EXPERT: return("No Expert Advisor in the chart that could handle the event");
      case ERR_CHART_CANNOT_OPEN: return("Chart opening error");
      case ERR_CHART_CANNOT_CHANGE: return("Failed to change chart symbol and period");
      case ERR_CHART_WRONG_PARAMETER: return("Wrong parameter for timer");
      case ERR_CHART_CANNOT_CREATE_TIMER: return("Failed to create timer");
      case ERR_CHART_WRONG_PROPERTY: return("Wrong chart property ID");
      case ERR_CHART_SCREENSHOT_FAILED: return("Error creating screenshots");
      case ERR_CHART_NAVIGATE_FAILED: return("Error navigating through chart");
      case ERR_CHART_TEMPLATE_FAILED: return("Error applying template");
      case ERR_CHART_WINDOW_NOT_FOUND: return("Subwindow containing the indicator was not found");
      case ERR_CHART_INDICATOR_CANNOT_ADD: return("Error adding an indicator to chart");
      case ERR_CHART_INDICATOR_CANNOT_DEL: return("Error deleting an indicator from the chart");
      case ERR_CHART_INDICATOR_NOT_FOUND: return("Indicator not found on the specified chart");

      // Graphical Objects
      case ERR_OBJECT_ERROR: return("Error working with a graphical object");
      case ERR_OBJECT_NOT_FOUND: return("Graphical object was not found");
      case ERR_OBJECT_WRONG_PROPERTY: return("Wrong ID of a graphical object property");
      case ERR_OBJECT_GETDATE_FAILED: return("Unable to get date corresponding to the value");
      case ERR_OBJECT_GETVALUE_FAILED: return("Unable to get value corresponding to the date");

      // MarketInfo
      case ERR_MARKET_UNKNOWN_SYMBOL: return("Unknown symbol");
      case ERR_MARKET_NOT_SELECTED: return("Symbol is not selected in MarketWatch");
      case ERR_MARKET_WRONG_PROPERTY: return("Wrong identifier of a symbol property");
      case ERR_MARKET_LASTTIME_UNKNOWN: return("Time of the last tick is not known (no ticks)");
      case ERR_MARKET_SELECT_ERROR: return("Error adding or deleting a symbol in MarketWatch");

      // History Access
      case ERR_HISTORY_NOT_FOUND: return("Requested history not found");
      case ERR_HISTORY_WRONG_PROPERTY: return("Wrong ID of the history property");

      // Global_Variables
      case ERR_GLOBALVARIABLE_NOT_FOUND: return("Global variable of the client terminal is not found");
      case ERR_GLOBALVARIABLE_EXISTS: return("Global variable of the client terminal with the same name already exists");
      case ERR_MAIL_SEND_FAILED: return("Email sending failed");
      case ERR_PLAY_SOUND_FAILED : return("Sound playing failed");
      case ERR_MQL5_WRONG_PROPERTY : return("Wrong identifier of the program property");
      case ERR_TERMINAL_WRONG_PROPERTY: return("Wrong identifier of the terminal property");
      case ERR_FTP_SEND_FAILED: return("File sending via ftp failed");

      // Custom Indicator Buffers
      case ERR_BUFFERS_NO_MEMORY: return("Not enough memory for the distribution of indicator buffers");
      case ERR_BUFFERS_WRONG_INDEX: return("Wrong indicator buffer index");

      // Custom Indicator Properties
      case ERR_CUSTOM_WRONG_PROPERTY: return("Wrong ID of the custom indicator property");

      // Account
      case ERR_ACCOUNT_WRONG_PROPERTY: return("Wrong account property ID");
      case ERR_TRADE_WRONG_PROPERTY: return("Wrong trade property ID");
      case ERR_TRADE_DISABLED: return("Trading by Expert Advisors prohibited");
      case ERR_TRADE_POSITION_NOT_FOUND: return("Position not found");
      case ERR_TRADE_ORDER_NOT_FOUND: return("Order not found");
      case ERR_TRADE_DEAL_NOT_FOUND: return("Deal not found");
      case ERR_TRADE_SEND_FAILED: return("Trade request sending failed");

      // Indicators
      case ERR_INDICATOR_UNKNOWN_SYMBOL: return("Unknown symbol");
      case ERR_INDICATOR_CANNOT_CREATE: return("Indicator cannot be created");
      case ERR_INDICATOR_NO_MEMORY: return("Not enough memory to add the indicator");
      case ERR_INDICATOR_CANNOT_APPLY: return("The indicator cannot be applied to another indicator");
      case ERR_INDICATOR_CANNOT_ADD: return("Error applying an indicator to chart");
      case ERR_INDICATOR_DATA_NOT_FOUND: return("Requested data not found");
      case ERR_INDICATOR_WRONG_HANDLE: return("Wrong indicator handle");
      case ERR_INDICATOR_WRONG_PARAMETERS: return("Wrong number of parameters when creating an indicator");
      case ERR_INDICATOR_PARAMETERS_MISSING: return("No parameters when creating an indicator");
      case ERR_INDICATOR_CUSTOM_NAME: return("The first parameter in the array must be the name of the custom indicator");
      case ERR_INDICATOR_PARAMETER_TYPE: return("Invalid parameter type in the array when creating an indicator");
      case ERR_INDICATOR_WRONG_INDEX: return("Wrong index of the requested indicator buffer");

      // Depth of Market
      case ERR_BOOKS_CANNOT_ADD: return("Depth Of Market can not be added");
      case ERR_BOOKS_CANNOT_DELETE: return("Depth Of Market can not be removed");
      case ERR_BOOKS_CANNOT_GET: return("The data from Depth Of Market can not be obtained");
      case ERR_BOOKS_CANNOT_SUBSCRIBE: return("Error in subscribing to receive new data from Depth Of Market");

      // File Operations
      case ERR_TOO_MANY_FILES: return("More than 64 files cannot be opened at the same time");
      case ERR_WRONG_FILENAME: return("Invalid file name");
      case ERR_TOO_LONG_FILENAME: return("Too long file name");
      case ERR_CANNOT_OPEN_FILE: return("File opening error");
      case ERR_FILE_CACHEBUFFER_ERROR: return("Not enough memory for cache to read");
      case ERR_CANNOT_DELETE_FILE: return("File deleting error");
      case ERR_INVALID_FILEHANDLE: return("A file with this handle was closed, or was not opening at all");
      case ERR_WRONG_FILEHANDLE: return("Wrong file handle");
      case ERR_FILE_NOTTOWRITE: return("The file must be opened for writing");
      case ERR_FILE_NOTTOREAD: return("The file must be opened for reading");
      case ERR_FILE_NOTBIN: return("The file must be opened as a binary one");
      case ERR_FILE_NOTTXT: return("The file must be opened as a text");
      case ERR_FILE_NOTTXTORCSV: return("The file must be opened as a text or CSV");
      case ERR_FILE_NOTCSV: return("The file must be opened as CSV");
      case ERR_FILE_READERROR: return("File reading error");
      case ERR_FILE_BINSTRINGSIZE: return("String size must be specified, because the file is opened as binary");
      case ERR_INCOMPATIBLE_FILE: return("A text file must be for string arrays, for other arrays - binary");
      case ERR_FILE_IS_DIRECTORY: return("This is not a file, this is a directory");
      case ERR_FILE_NOT_EXIST: return("File does not exist");
      case ERR_FILE_CANNOT_REWRITE: return("File can not be rewritten");
      case ERR_WRONG_DIRECTORYNAME: return("Wrong directory name");
      case ERR_DIRECTORY_NOT_EXIST: return("Directory does not exist");
      case ERR_FILE_ISNOT_DIRECTORY: return("This is a file, not a directory");
      case ERR_CANNOT_DELETE_DIRECTORY: return("The directory cannot be removed");
      case ERR_CANNOT_CLEAN_DIRECTORY: return("Failed to clear the directory (probably one or more files are blocked and removal operation failed)");

      // String Casting
      case ERR_NO_STRING_DATE: return("No date in the string");
      case ERR_WRONG_STRING_DATE: return("Wrong date in the string");
      case ERR_WRONG_STRING_TIME: return("Wrong time in the string");
      case ERR_STRING_TIME_ERROR: return("Error converting string to date");
      case ERR_STRING_OUT_OF_MEMORY: return("Not enough memory for the string");
      case ERR_STRING_SMALL_LEN: return("The string length is less than expected");
      case ERR_STRING_TOO_BIGNUMBER: return("Too large number, more than ULONG_MAX");
      case ERR_WRONG_FORMATSTRING: return("Invalid format string");
      case ERR_TOO_MANY_FORMATTERS: return("Amount of format specifiers more than the parameters");
      case ERR_TOO_MANY_PARAMETERS: return("Amount of parameters more than the format specifiers");
      case ERR_WRONG_STRING_PARAMETER: return("Damaged parameter of string type");
      case ERR_STRINGPOS_OUTOFRANGE: return("Position outside the string");
      case ERR_STRING_ZEROADDED: return("0 added to the string end, a useless operation");
      case ERR_STRING_UNKNOWNTYPE: return("Unknown data type when converting to a string");
      case ERR_WRONG_STRING_OBJECT: return("Damaged string object");

      // Operations with Arrays
      case ERR_INCOMPATIBLE_ARRAYS: return("Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only");
      case ERR_SMALL_ASSERIES_ARRAY: return("The receiving array is declared as AS_SERIES, and it is of insufficient size");
      case ERR_SMALL_ARRAY: return("Too small array, the starting position is outside the array");
      case ERR_ZEROSIZE_ARRAY: return("An array of zero length");
      case ERR_NUMBER_ARRAYS_ONLY: return("Must be a numeric array");
      case ERR_ONEDIM_ARRAYS_ONLY: return("Must be a one-dimensional array");
      case ERR_SERIES_ARRAY: return("Timeseries cannot be used");
      case ERR_DOUBLE_ARRAY_ONLY: return("Must be an array of type double");
      case ERR_FLOAT_ARRAY_ONLY: return("Must be an array of type float");
      case ERR_LONG_ARRAY_ONLY: return("Must be an array of type long");
      case ERR_INT_ARRAY_ONLY: return("Must be an array of type int");
      case ERR_SHORT_ARRAY_ONLY: return("Must be an array of type short");
      case ERR_CHAR_ARRAY_ONLY: return("Must be an array of type char");
      default: return("Warning: error number "+(string)nError+" not found");
     }
  }
//+------------------------------------------------------------------+
/// Converts bool to string.
/// \param [in]   bool
/// \return       "true" or "false"
//+------------------------------------------------------------------+
string BoolToString(bool b)
  {
   if(b) return("true");
   else return("false");
  }
//+------------------------------------------------------------------+
/// Describes period
/// \param [in]   Period
/// \return       Description of period
//+------------------------------------------------------------------+
string PeriodDescription(ENUM_TIMEFRAMES enumPeriod)
  {
   switch(enumPeriod)
     {
      case PERIOD_M1: return("1 minute");
      case PERIOD_M2: return("2 minute");
      case PERIOD_M3: return("3 minute");
      case PERIOD_M4: return("4 minute");
      case PERIOD_M5: return("5 minute");
      case PERIOD_M6: return("6 minute");
      case PERIOD_M10: return("10 minute");
      case PERIOD_M12: return("12 minute");
      case PERIOD_M15: return("15 minute");
      case PERIOD_M20: return("20 minute");
      case PERIOD_M30: return("30 minute");
      case PERIOD_H1: return("1 hour");
      case PERIOD_H2: return("2 hour");
      case PERIOD_H3: return("3 hour");
      case PERIOD_H4: return("4 hour");
      case PERIOD_H6: return("6 hour");
      case PERIOD_H8: return("8 hour");
      case PERIOD_D1: return("daily");
      case PERIOD_W1: return("weekly");
      case PERIOD_MN1: return("monthly");
      default: return("Error: unknown period "+(string)enumPeriod);
     }
  }
//+------------------------------------------------------------------+
/// Describes period
/// \param [in]   Period
/// \return       Description of period
//+------------------------------------------------------------------+
string PeriodToString(ENUM_TIMEFRAMES enumPeriod)
  {
   switch(enumPeriod)
     {
      case PERIOD_M1: return("M1");
      case PERIOD_M2: return("M2");
      case PERIOD_M3: return("M3");
      case PERIOD_M4: return("M4");
      case PERIOD_M5: return("M5");
      case PERIOD_M6: return("M6");
      case PERIOD_M10: return("M10");
      case PERIOD_M12: return("M12");
      case PERIOD_M15: return("M15");
      case PERIOD_M20: return("M20");
      case PERIOD_M30: return("M30");
      case PERIOD_H1: return("H1");
      case PERIOD_H2: return("H2");
      case PERIOD_H3: return("H3");
      case PERIOD_H4: return("H4");
      case PERIOD_H6: return("H6");
      case PERIOD_H8: return("H8");
      case PERIOD_D1: return("D1");
      case PERIOD_W1: return("W1");
      case PERIOD_MN1: return("MN1");
      default: return("Error: unknown period "+(string)enumPeriod);
     }
  }
//+------------------------------------------------------------------+
/// Converts color to string.
/// \param [in]   clr
/// \return       Name of clr
//+------------------------------------------------------------------+
string ColorToStr(color clr)
  {
   switch(clr)
     {
      case CLR_NONE: return("No color");
      case Black: return("Black");
      case DarkGreen: return("DarkGreen");
      case DarkSlateGray: return("DarkSlateGray");
      case Olive: return("Olive");
      case Green: return("Green");
      case Teal: return("Teal");
      case Navy: return("Navy");
      case Purple: return("Purple");
      case Maroon: return("Maroon");
      case Indigo: return("Indigo");
      case MidnightBlue: return("MidnightBlue");
      case DarkBlue: return("DarkBlue");
      case DarkOliveGreen: return("DarkOliveGreen");
      case SaddleBrown: return("SaddleBrown");
      case ForestGreen: return("ForestGreen");
      case OliveDrab: return("OliveDrab");
      case SeaGreen: return("SeaGreen");
      case DarkGoldenrod: return("DarkGoldenrod");
      case DarkSlateBlue: return("DarkSlateBlue");
      case Sienna: return("Sienna");
      case MediumBlue: return("MediumBlue");
      case Brown: return("Brown");
      case DarkTurquoise: return("DarkTurquoise");
      case DimGray: return("DimGray");
      case LightSeaGreen: return("LightSeaGreen");
      case DarkViolet: return("DarkViolet");
      case FireBrick: return("FireBrick");
      case MediumVioletRed: return("MediumVioletRed");
      case MediumSeaGreen: return("MediumSeaGreen");
      case Chocolate: return("Chocolate");
      case Crimson: return("Crimson");
      case SteelBlue: return("SteelBlue");
      case Goldenrod: return("Goldenrod");
      case MediumSpringGreen: return("MediumSpringGreen");
      case LawnGreen: return("LawnGreen");
      case CadetBlue: return("CadetBlue");
      case DarkOrchid: return("DarkOrchid");
      case YellowGreen: return("YellowGreen");
      case LimeGreen: return("LimeGreen");
      case OrangeRed: return("OrangeRed");
      case DarkOrange: return("DarkOrange");
      case Orange: return("Orange");
      case Gold: return("Gold");
      case Yellow: return("Yellow");
      case Chartreuse : return("Chartreuse ");
      case Lime: return("Lime");
      case SpringGreen: return("SpringGreen");
      case Aqua: return("Aqua");
      case DeepSkyBlue: return("DeepSkyBlue");
      case Blue: return("Blue");
      case Magenta: return("Magenta");
      case Red: return("Red");
      case Gray: return("Gray");
      case SlateGray: return("SlateGray");
      case Peru: return("Peru");
      case BlueViolet: return("BlueViolet");
      case LightSlateGray: return("LightSlateGray");
      case DeepPink: return("DeepPink");
      case MediumTurquoise: return("MediumTurquoise");
      case DodgerBlue: return("DodgerBlue");
      case Turquoise: return("Turquoise");
      case RoyalBlue: return("RoyalBlue");
      case SlateBlue: return("SlateBlue");
      case DarkKhaki: return("DarkKhaki");
      case IndianRed: return("IndianRed");
      case MediumOrchid: return("MediumOrchid");
      case GreenYellow: return("GreenYellow");
      case MediumAquamarine: return("MediumAquamarine");
      case DarkSeaGreen: return("DarkSeaGreen");
      case Tomato: return("Tomato");
      case RosyBrown: return("RosyBrown");
      case Orchid: return("Orchid");
      case MediumPurple: return("MediumPurple");
      case PaleVioletRed: return("PaleVioletRed");
      case Coral: return("Coral");
      case CornflowerBlue: return("CornflowerBlue");
      case DarkGray: return("DarkGray");
      case SandyBrown: return("SandyBrown");
      case MediumSlateBlue: return("MediumSlateBlue");
      case Tan: return("Tan");
      case DarkSalmon: return("DarkSalmon");
      case BurlyWood: return("BurlyWood");
      case HotPink: return("HotPink");
      case Salmon: return("Salmon");
      case Violet: return("Violet");
      case LightCoral: return("LightCoral");
      case SkyBlue: return("SkyBlue");
      case LightSalmon: return("LightSalmon");
      case Plum: return("Plum");
      case Khaki: return("Khaki");
      case LightGreen: return("LightGreen");
      case Aquamarine: return("Aquamarine");
      case Silver: return("Silver");
      case LightSkyBlue: return("LightSkyBlue");
      case LightSteelBlue: return("LightSteelBlue");
      case LightBlue: return("LightBlue");
      case PaleGreen: return("PaleGreen");
      case Thistle: return("Thistle");
      case PowderBlue: return("PowderBlue");
      case PaleGoldenrod: return("PaleGoldenrod");
      case PaleTurquoise: return("PaleTurquoise");
      case LightGray: return("LightGray");
      case Wheat: return("Wheat");
      case NavajoWhite: return("NavajoWhite");
      case Moccasin: return("Moccasin");
      case LightPink: return("LightPink");
      case Gainsboro: return("Gainsboro");
      case PeachPuff: return("PeachPuff");
      case Pink: return("Pink");
      case Bisque: return("Bisque");
      case LightGoldenrod: return("LightGoldenrod");
      case BlanchedAlmond: return("BlanchedAlmond");
      case LemonChiffon: return("LemonChiffon");
      case Beige: return("Beige");
      case AntiqueWhite: return("AntiqueWhite");
      case PapayaWhip: return("PapayaWhip");
      case Cornsilk: return("Cornsilk");
      case LightYellow: return("LightYellow");
      case LightCyan: return("LightCyan");
      case Linen: return("Linen");
      case Lavender: return("Lavender");
      case MistyRose: return("MistyRose");
      case OldLace: return("OldLace");
      case WhiteSmoke: return("WhiteSmoke");
      case Seashell: return("Seashell");
      case Ivory: return("Ivory");
      case Honeydew: return("Honeydew");
      case AliceBlue: return("AliceBlue");
      case LavenderBlush: return("LavenderBlush");
      case MintCream: return("MintCream");
      case Snow: return("Snow");
      case White: return("White");
      default: return("Error: unknown color "+string(clr));
     }
  }
//+------------------------------------------------------------------+
/// Converts day of week to string.
/// \param [in]   nDay, Sunday = 0
/// \return       Name of day
//+------------------------------------------------------------------+
string DayOfWeekToString(int nDay)
  {
   switch(nDay)
     {
      case 0: return("Sunday");
      case 1: return("Monday");
      case 2: return("Tuesday");
      case 3: return("Wednesday");
      case 4: return("Thursday");
      case 5: return("Friday");
      case 6: return("Saturday");
      default: return("Error: unknown day "+(string)nDay);
     }
  }
//+------------------------------------------------------------------+
/// Converts Order type to string.
/// \param [in]   enumOrderType  Order Type
/// \return       					Name of Order
//+------------------------------------------------------------------+
string OrderTypeToString(ENUM_ORDER_TYPE enumOrderType)
  {
   switch(enumOrderType)
     {
      case ORDER_TYPE_BUY: return("ORDER_TYPE_BUY");
      case ORDER_TYPE_SELL: return("ORDER_TYPE_SELL");
      case ORDER_TYPE_BUY_LIMIT: return("ORDER_TYPE_BUY_LIMIT");
      case ORDER_TYPE_SELL_LIMIT: return("ORDER_TYPE_SELL_LIMIT");
      case ORDER_TYPE_BUY_STOP: return("ORDER_TYPE_BUY_STOP");
      case ORDER_TYPE_SELL_STOP: return("ORDER_TYPE_SELL_STOP");
      case ORDER_TYPE_BUY_STOP_LIMIT: return("ORDER_TYPE_BUY_STOP_LIMIT");
      case ORDER_TYPE_SELL_STOP_LIMIT: return("ORDER_TYPE_SELL_STOP_LIMIT");
      default: return("Error: unknown order type"+(string)enumOrderType);
     }
  }
//+------------------------------------------------------------------+
/// Returns description of order state.
/// \param [in]   enumOrderState Order state
/// \return       Desciption of order state
//+------------------------------------------------------------------+
string OrderStateDescription(ENUM_ORDER_STATE enumOrderState)
  {
   switch(enumOrderState)
     {
      case ORDER_STATE_STARTED: return("Order checked, but not yet accepted by broker");
      case ORDER_STATE_PLACED: return("Order accepted");
      case ORDER_STATE_CANCELED: return("Order canceled");
      case ORDER_STATE_PARTIAL: return("Order partially executed");
      case ORDER_STATE_FILLED: return("Order fully executed");
      case ORDER_STATE_REJECTED: return("Order rejected");
      case ORDER_STATE_EXPIRED: return("Order expired");
      default: return("Error: unknown order state"+(string)enumOrderState);
     }
  }
//+------------------------------------------------------------------+
/// Converts Position type to string.
/// \param [in]   enumPositionType  Position Type
/// \return       					Name of Position type
//+------------------------------------------------------------------+
string PositionTypeToString(ENUM_POSITION_TYPE enumPositionType)
  {
   switch(enumPositionType)
     {
      case POSITION_TYPE_BUY: return(" POSITION_TYPE_BUY");
      case POSITION_TYPE_SELL: return("POSITION_TYPE_SELL");
      default: return("Error: unknown position type"+(string)enumPositionType);
     }
  }
//+------------------------------------------------------------------+
/// Return string list of all array elements
/// \param [in] Arr[] double array
/// \return     string list of all array elements
//+------------------------------------------------------------------+
string DoubleArrayToString(double &Arr[])
  {
   int nSize = ArraySize(Arr);
   string str="{";
   if(nSize>0) str=str+(string)Arr[0];
   for(int i=1;i<ArraySize(Arr);i++)
     {
      str=str+","+(string)Arr[i];
     }
   str=str+"}";
   return(str);
  }
//+------------------------------------------------------------------+
/// Return string list of all array elements
/// \param [in] Arr[] double array
/// \return     string list of all array elements
//+------------------------------------------------------------------+
string IntArrayToString(int &Arr[])
  {
   int nSize = ArraySize(Arr);
   string str="{";
   if(nSize>0) str=str+(string)Arr[0];
   for(int i=1;i<ArraySize(Arr);i++)
     {
      str=str+","+(string)Arr[i];
     }
   str=str+"}";
   return(str);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TimeToExcelString(const datetime dt)
  {
   MqlDateTime mdt; TimeToStruct(dt,mdt);
   return(StringFormat("%02d/%02d/%d %d:%02d:%02d",mdt.day,mdt.mon,mdt.year,mdt.hour,mdt.min,mdt.sec));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MonthTo3String(int nMonth)
  {
   switch(nMonth)
     {
      case 1: return("Jan");
      case 2: return("Feb");
      case 3: return("Mar");
      case 4: return("Apr");
      case 5: return("May");
      case 6: return("Jun");
      case 7: return("Jul");
      case 8: return("Aug");
      case 9: return("Sep");
      case 10: return("Oct");
      case 11: return("Nov");
      case 12: return("Dec");
      default: return("???");
     }
  }

string OrderTypeTimeToString(const uint type)
  {
   switch(type)
     {
      case ORDER_TIME_GTC          : return("gtc");
      case ORDER_TIME_DAY          : return("day");
      case ORDER_TIME_SPECIFIED    : return("specified");
      case ORDER_TIME_SPECIFIED_DAY: return("specified day");
      default:
         return("unknown type time "+(string)type);
     }
}
//+------------------------------------------------------------------+
