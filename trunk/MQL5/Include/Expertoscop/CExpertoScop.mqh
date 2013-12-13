//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"
 
#import "kernel32.dll"
   int  FindFirstFileA(string path, int& answer[]);
   bool FindNextFileA(int handle, int& answer[]);
   bool FindClose(int handle);
   int _lopen  (string path, int of);
   int _llseek (int handle, int offset, int origin);
   int _lread  (int handle, string buffer, int bytes);
   int _lclose (int handle);
#import
string filear[], param[][44]; 

//+------------------------------------------------------------------+
//| Структура параметров                                             |
//+------------------------------------------------------------------+
 
struct ExpertoScopParams
 {
  string expert_name;
  string symbol;
  
 };
 
//+------------------------------------------------------------------+
//| Класс экспертоскопа                                              |
//+------------------------------------------------------------------+

class CExpertoscop
 {
 
  private:
  
  public:
  //метод загрузки параметров из файла
  bool Start();
  //конструктор класса
  CExpertoscop();
  //деструктор класса
 ~CExpertoscop();
 };



bool CExpertoscop::Start()
//метод загрузки параметров из файла
{
 int win32_DATA[79];
 int num, i, ii, iii, cnt, pos, ex, flag, kol, xx;
 //переменная для хранения адреса файла
 string filename;
 //формируем адрес файла
 StringConcatenate(filename, TerminalInfoString(TERMINAL_PATH),"\\profiles\\charts\\default\\");
 
 string word, symbol, period;
 string buffer;
 string ch;
 int count;

 //открываем файл 
 int handle = FindFirstFileA(filename+"*.chr",win32_DATA);
 if(handle!=-1)
 {
  ArrayResize(filear, 1);
  filear[0]=bufferToString(win32_DATA);
  ArrayInitialize(win32_DATA,0);
 }
 
 num = 2;
 while(FindNextFileA(handle,win32_DATA))
 {
  ArrayResize(filear, num);
  filear[num-1] = bufferToString(win32_DATA);
  ArrayInitialize(win32_DATA,0);
  num++;
 }
 num-=1;
 if (handle>0) FindClose(handle);
 for(i=0;i<num;i++)
 {//1
  handle=_lopen (filename+filear[i],0);   
  if (handle>=0)
  {//2 
   int result=_llseek (handle,0,0);
   if (result<0) Print("Ошибка установки указателя" );
   buffer="";
   ch="x";
   count=0;
   result=_lread (handle,ch,1);
   while (result>0) 
   {//3
    buffer=buffer+ch;
    ch="x";
    count++;
    result=_lread (handle,ch,1);
   }//3
   result=_lclose (handle);              
   if (result<0)  Print ("Ошибка закрытия файла ",filename);         
  }//2
  pos = 0; flag = 0;
  symbol="";
  period="";
  for(cnt=0;cnt<StringLen(buffer);cnt++)
  {//2
   if(StringGetCharacter(buffer,cnt)==13)
   {//3
    word=StringSubstr(buffer,pos,cnt-pos);
    if(StringFind(word,"symbol=")!=-1&&cnt!=pos&&symbol=="")symbol=StringSubstr(word,7);
    if(StringFind(word,"period=")!=-1&&cnt!=pos&&period=="")period=StringSubstr(word,7);
    if(StringFind(word,"</window>")!=-1&&cnt!=pos)flag=1;
    if(StringFind(word,"<expert>")!=-1&&cnt!=pos&&flag==1)
    {//4
     ex++;
     ArrayResize(param,ex);
     for(cnt=cnt;cnt<StringLen(buffer);cnt++)
     {//5
      if(StringGetCharacter(buffer,cnt)==13)
      {//6
       word=StringSubstr(buffer,pos,cnt-pos);
       if(StringSubstr(word,0,4)=="name")
       {//7
        int basa[];
        param[ex-1][1]=StringSubstr(word,5);
        param[ex-1][4]=symbol;
        param[ex-1][5]=period;
        if(ex==1)
        {//8
         param[0][0]=IntegerToString(0);
         basa[1] = 1;
        }//8
        else
        {//8
         flag=0;
         for(ii=0;ii<ex-1;ii++)
         {//9
          if(param[ii][1]==StringSubstr(word,5))
          {//10
           param[ex-1][0]=param[ii][0];
           basa[StringToInteger(param[ex-1][0])]=basa[StringToInteger(param[ex-1][0])]+1;
           flag=1;
           break;
          }//10
         }//9
         if(flag==0)
         {//9
          kol++;
          ArrayResize(basa,kol+1);
          basa[kol]=1;
          param[ex-1][0]=IntegerToString(kol);
          //Print("kol - ",kol);
         }//9
        }//8   
       }//7
       if(StringSubstr(word,0,5)=="flags")
       {//7
        param[ex-1][2]=StringSubstr(word,6);
       }//7
       if(StringFind(word,"<inputs>")!=-1&&cnt!=pos)
       {//7
        xx=0;
        for(cnt=cnt;cnt<StringLen(buffer);cnt++)
        {//8
         if(StringGetCharacter(buffer,cnt)==13)
         {//9
          word=StringSubstr(buffer,pos,cnt-pos);
          for(iii=0;iii<StringLen(word);iii++)
          {//10
           if(CharToString(StringGetCharacter(word,iii))=="=")
           {//11
            param[ex-1][6+xx]=StringSubstr(word,0,iii);
            param[ex-1][7+xx]=StringSubstr(word,iii+1);
            xx+=2;
           }//11
          }//10
          if(StringFind(word,"</inputs>")!=-1)break;
          pos=cnt+2;
         }//9
        }//8   
        param[ex-1][3]=IntegerToString(xx/2);
       }//7
       if(StringFind(word,"</inputs>")!=-1)break;
       pos=cnt+2;
      }//6
     }//5
     break;   
    }//4
    pos=cnt+2;
   }//3
  }//2
 }//1
//----
 return(0);
}
  
CExpertoscop::CExpertoscop(void)
//конструктор класса
 {
 
 }  

CExpertoscop::~CExpertoscop(void)
//деструктор класса
 {
 
 }
  
//+------------------------------------------------------------------+
//|  считать текст из буфера                                         |
//+------------------------------------------------------------------+ 
string bufferToString(int &buffer[])
   {
   string text="";
   
   int pos = 10;
   for (int i=0; i<64; i++)
      {
      pos++;
      int curr = buffer[pos];
      text = text + CharToString(curr & 0x000000FF)
         +CharToString(curr >> 8 & 0x000000FF)
         +CharToString(curr >> 16 & 0x000000FF)
         +CharToString(curr >> 24 & 0x000000FF);
      }
   return (text);
   }  
//+------------------------------------------------------------------+
bool DecToBin(int dec)
   {
   int ch = 0, x = 3;
   bool res;
   dec-=3;
   while(x > 0)
      {
      ch = MathMod(dec,2);
      dec = MathFloor(dec/2);
      x--;
      }
   if(ch==0)res=false; else res=true;   
   return(res);
   }