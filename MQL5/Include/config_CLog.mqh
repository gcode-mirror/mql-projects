//+------------------------------------------------------------------+
//|                                                 config_C_Log.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define CONF_EXPIRATION_TIME 30              // время жизни лога в днях
#define CONF_LIMIT_SIZE 50                   // предельный размер log-файла в Mb
#define CONF_LOG_LEVEL LOG_DEBUG             // уровень логирования
#define CONF_CATALOG_NAME "CTMLog"           // имя каталога для хранения логов
#define CONF_OUT_TYPE OUT_COMMENT

