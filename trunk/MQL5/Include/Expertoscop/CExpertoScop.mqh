//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"
#include <StringUtilities.mqh>  // подключаем библиотеку констант

// константы
#define OPEN_GENETIC           0x80000000
#define OPEN_EXISTING          3
#define FILE_ATTRIBUTE_NORMAL  128
#define FILE_SHARE_READ_KERNEL 0x00000001

// подключаем DLL KERNEL32 для доступа к API функциям
#import "kernel32.dll"

   int  FindFirstFileW(string path, int& answer[]);
   
   bool FindNextFileW(int handle, int& answer[]);
   
   bool FindClose(int handle);

   bool ReadFile (                     // Чтение данных из файла
         int    hFile,                 // handle of file to read
         char&  lpBuffer[],            // address of buffer that receives data 
         int    nNumberOfBytesToRead,  // number of bytes to read
         int&   lpNumberOfBytesRead[], // address of number of bytes read
         int    lpOverlapped );        // address of structure for data 
         
   int CreateFileW (
         string lpFileName,            // pointer to name of the file
         int    dwDesiredAccess,       // access (read-write) mode
         int    dwShareMode,           // share mode
         int    lpSecurityAttributes,  // pointer to security attributes
         int    dwCreationDisposition, // how to create
         int    dwFlagsAndAttributes,  // file attributes
         int    hTemplateFile );       // handle to file with attributes to        

   bool CloseHandle (                  // Закрытие объекта
       int hObject );            
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
   // StringConcatenate(filename, TerminalInfoString(TERMINAL_PATH),"\\profiles\\charts\\default\\");
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

// метод считываения строки из файла

string CExpertoscop::ReadString(int handle)
 {
  int    nBytesRead[1]={1};
  char   buffer[2]={'_','-'};
  string str=""; 
  string ch="";
  if (handle>0) {
    // пропускаем пустой символ 
     ReadFile(handle, buffer, 2, nBytesRead, NULL);
    // считываем символы, пока не дойдем до конца строки
    while (nBytesRead[0]>0 && buffer[0]!=13) {
      // формируем строку
      str = str + ch;
      // считываем очередной символ
      ReadFile(handle, buffer, 2, nBytesRead, NULL);
      // сохраняем символ
      ch =  CharToString(buffer[0]);
    }
  }
  return (str);
 }

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
 //int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 int handle = CreateFileW(filename + fileHandle, OPEN_GENETIC, FILE_SHARE_READ_KERNEL, 0, OPEN_EXISTING, 128, NULL);
 
 Print("ОТКРЫЛИ ФАЙЛ ",fileHandle);
 //Print("ВОТ ТАК ВОТ");
 if(handle > 0)
 {
  // устанавливаем указатель в открытом файле 
  //FileSeek (handle,0,0);
  // читаем строки из файла и обрабатываем их
  do
  {
   // считываем строку
   // str = FileReadString(handle,-1);
   str = ReadString(handle);
   Print("ЗНАЧЕНИЕ СТРОКИ = ",str);
   // проверяем на символ 
   if (StringFind(str, "symbol=")!=-1)      symbol      =  StringSubstr(str, 7, -1);    
   // считываем тип таймфрейма
   if (StringFind(str, "period_type=")!=-1) period_type =  StringSubstr(str, 12, -1);    
   // считываем размер таймфрейма
   if (StringFind(str, "period_size=")!=-1)
    {
     period_size=StringSubstr(str, 12, -1);
     
     Print ("ТИП ПЕРИОДА = [",StringLen(period_type),"] РАЗМЕР ПЕРИОДА = [",StringLen(period_size),"]");
     
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
  while (handle > 0 && read_flag == true); 
  
  // закрываем файл
                 
 }
   if (CloseHandle(handle) == true)
   Print("Закрылись успешно !!!");
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