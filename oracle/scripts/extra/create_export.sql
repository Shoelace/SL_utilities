--create_export

--SET termout OFF
SET timing OFF
SET feedback OFF
set define on

spool eai_&1..sql

prompt --spool into to eai_&1..sql

prompt set timing off
prompt SET feedback OFF
prompt set linesize 2000
prompt SET pagesize 50000

prompt SET termout OFF

prompt --number(22)
prompt SET numformat 9999999999999999999999
prompt --iso format
prompt ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
prompt ALTER SESSION SET NLS_TIMESTAMP_FORMAT  = 'YYYY-MM-DD HH:MI:SSXFF';
prompt SET serveroutput ON SIZE UNLIMITED


prompt set trimspool on
prompt

prompt spool &1._export.SQL
prompt column systimestamp format a32
prompt column current_schema format a15
prompt COLUMN CURRENT_USER format a15
prompt column db_name format a10
prompt COLUMN module format a40 wrapped
prompt COLUMN os_user format a15
prompt SET LONG 20000

prompt SET heading ON

prompt prompt /* --------------------------------------------------------

prompt
prompt prompt -- export of &1 

prompt SELECT SYSTIMESTAMP, sys_context('USERENV','OS_USER') os_user ,sys_context('USERENV','DB_NAME') db_name, sys_context('USERENV','CURRENT_SCHEMA') CURRENT_SCHEMA FROM dual;;

prompt
prompt prompt -------------------------------------------------------- */

prompt
prompt SET heading OFF
prompt
prompt prompt SET define OFF;
prompt prompt set long 20000

@gen_export_as_insert &1 ''
prompt /


prompt spool OFF
prompt SET termout ON
prompt SET heading ON
spool off

--SET termout on