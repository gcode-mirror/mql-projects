//+------------------------------------------------------------------+
//|                                                    megathron.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек


#include <SystemLib/IndicatorManager.mqh>   // библиотека по работе с индикаторами
#include <MoveContainer/CMoveContainer.mqh> // нужный(новый) контейнер движений
#include <CTrendChannel.mqh>                // старый(на удаление) трендовый контейнер
#include <Rabbit/RabbitsBrain.mqh>
#include <Hvost/HvostBrain.mqh>
#include <Chicken/ChickensBrain.mqh>
#include <RobotEvgeny/EvgenysBrain.mqh>
#include <CLog.mqh>  
//#include <CExtrContainer.mgh>

//константы
#define SPREAD 30       // размер спреда 
#define rat_pos_tp 0.9;
#define rat_pos_give 0.1;


class CTI  // класс - обёртка для ВИ
{
 CArrayObj *robots;                         // массив роботов на этм ВИ
 ENUM_SIGNAL_FOR_TRADE _moveBUY;            // разрешение торговли на BUY для этого ВИ
 ENUM_SIGNAL_FOR_TRADE _moveSELL;           // разрешение торговли на SeLL для этого ВИ
  public:
  CTI(){_moveBUY = 0; _moveSELL = 0; robots = new CArrayObj();}
  ~CTI(){delete robots;}
  
  CObject *At(int i){return robots.At(i);}
  int  Total(){return robots.Total();}
  void Add(CBrain *brain);
  void SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY);
  ENUM_SIGNAL_FOR_TRADE GetMoveSell(){ return _moveSELL;}
  ENUM_SIGNAL_FOR_TRADE GetMoveBuy(){return _moveBUY;}
};
CTI::Add(CBrain *brain)
{
 robots.Add(brain);
}
CTI::SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 _moveSELL = moveSELL;
 _moveBUY = moveBUY;
}


// ---------переменные робота------------------
CExtrContainer    *extr_container;
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д;            
CRabbitsBrain     *rabbit;

CTradeManager     *ctm;        // торговый класс 
     
datetime history_start;    // время для получения торговой истории
ENUM_TM_POSITION_TYPE position_type_signal;
int handleDE; 
ENUM_SIGNAL_FOR_TRADE moveSELL;
ENUM_SIGNAL_FOR_TRADE moveBUY;  
double volume_ratio;                       
bool log_flag = false;
ENUM_TM_POSITION_TYPE opBuy, opSell; // заполнить
ENUM_TIMEFRAMES TFs[5]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M20, PERIOD_M30};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};/

//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;

/*//---------Массивы информации о торговых движениях на каждом роботе конкретного ВИ------
SPositionInfo mass_pos_info_Old[];
SPositionInfo mass_pos_info_Mid[];
SPositionInfo mass_pos_info_Jun[]; // Если можно ставить статус позиции 0, можно избежать массив роботов на каждом ТФ*/
STrailing     trailing;
//--------------массив роботов----------------------
CTI *robots_OLD;
CTI *robots_MID;
CTI *robots_JUN;

CBrain *robot;


// направление открытия позиции??
long magicAll[6] = {1111, 1112, 1113, 1114, 1115, 1116};


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 Print("Инициализация началась");
 ctm = new CTradeManager();
 history_start = TimeCurrent(); // запомним время запуска эксперта для получения торговой истории

 //---------- Загружаем контейнер всех данных по цене----------------
 conbuf = new CContainerBuffers(TFs);
 for (int attempts = 0; attempts < 25; attempts++)
 {
  conbuf.Update();
  Sleep(100);
  if(conbuf.isFullAvailable())
  {
   PrintFormat("Наконец-то загрузился! attempts = %d", attempts);
   break;
  }
 }
 if(!conbuf.isFullAvailable())
  return (INIT_FAILED);
 //---------- Загружаем контейнер экстремумов для Евгения на Н4----------------
 handleDE = DoesIndicatorExist(_Symbol, PERIOD_M30, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, PERIOD_M30, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора DrawExtremums");
   return (INIT_FAILED);
  }
 }   
 extr_container = new CExtrContainer(handleDE,_Symbol,PERIOD_M30,1000);
 if(!extr_container.Upload()) // Если не загрузился прервем работу
  return (INIT_FAILED);
 

 //-----------Заполним массив роботов на старшем ВИ----------------
 robots_OLD = new CTI();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_M30, extr_container, conbuf));
 //-----------Заполним массив роботов на среднем ВИ----------------
 robots_MID = new CTI();
              robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_M20, conbuf));
 //-----------Заполним массив роботов на младшем ВИ----------------
 robots_JUN = new CTI();
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M1, conbuf));
              robots_JUN.Add(new CRabbitsBrain(_Symbol, conbuf));
              
 pos_info.volume = 0;

 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
  
 moveSELL = 0;
 moveBUY = 0;
 Print("Инициализация успешно завершена");
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete rabbit;
 delete robots_OLD;
 delete robots_MID;
 delete robots_JUN;
 delete conbuf;
 delete ctm;
 delete extr_container;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 conbuf.Update();
 ctm.OnTick();   
 log_file.Write(LOG_DEBUG, "\n-------------------------MoveDown------------------------------------");
 MoveDown(robots_OLD);
 log_file.Write(LOG_DEBUG, "--------------------------MoveUp------------------------------------");
 MoveUp(robots_JUN);
   //PrintFormat("moveSELL = %d moveBUY %d", moveSELL, moveBUY);

   //Получить сигналы на старших ТФ, записать состояние в соответствующие переменные

   //В соответствии со старшими сигналами, получить сигнал от роботов средних ТФ; заполнить переменные состояний
   //Будет вестись одна общая позиция или для каждого робота своя?
   //Если отдельные позиции - как разделять для кого открылась позиция на нижнем ТФ?
   //Получить сигналы на младших ТФ
   
   //Проверить тенденции на слом, начиная со старших ТФ; закрыть позиции в случае слома тенденции
   //По оставшимся позициям проверить возможность передачи на верхние ТФ
   //
   
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 //---
   
}
//+------------------------------------------------------------------+

void MoveDown (CTI *robots) // привести в соответствие направление позиции и торговые сигналы SELL и OP_SELL
{
 //-----------
 robot = robots.At(0);
 log_file.Write(LOG_DEBUG, StringFormat("MoveDown: --- прогон на ВИ = %s", PeriodToString(robot.GetPeriod())));
 //-----------
 double vol_tp, vol_give;                       
 FillMoves(robots);    // заполнение разрешающих сигналов верхнего временного интервала
 // если на верхнем ВИ есть торговые сигналы
 if(robots.GetMoveBuy() != 0||robots.GetMoveSell() != 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("Был вычислен сигнал moveBUY = %d moveSELL = %d",robots.GetMoveBuy(),robots.GetMoveSell()));
  volume_ratio = CountTradeRate(robots);   // посчитать коэфициент для позиции на ВИ (для старших = 0)         

  // для каждого робота на этом ВИ
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // Вычислим торговый сигнал по алгоритму робота и записать тип позиции если она есть
   position_type_signal = robot.GetSignal();
   // Если пришел сигнал на открытие позиции 
   if(position_type_signal != OP_UNKNOWN)
   {
    log_file.Write(LOG_DEBUG, StringFormat("Был вычислен сигнал %d на роботе(%s)",position_type_signal, robot.GetName()));
    // открыть позицию, с мэджиком этого робота по направлению SELL/BUY
    // добавить функцию
    if((position_type_signal == OP_SELL || position_type_signal == OP_SELLSTOP) && robots.GetMoveSell() == SELL) // если есть разрешение с верхнего ВИ на торговлю в этом направлении
    {
     log_file.Write(LOG_DEBUG,StringFormat("Сигнал на SELL position_type_signal  = %d",position_type_signal));
     pos_info.type = position_type_signal;  // тип ордера установить согласно роботу
     pos_info.tp   = robot.CountTakeProfit();
     pos_info.sl   = robot.CountStopLoss();
     pos_info.volume = 1 * volume_ratio;
    }
    else if((position_type_signal == OP_BUY || position_type_signal == OP_BUYSTOP) && robots.GetMoveBuy() == BUY)
    {
     log_file.Write(LOG_DEBUG,StringFormat("Сигнал на BUY position_type_signal  = %d", position_type_signal));
     pos_info.type = position_type_signal;  // тип ордера установить согласно роботу
     pos_info.tp   = robot.CountTakeProfit();
     pos_info.sl   = robot.CountStopLoss();
     pos_info.volume = 1 * volume_ratio;
     
    }
    else
     continue;
    // ? <открытие позиции>
    log_flag = true;
    ctm.OpenPairPosition(_Symbol, robot.GetPeriod(), pos_info, trailing, volume_ratio);
    // должен работать таким образом, что бы робот мог открыть только эти две позиции в одном направлении, 
    // то есть как юникПозишн только для двух позиций того же направления
   }
   else if (position_type_signal == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL&&log_flag)// разрыв шаблона
   {
    log_file.Write(LOG_DEBUG, "Разрыв шаблона, закрытие позиции: position_type_signal == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL");
    // закрыть позицию с мэджиком этого робота
    //if(ctm.
    //ctm.ClosePosition(robot.GetMagic()); // полностью, обе
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CTI *robots)
{
 //-----------
 robot = robots.At(0);
 log_file.Write(LOG_DEBUG, StringFormat("MoveUp: --- прогон на ВИ = %s", PeriodToString(robot.GetPeriod())));
 //-----------
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // для каждого робота на ВИ
  // если его позиция существует и активна
  int positionCount = ctm.GetPositionCount(robot.GetMagic());
  if(positionCount <= 0 && log_flag) // если в стм по тп закрылась позиция, то pos_give должна перекинуться на др. робот
  {
   log_file.Write(LOG_DEBUG, StringFormat("У этого робота(%s) нет открытых позиций", robot.GetName()));
  }
  else if(positionCount == 1) // это значит что осталась только pos_give
  { 
   double vol = ctm.GetPositionVolume(_Symbol, robot.GetMagic());
   log_file.Write(LOG_DEBUG, StringFormat("У этого робота(%s) одна открытая позиция(значит give) vol = ", robot.GetName(), vol));
   long magicEld = ChooseTheBrain(ctm.GetPositionType(),GetNextTI(robots,false));
   log_file.Write(LOG_DEBUG, StringFormat("Присвоили позицию новому роботу с magic =  и открыли позицию на старшем", magicEld));
   OpenPosition(magicEld, vol); // открытие позиции по мэджику выбранного робота
  }
  else if (positionCount == 2 && log_flag)  // удалить - условие для лога
  {
   long magicEld = ChooseTheBrain(ctm.GetPositionType(),GetNextTI(robots,false));
   for(int i = 0; i < ctm.GetPositionCount() && magicEld != 0; i++)
   {
    ctm.PositionSelect(i, SELECT_BY_POS);
    if(ctm.GetPositionMagic() == robot.GetMagic())
    {
     if(ctm.GetPositionTakeProfit() != 0)
        log_file.Write(LOG_DEBUG, StringFormat("У робота (%d)  существует 2 позиции одна:  размером (profit) %f", robot.GetMagic(), ctm.GetPositionTakeProfit()));
     else
        log_file.Write(LOG_DEBUG, StringFormat("У робота (%d)  существует 2 позиции вторая:  размером (profit) %f", robot.GetMagic(), ctm.GetPositionTakeProfit()));
    }
   }
  }
   /*ENUM_POSITION_TYPE pos_type = ctm.GetPositionType(_Symbol, robot.GetMagic());
   switch(pos_type)
   {
    case OP_SELL:
    case OP_SELLLIMIT: // отл ордер сработал или нет?
    case OP_SELLSTOP:
    {
     // теперь здесь проверяется осталась ли pos_sl и pos_give !=0
     // если да, то 
     // добавляем объем разделяя к позициям работающих роботов (получается что мэджик не меняется)
     // Если отложенный ордер проверить активный ли он
     // если активный, то если позиция осталась одна ( это значит, что это pos_give)
     // выбираем робота, которому хотим присвоить эту позицию, предварительно получая разрешение с ВИ
     // Если на верхнем ест нужный сигнал, добавляем к позиции робота с этим моджиком (chooseBrain) весь   
     }
     
     if(ctm.GetPositionType(_Symbol,robot.GetMagic()) == OP_BUY)
     {
      curPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(curPrice >= ctm.GetPositionTakeProfit(_Symbol, robot.GetMagic()))
      {
       // закрываем часть позиции
       // ctm.ClosePosition(robot.GetMagic(), value);
       // value = ? 
       // и добавляем оставшийся объем к роботу верхнего ТФ
       // ctm.AddPositionValue(ChooseTheBrain(OP_SELL, GetNextTI(robots, false)) value);//up
      }
      // если позиция коснулась SL закрываем позицию полностью
      if(curPrice <= ctm.GetPositionStopLoss(_Symbol, robot.GetMagic()))
      {
       //ctm.ClosePosition(magic);
      }     
     }
    }*/
  }  
  if(robots != robots_OLD)
  MoveUp(GetNextTI(robots,false));
}

CTI *GetNextTI(CTI *robots, bool down)
{
 CBrain *robot = robots.At(0); 
 ENUM_TIMEFRAMES period = robot.GetPeriod();

 if(period >= PERIOD_M30)
  return down ? robots_MID  :  robots_OLD;
 if(period > PERIOD_M15 && period < PERIOD_M30)
  return down ? robots_JUN  :  robots_OLD;
 if(period <= PERIOD_M15)
  return down ? robots_JUN  :  robots_MID;
  
 return robots_JUN;  
}

void FillMoves(CTI *robots)
{
 ENUM_SIGNAL_FOR_TRADE newMoveSELL = NO_SIGNAL;
 ENUM_SIGNAL_FOR_TRADE newMoveBUY = NO_SIGNAL;
 ENUM_SIGNAL_FOR_TRADE moveSELL = SELL;
 ENUM_SIGNAL_FOR_TRADE moveBUY = BUY;
 // если это старший ВИ ему разрешено открывать шаблоны по своим сигналам
 if(robots == robots_OLD)// исправить по-скольку средни ДОЛЖЕН ориентироваться на старший сигнал
 {
  moveSELL = SELL; // разрешающий сигнал для старшего ВИ (всегда 1)
  moveBUY = BUY;
  //------
  newMoveSELL = SELL;
  newMoveBUY = BUY;
 } 
 else
 {
  CTI *ElderTI;
  ElderTI = GetNextTI(robots, false);
  moveSELL = ElderTI.GetMoveSell();
  moveBUY = ElderTI.GetMoveBuy();
  log_file.Write(LOG_DEBUG, StringFormat("Нижний ВИ со старшего считал: moveSEL = %d, MoveBUY = %d", moveSELL, moveBUY));
 } 

 for(int i = 0; i < robots.Total(); i++)      
 { 
  robot = robots.At(i); 
  //log_file.Write(LOG_DEBUG, StringFormat("Для этого ВИ(%s) robot.GetDirection() = %d",robot.GetName(), robot.GetDirection()));                      
  if(robot.GetDirection() == SELL && moveSELL == SELL)            
   newMoveSELL = SELL;
  else if(robot.GetDirection() == BUY && moveBUY == BUY)
   newMoveBUY = BUY;
 }  
 robots.SetMoves(newMoveSELL, newMoveBUY);
 return;
}

double CountTradeRate(CTI *robots)
{
  CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
  return 0.0;
 else
  return 0.9;
}



long ChooseTheBrain(ENUM_TM_POSITION_TYPE pos_type, CTI *robots) 
{
 double volume = 0;
 robot = robots.At(0);
 int type = pos_type % 2;
 int magic =  robot.GetMagic();  
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  if(ctm.GetPositionCount(magic) == 2)// если не 2, робот не может участвовать в принятии позиции снизу
  {
   if(ctm.GetPositionType(magic) % 2 == type && ctm.GetPositionType(magic) != OP_UNKNOWN) 
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
     log_file.Write(LOG_DEBUG, StringFormat("%s изменен маджик, текущий робот - %s, magic = ", robot.GetName(), magic));
    }
    else
     return magic;
   }
  }
 }
 return magic;
}

void OpenPosition(long magicEld, double vol)
{ 
 double temp;
 for(int i = 0; i < ctm.GetPositionCount() && magicEld != 0; i++)
 {
  ctm.PositionSelect(i, SELECT_BY_POS);
  if(ctm.GetPositionMagic() == magicEld)
  {
   if(ctm.GetPositionTakeProfit() != 0)
   {
    temp = vol * volume_ratio;
    ctm.PositionChangeSize(temp);
   }
   else
   {
    temp = vol * (1-volume_ratio);
    ctm.PositionChangeSize(temp);
   }
  }
 }
 return;
}
// Сравнить направление позиции с сигналом 
//bool 

