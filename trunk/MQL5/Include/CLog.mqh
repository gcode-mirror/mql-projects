//+------------------------------------------------------------------+
//|                                                        C_Log.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <config_CLog.mqh>
//#include <ErrorDescription.mqh> 
#define DAY  86400        //60*60*24
#define MgB  1048576      //1024*1024

//-----------------Global-variables----------------------------------+
enum ENUM_OUTPUT
{
 OUT_FILE = 0,        // Создает log-файл
 OUT_ALERT = 1,       // Выводит log алертами
 OUT_COMMENT = 2,     // Выводит log комментариями
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_LOGLEVEL     //уровень логирования
{
 LOG_NONE = 0,        //никакой информации
 LOG_MAIN = 1,        //ключевая информация
 LOG_DEBUG = 2       //информация для дебага
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CLog
{
 private:
  ENUM_OUTPUT _output_type;    // тип вывода информации
  ENUM_LOGLEVEL _level;          // уровень логирования
  int _limit_size;               // предельный размер log-файла в Mb
  string _catalog_name;          // имя каталога для хранения логов
  int _expiration_time;          // время жизни лога в днях
  string _current_filename;

 public:
  CLog();
  CLog(ENUM_OUTPUT output_type, ENUM_LOGLEVEL level, int limit_size, string catalog_name, int expiration_time);
 ~CLog();
  bool Check();
  void Write(ENUM_LOGLEVEL level, string str);
  string CreateNameBase();
  string MakeLogFilenameBase();
  string CreateNameDate();
  string MakeLogFilename(datetime dt);
  string LogLevelString();                                 //возвращает строку с именем перменной из ENUM_LOG_LEVEL
  string PeriodString();                                   //возвращает строку с названием периода
  datetime LogFileDate(string strLogFilename);             //берет дату из названия log-файла
  bool CreateLogFile(datetime dt);                         //создает log-файл
  void DeleteLogFile();                                    //удаляет log-файлы
  void SetOutputType (ENUM_OUTPUT type) { _output_type = type; }
  void SetLogLevel (ENUM_LOGLEVEL level) { _level = level; }
  void SetLimitFileSize (int size) { _limit_size = size; }
  void SetCatalogName (string name) { _catalog_name = name; }
  void SetExpirationTime (int days) { _expiration_time = days; } 
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CLog::CLog()
{
 _output_type = OUT_FILE;
 _level = LOG_DEBUG;         
 _limit_size = 50;          
 _catalog_name = "Log";   
 _expiration_time = 365;
 CreateLogFile(TimeCurrent());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CLog::CLog(ENUM_OUTPUT output_type, ENUM_LOGLEVEL level, int limit_size, string catalog_name, int expiration_time)
{
 _output_type = output_type;
 _level = level;         
 _limit_size = limit_size;          
 _catalog_name = catalog_name;   
 _expiration_time = expiration_time;
 CreateLogFile(TimeCurrent());
}
//+------------------------------------------------------------------+
CLog::~CLog()
{
}
//+------------------------------------------------------------------+
string CLog::CreateNameBase()
{
 string result;
 StringConcatenate(result, MQL5InfoString(MQL5_PROGRAM_NAME), "_", Symbol(), "_", PeriodString());
 return(result);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLog::Check()
{
 static int n = 1;
 if(LogFileDate(_current_filename) != TimeCurrent())
 {
  _current_filename = MakeLogFilename(TimeCurrent());
  n = 1;
  return true;
 }
 else
 {
  int fhandle = FileOpen(_current_filename, FILE_WRITE|FILE_READ|FILE_TXT);
  if(FileSize(fhandle) > _limit_size*MgB)
  {
   StringConcatenate(_current_filename, "_", n);  // заменить когда n> 1  не добавлять а заменять номер n
   n++; 
   FileClose(fhandle);
   return true;
  }
 }
 return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CLog::Write(ENUM_LOGLEVEL level, string str)
{
 Check();
 if(level <= _level)
 {
  switch(_output_type)
  {
   case OUT_FILE:
   {
    int filehandle=FileOpen(_current_filename,FILE_WRITE|FILE_READ|FILE_TXT|FILE_COMMON);
 
    if(filehandle != INVALID_HANDLE)
    {
     FileSeek(filehandle, 0, SEEK_END);
     FileWrite(filehandle, (TimeToString(TimeCurrent(), TIME_SECONDS) + " " + str));
     FileClose(filehandle);
    }
    else
     Alert("Bad filehandle.Name file:", _current_filename);
    break;
   }
   case OUT_COMMENT:
    Print(str);
    break;
   case OUT_ALERT:
    Alert(str);
    break;
  }
 }
}

//+------------------------------------------------------------------+
bool CLog::CreateLogFile(datetime dt)
{
 int error=0;
 _current_filename = MakeLogFilename(dt);
 int filehandle=FileOpen(_current_filename,FILE_WRITE|FILE_TXT|FILE_COMMON);
 
 if(filehandle==INVALID_HANDLE)
 {
  error=::GetLastError();
  Print(__FUNCTION__, " Не удалось создать log-файл с именем : ", _current_filename," Ошибка ",error, ".");
  return(false);
 }
 
 Print(__FUNCTION__, " Удалось создать log-файл с именем : ", _current_filename);
 FileClose(filehandle);
 return(true);
}
//+------------------------------------------------------------------+
void CLog::DeleteLogFile()
{
 string filter;
 StringConcatenate(filter, MakeLogFilenameBase(), "*");
 string search_file = "";
 long search_handle = FileFindFirst(filter, search_file);
 datetime creation_date;

 if(search_handle!=INVALID_HANDLE)
 {
  do
  {
   creation_date=LogFileDate(search_file);//(datetime)StringSubstr(search_file, StringLen(CreateNameBase()), StringLen((string)TimeLocal()));
   if((TimeLocal() - _expiration_time*DAY) > creation_date)
   {
    ResetLastError();
    search_file = _catalog_name+ "\\" + MQL5InfoString(MQL5_PROGRAM_NAME) + "\\" + search_file;
    FileDelete(search_file); 
    PrintFormat("Файл %s удален! Истек период ожидания.Error = %d",__DATETIME__ , search_file, ::GetLastError());
   }
  }
  while(FileFindNext(search_handle,search_file));
  FileFindClose(search_handle);
 }
 else
  PrintFormat("Отсутствуют файлы с маской: ",filter);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
/// Creates a filename base.
/// Used for creating log file wildcard and in constructing log filename
/// \return    The filename base EAlogs\\<EAname>\\<EAname>_<symbol>_<period>
//+------------------------------------------------------------------+
string CLog::MakeLogFilenameBase()
  {
   string strName=MQL5InfoString(MQL5_PROGRAM_NAME);
   return(StringFormat("%s\\%s\\%s_%s_%s", strName, _catalog_name, strName,StringSubstr(_Symbol,0,6),PeriodString()));
  }
//+------------------------------------------------------------------+
/// Creates a filename from date.
/// \param [in] dt Date to add to name for uniqueness
/// \return    The filename EAlogs\\<EAname>\\<EAname>_<symbol>_yyyymmdd_log.txt
//+------------------------------------------------------------------+
string CLog::MakeLogFilename(datetime dt)
{
 MqlDateTime mdt;
 TimeToStruct(dt,mdt);
 return(StringFormat("%s_%d%02d%02d_log.txt",MakeLogFilenameBase(),mdt.year,mdt.mon,mdt.day));
}
//+------------------------------------------------------------------
/// Extracts date from LogFilename.
/// \param [in] strLogFilename   Input filename
/// \return                      datetime of strLogFilename
//+------------------------------------------------------------------+
datetime CLog::LogFileDate(string strLogFilename)
  {
   int len=StringLen(strLogFilename);
   MqlDateTime mdt;
   TimeCurrent(mdt); // just to initialise

                     // ...yyyymmdd_log.txt
   mdt.year = (int)StringToInteger(StringSubstr(strLogFilename,len-16,4));
   mdt.mon  = (int)StringToInteger(StringSubstr(strLogFilename,len-12,2));
   mdt.day  = (int)StringToInteger(StringSubstr(strLogFilename,len-10,2));
   mdt.hour = 0;
   mdt.min  = 0;
   mdt.sec  = 0;
   return(StructToTime(mdt));
  }
  
//+------------------------------------------------------------------+
/// Converts ENUM_LOG_LEVEL into string.
//+------------------------------------------------------------------+
string CLog::LogLevelString()
{
 switch(_level)
 {
  case LOG_NONE: return("LOG_NONE");
  case LOG_MAIN: return("LOG_MAIN");
  case LOG_DEBUG: return("LOG_DEBUG");
  default: return("error: Unknown log level "+(string)_level);
 }
}

//+------------------------------------------------------------------+
/// Converts period to M1, H1, D1 etc
//+------------------------------------------------------------------+
string CLog::PeriodString()
  {
   switch(_Period)
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
      default: return("error: Unknown period "+(string)_Period);
     }
  }
  //+------------------------------------------------------------------+
  
  CLog log_file;