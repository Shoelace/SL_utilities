create or replace type typ_timestamp_tab
IS
table of timestamp with time zone;
/

create or replace  package esb_date as

function
 list_of_dates (
   calendar_string varchar2,
   start_date      TIMESTAMP WITH TIME ZONE,
   stop_date       TIMESTAMP WITH TIME ZONE default NULL)
return
  typ_timestamp_tab
pipelined;

function
 list_of_dates (
   calendar_string varchar2,
   start_date      TIMESTAMP WITH TIME ZONE,
   occurances       NUMBER)
return
  typ_timestamp_tab
pipelined;

FUNCTION add_work_days (p_startdate TIMESTAMP WITH TIME ZONE, p_numdays NUMBER) 
RETURN TIMESTAMP WITH TIME ZONE;

END;
/

create or replace  package body esb_date as

function
 list_of_dates (
   calendar_string varchar2,
   start_date      TIMESTAMP WITH TIME ZONE,
   stop_date       TIMESTAMP WITH TIME ZONE)
return
  typ_timestamp_tab
pipelined
is
  l_return_date_after TIMESTAMP WITH TIME ZONE := start_date - interval '1' second;
  l_next_run_date     TIMESTAMP WITH TIME ZONE;
begin
  loop
    DBMS_SCHEDULER.EVALUATE_CALENDAR_STRING(  
      calendar_string   => list_of_dates.calendar_string,
      start_date        => list_of_dates.start_date,
      return_date_after => l_return_date_after,
      next_run_date     => l_next_run_date);

      exit when list_of_dates.l_next_run_date > coalesce(list_of_dates.stop_date,date '9999-12-31');

      pipe row (list_of_dates.l_next_run_date);

      list_of_dates.l_return_date_after    := list_of_dates.l_next_run_date;

 end loop;
END;


function
 list_of_dates (
   calendar_string varchar2,
   start_date      TIMESTAMP WITH TIME ZONE,
   occurances       NUMBER)
return
  typ_timestamp_tab
pipelined
is
  l_return_date_after TIMESTAMP WITH TIME ZONE := start_date - interval '1' second;
  l_next_run_date     TIMESTAMP WITH TIME ZONE;
BEGIN
  FOR i IN 1 .. occurances loop
    DBMS_SCHEDULER.EVALUATE_CALENDAR_STRING(  
      calendar_string   => list_of_dates.calendar_string,
      start_date        => list_of_dates.start_date,
      return_date_after => l_return_date_after,
      next_run_date     => l_next_run_date);

      --exit when list_of_dates.l_next_run_date > coalesce(list_of_dates.stop_date,date '9999-12-31');

      pipe row (list_of_dates.l_next_run_date);

      list_of_dates.l_return_date_after    := list_of_dates.l_next_run_date;

 end loop;
END;


FUNCTION add_work_days (p_startdate TIMESTAMP WITH TIME ZONE, p_numdays NUMBER) 
RETURN TIMESTAMP WITH TIME ZONE
is

  CALENDAR_STRING VARCHAR2(200);
  START_DATE TIMESTAMP WITH TIME ZONE;
  RETURN_DATE_AFTER TIMESTAMP WITH TIME ZONE;
  NEXT_RUN_DATE TIMESTAMP WITH TIME ZONE;
  
  nextcount number := p_numdays;
BEGIN
  CALENDAR_STRING := 'Weekdays;exclude=PublicHolidays;';
  START_DATE := p_startdate;
  RETURN_DATE_AFTER := NULL;

for i in 1 .. nextcount LOOP
  DBMS_SCHEDULER.EVALUATE_CALENDAR_STRING(
    CALENDAR_STRING => CALENDAR_STRING,
    START_DATE => START_DATE,
    RETURN_DATE_AFTER => RETURN_DATE_AFTER,
    NEXT_RUN_DATE => NEXT_RUN_DATE
  );

DBMS_OUTPUT.PUT_LINE('NEXT_RUN_DATE = ' || NEXT_RUN_DATE);
RETURN_DATE_AFTER := NEXT_RUN_DATE;
END LOOP;

return NEXT_RUN_DATE;
END;



end;
/


select *
FROM   TABLE(
esb_date.list_of_dates(
'WEEKDAYS;intersect=PUBLICHOLIDAYS',
SYSDATE+43    ,
sysdate +490
));
/


select esb_date.add_work_days(trunc(sysdate), 5) from dual;
/


