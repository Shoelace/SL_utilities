select * from user_objects;
select * from user_objects_ae;

SELECT * FROM dba_USERS
where editions_enabled = 'Y';

SELECT * FROM all_EDITIONS;

SELECT SYS_CONTEXT('USERENV', 'CURRENT_EDITION_NAME') , SYS_CONTEXT('USERENV', 'SESSION_EDITION_NAME') FROM DUAL;


sys.UTL_RECOMP 

ALTER USER log4 ENABLE EDITIONS ;

CREATE EDITION log4_2;
drop EDITION log4_2;

alter session set edition = ora$base;