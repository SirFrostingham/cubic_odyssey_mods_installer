import sys
import os
from pathlib import Path
import shutil
import zipfile
import re
from typing import Optional

def find_folder_case_insensitive(base_path: Path, folder_name: str) -> Optional[Path]:
    """Search for a folder case-insensitively, including in subdirectories."""
    folder_name_lower = folder_name.lower()
    # Check root first
    for item in base_path.iterdir():
        if item.is_dir() and item.name.lower() == folder_name_lower:
            return item
    # Check subdirectories recursively
    for item in base_path.rglob("*"):
        if item.is_dir() and item.name.lower() == folder_name_lower:
            return item
    return None

def list_all_dirs(base_path: Path) -> list[str]:
    """List all directories in base_path recursively."""
    return [str(item.relative_to(base_path)) for item in base_path.rglob("*") if item.is_dir()]

def process_mods(game_input_dir: str, start_fresh: int = 0) -> tuple[bool, list[str]]:
    """
    Process mods for Cubic Odyssey by handling backups, unzipping files, and copying files per Instructions.txt.
    Args:
        game_input_dir: Path to the game directory.
        start_fresh: If 1, restore and back up configs; if 0 or omitted, back up configs only if configs_backup doesn't exist.
    Returns (success: bool, messages: list[str]).
    """
    errors = []
    warnings = []
    
    # Normalize game_input_dir by removing quotes and trailing slashes
    game_input_dir = game_input_dir.strip('"').rstrip("\\/")
    
    # Define paths using pathlib
    game_dir = Path(game_input_dir)
    configs_dir = game_dir / "configs"
    configs_backup_dir = game_dir / "configs_backup"
    downloads_dir = Path(os.path.expandvars(r"%userprofile%\Downloads\Cubic_Odyssey"))
    temp_dir = downloads_dir / "temp"

    # Validate game directory
    if not game_dir.exists():
        errors.append(f"Game directory {game_input_dir} does not exist")
        return False, errors

    # Handle configs backup and restore if start_fresh is 1
    if start_fresh == 1 and configs_backup_dir.exists():
        if configs_dir.exists():
            try:
                shutil.rmtree(configs_dir)
                print(f"Removed existing configs directory: {configs_dir}")
            except OSError as e:
                errors.append(f"Error removing configs directory {configs_dir}: {e}")
                return False, errors
        try:
            configs_backup_dir.rename(configs_dir)
            print(f"Renamed configs_backup to configs: {configs_dir}")
        except OSError as e:
            errors.append(f"Error renaming configs_backup to configs: {e}")
            return False, errors

    # Create configs directory if it doesn't exist
    try:
        configs_dir.mkdir(parents=True, exist_ok=True)
        if not start_fresh:
            print(f"Created or using existing configs directory: {configs_dir}")
    except OSError as e:
        errors.append(f"Error creating configs directory {configs_dir}: {e}")
        return False, errors

    # Create backup of configs if start_fresh is 1, or if start_fresh is 0 and configs_backup doesn't exist
    if (start_fresh == 1 or (start_fresh == 0 and not configs_backup_dir.exists())) and configs_dir.exists() and any(configs_dir.iterdir()):
        try:
            shutil.copytree(configs_dir, configs_backup_dir, dirs_exist_ok=True)
            print(f"Created backup of configs: {configs_backup_dir}")
        except OSError as e:
            errors.append(f"Error creating configs backup: {e}")
            return False, errors

    # Validate downloads directory
    if not downloads_dir.exists():
        errors.append(f"Downloads directory {downloads_dir} does not exist")
        return False, errors

    # Get all zip files
    zip_files = list(downloads_dir.glob("*.zip"))
    if not zip_files:
        errors.append(f"No .zip files found in {downloads_dir}")
        return False, errors

    instructions_lines = []
    configs_subfolders = []

    for zip_file in zip_files:
        print(f"\nProcessing zip file: {zip_file}")
        
        # Create or recreate temp directory
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        temp_dir.mkdir(parents=True)

        # Unzip file to temp directory
        try:
            with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                print(f"Zip contents: {zip_ref.namelist()}")
                zip_ref.extractall(temp_dir)
                print(f"Extracted {zip_file} to {temp_dir}")
                # List extracted files and directories
                extracted_items = list(temp_dir.iterdir())
                print(f"Extracted items in {temp_dir}: {[item.name for item in extracted_items]}")
                # List all directories recursively
                all_dirs = list_all_dirs(temp_dir)
                print(f"All directories in {temp_dir}: {all_dirs if all_dirs else ['None']}")
        except zipfile.BadZipFile as e:
            errors.append(f"Error unzipping {zip_file}: {e}")
            continue

        # Find Replacement Files directory
        replacement_dir = find_folder_case_insensitive(temp_dir, "Replacement Files")
        if replacement_dir:
            replacement_items = list(replacement_dir.iterdir())
            print(f"Replacement Files contents: {[item.name for item in replacement_items]}")

        # Read Instructions.txt
        instructions_path = temp_dir / "Instructions.txt"
        instructions_lines.clear()  # Reset for each zip
        configs_subfolders.clear()  # Reset for each zip
        expects_replacement_files = False

        if instructions_path.exists():
            with open(instructions_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                print(f"Instructions.txt contents:\n{''.join(lines)}")

            # Map source folders to destination subfolders for Chosen Files
            folder_mappings = {}

            for line in lines:
                line = line.strip()
                print(f"Processing line: {line}")
                
                # Look for "Copy and Paste" lines
                if re.search(r"Copy and Paste", line, re.IGNORECASE):
                    instructions_lines.append(line)
                    print(f"Added to instructions_lines: {line}")

                # Look for subfolder(s) pattern
                subfolder_match = re.search(r'subfolder\(s\): >\s*"([^"]+)"', line, re.IGNORECASE)
                if subfolder_match:
                    subfolder = subfolder_match.group(1)
                    configs_subfolders.append(subfolder)
                    print(f"Found subfolder: {subfolder}")

                # Check if Replacement Files is expected
                if "Replacement Files" in line:
                    expects_replacement_files = True

                # Handle complex scenario with Chosen Files
                chosen_files_match = re.search(
                    r"Copy and Paste.*folder\(s\): >\s*\"([^\"]+)\".*subfolder\(s\): >\s*\"([^\"]+)\"", 
                    line, 
                    re.IGNORECASE
                )
                if chosen_files_match:
                    source_folder = chosen_files_match.group(1)
                    dest_subfolder = chosen_files_match.group(2)
                    folder_mappings[source_folder] = dest_subfolder
                    print(f"Added mapping: {source_folder} -> {dest_subfolder}")

            # Process Chosen Files mappings
            for source_folder, dest_subfolder in folder_mappings.items():
                # Try part 1 and part 2 for ships due to discrepancy
                possible_folders = [source_folder]
                if "ships" in source_folder.lower():
                    # Generate alternative folder name (e.g., part 1 -> part 2, or vice versa)
                    alt_part = "part 2" if "part 1" in source_folder.lower() else "part 1"
                    alt_folder = source_folder.replace("part 1", alt_part).replace("Part 1", alt_part)
                    possible_folders.append(alt_folder)

                source_path = None
                for folder in possible_folders:
                    # Check temp root
                    source_path = find_folder_case_insensitive(temp_dir, folder)
                    # Check inside Replacement Files if not found
                    if not source_path and replacement_dir:
                        source_path = find_folder_case_insensitive(replacement_dir, folder)
                    if source_path:
                        break
                
                if source_path and source_path.is_dir():
                    dest_path = configs_dir / dest_subfolder
                    try:
                        dest_path.mkdir(parents=True, exist_ok=True)
                        files_copied = False
                        for item in source_path.iterdir():
                            if item.is_file():  # Copy only files
                                shutil.copy2(item, dest_path / item.name)
                                print(f"Copied file: {item} to {dest_path / item.name}")
                                files_copied = True
                            else:
                                print(f"Skipped directory: {item}")
                        if not files_copied:
                            warnings.append(f"No files found in {source_path} to copy to {dest_path}")
                    except OSError as e:
                        errors.append(f"Error copying from {source_path} to {dest_path}: {e}")
                else:
                    warnings.append(f"Skipping source path {temp_dir / source_folder}: does not exist or is not a directory")
                    # Log similar folder names for debugging
                    similar_dirs = [item.name for item in temp_dir.rglob("*") if item.is_dir() and source_folder.lower() in item.name.lower()]
                    if replacement_dir:
                        similar_dirs += [item.name for item in replacement_dir.rglob("*") if item.is_dir() and source_folder.lower() in item.name.lower()]
                    if similar_dirs:
                        warnings.append(f"Possible similar directories for '{source_folder}': {similar_dirs}")

        # Handle simple case: files next to Instructions.txt
        if configs_subfolders:
            for item in temp_dir.iterdir():
                if item.is_file() and item.name.lower() != "instructions.txt":
                    for subfolder in configs_subfolders:
                        dest_path = configs_dir / subfolder
                        try:
                            dest_path.mkdir(parents=True, exist_ok=True)
                            shutil.copy2(item, dest_path / item.name)
                            print(f"Copied {item} to {dest_path / item.name}")
                        except OSError as e:
                            errors.append(f"Error copying {item} to {dest_path}: {e}")
        else:
            warnings.append("No subfolders specified in Instructions.txt; skipping files next to Instructions.txt")

        # Handle Replacement Files subdirectory (case-insensitive)
        if replacement_dir and configs_subfolders:
            # Check if Replacement Files has subdirectories (e.g., part 1 - for player)
            has_subdirs = any(item.is_dir() for item in replacement_dir.iterdir())
            if not has_subdirs:  # Only process direct files if no subdirs
                for subfolder in configs_subfolders:
                    dest_path = configs_dir / subfolder
                    try:
                        dest_path.mkdir(parents=True, exist_ok=True)
                        files_copied = False
                        for item in replacement_dir.iterdir():
                            if item.is_file():  # Copy only files
                                shutil.copy2(item, dest_path / item.name)
                                print(f"Copied {item} from Replacement Files to {dest_path / item.name}")
                                files_copied = True
                            else:
                                print(f"Skipped directory: {item}")
                        if not files_copied and not has_subdirs:
                            warnings.append(f"No files found in {replacement_dir} to copy to {dest_path}")
                    except OSError as e:
                        errors.append(f"Error copying from {replacement_dir} to {dest_path}: {e}")
        elif not replacement_dir and expects_replacement_files:
            warnings.append("No Replacement Files directory found, but Instructions.txt references it")
        elif replacement_dir and not configs_subfolders:
            warnings.append("No subfolders specified in Instructions.txt; skipping Replacement Files")

        # Clean up temp directory
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
            print(f"Cleaned up temp directory: {temp_dir}")

    return len(errors) == 0, errors + warnings

if __name__ == "__main__":
    # Debug: Print raw sys.argv
    print(f"Raw sys.argv: {sys.argv}")
    
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python mod_installer.py <game_input_dir> [startFresh]")
        print("startFresh: 1 to restore and back up configs, 0 or omit to apply mods over existing configs (backup only if configs_backup doesn't exist)")
        sys.exit(1)
    
    # Handle case where game_input_dir and start_fresh are merged
    game_input_dir = sys.argv[1]
    start_fresh = 0  # Default to 0
    if len(sys.argv) == 2:
        # Check if sys.argv[1] contains a space-separated 0 or 1
        parts = sys.argv[1].rsplit(" ", 1)
        if len(parts) == 2 and parts[1] in ["0", "1"]:
            game_input_dir = parts[0]
            try:
                start_fresh = int(parts[1])
            except ValueError:
                print("Error: startFresh must be an integer (0 or 1)")
                sys.exit(1)
    elif len(sys.argv) == 3:
        try:
            start_fresh = int(sys.argv[2])
            if start_fresh not in [0, 1]:
                print("Error: startFresh must be 0 or 1")
                sys.exit(1)
        except ValueError:
            print("Error: startFresh must be an integer (0 or 1)")
            sys.exit(1)
    
    # Debug: Print parsed arguments
    print(f"Parsed game_input_dir: {game_input_dir}")
    print(f"Parsed start_fresh: {start_fresh}")
    
    success, messages = process_mods(game_input_dir, start_fresh)
    
    if messages:
        print("\nIssues encountered during mod installation:")
        for message in messages:
            print(f"- {message}")
    
    print("\nMod installation " + ("completed successfully" if success else "failed"))
    sys.exit(0 if success else 1)