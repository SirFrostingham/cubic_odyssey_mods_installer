# mod_installer.ps1
param (
    [Parameter(Mandatory=$true)]
    [string]$gameInputDir,
    [int]$startFresh = 0
)

function Find-FolderCaseInsensitive {
    param (
        [string]$basePath,
        [string]$folderName
    )
    $folderNameLower = $folderName.ToLower()
    # Check root first
    $items = Get-ChildItem -Path $basePath -Directory
    foreach ($item in $items) {
        if ($item.Name.ToLower() -eq $folderNameLower) {
            return $item.FullName
        }
    }
    # Check subdirectories recursively
    $items = Get-ChildItem -Path $basePath -Directory -Recurse
    foreach ($item in $items) {
        if ($item.Name.ToLower() -eq $folderNameLower) {
            return $item.FullName
        }
    }
    return $null
}

function List-AllDirs {
    param (
        [string]$basePath
    )
    $dirs = Get-ChildItem -Path $basePath -Directory -Recurse
    $relativePaths = @()
    foreach ($dir in $dirs) {
        $relativePath = $dir.FullName.Substring($basePath.Length + 1)
        $relativePaths += $relativePath
    }
    return $relativePaths
}

function Process-Mods {
    param (
        [string]$gameInputDir,
        [int]$startFresh = 0
    )
    $errors = @()
    $warnings = @()

    # Normalize game_input_dir
    $gameInputDir = $gameInputDir.Trim('"').TrimEnd('\', '/')

    # Define paths
    $gameDir = $gameInputDir
    $configsDir = Join-Path $gameDir "configs"
    $configsBackupDir = Join-Path $gameDir "configs_backup"
    $downloadsDir = Join-Path $env:USERPROFILE "Downloads\Cubic_Odyssey"
    $tempDir = Join-Path $downloadsDir "temp"

    # Validate game directory
    if (-not (Test-Path $gameDir)) {
        $errors += "Game directory $gameInputDir does not exist"
        return $false, ($errors + $warnings)
    }

    # Handle configs backup and restore if start_fresh is 1
    if ($startFresh -eq 1 -and (Test-Path $configsBackupDir)) {
        if (Test-Path $configsDir) {
            try {
                Remove-Item -Path $configsDir -Recurse -Force -ErrorAction Stop
                Write-Host "Removed existing configs directory: $configsDir"
            }
            catch {
                $errors += "Error removing configs directory $configsDir : $_"
                return $false, ($errors + $warnings)
            }
        }
        try {
            Rename-Item -Path $configsBackupDir -NewName "configs" -ErrorAction Stop
            Write-Host "Renamed configs_backup to configs: $configsDir"
        }
        catch {
            $errors += "Error renaming configs_backup to configs: $_"
            return $false, ($errors + $warnings)
        }
    }

    # Create configs directory if it doesn't exist
    try {
        if (-not (Test-Path $configsDir)) {
            New-Item -Path $configsDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        if (-not $startFresh) {
            Write-Host "Created or using existing configs directory: $configsDir"
        }
    }
    catch {
        $errors += "Error creating configs directory $configsDir : $_"
        return $false, ($errors + $warnings)
    }

    # Create backup of configs
    if (($startFresh -eq 1 -or ($startFresh -eq 0 -and -not (Test-Path $configsBackupDir))) -and (Test-Path $configsDir) -and (Get-ChildItem $configsDir)) {
        try {
            Copy-Item -Path $configsDir -Destination $configsBackupDir -Recurse -Force -ErrorAction Stop
            Write-Host "Created backup of configs: $configsBackupDir"
        }
        catch {
            $errors += "Error creating configs backup: $_"
            return $false, ($errors + $warnings)
        }
    }

    # Validate downloads directory
    if (-not (Test-Path $downloadsDir)) {
        $errors += "Downloads directory $downloadsDir does not exist"
        return $false, ($errors + $warnings)
    }

    # Get all zip files
    $zipFiles = Get-ChildItem -Path $downloadsDir -Filter "*.zip"
    if (-not $zipFiles) {
        $errors += "No .zip files found in $downloadsDir"
        return $false, ($errors + $warnings)
    }

    $instructionsLines = @()
    $configsSubfolders = @()

    foreach ($zipFile in $zipFiles) {
        Write-Host "`nProcessing zip file: $($zipFile.FullName)"

        # Create or recreate temp directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        # Unzip file to temp directory
        try {
            Expand-Archive -Path $zipFile.FullName -DestinationPath $tempDir -Force -ErrorAction Stop
            Write-Host "Extracted $($zipFile.Name) to $tempDir"
            $extractedItems = Get-ChildItem -Path $tempDir
            Write-Host "Extracted items in $tempDir : $($extractedItems.Name -join ', ')"
            $allDirs = List-AllDirs -basePath $tempDir
            Write-Host "All directories in $tempDir : $($allDirs -join ', ')"
        }
        catch {
            $errors += "Error unzipping $($zipFile.Name): $_"
            continue
        }

        # Find Replacement Files directory
        $replacementDir = Find-FolderCaseInsensitive -basePath $tempDir -folderName "Replacement Files"
        if ($replacementDir) {
            $replacementItems = Get-ChildItem -Path $replacementDir
            Write-Host "Replacement Files contents: $($replacementItems.Name -join ', ')"
        }

        # Read Instructions.txt
        $instructionsPath = Join-Path $tempDir "Instructions.txt"
        $instructionsLines = @()
        $configsSubfolders = @()
        $expectsReplacementFiles = $false

        if (Test-Path $instructionsPath) {
            $lines = Get-Content -Path $instructionsPath -Encoding UTF8
            Write-Host "Instructions.txt contents:`n$($lines -join "`n")"

            $folderMappings = @{}

            foreach ($line in $lines) {
                $line = $line.Trim()
                Write-Host "Processing line: $line"

                # Look for "Copy and Paste" lines
                if ($line -imatch "Copy and Paste") {
                    $instructionsLines += $line
                    Write-Host "Added to instructions_lines: $line"
                }

                # Look for subfolder(s) pattern
                if ($line -imatch 'subfolder\(s\): >\s*"([^"]+)"') {
                    $subfolder = $matches[1]
                    $configsSubfolders += $subfolder
                    Write-Host "Found subfolder: $subfolder"
                }

                # Check if Replacement Files is expected
                if ($line -imatch "Replacement Files") {
                    $expectsReplacementFiles = $true
                }

                # Handle complex scenario with Chosen Files
                if ($line -imatch 'Copy and Paste.*folder\(s\): >\s*"([^"]+)".*subfolder\(s\): >\s*"([^"]+)"') {
                    $sourceFolder = $matches[1]
                    $destSubfolder = $matches[2]
                    $folderMappings[$sourceFolder] = $destSubfolder
                    Write-Host "Added mapping: $sourceFolder -> $destSubfolder"
                }
            }

            # Process Chosen Files mappings
            foreach ($sourceFolder in $folderMappings.Keys) {
                $destSubfolder = $folderMappings[$sourceFolder]
                $possibleFolders = @($sourceFolder)
                if ($sourceFolder -imatch "ships") {
                    $altPart = if ($sourceFolder -imatch "part 1") { "part 2" } else { "part 1" }
                    $altFolder = $sourceFolder -replace "part 1", $altPart -replace "Part 1", $altPart
                    $possibleFolders += $altFolder
                }

                $sourcePath = $null
                foreach ($folder in $possibleFolders) {
                    $sourcePath = Find-FolderCaseInsensitive -basePath $tempDir -folderName $folder
                    if (-not $sourcePath -and $replacementDir) {
                        $sourcePath = Find-FolderCaseInsensitive -basePath $replacementDir -folderName $folder
                    }
                    if ($sourcePath) {
                        break
                    }
                }

                if ($sourcePath -and (Test-Path $sourcePath -PathType Container)) {
                    $destPath = Join-Path $configsDir $destSubfolder
                    try {
                        if (-not (Test-Path $destPath)) {
                            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                        }
                        $filesCopied = $false
                        $items = Get-ChildItem -Path $sourcePath
                        foreach ($item in $items) {
                            if ($item.PSIsContainer) {
                                Write-Host "Skipped directory: $($item.FullName)"
                                continue
                            }
                            Copy-Item -Path $item.FullName -Destination (Join-Path $destPath $item.Name) -Force -ErrorAction Stop
                            Write-Host "Copied file: $($item.FullName) to $(Join-Path $destPath $item.Name)"
                            $filesCopied = $true
                        }
                        if (-not $filesCopied) {
                            $warnings += "No files found in $sourcePath to copy to $destPath"
                        }
                    }
                    catch {
                        $errors += "Error copying from $sourcePath to $destPath : $_"
                    }
                }
                else {
                    $warnings += "Skipping source path $(Join-Path $tempDir $sourceFolder): does not exist or is not a directory"
                    $similarDirs = @()
                    $allDirs = Get-ChildItem -Path $tempDir -Directory -Recurse
                    foreach ($dir in $allDirs) {
                        if ($dir.Name -imatch [regex]::Escape($sourceFolder)) {
                            $similarDirs += $dir.Name
                        }
                    }
                    if ($replacementDir) {
                        $allDirs = Get-ChildItem -Path $replacementDir -Directory -Recurse
                        foreach ($dir in $allDirs) {
                            if ($dir.Name -imatch [regex]::Escape($sourceFolder)) {
                                $similarDirs += $dir.Name
                            }
                        }
                    }
                    if ($similarDirs) {
                        $warnings += "Possible similar directories for '$sourceFolder': $($similarDirs -join ', ')"
                    }
                }
            }
        }

        # Handle simple case: files next to Instructions.txt
        if ($configsSubfolders) {
            $items = Get-ChildItem -Path $tempDir
            foreach ($item in $items) {
                if ($item.PSIsContainer -or $item.Name -ieq "Instructions.txt") {
                    continue
                }
                foreach ($subfolder in $configsSubfolders) {
                    $destPath = Join-Path $configsDir $subfolder
                    try {
                        if (-not (Test-Path $destPath)) {
                            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                        }
                        Copy-Item -Path $item.FullName -Destination (Join-Path $destPath $item.Name) -Force -ErrorAction Stop
                        Write-Host "Copied $($item.FullName) to $(Join-Path $destPath $item.Name)"
                    }
                    catch {
                        $errors += "Error copying $($item.FullName) to $destPath : $_"
                    }
                }
            }
        }
        else {
            $warnings += "No subfolders specified in Instructions.txt; skipping files next to Instructions.txt"
        }

        # Handle Replacement Files subdirectory
        if ($replacementDir -and $configsSubfolders) {
            $hasSubdirs = (Get-ChildItem -Path $replacementDir -Directory).Count -gt 0
            if (-not $hasSubdirs) {
                foreach ($subfolder in $configsSubfolders) {
                    $destPath = Join-Path $configsDir $subfolder
                    try {
                        if (-not (Test-Path $destPath)) {
                            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                        }
                        $filesCopied = $false
                        $items = Get-ChildItem -Path $replacementDir
                        foreach ($item in $items) {
                            if ($item.PSIsContainer) {
                                Write-Host "Skipped directory: $($item.FullName)"
                                continue
                            }
                            Copy-Item -Path $item.FullName -Destination (Join-Path $destPath $item.Name) -Force -ErrorAction Stop
                            Write-Host "Copied $($item.FullName) from Replacement Files to $(Join-Path $destPath $item.Name)"
                            $filesCopied = $true
                        }
                        if (-not $filesCopied -and -not $hasSubdirs) {
                            $warnings += "No files found in $replacementDir to copy to $destPath"
                        }
                    }
                    catch {
                        $errors += "Error copying from $replacementDir to $destPath : $_"
                    }
                }
            }
        }
        elseif (-not $replacementDir -and $expectsReplacementFiles) {
            $warnings += "No Replacement Files directory found, but Instructions.txt references it"
        }
        elseif ($replacementDir -and -not $configsSubfolders) {
            $warnings += "No subfolders specified in Instructions.txt; skipping Replacement Files"
        }

        # Clean up temp directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-Host "Cleaned up temp directory: $tempDir"
        }
    }

    return ($errors.Count -eq 0), ($errors + $warnings)
}

# Main script
Write-Host "Raw arguments: $args"

if (-not $gameInputDir) {
    Write-Host "Usage: .\mod_installer.ps1 -gameInputDir <game_input_dir> [-startFresh <0 or 1>]"
    Write-Host "startFresh: 1 to restore and back up configs, 0 or omit to apply mods over existing configs"
    exit 1
}

Write-Host "Parsed game_input_dir: $gameInputDir"
Write-Host "Parsed start_fresh: $startFresh"

$success, $messages = Process-Mods -gameInputDir $gameInputDir -startFresh $startFresh

if ($messages) {
    Write-Host "`nIssues encountered during mod installation:"
    foreach ($message in $messages) {
        Write-Host "- $message"
    }
}

Write-Host "`nMod installation $(if ($success) { 'completed successfully' } else { 'failed' })"
exit $(if ($success) { 0 } else { 1 })