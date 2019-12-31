@echo off
set "packRoot=.\\build\\pack"
set "destRoot=%1"

if not exist "%destRoot%" mkdir "%destRoot%"
xcopy "%packRoot%" "%destRoot%" /e
