#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QPainter>
#include <QMessageBox>
#include <stdio.h>


#ifndef BACKTEST
#define BACKTEST

// стуктура очереди для хранения точек
typedef struct point
 {
  double value;        // значение в точке
  struct point * next; // указатель на следующий элемент
 }Point;
// указатель на корень очереди
Point * root = NULL;
// указатель на последний элемент очереди
Point * current;
// параметры отображения графиков
int graphW = 1000; // ширина отображения графика в пикселях
int graphH = 350; // высота отображения графика в пикселях
int n_positions; // количество позиций (точек) графика
double top_value = -100.0 ; // максимальное значение
double low_value = 100.0 ;   // минимальное значение
double range;        // размер в пунктах от low до top
double rangeX;       // размер единичного отрезка по Х
// параметры бэктеста
int    n_win_pos;      // число выйгрышных позиций
int    n_lose_pos;     // число убыточных позиций
int    sign_last_pos;  // знак последней позиции
float  max_win_pos;    // максимальная прибыльная позиция
float  min_lose_pos;   // минимальная убыточная позиция
float  max_profit;     // максимальная непрерывная прибыль
float  max_lose;       // максимальный непрерывный убыток
int    max_n_win;      // максимальное количество подряд идущих прибыльных позиций
int    max_n_lose;     // максимальное количество подряд идущих убыточных позиций
float  average_profit; // средняя прибыльная позиция
float  average_lose;   // средняя убыточная позиция
float  max_drawdown;   // максимальная просадка
float  abs_drawdown;   // абсолютная просадка
float  rel_drawdown;   // относительная просадка

// массив строк, содержащий наименования полей бэктеста
QString backtest_titles[15]=
{
    "Количество закрытых позиций: ",
    "Количество прибыльных позиций: ",
    "Количество убыточных позиций: ",
    "Знак последней позиции: ",
    "Максимальная прибыльная позиция: ",
    "Минимальная убыточная позиция: ",
    "Максимальная непрерывная прибыль: ",
    "Максимальный непрерывный убыток: ",
    "Максимальное число прибыльных позиций: ",
    "Максимальное число убыточных позиций: ",
    "Средняя прибыльная позиция: ",
    "Средний убыточная позиция: ",
    "Максимальная просадка: ",
    "Абсолютная просадка: ",
    "Относительная просадка: "
};


// функция добавления элемента в очередь. Возвращает указатель на последний созданный элемент

void SetPoint (double value)
 {
   Point * new_point;           // указатель на новый элемент очереди
   new_point = new Point();     // выделяем память под новый элемент
   new_point->next = NULL;      // указываем на следующий элемент очереди
   new_point->value = value;    // сохраняем в текущий элемент значение поля value
   if (root == NULL)            // если это первый элемент
     {
       root = new_point;
     }
   else
     {
       current->next = new_point;
     }
   current = new_point;
}

// функция очищения элементов очереди

 void  RemovePoints (Point * root)
  {
   Point * pn; // указатель на элемент стека
   while (root)
    {
      pn = root;
      root= root->next;
      delete pn;
    }
  }

// функция ищет максимальное и минимальное значения считанных данных

void  GetTopAndLow (double value)
 {
  if (value > top_value)
     top_value = value;
  if (value < low_value)
     low_value = value;
 }

// функция возвращает положение точки по оси Y в пикселях

int  GetY (double value)
 {
  return graphH - (int)(double)(graphH*(value-low_value)/range);
 }

// функция вычисляет размер в пикселях по Х единичного отрезка

void GetRangeX ()
 {
  rangeX = (int)(double)(1.0*graphW/(n_positions-1));
 }

// функция вычисляет размер в пунктах по Х единичного отрезка

void GetRangeXFloat ()
 {
  rangeX = 1.0*graphW/(n_positions-1);
 }

// функция открывает файл из считывает из него данные

 bool ReadFile (char * url)
  {
   FILE * fp; // хэндл файла
   int index;
   float tmp_value;   // переменная временного хранения данных
   fp = fopen(url,"r");
   if (fp == NULL) // если файл не удалось открыть
    return false;

   fscanf(fp,"%i",&n_positions); // считываем количество позиций из файла
   fscanf(fp,"%i",&n_win_pos); // считываем количество выйгрышных позиций из файла
   fscanf(fp,"%i",&n_lose_pos); // считываем количество убыточных позиций из файла
   fscanf(fp,"%i",&sign_last_pos); // считываем знак последней позиции
   fscanf(fp,"%f",&max_win_pos); // считываем максимальную прибыльную позицию
   fscanf(fp,"%f",&min_lose_pos); // считываем минимальную убыточную позицию
   fscanf(fp,"%f",&max_profit); // считываем максимальную непрерывную прибыль
   fscanf(fp,"%f",&max_lose); // считываем максимальный непрерывный убыток
   fscanf(fp,"%i",&max_n_win); // считываем максимальное число непрерывных прибыльных позиций
   fscanf(fp,"%i",&max_n_lose); // считываем максимальное число непрерывных убыточных позиций
   fscanf(fp,"%f",&average_profit); // считываем среднюю прибыльную позицию
   fscanf(fp,"%f",&average_lose); // считываем среднюю убыточную позицию
   fscanf(fp,"%f",&max_drawdown); // считываем максимальную просадку
   fscanf(fp,"%f",&abs_drawdown); // считываем абсолютную просадку
   fscanf(fp,"%f",&rel_drawdown); // считываем относительную просадку

   // проходим и считываем
   for (index=0;index<(n_positions-1) && !feof(fp); index++)
     {

      fscanf(fp,"%f",&tmp_value); // считываем значение точки 1-го графика
      SetPoint(tmp_value);        // выделяем память под новый элемент стека и записываем считанное значение
      GetTopAndLow (tmp_value);   // вычисляем top и low
     }
   range = top_value - low_value;  // вычисляем расстояние в пунктах от top до low
   fclose(fp);  // закрываем файл
   return true;
 }

 // дополнительные функции

 // создает BMP файл из графика баланса
 bool  CreateBitmapFile ()
  {
    return true;
  }

 // сохраняет отчетность в виде HTML страницы
 bool  SaveBacktestAsHTML (char * html_url)
  {
    FILE * fp;
    fp = fopen(html_url,"w");
    fprintf(fp,"<HTML>");
    fprintf(fp,"<title>Отчетность</title>");
    fprintf(fp,"<body>");
    // создание графиков баланса и маржи
    fprintf(fp,"<img></img>");
    fprintf(fp,"<br>");
    // создание таблицы отчетности
    fprintf(fp,"Бэктест:<br>");
    fprintf(fp,"<table border=1 style=border-style:double;>");
    fprintf(fp,"<tr>");
    fprintf(fp,"<td>Параметр</td>");
    fprintf(fp,"<td>Значение</td>");
    fprintf(fp,"</tr>");
    fprintf(fp,"</table>");
    fprintf(fp,"</body></HTML>");
    fclose(fp);
    return true;
  }


#endif

// базовая функция прорисовки графиков
void QWidget::paintEvent(QPaintEvent  *event) {
// объект графического отображения
QPainter paint(this);
  // точки для рисования рамки и графика
  QPoint point1(10,40);                // левая верхняя
  QPoint point2(graphW+10,40);         // правая верхняя
  QPoint point3(graphW+10,graphH+40);  // правая нижняя
  QPoint point4(10,graphH+40);         // левая нижняя
  // перья
  QPen pen_graph(Qt::blue, 2, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);         // перо для графика
  QPen pen_form(Qt::black, 1, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);   // перо для рамки графика
  // указатель на элемент очереди
  Point * elem;
  int     rgX;                     // смещение по оси Х в пикселях
  double  rgXFloat;                // смещение по оси X в пунктах

  // отрисовка рамки

   paint.setPen(pen_form); // задаем перо для отрисовки рамки
  // рисуем рамку
   paint.drawLine(point1,point2); // верхняя горизонталь
   paint.drawLine(point2,point3); // правая вертикаль
   paint.drawLine(point3,point4); // нижняя горизонталь
   paint.drawLine(point4,point1); // левая вертикаль

   paint.setPen(pen_graph); // задаем перо для отрисовки рамки
  // рисуем график по точкам
  if (root)
   {
    point1.setX(10);
    point1.setY(GetY(root->value)+40);
    if (graphW >= (n_positions-1) )
     {
     GetRangeX ();
     rgX = rangeX;
     for (elem = root->next; elem; elem = elem->next)
       {
        point2.setX(rgX+10);
        point2.setY(GetY(elem->value)+40);
        paint.drawLine(point1,point2);  // рисует линию
        point1.setX(rgX+10);
        point1.setY(GetY(elem->value)+40);
        rgX+=rangeX;  // смещаем на длину единичного отрезка
       }
     }
    else
     {
     GetRangeXFloat();
     rgX = 1;
     rgXFloat = rangeX;
     for (elem = root->next; elem; elem = elem->next)
       {
        if (rgXFloat >= 1)
          {
           rgXFloat-=1;
           point2.setX(rgX+10);
           point2.setY(GetY(elem->value)+40);
           paint.drawLine(point1,point2);  // рисует линию
           point1.setX(rgX+10);
           point1.setY(GetY(elem->value)+40);
           rgX++;
          }
        rgXFloat+=rangeX;  // смещаем на длину единичного отрезка
       }
     }


   }
}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
 int index;
 // считываем файл с результатами бэктеста
 ReadFile ("C:\\cool.txt") ;

 // заполняем поля отчетности параметрами из файла
/*
 int    n_win_pos;      // число выйгрышных позиций
 int    n_lose_pos;     // число убыточных позиций
 int    sign_last_pos;  // знак последней позиции
 float  max_win_pos;    // максимальная прибыльная позиция
 float  min_lose_pos;   // минимальная убыточная позиция
 float  max_profit;     // максимальная непрерывная прибыль
 float  max_lose;       // максимальный непрерывный убыток
 int    max_n_win;      // максимальное количество подряд идущих прибыльных позиций
 int    max_n_lose;     // максимальное количество подряд идущих убыточных позиций
 float  average_profit; // средняя прибыльная позиция
 float  average_lose;   // средняя убыточная позиция
 float  max_drawdown;   // максимальная просадка
 float  abs_drawdown;   // абсолютная просадка
 float  rel_drawdown;   // относительная просадка
*/
    ui->setupUi(this);
    ui->listWidget->addItem(backtest_titles[0]+QString::number(n_positions-1));  // число позиций
    ui->listWidget->addItem(backtest_titles[1]+QString::number(n_win_pos));    // число прибыльных позиций
    ui->listWidget->addItem(backtest_titles[2]+QString::number(n_lose_pos));   // число убыточных позиций
    ui->listWidget->addItem(backtest_titles[3]+QString::number(sign_last_pos));// знак последней позиции
    ui->listWidget->addItem(backtest_titles[4]+QString::number(max_win_pos));  // максимальная прибыльная позиция
    ui->listWidget->addItem(backtest_titles[5]+QString::number(min_lose_pos)); // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[6]+QString::number(max_profit));   // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[7]+QString::number(max_lose));     // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[8]+QString::number(max_n_win));     // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[9]+QString::number(max_n_lose));     // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[10]+QString::number(average_profit));     // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[11]+QString::number(average_lose));       // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[12]+QString::number(max_drawdown));       // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[13]+QString::number(abs_drawdown));     // минимальная убыточная позиция
    ui->listWidget->addItem(backtest_titles[14]+QString::number(rel_drawdown));     // минимальная убыточная позиция

    ui->listWidget->pos().setY(graphH+100);
    ui->listWidget->pos().setX(10);

}

MainWindow::~MainWindow()
{
    delete ui;
}

// сохраняет отчетность в формате HTML
void MainWindow::on_pushButton_clicked()
{
    SaveBacktestAsHTML ("D:\BACKTEST.html");
}

// обновляет отчетность
void MainWindow::on_pushButton_3_clicked()
{
    RemovePoints(root);
}
