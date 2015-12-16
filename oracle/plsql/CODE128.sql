create or replace FUNCTION Code128(P_INPUT varchar2 CHARACTER SET ANY_CS ) return varchar2  CHARACTER SET P_INPUT%CHARSET
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
 *  2015-11-30: fix checksum in non us charcatersets
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
            dbms_output.put_line('past end');
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
                --dbms_output.put_line('usetableC:'||i||'_'||mini);
            IF usetableC(i,mini) THEN
                IF I=1 THEN
                  --DBMS_OUTPUT.PUT_LINE('start with C_'||TO_CHAR(210,'FM0X'));
                    v_retval := UNISTR('\00'||to_char(210,'FM0X')); --start with tableC  (210)
                ELSE
                  --DBMS_OUTPUT.PUT_LINE('switch to C');
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
        --dbms_output.put_line('dummy:'||DUMMY);
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
--    dbms_output.put_line('checksum:'||chksum||':'||chr(chksum));
    --Add the checksum and the STOP codes
    v_retval := v_retval || UNISTR('\00'||to_char(chksum,'FM0X')) || unistr('\00D3') ;


    return v_retval;
END code128;
/