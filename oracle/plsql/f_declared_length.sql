create or replace function f_declared_length (
     p in out varchar2
   )
     return integer
   is
     r integer;
     a varchar2(32767) := p;
     function f_c ( p in out char ) return integer is
     begin
       return length(p);
     end;
   begin
     p := 1;
     r := f_c(p);
     p := a;
     return r;
   end;
/
