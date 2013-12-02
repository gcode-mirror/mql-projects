//+----------------------------------------------------------------------------+
//|                                                     test_OpenPosition.mq4  |
//|                                                                            |
//|                                                                            |
//|  17.03.2008  Скрипт для тестирования функции OpenPosition().               |
//+----------------------------------------------------------------------------+
#property copyright "Ким Игорь В. aka KimIV"
#property link  "http://www.kimiv.ru"
#property show_confirm

//------- Глобальные переменные -----------------------------------------------+
//bool   gbDisabled    = False;          // Флаг блокировки советника
//color  clOpenBuy     = LightBlue;      // Цвет значка открытия покупки
//color  clOpenSell    = LightCoral;     // Цвет значка открытия продажи
//int    Slippage      = 3;              // Проскальзывание цены
//int    NumberOfTry   = 5;              // Количество торговых попыток
//bool   UseSound      = True;           // Использовать звуковой сигнал
//string NameFileSound = "expert.wav";   // Наименование звукового файла

//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>                  // Стандартная библиотека
#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // Описание переменных 
#include <AddOnFuctions.mqh> 
#include <DesepticonOpening.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся

void start() {
  double pa, pb, po;
  string sy;
  openPlace = "test opening";
  int timeframe = PERIOD_H1;
//1. Купить 0.1 лота текущего инструмента
//  OpenPosition(NULL, OP_BUY, 0.1);

//2. Продать 2 лота EURUSD
//  sy="EURUSD";
//  pa=MarketInfo("EURUSD", MODE_ASK);
//  pb=MarketInfo("EURUSD", MODE_BID);
//  po=MarketInfo("EURUSD", MODE_POINT);
//  OpenPositionTest(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber);

//3. Продать 0.12 лота USDCAD со стопом 20 пунктов
//  sy="USDCAD";
//  pa=MarketInfo("USDCAD", MODE_ASK);
//  pb=MarketInfo("USDCAD", MODE_BID);
//  po=MarketInfo("USDCAD", MODE_POINT);
//  OpenPosition("USDCAD", OP_SELL, 0.12, pb+20*po);

//4. Купить 0.15 лота USDJPY с тейком 40 пунктов
//  sy="USDJPY";
//  pa=MarketInfo("USDJPY", MODE_ASK);
//  pb=MarketInfo("USDJPY", MODE_BID);
//  po=MarketInfo("USDJPY", MODE_POINT);
//  OpenPosition("USDJPY", OP_BUY, 0.15, 0, pa+40*po);

//5. Продать 0.1 лота GBPJPY со стопом 23 и тейком 44 пункта
//  sy="GBPJPY";
//  pa=MarketInfo("GBPJPY", MODE_ASK);
//  pb=MarketInfo("GBPJPY", MODE_BID);
//  po=MarketInfo("GBPJPY", MODE_POINT);
//  OpenPosition("GBPJPY", OP_SELL, 0.1, pb+23*po, pb-44*po);
}


