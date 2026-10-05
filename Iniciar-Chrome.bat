@echo off
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel% equ 0 (
    python scripts\run.py --device chrome
) else (
    py -3 scripts\run.py --device chrome
)
pause

