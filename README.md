# Overview
A generic mods installer, that was modeled after this Nexus Mods tweaks collection: [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=files)
- This mods script uses the installation.txt file from SkyPhoenixMods's mods collection to install mods to the Cubic Odyssey game directory -> data -> configs location.

# Prerequisites
- Install Python
- Tested on Windows 11

# How to
1. In your Downloads directory (%USERPROFILE%\Downloads), create a directory called Cubic_Odyssey - example: C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\
2. Download `mod_installer.py` and put it in the `Cubic_Odyssey` directory created in step 1
3. Download all files listed here [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=files) and put those zip files in the `Cubic_Odyssey` directory created in step 1
4. Run syntax: python mod_installer.py [REQUIRED:Game_directory_data_location] [OPTIONAL:Add_Fresh_configs_directory_backup]

Note: First run will back up the current data\configs directory.

Examples:
```
# Run use cases (will apply mod files copy fresh in line each time)
python mod_installer.py "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data"
python mod_installer.py "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data"

# Optional parameter - Fresh start (Backs up the data\configs directory and rebuilds the data\configs directory from a backup each time)
python mod_installer.py "C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data" 1
python mod_installer.py "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data" 1
```

Enjoy!
