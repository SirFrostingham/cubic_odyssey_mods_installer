# mod_installer_gui.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# GitHub repository details
$repoUrl = "https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer.ps1"
$guiScriptUrl = "https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer_gui.ps1"
$cmdScriptUrl = "https://raw.githubusercontent.com/SirFrostingham/cubic_odyssey_mods_installer/main/mod_installer_gui__RUN-AS-ADMIN.cmd"
$localModsPath = "$env:USERPROFILE\Downloads\Cubic_Odyssey\"
$localScriptPath = "$env:USERPROFILE\Downloads\Cubic_Odyssey\mod_installer.ps1"
$localGuiScriptPath = "$env:USERPROFILE\Downloads\Cubic_Odyssey\mod_installer_gui.ps1"
$localCmdScriptPath = "$env:USERPROFILE\Downloads\Cubic_Odyssey\mod_installer_gui__RUN-AS-ADMIN.cmd"
$configFilePath = "$env:USERPROFILE\Downloads\Cubic_Odyssey\mod_installer_config.txt"

# Function to check for updates from GitHub
function Check-ScriptUpdate {
    $updatesApplied = $false
    try {
        # Check and update mod_installer.ps1
        $webContent = Invoke-RestMethod -Uri $repoUrl -ErrorAction Stop
        $localContent = if (Test-Path $localScriptPath) { Get-Content $localScriptPath -Raw } else { "" }
        if ($webContent -ne $localContent) {
            $webContent | Out-File -FilePath $localScriptPath -Force
            $ResultsTextBox.Text += "Updated mod_installer.ps1 from GitHub.`r`n"
            Write-Host "Updated mod_installer.ps1 from GitHub."
            $updatesApplied = $true
        } else {
            $ResultsTextBox.Text += "mod_installer.ps1 is up to date.`r`n"
            Write-Host "mod_installer.ps1 is up to date."
        }

        # Check and update mod_installer_gui.ps1
        $webContent = Invoke-RestMethod -Uri $guiScriptUrl -ErrorAction Stop
        $localContent = if (Test-Path $localGuiScriptPath) { Get-Content $localGuiScriptPath -Raw } else { "" }
        if ($webContent -ne $localContent) {
            $webContent | Out-File -FilePath $localGuiScriptPath -Force
            $ResultsTextBox.Text += "Updated mod_installer_gui.ps1 from GitHub.`r`n"
            Write-Host "Updated mod_installer_gui.ps1 from GitHub."
            $updatesApplied = $true
        } else {
            $ResultsTextBox.Text += "mod_installer_gui.ps1 is up to date.`r`n"
            Write-Host "mod_installer_gui.ps1 is up to date."
        }

        # Check and update mod_installer_gui__RUN-AS-ADMIN.cmd
        $webContent = Invoke-RestMethod -Uri $cmdScriptUrl -ErrorAction Stop
        $localContent = if (Test-Path $localCmdScriptPath) { Get-Content $localCmdScriptPath -Raw } else { "" }
        if ($webContent -ne $localContent) {
            $webContent | Out-File -FilePath $localCmdScriptPath -Force
            $ResultsTextBox.Text += "Updated mod_installer_gui__RUN-AS-ADMIN.cmd from GitHub.`r`n"
            Write-Host "Updated mod_installer_gui__RUN-AS-ADMIN.cmd from GitHub."
            $updatesApplied = $true
        } else {
            $ResultsTextBox.Text += "mod_installer_gui__RUN-AS-ADMIN.cmd is up to date.`r`n"
            Write-Host "mod_installer_gui__RUN-AS-ADMIN.cmd is up to date."
        }

        if (-not $updatesApplied) {
            $ResultsTextBox.Text += "All files are up to date.`r`n"
        }
        return $updatesApplied
    } catch {
        $ResultsTextBox.Text += "Error checking for updates: $_`r`n"
        Write-Host "Error checking for updates: $_"
        return $false
    }
}

# Function to run the mod installer script
function Run-ModInstaller {
    $gameDir = $GameDirTextBox.Text.Trim()
    $startFresh = if ($StartFreshCheckbox.Checked) { 1 } else { 0 }

    if (-not $gameDir) {
        $ResultsTextBox.Text += "Error: Please enter a valid game directory.`r`n"
        return
    }
    if (-not (Test-Path $gameDir)) {
        $ResultsTextBox.Text += "Error: Game directory $gameDir does not exist.`r`n"
        return
    }
    if (-not (Test-Path $localScriptPath)) {
        $ResultsTextBox.Text += "Error: mod_installer.ps1 not found at $localScriptPath.`r`n"
        return
    }

    $ResultsTextBox.Text += "Running mod_installer.ps1 with gameInputDir=$gameDir and startFresh=$startFresh...`r`n"
    try {
        $command = "& '$localScriptPath' -gameInputDir '$gameDir' -startFresh $startFresh"
        $output = Invoke-Expression $command 2>&1 | Out-String
        $ResultsTextBox.Text += "$output`r`n"
        $ResultsTextBox.Text += "Mod installation completed.`r`n"
    } catch {
        $ResultsTextBox.Text += "Error running mod_installer.ps1: $_`r`n"
    }
}

# Function to launch Cubic Odyssey
function Launch-Game {
    try {
        Start-Process "steam://rungameid/3400000" -ErrorAction Stop
        $ResultsTextBox.Text += "Launching Cubic Odyssey via Steam...`r`n"
        Write-Host "Launching Cubic Odyssey via Steam..."
    } catch {
        $ResultsTextBox.Text += "Error launching Cubic Odyssey: $_`r`n"
        Write-Host "Error launching Cubic Odyssey: $_"
    }
}

# Create the form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Cubic Odyssey Mod Installer"
$Form.Size = New-Object System.Drawing.Size(600, 400)
$Form.StartPosition = "CenterScreen"

# Font for the form
$Font = New-Object System.Drawing.Font("Verdana", 10)
$Form.Font = $Font

# Game Directory Label
$GameDirLabel = New-Object System.Windows.Forms.Label
$GameDirLabel.Location = New-Object System.Drawing.Size(20, 20)
$GameDirLabel.Size = New-Object System.Drawing.Size(150, 20)
$GameDirLabel.Text = "Game 'data' Directory:"
$Form.Controls.Add($GameDirLabel)

# Game Directory TextBox
$GameDirTextBox = New-Object System.Windows.Forms.TextBox
$GameDirTextBox.Location = New-Object System.Drawing.Size(170, 20)
$GameDirTextBox.Size = New-Object System.Drawing.Size(300, 20)
# Load saved game directory if config file exists, else use default
$defaultGameDir = "D:\SteamLibrary\steamapps\common\Cubic Odyssey\data"
if (Test-Path $configFilePath) {
    try {
        $savedGameDir = Get-Content $configFilePath -Raw -ErrorAction Stop
        $GameDirTextBox.Text = $savedGameDir.Trim()
    } catch {
        $ResultsTextBox.Text += "Error loading config file: $_`r`n"
        $GameDirTextBox.Text = $defaultGameDir
    }
} else {
    $GameDirTextBox.Text = $defaultGameDir
}
$Form.Controls.Add($GameDirTextBox)

# Browse Button
$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Location = New-Object System.Drawing.Size(480, 20)
$BrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$BrowseButton.Text = "Browse"
$BrowseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the Cubic Odyssey data directory"
    $folderBrowser.SelectedPath = $GameDirTextBox.Text
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $GameDirTextBox.Text = $folderBrowser.SelectedPath
    }
})
$Form.Controls.Add($BrowseButton)

# Start Fresh Checkbox
$StartFreshCheckbox = New-Object System.Windows.Forms.CheckBox
$StartFreshCheckbox.Location = New-Object System.Drawing.Size(20, 60)
$StartFreshCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$StartFreshCheckbox.Text = "Start Fresh (Reset Configs)"
$StartFreshCheckbox.Checked = $false
$Form.Controls.Add($StartFreshCheckbox)

# Results TextBox
$ResultsTextBox = New-Object System.Windows.Forms.TextBox
$ResultsTextBox.Location = New-Object System.Drawing.Size(20, 100)
$ResultsTextBox.Size = New-Object System.Drawing.Size(540, 200)
$ResultsTextBox.Multiline = $true
$ResultsTextBox.ScrollBars = "Vertical"
$ResultsTextBox.Text = "Be sure you downloaded mods from https://www.nexusmods.com/games/cubicodyssey/mods and put the ZIP files in your directory: $localModsPath`r`n`r`nEnter the game directory and click 'Check for Updates' or 'Install Mods'.`r`n"
$Form.Controls.Add($ResultsTextBox)

# Check for Updates Button
$UpdateButton = New-Object System.Windows.Forms.Button
$UpdateButton.Location = New-Object System.Drawing.Size(20, 320)
$UpdateButton.Size = New-Object System.Drawing.Size(150, 30)
$UpdateButton.Text = "Check for Updates"
$UpdateButton.Add_Click({ Check-ScriptUpdate })
$Form.Controls.Add($UpdateButton)

# Install Mods Button
$RunButton = New-Object System.Windows.Forms.Button
$RunButton.Location = New-Object System.Drawing.Size(180, 320)
$RunButton.Size = New-Object System.Drawing.Size(150, 30)
$RunButton.Text = "Install Mods"
$RunButton.Add_Click({ Run-ModInstaller })
$Form.Controls.Add($RunButton)

# Launch Game Button
$LaunchButton = New-Object System.Windows.Forms.Button
$LaunchButton.Location = New-Object System.Drawing.Size(340, 320)
$LaunchButton.Size = New-Object System.Drawing.Size(150, 30)
$LaunchButton.Text = "Launch Game"
$LaunchButton.Add_Click({ Launch-Game })
$Form.Controls.Add($LaunchButton)

# Save game directory when form closes
$Form.Add_FormClosing({
    try {
        $gameDir = $GameDirTextBox.Text.Trim()
        if ($gameDir) {
            $gameDir | Out-File -FilePath $configFilePath -Force
            Write-Host "Saved game directory to $configFilePath"
        }
    } catch {
        $ResultsTextBox.Text += "Error saving config file: $_`r`n"
    }
})

# Show the form
[void]$Form.ShowDialog()
