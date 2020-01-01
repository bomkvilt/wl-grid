@echo off
REM -------------------------------------------------------
call :cmd_%1 %2 %3 %4 %5 %6 %7 %8 %9
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
:cmd_pack
    call "scripts/install.bat"
    call "scripts/pack.bat" %*
    exit /B 0
