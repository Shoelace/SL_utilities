--drop table tz_test
create table TZ_TEST as
select sessiontimezone SESS_TZ, current_date  CUR_DT ,current_timestamp CUR_TS, sysdate SYSD, SYSTIMESTAMP SYSTS, localtimestamp LOCAL_TS, dbtimezone  DB_TZ from DUAL
where 1=0;

column SESSIONTIMEZONE format a35
column TZNAME format a35
column TZABBREV format a10
column tzabbrevs format a50
set pagesize 50



column DUMP_CUR_TS format a60
column DUMP_local_TS format a60
column DUMP_CUR_TS_LOCAL format a70


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


select TZNAME, listagg(tzabbrev,', ') within group (order by tzabbrev) tzabbrevs
from V$TIMEZONE_NAMES
group by TZNAME;

--daylight changes
select timestamp '1999-10-31 01:30:00 US/Pacific PDT' us_daylight
,timestamp '1999-10-31 01:30:00 US/Pacific PST' us_standard
,(timestamp '1999-10-31 01:30:00 US/Pacific PDT' AT TIME ZONE 'UTC') us_daylight_utc
,(timestamp '1999-10-31 01:30:00 US/Pacific PST' AT TIME ZONE 'UTC') us_std_utc
,dump(TIMESTAMP '1999-10-31 01:30:00 US/Pacific PDT') dump_us_daylight
,dump(TIMESTAMP '1999-10-31 01:30:00 US/Pacific PST') dump_us_std
from dual;

select * from TZ_TEST;
select distinct cur_ts from TZ_TEST;

select sessiontimezone
,CUR_TS
, cast(CUR_TS as timestamp with local time zone) CUR_TS_LOCAL
,dump(CUR_TS) dump_cur_ts
, dump(cast(CUR_TS as timestamp with local time zone) ) dump_cur_ts_local
, CUR_TS at time zone 'US/Pacific' cur_ts_at_us
, cur_ts AT TIME ZONE 'UTC' cur_ts_at_utc
, LOCAL_TS
, cast(LOCAL_TS as timestamp with local time zone) LCL_TS_LOCAL
,dump(local_ts) dump_local_ts
from TZ_TEST;

desc TZ_TEST

select TO_DATE('31-AUG-2004','DD-MON-YYYY') + TO_YMINTERVAL('0-1')
FROM DUAL;