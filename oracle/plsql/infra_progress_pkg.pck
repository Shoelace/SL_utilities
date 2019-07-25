CREATE OR REPLACE PACKAGE infra_progress_pkg AS

  /** Infrastrucure package to simplify calls to session_long_ops
  * and other session progress functions.
  *
  * example usage:
  *<pre>
  * clear screen
  * set serveroutput on size 1000000
  * set serveroutput on size unlimited
  * begin
  * infra_progress_pkg.stop_p('EX970');
  * infra_progress_pkg.start_p('EX970', p_totalwork => 12345, p_target_desc =>'Testing', p_units =>'testunits');
  * infra_progress_pkg.step_p('EX970');
  * infra_progress_pkg.step_p('EX970', p_stepsize => 4);
  * infra_progress_pkg.step_p('EX970', p_stepsize => 4);
  * infra_progress_pkg.step_p('EX970', p_stepsize => 4);dbms_lock.sleep(5);
  * infra_progress_pkg.step_p('EX970', p_stepsize => 4);
  *
  * infra_progress_pkg.step_p('EX970');
  * infra_progress_pkg.step_p('EX970');
  * infra_progress_pkg.stop_p('EX970');
  * end;
  *</pre>
  * @headcom
  */

  /** subtype for longop name. allow many to be created per session */
  SUBTYPE longop_name_t IS VARCHAR2(255);

  /** plsql type referencing fields used in calls to dbms_application_info.set_session_longops  (plus a name) */
  TYPE longop_rec IS RECORD (
    longop_name VARCHAR2(100) DEFAULT 'DEFAULT_LONGOP',
    rindex      BINARY_INTEGER := dbms_application_info.set_session_longops_nohint,
    slno        BINARY_INTEGER := NULL,
    op_name     VARCHAR2(64 BYTE),
    target      BINARY_INTEGER := 0, -- table id?
    context     BINARY_INTEGER := 0,
    sofar       NUMBER := 0,
    totalwork   NUMBER := 0,
    target_desc VARCHAR2(32 BYTE) := 'TABLENAME',
    units       VARCHAR2(32 BYTE) := 'ROWNAME'
  );

    /** Associative array of timers   */
  TYPE longop_tab IS TABLE OF longop_rec INDEX BY longop_name_t;

  /** start a longops timer.
   *    @param pti_name        longop_name_t default 'DEFAULT_LONGOP'
   *    @param p_opname        varchar2 default null
   *    @param p_target        pls_integer default 0
   *    @param p_context       pls_integer default 0
   *    @param p_totalwork     pls_integer default 0
   *    @param p_target_desc   varchar2 default 'unknown target'
   *    @param p_units         varchar2 default null
   */
  PROCEDURE start_p (
    pti_name          IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pci_opname        IN VARCHAR2 DEFAULT NULL,
    pni_target        IN PLS_INTEGER DEFAULT 0,
    pni_context       IN PLS_INTEGER DEFAULT 0,
    pni_totalwork     IN PLS_INTEGER DEFAULT 0,
    pci_target_desc   IN VARCHAR2 DEFAULT 'unknown target',
    pci_units         IN VARCHAR2 DEFAULT NULL
  );

  /**
   *  move the longs entry ahead by p_stepsize. (default 1)
   *  @param pti_name     longop_name_t default 'DEFAULT_LONGOP'
   *  @param p_stepsize   pls_integer default 1
   *  @param p_context    pls_integer default 0
   */
  PROCEDURE step_p (
    pti_name       IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pni_stepsize   IN PLS_INTEGER DEFAULT 1,
    pni_context    IN PLS_INTEGER DEFAULT 0
  );
  /** Resets a longops timer totalwork value.
   * used when the effort required is unknown when eth timer began.
   *    @param pti_name        longop_name_t default 'DEFAULT_LONGOP'
   */
  PROCEDURE set_total_p (
    pti_name       IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pni_totalwork  IN PLS_INTEGER DEFAULT 0
  );

  /** Stop a longops timer.
   * also sets the totalwork to = sofar so completion is 100%
   *    @param pti_name        longop_name_t default 'DEFAULT_LONGOP'
   */
  PROCEDURE stop_p (
    pti_name  IN longop_name_t DEFAULT 'DEFAULT_LONGOP'
  );


END infra_progress_pkg;
/
show errors

CREATE OR REPLACE PACKAGE BODY infra_progress_pkg AS

  gvt_longops   longop_tab;

  PROCEDURE update_p (
    pti_name IN longop_name_t
  )
    IS
  BEGIN
    IF
      gvt_longops.EXISTS(pti_name)
    THEN
      dbms_application_info.set_session_longops(
                rindex  => gvt_longops(pti_name).rindex
              , slno    => gvt_longops(pti_name).slno
              , op_name => gvt_longops(pti_name).op_name
              , target  => gvt_longops(pti_name).target
              , context => gvt_longops(pti_name).context
              , sofar   => gvt_longops(pti_name).sofar
              , totalwork   => gvt_longops(pti_name).totalwork
              , target_desc => gvt_longops(pti_name).target_desc
              , units       => gvt_longops(pti_name).units);
    END IF;
  END update_p;

  PROCEDURE set_total_p (
    pti_name     IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pni_totalwork  IN PLS_INTEGER DEFAULT 0
  )
  IS
  BEGIN
    IF
      gvt_longops.EXISTS(pti_name)
    THEN
      gvt_longops(pti_name).totalwork   := pni_totalwork;
    END IF;
  END;

  /** start a longops timer.
  *
  */
  PROCEDURE start_p (
    pti_name        IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pci_opname      IN VARCHAR2 DEFAULT NULL,
    pni_target      IN PLS_INTEGER DEFAULT 0,
    pni_context     IN PLS_INTEGER DEFAULT 0,
    pni_totalwork   IN PLS_INTEGER DEFAULT 0,
    pci_target_desc IN VARCHAR2 DEFAULT 'unknown target',
    pci_units       IN VARCHAR2 DEFAULT NULL
  )
    IS
  BEGIN

    gvt_longops(pti_name).longop_name   := pti_name;
    gvt_longops(pti_name).op_name       := pti_name;
    gvt_longops(pti_name).rindex        := dbms_application_info.set_session_longops_nohint;
    gvt_longops(pti_name).slno          := 0;
    gvt_longops(pti_name).sofar         := 0;
    gvt_longops(pti_name).totalwork     := pni_totalwork;
    gvt_longops(pti_name).target_desc   := pci_target_desc;
    gvt_longops(pti_name).units         := pci_units;
    update_p(pti_name);
  END start_p;

  /** increment a longops timer.
  *
  */

  PROCEDURE step_p (
    pti_name      IN longop_name_t DEFAULT 'DEFAULT_LONGOP',
    pni_stepsize  IN PLS_INTEGER DEFAULT 1,
    pni_context   IN PLS_INTEGER DEFAULT 0
  )
    IS
  BEGIN
    IF
      gvt_longops.EXISTS(pti_name)
    THEN
      gvt_longops(pti_name).sofar     := gvt_longops(pti_name).sofar + pni_stepsize;
      gvt_longops(pti_name).context   := pni_context;
      update_p(pti_name);
    END IF;
  END step_p;

  /** stop a longops timer.
  *
  */

  PROCEDURE stop_p (
    pti_name IN longop_name_t DEFAULT 'DEFAULT_LONGOP'
  )
    IS
  BEGIN
    IF
      gvt_longops.EXISTS(pti_name) AND gvt_longops(pti_name).totalwork   > gvt_longops(pti_name).sofar
    THEN
      gvt_longops(pti_name).totalwork   := gvt_longops(pti_name).sofar;
      update_p(pti_name);
    END IF;
  END stop_p;

END infra_progress_pkg;
/
show errors
