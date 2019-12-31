@echo off
set "srcRoot=.\\src-wl"
set "packRoot=.\\build\\pack"
set "buildRoot=.\\build\\windows\\bin\\Release"

rd /s/q %packRoot%
mkdir   %packRoot%
for %%f IN (reader, writer) DO (
    cp   "%buildRoot%\\%%f.exe" "%packRoot%\\%%f.exe"
    echo "%buildRoot%\\%%f.exe"
)
xcopy %srcRoot% %packRoot% /e
