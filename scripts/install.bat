@echo off

for %%f IN (reader, writer) DO (
    if exist "bin\%%f.exe" rm "bin\%%f.exe"
    cp "build\windows\bin\Release\%%f.exe" "bin\%%f.exe"
)
