@echo off
set "targetDir=%userprofile%\Downloads\Cubic_Odyssey"

if not exist "%targetDir%" (
    echo Directory does not exist. Creating...
    mkdir "%targetDir%"
) else (
    echo Directory already exists.
)

pushd "%targetDir%"

powershell Install-Module -Name PS2EXE -Force
powershell Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
powershell Invoke-PS2EXE -inputFile "%targetDir%\mod_installer_gui.ps1" -outputFile "%targetDir%\ModInstaller.exe"
REM python mod_installer.py "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data"
ModInstaller.exe

popd

REM start "" "steam://rungameid/3400000"

