//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"

 
#import "kernel32.dll"
   int  FindFirstFileW(string path, int& answer[]);
   bool FindNextFileW(int handle, int& answer[]);
   bool FindClose(int handle);
   int _lopen  (string path, int of);
   int _llseek (int handle, int offset, int origin);
   int _lread  (int handle, string fileContain, int bytes);
   int _lclose (int handle);
#import


//+------------------------------------------------------------------+
//| Структура параметров                                             |
//+------------------------------------------------------------------+
 
struct ExpertoScopParams
 {
  string expert_name;
  string symbol;
  ENUM_TIMEFRAMES period;
 };
 
//+------------------------------------------------------------------+
//| Класс экспертоскопа                                              |
//+------------------------------------------------------------------+

class CExpertoscop
 {
 
  private:
   // массив параметров 
   ExpertoScopParams param[];
   // длина массива параметров
   uint   param_length;
   string filename; 
  public:
  
//+------------------------------------------------------------------+
//| Get методы                                                       |
//+------------------------------------------------------------------+
   
   // метод получения имени эксперта 
   string          GetExpertName(uint num){ return (param[num].expert_name ); };
   // метод получения символа
   string          GetSymbol(uint num){ return (param[num].symbol); };
   // метод получения таймфрейма
   ENUM_TIMEFRAMES GetTimeFrame(uint num){ return (param[num].period); };

//+------------------------------------------------------------------+
//| Методы работы с файлами                                          |
//+------------------------------------------------------------------+
   // метод чтения строки из файла (заменяет функцию MQL FileReadString )
   string          ReadString(int handle); 
   
//+------------------------------------------------------------------+
//| Базовые методы                                                   |
//+------------------------------------------------------------------+
   
   // метод получения длины массива параметров
   uint GetParamLength (){ return (/*param_length*/ArraySize(param)); };
   // метод получения всех открытых инструментов - заполняет aFilesHandle хэндлами файлов
   void DoExpertoScop();
   // метод получения параметров эксперта
   void GetExpertParams(string fileHandle);
   // конструктор класса
   CExpertoscop()
   {
    double ArBuffer[1] = {0}; // Буфер для записи или чтения.
     int    ArOutputByte[1]; 
    // формируем адрес файла
    //StringConcatenate(filename, TerminalInfoString(TERMINAL_PATH),"\\profiles\\charts\\default\\");
    StringConcatenate(filename,"","C:\\Users\\Илья\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\");    
    // обнуляем длину массива параметров
    param_length = 0;
   };
   // деструктор класса
   ~CExpertoscop()
   {
    // очищаем динамический массив
    ArrayFree(param);
   };
 };

// метод получения всех открытых инструментов 
void CExpertoscop::DoExpertoScop()
{
 int win32_DATA[79];
 int handle;
 //открываем файл  
 ArrayInitialize(win32_DATA,0); 
 handle = FindFirstFileW(filename+"*.chr", win32_DATA);
 if(handle!=-1)
 {
  GetExpertParams(bufferToString(win32_DATA));  //получаем параметры эксперта из файла
  ArrayInitialize(win32_DATA,0);
 // открываем остальные файлы
 while(FindNextFileW(handle, win32_DATA))
 {
  GetExpertParams(bufferToString(win32_DATA));
  ArrayInitialize(win32_DATA,0);
 }
 if (handle > 0) FindClose(handle);
 }
}

//метод загрузки параметров из файла
void CExpertoscop::GetExpertParams(string fileHandle)
{
 bool flag;
 int cnt, pos;
 //переменная для хранения адреса файла
 string word, symbol;
 ENUM_TIMEFRAMES period;
 string ch = " ";
 int count;
 Print("ПОЛНЫЙ АДРЕС ФАЙЛА = ",filename+fileHandle);
 int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 Alert("FILE HANDLE = ",fileHandle);
 if(handle!=INVALID_HANDLE)
 {
  Print("ПОЛУЧИЛИ ХЕНДЛ ФАЙЛА ,УРА",filename+fileHandle);
  // устанавливаем указатель в открытом файле 
  FileSeek (handle,0,0);
  fileContain = "";
  count = 0;
  // читаем побайтово из файла
  do
  {
   fileContain = fileContain + ch;
   count++;
   ch = FileReadString(handle,-1);
   Print("КАНТ = ",ch);
  }
  while (/*handle!=INVALID_HANDLE*/count<1);
  
  Alert("ФАЙЛ СОДЕРЖИТ = ",fileContain);
  // закрываем файл
  FileClose(handle);                  
 }
 pos = 0; flag = false;
 symbol="";
 //period="";
 // по всему содержимому файла
 for(cnt = 0; cnt < StringLen(fileContain); cnt++)
 {
  if(StringGetCharacter(fileContain, cnt)==13) // перевод строки (Enter), дошли до конца строки
  {
   // берем строку
   word = StringSubstr(fileContain, pos, cnt - pos); 
   // Получаем имя символа
   if(StringFind(word, "symbol=") != -1 && cnt != pos && symbol == "") symbol = StringSubstr(word, 7); 
   // Получаем период
   //if(StringFind(word, "period=") != -1 && cnt != pos && period == "") period = StringSubstr(word, 7);  
   
   if(StringFind(word, "</window>") != -1 && cnt != pos) flag = true; 
   if(StringFind(word, "<expert>") != -1 && cnt != pos && flag)
   {
    
    ArrayResize(param, ++param_length);
    // по всему оставшемуся файлу после тега <expert>
    for(cnt = cnt; cnt < StringLen(fileContain); cnt++) 
    {
     if(StringGetCharacter(fileContain, cnt) == 13)
     {
      word = StringSubstr(fileContain, pos, cnt-pos);
      if(StringSubstr(word, 0, 4) == "name")
      {
       int basa[];
       param[param_length - 1].expert_name = StringSubstr(word, 5); // имя эксперта 
       param[param_length - 1].symbol = symbol;
       //param[expNumber - 1].period = period;
      }
     }
    }
    break;   
   }
   pos=cnt+2;
  }
 }
}
  
//+------------------------------------------------------------------+
//|  считать текст из буфера                                         |
//+------------------------------------------------------------------+ 
string bufferToString(int &fileContain[])
   {
   string text="";
   
   int pos = 10;
   for (int i = 0; i < 64; i++)
      {
      pos++;
      int curr = fileContain[pos];
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