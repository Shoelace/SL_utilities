
CREATE OR REPLACE PROCEDURE Maintain_DATABASE_CONSTANTS
authid current_user
IS

--dual purpose git comment.. this procedure and generated package
c_GIT VARCHAR2(32000) := '
/*GITSTART$Format:
Git ID   : %H
Author   : %an < %ae >
Date     : %ai
Reference: %d
$GITEND*/
';

  v_exists NUMBER;
  v_do_apply BOOLEAN;

  Newline    CONSTANT CHAR( 1 ) := Chr( 10 );

  --need schema and double quotes here to match dbms_metadata
  First_Line CONSTANT VARCHAR2(80)    := 'CREATE OR REPLACE PACKAGE "'||USER||'"."DATABASE_CONSTANTS" AUTHID CURRENT_USER IS';
  Last_Line  CONSTANT VARCHAR2(80)    := 'END;';
  v_DDL        CLOB  := First_Line||Newline||c_GIT||Newline;
  
  TYPE obj_table IS TABLE OF VARCHAR2(32);
  --list of custom objects that need checking for existance.
  v_OBJECTS obj_table := obj_table('LOGMANAGER','PK_SEND_EMAIL','DATABASE_CONSTANTS');

  v_param_qry VARCHAR2(2000) := 
q'[SELECT NAME param_name
         ,TYPE param_type
         , (CASE TYPE WHEN 1 THEN 'BOOLEAN' WHEN 2 THEN 'VARCHAR2(4000)' WHEN 3 THEN 'INTEGER' WHEN 6 THEN 'INTEGER' END) plsql_type
         ,VALUE param_value
         , display_value
         , description 
         --, max(length(name)) over () max_name_len
         ,translate(initcap(NAME),' _',' ') display_name
    FROM v$parameter
    WHERE isinstance_modifiable = 'FALSE'
    AND issys_modifiable = 'FALSE'
    AND isses_modifiable = 'FALSE'
    AND TYPE != 4
    ORDER BY 1]';

   TYPE t_vparam_rec IS RECORD (  param_name VARCHAR2(2000)
                                , param_type NUMBER
                                , plsql_type VARCHAR2(2000)
                                , param_value VARCHAR2(2000)
                                , display_value VARCHAR2(2000)
                                , description VARCHAR2(2000)
                                , display_name VARCHAR2(2000)
                                );
   v_rc        sys_refcursor;    
   v_param_rec        t_vparam_rec;    
   
BEGIN

  FOR o IN v_OBJECTS.FIRST .. v_OBJECTS.LAST LOOP
    SELECT count(*)
    INTO v_exists
    FROM all_objects
    WHERE object_name = v_OBJECTS(o);
    
    IF v_exists > 0 THEN
      v_DDL := v_DDL ||' '|| Rpad( v_OBJECTS(o) , 30 )||' CONSTANT BOOLEAN := TRUE;'|| Newline|| Newline;
    ELSE
      v_DDL := v_DDL ||' '|| Rpad( v_OBJECTS(o) , 30 )||' CONSTANT BOOLEAN := FALSE;'|| Newline|| Newline;
    END IF;
  END LOOP;

IF SYS_CONTEXT('USERENV','DB_NAME') like '%p' THEN
      v_DDL := v_DDL ||' is_live CONSTANT BOOLEAN := TRUE;'|| Newline|| Newline;
ELSE
      v_DDL := v_DDL ||' is_live CONSTANT BOOLEAN := FALSE;'|| Newline|| Newline;
END IF;

IF upper(sys_context('USERENV','DB_NAME')) = upper(USER) THEN
      v_DDL := v_DDL ||' is_app_schema CONSTANT BOOLEAN := TRUE;'|| Newline|| Newline;
ELSE
      v_DDL := v_DDL ||' is_app_schema CONSTANT BOOLEAN := FALSE;'|| Newline|| Newline;
END IF;


--NB: need access to v$parameter for this to work

  --v$parameters that cannot be changed without a bounce.
  declare
   e_table_not_exist exception;
	pragma exception_init(e_table_not_exist, -00942);

  BEGIN
  OPEN v_rc FOR v_param_qry;
  LOOP
    FETCH v_rc INTO v_param_rec;
    exit WHEN v_rc%NOTFOUND;

    v_DDL := v_DDL ||Newline||' --'|| Initcap( v_param_rec.param_name ) ||' : '||v_param_rec.description|| Newline;
  
    IF v_param_rec.param_type = 2 THEN --wrap varchar value in quotes
      v_DDL := v_DDL ||' '|| Rpad(  v_param_rec.display_name , 30 )||' CONSTANT '||v_param_rec.plsql_type||' := '''||v_param_rec.param_value||''';';
    ELSE
      v_DDL := v_DDL ||' '|| Rpad(  v_param_rec.display_name , 30 )||' CONSTANT '||v_param_rec.plsql_type||' := '||NVL(v_param_rec.param_value,'NULL')||';';
    END IF;
  
    IF v_param_rec.param_value != v_param_rec.display_value THEN
      v_DDL := v_DDL ||' --'||v_param_rec.display_value;
    END IF;
  
    v_DDL := v_DDL||Newline;

  
  END LOOP;
  
  CLOSE v_rc ;
  EXCEPTIOn
  WHEN e_table_not_exist THEN
  dbms_output.put_line('no access to v$parameter... skipping.');
  END;

  v_DDL := v_DDL||Newline||Last_Line;
  
  --other installed stuff
  
  --EXECUTE IMMEDIATE v_ddl;
  --or  
  --DBMS_DDL.Create_Wrapped(v_ddl);
  
  dbms_output.put_line(DBMS_OBFUSCATION_TOOLKIT.md5 (input => UTL_RAW.cast_to_raw(v_ddl)) );
    
  --DBMS_OUTPUT.PUT_LINE('---');
  --dbms_output.put_line(v_ddl||'#');
   
DECLARE
  l_obj_type VARCHAR2(200);
  l_name VARCHAR2(200);
  l_schema VARCHAR2(200);
  v_Return CLOB;
BEGIN

  l_obj_type := 'PACKAGE';
  l_name := 'DATABASE_CONSTANTS';
  l_schema := NULL;

  
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', FALSE);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', TRUE);
   
  v_Return := DBMS_METADATA.GET_DDL(
    OBJECT_TYPE => l_obj_type,
    NAME => l_name,
    SCHEMA => l_schema,
    VERSION => 'COMPATIBLE',
    MODEL => 'ORACLE',
    TRANSFORM => 'DDL'
  );
  v_Return:= rtrim(ltrim(v_Return,chr(10)||' '),chr(10)||' ');
  dbms_output.put_line(DBMS_OBFUSCATION_TOOLKIT.md5 (input => UTL_RAW.cast_to_raw(v_Return)) );
 --dbms_output.put_line( );
--DBMS_OUTPUT.PUT_LINE('---');
--DBMS_OUTPUT.PUT_LINE(v_Return||'#');
  v_do_apply := DBMS_OBFUSCATION_TOOLKIT.md5 (input => UTL_RAW.cast_to_raw(v_Return)) != DBMS_OBFUSCATION_TOOLKIT.md5 (input => UTL_RAW.cast_to_raw(v_ddl));
EXCEPTION
 WHEN DBMS_METADATA.object_not_found THEN
 v_do_apply := TRUE;
END;
   
IF v_do_apply THEN
DBMS_OUTPUT.PUT_LINE('changing');
  EXECUTE IMMEDIATE v_ddl;
ELSE
DBMS_OUTPUT.PUT_LINE('same.. no change');
END IF;

  

END Maintain_DATABASE_CONSTANTS;
/
--DATABASE_CONSTANTS
set serveroutput on
exec Maintain_DATABASE_CONSTANTS

