@echo off
cd /d "%~dp0"
"%~dp0tools\Godot_v4.6.1-stable_win64.exe" --path "%~dp0" %*
