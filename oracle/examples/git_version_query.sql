with minmax as (SELECT owner,name, type, min(line)+1 mn, max(line)-1 mx
from DBA_SOURCE
WHERE (text = '/*GITSTART'||CHR(10)
or TEXT = 'GITEND*/'||CHR(10)
)
group by  owner,name, type
)
select *
from (
select US.OWNER,US.name, US.type, REGEXP_SUBSTR(TEXT, '(.*?): +(.?*)',1,1,'',1) TAG_NAME
, regexp_substr(text, '(.*?): +(.?*)',1,1,'',2) tag_value
FROM dba_source us, minmax mnmx
WHERE us.owner = mnmx.owner and us.NAME = mnmx.NAME AND us.TYPE = mnmx.TYPE
and US.LINE between MNMX.MN and MNMX.MX
)
where 1=1
--and US.name = 'SRS2ABW_STUDENTS'
and OWNER = 'DEVELOP'
order by 1,2,3,4
;

SELECT * FROM user_source
WHERE TYPE LIKE '%TYPE%'
order by 1,2,3;

SELECT view_name, regexp_substr(substr(text,1,2000 ), '(.*): (.?*)',1,1,'',1) 
FROM user_views
;

comment on table v_HR_Resource is '/*GITSTART
Git ID   : 74fc10c38ca6cfcd228afb6247c7a3fd03ad5bde
Author   : David Pyke Le Brun < me@example.com >
Date     : 2014-09-29 12:18:07 +0100
Reference:  (HEAD, origin/export_subst, export_subst)
GITEND*/
';

select * FROM user_tab_comments ;

WITH lines AS (SELECT LEVEL l FROM dual CONNECT BY LEVEL <= 5)
SELECT table_name, table_type
, regexp_substr(comments, '(.*): (.?*)',1,l,'',1) ,regexp_substr(comments, '(.*): (.?*)',1,l,'',2) 
FROM dba_tab_comments ,lines
WHERE comments like '%GITSTART%GITEND%' and regexp_substr(comments, '(.*): (.?*)',1,l,'',1) IS NOT NULL
ORDER BY 1,2,3
;
