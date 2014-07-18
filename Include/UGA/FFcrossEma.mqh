//+------------------------------------------------------------------+
//|                                                   FFcrossEma.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//-----------------------------------------------------------------------+
// Функция оценки приспособленности особи. Вызывается из UGA.            |
// В ней рассчитывается оптимизируемая функция задачи.                   |
//-----------------------------------------------------------------------+
//========Skin============================================================
void FitnessFunction(int chromos)
{
/*  double x1 =0.0;
  double x2 =0.0;
  double sum=0.0;
  int    cnt=1;

  while (cnt<=GeneCount)
  {
    x1=Colony[cnt][chromos];
    cnt++;
    x2=Colony[cnt][chromos];
    cnt++;
    sum+=pow(cos((double) (2 * x1 * x1)) - 0.11e1, 0.2e1) + 
         pow(sin(0.5e0 * (double) x1) - 0.12e1, 0.2e1) - 
         pow(cos((double) (2 * x2 * x2)) - 0.11e1, 0.2e1) + 
         pow(sin(0.5e0 * (double) x2) - 0.12e1, 0.2e1);
  }
  AmountStartsFF++;
  Colony[0][chromos]=sum;*/
}
//————————————————————————————————————————————————————————————————————————

//-----------------------------------------------------------------------+
// Сервисная функция. Вызывается из UGA.                                 |
// Если в ней нет обходимости, оставить функцию пустой так:              |
//   void ServiceFunction()                                              |
//   {                                                                   |
//   }                                                                   |
//-----------------------------------------------------------------------+
void ServiceFunction()
{ 
/*  double x1 =0.0;
  double x2 =0.0;
  int    cnt=1;
  ERROR=0.0;

  if (OptimizeMethod==1)
  {
    while (cnt<=GeneCount)
    {
      x1=Chromosome[cnt];
      ERROR+=MathAbs(3.0702-x1);
      cnt++;
      x2=Chromosome[cnt];
      ERROR+=MathAbs(3.3159-x2);
      cnt++;
    }
    ERROR=ERROR/GeneCount;
    Comment("Fitness func =",Chromosome[0],"\n",
            "Эталонные значения аргументов:","\n",
            "x1 = 3.0702","\n",
            "x2 = 3.3159","\n",
            "Полученные значения аргументов:","\n",
            "x1 =",Chromosome[1],"\n",
            "x2 =",Chromosome[2],"\n",
            " ","\n",
            "Средняя ошибка на ген=",ERROR);
  }
  else
  {
    while (cnt<=GeneCount)
    {
      x1=Chromosome[cnt];
      ERROR+=MathAbs(-3.3157-x1);
      cnt++;
      x2=Chromosome[cnt];
      ERROR+=MathAbs(-3.0725-x2);
      cnt++;
    }
    ERROR=ERROR/GeneCount;
    Comment("Fitness func =",Chromosome[0],"\n",
            "Эталонные значения аргументов:","\n",
            "x1 = -3.3157","\n",
            "x2 = -3.0725","\n",
            "Полученные значения аргументов:","\n",
            "x1 =",Chromosome[1],"\n",
            "x2 =",Chromosome[2],"\n",
            " ","\n",
            "Средняя ошибка на ген=",ERROR);
  }*/
}
//————————————————————————————————————————————————————————————————————————

