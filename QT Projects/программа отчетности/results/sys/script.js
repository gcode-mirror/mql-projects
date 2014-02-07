//+------------------------------------------------------------------+
//| Скрипт переводит Unix time в формат Григорианского календаря     |
//+------------------------------------------------------------------+

 var N_DAYS = new Array // массив сумм дней в серии из  4-х годов
 (
  31,59,90,120,151,181,212,243,273,304,334,365,
  396,424,455,485,516,546,577,608,638,669,699,730,
  761,790,821,851,882,912,943,974,1004,1035,1065,1096,
  1127,1155,1186,1216,1247,1277,1308,1339,1369,1400,1430,1461 
 );

   var _4years_days = 1461;  // количество дней в первых 4-х годах (дальше ситуация по циклу повторяется)


   // временные поля 
   var _year;     // год
   var _month;    // месяц
   var _day;      // день
   var _hours;    // час
   var _minutes;  // минута
   var _seconds;  // секунда

 // переменные для вычисления текущего положения курсора (баланса, времени)

   var _max_balance,_min_balance;
   var _start_time, _finish_time;
   var _balance_range,_time_range;

 //для деления числа без остатка
 function div(val, by)
  {
   return (val - val % by) / by;
  } 


 //возвращает время в виде строки
 function GetN4Years(last_days)
  {
	var index;   // счетчик по циклу
	for (index=0;index<48;index++)
	{
	  if (N_DAYS[index] >= last_days)
           return index;
	}
   return 0;
  }

 //возвращает время в виде строки
 function   ConvertUnixToTime (unix_time)
  {
	var tmp;
	// получаем количество минут
	_minutes = div(unix_time, 60);
	// получаем форматное остаточное количество секунд
	_seconds = unix_time % 60;
	// получаем количество часов
	_hours   = div(_minutes , 60);
	// получаем форматное остаточное количество минут
	_minutes = _minutes % 60;
	// получаем количество дней
	_day     = div(_hours , 24);
	// получаем форматное остаточное количество часов
	_hours   =  _hours % 24;
	// получаем количество серий из 4-х годов
	_year    =  (div(_day , _4years_days) )*4+1970;
	// получаем месяц, день и модифицируем год
	tmp      =  GetN4Years(_day % _4years_days);
	// модифицируем год
	_year    =  _year + div(tmp , 12);
	// вычисляем месяц
	_month   =  1 + tmp % 12;
	// вычисляем день
	if (tmp > 0)
	_day     =  _day % _4years_days - N_DAYS[tmp-1] + 1;
	else
        _day     =  _day % _4years_days + 1;

  }

 // функция переводит unix время в формат григорианского календаря в виде строки
function   TimeToString (unix_time)
 {
   var returned_str="";
   ConvertUnixToTime (unix_time);
   if (_day < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _day+".";
   if (_month < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _month+".";
   returned_str = returned_str + _year+" "; 
   if (_hours < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _hours+":";
   if (_minutes < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _minutes+":";
   if (_seconds < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _seconds+"";
  return returned_str;
   
 }
 
 // функция получает значение баланса и времени в текущем положении курсора
function GetPoints() 
 {
  var x=event.x,y=event.y;
  var value_balance;
  var value_time; 
  if (y >= 20 && y <= 306 && x >= 0 && x <= 688) 
    { 
     value_balance = _min_balance + (286-y+20)/286*_balance_range;
     value_time    = _start_time  + Math.floor( x/688*_time_range );
     graph.alt = 'Баланс: '+ value_balance.toFixed(6)+'\nВремя: '+ TimeToString(value_time); 
    } 
  }


//---- функция при загрузке скрипта 
function     OnLoad (max_balance,min_balance,start_time,finish_time)
 {
  _max_balance   = max_balance;
  _min_balance   = min_balance;
  _start_time    = start_time;
  _finish_time   = finish_time;
  _balance_range = max_balance-min_balance;
  _time_range    = finish_time-start_time;

 }