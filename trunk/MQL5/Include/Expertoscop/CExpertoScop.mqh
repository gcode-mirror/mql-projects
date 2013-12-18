//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"

#define OPEN_GENETIC 0x80000000
#define OPEN_EXISTING 3
#define FILE_ATTRIBUTE_NORMAL 128
#define FILE_SHARE_READ_KERNEL 0x00000001
 
#import "kernel32.dll"
   int  FindFirstFileW(string path, int& answer[]);
   bool FindNextFileW(int handle, int& answer[]);
   bool FindClose(int handle);
   int _lopen  (string path, int of);
   int _llseek (int handle, int offset, int origin);
   int _lread  (int handle, string fileContain, int bytes);
   int _lclose (int handle);
   int GetLastError();
   bool ReadFile (int hFile, double& lpBuffer[], int nNumberOfBytesToRead, int& lpNumberOfBytesRead[], int lpOverlapped);
   int CreateFileW(
    string lpFileName,         // pointer to name of the file
    int dwDesiredAccess,       // access (read-write) mode
    int dwShareMode,           // share mode
    int lpSecurityAttributes,  // pointer to security attributes
    int dwCreationDisposition, // how to create
    int dwFlagsAndAttributes,  // file attributes
    int hTemplateFile          // handle to file with attributes to        
);   
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
  // string aFilesHandle[];
   // массив параметров 
   ExpertoScopParams param[];
   // длина массива параметров
   uint   param_length;
   string filename; 
  public:
   // методы получения параметров запущенных экспертов
   // ------------------------------------------------
   // метод получения имени эксперта 
   string          GetExpertName(uint num){ return (param[num].expert_name ); };
   // метод получения символа
   string          GetSymbol(uint num){ return (param[num].symbol); };
   // метод получения таймфрейма
   ENUM_TIMEFRAMES GetTimeFrame(uint num){ return (param[num].period); };
   // метод получения длины массива параметров
   uint GetParamLength (){ return (/*param_length*/ArraySize(param)); };
   // метод получения всех открытых инструментов - заполняет aFilesHandle хэндлами файлов
   void DoExpertoScop();
   // метод получения параметров эксперта
   void GetExpertParams(string fileHandle);
   // конструктор класса
   CExpertoscop()
   {
    // формируем адрес файла
    StringConcatenate(filename, TerminalInfoString(TERMINAL_PATH),"\\profiles\\charts\\default\\");
    // обнуляем длину массива параметров
    param_length = 0;
    
   //Print("HANDLA = ",handle);
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
  //ArrayResize(aFilesHandle, 1);
 // aFilesHandle[0] = bufferToString(win32_DATA);
  GetExpertParams(bufferToString(win32_DATA));  //получаем параметры эксперта из файла
  ArrayInitialize(win32_DATA,0);
 
 // открываем остальные файлы
 while(FindNextFileW(handle, win32_DATA))
 {
 // ArrayResize(aFilesHandle, ++fileCount);
 // aFilesHandle[fileCount - 1] = bufferToString(win32_DATA);

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
 string fileContain;
 string ch = " ";
 int count;
 
 // получаем указатель на файл
 //int handle = _lopen(filename + fileHandle, 0);
 int handle = CreateFileW(filename + fileHandle,OPEN_GENETIC, FILE_SHARE_READ_KERNEL, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
 Print("LAST ERR = ",kernel32::GetLastError());
 Print("ПОЛНЫЙ АДРЕС ФАЙЛА = ",filename+fileHandle);
 
 Print("Ебучий хендл = ",handle);
 
 if (handle >= 0)
 {
  Print("ПОЛУЧИЛИ ХЕНДЛ ФАЙЛА ",filename+fileHandle);
  // устанавливаем указатель в открытом файле
  int result = _llseek(handle, 0, 0);
  if (result < 0) Print("Ошибка установки указателя");

  fileContain = "";
  count = 0;
  // читаем побайтово из файла
  do
  {
   fileContain = fileContain + ch;
   count++;
   ch = "x";
   result = _lread(handle, ch, 1);
  }
  while (result > 0);

  // закрываем файл
  result=_lclose (handle);              
  if (result<0) Print("Ошибка закрытия файла ",filename);         
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