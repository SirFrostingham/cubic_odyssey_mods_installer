# Overview
A generic mods installer, that was modeled after this Nexus Mods tweaks collection: [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=description)
- This mods script uses the installation.txt file from SkyPhoenixMods's mods collection to install mods to the Cubic Odyssey game directory -> data -> configs location.

# 2 Options
1. Powershell script
2. Python script

# Prerequisites
- If Powershell Option: Powershell is built into Windows
- If Python Option: Install Python (see steps here for my favorite way to install Python for Windows: https://github.com/SirFrostingham/windows_python_install)
- Both script options tested on Windows 11

# How to
1. In your Downloads directory (`%USERPROFILE%\Downloads`), create a directory called Cubic_Odyssey - example: `C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\`
2. Download `mod_installer.py` and put it in the `Cubic_Odyssey` directory created in step 1
3. Download all files listed here [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=files) and put those zip files in the `Cubic_Odyssey` directory created in step 1
4. Windows menu -> Type: `cmd.exe` -> `cd %userprofile%\Downloads\Cubic_Odyssey`
5. a. Powershell SCRIPT - Run syntax: `powershell -ExecutionPolicy Bypass -File .\mod_installer.ps1 -gameInputDir "[REQUIRED:Game_directory_data_location]"`
5. b. PYTHON SCRIPT - Run syntax: `python mod_installer.py "[REQUIRED:Game_directory_data_location]"`
6. After the script runs, run the game.
   - Note: you will see this message as the last message for a successful install: Mod installation completed successfully

Note: First run will run a little slower, due to backing up the current data\configs directory.

Powershell Option Examples:
```
# Run use cases (will apply mod files copy fresh in line each time)
powershell -ExecutionPolicy Bypass -File .\mod_installer.ps1 -gameInputDir "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data"
powershell -ExecutionPolicy Bypass -File .\mod_installer.ps1 -gameInputDir "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data"

# Optional parameter - Fresh start (Backs up the data\configs directory and rebuilds the data\configs directory from a backup each time)
powershell -ExecutionPolicy Bypass -File .\mod_installer.ps1 -gameInputDir "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data" -startFresh 1
powershell -ExecutionPolicy Bypass -File .\mod_installer.ps1 -gameInputDir "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data" -startFresh 1
```

Python Option Examples:
```
# Run use cases (will apply mod files copy fresh in line each time)
python mod_installer.py "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data"
python mod_installer.py "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data"

# Optional parameter - Fresh start (Backs up the data\configs directory and rebuilds the data\configs directory from a backup each time)
python mod_installer.py "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data" 1
python mod_installer.py "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data" 1
```

Enjoy!
