SET serveroutput ON format wrapped
set timing off

spool mypacktest
DECLARE
  --generate package tester
  CURSOR c_package
  IS
    SELECT
      object_name AS package_name
    FROM
      user_objects
    WHERE
      object_type = 'PACKAGE'
    AND object_name LIKE 'RP/_%' ESCAPE '/'
    AND object_name NOT LIKE 'RP/_RUN%' ESCAPE '/'
    ORDER BY
      object_name;
  CURSOR c_procedures (cp_package_name VARCHAR2)
  IS
    SELECT
      *
    FROM
      user_procedures
    WHERE
      object_name       = cp_package_name
    AND procedure_name IS NOT NULL
    ORDER BY
      subprogram_id;
  CURSOR c_proc_args (cp_package_name VARCHAR2, cp_sp_id NUMBER)
  IS
    SELECT
      *
    FROM
      user_arguments
    WHERE
      package_name    = cp_package_name
    AND subprogram_id = cp_sp_id
    ORDER BY
      SEQUENCE ;
  TYPE myargarray IS   TABLE OF c_proc_args%ROWTYPE;
  arg_array myargarray;

  vcursorname VARCHAR2(32) := '';

BEGIN
--  dbms_output.put_line('var vcursor REFCURSOR');
  dbms_output.put_line('SET serveroutput ON format wrapped');
  FOR v_package_rec IN c_package
  LOOP
    dbms_output.new_line;
    dbms_output.put_line('<<test_'||v_package_rec.package_name||'>>');
    dbms_output.put_line('BEGIN');
    dbms_output.put_line(q'[dbms_output.put_line('starting PACKAGE ]'||v_package_rec.package_name||q'['); ]');

    FOR v_procedures_rec IN c_procedures(v_package_rec.package_name)
    LOOP
vcursorname := NULL;
      dbms_output.put_line('DECLARE');
      dbms_output.put_line('--'||v_procedures_rec.procedure_name);
      OPEN c_proc_args(v_package_rec.package_name,
      v_procedures_rec.subprogram_id);
      LOOP
        FETCH
          c_proc_args BULK COLLECT
        INTO
          arg_array ;
        EXIT
      WHEN c_proc_args%NOTFOUND;
      END LOOP;
      CLOSE c_proc_args;

      FOR i IN arg_array.FIRST .. arg_array.LAST
      LOOP
        IF arg_array(i).argument_name IS NULL THEN

        IF arg_array(i).position = 0 THEN
          --position 0 is return value
          dbms_output.put('  vRETVAL ');
CASE arg_array(i).data_type
        WHEN 'REF CURSOR' THEN
          vcursorname := arg_array(i).argument_name;
          dbms_output.put_line('SYS_REFCURSOR;');
        WHEN 'VARCHAR2' THEN
          dbms_output.put_line('VARCHAR2(2000);');
        WHEN 'DATE' THEN
          dbms_output.put_line(arg_array(i).data_type||';');
        WHEN 'NUMBER' THEN
          dbms_output.put_line(arg_array(i).data_type||';');
        ELSE
          dbms_output.put_line(arg_array(i).data_type ||
          ';--#########');
        END CASE;
        END IF;

        ELSE

        dbms_output.put('   v'||RPAD(arg_array(i).argument_name,30)||' ');
        CASE arg_array(i).data_type
        WHEN 'REF CURSOR' THEN
          vcursorname := arg_array(i).argument_name;
          dbms_output.put_line('SYS_REFCURSOR;');
        WHEN 'VARCHAR2' THEN
          dbms_output.put_line('VARCHAR2(2000);');
        WHEN 'DATE' THEN
          dbms_output.put_line(arg_array(i).data_type||';');
        WHEN 'NUMBER' THEN
          dbms_output.put_line(arg_array(i).data_type||';');
        ELSE
          dbms_output.put_line(arg_array(i).data_type ||
          ';--#########');
        END CASE;
        END IF;
      END LOOP;
if vcursorname IS NOT NULL THEN
      dbms_output.put_line(q'[ 
cnum INTEGER;
rcnt  INTEGER;
x  INTEGER;
]'
      );
END IF;

      dbms_output.put_line('BEGIN');
      dbms_output.put_line(q'[dbms_output.put_line('starting ]'||
      v_procedures_rec.procedure_name||q'['); ]');
      --initialise input vailables
      FOR i IN arg_array.FIRST .. arg_array.LAST
      LOOP
        IF arg_array(i).argument_name IS NOT NULL AND arg_array(i).in_out IN ('IN','IN/OUT') THEN
          dbms_output.put_line('  v'||RPAD(arg_array(i).argument_name,30)||
          ' := NULL;');
        END IF;
      END LOOP;
      dbms_output.new_line;
      IF arg_array(arg_array.FIRST).position = 0 THEN
        dbms_output.put(' vRETVAL:= ');
      END IF;
      dbms_output.put_line('  '||v_package_rec.package_name||'.'||
      v_procedures_rec.procedure_name||'(');
      FOR i IN arg_array.FIRST .. arg_array.LAST
      LOOP
        IF arg_array(i).argument_name IS NOT NULL AND arg_array(i).position   > 0 THEN
          IF arg_array(i).position > 1 THEN
            dbms_output.put('   ,');
          ELSE
            dbms_output.put('    ');
          END IF;
          dbms_output.put_line(arg_array(i).argument_name||' =>  v'||arg_array(i).argument_name );
        END IF;
      END LOOP;
      dbms_output.put_line('  );');

      IF arg_array(arg_array.FIRST).position = 0 THEN
      dbms_output.put_line(q'[dbms_output.put_line('retval='||vRETVAL);]');

      end if;
      --dbms_output.put_line(q'[dbms_output.put_line(vVCURSOR%ROWCOUNT);]');
      --dbms_output.put_line(q'[    :vcursor := vvcursor;]');
IF vcursorname IS NOT NULL THEN
      dbms_output.put_line('cnum := dbms_sql.to_cursor_number(v'||
      vcursorname||q'[);
x:= 0;
loop    
rcnt := dbms_sql.fetch_rows(cnum);    
x := x + rcnt;    
exit WHEN rcnt = 0;
END loop;
dbms_output.put_line('rows='||x); 
dbms_sql.close_cursor(cnum);
]' );
END IF;

      dbms_output.put_line(q'[dbms_output.put_line('finished ]'||
      v_procedures_rec.procedure_name||q'['); ]');

      --dbms_output.put_line('EXCEPTION');
      --dbms_output.put_line('  WHEN OTHERS THEN');
      dbms_output.put_line('END;');
      --dbms_output.put_line('/');
      --dbms_output.new_line;
      --dbms_output.put_line('print vcursor');
      --dbms_output.new_line;
    END LOOP;
    dbms_output.put_line(q'[dbms_output.put_line('finished PACKAGE ]'||
    v_package_rec.package_name||q'['); ]');
    dbms_output.put_line('END;');
    dbms_output.put_line('/');
  END LOOP;
  --dbms_output.put_line(q'[dbms_output.put_line('finished.');]');
END;
/
spool off
