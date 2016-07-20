export ORACLE_TERM=vt220
export TERM=vt220
### export NLS_LANG="ENGLISH_UNITED KINGDOM.WE8ISO8859P1"

export INSTANCE_HOME=/software/oracle/product/Middleware/asinst_1

export ORACLE_HOME=/software/oracle/product/Middleware/as_1

USERID=scott/tiger@orcl


for i in `ls *.rdf`
do
echo compile report $i
$INSTANCE_HOME/config/reports/bin/rwconverter.sh Userid=${USERID} stype=RDFFILE source=$i dtype=REPFILE  batch=yes OVERWRITE=yes compile_all=yes
done

mv *.rep ../forms90/.
