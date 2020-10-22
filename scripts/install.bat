@echo off
set "srcRoot=.\src-wl"
set "packRoot=.\build\pack"
set "buildRoot=.\build\windows\bin\Release"

rd /s/q %packRoot%
mkdir   %packRoot%
for %%f IN (reader, writer) DO (
    xcopy "%buildRoot%\%%f.exe" "%packRoot%"
    echo  "%buildRoot%\%%f.exe"
)
xcopy %srcRoot% %packRoot% /e
