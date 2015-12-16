CREATE OR REPLACE TYPE typ_varchar255_tab AS TABLE 
     of varchar2 (255);

CREATE OR REPLACE TYPE typ_number_tab AS TABLE 
     of number;

CREATE OR REPLACE TYPE typ_date_tab AS TABLE 
     OF date;

CREATE OR REPLACE TYPE typ_timestamp_tab AS TABLE 
     OF timestamp with time zone;
     
     CREATE OR REPLACE 
     function in_list( p_string in varchar2, p_delimiter varchar2 default ',' ) return typ_varchar255_tab
    as
        l_string        long default p_string || p_delimiter;
        l_data          typ_varchar255_tab := typ_varchar255_tab();
        n               number;
    begin
      loop
          exit when l_string is null;
          n := instr( l_string, p_delimiter );
         l_data.extend;
         l_data(l_data.count) := 
                 ltrim( rtrim( substr( l_string, 1, n-1 ) ) );
         l_string := substr( l_string, n+length(p_delimiter) );
    end loop;

    return l_data;
  END;
  /

CREATE OR REPLACE FUNCTION in_list_pipe(p_list IN VARCHAR2, p_delimiter varchar2 default ',' )
     RETURN typ_varchar255_tab
   PIPELINED
   AS
     l_string       LONG := p_list || p_delimiter;
     l_comma_index  PLS_INTEGER;
     l_index        PLS_INTEGER := 1;
   BEGIN
     LOOP
       l_comma_index := INSTR(l_string, p_delimiter, l_index);
       EXIT WHEN l_comma_index = 0;
       PIPE ROW ( SUBSTR(l_string, l_index, l_comma_index - l_index) );
       l_index := l_comma_index + 1;
     END LOOP;
     RETURN;
   END in_list_pipe;
   /
   


SELECT rownum, to_number(column_value) column_value
from table( in_list( '5 4 3 2 1' ,' ') )
