--report outputs

/*
SELECT   *    
FROM  agr56.ACRREPFILE INNER JOIN agr56.acrprintblob USING (blob_id)
WHERE 1=1
--and report_name = 'ADDR7'
and orderno = 265
--;
*/

set serveroutput on

DECLARE

daysback INTERVAL DAY TO SECOND := INTERVAL '1' DAY;

c CLOB;
re VARCHAR2(255);

function BlobToClob( b blob ) return clob is
          c               clob;
          srcOffset       number := 1;
          dstOffset       number := 1;
          warning         number;
          langContext     number := DBMS_LOB.default_lang_ctx;
  begin
          DBMS_LOB.CreateTemporary( c, true );
  
          DBMS_LOB.ConvertToClob(
                  dest_lob => c,
                  src_blob => b,
                  amount => DBMS_LOB.GetLength(b),
                  dest_offset => dstOffset,
                  src_offset => srcOffset,
                  blob_csid => DBMS_LOB.default_csid,
                  lang_context => langContext,
                  warning => warning
          );
  
          return( c );
  end;

begin

--
-- use this query to choose your intended reports.
--

FOR x IN (SELECT report_name, orderno, o.description
--,CAST(decode(date_ended, to_date('01/01/1900','DD/MM/YYYY'),SYSTIMESTAMP,date_ended) AS TIMESTAMP)-date_started elapsed
          FROM agr56.acrrepord o 
          WHERE 1=1
          AND o.date_ended BETWEEN SYSDATE - daysback AND SYSDATE +1 -daysback
          AND o.user_id = 'ESBAGRBTCH'
          --AND report_name = 'GL07'
          --and orderno = 17950
          --and rownum < 10
          ORDER BY o.order_date DESC, date_started desc) LOOP

dbms_output.new_line;
--dbms_output.put_line(x.report_name||'-'||x.description||'-'||x.orderno);
dbms_output.put_line(x.report_name||'-'||x.orderno||' : '||x.description);






FOR z IN (SELECT * -- f.description y, f.sequence_no, f.TYPE,blob_id , blob_image
          FROM agr56.ACRREPFILE f 
          INNER JOIN agr56.acrprintblob b USING (blob_id)
          WHERE f.TYPE ='A'
          AND f.report_name = x.report_name
          AND f.orderno =  x.orderno
          ) LOOP

c := BlobToClob(z.blob_image);
CASE 
WHEN x.report_name = 'CS15' THEN
NULL;
--into asuheader
--dbms_output.put_line();
--re := '^.*\((CS150020|CS150030).*\)*$';
re := '(AP/AR type.*$)|(\[.*\((CS15_INT0030|CS15_INT0050).*\)*$)';


FOR A IN 1 .. nvl(regexp_count(c,re,1,'im'),0) LOOP
dbms_output.put_line(regexp_substr(c,re,1,a,'im'));
END LOOP;

WHEN x.report_name = 'PR43' THEN
NULL;
re := '\[.*\((PR43_INS0010|PR43_UPD0135).*\)*$';


FOR A IN 1 .. nvl(regexp_count(c,re,1,'im'),0) LOOP
dbms_output.put_line(regexp_substr(c,re,1,a,'im'));
END LOOP;



WHEN x.report_name = 'GL07' THEN
NULL;
--01:00:39 [   30] insert GL transactions (GL07_PST0010)
--01:00:39 [   10] INSERT AR transactions (GL07_PST0020)
--01:00:39 [    0] insert AP transactions (GL07_PST0030)
re := '(BatchID.*$)|(\[.*\((GL07_PST0010|GL07_PST0020|GL07_PST0030).*\)*$)';


FOR A IN 1 .. nvl(regexp_count(c,re,1,'im'),0) LOOP
dbms_output.put_line(regexp_substr(c,re,1,A,'im'));
END LOOP;

WHEN x.report_name IN  ('ATTR7' , 'ADDR7', 'RELA7','HREL7','FLEX') THEN
NULL;
re := '(Batch Key.*$)|([0-9]* line\(s\) processed.*$)';

FOR A IN 1 .. nvl(regexp_count(c,re,1,'im'),0) LOOP
dbms_output.put_line(regexp_substr(c,re,1,A,'im'));
END LOOP;

ELSE
dbms_output.put_line(x.report_name);
END CASE;

--cleanup blob
IF dbms_lob.istemporary(c) = 1 THEN
dbms_lob.freetemporary(c);
END IF;

NULL;
END LOOP;


IF x.report_name = 'GL07' THEN
FOR z IN (SELECT * -- f.description y, f.sequence_no, f.TYPE,blob_id , blob_image
          FROM agr56.ACRREPFILE f 
          INNER JOIN agr56.acrprintblob b USING (blob_id)
          WHERE f.TYPE ='R'
          AND f.report_name = x.report_name
          AND f.orderno =  x.orderno
          ) LOOP

c := BlobToClob(z.blob_image);

--into asuheader
--dbms_output.put_line();
--re := '^.*\((CS150020|CS150030).*\)*$';
re := 'TOT.*$|.*ERROR.*$|.*Error log.*|.*\*\*\*\*\*\*\*\*.*';


FOR A IN 1 .. nvl(regexp_count(c,re,1,'m'),0) LOOP
dbms_output.put_line(regexp_substr(c,re,1,A,'m'));
END LOOP;
END LOOP;
END IF;

END LOOP;

/*
FOR x IN (SELECT report_name, orderno, o.description x, f.description y, f.sequence_no, f.TYPE,blob_id 
          FROM AGR56.ACRREPFILE f 
          INNER JOIN agr56.acrrepord o USING (report_name, orderno)
          INNER JOIN agr56.acrprintblob b USING (blob_id)
          WHERE o.date_ended > SYSDATE -1
          AND o.user_id = 'ESBAGRBTCH'
          and f.type ='A'
          ORDER BY o.date_ended DESC) LOOP

dbms_output.put_line(x.report_name||'-'||x.x||'-'||x.orderno);
--dbms_output.put_line(x.orderno);

FOR z IN (SELECT report_name, orderno, o.description x, f.description y, f.sequence_no, f.TYPE,blob_id 
          FROM AGR56.ACRREPFILE f 
          INNER JOIN agr56.acrrepord o USING (report_name, orderno)
          INNER JOIN agr56.acrprintblob b USING (blob_id)
          WHERE o.date_ended > SYSDATE -1
          AND o.user_id = 'ESBAGRBTCH'
          and f.type ='A'
          ORDER BY o.date_ended DESC
          ) LOOP

c := BlobToClob(z.blob_image);
dbms_output.put_line(regexp_substr(c,'^.*line\(s\) processed.*$',1,1,'im'));
END LOOP;
END LOOP;
*/

END;
/
