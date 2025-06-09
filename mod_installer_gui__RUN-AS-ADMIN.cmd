@echo off
set "targetDir=%userprofile%\Downloads\Cubic_Odyssey"

if not exist "%targetDir%" (
    echo Directory does not exist. Creating...
    mkdir "%targetDir%"
) else (
    REM echo Directory already exists.
)

pushd "%targetDir%"

REM close existing ModInstaller instances
taskkill /IM "ModInstaller.exe" /F >nul 2>&1

REM build ModInstaller
powershell Install-Module -Name PS2EXE -Force
powershell Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
powershell Invoke-PS2EXE -inputFile "%targetDir%\mod_installer_gui.ps1" -outputFile "%targetDir%\ModInstaller.exe"

REM Run ModInstaller
ModInstaller.exe

popd

REM start "" "steam://rungameid/3400000"

