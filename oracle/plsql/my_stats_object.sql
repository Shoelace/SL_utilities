--------------------------------------------------------
--  DDL for Type STATS_OT
--------------------------------------------------------

  CREATE OR REPLACE TYPE STATS_OT AS OBJECT (

     dummy_attribute NUMBER,

     STATIC FUNCTION ODCIGetInterfaces (
                     p_interfaces OUT SYS.ODCIObjectList
                     ) RETURN NUMBER,

/*
STATIC FUNCTION ODCIStatsSelectivity (
                     p_pred_info        IN  SYS.ODCIPredInfo,
                     p_selectivity      OUT NUMBER,
                     p_args             IN  SYS.ODCIArgDescList,
                     p_start            IN  VARCHAR2,
                     p_stop             IN  VARCHAR2,
                      V_BASETYPE_NAME  IN  VARCHAR2,
                       V_ENUM_VALUE IN  VARCHAR2,
                     p_env              IN  SYS.ODCIEnv
                     ) RETURN NUMBER,
*/
STATIC FUNCTION ODCIStatsSelectivity (
                     p_pred_info        IN  SYS.ODCIPredInfo,
                     p_selectivity      OUT NUMBER,
                     p_args             IN  SYS.ODCIArgDescList,
                     p_start            IN  VARCHAR2,
                     P_STOP             IN  VARCHAR2,
                      p_PART_ID  IN  NUMBER,
p_dataversion   IN   NUMBER,
                     P_ENV              IN  SYS.ODCIENV
                     ) RETURN NUMBER,

     STATIC FUNCTION ODCIStatsFunctionCost (
                     p_func_info      IN  SYS.ODCIFuncInfo,
                     p_cost           OUT SYS.ODCICost,
                     p_args           IN  SYS.ODCIArgDescList,
                      V_BASETYPE_NAME  IN  VARCHAR2,
 V_ENUM_VALUE IN  VARCHAR2,
                     p_env            IN  SYS.ODCIEnv
                     ) RETURN NUMBER
  );
/
CREATE OR REPLACE TYPE BODY "REPORTS"."STATS_OT" AS

     STATIC FUNCTION ODCIGetInterfaces (
                     p_interfaces OUT SYS.ODCIObjectList
                     ) RETURN NUMBER IS
     BEGIN
        p_interfaces := SYS.ODCIObjectList(
                           SYS.ODCIObject ('SYS', 'ODCISTATS2')
                           );
        RETURN ODCIConst.success;
     END ODCIGETINTERFACES;
/*
STATIC FUNCTION ODCIStatsSelectivity (
                     p_pred_info        IN  SYS.ODCIPredInfo,
                     p_selectivity      OUT NUMBER,
                     p_args             IN  SYS.ODCIArgDescList,
                     p_start            IN  VARCHAR2,
                     p_stop             IN  VARCHAR2,
                      V_BASETYPE_NAME  IN  VARCHAR2,
 V_ENUM_VALUE IN  VARCHAR2,
                     p_env              IN  SYS.ODCIEnv
                     ) RETURN NUMBER IS
     BEGIN
dbms_output.put_line('generate selectivity for:');
dbms_output.put_line('ObjectSchema:'||p_pred_info.ObjectSchema);
dbms_output.put_line('ObjectName:'||p_pred_info.ObjectName);
DBMS_OUTPUT.PUT_LINE('MethodName:'||p_pred_info.METHODNAME);
DBMS_OUTPUT.PUT_LINE('Flags:'||p_pred_info.FLAGS);

dbms_output.put_line('EnvFlags:'||p_env.EnvFlags);
dbms_output.put_line('CallProperty:'||p_env.CallProperty);
DBMS_OUTPUT.PUT_LINE('DebugLevel:'||P_ENV.DEBUGLEVEL);
DBMS_OUTPUT.PUT_LINE('CursorNum:'||P_ENV.CURSORNUM);

DBMS_OUTPUT.PUT_LINE('p_start:'||p_start);
dbms_output.put_line('p_stop:'||p_stop);
DBMS_OUTPUT.PUT_LINE('V_BASETYPE_NAME:'||V_BASETYPE_NAME);
DBMS_OUTPUT.PUT_LINE('V_ENUM_VALUE:'||V_ENUM_VALUE);

        -- Calculate selectivity of predicate... 
        SELECT (COUNT(CASE
                         WHEN enum_key = p_start
                         THEN 0
                      END) / COUNT(*)) * 100 AS selectivity
        INTO   p_selectivity
        FROM   BASETYPES
;

--p_selectivity := 0;

DBMS_OUTPUT.PUT_LINE('p_selectivity:'||P_SELECTIVITY);

        RETURN ODCIConst.success;
     END ODCISTATSSELECTIVITY;
*/
STATIC FUNCTION ODCIStatsSelectivity (
                     p_pred_info        IN  SYS.ODCIPredInfo,
                     p_selectivity      OUT NUMBER,
                     p_args             IN  SYS.ODCIArgDescList,
                     p_start            IN  VARCHAR2,
                     P_STOP             IN  VARCHAR2,
                      p_PART_ID  IN  NUMBER,
p_dataversion   IN   NUMBER,
                     P_ENV              IN  SYS.ODCIENV
                     ) RETURN NUMBER
IS
BEGIN
dbms_output.put_line('generate selectivity for:');
dbms_output.put_line('ObjectSchema:'||p_pred_info.ObjectSchema);
dbms_output.put_line('ObjectName:'||p_pred_info.ObjectName);
DBMS_OUTPUT.PUT_LINE('MethodName:'||p_pred_info.METHODNAME);
DBMS_OUTPUT.PUT_LINE('Flags:'||p_pred_info.FLAGS);

dbms_output.put_line('EnvFlags:'||p_env.EnvFlags);
dbms_output.put_line('CallProperty:'||p_env.CallProperty);
DBMS_OUTPUT.PUT_LINE('DebugLevel:'||P_ENV.DEBUGLEVEL);
DBMS_OUTPUT.PUT_LINE('CursorNum:'||P_ENV.CURSORNUM);

DBMS_OUTPUT.PUT_LINE('p_start:'||P_START);
dbms_output.put_line('p_stop:'||p_stop);
p_selectivity := 0;

DBMS_OUTPUT.PUT_LINE('p_selectivity:'||P_SELECTIVITY);
END;


STATIC FUNCTION ODCIStatsFunctionCost (
                     p_func_info      IN  SYS.ODCIFuncInfo,
                     p_cost           OUT SYS.ODCICost,
                     p_args           IN  SYS.ODCIArgDescList,
                      V_BASETYPE_NAME  IN  VARCHAR2,
 V_ENUM_VALUE IN  VARCHAR2,
                     p_env            IN  SYS.ODCIEnv
                     ) RETURN NUMBER IS

        aa_io   DBMS_SQL.NUMBER_TABLE;
        aa_ela  DBMS_SQL.NUMBER_TABLE;
        v_dummy VARCHAR2(100);

        FUNCTION snap_io RETURN NUMBER IS
           v_io NUMBER;
        BEGIN
           SELECT SUM(ss.value) INTO v_io
           FROM   v$sesstat ss
           ,      v$statname sn
           WHERE  ss.statistic# = sn.statistic#
           AND    sn.name IN ('db block gets','consistent gets');
           RETURN v_io;
        END snap_io;

     BEGIN
dbms_output.put_line('generate cost for:');
dbms_output.put_line('ObjectSchema:'||p_func_info.ObjectSchema);
dbms_output.put_line('ObjectName:'||p_func_info.ObjectName);
dbms_output.put_line('MethodName:'||p_func_info.MethodName);
dbms_output.put_line('Flags:'||p_func_info.Flags);

dbms_output.put_line('EnvFlags:'||p_env.EnvFlags);
dbms_output.put_line('CallProperty:'||p_env.CallProperty);
dbms_output.put_line('DebugLevel:'||p_env.DebugLevel);
dbms_output.put_line('CursorNum:'||p_env.CursorNum);

DBMS_OUTPUT.PUT_LINE('V_BASETYPE_NAME:'||V_BASETYPE_NAME);
dbms_output.put_line('V_ENUM_VALUE:'||V_ENUM_VALUE);


        p_cost := SYS.ODCICost(NULL, NULL, NULL, NULL);

        /* Snap a sample execution of the function... */
        aa_io(1) := snap_io;
        AA_ELA(1) := DBMS_UTILITY.GET_TIME;
        begin
        v_dummy := case p_func_info.ObjectName
WHEN 'GET_BASETYPE_KEY' THEN GET_BASETYPE_KEY(V_BASETYPE_NAME,V_ENUM_VALUE)
WHEN 'GET_BASETYPE_VALUE' THEN GET_BASETYPE_VALUE(V_BASETYPE_NAME,V_ENUM_VALUE)
END;
EXCEPTION
WHEN NO_DATA_FOUND THEN NULL;
end;
        aa_ela(2) := DBMS_UTILITY.GET_TIME;
        aa_io(2) := snap_io;

        /* Calculate costs from snaps... */
        p_cost.CPUCost := 999* 1000 * DBMS_ODCI.ESTIMATE_CPU_UNITS(
                                    (aa_ela(2) - aa_ela(1)) / 100);
        p_cost.IOCost := aa_io(2) - aa_io(1);
        P_COST.NETWORKCOST := 0;

dbms_output.put_line('COST:('||p_cost.CPUCost||','||p_cost.IOCost||','||p_cost.NETWORKCOST||','||p_cost.IndexCostInfo||')' );
        RETURN ODCIConst.success;
    EXCEPTION
        WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('EXCEPTIOn:'||SQLERRM);
RAISE;
      --  RETURN ODCICONST.ERROR;


     END ODCIStatsFunctionCost;

  END;

/

