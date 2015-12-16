--------------------------------------------------------
--  File created - Thursday-June-18-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function BLOBTOCLOB
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION BLOBTOCLOB ( b blob ) return clob is
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
  

/
