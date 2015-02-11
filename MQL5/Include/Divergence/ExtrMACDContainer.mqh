//+------------------------------------------------------------------+
//|                                            ExtrMACDContainer.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>     // для сравнения вещественных переменных
#include <Constants.mqh>          // подключаем библиотеку констант
#include <CLog.mqh>               // log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить rescue-файл: %s", MakeFunctionPrefix(__FUNCTION__), rescueDataFileName)); 
#include <Arrays/ArrayObj.mqh>
#include <Divergence/CExtremumMACD.mqh>

#define ARRAY_SIZE 130           



//+----------------------------------------------------------------------------------------------+
//|            Класс CExtrMACDContainer предназначен для хранения и вычисления экстремумов MACD  |
//                                                          на определенном участке ARRAY_SIZE.  |
//+----------------------------------------------------------------------------------------------+
class CExtrMACDContainer
{
private: 
 CArrayObj extremums;                        // массив экстремумов MACD
 double valueMACDbuffer[ARRAY_SIZE];         // массив значений MACD на участке ARRAY_SIZE
 bool _flagFillSucceed;                      // флаг учпешного заполенния контейнера
 int count;                                  // количесвто хранимых экстремумов MACD
 int _depth;                                 
 int _handle;
 
public: 
 
 CExtrMACDContainer();
 ~CExtrMACDContainer();
 CExtrMACDContainer(int handleMACD,int startIndex,int depth);  //Начальная позиция - startIndex, 
                                                               //смещение  - DEPTH, Handle
  
 //---------------Методы для работы с классом-------------------
 int isMACDExtremum(int startIndex);                         // находит есть ли экстремумы на данном бар
 void FilltheExtremums(int startIndex);                      // заполняет контейнер                                    
    //--------------Необходимые методы-----------------------------------------------
 CExtremumMACD *getExtr(int i);                              // возвращает i-ый элемент массива
 bool RecountExtremum(int startIndex, bool fill = false);    // обновиляет массив экстремумов
 CExtremumMACD *maxExtr();                                   // возвращает экстремум MACD с максимальным значением
 CExtremumMACD *minExtr();                                   // возвращает экстремум MACD с минимальным  значением
 int getCount();
 //void maxExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //Возвращает максимальный верхний экстремум
 //void minExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //Возвращает минимальный нижний экстремум
};  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::CExtrMACDContainer(int handle, int startIndex, int depth)    //Передается нулевой индекс, слева
{
 _handle = handle;
 _depth = depth;
 FilltheExtremums(startIndex);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::~CExtrMACDContainer()
{
}
  
//+------------------------------------------------------------------+
//                                                                   |
//            FilltheExtremums заполняет контейнер экстремумами MACD |
//                           начиная с startIndex на глубину _depth. |
//+------------------------------------------------------------------+

void CExtrMACDContainer::FilltheExtremums(int startIndex)
{
 int copied = 0;
 //----------Копирование значений MACD в буфер valueMACDbuffer-------
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex , _depth, valueMACDbuffer);
  Sleep(100);
 }
 if(copied != _depth)
 {
  int err = GetLastError();
  Print(__FUNCTION__, " Не удалось скопировать буффер полностью.", copied, "/. Error = ", err);
  _flagFillSucceed = false;
  return;
 }
 //-----------------------Заполнение контейнера---------------------
 count = 0;
 int indexForExtremum = startIndex + 1;                       
 int extremRslt = 0;
 int i, j = 2 , ind = _depth - 3;
 for(i = 0; indexForExtremum - startIndex  < _depth - 5; indexForExtremum++) //от 1ого до 126ого
 {
  extremRslt = isMACDExtremum(indexForExtremum);  // проверка на экстремум MACD
  if(extremRslt != 0)                             // если текущий элемент экстремум 
  {
   CExtremumMACD *new_extr = new CExtremumMACD(); // новый экстремум 
   new_extr.direction = extremRslt;               // запомнить направление
   new_extr.index = j;                            // запомнить индекс относитьельно _depth (т.е текущий элемент - [0 + 2])
   new_extr.value = valueMACDbuffer[ind];         // значение экстремума
   extremums.Add(new_extr);                       // добавление экстремума в массив 
   i++;
  }
  j++; 
  ind--;
 }
 count = i;
 _flagFillSucceed = true; 
 return;
} 
//+-------------------------------------------------------------------------------+
//                                                                                |
//            RecountExtremum целесообразно вызывать при поступлении нового бара, | 
//                                             а также при заполнении контейнера. |
//                        Таким образом, RecountExtremum работает в двух режимах: |
//                        в зависимости от флага fill может запустить заполнение, |
//        а может пересчитать индексы экстремумов MACD и добавить новый в начало. |
//+-------------------------------------------------------------------------------+

bool CExtrMACDContainer::RecountExtremum(int startIndex, bool fill = false)
{
 if(!_flagFillSucceed || fill)       
 {
  FilltheExtremums(startIndex);
  return (_flagFillSucceed);
 }
 
 CExtremumMACD *new_extr  = new CExtremumMACD(0, -1, 0.0);         // временная переменная в которую isMACDExtremum 
                                                                   // запишет текущий экстремум (если он есть)
 //--------Копирование значения предполагаемого экстремума------------
 double buf_Value[1];                                       
 int copied = 0;  
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex + 2, 1, buf_Value);        
  Sleep(100);                   
 }
 if(copied != 1)                   
 {
  int err = GetLastError();
  Print(__FUNCTION__, "Не удалось обновить последний элемент", copied, "/1. Error = ", err);
  return(false);
 }
 
 //-------------------Обновление индексов--------------------------
 CExtremumMACD *tmp;  
 count = extremums.Total() - 1;
 for(int i = 0; i <= count; i++)
 {
  tmp = extremums.At(i);
  tmp.index++;
  if(tmp.index >= 130)   
  {
   extremums.Delete(i);
   count--;
  }
 } 
 //-------Добавление экстремума MACDE в начало массива------------
 int is_extr_exist = isMACDExtremum(startIndex + 1); 
 if (is_extr_exist != 0)
 { 
  new_extr.direction = is_extr_exist;
  new_extr.index = 2;    
  new_extr.value = buf_Value[0];
  extremums.Insert(new_extr, 0);             
 }   
 return(true);
}            


//+------------------------------------------------------------------+
//|    getCount() - возвращает количесвто экстремумов MACD в массиве |
//+------------------------------------------------------------------+
int CExtrMACDContainer::getCount()
{
 return (extremums.Total());
}

CExtremumMACD *CExtrMACDContainer::getExtr(int i)
{
 return extremums.At(i);
}

//+------------------------------------------------------------------+
//|         maxExtr() - возвращает максимальный экстремум в массиве |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::maxExtr()   //--- ArrayMaximum(extrems,0,whole_array)
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0);
 int indexMax = 0;
 if(_flagFillSucceed && count > 0)
 {
  int j = 0; 
  double extrMax = -1;
  for(int i = 0; i < count; i++)
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
 return temp_Extr;  
}


//+------------------------------------------------------------------+
//|           minExtr() - возвращает минимальный экстремум в массиве |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::minExtr()  
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0);
 int indexMin = 0;
 if(_flagFillSucceed && count > 0)
 {
  int j = 0; 
  double extrMin = 1;
  for(int i = 0; i < count; i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.index < _depth && temp_Extr.direction == -1)
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
 return temp_Extr;  
}

//+------------------------------------------------------------------+
//             isMACDExtremum - проверяет наличие  экстремума MACD.  | 
//                           Возвращает 1/-1 если эестремум найден   |
//                                            в противном случае 0.  |
//+------------------------------------------------------------------+
int CExtrMACDContainer::isMACDExtremum(int startIndex)
{
 double iMACD_buf[4];
 int copied = 0;
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex, 4, iMACD_buf);
  Sleep(100);
 }
 if(copied != 4)
 {
  int err = GetLastError();
  Print(__FUNCTION__, "Не удалось скопировать буффер полностью.", copied, "/4. Error = ", err);
  return(0);
 }

   if ( GreatDoubles(iMACD_buf[2], iMACD_buf[0]) && GreatDoubles(iMACD_buf[2], iMACD_buf[1]) &&
         GreatDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] > 0)
   {
      return(1);
   }
   else if ( LessDoubles(iMACD_buf[2], iMACD_buf[0]) && LessDoubles(iMACD_buf[2], iMACD_buf[1]) && 
           LessDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] < 0) 
   {
      return(-1);     
   }
 return(0);
}
