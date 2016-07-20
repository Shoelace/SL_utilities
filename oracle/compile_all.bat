@echo off

USERID=scott/tiger@orcl

FOR  %%i  IN (*.fmb) DO (
	echo %%i 
	frmcmp module=%%i userid=%USERID%  module_type=FORM  logon=YES compile_all=YES batch=YES window_state=MINIMIZE
	IF NOT ERRORLEVEL 1 del %%~ni.err
)

FOR  %%i  IN (*.pll) DO (
	echo %%i
	frmcmp module=%%i userid=%USERID%  module_type=LIBRARY  logon=YES compile_all=YES batch=YES window_state=MINIMIZE
	IF NOT ERRORLEVEL 1 del %%~ni.err
)
FOR  %%i  IN (*.mmb) DO (
	echo %%i
	frmcmp module=%%i userid=%USERID%  module_type=MENU  logon=YES compile_all=YES batch=YES window_state=MINIMIZE
	IF NOT ERRORLEVEL 1 del %%~ni.err
)


REM frmcmp module=ab_gcmnu.fmb userid=impdpb/gc11dvp@gcdev  module_type=FORM  logon=YES compile_all=YES batch=YES window_state=MINIMIZE
