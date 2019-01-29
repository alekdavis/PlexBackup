#------------------------------[ HELP INFO ]-------------------------------

<#
.SYNOPSIS
Backs up or restores Plex application data files and registry keys on a 
Windows system.

.DESCRIPTION
The script can run in three modes: 

- Backup (initiates a new backup),
- Continue (continues a previous backup), and 
- Restore (restores Plex app data from a backup).

The script backs up the contents of the 'Plex Media Server' folder (app
data folder) with the exception of some top-level, non-essential folders. 
You can customize the list of folders that do not need to be backed up. 
By default, the following top-level app data folders are not backed up:

  Diagnostics, Crash Reports, Updates, Logs

The backup process compresses the contents Plex app data folders to the ZIP 
files (with the exception of folders containing subfolders and files with 
really long paths). For efficiency reasons, the script first compresses the 
data in a temporary folder and then copies the compressed (ZIP) files to the 
backup destination folder. You can compress data to the backup destination 
folder directly (bypassing the saving to the temp folder step) by setting the
value of the $TempZipFileDir variable to null or empty string. Folders holding 
subfolders and files with very long paths get special treatment: instead of 
compressing them, before performing the backup, the script moves them to the 
backup folder as-is, and after the backup, it copies them to their original 
locations. Alternatively, backup can create a mirror of the essential app
data folder via the Robocopy command (to use this option, set the -Robocopy
switch).

In addition to backing up Plex app data, the script also backs up the contents 
of the Plex Windows Registry key. 

The backup is created in the specified backup folder under a subfolder which
name reflects the script start time. It deletes the old backup folders 
(you can specify the number of old backup folders to keep).

If the backup process does not complete due to error, you can run backup in 
the Continue mode (using the '-Mode Continue' command-line switch) and it will
resume from where it left off. By default, the script picks up the most recent
backup folder, but you can specify the backup folder using the -BackupDirPath
command-line switch.

When restoring Plex application data from a backup, the script expects the
backup folder structure to be the same as the one it creates when it runs in 
the backup mode. By default, it use the backup folder with the name reflecting 
the most recent timestamp, but you can specify an alternative backup folder.

Before creating backup or restoring data from a backup, the script stops all
running Plex services and the Plex Media Server process (it restarts them once 
the operation is completed). You can force the script to not start the Plex
Media Server process via the -Shutdown switch.

To override the default script settings, modify the values of script parameters 
and global variables inline or specify them in a config file. The config file 
must use the JSON format. Not every script variable can be specified in the 
config file (for the list of overridable variables, see the InitConfig function 
or a sample config file). Only non-null values from config file will be used. 
The default config file is named after the running script with the '.json' 
extension, such as: PlexBackup.ps1.json. You can specify a custom config file 
via the -ConfigFile command-line switch. Config file is optional.

This script must run as an administrator. 

The execution policy must allow running scripts. To check execution policy,
run the following command: 

  Get-ExecutionPolicy

If the execution policy doe snot allow running scripts, do the following:

  (1) Start Windows PowerShell with the "Run as Administrator" option. 
  (2) Run the following command: 

    Set-ExecutionPolicy RemoteSigned

This will allow running unsigned scripts that you write on your local 
computer and signed scripts from Internet.

See also 'Running Scripts' at Microsoft TechNet Library:
https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)

.PARAMETER Mode
Specifies the mode of operation: Backup (default), Continue, or Re.

.PARAMETER BackupDirPath
When running the script in the Restore mode, specifies path to the backup folder.

.PARAMETER BackupRootDir
Path to the root backup folder holding timestamped backup subfolders.

.PARAMETER TempZipFileDir
Temp folder used to stage archiving job (use local drive for efficiency).
To bypass the staging step, set this parameter to null or empty string.

.PARAMETER PlexAppDataDir
Location of the Plex application data folder.

.PARAMETER ConfigFile
Path to the optional config (JSON) file.

.PARAMETER Robocopy
When true, the script will use Robocopy instead of ZIP compression.

.PARAMETER Retries
The number of retries on failed copies (Robocopy /R switch).

.PARAMETER RetryWaitSec
pecifies the wait time between retries, in seconds (Robocopy /W switch).

.PARAMETER Shutdown
When set to true, the Plex Media Server process will not be restarted.

.NOTES
Version    : 1.0
Author     : Alek Davis
Created on : 2019-01-28

.LINK
https://github.com/alekdavis/PlexBackup

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
PlexBackup.ps1
Backs up compressed Plex application data to the default backup location.

.EXAMPLE
PlexBackup.ps1 -Robocopy
Backs up Plex application data to the default backup location using
the Robocopy command instead of the file and folder compression.

.EXAMPLE
PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
Backs up Plex application data to the specified backup location on a 
network share.

.EXAMPLE
PlexBackup.ps1 -Mode Continue
Continues the last backup process where it left off.

.EXAMPLE
PlexBackup.ps1 -Mode Restore
Restores Plex application data from the latest backup in the default folder.

.EXAMPLE
PlexBackup.ps1 -Mode Restore -Robocopy
Restores Plex application data from the latest backup in the default folder
created using the Robocopy command.

.EXAMPLE
PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MyNas\PlexBackup\20190101183015"
Restores Plex application data from a backup in the specified remote folder.

.EXAMPLE
Get-Help .\PlexBackup.ps1
View help information.
#>
#------------------------[ RUN-TIME REQUIREMENTS ]-------------------------

#Requires -Version 4.0
#Requires -RunAsAdministrator

#------------------------[ COMMAND-LINE SWITCHES ]-------------------------

# Script command-line arguments (see descriptions in the .PARAMETER comments above).
param
(
    [ValidateSet("Backup", "Continue", "Restore")]
    [string]
    $Mode = "Backup",
    [string]
    $BackupDirPath = $null,
    [string]
    $BackupRootDir = "C:\PlexBackup",
    [string]
    $PlexAppDataDir = "$env:LOCALAPPDATA\Plex Media Server",
    [string]
    $TempZipFileDir = $env:TEMP,
    [string]
    $ConfigFile = $null,
    [switch]
    $Robocopy = $false,
    [int]
    $Retries = 2,
    [int]
    $RetryWaitSec = 10,
    [switch]
    $Shutdown = $false
)

#-----------------------------[ DECLARATIONS ]-----------------------------

# The following Plex application folders do not need to be backed up.
$ExcludePlexAppDataDirs = @("Diagnostics", "Crash Reports", "Updates", "Logs")

# Regular expression used to find display names of the Plex Windows service(s).
$PlexServiceNameMatchString = "^Plex"

# Name of the Plex Media Server executable file.
$PlexServerExeFileName = "Plex Media Server.exe"

# If Plex Media Server is not running, define path to the executable here.
$PlexServerExePath = $null

# Number of backups to retain: 
# 0 - retain all previously created backups,
# 1 - latest backup only,
# 2 - latest and one before it,
# 3 - latest and two before it, 
# and so on.
$RetainBackups = 3

# DO NOT CHANGE THE FOLLOWING SETTINGS:

# Plex registry key path.
$PlexRegKey = "HKCU\Software\Plex, Inc.\Plex Media Server"

# Backup folder format: YYYYMMDDhhmmss
$RegexBackupDirNameFormat = "^\d{14}$"

# Format of the backup folder name (so it can be easily sortable).
$BackupDirNameFormat = "yyyyMMddHHmmss"

# Extension of config file.
$ConfigFileExt = ".json"

# Subfolders in the backup directory.
$SubDirFiles    = "0"
$SubDirFolders  = "1"
$SubDirRegistry = "2"
$SubDirSpecial  = "3"

# Name of the common backup files.
$BackupFileName = "Plex"

# File extensions.
$ZipFileExt = ".zip"
$RegFileExt = ".reg"

# Subfolders that cannot be archived because the path may be too long.
# Long (over 260 characters) paths cause Compress-Archive to fail,
# so before running the archival steps, we will move these folders to
# the backup directory, and copy it back once the archival step completes.
# On restore, we'll copy these folders from the backup directory to the
# Plex app data folder.
$SpecialPlexAppDataSubDirs = 
@(
    "Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated"
)

#------------------------------[ FUNCTIONS ]-------------------------------

function GetTimestamp
{
    return $(Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
}

function InitConfig
{
    # If config file is specified, check if it exists.
    if ($script:ConfigFile)
    {
        if (!(Test-Path -Path $script:ConfigFile -PathType Container))
        {
            Write-Host "Config file:" -ForegroundColor Red
            Write-Host " " $script:ConfigFile -ForegroundColor Red
            Write-Host "not found." -ForegroundColor Red

            return $false
        }
    }
    # If config file is not specified, check if the default config file exists.
    else
    {
        # Default config file is named after running script with .json extension.
        $script:ConfigFile = $PSCommandPath + $script:ConfigFileExt

        # Default config file is optional.
        if (!(Test-Path -Path $script:ConfigFile -PathType Leaf))
        {
            return $true
        }
    }

    Write-Host "Loading configuration settings from:"
    Write-Host " " $script:ConfigFile

    $Error.Clear()

    $config = Get-Content $script:ConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |
            ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
    
    if ($Error.Count -gt 0)
    {
        return $false
    }

    if (!$config)
    {
        return $true
    }

    # Overwrite settings if the corresponding values are not null/empty/false in the config file.
    if ($config.Mode) { $script:Mode = $config.Mode }
    if ($config.BackupDirPath) { $script:BackupDirPath = $config.BackupDirPath }
    if ($config.BackupRootDir) { $script:BackupRootDir = $config.BackupRootDir }
    if ($config.PlexAppDataDir) { $script:PlexAppDataDir = $config.PlexAppDataDir }
    if ($config.PlexRegKey) { $script:PlexRegKey = $config.PlexRegKey }
    if ($config.ExcludePlexAppDataDirs) { $script:ExcludePlexAppDataDirs = $config.ExcludePlexAppDataDirs }
    if ($config.SpecialPlexAppDataSubDirs) { $script:SpecialPlexAppDataSubDirs = $config.SpecialPlexAppDataSubDirs }
    if ($config.PlexServiceNameMatchString) { $script:PlexServiceNameMatchString = $config.PlexServiceNameMatchString }
    if ($config.PlexServerExeFileName) { $script:PlexServerExeFileName = $config.PlexServerExeFileName }
    if ($config.PlexServerExePath) { $script:PlexServerExePath = $config.PlexServerExePath }
    if ($config.RetainBackups) { $script:RetainBackups = $config.RetainBackups }
    if ($config.Robocopy) { $script:Robocopy = $config.Robocopy }
    if ($config.Retries) { $script:Retries = $config.Retries }
    if ($config.RetryWaitSec) { $script:RetryWaitSec = $config.RetryWaitSec }
    if ($config.Shutdown) { $script:Shutdown = $config.Shutdown }

    # Overwrite settings if the corresponding values are not null in the config file.
    if ($config.TempZipFileDir -ne $null) { $script:TempZipFileDir = $config.TempZipFileDir }

    return $true
}

function GetLastBackupDirPath
{
    param
    (
        [string]
        $backupRootDir,
        [string]
        $regexBackupDirNameFormat
    )

    # Get all folders with names from newest to oldest.
    $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory | 
        Where-Object { $_.Name -match $regexBackupDirNameFormat } | 
            Sort-Object -Descending

    if ($oldBackupDirs.Count -lt 1)
    {
        return $null
    }
    
    return $oldBackupDirs[0].FullName
}

function GetPlexMediaServerExePath
{
    param
    (
        [string]
        $path,
        [string]
        $name
    )

    # Get path of the Plex Media Server executable.
    if (!$path)
    {
        $path = Get-Process | 
            Where-Object {$_.Path -match $name + "$" } | 
                Select-Object -ExpandProperty Path
    }

    # Make sure we got the Plex Media Server executable file path.
    if (!$path)
    {
        Write-Host "Cannot determine path of the the Plex Media Server executable file." -ForegroundColor Red
        Write-Host "Please make sure Plex Media Server is running." -ForegroundColor Red
        return $false, $null
    }

    # Verify that the Plex Media Server executable file exists.
    if (!(Test-Path -Path $path -PathType Leaf))
    {
        Write-Host "Plex Media Server executable file at:" -ForegroundColor Red
        Write-Host " " $path -ForegroundColor Red
        Write-Host "does not exist." -ForegroundColor Red
        return $false, $null
    }

    return $true, $path
}

function GetRunningPlexServices
{
    param
    (
        [string]
        $displayNameSearchString
    )

    return Get-Service | 
        Where-Object {$_.DisplayName -match $displayNameSearchString} | 
            Where-Object {$_.status -eq 'Running'}
}

function StopPlexServices
{
    param
    (
        [object[]]
        $services
    )

    # We'll keep track of every Plex service we successfully stopped.
    $stoppedPlexServices = [System.Collections.ArrayList]@()

    if ($services.Count -gt 0)
    {
        Write-Host "Stopping Plex service(s):"
        foreach ($service in $services)
        {
            Write-Host " " $service.DisplayName
            Stop-Service -Name $service.Name -Force

            if ($Error.Count -gt 0)
            {
                return $false, $null
            }

            $i = $stoppedPlexServices.Add($service)
        }
    }

    return $true, $stoppedPlexServices
}

function StartPlexServices
{
    param
    (
        [object[]]
        $services
    )

    if (!$services)
    {
        return
    }

    if ($services.Count -le 0)
    {
        return
    }

    Write-Host "Starting Plex service(s):"

    foreach ($service in $services)
    {
        Write-Host " " $service.DisplayName
        Start-Service -Name $service.Name
    }
}

function StopPlexMediaServer
{
    param
    (
        [string]
        $plexServerExeFileName,
        [string]
        $plexServerExePath
    )
    
    $Error.Clear()

    # If we have the path to Plex Media Server executable, see if it's running.
    $exeFileName = $plexServerExeFileName

    if ($plexServerExePath)
    {
        $exeFileName = Get-Process | 
            Where-Object {$_.Path -eq $plexServerExePath } | 
		        Select-Object -ExpandProperty Name
    }
    # If we do not have the path, use the file name to see if the process is running.
    else
    {
        $plexServerExePath = Get-Process | 
            Where-Object {$_.Path -match $plexServerExeFileName + "$" } | 
                Select-Object -ExpandProperty Path
    }

    # Stop Plex Media Server executable (if it is running).
    if ($exeFileName -and $plexServerExePath)
    {
        Write-Host "Stopping Plex Media Server process:"
        Write-Host " " $plexServerExeFileName
        taskkill /f /im $plexServerExeFileName /t >$nul 2>&1
    }

    if ($Error.Count -gt 0)
    {
        return $false
    }

    return $true
}

function StartPlexMediaServer
{
    param
    (
        [string]
        $plexServerExeFileName,
        [string]
        $plexServerExePath
    )
    
    $Error.Clear()

    # Get name of the Plex Media Server executable (just to see if it is running).
    $plexServerExeFileName = Get-Process | 
        Where-Object {$_.Path -match $plexServerExeFileName + "$" } | 
            Select-Object -ExpandProperty Name

    # Start Plex Media Server executable (if it is not running).
    if (!$plexServerExeFileName -and $plexServerExePath)
    {
        Write-Host "Starting Plex Media Server process:"
        Write-Host " " $plexServerExePath
        Start-Process $plexServerExePath
    }
}

function CopyFolder
{
    param
    (
        [string]
        $source,
        [string]
        $destination
    )

    if (!(Test-Path -Path $source -PathType Container))
    {
        Write-Host "Source folder:"
        Write-Host " " $source
        Write-Host "does not exist; skipping."

        return $true
    }

    Write-Host "Copying folder:"
    Write-Host " " $source
    Write-Host "to:"
    Write-Host " " $destination
    Write-Host "at:"
    Write-Host " " (GetTimestamp)

    robocopy $source $destination *.* /e /is /it *>&1 | Out-Null

    if ($LASTEXITCODE -gt 7)
    {
        Write-Host "Robocopy failed with error code:" -ForegroundColor Red
        Write-Host " " $LASTEXITCODE
        Write-Host "To troubleshoot, execute the following command:" -ForegroundColor Red
        Write-Host "robocopy $source $destination *.* /e /is /it" -ForegroundColor Red

        returnd $false
    }
    
    Write-Host "Completed at:"
    Write-Host " " (GetTimestamp)

    return $true
}

function MoveFolder
{
    param
    (
        [string]
        $source,
        [string]
        $destination
    )

    if (!(Test-Path -Path $source -PathType Container))
    {
        Write-Host "Source folder:"
        Write-Host " " $source
        Write-Host "does not exist; skipping."

        return $true
    }

    Write-Host "Moving folder:"
    Write-Host " " $source
    Write-Host "to:"
    Write-Host " " $destination
    Write-Host "at:"
    Write-Host " " (GetTimestamp)

    robocopy $source $destination *.* /e /is /it /move *>&1 | Out-Null

    if ($LASTEXITCODE -gt 7)
    {
        Write-Host "Robocopy failed with error code:" -ForegroundColor Red
        Write-Host " " $LASTEXITCODE
        Write-Host "To troubleshoot, execute the following command:" -ForegroundColor Red
        Write-Host "robocopy $source $destination *.* /e /is /it /move" -ForegroundColor Red

        returnd $false
    }
    
    Write-Host "Completed at:"
    Write-Host " " (GetTimestamp)

    return $true
}

function BackupSpecialSubDirs
{
    param
    (
        [string[]]
        $specialPlexAppDataSubDirs,
        [string]
        $plexAppDataDir,
        [string]
        $backupDirPath
    )

    if (!($specialPlexAppDataSubDirs) -or 
         ($specialPlexAppDataSubDirs.Count -eq 0))
    {
        retrun $true
    }

    Write-Host "Backing up special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs)
    {
        $source = Join-Path $plexAppDataDir $specialPlexAppDataSubDir
        $destination = Join-Path $backupDirPath $specialPlexAppDataSubDir
      
        if (!(MoveFolder $source $destination))
        {
            return $false
        }
    }

    return $true
}

function RestoreSpecialSubDirs
{
    param
    (
        [string[]]
        $specialPlexAppDataSubDirs,
        [string]
        $plexAppDataDir,
        [string]
        $backupDirPath
    )

    if (!($specialPlexAppDataSubDirs) -or 
         ($specialPlexAppDataSubDirs.Count -eq 0))
    {
        retrun $true
    }

    Write-Host "Restoring special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs)
    {
        $source = Join-Path $backupDirPath $specialPlexAppDataSubDir
        $destination = Join-Path $plexAppDataDir $specialPlexAppDataSubDir
      
        if (!(CopyFolder $source $destination))
        {
            return $false
        }
    }

    return $true
}

function DecompressPlexAppDataFolder
{
    param
    (
        [object]
        $backupZipFile,
        [string]
        $backupDirPath,
        [string]
        $plexAppDataDir,
        [string]
        $tempZipFileDir,
        [string]
        $zipFileExt
    )
    
    $backupZipFileName = $backupZipFile.Name
    $backupZipFilePath = $backupZipFile.FullName

    $plexAppDataDirName = $backupZipFile.BaseName
    $plexAppDataDirPath = Join-Path $plexAppDataDir $plexAppDataDirName

    $Error.Clear()

    # If we have a temp folder, stage the extracting job.
    if ($tempZipFileDir)
    {
        $tempZipFileName= (New-Guid).Guid + $zipFileExt
        
        $tempZipFilePath= Join-Path $tempZipFileDir $tempZipFileName
    
        # Copy backup archive to a temp zip file.
        Write-Host "Copying backup archive file:"
        Write-Host " " $backupZipFileName
        Write-Host "from:"
        Write-Host " " $backupDirPath
        Write-Host "to a temp zip file:"
        Write-Host " " $tempZipFileName
        Write-Host "in:"
        Write-Host " " $tempZipFileDir
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Start-BitsTransfer -Source $backupZipFilePath -Destination $tempZipFilePath

        if ($Error.Count -gt 0)
        {
            return $false
        }

        Write-Host "Completed at:"
        Write-Host " " (GetTimestamp)

        Write-Host "Restoring Plex app data from:"
        Write-Host " " $tempZipFileName
        Write-Host "in:"
        Write-Host " " $tempZipFileDir
        Write-Host "to Plex app data folder:"
        Write-Host " " $plexAppDataDirName
        Write-Host "in:"
        Write-Host " " $plexAppDataDir
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Expand-Archive -Path $tempZipFilePath -DestinationPath $plexAppDataDirPath -Force

        if ($Error.Count -gt 0)
        {
            return $false
        }

        Write-Host "Completed at:"
        Write-Host " " (GetTimestamp)
         
        # Delete temp file.
        Write-Host "Deleting temp file:"
        Write-Host " " $tempZipFileName
        Write-Host "from:"
        Write-Host " " $tempZipFileDir
        Remove-Item $tempZipFilePath -Force

        $Error.Clear()
    }
    # If we don't have a temp folder, restore archive in the Plex app data folder.
    else 
    {
        Write-Host "Restoring Plex app data from:"
        Write-Host " " $backupZipFileName
        Write-Host "in:"
        Write-Host " " $backupDirPath
        Write-Host "to Plex app data folder:"
        Write-Host " " $plexAppDataDirName
        Write-Host "in:"
        Write-Host " " $plexAppDataDir
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Expand-Archive -Path $backupZipFilePath -DestinationPath $plexAppDataDirPath -Force

        if ($Error.Count -gt 0)
        {
            return $false
        }

        Write-Host "Completed at:"
        Write-Host " " (GetTimestamp)
    }

    return $true
}

function DecompressPlexAppData
{
    param
    (
        [string]
        $plexAppDataDir,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string]
        $backupFileName,
        [string]
        $zipFileExt,
        [string]
        $subDirFiles,
        [string]
        $subDirFolders
    )

    # Build path to the ZIP file that holds files from Plex app data folder.
    $zipFileName = $backupFileName + $zipFileExt
    $zipFileDir  = Join-Path $backupDirPath $subDirFiles
    $zipFilePath = Join-Path $zipFileDir $zipFileName

    if (Test-Path -Path $zipFilePath -PathType Leaf)
    {
        Write-Host "Restoring Plex app data files from:"
        Write-Host " " $zipFileName
        Write-Host "in:"
        Write-Host " " $zipFileDir
        Write-Host "to:" 
        Write-Host " " $plexAppDataDir
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Expand-Archive -Path $zipFilePath -DestinationPath $plexAppDataDir -Force

        if ($Error.Count -gt 0)
        {
            return $false
        }

        Write-Host "Completed at:"
        Write-Host " " (GetTimestamp)
    }

    Write-Host "Restoring Plex app data folders from:"
    Write-Host " " (Join-Path $backupDirPath $subDirFolders)

    $backupZipFiles = Get-ChildItem `
        (Join-Path $backupDirPath $subDirFolders) -File  | 
            Where-Object { $_.Extension -eq $zipFileExt }

    foreach ($backupZipFile in $backupZipFiles)
    {
        if (!(DecompressPlexAppDataFolder `
                $backupZipFile `
                (Join-Path $backupDirPath $subDirFolders) `
                $plexAppDataDir `
                $tempZipFileDir `
                $zipFileExt))
        {
            return $false
        }
    }

    return $true
}

function CompressPlexAppDataFolder
{
    param
    (
        [object]
        $sourceDir,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string]
        $zipFileExt
    )
    
    $backupZipFileName = $sourceDir.Name + $zipFileExt
    $backupZipFilePath = Join-Path $backupDirPath $backupZipFileName

    Write-Host "Archiving subfolder:"
    Write-Host " " $sourceDir.Name

    if (Test-Path $backupZipFilePath -PathType Leaf)
    {
        Write-Host "Backup archive:"
        Write-Host " " $backupZipFileName
        Write-Host "already exists in:"
        Write-Host " " $backupDirPath
        Write-Host "Skipping."
        
        return $true   
    }

    if ($tempZipFileDir)
    {
        $tempZipFileName= (New-Guid).Guid + $zipFileExt

        $tempZipFilePath= Join-Path $tempZipFileDir $tempZipFileName

        Write-Host "Creating temp archive file:"
        Write-Host " " $tempZipFileName
        Write-Host "in:"
        Write-Host " " $tempZipFileDir
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $tempZipFilePath

        if ($Error.Count -gt 0)
        {
            return $false
        }

        Write-Host "Completed at:"
        Write-Host " " (GetTimestamp)

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $tempZipFilePath -PathType Leaf))
        {
            Write-Host "Subfolder is empty; skipping."
        }
        else
        {
            # Copy temp ZIP file to the backup folder.
            Write-Host "Copying temp archive file:"
            Write-Host " " $tempZipFileName
            Write-Host "from:"
            Write-Host " " $tempZipFileDir
            Write-Host "to:"
            Write-Host " " $backupZipFileName
            Write-Host "in:"
            Write-Host " " $backupDirPath
            Write-Host "at:"
            Write-Host " " (GetTimestamp)

            Start-BitsTransfer -Source $tempZipFilePath -Destination $backupZipFilePath
                      
            if ($Error.Count -gt 0)
            {
                return $false
            }

            Write-Host "Completed at:"
            Write-Host " " (GetTimestamp)

            # Delete temp file.
            Write-Host "Deleting temp archive file:"
            Write-Host " " $tempZipFileName
            Write-Host "from:"
            Write-Host " " $tempZipFileDir
            Remove-Item $tempZipFilePath -Force

            $Error.Clear()
       }
    }
    # If we don't have a temp folder, create an archive in the destination folder.
    else 
    {
        Write-Host "Creating archive file:"
        Write-Host " " $backupZipFileName
        Write-Host "in:"
        Write-Host " " $backupDirPath
        Write-Host "at:"
        Write-Host " " (GetTimestamp)

        Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $backupZipFilePath

        if ($Error.Count -gt 0)
        {
            return $false
        }

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $backupZipFilePath -PathType Leaf))
        {
            Write-Host "Subfolder is empty; skipping."
        }
        else
        {
            Write-Host "Completed at:"
            Write-Host " " (GetTimestamp)
        }
    }

    return $true
}

function RobocopyPlexAppData
{
    param
    (
        [string]
        $source,
        [string]
        $destination,
        [string[]]
        $excludeDirs,
        [int]
        $retries,
        [int]
        $retryWaitSec
    )

    Write-Host "Copying Plex app data files from:"
    Write-Host " " $source
    Write-Host "to:"
    Write-Host " " $destination
    Write-Host "at:"
    Write-Host " " (GetTimestamp)

    Write-Host "THIS OPERATION IS LONG: IT MAY TAKE HOURS."
    Write-Host "THERE WILL BE NO FEEDBACK UNLESS SOMETHING GOES WRONG."
    Write-Host "IF YOU GET WORRIED, USE TASK MANAGER TO CHECK CPU/DISK USAGE."
    Write-Host "OTHERWISE, TAKE A BREAK AND COME BACK LATER."
    Write-Host "Robocopy is running quietly..."

    # Build full paths to the excluded folders.
    $excludePaths = $null

    if (($excludeDirs) -and ($excludeDirs.Count -gt 0))
    {
        $excludePaths = [System.Collections.ArrayList]@()

        foreach ($excludeDir in $excludeDirs)
        {
            $i = $excludePaths.Add((Join-Path $source $excludeDir))
        }

        robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT /XD $excludePaths
    }
    else
    {
        robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT
    }

    if ($LASTEXITCODE -gt 7)
    {
        Write-Host "Robocopy failed with error code:" -ForegroundColor Red
        Write-Host " " $LASTEXITCODE
        Write-Host "To troubleshoot, execute the following command:" -ForegroundColor Red

        if (($excludePaths) -and ($excludePaths.Count -gt 0))
        {
            Write-Host "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT /XD $excludePaths" -ForegroundColor Red
        }
        else
        {
            Write-Host "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT" -ForegroundColor Red
        }

        returnd $false
    }
    
    Write-Host "Completed at:"
    Write-Host " " (GetTimestamp)

    return $true
}

function CompressPlexAppData
{
    param
    (
        [string]
        $plexAppDataDir,
        [string[]]
        $excludePlexAppDataDirs,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string]
        $backupFileName,
        [string]
        $zipFileExt,
        [string]
        $subDirFiles,
        [string]
        $subDirFolders
    )

    # Build path to the ZIP file that will hold files from Plex app data folder.
    $zipFileName = $backupFileName + $zipFileExt
    $zipFileDir  = Join-Path $backupDirPath $subDirFiles
    $zipFilePath = Join-Path $zipFileDir $zipFileName

    Write-Host "Backing up Plex app data files from:"
    Write-Host " " $plexAppDataDir
    Write-Host "to:"
    Write-Host " " $zipFileName
    Write-Host "in:"
    Write-Host " " $zipFileDir
    Write-Host "at:"
    Write-Host " " (GetTimestamp)

    if (Test-Path $zipFilePath -PathType Leaf)
    {
        Write-Host "Backup file already exists; skipping."
    }
    else
    {
        Get-ChildItem -File "$plexAppDataDir" | 
            Compress-Archive -DestinationPath $zipFilePath -Update

        if ($Error.Count -gt 0)
        {
            return $false
        }

        if (Test-Path $zipFilePath -PathType Leaf)
        {
            Write-Host "Completed at:"
            Write-Host " " (GetTimestamp)
        }
        else
        {
            Write-Host "No files found; skipping."
        }
     }

    Write-Host "Backing up Plex app data folders from:"
    Write-Host " " $plexAppDataDir
    Write-Host "to:"
    Write-Host " " (Join-Path $backupDirPath $subDirFolders)

    $plexAppDataSubDirs = Get-ChildItem $plexAppDataDir -Directory  | 
        Where-Object { $_.Name -notin $excludePlexAppDataDirs }

    foreach ($plexAppDataSubDir in $plexAppDataSubDirs)
    {
        if (!(CompressPlexAppDataFolder `
                $plexAppDataSubDir `
                (Join-Path $backupDirPath $subDirFolders) `
                $tempZipFileDir `
                $zipFileExt))
        {
            return $false
        }
    }

    return $true
}

function RestorePlexFromBackup
{
    param
    (
        [string]
        $plexAppDataDir,
        [string]
        $plexRegKey,
        [string]
        $backupDirPath,
        [string]
        $backupRootDir,
        [string]
        $tempZipFileDir,
        [string]
        $specialPlexAppDataSubDirs,
        [string]
        $regexBackupDirNameFormat,
        [string]
        $backupDirNameFormat,
        [string]
        $subDirFiles,
        [string]
        $subDirFolders,
        [string]
        $subDirRegistry,
        [string]
        $subDirSpecial,
        [string]
        $backupFileName,
        [string]
        $zipFileExt,
        [string]
        $regFileExt,
        [bool]
        $robocopy,
        [int]
        $retries,
        [int]
        $retryWaitSec
    )
    $Error.Clear()

    # Make sure the backup root folder exists.
    if (!(Test-Path $backupRootDir -PathType Container))
    {
        Write-Host "Backup root folder:" -ForegroundColor Red
        Write-Host " " $backupDirPath -ForegroundColor Red
        Write-Host "does not exist." -ForegroundColor Red
        
        return $false
    }

    # If the backup folder is not specified, use the latest timestamped
    # folder under the backup directory defined at the top of the script.
    if (!$backupDirPath)
    {
        $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat

        if (!($backupDirPath))
        {
            Write-Host "No backup folder matching timestamp format:" -ForegroundColor Red
            Write-Host " " $backupDirNameFormat -ForegroundColor Red
            Write-Host "found under:" -ForegroundColor Red
            Write-Host " " $backupRootDir -ForegroundColor Red

            return $false
        }
    }

    # Make sure the backup folder exists.
    if (!(Test-Path $backupDirPath -PathType Container))
    {
        Write-Host "Backup folder:" -ForegroundColor Red
        Write-Host " " $backupDirPath -ForegroundColor Red
        Write-Host "does not exist." -ForegroundColor Red
        
        return $false
    }

    if ($robocopy)
    {
        if (!(RobocopyPlexAppData `
                (Join-Path $backupDirPath $subDirFiles) `
                $plexAppDataDir `
                $null `
                $retries `
                $retryWaitSec))
        {
            return $false
        }
    }
    else
    { 
       if (!(DecompressPlexAppData `
                $plexAppDataDir `
                $backupDirPath `
                $tempZipFileDir `
                $backupFileName `
                $zipFileExt `
                $subDirFiles `
                $subDirFolders))
        {
            return $false
        }

        # Restore special subfolders.
        if (!(RestoreSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial)))
        {
            return $false
        }
    }

    # Import Plex registry key.
    $backupRegKeyFilePath = (Join-Path (Join-Path `
        $backupDirPath $subDirRegistry) ($backupFileName + $regFileExt))

    if (!(Test-Path $backupRegKeyFilePath -PathType Leaf))
    {
        Write-Host "Backup registry key file:"
        Write-Host " " ($backupFileName + $regFileExt)
        Write-Host "in:"
        Write-Host " " (Join-Path $backupDirPath $subDirRegistry)
        Write-Host "is not found."
        Write-Host "Plex Windows registry key will not be restored."
    }
    else
    {
        Write-Host "Restoring Plex Windows registry key from file:"
        Write-Host " " ($backupFileName + $regFileExt)
        Write-Host "in:"
        Write-Host " " (Join-Path $backupDirPath $subDirRegistry)

        Invoke-Command {reg import $backupRegKeyFilePath *>&1 | Out-Null}
    }

    return $true
}

function CreatePlexBackup
{
    param
    (
        [string]
        $mode,
        [string]
        $plexAppDataDir,
        [string]
        $plexRegKey,
        [string]
        $backupRootDir,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string[]]
        $excludePlexAppDataDirs,
        [string[]]
        $specialPlexAppDataSubDirs,
        [int]
        $retainBackups,
        [string]
        $regexBackupDirNameFormat,
        [string]
        $backupDirNameFormat,
        [string]
        $subDirFiles,
        [string]
        $subDirFolders,
        [string]
        $subDirRegistry,
        [string]
        $subDirSpecial,
        [string]
        $backupFileName,
        [string]
        $zipFileExt,
        [string]
        $regFileExt,
        [bool]
        $robocopy,
        [int]
        $retries,
        [int]
        $retryWaitSec
    )

    $Error.Clear()

    # If we are continuing backup...
    if ($mode -eq "Continue")
    {
        # If backup folder path is not provided, get the latest timestamped folder
        # from the backup root folder.
        if (!($backupDirPath))
        {
            $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat

            if (!($backupDirPath))
            {
                Write-Host "No backup folder matching timestamp format:" -ForegroundColor Red
                Write-Host " " $backupDirNameFormat -ForegroundColor Red
                Write-Host "found under:" -ForegroundColor Red
                Write-Host " " $backupRootDir -ForegroundColor Red

                return $false
            }
        }
        # If backup folder path is provided, verify that it exists.
        else
        {
            if (!(Test-Path $backupRootDir -PathType Container))
            {
                Write-Host "Backup folder:" -ForegroundColor Red
                Write-Host " " $backupRootDir -ForegroundColor Red
                Write-Host "does not exist." -ForegroundColor Red

                return $false
            }
        }
    }
    # If we are creating a new backup...
    else
    {
        # Get current timestamp that will be used as a backup folder.
        $backupDirName = (Get-Date).ToString($backupDirNameFormat)

        # Make sure that the backup parent folder exists.
        New-Item -Path $backupRootDir -ItemType Directory -Force | Out-Null

        # Verify that we got the backup parent folder.
        if (!(Test-Path $backupRootDir -PathType Container))
        {
            Write-Host "Backup folder:"  -ForegroundColor Red
            Write-Host " " $backupRootDir -ForegroundColor Red
            Write-Host "does not exist and cannot be created." -ForegroundColor Red

            return $false
        }
    
        $Error.Clear()

        # Build backup folder path.
        $backupDirPath = Join-Path $backupRootDir $backupDirName
        Write-Host "New backup will be created under:"
        Write-Host " " $backupRootDir

        # If the backup folder already exists, rename it by appending 1 
        # (or next sequential number).
        if (Test-Path -Path $backupDirPath -PathType Container)
        {
            $i = 1

            # Parse through all backups of backup folder (with appended counter).
            while (Test-Path -Path $backupDirPath + "." + $i -PathType Container)
            {
                $i++
            }

            Write-Host "Renaming old backup folder to " + $backupDirName + "." + $i + "."
            Rename-Item -Path $backupDirPath -NewName $backupDirName + "." + $i

            if ($Error.Count -gt 0)
            {
                return $false
            }
        }

        # Delete old backup folders.
        if ($retainBackups -gt 0)
        {
            # Get all folders with names from newest to oldest.
            $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory | 
                Where-Object { $_.Name -match $regexBackupDirNameFormat } | 
                    Sort-Object -Descending

            $i = 1

            if ($oldBackupDirs.Count -ge $retainBackups)
            {
                Write-Host "Purging old backup folder(s):"
            }

            foreach ($oldBackupDir in $oldBackupDirs)
            {
                if ($i -ge $retainBackups)
                {
                     Write-Host " " $oldBackupDir.Name
                     Remove-Item $oldBackupDir.FullName -Force -Recurse `
                        -ErrorAction SilentlyContinue         
                }

                $i++
            }
        }

        $Error.Clear()

        # Create new backup folder.
        if (!(Test-Path -Path $backupDirPath -PathType Container))
        {
            Write-Host "Creating new backup folder:"
            Write-Host " " $backupDirName
            New-Item -Path $backupDirPath -ItemType Directory -Force | Out-Null
        }

        if ($Error.Count -gt 0)
        {
            return $false
        }

        # Verify that temp folder exists (if specified).
        if ($tempZipFileDir)
        {
            # Make sure temp folder exists.
            if (!(Test-Path -Path $tempZipFileDir -PathType Container))
            {
                # Create temp folder.
                New-Item -Path $tempZipFileDir -ItemType Directory -Force | Out-Null

                if ($Error.Count -gt 0)
                {
                    Write-Host "Temp archive folder:" -ForegroundColor Red
                    Write-Host " " $tempZipFileDir -ForegroundColor Red
                    Write-Host "does not exist and cannot be created." -ForegroundColor Red

                    return $false
                }
            }
        }
    }

    # Make sure that we have subfolders for files, folders, registry, 
	# and special folder backups.
    $subDirs = @($subDirFiles, $subDirFolders, $subDirRegistry, $subDirSpecial)

    $printMsg = $false
    foreach ($subDir in $subDirs)
    {
        $subDirPath = Join-Path $backupDirPath $subDir

        if (!(Test-Path -Path $subDirPath -PathType Container))
        {
            if (!$printMsg)
            {
                Write-Host "Creating task-specific subfolder(s) in:"
                Write-Host " " $backupDirPath

                $printMsg = $true
            }

            New-Item -Path $subDirPath -ItemType Directory -Force | Out-Null

            if ($Error.Count -gt 0)
            {
                Write-Host "Cannot create subfolder:" -ForegroundColor Red
                Write-Host " " $subDir -ForegroundColor Red
                Write-Host "in backup folder:" -ForegroundColor Red
                Write-Host " " $backupDirPath -ForegroundColor Red

                return $false
            }
        }
    }

    if ($robocopy)
    {
        if (!(RobocopyPlexAppData `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirFiles) `
                $excludePlexAppDataDirs `
                $retries `
                $retryWaitSec))
        {
            return $false
        }
    }
    else
    {
        # Temporarily move special subfolders to backup folder.
        if (!(BackupSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial)))
        {
            RestoreSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial)

            return $false
        }

        # Compress and archive Plex app data.
        if (!(CompressPlexAppData `
                $plexAppDataDir `
                $excludePlexAppDataDirs `
                $backupDirPath `
                $tempZipFileDir `
                $backupFileName `
                $zipFileExt `
                $subDirFiles `
                $subDirFolders))
        {
            if (!(RestoreSpecialSubDirs `
                    $specialPlexAppDataSubDirs `
                    $plexAppDataDir `
                    (Join-Path $backupDirPath $subDirSpecial)))
            {
                return $false
            }
            return $false
        }
    }

    # Export Plex registry key.
    Write-Host "Backing up registry key:"
    Write-Host " " $plexRegKey
    Write-Host "to file:"
    Write-Host " " ($backupFileName + $regFileExt)
    Write-Host "in:"
    Write-Host " " (Join-Path $backupDirPath $subDirRegistry)
    Invoke-Command `
        {reg export $plexRegKey `
            ((Join-Path (Join-Path $backupDirPath $subDirRegistry) `
                ($backupFileName + $regFileExt))) /y *>&1 | 
                    Out-Null}

    # Copy moved special subfolders back to original folders.
    if (!$robocopy)
    {
        if (!(RestoreSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial)))
        {
            return $false
        }
    }

    return $true
}

#---------------------------------[ MAIN ]---------------------------------

# Clear screen.
Clear-Host

$StartTime = Get-Date

Write-Host "Script started at:"
Write-Host " " (GetTimestamp)

if (!(InitConfig))
{
    Write-Host "Script exiting." -ForegroundColor DarkYellow
    return
}

Write-Host "Operation mode:"
Write-Host " " $Mode.ToUpper()

# Determine path to Plex Media Server executable.
$Success, $PlexServerExePath = 
    GetPlexMediaServerExePath $PlexServerExePath $PlexServerExeFileName

if (!$Success)
{
    Write-Host "Script exiting." -ForegroundColor DarkYellow
    return
}

# Get list of all running Plex services (match by display name).
$PlexServices = GetRunningPlexServices $PlexServiceNameMatchString

# Stop all running Plex services.
$Success, $PlexServices = StopPlexServices $PlexServices
if (!$Success)
{
    StartPlexServices $PlexServices
    Write-Host "Script exiting." -ForegroundColor DarkYellow
    return
}

# Stop Plex Media Server executable (if it's still running).
if (!(StopPlexMediaServer $PlexServerExeFileName $PlexServerExePath))
{
    StartPlexServices $PlexServices
    Write-Host "Script exiting." -ForegroundColor DarkYellow
    return
}

# Restore Plex app data from backup.
if ($Mode -eq "Restore")
{
    $Success = RestorePlexFromBackup `
        $PlexAppDataDir `
        $PlexRegKey `
        $BackupDirPath `
        $BackupRootDir `
        $TempZipFileDir `
        $SpecialPlexAppDataSubDirs `
        $RegexBackupDirNameFormat `
        $BackupDirNameFormat `
        $SubDirFiles `
        $SubDirFolders `
        $SubDirRegistry `
        $SubDirSpecial `
        $BackupFileName `
        $ZipFileExt `
        $RegFileExt `
        $Robocopy `
        $Retries `
        $RetryWaitSec
}
# Back up Plex app data.
else
{
    $Success = CreatePlexBackup `
        $Mode `
        $PlexAppDataDir `
        $PlexRegKey `
        $BackupRootDir `
        $BackupdDirPath `
        $TempZipFileDir `
        $ExcludePlexAppDataDirs `
        $SpecialPlexAppDataSubDirs `
        $RetainBackups `
        $RegexBackupDirNameFormat `
        $BackupDirNameFormat `
        $SubDirFiles `
        $SubDirFolders `
        $SubDirRegistry `
        $SubDirSpecial `
        $BackupFileName `
        $ZipFileExt `
        $RegFileExt `
        $Robocopy `
        $Retries `
        $RetryWaitSec
}

# Start all previously running Plex services (if any).
StartPlexServices $PlexServices

# Start Plex Media Server (if it's not running).
if (!($Shutdown))
{
    StartPlexMediaServer $PlexServerExeFileName $PlexServerExePath
}

Write-Host "Script ended at:"
Write-Host " " (GetTimestamp)

$EndTime = Get-Date

Write-Host "Script ran for (hr:min:sec.msec):"
Write-Host " " (New-TimeSpan –Start $StartTime –End $EndTime).ToString("hh\:mm\:ss\.fff")

Write-Host "Script returned:"
if ($Success)
{
    Write-Host " " "SUCCESS"
}
else
{
    Write-Host " " "ERROR"
}
