@echo off
:: mod_installer_gui__RUN-AS-ADMIN.cmd
:: Compiles and launches ModInstaller.exe with basic error handling and GitHub download

:: Define paths
set "targetDir=%userprofile%\Downloads\Cubic_Odyssey"
set "SCRIPT_PATH=%targetDir%\mod_installer_gui.ps1"
set "INSTALLER_PATH=%targetDir%\mod_installer.ps1"
set "EXE_PATH=%targetDir%\ModInstaller.exe"
set "GUI_SCRIPT_URL=https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer_gui.ps1"
set "INSTALLER_URL=https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer.ps1"

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"^\"%~dp0mod_installer_gui__RUN-AS-ADMIN.cmd^\"' -Verb RunAs"
    exit /b
)

:: Create Cubic_Odyssey directory if it doesn't exist
if not exist "%targetDir%" (
    echo Directory does not exist. Creating...
    mkdir "%targetDir%" 2>nul
    if errorlevel 1 (
        echo Failed to create directory %targetDir%. Please run as administrator or create it manually.
        pause
        exit /b 1
    )
    echo Directory %targetDir% created successfully.
)

pushd "%targetDir%"

:: Close existing ModInstaller instances
echo Closing existing ModInstaller.exe instances...
taskkill /IM "ModInstaller.exe" /F >nul 2>&1
if %errorlevel% equ 0 (
    echo Closed existing instances.
) else (
    echo No running instances found or access denied.
)

:: Check if mod_installer.ps1 exists, download if missing
if not exist "%INSTALLER_PATH%" (
    echo mod_installer.ps1 not found. Downloading from GitHub...
    powershell -Command "Invoke-WebRequest -Uri '%INSTALLER_URL%' -OutFile '%INSTALLER_PATH%'" 2>&1
    if errorlevel 1 (
        echo Failed to download %INSTALLER_PATH%. Please check your internet connection or GitHub URL.
        pause
        exit /b 1
    )
    echo Downloaded %INSTALLER_PATH% successfully.
)

:: Check if mod_installer_gui.ps1 exists, download if missing
if not exist "%SCRIPT_PATH%" (
    echo mod_installer_gui.ps1 not found. Downloading from GitHub...
    powershell -Command "Invoke-WebRequest -Uri '%GUI_SCRIPT_URL%' -OutFile '%SCRIPT_PATH%'" 2>&1
    if errorlevel 1 (
        echo Failed to download %SCRIPT_PATH%. Please check your internet connection or GitHub URL.
        pause
        exit /b 1
    )
    echo Downloaded %SCRIPT_PATH% successfully.
)

:: Install PS2EXE if not already installed (silent if already present)
powershell -Command "if (-not (Get-Module -ListAvailable -Name PS2EXE)) { Install-Module -Name PS2EXE -Force -Scope CurrentUser }" 2>nul

:: Set execution policy (silent if already set)
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force" 2>nul

:: Compile the script
echo Compiling %SCRIPT_PATH% to %EXE_PATH%...
powershell -Command "Import-Module PS2EXE; Invoke-PS2EXE -inputFile '%SCRIPT_PATH%' -outputFile '%EXE_PATH%' -Verbose" 2>&1
if errorlevel 1 (
    echo Failed to compile %SCRIPT_PATH%. Check PowerShell output for details.
    pause
    exit /b 1
)
echo Compilation successful.

:: Run ModInstaller
if exist "%EXE_PATH%" (
    echo Launching %EXE_PATH%...
    start "" "%EXE_PATH%"
) else (
    echo Error: %EXE_PATH% not created.
    pause
    exit /b 1
)

popd

exit /b 0
