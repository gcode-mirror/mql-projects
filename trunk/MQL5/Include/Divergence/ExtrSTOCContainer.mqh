//+------------------------------------------------------------------+
//|                                            ExtrSTOCContainer.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>     // для сравнения вещественных переменных
#include <Constants.mqh>          // подключаем библиотеку констант
#include <Arrays/ArrayObj.mqh>
#include <Divergence/CExtremumSTOC.mqh>

#define DEPTH_STOC 20                  // Глубина на которой ищем расхождение стохастика
#define BORDER_DEPTH 3                 // Количество баров где смотрим на наличие нового экстремум цены         

//+----------------------------------------------------------------------------------------------+
//|            Класс CExtrSTOCContainer предназначен для хранения и вычисления экстремумов MACD  |
//                                                          на определенном участке DEPTH_MACD.  |
//+----------------------------------------------------------------------------------------------+

class CExtrSTOCContainer
{
private:
 CArrayObj        extremums;                        // массив экстремумов STOC
 double           valueSTOCbuffer[DEPTH_STOC];      // массив значений STOC на участке DEPTH_STOC
 datetime         date_buf[DEPTH_STOC];             // массив даты хранимого экстремума
 bool             _flagFillSucceed;                 // флаг учпешного заполенния контейнера
 int              _handle;
 string           _symbol;
 ENUM_TIMEFRAMES  _period;
 
public:
 CExtrSTOCContainer();
 ~CExtrSTOCContainer();
 CExtrSTOCContainer(string symbol, ENUM_TIMEFRAMES period, int handleMACD, int startIndex);
 
 //---------------Методы для работы с классом-------------------
 int isSTOCExtremum(int startIndex);                         // находит есть ли экстремумы на данном баре
 void FilltheExtremums(int startIndex);                      // заполняет контейнер                                    
    //--------------Необходимые методы-----------------------------------------------
 CExtremumSTOC *getExtr(int i);                              // возвращает i-ый элемент массива
 bool RecountExtremum(int startIndex, bool fill = false);    // обновиляет массив экстремумов
 CExtremumSTOC *maxExtr();                                   // возвращает экстремум STOC с максимальным значением
 CExtremumSTOC *minExtr();                                   // возвращает экстремум STOC с минимальным  значением
 int getCount();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrSTOCContainer::CExtrSTOCContainer(string symbol, ENUM_TIMEFRAMES period, int handle, int startIndex)    
{
 _symbol = symbol;
 _period = period;
 _handle = handle;
 FilltheExtremums(startIndex);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrSTOCContainer::~CExtrSTOCContainer()
{
 extremums.Clear();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+
//                                                                   |
//            FilltheExtremums заполняет контейнер экстремумами STOC |
//                           начиная с startIndex на глубину _depth. |
//+------------------------------------------------------------------+

void CExtrSTOCContainer::FilltheExtremums(int startIndex)
{
 int copiedSTOC = 0;
 int copiedDate = 0;
 //extremums.Clear();
 Print(__FUNCTION__," was here");
 //----------Копирование значений STOC в буфер valueSTOCbuffer-------
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  copiedSTOC = CopyBuffer(_handle, 0, startIndex , DEPTH_STOC, valueSTOCbuffer); //DEPTH_STOC-1 потому что иы начинаем со следующего после текущего   
  copiedDate = CopyTime(_symbol, _period, startIndex, DEPTH_STOC, date_buf); 
  Sleep(100);
 }
 
 if(copiedSTOC != DEPTH_STOC || copiedDate != DEPTH_STOC)
 {
  int err = GetLastError();
  Print(__FUNCTION__, " Не удалось скопировать буффер полностью. /. Error = ", err);
  _flagFillSucceed = false;
  return;
 }
 //-----------------------Заполнение контейнера---------------------
 int indexForExtremum = startIndex;                       
 int extremRslt = 0;
 int i, j = 2 , ind = DEPTH_STOC - 2;
 for(i = 0; indexForExtremum - startIndex  <= DEPTH_STOC - 3 ; indexForExtremum++) //от 0ого до 17
 {
  extremRslt = isSTOCExtremum(indexForExtremum);  // проверка на экстремум STOC
  if(extremRslt != 0)                             // если текущий элемент экстремум 
  {
   CExtremumSTOC *new_extr = new CExtremumSTOC(); // новый экстремум 
   new_extr.direction = extremRslt;               // запомнить направление
   new_extr.index = j;                            // запомнить индекс относитьельно _depth (т.е текущий элемент - [0 + 2])
   new_extr.value = valueSTOCbuffer[ind];         // значение экстремума
   new_extr.time  = date_buf[ind];
   extremums.Add(new_extr);                       // добавление экстремума в массив 
   i++;
  }
  j++; 
  ind--;
 }
 _flagFillSucceed = true; 
 return;
} 
//+-------------------------------------------------------------------------------+
//                                                                                |
//            RecountExtremum целесообразно вызывать при поступлении нового бара, | 
//                                             а также при заполнении контейнера. |
//                        Таким образом, RecountExtremum работает в двух режимах: |
//                        в зависимости от флага fill может запустить заполнение, |
//        а может пересчитать индексы экстремумов STOC и добавить новый в начало. |
//                                     Важно: если рассчет дивергенции выхывается |
//                                с индексом текущего бара (например startIndex), |
//                             то RecountExtremum на один позже (startIndex + 1). |
//+-------------------------------------------------------------------------------+

bool CExtrSTOCContainer::RecountExtremum(int startIndex, bool fill = false)
{
 if(!_flagFillSucceed || fill)       
 {
  FilltheExtremums(startIndex);
  return (_flagFillSucceed);
 }

 //--------Копирование значения предполагаемого экстремума------------
 double buf_Value[1];                                       
 int copiedSTOC = 0; 
 int copiedDate = 0; 
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  copiedSTOC = CopyBuffer(_handle, 0, startIndex + 1, 1, buf_Value);   
  copiedDate = CopyTime(_symbol, _period, startIndex + 2, 1, date_buf); 
  Sleep(100);                   
 }
 if(copiedSTOC != 1 || copiedDate != 1)                   
 {
  int err = GetLastError();
  Print(__FUNCTION__, "Не удалось обновить последний элемент. Error = ", err);
  return(false);
 }
 
 //-------------------Обновление индексов--------------------------
 CExtremumSTOC *tmp;  
 for(int i = extremums.Total() - 1; i >= 0; i--)
 {
  tmp = extremums.At(i);
  tmp.index++;
  if(tmp.index >= DEPTH_STOC)   
  {
   extremums.Delete(i);
  }
 }
 //tmp = extremums.At(0);
 //if(buf_Value[0]==tmp.value) 
 //-------Добавление экстремума STOC в начало массива------------
 int is_extr_exist = isSTOCExtremum(startIndex); 
 if(is_extr_exist != 0)
 {
  CExtremumSTOC *new_extr = new CExtremumSTOC();                                                    
  new_extr.direction = is_extr_exist;
  new_extr.index = 2;    
  new_extr.value = buf_Value[0];
  new_extr.time = date_buf[0];
  extremums.Insert(new_extr, 0);             
 }  
 //Print("New extremum  index = ", new_extr.index, " value = ", new_extr.value, " time = ",date_buf[0]);
 return(true);
}            


//+------------------------------------------------------------------+
//|    getCount() - возвращает количесвто экстремумов STOC в массиве |
//+------------------------------------------------------------------+
int CExtrSTOCContainer::getCount()
{
 return (extremums.Total());
}

CExtremumSTOC *CExtrSTOCContainer::getExtr(int i)
{
 return extremums.At(i);
}

//+------------------------------------------------------------------+
//|         maxExtr() - возвращает максимальный экстремум в массиве  |
//+------------------------------------------------------------------+
CExtremumSTOC *CExtrSTOCContainer::maxExtr()   
{
 CExtremumSTOC *temp_Extr;
 int indexMax = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMax = -1;
  for(int i = 0; i < extremums.Total(); i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == 1)
   {
    if(extrMax < temp_Extr.value)
    {
     extrMax = temp_Extr.value;
     indexMax = i;
    }
   }
  }
  return extremums.At(indexMax);
 }
 return  new CExtremumSTOC(0, -1, 0, 0);  
}


//+------------------------------------------------------------------+
//|           minExtr() - возвращает минимальный экстремум в массиве |
//+------------------------------------------------------------------+
CExtremumSTOC *CExtrSTOCContainer::minExtr()  
{
 CExtremumSTOC *temp_Extr;
 int indexMin = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMin = 1000;
  for(int i = 0; i < extremums.Total(); i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == -1)
   {
    if(extrMin > temp_Extr.value)
    {
     extrMin = temp_Extr.value;
     indexMin = i;
    }
   }
  }
  return extremums.At(indexMin);
 }
 return  new CExtremumSTOC(0, 1, 0, 0);  
}

//+------------------------------------------------------------------+
//             isMACDExtremum - проверяет наличие  экстремума MACD.  | 
//                           Возвращает 1/-1 если экстремум найден   |
//                                            в противном случае 0.  |
//+------------------------------------------------------------------+
int CExtrSTOCContainer::isSTOCExtremum(int startIndex)
{
 //if (startIndex < 1) return 0;
 double iSTOC_buf[3];
 int copiedSTOC = 0;
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(_handle, 0, startIndex, 3, iSTOC_buf);
 }
 if (copiedSTOC < 3)
 {
  Print(__FUNCTION__, "Не удалось скопировать буффер полностью. Error = ", GetLastError());
  return(0);
 }
 
 if (GreatDoubles(iSTOC_buf[1], iSTOC_buf[0]) && GreatDoubles(iSTOC_buf[1], iSTOC_buf[2]))
 {
  return(1);
 }
 else if (LessDoubles(iSTOC_buf[1], iSTOC_buf[0]) && LessDoubles(iSTOC_buf[1], iSTOC_buf[2]))
 {
  return(-1);
 }
 
 return(0);
}
