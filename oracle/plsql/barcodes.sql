
create or replace package barcode
as

FUNCTION Code128(P_INPUT varchar2 CHARACTER SET ANY_CS ) return varchar2  CHARACTER SET P_INPUT%CHARSET DETERMINISTIC;

function code128_to_svg(p_code varchar2) return varchar2;

function code128_svg(p_code number) return varchar2;
function code128_svg(p_1 number,p_2 number,p_3 number,p_4 number,p_5 number,p_6 number,p_7 number default NULL) return varchar2;

end;
/

create or replace package body barcode
AS

FUNCTION INTE(X NUMBER, T VARCHAR2, E VARCHAR2) RETURN VARCHAR2
is
BEGIN
IF X IS NULL THEN RETURN T; END IF;
RETURN E;
end;
function code128_to_svg(p_code varchar2) return varchar2
IS
V_OFFSET NUMBER := 0;
V_X VARCHAR2(32000);
V_svg VARCHAR2(32000);
v_id number;
BEGIN

V_svg := '<use xlink:href="#quiet_zone" x="'||V_OFFSET||'" y="0" />';
V_OFFSET := V_OFFSET +10;

DBMS_OUTPUT.PUT_LINE( '<defs>');
FOR I IN 1 .. LENGTH(P_CODE) LOOP
if ascii(substr(p_code,i,1)) < 128 THEN
--DBMS_OUTPUT.PUT_LINE( ASCII(SUBSTR(P_CODE,I,1)));
v_id := ASCII(SUBSTR(P_CODE,I,1)) -32;
ELSE
--DBMS_OUTPUT.PUT_LINE('unistr='|| ASCIISTR(SUBSTR(P_CODE,I,1)));
--DBMS_OUTPUT.PUT_LINE(TO_NUMBER(SUBSTR(ASCIISTR(SUBSTR(P_CODE,I,1)),2),'XXXX'));
--DBMS_OUTPUT.PUT_LINE( V_X);
v_id :=  to_number(substr(ASCIIstr(SUBSTR(P_CODE,I,1)),2),'XXXX')-105 ;
end if;
V_X := CODE128_SVG( V_ID );
DBMS_OUTPUT.PUT_LINE( '<g id="code'||v_id||'">');
DBMS_OUTPUT.PUT_LINE( V_X);
DBMS_OUTPUT.PUT_LINE( '</g>');

V_svg := V_svg ||'<use xlink:href="#code'||V_ID||'" x="'||V_OFFSET||'" y="0" />';
v_offset := v_offset +11;



END LOOP;
V_SVG := V_SVG ||'<use xlink:href="#quiet_zone" x="'||V_OFFSET||'" y="0" />';
DBMS_OUTPUT.PUT_LINE( '</defs>');
--DBMS_OUTPUT.PUT_LINE( '<svg >');
DBMS_OUTPUT.PUT_LINE( V_SVG);
DBMS_OUTPUT.PUT_LINE( '</svg>');
return '';

end;




FUNCTION CODE128_SVG(P_code number) RETURN VARCHAR2
IS

BEGIN

RETURN CASE P_CODE
WHEN 0 THEN code128_svg(2,1,2,2,2,2)
WHEN 1 THEN code128_svg(2,2,2,1,2,2)
WHEN 2 THEN code128_svg(2,2,2,2,2,1)
WHEN 3 THEN code128_svg(1,2,1,2,2,3)
WHEN 4 THEN code128_svg(1,2,1,3,2,2)
WHEN 5 THEN code128_svg(1,3,1,2,2,2)
WHEN 6 THEN code128_svg(1,2,2,2,1,3)
WHEN 7 THEN code128_svg(1,2,2,3,1,2)
WHEN 8 THEN code128_svg(1,3,2,2,1,2)
WHEN 9 THEN code128_svg(2,2,1,2,1,3)
WHEN 10 THEN code128_svg(2,2,1,3,1,2)
WHEN 11 THEN code128_svg(2,3,1,2,1,2)
WHEN 12 THEN code128_svg(1,1,2,2,3,2)
WHEN 13 THEN code128_svg(1,2,2,1,3,2)
WHEN 14 THEN code128_svg(1,2,2,2,3,1)
WHEN 15 THEN code128_svg(1,1,3,2,2,2)
WHEN 16 THEN code128_svg(1,2,3,1,2,2)
WHEN 17 THEN code128_svg(1,2,3,2,2,1)
WHEN 18 THEN code128_svg(2,2,3,2,1,1)
WHEN 19 THEN code128_svg(2,2,1,1,3,2)
WHEN 20 THEN code128_svg(2,2,1,2,3,1)
WHEN 21 THEN code128_svg(2,1,3,2,1,2)
WHEN 22 THEN code128_svg(2,2,3,1,1,2)
WHEN 23 THEN code128_svg(3,1,2,1,3,1)
WHEN 24 THEN code128_svg(3,1,1,2,2,2)
WHEN 25 THEN code128_svg(3,2,1,1,2,2)
WHEN 26 THEN code128_svg(3,2,1,2,2,1)
WHEN 27 THEN code128_svg(3,1,2,2,1,2)
WHEN 28 THEN code128_svg(3,2,2,1,1,2)
WHEN 29 THEN code128_svg(3,2,2,2,1,1)
WHEN 30 THEN code128_svg(2,1,2,1,2,3)
WHEN 31 THEN code128_svg(2,1,2,3,2,1)
WHEN 32 THEN code128_svg(2,3,2,1,2,1)
WHEN 33 THEN code128_svg(1,1,1,3,2,3)
WHEN 34 THEN code128_svg(1,3,1,1,2,3)
WHEN 35 THEN code128_svg(1,3,1,3,2,1)
WHEN 36 THEN code128_svg(1,1,2,3,1,3)
WHEN 37 THEN code128_svg(1,3,2,1,1,3)
WHEN 38 THEN code128_svg(1,3,2,3,1,1)
WHEN 39 THEN code128_svg(2,1,1,3,1,3)
WHEN 40 THEN code128_svg(2,3,1,1,1,3)
WHEN 41 THEN code128_svg(2,3,1,3,1,1)
WHEN 42 THEN code128_svg(1,1,2,1,3,3)
WHEN 43 THEN code128_svg(1,1,2,3,3,1)
WHEN 44 THEN code128_svg(1,3,2,1,3,1)
WHEN 45 THEN code128_svg(1,1,3,1,2,3)
WHEN 46 THEN code128_svg(1,1,3,3,2,1)
WHEN 47 THEN code128_svg(1,3,3,1,2,1)
WHEN 48 THEN code128_svg(3,1,3,1,2,1)
WHEN 49 THEN code128_svg(2,1,1,3,3,1)
WHEN 50 THEN code128_svg(2,3,1,1,3,1)
WHEN 51 THEN code128_svg(2,1,3,1,1,3)
WHEN 52 THEN code128_svg(2,1,3,3,1,1)
WHEN 53 THEN code128_svg(2,1,3,1,3,1)
WHEN 54 THEN code128_svg(3,1,1,1,2,3)
WHEN 55 THEN code128_svg(3,1,1,3,2,1)
WHEN 56 THEN code128_svg(3,3,1,1,2,1)
WHEN 57 THEN code128_svg(3,1,2,1,1,3)
WHEN 58 THEN code128_svg(3,1,2,3,1,1)
WHEN 59 THEN code128_svg(3,3,2,1,1,1)
WHEN 60 THEN code128_svg(3,1,4,1,1,1)
WHEN 61 THEN code128_svg(2,2,1,4,1,1)
WHEN 62 THEN code128_svg(4,3,1,1,1,1)
WHEN 63 THEN code128_svg(1,1,1,2,2,4)
WHEN 64 THEN code128_svg(1,1,1,4,2,2)
WHEN 65 THEN code128_svg(1,2,1,1,2,4)
WHEN 66 THEN code128_svg(1,2,1,4,2,1)
WHEN 67 THEN code128_svg(1,4,1,1,2,2)
WHEN 68 THEN code128_svg(1,4,1,2,2,1)
WHEN 69 THEN code128_svg(1,1,2,2,1,4)
WHEN 70 THEN code128_svg(1,1,2,4,1,2)
WHEN 71 THEN code128_svg(1,2,2,1,1,4)
WHEN 72 THEN code128_svg(1,2,2,4,1,1)
WHEN 73 THEN code128_svg(1,4,2,1,1,2)
WHEN 74 THEN code128_svg(1,4,2,2,1,1)
WHEN 75 THEN code128_svg(2,4,1,2,1,1)
WHEN 76 THEN code128_svg(2,2,1,1,1,4)
WHEN 77 THEN code128_svg(4,1,3,1,1,1)
WHEN 78 THEN code128_svg(2,4,1,1,1,2)
WHEN 79 THEN code128_svg(1,3,4,1,1,1)
WHEN 80 THEN code128_svg(1,1,1,2,4,2)
WHEN 81 THEN code128_svg(1,2,1,1,4,2)
WHEN 82 THEN code128_svg(1,2,1,2,4,1)
WHEN 83 THEN code128_svg(1,1,4,2,1,2)
WHEN 84 THEN code128_svg(1,2,4,1,1,2)
WHEN 85 THEN code128_svg(1,2,4,2,1,1)
WHEN 86 THEN code128_svg(4,1,1,2,1,2)
WHEN 87 THEN code128_svg(4,2,1,1,1,2)
WHEN 88 THEN code128_svg(4,2,1,2,1,1)
WHEN 89 THEN code128_svg(2,1,2,1,4,1)
WHEN 90 THEN code128_svg(2,1,4,1,2,1)
WHEN 91 THEN code128_svg(4,1,2,1,2,1)
WHEN 92 THEN code128_svg(1,1,1,1,4,3)
WHEN 93 THEN code128_svg(1,1,1,3,4,1)
WHEN 94 THEN code128_svg(1,3,1,1,4,1)
WHEN 95 THEN code128_svg(1,1,4,1,1,3)
WHEN 96 THEN code128_svg(1,1,4,3,1,1)
WHEN 97 THEN code128_svg(4,1,1,1,1,3)
WHEN 98 THEN code128_svg(4,1,1,3,1,1)
WHEN 99 THEN code128_svg(1,1,3,1,4,1)
WHEN 100 THEN code128_svg(1,1,4,1,3,1)
WHEN 101 THEN code128_svg(3,1,1,1,4,1)
WHEN 102 THEN code128_svg(4,1,1,1,3,1)
WHEN 103 THEN code128_svg(2,1,1,4,1,2)
WHEN 104 THEN code128_svg(2,1,1,2,1,4)
WHEN 105 THEN CODE128_SVG(2,1,1,2,3,2)
WHEN 106 THEN CODE128_SVG(2,3,3,1,1,1,2)
end ;

END;

FUNCTION CODE128_SVG(P_1 NUMBER,P_2 NUMBER,P_3 NUMBER,P_4 NUMBER,P_5 NUMBER,P_6 NUMBER,P_7 NUMBER DEFAULT NULL) RETURN VARCHAR2
IS
V_RETVAL VARCHAR2(32000);
BEGIN

RETURN '<rect x="0" y="0" width="'||P_1||'" height="100" />'||CHR(10)
||'<rect x="'||(P_1 + P_2)||'" y="0" width="'||P_3||'" height="100" />'||CHR(10)
||'<rect x="'||(p_1 + P_2 + p_3 + P_4)||'" y="0" width="'||P_5||'" height="100" />'||CHR(10)||INTE(P_7,NULL,'<rect x="11" y="0" width="'||P_7||'" height="100" />');


END;



FUNCTION Code128(P_INPUT varchar2 CHARACTER SET ANY_CS ) return varchar2  CHARACTER SET P_INPUT%CHARSET
DETERMINISTIC 
IS
/*
 *  This function is governed by the GNU Lesser General Public License (GNU LGPL)
 *  Parameters : a string
 *  Return : * a string which give the bar code when it is dispayed with CODE128.TTF font
 *           * an empty string if the supplied parameter is no good
 *
 * the CODE128.TTF font can be source from http://sourceforge.net/projects/openbarcodes
 *
 * written by David Pyke (eselle@sourceforge.net)
 * based on code found at http://grandzebu.net/informatique/codbar-en/codbar.htm
 *                        http://sourceforge.net/projects/openbarcodes
 *
 *  2015-03-11: fixed character set issue. not exhaustivly tested
 *  2015-11-03: started modifed to work with non ascii NLS_CHARACTERSET  (tested with AR8MSWIN1256 )
*/
    i   NUMBER;
    chksum  NUMBER;
    mini    NUMBER;
    dummy   NUMBER;
    tableB  BOOLEAN;
    c_pinput_length constant NUMBER := LENGTH(p_input);
    v_retval NVARCHAR2(4000);
	  
    FUNCTION usetableC(p_start NUMBER, p_cnt NUMBER)
    RETURN BOOLEAN
    IS
        -- Determine if the p_cnt characters from p_start are numeric
    BEGIN
        FOR x in p_start .. p_start+p_cnt-1 LOOP

            IF(x > c_pinput_length ) THEN
            DBMS_OUTPUT.PUT_LINE('past end');
                RETURN FALSE;
            END IF;
            IF ascii(substr(p_input,x,1)) <48 OR ascii(substr(p_input,x,1)) >57 THEN
            dbms_output.put_line(x||':not digit:'||substr(p_input,x,1));
                RETURN FALSE;
            END IF;
        END LOOP;
        RETURN TRUE;
    END usetableC;
BEGIN
    IF c_pinput_length = 0 THEN
        RETURN NULL;
    END IF;
    --Check for valid characters
    --for c in 1..length(p_input) loop
        -- if not 21 -> 126 or 203.. return null
    --END LOOP;\
    tableB := true;
    i := 1;
    FOR c IN 1..c_pinput_length LOOP
      EXIT when I >c_pinput_length;
        IF tableB THEN
            IF i =1 or (i+3) =length(p_input) THEN
                mini := 4;
            ELSE
                mini := 6;
            END IF;
                dbms_output.put_line('usetableC:'||i||'_'||mini);
            IF usetableC(i,mini) THEN
                IF I=1 THEN
                  DBMS_OUTPUT.PUT_LINE('start with C_'||TO_CHAR(210,'FM0X'));
                    v_retval := UNISTR('\00'||to_char(210,'FM0X')); --start with tableC  (210)
                ELSE
                  DBMS_OUTPUT.PUT_LINE('switch to C');
                    v_retval := v_retval||UNISTR('\00'||to_char(204,'FM0X')); --switch to tabelC (204)
                END IF;
                tableB := FALSE;
            ELSE
                 IF I = 1 THEN 
                    v_retval := UNISTR('\00'||to_char(209,'FM0X')); --00d1 = 209

					END IF; --Starting with table B
            END IF;
        END IF;
        IF NOT tableB THEN

            --We are on table C, try to process 2 digits
            mini := 2;
            if usetableC(I,MINI) THEN
                dummy := TO_NUMBER(SUBSTR(p_input, i, 2));
                IF(dummy < 95) THEN
                    dummy := dummy +32;
                ELSE
                    dummy := dummy +105;
                END IF;
                v_retval := v_retval || UNISTR('\00'||to_char(dummy,'FM0X'));
                

                 i := i + 2;
            ELSE
                v_retval := v_retval || UNISTR('\00'||to_char(205,'FM0X'));
                tableB := TRUE; 
            END IF;
        END IF;
        IF tableB THEN
		--Process 1 digit with table B
            v_retval := v_retval || nvl(SUBSTR(p_input, i, 1),'#');
            i := i +1;
        END IF;
    END loop;
    
    --Calculation of the checksum
    FOR i IN 1 .. LENGTH(v_retval) LOOP
        DUMMY := ASCII(SUBSTR(V_RETVAL,I,1));
        dbms_output.put_line('dummy:'||DUMMY);
        IF(dummy < 127) THEN
            dummy := dummy -32;
        ELSE
            dummy := dummy -105;
        END IF;
        IF i =1 then chksum := dummy;  END IF;

        chksum :=MOD(chksum + (i-1)*dummy, 103);
    END LOOP;


    -- Calculation of the checksum ASCII code
    IF chksum <95 THEN
        chksum := chksum +32;
    ELSE
        chksum := chksum +105;
    END IF;
    dbms_output.put_line('checksum:'||chksum||':'||chr(chksum));
    --Add the checksum and the STOP codes
    v_retval := v_retval || UNISTR('\00'||to_char(chksum,'FM0X')) || unistr('\00D3') ;
    
    
    return v_retval;
END code128;

end;
/


