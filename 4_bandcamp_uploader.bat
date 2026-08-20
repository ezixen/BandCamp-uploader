@echo off
cd /d "%~dp0"
call "%~dp0_run_ps1.bat" "%~dp04_bandcamp_uploader.ps1" %*
