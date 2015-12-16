--modified version from Tom Kyte.
--see also log4oracle

--depth based version
create or replace procedure who_called_me( owner      out varchar2,
                        name       out varchar2,
                        lineno     OUT number,
                        caller_t   OUT varchar2 ,
                        depth number default 1)
AUTHID DEFINER
as
   call_stack  varchar2(4096) default dbms_utility.format_call_stack;
   n           number;
   found_stack BOOLEAN default FALSE;
   line        varchar2(255);
   cnt         number := 0;
begin
--dbms_output.put_line(call_stack);
--
   loop
       n := instr( call_stack, chr(10) );
       exit when ( n is NULL or n = 0 );
--
       line := substr( call_stack, 1, n-1 );
       call_stack := substr( call_stack, n+1 );
--
       if ( NOT found_stack ) then
           if ( line like '%handle%number%name%' ) then
               found_stack := TRUE;
           end if;
       else
           cnt := cnt + 1;
           -- cnt = 1 is ME
           -- cnt = 2 is MY Caller
           -- cnt = 3 is Their Caller
           if ( cnt = (2+depth) ) then
--dbms_output.put_line('         1         2         3');
--dbms_output.put_line('123456789012345678901234567890');
--dbms_output.put_line(line);
				--format '0x70165ba0       104  package body S06DP3.LOGMANAGER'
--dbms_output.put_line('substr:'||substr( line, 14, 8 ));
               lineno := to_number(substr( line, 14, 8 ));
               line   := substr( line, 23 ); --set to rest of line .. change from 21 to 23
               if ( line like 'pr%' ) then
                   n := length( 'procedure ' );
               elsif ( line like 'fun%' ) then
                   n := length( 'function ' );
               elsif ( line like 'package body%' ) then
                   n := length( 'package body ' );
               elsif ( line like 'pack%' ) then
                   n := length( 'package ' );
               elsif ( line like 'anonymous%' ) then
                   n := length( 'anonymous block ' );
               else
                   n := null;
               end if;
               if ( n is not null ) then
                  caller_t := ltrim(rtrim(upper(substr( line, 1, n-1 ))));
               else
                  caller_t := 'TRIGGER';
               end if;

               line := substr( line, nvl(n,1) );
               n := instr( line, '.' );
               owner := ltrim(rtrim(substr( line, 1, n-1 )));
               name  := LTRIM(RTRIM(SUBSTR( LINE, N+1 )));
               exit;
           end if;
       end if;
   end loop;
end;
/

