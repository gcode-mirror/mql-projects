//+------------------------------------------------------------------+
//|                                            VirtualOrderArray.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include "VirtualOrderManagerConfig.mqh"
#include "Log.mqh"
#include "VirtualOrderManagerEnums.mqh"
#include "VirtualOrder.mqh"
#include <Arrays/ArrayObj.mqh>
#include "StringUtilities.mqh"
//+------------------------------------------------------------------+
/// Stores an array of virtual orders.
//+------------------------------------------------------------------+
class CVirtualOrderArray : public CArrayObj
  {
private:
   string            m_strPersistFilename;

public:
                     CVirtualOrderArray();
   CVirtualOrder    *AtTicket(long lTicket);
   int               OpenLots(string strSymbol);
   /// Count of orders.
   int               OrderCount(string strSymbol,long lMagic);
   int               OrderCount(string strSymbol,ENUM_VIRTUAL_ORDER_TYPE eOrderType,long lMagic);
   string            PersistFilename(){return(m_strPersistFilename);}
   string            PersistFilename(string strFilename);
   int               TicketToIndex(long lTicket);
   bool              ReadFromFile(bool bCreateLineObjects=true);
   void              ReadAllVomOpenOrders(string strFolder);
   bool              WriteToFile();
   string            SummaryList();
   void              Clear(const long nMagic);
   void              Clear(const string strSymbol);
   CVirtualOrder    *VirtualOrder(int nIndex){return((CVirtualOrder*)CArrayObj::At(nIndex));}

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CVirtualOrderArray::CVirtualOrderArray()
  {
   m_strPersistFilename="";
  }
//+------------------------------------------------------------------+
/// Searches for and returns the VirtualOrder which matches ticket.
/// \param [in]	lTicket	Order ticket
/// \return						CVirtualOrder handle, or NULL if not found
//+------------------------------------------------------------------+
CVirtualOrder *CVirtualOrderArray::AtTicket(long lTicket)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.Ticket()==lTicket)
        {
         LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) returning valid CVirtualOrder",lTicket));
         return(vo);
        }
     }
   LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat("(%d) error: could not find a valid CVirtualOrder",lTicket));
   return(NULL);
  }
//+------------------------------------------------------------------+
/// Returns positive lots if total virtual position is long and negative lots if short.
/// \param [in]   strSymbol   Symbol
/// \return       +/-Lots * 1000                                                                  |
//+------------------------------------------------------------------+
int CVirtualOrderArray::OpenLots(string strSymbol)
  {
   double dblTotalPosition=0.0;
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.Symbol()==strSymbol)
         switch(vo.OrderType())
           {
            case VIRTUAL_ORDER_TYPE_BUY:
               dblTotalPosition+=vo.Lots(); break;
            case VIRTUAL_ORDER_TYPE_SELL:
               dblTotalPosition-=vo.Lots();
           }
     }
   int nTotalPosition=(int)MathRound(dblTotalPosition*1000.0);
   LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%s) returning %d",strSymbol,nTotalPosition));
   return(nTotalPosition);
  }
//+------------------------------------------------------------------+
/// Count of orders.
/// \param [in] strSymbol
/// \param [in] nMagic
/// \return	Count of orders matching input criteria
//+------------------------------------------------------------------+
int CVirtualOrderArray::OrderCount(string strSymbol,long lMagic)
  {
   int nOrdersTotal=0;
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.MagicNumber()==lMagic)
         if(vo.Symbol()==strSymbol)
            nOrdersTotal++;
     }
   return(nOrdersTotal);
  }
//+------------------------------------------------------------------+
/// Count of orders of a certain type.
/// \param [in] strSymbol
/// \param [in] nMagic
/// \return	Count of orders matching input criteria
//+------------------------------------------------------------------+
int CVirtualOrderArray::OrderCount(string strSymbol,ENUM_VIRTUAL_ORDER_TYPE eOrderType,long lMagic)
  {
   int nOrdersTotal=0;
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.MagicNumber()==lMagic)
         if(vo.OrderType()==eOrderType)
            if(vo.Symbol()==strSymbol)
               nOrdersTotal++;
     }
   return(nOrdersTotal);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualOrderArray::PersistFilename(string strFilename)
  {
// need to start with a fresh file for every test
   if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
      FileDelete(strFilename);

   return(m_strPersistFilename=strFilename);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualOrderArray::ReadAllVomOpenOrders(string strFolder)
  {
   Clear();
   string strFilenameWildcard=strFolder+"*_OpenOrders.csv";
   string strFoundFile="";

   long hFind=FileFindFirst(strFilenameWildcard,strFoundFile);
   if(hFind!=INVALID_HANDLE)
     {
      do
        {
         PersistFilename(strFolder+strFoundFile);
         // read without creating line objects
         ReadFromFile(false);
        }
      while(FileFindNext(hFind,strFoundFile));
      FileFindClose(hFind);
     }
  }
//+------------------------------------------------------------------+
/// Reads array contents from PersistFilename()
//+------------------------------------------------------------------+
bool CVirtualOrderArray::ReadFromFile(bool bCreateLineObjects=true)
  {
   if(!FileIsExist(PersistFilename()))
     {
      LogFile.Log(LOG_VERBOSE,__FUNCTION__," warning: file "+PersistFilename()+" does not exist yet - assume zero orders");
      return(true);
     }

   int handle=-1;
   int nRepeatCount=Config.FileAccessRetries;
   while((handle=FileOpen(PersistFilename(),FILE_READ|FILE_CSV,Config.VirtualOrdersFileCsvDelimiter))<=0 && nRepeatCount>0)
     {
      Sleep(Config.FileAccessSleep_mSec);
      nRepeatCount--;
      LogFile.Log(LOG_DEBUG,__FUNCTION__," retrying #"+(string)nRepeatCount);
     }

   if(handle<=0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: "+ErrorDescription(::GetLastError())+" opening "+PersistFilename());
      return(false);
     }

// clear off header
   while(!FileIsLineEnding(handle)) FileReadString(handle);

   while(!FileIsEnding(handle))
     {
      CVirtualOrder *vo=new CVirtualOrder;
      // only add orders that don't already exist in the array
      if(vo.ReadFromFile(handle,bCreateLineObjects))
        {
         if(TicketToIndex(vo.Ticket())==-1)
           {
            Add(vo);
           }
         else
           {
            delete vo;
           }
        }
     }
   FileClose(handle);
   LogFile.Log(LOG_DEBUG,__FUNCTION__," successful reading from "+PersistFilename());
   return(true);
  }
//+------------------------------------------------------------------+
/// Searches for and returns the index of the VirtualOrder which matches ticket.
/// \param [in]	lTicket	Order ticket
/// \return						Index, or -1 if not found
//+------------------------------------------------------------------+
int CVirtualOrderArray::TicketToIndex(long lTicket)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) looking at open virtual order #%d",lTicket,vo.Ticket()));
      if(vo.Ticket()==lTicket)
        {
         LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) returning %d",lTicket,i));
         return(i);
        }
     }
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%d) warning: ticket not found, returning -1",lTicket));
   return(-1);
  }
//+------------------------------------------------------------------+
/// Saves array contents to PersistFilename()
//+------------------------------------------------------------------+
bool CVirtualOrderArray::WriteToFile()
  {
   int handle=-1;
   int nRepeatCount=Config.FileAccessRetries;
   while((handle=FileOpen(PersistFilename(),FILE_CSV|FILE_WRITE,Config.VirtualOrdersFileCsvDelimiter))<=0 && nRepeatCount>0)
     {
      Sleep(Config.FileAccessSleep_mSec);
      nRepeatCount--;
      LogFile.Log(LOG_DEBUG,__FUNCTION__," retrying #"+(string)nRepeatCount);
     }

   if(handle<=0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: "+ErrorDescription(::GetLastError())+" opening "+PersistFilename());
      return(false);
     }

   CVirtualOrder tmp;
   tmp.WriteToFile(handle,true);
   for(int i=0;i<Total();i++)
     {
      VirtualOrder(i).WriteToFile(handle);
     }
   FileClose(handle);
   LogFile.Log(LOG_DEBUG,__FUNCTION__," successful writing to "+PersistFilename());
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualOrderArray::SummaryList()
  {
   string strSummary; StringInit(strSummary);
   for(int i=0;i<Total();i++)
     {
      strSummary=strSummary+VirtualOrder(i).SummaryString()+"\n";
     }
   return(strSummary);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualOrderArray::Clear(const long nMagic)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.MagicNumber()==nMagic) Delete(i);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVirtualOrderArray::Clear(const string strSymbol)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=VirtualOrder(i);
      if(vo.Symbol()==strSymbol) Delete(i);
     }
  }
//+------------------------------------------------------------------+
