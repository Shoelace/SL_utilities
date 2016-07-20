CREATE OR REPLACE PACKAGE SL_LOG4_LIB
AUTHID CURRENT_USER
AS

PROCEDURE log_table_trim(p_retention INTERVAL DAY TO SECOND       , p_loglevel log4.loglevel DEFAULT NULL, p_loguser log_table.loguser%TYPE DEFAULT NULL, p_loggername log_table.loggername%TYPE DEFAULT NULL,p_archive_tablename VARCHAR2 DEFAULT NULL);
PROCEDURE log_table_trim(p_retention_date TIMESTAMP WITH TIME ZONE, p_loglevel log4.loglevel DEFAULT NULL, p_loguser log_table.loguser%TYPE DEFAULT NULL, p_loggername log_table.loggername%TYPE DEFAULT NULL,p_archive_tablename VARCHAR2 default NULL);

PROCEDURE log_table_trim;
PROCEDURE log_table_archive(p_archive_tablename VARCHAR2 default 'LOG_ARCHIVE');

END SL_LOG4_LIB;
/


CREATE OR REPLACE PACKAGE BODY SL_LOG4_LIB
AS
k_log logger := logmanager.getlogger();

PROCEDURE log_table_trim(p_retention INTERVAL DAY TO SECOND, p_loglevel log4.loglevel DEFAULT NULL, p_loguser log_table.loguser%TYPE DEFAULT NULL, p_loggername log_table.loggername%TYPE DEFAULT NULL,p_archive_tablename VARCHAR2 default NULL)
AS
v_now TIMESTAMP := systimestamp;
BEGIN
k_log.ENTRY;

k_log.debug('retention period:'||p_retention);

  IF  p_retention < INTERVAL '0' SECOND THEN
    log_table_trim(v_now + p_retention,p_loglevel,p_loguser,p_loggername,p_archive_tablename);
  ELSE
    log_table_trim(v_now - p_retention,p_loglevel,p_loguser,p_loggername,p_archive_tablename);
  end if;

k_log.exit;

END log_table_trim;



PROCEDURE log_table_trim(p_retention_date TIMESTAMP WITH TIME ZONE, p_loglevel log4.loglevel DEFAULT NULL, p_loguser log_table.loguser%TYPE DEFAULT NULL, p_loggername log_table.loggername%TYPE DEFAULT NULL,p_archive_tablename VARCHAR2 default NULL)
AS
v_llevel VARCHAR2(2000);
v_stmt VARCHAR(32000) := q'[ FROM log_table WHERE logtimestamp < :retention]';
cnt number;
BEGIN
k_log.entry;

  IF p_loglevel IS NOT NULL THEN
    v_stmt := v_stmt ||' AND loglevel = :llevel' ;
    v_llevel := p_loglevel.toString();
  ELSE
    v_stmt := v_stmt ||' AND (1=1 OR :llevel IS NULL)' ;
    v_llevel := NULL;
  END IF;

  IF p_loguser IS NOT NULL THEN
    v_stmt := v_stmt ||' AND loguser = :luser' ;
  ELSE
    v_stmt := v_stmt ||' AND (1=1 OR :luser IS NULL)' ;
  END IF;
  
  IF p_loggername IS NOT NULL THEN
    v_stmt := v_stmt ||' AND loggername = :lname' ;
  ELSE
    v_stmt := v_stmt ||' AND (1=1 OR :lname IS NULL)' ;
  END IF;

  --k_log.debug('about to execute:'||v_stmt);
  
  IF p_archive_tablename IS NOT NULL THEN
    k_log.DEBUG('about to execute:'||'insert into '||p_archive_tablename||' select *'||v_stmt);
    EXECUTE IMMEDIATE 'insert into '||p_archive_tablename||' select *'||v_stmt USING p_retention_date, v_llevel , p_loguser, p_loggername  ;
    cnt := SQL%ROWCOUNT;
    k_log.DEBUG('archived {} {} {} records', cnt, p_loggername, v_llevel );
  END IF;

  
  EXECUTE immediate 'DELETE'||v_stmt USING p_retention_date, v_llevel , p_loguser, p_loggername;
  cnt := SQL%ROWCOUNT;
 -- EXECUTE IMMEDIATE 'select count(*) '||v_stmt INTO cnt USING p_retention_date, v_llevel , p_loguser, p_loggername  ;
 
  k_log.DEBUG('deleted {} {} {} records older then {} {} ', cnt, p_loggername, v_llevel, p_retention_date );


k_log.exit;

END log_table_trim;


PROCEDURE log_table_trim
IS 
BEGIN
  log_table_archive(NULL);

END log_table_trim;

PROCEDURE log_table_archive(p_archive_tablename VARCHAR2 DEFAULT 'LOG_ARCHIVE')
IS
ll_row log_levels%rowtype;

l_min_retention NUMBER;

BEGIN
  k_log.ENTRY;

  --get minimum number of days to look back to delete/archive stuff
  SELECT MIN(min_retention)
  INTO l_min_retention
  from (
  SELECT logger_name,least((CASE WHEN TRACE > 0 THEN TRACE ELSE 999999999 END)
  ,(CASE WHEN debug > 0 THEN debug ELSE 999999999 END)
  ,(CASE WHEN info > 0 THEN info ELSE 999999999 END)
  ,(CASE WHEN warn > 0 THEN warn ELSE 999999999 END)
  ,(CASE WHEN ERROR > 0 THEN ERROR ELSE 999999999 END)
  ,(CASE WHEN fatal > 0 THEN fatal ELSE 999999999 END)
  ) min_retention
  FROM log_levels)
  where min_retention > 0;
  
  k_log.debug('min_retention='||l_min_retention);
  
  IF l_min_retention IS NULL OR l_min_retention = 999999999 THEN
  k_log.info('retention disbaled');
  k_log.exit;
  END IF;

  FOR v_loggernames IN (SELECT DISTINCT loggername,loglevel FROM log_table where logtimestamp < systimestamp - l_min_retention order by loggername, loglevel ) LOOP
      ll_row := get_log_level(v_loggernames.loggername);
      
      --k_log.DEBUG('loggername:{}   loglevel name:{}  trace:{}', v_loggernames.loggername, ll_row.logger_name, ll_row.TRACE);
      CASE v_loggernames.loglevel
      when 'TRACE' THEN
        IF ll_row.TRACE >= 0 THEN
           log_table_trim(p_retention_date => trunc(systimestamp) - ll_row.TRACE  , p_loglevel => LogLevel.TRACE, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      when 'DEBUG' THEN
        IF ll_row.DEBUG >= 0 THEN
           log_table_trim(p_retention_date => trunc(SYSTIMESTAMP) - ll_row.DEBUG  , p_loglevel => LogLevel.DEBUG, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      when 'INFO' THEN
        IF ll_row.INFO >= 0 THEN
           log_table_trim(p_retention_date => trunc(SYSTIMESTAMP) - ll_row.INFO  , p_loglevel => LogLevel.INFO, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      when 'WARN' THEN
        IF ll_row.WARN >= 0 THEN
           log_table_trim(p_retention_date => trunc(SYSTIMESTAMP) - ll_row.WARN  , p_loglevel => LogLevel.WARN, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      when 'ERROR' THEN
        IF ll_row.ERROR >= 0 THEN
           log_table_trim(p_retention_date => trunc(SYSTIMESTAMP) - ll_row.ERROR  , p_loglevel => LogLevel.ERROR, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      when 'FATAL' THEN
        IF ll_row.WARN >= 0 THEN
           log_table_trim(p_retention_date => trunc(systimestamp) - ll_row.FATAL  , p_loglevel => LogLevel.FATAL, p_loggername => v_loggernames.loggername, p_archive_tablename => p_archive_tablename);
        END IF;
      ELSE
       NULL; --unknown level
      END CASE;
      
  END LOOP;
k_log.exit;
END;


END SL_LOG4_LIB;
/
