//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+

#include "StringUtilities.mqh"
//+------------------------------------------------------------------+
/// Used to control the quantity and detail of logs produced by CLog.
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL
  {
   /// No logging - not normally used, but may be useful for testing
   LOG_NONE,
   /// Use for major events which will also be printed in the terminal log   
   LOG_PRINT,
   /// use for major events such as results of trading or errors  
   LOG_MAJOR,
   /// Use to record status and events which would not affect normal running of the code  
   LOG_DEBUG,
   /// Use to track detailed and frequent code events for debugging 
   LOG_VERBOSE
  };
//+------------------------------------------------------------------+
/** A utility to assist with monitoring and debugging.
 
\b Features
	- Records logging activity in Files\\EAlogs\\<EAname>\\<EAname>_<symbol>_yyyymmdd_log.txt
	- Four levels of logging, see ENUM_LOG_LEVEL, default LOG_DEBUG
	- No logging during optimisation
	- Logging is via Print commands when testing, ie log messages appear in Strategy Tester window
	- On restart, will open up an existing log file and continue writing to it.
	
<b> Example of usage </b>

\code
input ENUM_LOG_LEVEL LogLevel = LOG_VERBOSE;

OnInit()
{
	LogFile.LogLevel(LogLevel);
}

bool MyFunction(int param1, double param2)
{
	LOG(LOG_DEBUG,__FUNCTION__,"StringFormat("Entry to MyFunction(%d,%f)",param1,param2)); 
	
	bool bReturn = false;
	
	for (int i=0 ; i<1000 ; i++)
	{
		LOG(LOG_VERBOSE,__FUNCTION__,(string)i);
	}

	if (bReturn)
	{	
 		LOG(LOG_MAJOR,__FUNCTION__,StringFormat("MyFunction(%d,%f) returning true",param1,param2));
	}
	else
	{
		LOG(LOG_PRINT,__FUNCTION__,StringFormat("MyFunction(%d,%f) returning false",param1,param2));
	}
	return(bReturn);
}
\endcode
*/

class CLog
  {
private:
   bool              m_bReducedLogging;            ///< True if max log filesize has been reached
   ENUM_LOG_LEVEL    m_LogLevel;                   ///< Logging level, accessed with LogLevel().
   string            m_strFilename;                ///< Filename of the current log, set by Log(), accessed with Filename().
   uint              m_uLogFileMaxAgeDays;         ///< Number of days before Logfiles are deleted to manage filespace. Accessed with MaxLogAgeDays()
   uint              m_uLogStartDaysSince1970;     ///< Used to detect a new day.
   ulong             m_ulMaxLogfileSize;           ///< Max daily file size in bytes before logging is reduced or stopped. Accessed with MaxLogFileSizeMB()
   bool              m_bLogToFileWhileTesting;      ///< Can switch log to file on or off

protected:
   void              CleanUpOldLogs();             ///< Deletes all log files older than MaxLogAgeDays().
   string            MakeLogFilename(datetime dt); ///< Creates a filename from date.
   string            MakeLogFilenameBase();        ///< Creates a filename base.
   datetime          LogFileDate(string strLogFilename); ///< Extracts date from LogFilename.
   string            LogLevelString();             ///< Converts ENUM_LOG_LEVEL into string.
   string            PeriodString();               ///< Converts period to M1, H1, D1 etc.

public:
                     CLog(); ///< Constructor setting default parameters.
   void              Delete(){ if(FileIsExist(m_strFilename)) FileDelete(m_strFilename); } ///< Deletes the currently named log file.
   string            Filename(){return(m_strFilename);} ///< Gets current filename set by Log().
                                                        /// The main logging function.
   void              Log(const ENUM_LOG_LEVEL Level,string s1="",string s2="",string s3="",string s4="",string s5="",string s6="",string s7="",string s8="",string s9="",string s10="");
   /// Sets logging level.
   ENUM_LOG_LEVEL    LogLevel(const ENUM_LOG_LEVEL Level)
     {
      if(m_LogLevel!=Level)
        {
         m_LogLevel=Level;
         if(Level==LOG_NONE) Print("No logging active because log level has been set to ",LogLevelString());
         else if((bool)MQL5InfoInteger(MQL5_TESTING)) Print("Logging at level ",LogLevelString()," to terminal logfile");
         else Print("Logging at level ",LogLevelString()," to file ",Filename());
        }
      return(m_LogLevel);
     }
   ENUM_LOG_LEVEL    LogLevel() {return(m_LogLevel);} ///< Gets logging level.
   uint              MaxLogFileSizeMB(uint uMaxSize){ m_ulMaxLogfileSize=((ulong)uMaxSize*1024)*1024; return(uMaxSize);} ///< Sets max file size in MB
   uint              MaxLogFileSizeMB(){ return((uint)(m_ulMaxLogfileSize/(1024*1024)));} ///< Gets max file size in MB
                                                                                          /// Sets maximum age of log files before they are deleted to manage filespace.
   uint              MaxLogAgeDays(const uint uDays){ return(m_uLogFileMaxAgeDays=uDays);}
   /// Gets number of days before log files are deleted to manage filespace.
   uint              MaxLogAgeDays(){ return(m_uLogFileMaxAgeDays);}
   void              LogToFileWhileTesting(bool bLogToFileWhileTesting) { m_bLogToFileWhileTesting=bLogToFileWhileTesting;}

  };
//+------------------------------------------------------------------+
/// Constructor setting default parameters.
/// Sets default logfile maximum age of 28 days - change using MaxLogAgeDays() \n
/// Sets default maximum logfile size of 50MB - change using MaxLogFileSizeMB() \n
/// Sets default LogLevel of LOG_DEBUG - change using LogLevel() \n
//+------------------------------------------------------------------+
CLog::CLog()
  {
   m_strFilename=MakeLogFilename(TimeLocal());
   MaxLogAgeDays(28);
   MaxLogFileSizeMB(50);
   m_LogLevel=LOG_PRINT;
   m_bReducedLogging=false;
   m_uLogStartDaysSince1970=0;
   m_bLogToFileWhileTesting=true;
  }
//+------------------------------------------------------------------+
/// The main logging function.
/// Records logging activity in Files\\EAlogs\\<EAname>\\<EAname>_<symbol>_<period>_yyyymmdd_log.txt \n
/// Creates a new file at the beginning of each day \n
/// Cleans up logfiles older than MaxLogAgeDays() \n
/// Reduces or ceases logging if log file size exceeds MaxLogFileSizeMB()
/// \param [in]   Level    				The importance of the logged message
/// \param [in]   s1,s2...,s10         Up to 10 optional input strings
//+------------------------------------------------------------------+
void CLog::Log(const ENUM_LOG_LEVEL Level,string s1="",string s2="",string s3="",string s4="",string s5="",string s6="",string s7="",string s8="",string s9="",string s10="")
  {
   if(Level>m_LogLevel)return;
// no logging during optimisation
   if((bool)MQL5InfoInteger(MQL5_OPTIMIZATION)) return;

   string strMsg; StringInit(strMsg);
   StringConcatenate(strMsg,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10);

   if((bool)MQL5InfoInteger(MQL5_TESTING) && !m_bLogToFileWhileTesting) return;
 
   datetime dtNow=TimeLocal();
   bool bStartup=false;
   uint uDaysSince1970=(uint)dtNow/(3600*24);
   if(uDaysSince1970>m_uLogStartDaysSince1970)
     {
      // new day, or startup
      m_strFilename=MakeLogFilename(dtNow);
      m_uLogStartDaysSince1970=uDaysSince1970;
      CleanUpOldLogs();
      bStartup=true;
     }

   int hLog=FileOpen(m_strFilename,FILE_TXT|FILE_READ|FILE_WRITE);
   if(hLog<=0)
     {
      Print("Logfile error: ",ErrorDescription(::GetLastError())," log message follows: ",strMsg);
     }
   else
     {
      // write at end of logfile  
      FileSeek(hLog,0,SEEK_END);
      if(bStartup)
         FileWrite(hLog,"\nStartup or new day\n"+TimeToString(dtNow,TIME_DATE|TIME_SECONDS)+" "+strMsg);
      else
         FileWrite(hLog,TimeToString(dtNow,TIME_DATE|TIME_SECONDS)+" "+strMsg);

      // also log to terminal if LOG_PRINT
      if(Level==LOG_PRINT) Print(strMsg);

      // check for oversize logfile
      if(!m_bReducedLogging && FileSize(hLog)>m_ulMaxLogfileSize)
        {
         // since max size has been reached within a day, cease logging or reduce log level
         m_bReducedLogging=true;
         if(LogLevel()==LOG_MAJOR || LogLevel()==LOG_PRINT)
           {
            Print("Warning - max log size of ",MaxLogFileSizeMB(),"MB has been reached, no further logging active");
            LogLevel(LOG_NONE);
           }
         else
           {
            Print("Warning - max log size of ",MaxLogFileSizeMB(),"MB has been reached, reducing log level");
            LogLevel(LOG_MAJOR);
           }
        }
      FileClose(hLog);
     }
  }
//+------------------------------------------------------------------+
/// Creates a filename base.
/// Used for creating log file wildcard and in constructing log filename
/// \return				The filename base EAlogs\\<EAname>\\<EAname>_<symbol>_<period>
//+------------------------------------------------------------------+
string CLog::MakeLogFilenameBase()
  {
   string strName=MQL5InfoString(MQL5_PROGRAM_NAME);
   return(StringFormat("EAlogs\\%s\\%s_%s_%s",strName,strName,StringSubstr(_Symbol,0,6),PeriodString()));
  }
//+------------------------------------------------------------------+
/// Creates a filename from date.
/// \param [in] dt	Date to add to name for uniqueness
/// \return				The filename EAlogs\\<EAname>\\<EAname>_<symbol>_yyyymmdd_log.txt
//+------------------------------------------------------------------+
string CLog::MakeLogFilename(datetime dt)
  {
   MqlDateTime mdt;
   TimeToStruct(dt,mdt);
   return(StringFormat("%s_%d%02d%02d_log.txt",MakeLogFilenameBase(),mdt.year,mdt.mon,mdt.day));
  }
//+------------------------------------------------------------------+
/// Deletes all log files older than MaxLogAgeDays().
//+------------------------------------------------------------------+
void CLog::CleanUpOldLogs()
  {
   datetime dtNow=TimeLocal();
   datetime dtExpiry=dtNow-24*3600*MaxLogAgeDays();
   string strFilenameWildcard=MakeLogFilenameBase()+"*";
   string strFoundFile="";

   long hFind=FileFindFirst(strFilenameWildcard,strFoundFile);
   if(hFind!=INVALID_HANDLE)
     {
      do
        {
         strFoundFile="EAlogs\\"+MQL5InfoString(MQL5_PROGRAM_NAME)+"\\"+strFoundFile;
         datetime dt=LogFileDate(strFoundFile);
         if(dt!=-1 && dt<dtExpiry)
           {
            ResetLastError();
            FileDelete(strFoundFile);
            Print(ErrorDescription(::GetLastError())," cleaning up greater than ",MaxLogAgeDays()," day old logfile ",strFoundFile);
           }
        }
      while(FileFindNext(hFind,strFoundFile));
      FileFindClose(hFind);
     }
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
   switch(m_LogLevel)
     {
      case LOG_NONE: return("LOG_NONE");
      case LOG_PRINT: return("LOG_PRINT");
      case LOG_MAJOR: return("LOG_MAJOR");
      case LOG_DEBUG: return("LOG_DEBUG");
      case LOG_VERBOSE: return("LOG_VERBOSE");
      default: return("error: Unknown log level "+(string)LogLevel());
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
// Define global logfile
CLog LogFile;
#define LOG LogFile.Log
//+------------------------------------------------------------------+
