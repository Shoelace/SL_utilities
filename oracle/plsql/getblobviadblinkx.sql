--------------------------------------------------------
--  File created - Thursday-June-18-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function GETBLOBVIADBLINK
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION GETBLOBVIADBLINK
( dblnk in varchar2
  ,tbl  in varchar2
  ,col  in varchar2
  ,rwid in urowid)
return blob
is
L_LOG LOGGER := LOGMANAGER.GETLOGGER();
  RETVAL blob;
  CHKSIZE number :=2000; --db_link raw limit
  tmpraw raw(2000);  
  tmplen number;
  tmpchk number;
begin
  --L_LOG.entry;
  --L_LOG.INFO('CHKSIZE='||CHKSIZE);

  --preset vars
  DBMS_LOB.CREATETEMPORARY (RETVAL,true);
  execute immediate 'select dbms_lob.getlength@'||dblnk||' ('||col||') from '||tbl||'@'||dblnk||' where rowid=:rwid' into tmplen using rwid;

 --L_LOG.INFO('TMPLEN='||TMPLEN);
  
  -- precalc  
  TMPCHK:=FLOOR(TMPLEN/CHKSIZE);
  --L_LOG.info('TMPCHK='||TMPCHK);
  -- applicate frist chunks  
  for I in 0 .. TMPCHK-1
  LOOP  
  --L_LOG.INFO('i='||i);
    execute immediate 'select dbms_lob.substr@'||DBLNK||'('||COL||','||CHKSIZE||','||((I*CHKSIZE)+1)||') from '||TBL||'@'||DBLNK||' where rowid=:rwid' into TMPRAW using RWID;
  --L_LOG.INFO('append');
    DBMS_LOB.append(RETVAL,TMPRAW);
  end LOOP;
  --L_LOG.INFO('next');
  
  -- applicate last entry
  --L_LOG.info('tmplen-(tmpchk*chksize))='||( tmplen-(tmpchk*chksize)) );
  if (TMPLEN-(TMPCHK*CHKSIZE)) > 0 then
  --L_LOG.INFO('get last');
    execute immediate 'select dbms_lob.substr@'||DBLNK||'('||COL||','||(TMPLEN-(TMPCHK*CHKSIZE))||','||((TMPCHK*CHKSIZE)+1)||') from '||TBL||'@'||DBLNK||' where rowid=:rwid' into TMPRAW using RWID;
  --L_LOG.INFO('append last');
    dbms_lob.append(retval,tmpraw);
  end if;
  return retval;
end;

/
