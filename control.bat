@echo off
REM -------------------------------------------------------
call :cmd_%1
exit 0

REM -------------------------------------------------------
:cmd_init
    call "scripts/gen_project.bat"
    exit /B 0
:cmd_vs
    call "scripts/run_vs.bat"
    exit /B 0
:cmd_install
    call "scripts/install.bat"
    exit /B 0
