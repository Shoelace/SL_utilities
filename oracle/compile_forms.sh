export ORACLE_TERM=vt220
export TERM=vt220
### export NLS_LANG="ENGLISH_UNITED KINGDOM.WE8ISO8859P1"

export INSTANCE_HOME=/software/oracle/product/Middleware/asinst_1

export ORACLE_HOME=/software/oracle/product/Middleware/as_1

USERID=scott/tiger@orcl


for i in `ls *.pll`
do
  echo compiling library $i
  $INSTANCE_HOME/bin/frmcmp_batch.sh Module=$i Userid=${USERID} batch=YES Module_Type=LIBRARY Compile_All=YES
done

for i in `ls *.fmb`
do
  echo compiling form $i
  $INSTANCE_HOME/bin/frmcmp_batch.sh Module=$i Userid=${USERID} batch=YES Module_Type=FORM Compile_All=YES
done

for i in `ls *.mmb`
do
  echo compiling menu $i
  $INSTANCE_HOME/bin/frmcmp_batch.sh Module=$i Userid=${USERID} batch=YES Module_Type=MENU Compile_All=YES
done


grep "Compilation errors have occurred." *.err
