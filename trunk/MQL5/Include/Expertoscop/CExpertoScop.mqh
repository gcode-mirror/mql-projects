//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"
#include <StringUtilities.mqh>  // подключаем библиотеку констант

 
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
   // размер массива параметров
   uint params_size;
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
//| Методы работы с файловыми данными                                |
//+------------------------------------------------------------------+
   // метод чтения строки из файла (заменяет функцию MQL FileReadString )
   string          ReadString(int handle); 
   // метод формирует таймфрейм из считанных из файла данных
   ENUM_TIMEFRAMES ReturnTimeframe(string period_type,string period_size);
//+------------------------------------------------------------------+
//| Базовые методы                                                   |
//+------------------------------------------------------------------+
   
   // метод получения длины массива параметров
   uint GetParamLength (){ return (ArraySize(param)); };
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
    params_size = 0;
   };
   // деструктор класса
   ~CExpertoscop()
   {
    // очищаем динамический массив
    ArrayFree(param);
   };
 };
 

//+------------------------------------------------------------------+
//| Методы работы с файловыми данными                                |
//+------------------------------------------------------------------+ 

// метод формирования таймфрейма из считанных из файла данных
ENUM_TIMEFRAMES CExpertoscop::ReturnTimeframe(string period_type,string period_size)
 {
  ENUM_TIMEFRAMES period=0;
  //если "минутка"
  if (period_type == "0")
   {
    if (period_size == "1") return PERIOD_M1;
    if (period_size == "2") return PERIOD_M2;
    if (period_size == "3") return PERIOD_M3;
    if (period_size == "4") return PERIOD_M4;
    if (period_size == "5") return PERIOD_M5;
    if (period_size == "6") return PERIOD_M6;
    if (period_size == "10") return PERIOD_M10;
    if (period_size == "12") return PERIOD_M12;  
    if (period_size == "15") return PERIOD_M15;
    if (period_size == "20") return PERIOD_M20;
    if (period_size == "30") return PERIOD_M30;                               
   } 
  //если "часовик"
  if (period_type == "1")
   {
    if (period_size == "1") return PERIOD_H1;
    if (period_size == "2") return PERIOD_H2;
    if (period_size == "3") return PERIOD_H3;
    if (period_size == "4") return PERIOD_H4;
    if (period_size == "6") return PERIOD_H6;  
    if (period_size == "8") return PERIOD_H8;    
    if (period_size == "24") return PERIOD_D1;                                           
   }    
  //если "недельник"
  if (period_type == "2")
    return PERIOD_W1;
  if (period_type == "3")
    return PERIOD_MN1;
  return period;
 }
 
//+------------------------------------------------------------------+
//| Базовые методы                                                   |
//+------------------------------------------------------------------+

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
 // флаг поиска тэга <expert>
 bool found_expert = false;
 // флаг продолжения чтения файла
 bool read_flag    = true;
 // переменная для хренения символа
 string symbol;
 // тип таймфрейма
 string period_type;
 // размер периода
 string period_size;
 // период 
 ENUM_TIMEFRAMES period;
 // строка файла
 string str = " ";
 int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 if(handle!=INVALID_HANDLE)
 {
  // устанавливаем указатель в открытом файле 
  FileSeek (handle,0,0);
  // читаем строки из файла и обрабатываем их
  do
  {
   // считываем строку
   str = FileReadString(handle,-1);
   // проверяем на символ 
   if (StringFind(str, "symbol=")!=-1) symbol=StringSubstr(str, 7, -1);    
   // считываем тип таймфрейма
   if (StringFind(str, "period_type=")!=-1) period_type=StringSubstr(str, 12, -1);    
   // считываем размер таймфрейма
   if (StringFind(str, "period_size=")!=-1)
    {
     period_size=StringSubstr(str, 12, -1);
     period = ReturnTimeframe(period_type,period_size ); 
    }         
   // считываем тэг <expert>
   if (StringFind(str, "<expert>")!=-1 && found_expert==false)
     found_expert = true;
   // считываем имя эксперта
   if (StringFind(str, "name=")!=-1 && found_expert == true)
     {
      //нашли все данные, значит сохраняем их 
      params_size++; //увеличиваем массив параметров на единицу
      ArrayResize(param,params_size); //увеличиваем массив на единицу
      param[params_size-1].expert_name = StringSubstr(str, 5, -1); // сохраняем имя эксперта
      param[params_size-1].period      = period;                   // сохраняем период
      param[params_size-1].symbol      = symbol;                   // сохраняем символ
      read_flag = false; 
     }
      
  }
  while (!FileIsEnding(handle) && read_flag == true); 
  
  // закрываем файл
  FileClose(handle);                  
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