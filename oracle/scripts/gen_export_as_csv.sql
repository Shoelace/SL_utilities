--CLEAR SCREEN
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WORD_WRAPPED
--define vcursor REFCURSOR
--prompt start

DECLARE
c_x SYS_REFCURSOR;
  C NUMBER;
  COL_CNT NUMBER;
  maxCOL NUMBER;
  
  CST_DATE_FMT CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
  
  DESC_T SYS.DBMS_SQL.DESC_TAB3;
  r sys.dbms_sql.desc_rec3;
  
  x VARCHAR2(2000);
  v_null varchar2(20);

  V_TABLE_NAME VARCHAR2(32) := '&1';
  v_query VARCHAR2(32000) := '&2';

V_OUTPUT_QUERY VARCHAR2(32000);

BEGIN


IF V_QUERY IS NULL THEN
v_query := 'select * from '||v_table_name;
END IF;

DBMS_OUTPUT.PUT_LINE('query:'||V_QUERY);

  OPEN C_X FOR V_QUERY;
  C := dbms_sql.to_cursor_number(c_x);


  SYS.DBMS_SQL.DESCRIBE_COLUMNS3(
    C => C,
    COL_CNT => COL_CNT,
    DESC_T => DESC_T
  );
DBMS_OUTPUT.PUT_LINE('COL_CNT = ' || COL_CNT);

  maxCOL := 1;

V_OUTPUT_QUERY :=  'SELECT ''';
  FOR I IN   DESC_T.FIRST .. DESC_T.LAST LOOP
    MAXCOL := GREATEST(MAXCOL , LENGTH(DESC_T(I).COL_NAME) );
    V_OUTPUT_QUERY := V_OUTPUT_QUERY ||'"'||DESC_T(I).COL_NAME||'",';
END LOOP;
V_OUTPUT_QUERY := rtrim(V_OUTPUT_QUERY,',') ||''' csv_row'||chr(10)||'FROM DUAL UNION ALL ';
MAXCOL := MAXCOL + 1;
DBMS_OUTPUT.PUT_LINE('MAXCOL = ' || MAXCOL);

V_OUTPUT_QUERY :=  V_OUTPUT_QUERY||'SELECT ';

  FOR i IN   DESC_T.FIRST .. DESC_T.LAST LOOP
  r := DESC_T(i);

--ripped from dba_tab_cols
X:= CASE R.COL_TYPE
	WHEN DBMS_SQL.VARCHAR2_TYPE  THEN '''"''||'||r.col_name||'||''"'''
	WHEN DBMS_SQL.Char_Type  THEN '''"''||'||r.col_name||'||''"'''
	--WHEN dbms_sql.Number_Type    THEN r.col_name
	WHEN DBMS_SQL.LONG_TYPE                    THEN 'LONG'
	--WHEN dbms_sql.Rowid_Type                   THEN 'ROWID'
	--WHEN DBMS_SQL.UROWID_TYPE                  THEN 'UROWID' || (CASE R.COL_MAX_LEN WHEN 4000 THEN NULL ELSE '('||R.COL_MAX_LEN||')' END)
	WHEN dbms_sql.Date_Type                    THEN '''"''||to_char('||r.col_name||','''||CST_DATE_FMT||''')||''"'''
	WHEN dbms_sql.User_Defined_Type            THEN r.col_type_name --'USERDEFINED'
	WHEN dbms_sql.Clob_Type                    THEN (case r.col_charsetform when 2 then 'NCLOB' else 'CLOB' end) 
	WHEN dbms_sql.Blob_Type                    THEN 'BLOB'
	WHEN dbms_sql.Bfile_Type                   THEN 'BINARY FILE LOB'
	WHEN dbms_sql.Timestamp_Type               THEN 'TIMESTAMP(' ||r.col_scale|| ')' 
	WHEN dbms_sql.Timestamp_With_TZ_Type       THEN 'TIMESTAMP(' ||r.col_scale|| ')' || ' WITH TIME ZONE'
	WHEN dbms_sql.Timestamp_With_Local_TZ_type THEN 'TIMESTAMP(' ||r.col_scale|| ')' || ' WITH LOCAL TIME ZONE' 
	WHEN dbms_sql.Interval_Year_to_Month_Type  THEN 'INTERVAL YEAR(' ||r.col_precision||') TO MONTH'
	WHEN dbms_sql.Interval_Day_To_Second_Type  THEN 'INTERVAL DAY(' ||r.col_precision||') TO SECOND(' || r.col_scale || ')'
	ELSE r.col_name
END;

/*
Varchar2_Type                         constant pls_integer :=   1;
Number_Type                           constant pls_integer :=   2;
Long_Type                             constant pls_integer :=   8;
Rowid_Type                            constant pls_integer :=  11;
Date_Type                             constant pls_integer :=  12;
Raw_Type                              constant pls_integer :=  23;
Long_Raw_Type                         constant pls_integer :=  24;
Char_Type                             constant pls_integer :=  96;
Binary_Float_Type                     constant pls_integer := 100;
Binary_Bouble_Type                    constant pls_integer := 101;
MLSLabel_Type                         constant pls_integer := 106;
User_Defined_Type                     constant pls_integer := 109;
Ref_Type                              constant pls_integer := 111;
Clob_Type                             constant pls_integer := 112;
Blob_Type                             constant pls_integer := 113;
Bfile_Type                            constant pls_integer := 114;
Timestamp_Type                        constant pls_integer := 180;
Timestamp_With_TZ_Type                constant pls_integer := 181;
Interval_Year_to_Month_Type           constant pls_integer := 182;
Interval_Day_To_Second_Type           constant pls_integer := 183;
Urowid_Type                           constant pls_integer := 208;
Timestamp_With_Local_TZ_type          constant pls_integer := 231;
*/


IF NOT r.col_null_ok THEN
v_null := 'NOT NULL';
ELSE
v_null := '        ';
END IF;


V_OUTPUT_QUERY := V_OUTPUT_QUERY||CHR(10)||'nvl2('||rpad(r.col_name,maxCOL)||','||X||',NULL)';
  

IF I < COL_CNT THEN
  V_OUTPUT_QUERY := V_OUTPUT_QUERY|| '||'',''||';
ELSE
  V_OUTPUT_QUERY := V_OUTPUT_QUERY||' csv_row'||chr(10);
end if;

END LOOP;


V_OUTPUT_QUERY := V_OUTPUT_QUERY||'FROM ('||v_query||')';

--DBMS_OUTPUT.PUT_LINE is screwy on older oracle version.. it puts breaks in wrong spot
--DBMS_OUTPUT.PUT_LINE(V_OUTPUT_QUERY);

FOR I IN 1 .. REGEXP_COUNT(V_OUTPUT_QUERY,'$',1,'im') LOOP
DBMS_OUTPUT.PUT_LINE(REGEXP_SUBSTR(V_OUTPUT_QUERY,'^.*$',1,I,'im'));
end loop;


	DBMS_SQL.CLOSE_CURSOR(C);
  
--OPEN :VCURSOR FOR V_OUTPUT_QUERY;


end;
/
undefine 1
undefine 2

--print vcursor
