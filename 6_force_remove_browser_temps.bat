@echo off
cd /d "%~dp0"
REM Pass-through args, e.g.  6_force_remove_browser_temps.bat -Elevated -KillAllChrome
call "%~dp0_run_ps1.bat" "%~dp06_force_remove_browser_temps.ps1" %*
