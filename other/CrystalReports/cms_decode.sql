CREATE OR REPLACE FUNCTION CMS_DECODE(P_CODED VARCHAR2)
RETURN VARCHAR2
AUTHID DEFINER
DETERMINISTIC
PARALLEL_ENABLE
IS
V_RETVAL VARCHAR2(32000);
V_UNCODED_LENGTH NUMBER;
v_remaining varchar2(32000);

FUNCTION DECODE_CHAR(LP_X IN OUT NOCOPY VARCHAR2 )
RETURN VARCHAR2
IS
v_retval varchar2(32000);
v_consume number :=1;
v_cnt number :=0;
BEGIN

case
  when instr(')+-/13579;=?ACEGIKMOQSUWY]',SUBSTR(LP_X,1,1)) >0 then
--      V_RETVAL :=  TRANSLATE(SUBSTR(LP_X,1,1) ,')+-/13579;=?ACEGIKMOQSUWY]',
--                                              'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
V_RETVAL := chr((ascii(SUBSTR(LP_X,1,1))-41)/2+ 65);

WHEN SUBSTR(LP_X,1,3) = '!`|' THEN  
V_RETVAL := (ascii(SUBSTR(LP_X,4,1))-60)/2;
 v_consume :=4;

WHEN SUBSTR(LP_X,1,4) = '!A|N' THEN  
V_RETVAL := '_'; v_consume :=4;
WHEN SUBSTR(LP_X,1,4) = '!A|Z' THEN  
V_RETVAL := '-'; v_consume :=4;

WHEN SUBSTR(LP_X,1,3) = '!B|' THEN  
V_RETVAL := CHR((ascii(SUBSTR(LP_X,4,1))-66)/2 +40);
 v_consume :=4;

WHEN SUBSTR(LP_X,1,3) = '!@E' THEN  
V_RETVAL := '_'; v_consume :=3;

WHEN SUBSTR(LP_X,1,3) = '!BE' THEN  
  loop
DBMS_OUTPUT.PUT_LINE('BE loop');
    V_RETVAL := V_RETVAL||'.'; 
    v_consume := 2+ v_consume ;
DBMS_OUTPUT.PUT_LINE('next:'||SUBSTR(LP_X,v_consume+1,2));

    exit when SUBSTR(LP_X,v_consume+1,2) != 'BE' oR  SUBSTR(LP_X,v_consume+1,1) is null;
  end loop;
    v_consume := 2+ v_consume ;


WHEN SUBSTR(LP_X,1,2) = '!@' THEN  
  loop
    V_RETVAL := V_RETVAL||' '; 
    v_consume := 1+ v_consume ;
    exit when SUBSTR(LP_X,v_consume+1,1) != '@' oR  SUBSTR(LP_X,v_consume+1,1) is null;
  end loop;
    v_consume := 1+ v_consume ;



WHEN SUBSTR(LP_X,1,4) = '!E}P' THEN  
V_RETVAL := '<'; v_consume :=4;
WHEN SUBSTR(LP_X,1,4) = '!E}T' THEN  
V_RETVAL := '>'; v_consume :=4;

WHEN SUBSTR(LP_X,1,2) = '!' THEN  
null;

else v_retval:='?';
END case;

LP_X := SUBSTR(LP_X,v_consume+1);

return v_retval;
end;

BEGIN
--INSTR(P_CODED,';', -1) 
v_remaining :=SUBSTR(P_CODED,INSTR(P_CODED,';', -1)+1);
DBMS_OUTPUT.PUT_LINE('lastchar:'||v_remaining );

V_UNCODED_LENGTH := ASCII(SUBSTR(v_remaining,-1,1) ) -62 ;

DBMS_OUTPUT.PUT_LINE('V_UNCODED_LENGTH:'||V_UNCODED_LENGTH );


v_remaining := substr(P_CODED, 1, INSTR(P_CODED,';', -1)-1);
DBMS_OUTPUT.PUT_LINE('v_remaining:'||v_remaining);

while v_remaining IS NOT NULL LOOP
v_retval := v_retval || DECODE_CHAR(v_remaining);
END LOOP;


RETURN v_retval;

exception
when others then
DBMS_OUTPUT.PUT_LINE('ERROR'||P_CODED);
RAISE;
end;
