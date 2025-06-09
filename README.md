# Cubic Odyssey Mod Installer Guide

## Overview
A user-friendly mod installer for *Cubic Odyssey*, modeled after the [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=description) collection. This installer uses the `Instructions.txt` file from SkyPhoenixMods's mod collection to install mods to the *Cubic Odyssey* game directory (`data\configs`).

## Prerequisites
- **Operating System**: Windows 10 or 11 (PowerShell is built-in).
- **Administrator Privileges**: The installer must be run as an administrator to access game directories (e.g., in `Program Files`).
- **Steam**: Required to launch *Cubic Odyssey* via the installer.
- **Internet Connection**: Needed to check for updates to the installer script from GitHub.

## Screenshot
![image](https://github.com/user-attachments/assets/765b1f4b-b002-4fde-8795-817442ca7c5b)


## How to Install and Use

1. **Create the Mods Directory**:
   - In your Downloads directory (`%USERPROFILE%\Downloads`), create a folder named `Cubic_Odyssey`. Example: `C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\`.

2. **Download the Installer**:
   - Download `mod_installer_gui__RUN-AS-ADMIN.cmd` from the [GitHub repository](https://github.com/SirFrostingham/cubic_odyssey_mods_installer).
   - Place `mod_installer_gui__RUN-AS-ADMIN.cmd` in the `Cubic_Odyssey` directory created in step 1.

3. **Download Mods**:
   - Download all mod `.zip` files from [SkyPhoenixMods - Cubic Odyssey - Tweakers](https://www.nexusmods.com/cubicodyssey/mods/5?tab=files).
   - Place these `.zip` files in the `Cubic_Odyssey` directory.

4. **Run the Installer**:
   - Navigate to the `Cubic_Odyssey` directory (e.g., `C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\`).
   - Right-click `mod_installer_gui__RUN-AS-ADMIN.cmd` and select **Run as administrator**.
   - This creates and launches `ModInstaller.exe` with elevated privileges, opening a GUI with the following features:
     - **Game Directory**: Enter or browse to the *Cubic Odyssey* data directory (e.g., `C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data`).
     - **Start Fresh Checkbox**: Check to reset configs by restoring from a backup and creating a new backup (`-startFresh 1`).
     - **Check for Updates**: Downloads the latest `mod_installer.ps1` from GitHub.
     - **Run Installer**: Applies mods to the game directory based on `Instructions.txt` in the mod `.zip` files.
     - **Launch Game**: Starts *Cubic Odyssey* via Steam (`steam://rungameid/3400000`).

5. **Configure and Install**:
   - In the GUI, set the game directory (defaults to `C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data` or the last saved directory).
   - Optionally check "Start Fresh" to reset configs.
   - Click **Check for Updates** to ensure the latest mod installer script is used.
   - Click **Run Installer** to apply mods. The results textbox will show progress and errors.
   - On success, the final message will be: `Mod installation completed.`
   - Click **Launch Game** to start *Cubic Odyssey* via Steam.

6. **Notes**:
   - The first run may take longer due to backing up the `data\configs` directory to `data\configs_backup`.
   - The game directory is saved to `C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\mod_installer_config.txt` when you close the GUI, so it persists across sessions.
   - If the game directory is in a protected location (e.g., `C:\Program Files (x86)`), running as administrator is required.

## Example Game Directories
- `C:\Program Files (x86)\Steam\steamapps\common\Cubic Odyssey\data`
- `D:\SteamLibrary\steamapps\common\Cubic Odyssey\data`

## Troubleshooting
- **Installer Fails to Run**: Ensure you right-click `mod_installer_gui__RUN-AS-ADMIN.cmd` and select "Run as administrator".
- **Game Directory Not Found**: Verify the path points to the `data` folder in your *Cubic Odyssey* installation.
- **Steam Launch Fails**: Ensure Steam is installed and logged in. Test the URI manually: `Start-Process "steam://rungameid/3400000"` in PowerShell.
- **Mod Installation Errors**: Check that mod `.zip` files are in `C:\Users\Your_User_Name\Downloads\Cubic_Odyssey\` and contain a valid `Instructions.txt`.

Enjoy your modded *Cubic Odyssey* experience!
