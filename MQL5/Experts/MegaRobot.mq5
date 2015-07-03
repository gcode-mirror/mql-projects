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
//#include <CExtrContainer.mgh>

//константы
#define SPREAD 30       // размер спреда 

class CTI 
{
 CArrayObj *robots;                        // массив роботов на этм ВИ
 ENUM_SIGNAL_FOR_TRADE _moveBUY;            // разрешение торговли на BUY на этом ВИ
 ENUM_SIGNAL_FOR_TRADE _moveSELL;           // разрешение торговли на SeLL на этом ВИ
  public:
  CTI(){_moveBUY = 0; _moveSELL = 0; robots = new CArrayObj();};
  
  CObject *At(int i){return robots.At(i);}
  int  Total(){return robots.Total();}
  void Add(CBrain *brain);
  void SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY);
  ENUM_SIGNAL_FOR_TRADE GetMoveSell(){return _moveSELL;}
  ENUM_SIGNAL_FOR_TRADE GetMoveBuy(){return _moveBUY;}
};
CTI::Add(CBrain *brain)
{
 robots.Add(brain);
}
CTI::SetMoves(ENUM_SIGNAL_FOR_TRADE _moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 _moveSELL = moveSELL;
 _moveBUY = moveBUY;
}


// ---------переменные робота------------------
CExtrContainer *extr_container;
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
                           
CRabbitsBrain  *rabbit;

CTradeManager *ctm;        // торговый класс 
     
datetime history_start;    // время для получения торговой истории
ENUM_SIGNAL_FOR_TRADE robot_position;
int handleDE; 
ENUM_SIGNAL_FOR_TRADE moveSELL;
ENUM_SIGNAL_FOR_TRADE moveBUY;  
double vol;  // объем позиции                        

ENUM_TM_POSITION_TYPE opBuy, opSell; // заполнить
ENUM_TIMEFRAMES TFs[7]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};/

//---------параметры позиции и трейлинга------------
SPositionInfo pos_tp;
SPositionInfo pos_give;
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
 handleDE = DoesIndicatorExist(_Symbol, PERIOD_H4, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, PERIOD_H4, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора DrawExtremums");
   return (INIT_FAILED);
  }
 }   
 extr_container = new CExtrContainer(handleDE,_Symbol,PERIOD_H4,1000);
 if(!extr_container.Upload()) // Если не загрузился прервем работу
  return (INIT_FAILED);
 

 //-----------Заполним массив роботов на старшем ВИ----------------
 robots_OLD = new CTI();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_H4, extr_container, conbuf));
 //-----------Заполним массив роботов на среднем ВИ----------------
 robots_MID = new CTI();
              robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_H1, conbuf));
 //-----------Заполним массив роботов на младшем ВИ----------------
 robots_JUN = new CTI();
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M15, conbuf));
              robots_JUN.Add(new  CRabbitsBrain(_Symbol, conbuf));
              
 pos_tp.volume = 0;
 pos_give.volume = 0;
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
       
 MoveDown(robots_OLD);
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
 ENUM_SIGNAL_FOR_TRADE moveSELL, moveBUY; 
 double vol_tp, vol_give;                       
 FillMoves(robots, moveSELL, moveBUY);    // заполнение разрешающих сигналов верхнего временного интервала
 FillVolumes(robots, vol_tp, vol_give);   // заполнение объема позиций в соответствиии с временным интервалом (старшие 0-0, младший 0,9-0,1
 // если на верхнем ВИ есть торговые сигналы
 if(moveBUY != 0||moveSELL != 0)
 {
  pos_tp.volume = vol_tp;               
  pos_give.volume = vol_give;
  // для каждого робота на этом ВИ
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // Вычислим торговый сигнал по алгоритму робота и записать тип позиции если она есть
   robot_position = robot.GetSignal();
   // Если пришел сигнал на открытие позиции 
   if(robot_position != OP_UNKNOWN )
   {
    // открыть позицию, с мэджиком этого робота по направлению SELL/BUY
    if(robot_position == SELL && moveSELL == SELL) // если есть разрешение с верхнего ВИ на торговлю в этом направлении
    {
     pos_tp.type = robot_position;  // тип ордера установить согласно роботу
     pos_give.type = robot_position;
    }
    else if(robot_position == BUY && moveBUY == BUY)
    {
     pos_tp.type = robot_position;
     pos_give.type = robot_position;
    }
    else
     continue;
    // ? <открытие позиции>
    ctm.OpenUniquePosition(_Symbol, robot.GetPeriod(), pos_tp, trailing);
    // должен работать таким образом, что бы робот мог открыть только эти две позиции в одном направлении, 
    // то есть как юникПозишн только для двух позиций того же направления
    // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pod_info1,trailing);magic!!
    // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pod_info1,trailing);magic!!
   }
   else if (robot_position == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL)
   {
    // закрыть позицию с мэджиком этого робота
    ctm.ClosePosition(robot.GetMagic()); // полностью, обе
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CTI *robots)
{
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // для каждого робота на ВИ
  // если его позиция существует и активна
  if(ctm.GetPositionCount(robot.GetMagic()) <= 0) // если в стм по тп закрылась позиция, то pos_give должна перекинуться на др. робот
  {
  }
  else
  {
   // если позиция одна, значит нужно передать другому роботу
    //if(ctm.GetPositionCount(robot.GetMagic()) == 1)
    //{
    // long newmagic = ChoseTheBrain(ctm.GetPositionCount(robot.GetMagic()),GetNextTI(robots,false));
    // 
    // ctm.PositionChangeSize(_Symbol, ctm.GetPositionVolume(_Symbol, robot.GetMagic()));
    //}
   ctm.Positi
   double curPrice;
   
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
}

CTI *GetNextTI(CTI *robots, bool down)
{
 CBrain *robot = robots.At(0); 
 ENUM_TIMEFRAMES period = robot.GetPeriod();

 if(period >= PERIOD_H4)
  return down ? robots_MID  :  robots_OLD;
 if(period > PERIOD_M15 && period < PERIOD_H4)
  return down ? robots_JUN  :  robots_OLD;
 if(period <= PERIOD_M15)
  return down ? robots_JUN  :  robots_MID;
  
 return robots_JUN;  
}

void FillMoves(CTI *robots, ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 moveSELL = 0;
 moveBUY = 0;
 // если это старший ВИ ему разрешено открывать шаблоны по своим сигналам
 if(robots == robots_OLD)// достаточно ли безопасно так сравнивать?
 {
  moveSELL = SELL; // разрешающий сигнал для старшего ВИ (всегда 1)
  moveBUY = BUY;
 } 
 else
 {
  CTI *ElderTI;
  ElderTI = GetNextTI(robots, false);
  moveSELL = ElderTI.GetMoveSell();
  moveBUY = ElderTI.GetMoveBuy();
 } 

 for(int i = 0; i < robots.Total(); i++)      
 { 
  robot = robots.At(i);                         
  if(robot.GetDirection() == SELL && moveSELL == SELL)            
   moveSELL = SELL;
  else if(robot.GetDirection() == BUY && moveBUY == BUY)
   moveBUY = BUY;
 }  
 robots.SetMoves(moveSELL, moveBUY);
 return;
}


void FillVolumes(CTI *robots, double vol_tp, double vol_give)
{
  CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
 {
  vol_tp = 0.0;
  vol_give = 0.0;
 }
 else
 {
  vol_tp = 0.9;
  vol_give = 0.1;
 }
}



long ChooseTheBrain(ENUM_TM_POSITION_TYPE pos_type, CArrayObj *robots) 
{
 double volume = 0;
 robot = robots.At(0);
 int magic =  robot.GetMagic();  
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  if(ctm.GetPositionCount(magic))
  {
   if(ctm.GetPositionType(magic) == pos_type)
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
    }
    else
     return magic;
   }
  }
 }
 return magic;
}

// Сравнить направление позиции с сигналом 
//bool 

