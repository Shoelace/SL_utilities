--------------------------------------------------------
--  File created - Thursday-June-18-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function PRINT_TABLE_TO_CLOB
--------------------------------------------------------

CREATE OR REPLACE FUNCTION PRINT_TABLE_TO_CLOB ( p_query in varchar2 )  return clob AUTHID CURRENT_USER is
  l_theCursor     integer default dbms_sql.open_cursor;
  l_columnValue   varchar2(4000);
  l_status        INTEGER;
  l_descTbl       dbms_sql.desc_tab3;
  l_colCnt        NUMBER;
  l_separator     VARCHAR2(1);
  l_clob CLOB := '';
begin
  dbms_sql.parse(l_theCursor,p_query,dbms_sql.native);

  dbms_sql.describe_columns3( l_theCursor, l_colCnt, l_descTbl);

  --for i in 1 .. l_colCnt loop
      --dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
  --end loop;
   FOR i IN 1 .. l_colCnt loop
--   DBMS_OUTPUT.PUT_LINE ('col_type:'||l_descTbl(i).col_type);
--   DBMS_OUTPUT.PUT_LINE ('col_name:'||l_descTbl(i).col_name);
--   DBMS_OUTPUT.PUT_LINE ('col_max_len:'||l_descTbl(i).col_max_len);
--   DBMS_OUTPUT.PUT_LINE ('col_name_len:'||l_descTbl(i).col_name_len);
--   DBMS_OUTPUT.PUT_LINE ('col_precision:'||l_descTbl(i).col_precision);
--   DBMS_OUTPUT.PUT_LINE ('col_scale:'||l_descTbl(i).col_scale);
        IF l_descTbl(i).col_type = 2 THEN
          l_clob := l_clob|| l_separator || RPAD(l_descTbl(i).col_name , greatest(l_descTbl(i).col_precision ,l_descTbl(i).col_name_len )) ;
        ELSE
          l_clob := l_clob|| l_separator || RPAD(l_descTbl(i).col_name , greatest(l_descTbl(i).col_max_len ,l_descTbl(i).col_name_len )) ;
        END IF;   
       dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
       l_separator := ' ';
   END loop;
   l_clob := l_clob||chr(10);
   l_separator := '';
   FOR i IN 1 .. l_colCnt loop
        IF l_descTbl(i).col_type = 2 THEN
          l_clob := l_clob|| l_separator || RPAD('-',greatest(l_descTbl(i).col_precision ,l_descTbl(i).col_name_len ),'-') ;
        ELSE
          l_clob := l_clob|| l_separator || RPAD('-',greatest(l_descTbl(i).col_max_len ,l_descTbl(i).col_name_len ),'-') ;
        END IF;   
       dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
       l_separator := ' ';
   END loop;
   l_clob := l_clob||chr(10);


  l_status := dbms_sql.execute(l_theCursor);

  while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
      for i in 1 .. l_colCnt loop

         dbms_sql.column_value( l_theCursor, i, l_columnValue );

            IF l_descTbl(i).col_type = 2 THEN
               l_clob := l_clob|| lpad( NVL(l_columnValue,' ') , greatest(l_descTbl(i).col_precision ,l_descTbl(i).col_name_len ) ) || ' ' ;
            ELSE
               l_clob := l_clob|| rpad( NVL(l_columnValue,' ') , greatest(l_descTbl(i).col_max_len ,l_descTbl(i).col_name_len ) ) || ' ' ;
            END IF;
      END loop;
   l_clob := l_clob||chr(10);
  END loop;
  return l_clob;
exception
  when others then dbms_sql.close_cursor( l_theCursor ); RAISE;
end;
/
