@echo off
:: mod_installer_gui__RUN-AS-ADMIN.cmd
:: Launches ModInstaller.exe with administrator privileges after ensuring required files are present

:: Define paths
set "SCRIPT_PATH=C:\Users\areed\Downloads\Cubic_Odyssey\mod_installer_gui.ps1"
set "EXE_PATH=C:\Users\areed\Downloads\Cubic_Odyssey\ModInstaller.exe"
set "GUI_SCRIPT_URL=https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer_gui.ps1"

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"^\"%~dp0mod_installer_gui__RUN-AS-ADMIN.cmd^\"' -Verb RunAs"
    exit /b
)

:: Close any existing ModInstaller.exe instances
echo Closing existing ModInstaller.exe instances...
taskkill /IM "ModInstaller.exe" /F >nul 2>&1
if %errorlevel% equ 0 (
    echo Closed existing instances.
) else (
    echo No running instances found or access denied.
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

:: Compile the script if PS2EXE is available
if exist "%SCRIPT_PATH%" (
    echo Compiling %SCRIPT_PATH% to %EXE_PATH%...
    powershell -Command "Import-Module PS2EXE; Invoke-PS2EXE -inputFile '%SCRIPT_PATH%' -outputFile '%EXE_PATH%' -Verbose" 2>&1
    if %errorlevel% equ 0 (
        echo Compilation successful.
    ) else (
        echo Failed to compile %SCRIPT_PATH%. Check PowerShell output for details.
        pause
        exit /b 1
    )
) else (
    echo Error: %SCRIPT_PATH% not found after download attempt.
    pause
    exit /b 1
)

:: Launch the compiled executable
if exist "%EXE_PATH%" (
    echo Launching %EXE_PATH%...
    start "" "%EXE_PATH%"
) else (
    echo Error: %EXE_PATH% not created.
    pause
    exit /b 1
)

exit /b 0
