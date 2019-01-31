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
and global variables inline or specify them in a config file. 

The config file must use the JSON format. Not every script variable can be 
specified in the config file (for the list of overridable variables, see the 
InitConfig function or a sample config file). Only non-null values from config
file will be used. The default config file is named after the running script 
with the '.json' extension, such as: PlexBackup.ps1.json. You can specify a 
custom config file via the -ConfigFile command-line switch. Config file is 
optional. All config values in the config file are optional. The non-null 
config file settings override the default and command-line paramateres, e.g. 
if the command-line -Mode switch is set to 'Backup' and the corresponding 
element in the config file is set to 'Restore' then the script will run in the 
Restore mode.

This script must run as an administrator. 

The execution policy must allow running scripts. To check execution policy,
run the following command: 

  Get-ExecutionPolicy

If the execution policy does not allow running scripts, do the following:

  (1) Start Windows PowerShell with the "Run as Administrator" option. 
  (2) Run the following command: 

    Set-ExecutionPolicy RemoteSigned

This will allow running unsigned scripts that you write on your local 
computer and signed scripts from Internet.

See also 'Running Scripts' at Microsoft TechNet Library:
https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)

.PARAMETER Mode
Specifies the mode of operation: Backup (default), Continue, or Restore.

.PARAMETER ConfigFile
Path to the optional custom config file. The default config file is named after
the script with the '.json' extension, such as 'PlexBackup.ps1.json'.

.PARAMETER PlexAppDataDir
Location of the Plex Media Server application data folder.

.PARAMETER BackupRootDir
Path to the root backup folder holding timestamped backup subfolders.

.PARAMETER BackupDirPath
When running the script in the Restore mode, holds path to the backup folder
(by default, the subfolder with the most recent timestamp in the name located
in the backup root folder will be used).

.PARAMETER TempZipFileDir
Temp folder used to stage the archiving job (use local drive for efficiency).
To bypass the staging step, set this parameter to null or empty string.

.PARAMETER Keep
Number of old backups to keep: 
# 0 - retain all previously created backups,
# 1 - latest backup only,
# 2 - latest and one before it,
# 3 - latest and two before it, 
# and so on.

.PARAMETER Robocopy
Set this switch to use Robocopy instead of file and folder compression.

.PARAMETER Retries
The number of retries on failed copy operations (corresponds to the Robocopy
/R switch).

.PARAMETER RetryWaitSec
Specifies the wait time between retries in seconds (corresponds to the Robocopy 
/W switch).

.PARAMETER Log
When set to true, informational messages will be written to a log file.
The default log file will be created in the backup folder and will be named 
after this script with the '.log' extension, such as 'PlexBackup.ps1.log'.

.PARAMETER LogFile
Use this switch to specify a custom log file location. When this parameter
is set to a non-null and non-empty value, the '-Log' switch can be omitted.

.PARAMETER LogAppend
Set this switch to appended log entries to the existing log file, if it exists
(by default, the old log file will be overwritten).

.PARAMETER Quiet
Set this switch to supress all log entries sent to a console.

.PARAMETER Shutdown
Set this switch to not start the Plex Media Server process at the end of the 
operation (could be handy for restores, so you can double check that all is
good befaure launching Plex media Server).

.NOTES
Version    : 1.1.0
Author     : Alek Davis
Created on : 2019-01-30

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
PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MYNAS\PlexBackup\20190101183015"
Restores Plex application data from a backup in the specified remote folder.

.EXAMPLE
Get-Help .\PlexBackup.ps1
View help information.
#>
#------------------------[ RUN-TIME REQUIREMENTS ]-------------------------

#Requires -Version 4.0
#Requires -RunAsAdministrator

#------------------------[ COMMAND-LINE SWITCHES ]-------------------------

# Script command-line arguments (see descriptions in the .PARAMETER comments 
# above).
param
(
    [ValidateSet("Backup", "Continue", "Restore")]
    [string]
    $Mode = "Backup",
    [string]
    $ConfigFile = $null,
    [string]
    $PlexAppDataDir = "$env:LOCALAPPDATA\Plex Media Server",
    [string]
    $BackupRootDir = "C:\PlexBackup",
    [string]
    $BackupDirPath = $null,
    [string]
    $TempZipFileDir = $env:TEMP,
    [int]
    $Keep = 3,
    [switch]
    $Robocopy = $false,
    [int]
    $Retries = 5,
    [int]
    $RetryWaitSec = 10,
    [alias("L")]
    [switch]
    $Log = $false,
    [int]
    $LogAppend = 3,
    [string]
    $LogFile,
    [alias("Q")]
    [switch]
    $Quiet = $false,
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

# DO NOT CHANGE THE FOLLOWING SETTINGS:

# Plex registry key path.
$PlexRegKey = "HKCU\Software\Plex, Inc.\Plex Media Server"

# Backup folder format: YYYYMMDDhhmmss
$RegexBackupDirNameFormat = "^\d{14}$"

# Format of the backup folder name (so it can be easily sortable).
$BackupDirNameFormat = "yyyyMMddHHmmss"

# Extension of config file.
$ConfigFileExt = ".json"

#Extension of the log file.
$LogFileExt = ".log"

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

function InitConfig
{
    # If config file is specified, check if it exists.
    if ($script:ConfigFile)
    {
        if (!(Test-Path -Path $script:ConfigFile -PathType Container))
        {
            LogError "Config file:" $false
            LogError (Indent $script:ConfigFile) $false
            LogError "not found." $false

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

    LogMessage "Loading configuration settings from:" $false
    LogMessage (Indent (Split-Path -Path $script:ConfigFile -Leaf)) $false
    LogMessage "in:" $false
    LogMessage (Indent (Split-Path -Path $script:ConfigFile -Parent)) $false

    try
    {
        $config = Get-Content $script:ConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |
                ConvertFrom-Json -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
    }
    catch
    {
        LogException $_

        return $false
    }

    if (!$config)
    {
        return $true
    }

    # Overwrite settings if the corresponding values are not null/empty/false in the config file.
    if ($config.Mode) { $script:Mode = $config.Mode }
    if ($config.PlexAppDataDir) { $script:PlexAppDataDir = $config.PlexAppDataDir }
    if ($config.BackupRootDir) { $script:BackupRootDir = $config.BackupRootDir }
    if ($config.BackupDirPath) { $script:BackupDirPath = $config.BackupDirPath }
    if ($config.PlexRegKey) { $script:PlexRegKey = $config.PlexRegKey }
    if ($config.ExcludePlexAppDataDirs) { $script:ExcludePlexAppDataDirs = $config.ExcludePlexAppDataDirs }
    if ($config.SpecialPlexAppDataSubDirs) { $script:SpecialPlexAppDataSubDirs = $config.SpecialPlexAppDataSubDirs }
    if ($config.PlexServiceNameMatchString) { $script:PlexServiceNameMatchString = $config.PlexServiceNameMatchString }
    if ($config.PlexServerExeFileName) { $script:PlexServerExeFileName = $config.PlexServerExeFileName }
    if ($config.PlexServerExePath) { $script:PlexServerExePath = $config.PlexServerExePath }
    if ($config.Keep) { $script:Keep = $config.Keep }
    if ($config.Robocopy) { $script:Robocopy = $config.Robocopy }
    if ($config.Retries) { $script:Retries = $config.Retries }
    if ($config.RetryWaitSec) { $script:RetryWaitSec = $config.RetryWaitSec }
    if ($config.Log) { $script:Log = $config.Log }
    if ($config.LogAppend) { $script:LogAppend = $config.LogAppend }
    if ($config.LogFile) { $script:LogFile = $config.LogFile }
    if ($config.LogFileExt) { $script:LogFileExt = $config.LogFileExt }
    if ($config.Shutdown) { $script:Shutdown = $config.Shutdown }

    # Overwrite settings if the corresponding values are not null in the config file.
    if ($config.TempZipFileDir -ne $null) { $script:TempZipFileDir = $config.TempZipFileDir }

    return $true
}

function Indent
{
    param
    (
        [string]
        $message,
        [int]
        $indentLevel = 1
    )

    $indents = ""

    if ($message)
    {
        for ($i=0; $i -lt $indentLevel; $i++)
        {
            $indents = $indents + "  "
        }
    }
    else
    {
        $message = ""
    }

    $message = $indents + $message

    return $message
}

function Log
{
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true,
        [System.ConsoleColor]
        $textColor = $Host.ui.RawUI.ForegroundColor
    )

    if ($textColor -eq -1)
    {
        [System.ConsoleColor]$foregroundColor = [System.ConsoleColor]::White
    }
    else
    {
        [System.ConsoleColor]$foregroundColor = $textColor        
    }

    if (!$script:Quiet -and $writeToConsole)
    {
        Write-Host $message -ForegroundColor $foregroundColor
    }
    
    if ($script:Log -and $script:LogFile -and $writeToFile)
    {
        $Error.Clear()
        try
        {
            $message | Out-File $script:LogFile -Append -Encoding utf8
        }
        catch
        {
            # There was a problem writing to a file, so don't use log file.
            $script:Log     = $false
            $script:LogFile = $null

            LogException $_
            $Error.Clear()
        }
    }
}

function LogException
{
    param
    (
        [object]
        $ex,
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    if ((!$script:Quiet) -and ($writeToConsole))
    {
         Write-Error $ex -ErrorAction Continue
    }

    if ($script:Log -and $script:LogFile -and $writeToFile)
    {
        try
        {
            Out-File -FilePath $script:LogFilePath -Append -Encoding utf8 -InputObject $ex
        }
        catch
        {
            # There was a problem writing to a file, so don't use log file.
            $script:Log     = $false
            $script:LogFile = $null

            LogException $_
            $Error.Clear()
        }
    }
}

function LogMessage
{
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    Log $message $writeToFile $writeToConsole
}

function LogError
{
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    Log $message $writeToFile $writeToConsole Red
}

function LogWarning
{
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    Log $message $writeToFile $writeToConsole Yellow
}

function InitLog
{
    if ($script:LogFile)
    {
        $script:Log = $true
    }

    if (!$script:Log)
    {
        return $true
    }

    if (!$script:LogFile)
    {
        $logFileName = (Split-Path -Path $PSCommandpath -Leaf) + ".log"

        $script:LogFile = Join-Path $script:BackupDirPath $logFileName
    }

    $logFileDir  = Split-Path -Path $script:LogFile -Parent
    $logFileName = Split-Path -Path $script:LogFile -Leaf

    if (!$script:LogAppend)
    {
        if (Test-Path -Path $script:LogFile -PathType Leaf)
        {
            try
            {
                Remove-Item -Path $script:LogFile -Force
            }
            catch
            {
                LogError "Cannot delete old log file:" $false
                LogError (Indent $logFileName) $false
                LogError "from:" $false
                LogError (Indent $logFileDir) $false

                LogException $_ $false

                return $false
            }
        } 
    }

    # Make sure log folder exists.
    if (!(Test-Path -Path $logFileDir -PathType Container))
    {
        try
        {
            New-Item -Path $logFileDir -ItemType Directory -Force | Out-Null
        }
        catch
        {
            LogException $_

            return $false;
        }
    }

    return $true
}

function GetTimestamp
{
    return $(Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
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

function GetNewBackupDirName
{
    param
    (
        [string]
        $backupDirNameFormat,
        [DateTime]
        $date = (Get-Date)
    )

    if (!$date)
    {
        $date = Get-Date
    }

    return ($date).ToString($backupDirNameFormat)
}

function GetBackupDirNameAndPath
{
    param
    (
        [string]
        $mode,
        [string]
        $backupRootDir,
        [string]
        $backupdDirNameFormat,
        [string]
        $regexBackupDirNameFormat,
        [string]
        $backupDirPath,
        [DateTime]
        $date = (Get-Date)
    )

    if ($backupDirPath)
    {
        return (Split-Path -Path $backupDirPath -Leaf), $backupDirPath
    }

    if ($mode -ne "Backup")
    {
        $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat
    }

    if ($backupDirPath)
    {
        return (Split-Path -Path $backupDirPath -Leaf), $backupDirPath
    }

    # If we didn't get the backup folder path in the Restore mode, we're in trouble.
    if ($mode -eq "Restore")
    {
        # Looks like we could not find a backup folder.
        return $null, $null
    }

    # For the Backup mode, generate a new timestamp-based folder name.
    $backupDirName = GetNewBackupDirName $backupDirNameFormat $date

    return $backupDirName, (Join-Path $backupRootDir $backupDirName)
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
        LogError "Cannot determine path of the the Plex Media Server executable file."
        LogError "Please make sure Plex Media Server is running."

        return $false, $null
    }

    # Verify that the Plex Media Server executable file exists.
    if (!(Test-Path -Path $path -PathType Leaf))
    {
        LogError "Plex Media Server executable file:"
        LogError (Indent (Split-Path -Path $path -Leaf))
        LogError "does not exist in:"
        LogError (Indent (Split-Path -Path $path -Parent))

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
        LogMessage "Stopping Plex service(s):"

        foreach ($service in $services)
        {
            LogMessage (Indent $service.DisplayName)

            try
            {
                Stop-Service -Name $service.Name -Force
            }
            catch
            {
                LogException $_

                return $false, $stoppedPlexServices
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

    LogMessage "Starting Plex service(s):"

    foreach ($service in $services)
    {
        LogMessage (Indent $service.DisplayName)

        try
        {
            Start-Service -Name $service.Name
        }
        catch
        {
            LogException $_

            # Non-critical error; can continue.
        }
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
        LogMessage "Stopping Plex Media Server process:"
        LogMessage (Indent $plexServerExeFileName)

        try
        {
            taskkill /f /im $plexServerExeFileName /t >$nul 2>&1
        }
        catch
        {
            LogException $_

            return $false
        }
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
        LogMessage "Starting Plex Media Server process:"
        LogMessage (Indent $plexServerExePath)

        try
        {
            Start-Process $plexServerExePath
        }
        catch
        {
            LogException $_
        }
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
        LogWarning "Source folder:"
        LogWarning (Indent $source)
        LogWarning "does not exist; skipping."

        return $true
    }

    LogMessage "Copying folder:"
    LogMessage (Indent $source)
    LogMessage "to:"
    LogMessage (Indent $destination)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    try
    {
        robocopy $source $destination *.* /e /is /it *>&1 | Out-Null
    }
    catch
    {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7)
    {
        LogError "Robocopy failed with error code:"
        LogError (Indent $LASTEXITCODE)
        LogError "To troubleshoot, execute the following command:"
        LogError "robocopy $source $destination *.* /e /is /it"

        return $false
    }
    
    LogMessage "Completed at:"
    LogMessage (Indent (GetTimestamp))

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
        LogWarning "Source folder:"
        LogWarning (Indent $source)
        LogWarning "does not exist; skipping."

        return $true
    }

    LogMessage "Moving folder:"
    LogMessage (Indent $source)
    LogMessage "to:"
    LogMessage (Indent $destination)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    try
    {
        robocopy $source $destination *.* /e /is /it /move *>&1 | Out-Null
    }
    catch
    {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7)
    {
        LogError "Robocopy failed with error code:"
        LogError (Indent $LASTEXITCODE)
        LogError "To troubleshoot, execute the following command:"
        LogError "robocopy $source $destination *.* /e /is /it /move"

        return $false
    }
    
    LogMessage "Completed at:"
    LogMessage (Indent (GetTimestamp))

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

    LogMessage "Backing up special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs)
    {
        $source      = Join-Path $plexAppDataDir $specialPlexAppDataSubDir
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

    LogMessage "Restoring special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs)
    {
        $source      = Join-Path $backupDirPath $specialPlexAppDataSubDir
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
        LogMessage "Copying backup archive file:"
        LogMessage (Indent $backupZipFileName)
        LogMessage "from:"
        LogMessage (Indent $backupDirPath)
        LogMessage "to a temp zip file:"
        LogMessage (Indent $tempZipFileName)
        LogMessage "in:"
        LogMessage (Indent $tempZipFileDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try
        {
            Start-BitsTransfer -Source $backupZipFilePath -Destination $tempZipFilePath
        }
        catch
        {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))

        LogMessage "Restoring Plex app data from:"
        LogMessage (Indent $tempZipFileName)
        LogMessage "in:"
        LogMessage (Indent $tempZipFileDir)
        LogMessage "to Plex app data folder:"
        LogMessage (Indent $plexAppDataDirName)
        LogMessage "in:"
        LogMessage (Indent $plexAppDataDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try
        {
            Expand-Archive -Path $tempZipFilePath -DestinationPath $plexAppDataDirPath -Force
        }
        catch
        {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))
         
        # Delete temp file.
        LogMessage "Deleting temp file:"
        LogMessage (Indent $tempZipFileName)
        LogMessage "from:"
        LogMessage (Indent $tempZipFileDir)

        try
        {
            Remove-Item $tempZipFilePath -Force
        }
        catch
        {
            LogException $_

            # Non-critical error; can continue.
        }
    }
    # If we don't have a temp folder, restore archive in the Plex app data folder.
    else 
    {
        LogMessage "Restoring Plex app data from:"
        LogMessage (Indent $backupZipFileName)
        LogMessage "in:"
        LogMessage (Indent $backupDirPath)
        LogMessage "to Plex app data folder:"
        LogMessage (Indent $plexAppDataDirName)
        LogMessage "in:"
        LogMessage (Indent $plexAppDataDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try
        {
            Expand-Archive -Path $backupZipFilePath -DestinationPath $plexAppDataDirPath -Force
        }
        catch
        {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))
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
        LogMessage "Restoring Plex app data files from:"
        LogMessage (Indent $zipFileName)
        LogMessage "in:"
        LogMessage (Indent $zipFileDir)
        LogMessage "to:" 
        LogMessage (Indent $plexAppDataDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try
        {
            Expand-Archive -Path $zipFilePath -DestinationPath $plexAppDataDir -Force
        }
        catch
        {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))
    }

    LogMessage "Restoring Plex app data folders from:"
    LogMessage (Indent (Join-Path $backupDirPath $subDirFolders))

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

    LogMessage "Archiving subfolder:"
    LogMessage (Indent $sourceDir.Name)

    if (Test-Path $backupZipFilePath -PathType Leaf)
    {
        LogWarning "Backup archive:"
        LogWarning (Indent $backupZipFileName)
        LogWarning "already exists in:"
        LogWarning (Indent $backupDirPath)
        LogWarning "Skipping."
        
        return $true   
    }

    if ($tempZipFileDir)
    {
        $tempZipFileName= (New-Guid).Guid + $zipFileExt

        $tempZipFilePath= Join-Path $tempZipFileDir $tempZipFileName

        LogMessage "Creating temp archive file:"
        LogMessage (Indent $tempZipFileName)
        LogMessage "in:"
        LogMessage (Indent $tempZipFileDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try
        {
            Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $tempZipFilePath
        }
        catch
        {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $tempZipFilePath -PathType Leaf))
        {
            LogWarning "Subfolder is empty; skipping."
        }
        else
        {
            # Copy temp ZIP file to the backup folder.
            LogMessage "Copying temp archive file:"
            LogMessage (Indent $tempZipFileName)
            LogMessage "from:"
            LogMessage (Indent $tempZipFileDir)
            LogMessage "to:"
            LogMessage (Indent $backupZipFileName)
            LogMessage "in:"
            LogMessage (Indent $backupDirPath)
            LogMessage "at:"
            LogMessage (Indent (GetTimestamp))

            try
            {
                Start-BitsTransfer -Source $tempZipFilePath -Destination $backupZipFilePath
            }
            catch
            {
                LogException $_

                return $false
            }

            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))

            # Delete temp file.
            LogMessage "Deleting temp archive file:"
            LogMessage (Indent $tempZipFileName)
            LogMessage "from:"
            LogMessage (Indent $tempZipFileDir)

            try
            {
                Remove-Item $tempZipFilePath -Force
            }
            catch
            {
                LogException $_

                # Non-critical error; can continue.
            }
       }
    }
    # If we don't have a temp folder, create an archive in the destination folder.
    else 
    {
        LogMessage "Creating archive file:"
        LogMessage (Indent $backupZipFileName)
        LogMessage "in:"
        LogMessage (Indent $backupDirPath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $backupZipFilePath

        if ($Error.Count -gt 0)
        {
            return $false
        }

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $backupZipFilePath -PathType Leaf))
        {
            LogWarning "Subfolder is empty; skipping."
        }
        else
        {
            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))
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

    LogMessage "Copying Plex app data files from:"
    LogMessage (Indent $source)
    LogMessage "to:"
    LogMessage (Indent $destination)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    LogWarning "THIS OPERATION IS LONG: IT MAY TAKE HOURS."
    LogWarning "THERE WILL BE NO FEEDBACK UNLESS SOMETHING GOES WRONG."
    LogWarning "IF YOU GET WORRIED, USE TASK MANAGER TO CHECK CPU/DISK USAGE."
    LogWarning "OTHERWISE, TAKE A BREAK AND COME BACK LATER."
    LogMessage "Robocopy is running quietly..."

    # Build full paths to the excluded folders.
    $excludePaths = $null

    try
    {
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
    }
    catch
    {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7)
    {
        LogError "Robocopy failed with error code:" 
        LogError (Indent $LASTEXITCODE)
        LogError "To troubleshoot, execute the following command:"

        if (($excludePaths) -and ($excludePaths.Count -gt 0))
        {
            LogError "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT /XD $excludePaths"
        }
        else
        {
            LogError "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT"
        }

        return $false
    }
    
    LogMessage "Completed at:"
    LogMessage (Indent (GetTimestamp))

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

    LogMessage "Backing up Plex app data files from:"
    LogMessage (Indent $plexAppDataDir)
    LogMessage "to:"
    LogMessage (Indent $zipFileName)
    LogMessage "in:"
    LogMessage (Indent $zipFileDir)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    if (Test-Path $zipFilePath -PathType Leaf)
    {
        LogWarning "Backup file already exists; skipping."
    }
    else
    {
        try
        {
            Get-ChildItem -File "$plexAppDataDir" | 
                Compress-Archive -DestinationPath $zipFilePath -Update
        }
        catch
        {
            LogException $_

            return $false
        }

        if (Test-Path $zipFilePath -PathType Leaf)
        {
            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))
        }
        else
        {
            LogWarning "No files found; skipping."
        }
     }

    LogMessage "Backing up Plex app data folders from:"
    LogMessage (Indent $plexAppDataDir)
    LogMessage "to:"
    LogMessage (Indent (Join-Path $backupDirPath $subDirFolders))

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
        $backupRootDir,
        [string]
        $backupDirName,
        [string]
        $backupDirPath,
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
    # Make sure the backup root folder exists.
    if (!(Test-Path $backupRootDir -PathType Container))
    {
        LogError "Backup root folder:"
        LogError (Indent $backupDirPath)
        LogError "does not exist."
        
        return $false
    }

    # If the backup folder is not specified, use the latest timestamped
    # folder under the backup directory defined at the top of the script.
    if (!$backupDirPath)
    {
        $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat

        if (!($backupDirPath))
        {
            LogError "No backup folder matching timestamp format:"
            LogError (Indent $backupDirNameFormat)
            LogError "found under:"
            LogError (Indent $backupRootDir)

            return $false
        }
    }

    # Make sure the backup folder exists.
    if (!(Test-Path $backupDirPath -PathType Container))
    {
        LogError "Backup folder:"
        LogError (Indent $backupDirPath)
        LogError "does not exist."
        
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
        LogWarning "Backup registry key file:"
        LogWarning (Indent ($backupFileName + $regFileExt))
        LogWarning "in:"
        LogWarning (Indent (Join-Path $backupDirPath $subDirRegistry))
        LogWarning "is not found."
        LogWarning "Plex Windows registry key will not be restored."
    }
    else
    {
        LogMessage "Restoring Plex Windows registry key from file:"
        LogMessage (Indent ($backupFileName + $regFileExt))
        LogMessage "in:"
        LogMessage (Indent (Join-Path $backupDirPath $subDirRegistry))

        try
        {
            reg import $backupRegKeyFilePath *>&1 | Out-Null
        }
        catch
        {
            if ($_.Exception -and 
                $_.Exception.Message -and
                ($_.Exception.Message -match "^The operation completed successfully"))
            {
                # This is a bogus error that only appears in PowerShell ISE, so ignore.
                return $true
            }
            else
            {
                LogException $_
            }

            return $false
        }
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
        $backupDirName,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string[]]
        $excludePlexAppDataDirs,
        [string[]]
        $specialPlexAppDataSubDirs,
        [int]
        $keep,
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

    # Make sure that the backup parent folder exists.
    if (!(Test-Path $backupRootDir -PathType Container))
    {
        try
        {
            LogMessage "Creating backup root folder:"
            LogMessage (Indent $backupRootDir)

            New-Item -Path $backupRootDir -ItemType Directory -Force | Out-Null
        }
        catch
        {
            LogException $_

            return $false
        }
    }

    # Verify that we got the backup parent folder.
    if (!(Test-Path $backupRootDir -PathType Container))
    {
        LogError "Backup folder:"
        LogError (Indent $backupRootDir)
        LogError "does not exist and cannot be created."

        return $false
    }
    
    # Build backup folder path.
    LogMessage "New backup will be created in:"
    LogMessage (Indent $backupDirName)
    LogMessage "under:"
    LogMessage (Indent $backupRootDir)

    # If the backup folder already exists, rename it by appending 1 
    # (or next sequential number).
    if (!$backupDirPath)
    {
        $backupDirPath = Join-Path $backupRootDir $backupDirName
    }

    # Delete old backup folders.
    if ($keep -gt 0)
    {
        # Get all folders with names from newest to oldest.
        $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory | 
            Where-Object { $_.Name -match $regexBackupDirNameFormat } | 
                Sort-Object -Descending

        $i = 1

        if ($oldBackupDirs.Count -ge $keep)
        {
            LogMessage "Deleting old backup folder(s):"
        }

        foreach ($oldBackupDir in $oldBackupDirs)
        {
            if ($i -ge $keep)
            {
                LogMessage (Indent $oldBackupDir.Name)

                try
                {
                    Remove-Item $oldBackupDir.FullName -Force -Recurse
                }
                catch
                {
                    LogError $_

                    # Non-critical error; can continue.
                }  
            }

            $i++
        }
    }

    $Error.Clear()

    # Create new backup folder.
    if (!(Test-Path -Path $backupDirPath -PathType Container))
    {
        LogMessage "Creating backup folder:"
        LogMessage (Indent $backupDirName)

        try
        {
            New-Item -Path $backupDirPath -ItemType Directory -Force | Out-Null
        }
        catch
        {
            LogException $_

            return $false
        }
    }

    # Verify that temp folder exists (if specified).
    if ($tempZipFileDir)
    {
        # Make sure temp folder exists.
        if (!(Test-Path -Path $tempZipFileDir -PathType Container))
        {
            try
            {
                # Create temp folder.
                New-Item -Path $tempZipFileDir -ItemType Directory -Force | Out-Null
            }
            catch
            {
                LogException $_

                LogError "Temp archive folder:"
                LogError (Indent $tempZipFileDir)
                LogError "does not exist and cannot be created."

                return $false
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
                LogMessage "Creating task-specific subfolder(s) in:"
                LogMessage (Indent $backupDirPath)

                $printMsg = $true
            }

            try
            {
                New-Item -Path $subDirPath -ItemType Directory -Force | Out-Null
            }
            catch
            {
                LogError "Cannot create subfolder:"
                LogError (Indent $subDir)
                LogError "in backup folder:"
                LogError (Indent $backupDirPath)

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
    LogMessage "Backing up registry key:"
    LogMessage (Indent $plexRegKey)
    LogMessage "to file:"
    LogMessage (Indent ($backupFileName + $regFileExt))
    LogMessage "in:"
    LogMessage (Indent (Join-Path $backupDirPath $subDirRegistry))

    try
    {
        Invoke-Command `
            {reg export $plexRegKey `
                ((Join-Path (Join-Path $backupDirPath $subDirRegistry) `
                    ($backupFileName + $regFileExt))) /y *>&1 | 
                        Out-Null}
    }
    catch
    {
        LogException $_

        # Non-critical error; can continue.
    }

    $Error.Clear()

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

$ErrorActionPreference = 'Stop'

# Clear screen.
Clear-Host

# Make sure we have no pending errors.
$Error.Clear()

$StartTime = Get-Date

LogMessage "Script started at:" $false
LogMessage (Indent $StartTime) $false

if (!(InitConfig))
{
    LogWarning "Cannot initialize run-time configuration settings." $false
    return
}

# Get the name and path of the backup directory.
$BackupDirName, $BackupDirPath = 
    GetBackupDirNameAndPath `
        $Mode `
        $BackupRootDir `
        $BackupdDirNameFormat `
        $RegexBackupDirNameFormat `
        $BackupDirPath `
        $StartTime

if ((!$BackupDirName) -or (!$BackupDirPath))
{
    LogError "Cannot determine location of the backup folder." $false
    return
}

if (!(InitLog))
{
    return
}

LogMessage "Script started at:" $true $false
LogMessage (Indent $StartTime) $true $false

LogMessage "Operation mode:"
LogMessage (Indent $Mode.ToUpper())

# Determine path to Plex Media Server executable.
$Success, $PlexServerExePath = 
    GetPlexMediaServerExePath `
        $PlexServerExePath `
        $PlexServerExeFileName

if (!$Success)
{
    return
}

# Get list of all running Plex services (match by display name).
try
{
    $PlexServices = GetRunningPlexServices $PlexServiceNameMatchString
}
catch
{
    LogException $_
    return
}

# Stop all running Plex services.
$Success, $PlexServices = StopPlexServices $PlexServices
if (!$Success)
{
    StartPlexServices $PlexServices
    return
}

# Stop Plex Media Server executable (if it's still running).
if (!(StopPlexMediaServer $PlexServerExeFileName $PlexServerExePath))
{
    StartPlexServices $PlexServices
    return
}

# Restore Plex app data from backup.
if ($Mode -eq "Restore")
{
    $Success = RestorePlexFromBackup `
        $PlexAppDataDir `
        $PlexRegKey `
        $BackupRootDir `
        $BackupDirName `
        $BackupDirPath `
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
        $BackupDirName `
        $BackupdDirPath `
        $TempZipFileDir `
        $ExcludePlexAppDataDirs `
        $SpecialPlexAppDataSubDirs `
        $Keep `
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

LogMessage "Script ended at:"
LogMessage (Indent (GetTimestamp))

$EndTime = Get-Date

LogMessage "Script ran for (hr:min:sec.msec):"
LogMessage (Indent (New-TimeSpan –Start $StartTime –End $EndTime).ToString("hh\:mm\:ss\.fff"))

LogMessage "Script returned:"
if ($Success)
{
    LogMessage (Indent "SUCCESS")
}
else
{
    LogMessage (Indent "ERROR")
}
