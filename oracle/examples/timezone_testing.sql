--drop table tz_test
create table TZ_TEST as
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, SYSTIMESTAMP SYSTS localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL
where 1=0;


alter session set time_zone = 'America/Los_Angeles';
insert into TZ_TEST 
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, SYSTIMESTAMP SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL;

alter session set time_zone = 'US/Pacific PDT';
insert into TZ_TEST 
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, systimestamp SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL;

alter session set time_zone = 'UTC';
insert into TZ_TEST 
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, SYSTIMESTAMP SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL;

alter session set time_zone = 'Australia/Melbourne';
insert into TZ_TEST 
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, SYSTIMESTAMP SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL;

alter session set time_zone = 'Australia/Melbourne';
insert into TZ_TEST 
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, systimestamp SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL;


select * from V$TIMEZONE_NAMES;

--daylight changes
select timestamp '1999-10-31 01:30:00 US/Pacific PDT',timestamp '1999-10-31 01:30:00 US/Pacific PST'
,(timestamp '1999-10-31 01:30:00 US/Pacific PDT' AT TIME ZONE 'UTC'),(timestamp '1999-10-31 01:30:00 US/Pacific PST' AT TIME ZONE 'UTC')
,dump(TIMESTAMP '1999-10-31 01:30:00 US/Pacific PDT'),dump(TIMESTAMP '1999-10-31 01:30:00 US/Pacific PST')
from dual;

select * from TZ_TEST;
select distinct cur_ts from TZ_TEST;

select sessiontimezone
,CUR_TS
, cast(CUR_TS as timestamp with local time zone) CUR_TS_LOCAL
,dump(CUR_TS)
, dump(cast(CUR_TS as timestamp with local time zone) )
, CUR_TS at time zone 'US/Pacific'
, cur_ts AT TIME ZONE 'UTC'
, LOCAL_TS
, cast(LOCAL_TS as timestamp with local time zone) LCL_TS_LOCAL
,dump(local_ts)
from TZ_TEST;

desc TZ_TEST

select TO_DATE('31-AUG-2004','DD-MON-YYYY') + TO_YMINTERVAL('0-1')
FROM DUAL;