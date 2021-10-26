#------------------------------[ HELP INFO ]-------------------------------

<#
.SYNOPSIS
Backs up or restores Plex application data files and registry keys on a Windows system.

.DESCRIPTION
The script can run in these modes:

- Backup   : A default mode to initiate a new backup.
- Continue : Continues from where a previous backup stopped.
- Restore  : Restores Plex app data from a backup.

The script backs up the contents of the 'Plex Media Server' folder (app data folder) with the exception of some top-level, non-essential folders. You can customize the list of folders that do not need to be backed up. By default, the following top-level app data folders are not backed up:

- Diagnostics
- Crash Reports
- Updates
- Logs

The backup process compresses the contents Plex app data folders to the ZIP files (with the exception of folders containing subfolders and files with really long paths). For efficiency reasons, the script first compresses the data in a temporary folder and then copies the compressed (ZIP) files to the backup destination folder. You can compress data to the backup destination folder directly (bypassing the saving to the temp folder step) by setting the value of the $TempZipFileDir variable to null or empty string. Folders holding subfolders and files with very long paths get special treatment: instead of compressing them, before performing the backup, the script moves them to the backup folder as-is, and after the backup, it copies them to their original locations. Alternatively, backup can create a mirror of the essential app data folder via the Robocopy command (to use this option, set the -Robocopy switch).

In addition to backing up Plex app data, the script also backs up the contents of the Plex Windows Registry key.

The backup is created in the specified backup folder under a subfolder which name reflects the script start time. It deletes the old backup folders (you can specify the number of old backup folders to keep).

If the backup process does not complete due to error, you can run backup in the Continue mode (using the '-Mode Continue' command-line switch) and it will resume from where it left off. By default, the script picks up the most recent backup folder, but you can specify the backup folder using the -BackupDirPath command-line switch.

When restoring Plex application data from a backup, the script expects the backup folder structure to be the same as the one it creates when it runs in the backup mode. By default, it use the backup folder with the name reflecting the most recent timestamp, but you can specify an alternative backup folder.

Before creating backup or restoring data from a backup, the script stops all running Plex services and the Plex Media Server process (it restarts them once the operation is completed). You can force the script to not start the Plex Media Server process via the -Shutdown switch.

To override the default script settings, modify the values of script parameters and global variables inline or specify them in a config file.

The script can send an email notification on the operation completion.

The config file must use the JSON format. Not every script variable can be specified in the config file (for the list of overridable variables, see the sample config file). Only non-null values from config file will be used. The default config file is named after the running script with the '.json' extension, such as: PlexBackup.ps1.json. You can specify a custom config file via the -ConfigFile command-line switch. Config file is optional. All config values in the config file are optional. The non-null config file settings override the default and command-line paramateres, e.g. if the command-line -Mode switch is set to 'Backup' and the corresponding element in the config file is set to 'Restore' then the script will run in the Restore mode.

On success, the script will set the value of the $LASTEXITCODE variable to 0; on error, it will be greater than zero.

This script must run as an administrator.

The execution policy must allow running scripts. To check execution policy, run the following command:

  Get-ExecutionPolicy

If the execution policy does not allow running scripts, do the following:

  (1) Start Windows PowerShell with the "Run as Administrator" option.
  (2) Run the following command:

    Set-ExecutionPolicy RemoteSigned

This will allow running unsigned scripts that you write on your local computer and signed scripts from Internet.

Alternatively, you may want to run the script as:

  start powershell.exe -noprofile -executionpolicy bypass -file .\PlexBackup.ps1 -ConfigFile .\PlexBackup.ps1.json

See also 'Running Scripts' at Microsoft TechNet Library:

https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)

.PARAMETER Mode
Specifies the mode of operation:

- Backup (default)
- Continue
- Restore

.PARAMETER Backup
Shortcut for '-Mode Backup'.

.PARAMETER Continue
Shortcut for '-Mode Continue'.

.PARAMETER Restore
Shortcut for '-Mode Restore'.

.PARAMETER Type
Specifies the non-default type of backup method:

- 7zip
- Robocopy

By default, the script will use the built-in compression.

.PARAMETER SevenZip
Shortcut for '-Type 7zip'

.PARAMETER Robocopy
Shortcut for '-Type Robocopy'.

.PARAMETER ModuleDir
Optional path to directory holding the modules used by this script. This can be useful if the script runs on the system with no or restricted access to the Internet. By default, the module path will point to the 'Modules' folder in the script's folder.

.PARAMETER ConfigFile
Path to the optional custom config file. The default config file is named after the script with the '.json' extension, such as 'PlexBackup.ps1.json'.

.PARAMETER PlexAppDataDir
Location of the Plex Media Server application data folder.

.PARAMETER BackupRootDir
Path to the root backup folder holding timestamped backup subfolders. If not specified, the script folder will be used.

.PARAMETER BackupDirPath
When running the script in the 'Restore' mode, holds path to the backup folder (by default, the subfolder with the most recent timestamp in the name located in the backup root folder will be used).

.PARAMETER TempDir
Temp folder used to stage the archiving job (use local drive for efficiency). To bypass the staging step, set this parameter to null or empty string.

.PARAMETER WakeUpDir
Optional path to a remote share that may need to be woken up before starting Plex Media Server.

.PARAMETER ArchiverPath
Defines the path to the 7-zip command line tool (7z.exe) which is required when running the script with the '-Type 7zip' or '-SevenZip' switch. Default: $env:ProgramFiles\7-Zip\7z.exe.

.PARAMETER Quiet
Set this switch to suppress log entries sent to a console.

.PARAMETER LogLevel
Specifies the log level of the output:

- None
- Error
- Warning
- Info
- Debug

.PARAMETER Log
When set to true, informational messages will be written to a log file. The default log file will be created in the backup folder and will be named after this script with the '.log' extension, such as 'PlexBackup.ps1.log'.

.PARAMETER LogFile
Use this switch to specify a custom log file location. When this parameter is set to a non-null and non-empty value, the '-Log' switch can be omitted.

.PARAMETER ErrorLog
When set to true, error messages will be written to an error log file. The default error log file will be created in the backup folder and will be named after this script with the '.err.log' extension, such as 'PlexBackup.ps1.err.log'.

.PARAMETER ErrorLogFile
Use this switch to specify a custom error log file location. When this parameter is set to a non-null and non-empty value, the '-ErrorLog' switch can be omitted.

.PARAMETER Keep
Number of old backups to keep:

  0 - retain all previously created backups,
  1 - latest backup only,
  2 - latest and one before it,
  3 - latest and two before it,

and so on.

.PARAMETER Retries
The number of retries on failed copy operations (corresponds to the Robocopy /R switch).

.PARAMETER RetryWaitSec
Specifies the wait time between retries in seconds (corresponds to the Robocopy /W switch).

.PARAMETER RawOutput
Set this switch to display raw output from the external commands, such as Robocopy or 7-zip.

.PARAMETER Inactive
When set, allows the script to continue if Plex Media Server is not running.

.PARAMETER NoRestart
Set this switch to not start the Plex Media Server process at the end of the operation (could be handy for restores, so you can double check that all is good before launching Plex media Server).

.PARAMETER NoSingleton
Set this switch to ignore check for multiple script instances running concurrently.

.PARAMETER NoVersion
Forces restore to ignore version mismatch between the current version of Plex Media Server and the version of Plex Media Server active during backup.

.PARAMETER NoLogo
Specify this command-line switch to not print version and copyright info.

.PARAMETER Test
When turned on, the script will not generate backup files or restore Plex app data from the backup files.

.PARAMETER SendMail
Indicates in which case the script must send an email notification about the result of the operation:

- Never (default)
- Always
- OnError (for any operation)
- OnSuccess (for any operation)
- OnBackup (for both the Backup and Continue modes on either error or success)
- OnBackupError
- OnBackupSuccess
- OnRestore (on either error or success)
- OnRestoreError
- OnRestoreSuccess

.PARAMETER SmtpServer
Defines the SMTP server host. If not specified, the notification will not be sent.

.PARAMETER Port
Specifies an alternative port on the SMTP server. Default: 0 (zero, i.e. default port 25 will be used).

.PARAMETER From
Specifies the email address when email notification sender. If this value is not provided, the username from the credentails saved in the credentials file or entered at the credentials prompt will be used. If the From address cannot be determined, the notification will not be sent.

.PARAMETER To
Specifies the email address of the email recipient. If this value is not provided, the addressed defined in the To parameter will be used.

.PARAMETER NoSsl
Tells the script not to use the Secure Sockets Layer (SSL) protocol when connecting to the SMTP server. By default, SSL is used.

.PARAMETER CredentialFile
Path to the file holding username and encrypted password of the account that has permission to send mail via the SMTP server. You can generate the file via the following PowerShell command:

  Get-Credential | Export-CliXml -Path "PathToFile.xml"

The default log file will be created in the backup folder and will be named after this script with the '.xml' extension, such as 'PlexBackup.ps1.xml'.

.PARAMETER SaveCredential
When set, the SMTP credentials will be saved in a file (encrypted with user- and machine-specific key) for future use.

.PARAMETER Anonymous
Tells the script to not use credentials when sending email notifications.

.PARAMETER SendLogFile
Indicates in which case the script must send an attachment along with th email notification

- Never (default)
- Always
- OnError
- OnSuccess

.PARAMETER Logoff
Specify this command-line switch to log off all user accounts (except the running one) before starting Plex Media Server. This may help address issues with remote drive mappings under the wrong credentials.

.PARAMETER Reboot
Reboots the computer after a successful backup operation (ignored on restore).

.PARAMETER ForceReboot
Forces an immediate restart of the computer after a successfull backup operation (ignored on restore).

.NOTES
Version    : 2.1.1
Author     : Alek Davis
Created on : 2021-10-26
License    : MIT License
LicenseLink: https://github.com/alekdavis/PlexBackup/blob/master/LICENSE
Copyright  : (c) 2019-2021 Alek Davis

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
Backs up Plex application data to the default backup location using the Robocopy command instead of the file and folder compression.

.EXAMPLE
PlexBackup.ps1 -SevenZip
Backs up Plex application data to the default backup location using the 7-zip command-line tool (7z.exe). 7-zip command-line tool must be installed and the script must know its path.

.EXAMPLE
PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
Backs up Plex application data to the specified backup location on a network share.

.EXAMPLE
PlexBackup.ps1 -Continue
Continues a previous backup process from where it left off.

.EXAMPLE
PlexBackup.ps1 -Restore
Restores Plex application data from the latest backup in the default folder.

.EXAMPLE
PlexBackup.ps1 -Restore -Robocopy
Restores Plex application data from the latest backup in the default folder created using the Robocopy command.

.EXAMPLE
PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MYNAS\PlexBackup\20190101183015" Restores Plex application data from a backup in the specified remote folder.

.EXAMPLE
PlexBackup.ps1 -SendMail Always -Prompt -Save -SendLogFile OnError -SmtpServer smtp.gmail.com -Port 587
Runs a backup job and sends an email notification over an SSL channel. If the backup operation fails, the log file will be attached to the email message. The sender's and the recipient's email addresses will determined from the username of the credential object. The credential object will be set either from the credential file or, if the file does not exist, via a user prompt (in the latter case, the credential object will be saved in the credential file with password encrypted using a user- and computer-specific key).

.EXAMPLE
Get-Help .\PlexBackup.ps1
View help information.
#>

#------------------------------[ IMPORTANT ]-------------------------------

<#
PLEASE MAKE SURE THAT THE SCRIPT STARTS WITH THE COMMENT HEADER ABOVE AND
THE HEADER IS FOLLOWED BY AT LEAST ONE BLANK LINE; OTHERWISE, GET-HELP AND
GETVERSION COMMANDS WILL NOT WORK.
#>

#------------------------[ RUN-TIME REQUIREMENTS ]-------------------------

#Requires -Version 4.0
#Requires -RunAsAdministrator

#------------------------[ COMMAND-LINE SWITCHES ]-------------------------

# Script command-line arguments (see descriptions in the .PARAMETER comments
# above). These parameters can also be specified in the accompanying
# configuration (.json) file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute( `
    'PSAvoidUsingPlainTextForPassword', 'CredentialFile', `
    Justification='No need for SecureString, since it holds path, not secret.')]
[CmdletBinding(DefaultParameterSetName="default")]
param (
    [Parameter(ParameterSetName="Mode")]
    [Parameter(Mandatory, ParameterSetName="ModeType")]
    [Parameter(Mandatory, ParameterSetName="ModeSevenZip")]
    [Parameter(Mandatory, ParameterSetName="ModeRobocopy")]
    [ValidateSet("", "Backup", "Continue", "Restore")]
    [string]
    $Mode = "",

    [Parameter(ParameterSetName="Backup")]
    [Parameter(Mandatory, ParameterSetName="BackupType")]
    [Parameter(Mandatory, ParameterSetName="BackupSevenZip")]
    [Parameter(Mandatory, ParameterSetName="BackupRobocopy")]
    [switch]
    $Backup,

    [Parameter(ParameterSetName="Continue")]
    [Parameter(Mandatory, ParameterSetName="ContinueType")]
    [Parameter(Mandatory, ParameterSetName="ContinueSevenZip")]
    [Parameter(Mandatory, ParameterSetName="ContinueRobocopy")]
    [switch]
    $Continue,

    [Parameter(ParameterSetName="Restore")]
    [Parameter(Mandatory, ParameterSetName="RestoreType")]
    [Parameter(Mandatory, ParameterSetName="RestoreSevenZip")]
    [Parameter(Mandatory, ParameterSetName="RestoreRobocopy")]
    [switch]
    $Restore,

    [Parameter(ParameterSetName="Type")]
    [Parameter(Mandatory, ParameterSetName="ModeType")]
    [Parameter(Mandatory, ParameterSetName="BackupType")]
    [Parameter(Mandatory, ParameterSetName="ContinueType")]
    [Parameter(Mandatory, ParameterSetName="RestoreType")]
    [ValidateSet("", "7zip", "Robocopy")]
    [string]
    $Type = "",

    [Parameter(ParameterSetName="SevenZip")]
    [Parameter(Mandatory, ParameterSetName="ModeSevenZip")]
    [Parameter(Mandatory, ParameterSetName="BackupSevenZip")]
    [Parameter(Mandatory, ParameterSetName="ContinueSevenZip")]
    [Parameter(Mandatory, ParameterSetName="RestoreSevenZip")]
    [switch]
    $SevenZip,

    [Parameter(ParameterSetName="Robocopy")]
    [Parameter(Mandatory, ParameterSetName="ModeRobocopy")]
    [Parameter(Mandatory, ParameterSetName="BackupRobocopy")]
    [Parameter(Mandatory, ParameterSetName="ContinueRobocopy")]
    [Parameter(Mandatory, ParameterSetName="RestoreRobocopy")]
    [switch]
    $Robocopy,

    [string]
    $ModuleDir = "$PSScriptRoot\Modules",

    [Alias("Config")]
    [string]
    $ConfigFile,

    [string]
    $PlexAppDataDir = "$env:LOCALAPPDATA\Plex Media Server",

    [string]
    $BackupRootDir = $PSScriptRoot,

    [Alias("BackupDirPath")]
    [string]
    $BackupDir = $null,

    [Alias("TempZipFileDir")]
    [AllowEmptyString()]
    [string]
    $TempDir = $env:TEMP,

    [string]
    $WakeUpDir = $null,

    [string]
    $ArchiverPath = "$env:ProgramFiles\7-Zip\7z.exe",

    [Alias("Q")]
    [switch]
    $Quiet,

    [ValidateSet("None", "Error", "Warning", "Info", "Debug")]
    [string]
    $LogLevel = "Info",

    [Alias("L")]
    [switch]
    $Log,

    [string]
    $LogFile,

    [switch]
    $ErrorLog,

    [string]
    $ErrorLogFile,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Keep = 3,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Retries = 5,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $RetryWaitSec = 10,

    [switch]
    $RawOutput,

    [switch]
    $Inactive,

    [Alias("Shutdown")]
    [switch]
    $NoRestart,

    [switch]
    $NoSingleton,

    [Alias("Force")]
    [Alias("NoVersionCheck")]
    [switch]
    $NoVersion,

    [switch]
    $NoLogo,

    [switch]
    $Test,

    [ValidateSet(
        "Never", "Always", "OnError", "OnSuccess",
        "OnBackup", "OnBackupError", "OnBackupSuccess",
        "OnRestore", "OnRestoreError", "OnRestoreSuccess")]
    [string]
    $SendMail = "Never",

    [string]
    $SmtpServer,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Port = 0,

    [string]
    $From = $null,

    [string]
    $To,

    [switch]
    $NoSsl,

    [Alias("Credential")]
    [string]
    $CredentialFile = $null,

    [switch]
    $SaveCredential,

    [switch]
    $Anonymous,

    [ValidateSet("Never", "OnError", "OnSuccess", "Always")]
    [string]
    $SendLogFile = "Never",

    [switch]
    $Logoff,

    [switch]
    $Reboot,

    [switch]
    $ForceReboot
)
#---------------[ VARIABLES CONFIGURABLE VIA CONFIG FILE ]-----------------

# The following Plex application folders do not need to be backed up.
$ExcludeDirs = @(
    "Diagnostics",
    "Crash Reports",
    "Updates",
    "Logs"
)

# The following file types do not need to be backed up:
# *.bif - thumbnail previews
# Transcode - cache subfolder used for transcoding and syncs (could be huge)
$ExcludeFiles = @(
    "*.bif",
    "Transcode"
)

# Subfolders that cannot be archived because the path may be too long.
# Long (over 260 characters) paths cause Compress-Archive to fail,
# so before running the archival steps, we will move these folders to
# the backup directory, and copy it back once the archival step completes.
# On restore, we'll copy these folders from the backup directory to the
# Plex app data folder.
$SpecialDirs = @(
    "Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated"
)

# Regular expression used to find display names of the Plex Windows service(s).
$PlexServiceName = "^Plex"

# Name of the Plex Media Server executable file.
$PlexServerFileName = "Plex Media Server.exe"

# If Plex Media Server is not running, define path to the executable here.
$PlexServerPath = $null

# 7-zip command-line option for compression.
$ArchiverOptionsCompress =
@(
    $null
)

# 7-zip command-line option for decompression.
$ArchiverOptionsExpand =
@(
    $null
)

#-------------------------[ MODULE DEPENDENCIES ]--------------------------

# Module to get script version info:
# https://www.powershellgallery.com/packages/ScriptVersion

# Module to initialize script parameters and variables from a config file:
# https://www.powershellgallery.com/packages/ConfigFile

# Module implementing logging to file and console routines:
# https://www.powershellgallery.com/packages/StreamLogging

# Module responsible for making sure only one instance of the script is running:
# https://www.powershellgallery.com/packages/SingleInstance

$MODULE_ScriptVersion   = "ScriptVersion"
$MODULE_ConfigFile      = "ConfigFile"
$MODULE_StreamLogging   = "StreamLogging|1.2.1"
$MODULE_SingleInstance  = "SingleInstance"

$MODULES = @(
    $MODULE_ScriptVersion,
    $MODULE_ConfigFile,
    $MODULE_StreamLogging,
    $MODULE_SingleInstance
)

#------------------------------[ CONSTANTS ]-------------------------------

# Mutex name (to enforce single instance).
$MUTEX_NAME = $PSCommandPath.Replace("\", "/")

# Plex registry key path.
$PLEX_REG_KEYS = @(
    "HKCU:\Software\Plex, Inc.\Plex Media Server",
    "HKU:\.DEFAULT\Software\Plex, Inc.\Plex Media Server"
)

# Default path of the Plex Media Server.exe.
$DEFAULT_PLEX_SERVER_EXE_PATH = "${env:ProgramFiles(x86)}\Plex\Plex Media Server\Plex Media Server.exe"

# File extensions.
$FILE_EXT_ZIP   = ".zip"
$FILE_EXT_7ZIP  = ".7z"
$FILE_EXT_REG   = ".reg"
$FILE_EXT_CRED  = ".xml"

# File names.
$VERSION_FILE_NAME = "Version.txt"

# Backup mode types.
$MODE_BACKUP    = "Backup"
$MODE_CONTINUE  = "Continue"
$MODE_RESTORE   = "Restore"

# Backup types.
$TYPE_ROBOCOPY = "Robocopy"
$TYPE_7ZIP     = "7zip"

# Backup folder format: YYYYMMDDhhmmss
$REGEX_BACKUPDIRNAMEFORMAT = "^\d{14}$"

# Format of the backup folder name (so it can be easily sortable).
$BACKUP_DIRNAMEFORMAT = "yyyyMMddHHmmss"

# Subfolders in the backup directory.
$SUBDIR_FILES    = "1"
$SUBDIR_FOLDERS  = "2"
$SUBDIR_REGISTRY = "3"
$SUBDIR_SPECIAL  = "4"

# Name of the common backup files.
$BACKUP_FILENAME = "Plex"

# Send mail settings.
$SEND_MAIL_NEVER   = "Never"
$SEND_MAIL_ALWAYS  = "Always"
$SEND_MAIL_ERROR   = "OnError"
$SEND_MAIL_SUCCESS = "OnSuccess"
$SEND_MAIL_BACKUP  = "OnBackup"
$SEND_MAIL_RESTORE = "OnRestore"

$SEND_LOGFILE_NEVER   = "Never"
$SEND_LOGFILE_ALWAYS  = "Always"
$SEND_LOGFILE_ERROR   = "OnError"
$SEND_LOGFILE_SUCCESS = "OnSuccess"

# Set variables for email notification.
$SUBJECT_ERROR    = "Plex backup failed :-("
$SUBJECT_SUCCESS  = "Plex backup completed :-)"

#------------------------------[ EXIT CODES]-------------------------------

$EXITCODE_SUCCESS =  0 # success
$EXITCODE_ERROR   =  1 # error

#----------------------[ NON-CONFIGURABLE VARIABLES ]----------------------

# File extensions.
$ZipFileExt = $FILE_EXT_ZIP
$RegFileExt = $FILE_EXT_REG

# Files and folders.
[string]$BackupDirName      = $null
[string]$VersionFilePath    = $null

# Version info.
[string]$PlexVersion         = $null
[string]$BackupVersion      = $null

# Save time for logging purposes.
[DateTime]$StartTime    = Get-Date
[DateTime]$EndTime      = $StartTime
[string]  $Duration     = $null

# Mail credentials object.
[PSCredential]$Credential  = $null

# Error message set in case of error.
[string]$ErrorResult       = $null

# Backup stats.
[string]$ObjectCount  = "UNKNOWN"
[string]$BackupSize   = "UNKNOWN"

# The default exit code indicates error (we'll set it to success at the end).
$ExitCode = $EXITCODE_ERROR

#--------------------------[ STANDARD FUNCTIONS ]--------------------------

#--------------------------------------------------------------------------
# SetModulePath
#   Adds custom folders to the module path.
function SetModulePath {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered SetModulePath."

    if ($Script:ModuleDir) {
        if ($env:PSModulePath -notmatch ";$") {
            $env:PSModulePath += ";"
        }

        $paths = $Script:ModuleDir -split ";"

        foreach ($path in $paths){
            $path = $path.Trim();

            if (-not ($env:PSModulePath.ToLower().
                Contains(";$path;".ToLower()))) {

                $env:PSModulePath += "$path;"
            }
        }
    }

    WriteDebug "Exiting SetModulePath."
}

#--------------------------------------------------------------------------
# GetModuleVersion
#   Returns version string for the specified module using format:
#   major.minor.build.
function GetModuleVersion {
    [CmdletBinding()]
    param(
        [PSModuleInfo]
        $moduleInfo
    )

    $major = $moduleInfo.Version.Major
    $minor = $moduleInfo.Version.Minor
    $build = $moduleInfo.Version.Build

    return "$major.$minor.$build"

}

#--------------------------------------------------------------------------
# GetVersionParts
#   Converts version string into three parts: major, minor, and build.
function GetVersionParts {
    [CmdletBinding()]
    param(
        [string]
        $version
    )

    $versionParts = $version.Split(".")

    $major = $versionParts[0]
    $minor = 0
    $build = 0

    if ($versionParts.Count -gt 1) {
        $minor = $versionParts[1]
    }

    if ($versionParts.Count -gt 2) {
        $build = $versionParts[2]
    }

    return $major, $minor, $build
}

#--------------------------------------------------------------------------
# CompareVersions
#   Compares two major, minor, and build parts of two version strings and
#   returns 0 is they are the same, -1 if source version is older, or 1
# if source version is newer than target version.
function CompareVersions {
    [CmdletBinding()]
    param(
        [string]
        $sourceVersion,

        [string]
        $targetVersion
    )

    if ($sourceVersion -eq $targetVersion) {
        return 0
    }

    $sourceMajor, $sourceMinor, $sourceBuild = GetVersionParts $sourceVersion
    $targetMajor, $targetMinor, $targetBuild = GetVersionParts $targetVersion

    $source = @($sourceMajor, $sourceMinor, $sourceBuild)
    $target = @($targetMajor, $targetMinor, $targetBuild)

    for ($i = 0; $i -lt $source.Count; $i++) {
        $diff = $source[$i] - $target[$i]

        if ($diff -ne 0) {
            if ($diff -lt 0) {
                return -1
            }

            return 1
        }
    }

    return 0
}

#--------------------------------------------------------------------------
# IsSupportedVersion
#   Checks whether the specified version is within the min-max range.
function IsSupportedVersion {
    [CmdletBinding()]
    param(
        [string]
        $version,

        [string]
        $minVersion,

        [string]
        $maxVersion
    )

    if (!($minVersion) -and (!($maxVersion))) {
        return $true
    }

    if (($version -and $minVersion -and $maxVersion) -and
        ($minVersion -eq $maxVersion) -and
        ($version -eq $minVersion)) {
        return 0
    }

    if ($minVersion) {
        if ((CompareVersions $version $minVersion) -lt 0) {
            return $false
        }
    }

    if ($maxVersion) {
        if ((CompareVersions $version $maxVersion) -gt 0) {
            return $false
        }
    }

    return $true
}

#--------------------------------------------------------------------------
# LoadModules
#   Installs (if needed) and loads the specified PowerShell modules.
function LoadModules {
    [CmdletBinding()]
    param(
        [string[]]
        $modules
    )
    WriteDebug "Entered LoadModules."

     # Make sure we got the modules.
    if (!($modules) -or ($modules.Count -eq 0)) {
        return
    }

    $module = ""
    $cmdArgs = @{}

    try {
        foreach ($module in $modules) {
            Write-Verbose "Processing module '$module'."

            $moduleInfo = $module.Split("|:")

            $moduleName         = $moduleInfo[0]
            $moduleVersion      = ""
            $moduleMinVersion   = ""
            $moduleMaxVersion   = ""
            $cmdArgs.Clear()

            if ($moduleInfo.Count -gt 1) {
                $moduleMinVersion = $moduleInfo[1]

                if ($moduleMinVersion) {
                    $cmdArgs["MinimumVersion"] = $moduleMinVersion
                }
            }

            if ($moduleInfo.Count -gt 2) {
                $moduleMaxVersion = $moduleInfo[2]

                if ($moduleMaxVersion) {
                    $cmdArgs["MaximumVersion"] = $moduleMaxVersion
                }
            }

            Write-Verbose "Required module name: '$moduleName'."

            if ($moduleMinVersion) {
                Write-Verbose "Required module min version: '$moduleMinVersion'."
            }

            if ($moduleMaxVersion) {
             Write-Verbose "Required module max version: '$moduleMaxVersion'."
            }

            # Check if module is loaded into the process.
            $loadedModules = Get-Module -Name $moduleName
            $isLoaded = $false

            if ($loadedModules) {
                Write-Verbose "Module '$moduleName' is loaded."

                # If version check is required, compare versions.
                if ($moduleMinVersion -or $moduleMaxVersion) {

                    foreach ($loadedModule in $loadedModules) {
                        $moduleVersion = GetModuleVersion $loadedModule

                        Write-Verbose "Checking if loaded module '$moduleName' version '$moduleVersion' is supported."

                        if (IsSupportedVersion $moduleVersion $moduleMinVersion $moduleMaxVersion) {
                            Write-Verbose "Loaded module '$moduleName' version '$moduleVersion' is supported."
                            $isLoaded = $true
                            break
                        }
                        else {
                            Write-Verbose "Loaded module '$moduleName' version '$moduleVersion' is not supported."
                        }
                    }
                }
                else {
                    $isLoaded = $true
                }
            }

            # If module is not loaded or version is wrong.
            if (!$isLoaded) {
                Write-Verbose "Required module '$moduleName' is not loaded."

                # Check if module is locally available.
                $installedModules = Get-Module -ListAvailable -Name $moduleName

                $isInstalled = $false

                # If module is found, validate the version.
                if ($installedModules) {
                    foreach ($installedModule in $installedModules) {
                        $installedModuleVersion = GetModuleVersion $installedModule
                        Write-Verbose "Found installed '$moduleName' module version '$installedModuleVersion'."

                        if (IsSupportedVersion $installedModuleVersion $moduleMinVersion $moduleMaxVersion) {

                            Write-Verbose "Module '$moduleName' version '$moduleVersion' is supported."
                            $isInstalled = $true
                            break
                        }

                        Write-Verbose "Module '$moduleName' version '$moduleVersion' is not supported."
                        Write-Verbose "Supported module '$moduleName' versions are: '$minVersion'-'$maxVersion'."
                    }

                    if (!$isInstalled) {

                        # Download module if needed.
                        Write-Verbose "Installing module '$moduleName'."
                        Install-Module -Name $moduleName @cmdArgs -Force -Scope CurrentUser -ErrorAction Stop
                    }
                }
            }

            #  Import module into the process.
            Write-Verbose "Importing module '$moduleName'."
            Import-Module $moduleName -ErrorAction Stop -Force @cmdArgs
        }
    }
    catch {
        $errMsg = "Cannot load module '$module'."
        throw (New-Object System.Exception($errMsg, $_.Exception))
    }
    finally {
        WriteDebug "Exiting LoadModules."
    }
}

#--------------------------------------------------------------------------
# GetScriptVersion
#   Returns script version info.
function GetScriptVersion {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered GetScriptVersion."

    $versionInfo = Get-ScriptVersion
    $scriptName  = (Get-Item $PSCommandPath).Basename

    WriteDebug "Exiting GetScriptVersion."

    return ($scriptName +
        " v" + $versionInfo["Version"] +
        " " + $versionInfo["Copyright"])
}

#--------------------------------------------------------------------------
# GetPowerShellVersion
#   Returns PowerShell version info.
function GetPowerShellVersion {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered GetPowerShellVersion."

    $psVersion = $PSVersionTable.PSVersion

    WriteDebug "Exiting GetScriptVersion."

    return ($psVersion.Major.ToString() + '.' +
            $psVersion.Minor.ToString() + '.' +
            $psVersion.Build.ToString() + '.' +
            $psVersion.Revision.ToString())
}

#--------------------------------------------------------------------------
# GetCommandLineArgs
#   Returns command-line arguments as a string.
function GetCommandLineArgs {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered GetCommandLineArgs."

    $commandLine = ""
    if ($args.Count -gt 0) {

        for ($i = 0; $i -lt $args.Count; $i++) {
            if ($args[$i].Contains(" ")) {
                $commandLine = $commandLine + '"' + $args[$i] + '" '
            }
            else {
                $commandLine = $commandLine + $args[$i] + ' '
            }
        }
    }

    WriteDebug "Exiting GetCommandLineArgs."

    return $commandLine.Trim()
}

#--------------------------------------------------------------------------
# FormatError
#   Returns error message from exception and inner exceptions.
function FormatError {
    [CmdletBinding()]
    param (
        $errors
    )

    if (!$errors -or $errors.Count -lt 1) {
        return $null
    }

    [System.Exception]$ex = $errors[0].Exception

    [string]$message = $null

    while ($ex) {
        if ($message) {
            $message += " $($ex.Message)"
        }
        else {
            $message = $ex.Message
        }

        $ex = $ex.InnerException
    }

    return $message
}

#--------------------------------------------------------------------------
# WriteException
#   Writes exception to console.
function WriteException {
    [CmdletBinding()]
    param (
        $errors
    )

    WriteError (FormatError $errors)
}

#--------------------------------------------------------------------------
# WriteLogException
#   Logs exception and inner exceptions.
function WriteLogException {
    [CmdletBinding()]
    param (
        $errors
    )

    Write-LogError (FormatError $errors)
}

#--------------------------------------------------------------------------
# WriteDebug
#   Writes debug messages to console.
function WriteDebug {
    #[CmdletBinding()]
    param (
        $message
    )
    if ($message -and $DebugPreference -ne 'SilentlyContinue') {
        Write-Verbose $message
    }
}

#--------------------------------------------------------------------------
# WriteError
#   Writes error message to console.
function WriteError {
    [CmdletBinding()]
    param (
        $message
    )

    if ($message) {
        [Console]::ForegroundColor = 'red'
        [Console]::BackgroundColor = 'black'
        [Console]::WriteLine($message)
        [Console]::ResetColor()
    }
}

#--------------------------------------------------------------------------
# StartLogging
#   Initializes log settings.
function StartLogging {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered StartLogging."

    $logArgs = @{}

    if ($Script:LogLevel) {
        $logArgs.Add("LogLevel", $Script:LogLevel)
    }

    if ($Script:Log -and !$Script:LogFile) {
        $logFileName = "$Script:Mode.log"

        $Script:LogFile = Join-Path $Script:BackupDir $logFileName
    }

    if ($Script:LogFile) {
        Write-Verbose "Setting log file to '$Script:LogFile'."
        $logArgs.Add("FilePath", $Script:LogFile)
    }
    else {
        Write-Verbose "Not using log file."
        $logArgs.Add("File", $false)
    }

    if ($script:ErrorLog -and !$script:ErrorLogFile) {
        $errorLogFileName = "$Script:Mode.err.log"

        $Script:ErrorLogFile = Join-Path $Script:BackupDir $errorLogFileName
    }

    if ($Script:ErrorLogFile) {
        Write-Verbose "Setting error log file to '$Script:ErrorLogFile'."
        $logArgs.Add("ErrorFilePath", $Script:ErrorLogFile)
    }
    else {
        Write-Verbose "Not using error log file."
        $logArgs.Add("ErrorFile", $false)
    }

    # If script was launched with the -Quiet switch, do not output log to console.
    if ($Script:Quiet) {
        Write-Verbose "Not logging to console because of the '-Quiet' switch."
        $logArgs.Add("Console", $false)
    }

    # Initialize log settings.
    Write-Verbose "Initializing logging."
    Start-Logging @logArgs

    WriteDebug "Exiting StartLogging."
}

#--------------------------------------------------------------------------
# StopLogging
#   Clears logging resources.
function StopLogging {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered StopLogging."

    if (Get-Module -Name $MODULE_StreamLogging) {
        if (Test-LoggingStarted) {
            try {
                Write-Verbose "Uninitializing logging."
                Stop-Logging
            }
            catch {
                WriteError "Cannot stop logging."
                WriteException $_

                $Error.Clear()
            }
        }
        else {
            Write-Verbose "Logging has not started, so nothing to uninitialize."
        }
    }
    else {
        Write-Verbose "$MODULE_StreamLogging module is not loaded."
    }

    WriteDebug "Exiting StopLogging."
}

#--------------------------------------------------------------------------
# Prologue
#   Performs common action before the main execution logic.
function Prologue {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered Prologue."

    # Display script version info.
    if (!($Script:NoLogo)){
        Write-LogInfo (GetScriptVersion)
    }

    Write-LogInfo "Script started at:"
    Write-LogInfo $Script:StartTime -Indent 1

    # Get script
    $scriptArgs = GetCommandLineArgs

    # Only write command-line arguments to the log file.
    if ($scriptArgs) {
        Write-LogInfo "Command-line arguments:"
        Write-LogInfo $scriptArgs -Indent 1 -NoConsole
    }

    # Only write logging configuration to the log file.
    $loggingConfig = Get-LoggingConfig -Compress
    Write-LogDebug "Logging configuration:" -NoConsole
    Write-LogDebug $loggingConfig -Indent 1 -NoConsole

    WriteDebug "Exiting Prologue."
}

#--------------------------------------------------------------------------
# Epilogue
#   Performs common action after the main execution logic.
function Epilogue {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered Epilogue."

    try {
        if (!$Script:ErrorResult) {
            if ($Script:Mode -ne $MODE_RESTORE) {
                Write-LogInfo "Plex backup size:"
            }
            else {
                Write-LogInfo "Plex app data size:"
            }

            Write-LogInfo "$($Script:ObjectCount) files and folders" -Indent 1

            Write-LogInfo "$($Script:BackupSize) GB of data" -Indent 1
        }

        $runTime = (New-TimeSpan -Start $Script:StartTime -End $Script:EndTime).
            ToString("hh\:mm\:ss\.fff")

        Write-LogInfo "Script ended at:"
        Write-LogInfo $Script:EndTime -Indent 1

        Write-LogInfo "Script ran for (hr:min:sec.msec):"
        Write-LogInfo $runTime -Indent 1

        Write-LogInfo "Script execution result:"
        if ($Script:ErrorResult) {
            Write-LogInfo "ERROR" -Indent 1
        }
        else {
            Write-LogInfo "SUCCESS" -Indent 1
        }

        Write-LogInfo "Done."
    }
    catch {
        WriteLogException $_

        $Error.Clear()
    }

    WriteDebug "Exiting Epilogue."
}

#---------------------------[ CUSTOM FUNCTIONS ]---------------------------

# TODO: IMPLEMENT THE FOLLOWING FUNCTIONS AND ADD YOUR OWN IF NEEDED.

#--------------------------------------------------------------------------
# InitGlobals
#   Initializes global variables.
function InitGlobals {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered InitGlobals."

    # First, set up the script execution mode.
    Write-Verbose "Validating script execution mode."
    if ($Script:Backup) {
        $Script:Mode = $MODE_BACKUP
    }
    elseif ($Script:Continue) {
        $Script:Mode = $MODE_CONTINUE
    }
    elseif ($Script:Restore) {
        $Script:Mode = $MODE_RESTORE
    }
    else {
        if (!$Script:Mode) {
            $Script:Mode = $MODE_BACKUP
        }
    }

    # Set up the backup type.
    Write-Verbose "Validating backup type."
    if ($Script:Robocopy) {
        $Script:Type = $TYPE_ROBOCOPY
    }
    elseif ($Script:SevenZip) {
        $Script:Type = $TYPE_7ZIP
    }

    # For 7-zip archival, change default '.zip' extension to '.7z'.
    if ($Script:Type -eq $TYPE_7ZIP) {
        $Script:ZipFileExt = $FILE_EXT_7ZIP
    }

    # If backup folder is specified, use its parent as the root.
    if ($Script:BackupDir) {
        $Script:BackupRootDir = Split-Path -Path $Script:BackupDir -Parent
    }

    # Get the name and path of the backup directory.
    try {
        $Script:BackupDirName, $Script:BackupDir = GetBackupDirAndPath
    }
    catch {
        throw (New-Object System.Exception( `
            "Cannot determine name and/or path of the backup folder.", `
                $_.Exception))
    }

    try {
        # Determine path to Plex Media Server executable.
        $Script:PlexServerPath =
            GetPlexServerPath
    }
    catch {
        if (!$Script:Inactive) {
            throw (New-Object System.Exception( `
                "Cannot validate Plex Media Server executable path.", `
                    $_.Exception))
        }
        else {
            Write-Verbose (FormatError $_)
            Write-Verbose "Will continue because the '-Inactive' switch is turned on."
        }
    }

    # Get version information.
    $Script:VersionFilePath= Join-Path $Script:BackupDir $VERSION_FILE_NAME

    $Script:PlexVersion    = GetPlexVersion
    $Script:BackupVersion  = GetBackupVersion

    WriteDebug "Exiting InitGlobals."
}

#--------------------------------------------------------------------------
# FormatRegFilename
#   Converts registry key path to filename (basically, hashes the name).
function FormatRegFilename {
    [CmdletBinding()]
    param (
        $regKeyPath
    )

    #foreach ($token in $REG_KEY_CHAR_SUBS.GetEnumerator()) {
    #    $regKeyPath = $regKeyPath.Replace($token.key, $token.Value)
    #}
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($regKeyPath)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $stringBuilder = New-Object System.Text.StringBuilder

    $algorithm.ComputeHash($bytes) |
    ForEach-Object {
        $null = $StringBuilder.Append($_.ToString("x2"))
    }

    return $stringBuilder.ToString()
}

#--------------------------------------------------------------------------
# FormatFileSize
#   Generates a string representation of the file size.

Function FormatFileSize() {
    param
    (
        [string]
        $path
    )
    $result = $null

    if (!(Test-Path -Path $path -PathType Leaf)) {
        return $result
    }

    $size = (Get-Item $path).length

    if ($size -gt 1TB) {
        $result = [string]::Format("{0:0.0} TB", $size / 1TB)
    }
    elseif ($size -gt 1GB) {
        $result = [string]::Format("{0:0.0} GB", $size / 1GB)
    }
    elseif ($size -gt 1MB) {
        $result = [string]::Format("{0:0.0} MB", $size / 1MB)
    }
    elseif ($size -gt 1KB) {
        $result = [string]::Format("{0:0.0} KB", $size / 1KB)
    }
    elseif ($size -gt 0) {
        $result = [string]::Format("{0:0.0} B", $size)
    }

    return $result
}

#--------------------------------------------------------------------------
# GetTimestamp
#   Returns current timestamp in a consistent format.
function GetTimestamp {
    return $(Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
}

#--------------------------------------------------------------------------
# WakeUpDir
#   Attempts to wake a remote host just in case if the backup folder is
#   hosted on a remote share (pseudo Wake-onLAN command).
function WakeUpDir {
    param (
        [string]
        $path,

        [int]
        $attempts = 6,

        [int]
        $sleepTimeSec = 5
    )
    WriteDebug "Entered WakeUpdDir."

    if ($path) {
        # Just in case path points to a remote share on a sleeping device,
        # try waking it up (a directory listing should do it).
        for ($i = 0; $i -lt $attempts; $i++) {
            try {
                Write-Verbose "Waking up '$path'."
                Get-ChildItem -Path $path | Out-Null
                break
            }
            catch {
                $Error.Clear()
                Start-Sleep -Seconds $sleepTimeSec
            }
        }
    }

    WriteDebug "Exiting WakeUpDir."
}

#--------------------------------------------------------------------------
# GetNewBackupDirName
#   Generates the new name of the backup subfolder based on the current
#   timestamp in the format: YYYYMMDDhhmmss.
function GetNewBackupDirName {
    param (
    )

    return ($Script:StartTime).ToString($BACKUP_DIRNAMEFORMAT)
}

#--------------------------------------------------------------------------
# GetLastBackupDirPath
#   Returns the path of the most recent backup folder.
function GetLastBackupDirPath {
    param (
    )
    WriteDebug "Entered GetLastBackupDirPath."
    [string]$path = $null

    WakeUpDir $Script:BackupRootDir

    Write-Verbose "Checking backup root folder '$Script:BackupRootDir'."
    if (!(Test-Path -Path $Script:BackupRootDir -PathType Container)) {
        throw "Backup root folder '$Script:BackupRootDir' does not exist."
    }

    # Get all folders with names from newest to oldest.
    $oldBackupDirs = Get-ChildItem -Path $Script:BackupRootDir -Directory |
        Where-Object { $_.Name -match $REGEX_BACKUPDIRNAMEFORMAT } |
            Sort-Object -Descending

    # Check if there is at least one matching subdirectory.
    if ($oldBackupDirs.Count -gt 0) {
        $path = $oldBackupDirs[0].FullName
    }

    WriteDebug "Exiting GetLastBackupDirPath."
    return $path
}

#--------------------------------------------------------------------------
# GetBackupDirAndPath
#   Returns name and path of the backup directory that will be used for the
#   running backup job (it can be an existing or a new directory depending
#   on the backup mode).
function GetBackupDirAndPath {
    param (
    )
    WriteDebug "Entered GetBackupDirAndPath."

    [string]$name = $null
    [string]$path = $null

    if ($Script:BackupDir) {
        WakeUpDir $Script:BackupDir

        $name = (Split-Path -Path $Script:BackupDir -Leaf)
        $path = $Script:BackupDir
    }
    else {
        WakeUpDir $Script:BackupRootDir

        # For Restore and Continue, get the latest timestamped subfolder from the backup root.
        if ($Script:Mode -ne $MODE_BACKUP) {
            $path = GetLastBackupDirPath

            # For Restore mode we must have at least one matching folder;
            # for Continue, it's okay if none are found (we'll create a new one a
            # as if running in the Backup mode).
            if (!$path -and ($Script:Mode -eq $MODE_RESTORE)) {
                throw "No folder matching the timestamp regex format " +
                    "'$REGEX_BACKUPDIRNAMEFORMAT' found in the " +
                    "backup root folder '$Script:BackupRootDir'."
            }
        }

        if ($path) {
            $name = (Split-Path -Path $path -Leaf)
        }
        else {
            # For the Backup mode, generate a new timestamp-based folder name.
            # Do the same for Continue mode if we did not find the last backup folder.
            $name = GetNewBackupDirName
            $path = (Join-Path $Script:BackupRootDir $name)
        }
    }

    WriteDebug "Exiting GetBackupDirAndPath."
    return $name, $path
}

#--------------------------------------------------------------------------
# InitMail
#   Initializes SMTP and mail notification setting.
function InitMail {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered InitMail."

    # Set up mail configuration.
    if (!$Script:SmtpServer) {
        if ($Script:SendMail -ne $SEND_MAIL_NEVER) {
            Write-Verbose "Will not send email notification because SMTP server is not specified."
        }

        WriteDebug "Exiting InitSmtp."
        return
    }

    try {
        if (!(MustSendMail)) {
            if ($Script:SendMail -ne $SEND_MAIL_NEVER) {
                Write-Verbose "Will not send email notification because the condition is not met."
                $Script:SendMail = $SEND_MAIL_NEVER
            }
            else {
                Write-Verbose "Email notification will not be sent."
            }

            return
        }

        # If we do not support anonymous SMTP, need to get credentials.
        if (!$Script:Anonymous) {
            # If credential file path is not specified, use the default.
            if (!$Script:CredentialFile) {
                $Script:CredentialFile = $PSCommandPath + $FILE_EXT_CRED
            }

            # If credential file exists, read credentials from the file.
            if (Test-Path -Path $Script:CredentialFile -PathType Leaf) {
                try {
                    Write-Verbose "Importing SMTP credentials from '$Script:CredentialFile'."
                    $Script:Credential = Import-CliXml -Path $Script:CredentialFile
                }
                catch {
                    Write-Verbose ("Cannot import SMTP credentials from '$Script:CredentialFile'. " +
                        "If the file is no longer valid, please delete it and try again.")
                }

                # If we did not get credentail from the file and  user prompt not specified,
                # nothing we can do.
                if (!$Script:Credential) {
                    Write-Verbose ("SMTP credentials in '$Script:CredentialFile' are empty. " +
                        "If the file is no longer valid, please delete it and try again.")
                }
            }

            # Show prompt to allow user to enter credentials.
            if (!$Script:Credential) {
                try {
                    $Script:Credential = $Host.UI.PromptForCredential(
                        "SMTP Server Authentication",
                        "Please enter your credentials for " + $Script:SmtpServer,
                        "",
                        "",
                        [System.Management.Automation.PSCredentialTypes]::Generic,
                        [System.Management.Automation.PSCredentialUIOptions]::None)
                }
                catch {
                   throw (New-Object System.Exception( `
                        "Cannot get SMTP credentials from the Windows prompt.", $_.Exception))
                }

                # If we did not get credentail from the file and  user prompt not specified,
                # nothing we can do.
                if (!$Script:Credential) {
                    throw "No SMTP credentials provided."
                }

                # Save entered credentials if needed.
                if ($Script:SaveCredential) {
                    try {
                        Write-Verbose "Exporting SMTP credentials to '$Script:CredentialFile'."

                        Export-CliXml -Path $Script:CredentialFile -InputObject $Script:Credential
                    }
                    catch {
                        throw (New-Object System.Exception( `
                            "Cannot export SMTP credentials to '$Script:CredentialFile'.", $_.Exception))
                    }
                }
            }
        }

        if (!$Script:From -and !$Script:To -and (!$Script:Credential -or !$Script:Credential.UserName)) {
            throw "No address specified for email notification."
        }

        # If the From address is not specified, get it from credential object or To address.
        if (!$Script:From) {
            if ($Script:Credential -and $Script:Credential.UserName) {
                $Script:From = $Script:Credential.UserName
            }
            else {
                $Script:From = $Script:To
            }
        }

        # If the To address is not specified, get it from the From address.
        if (!$Script:To) {
            $Script:To = $Script:From
        }

        # If the To or From address not specified, do not send mail.
        if (!$Script:From -or !$Script:To) {
            Write-Verbose "Will not send email notification because of missing address."
            $Script:SendMail = $SEND_MAIL_NEVER
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting InitMail."
    }
}

#--------------------------------------------------------------------------
# Validate7Zip
#   Validates path to the 7-zip command-line tool.
function Validate7Zip {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered Validate7Zip."

    try {
        if ($Script:Type -eq $TYPE_7ZIP) {
            if (!$Script:ArchiverPath) {
                throw "Please set the value of parameter 'ArchiverPath' " +
                    "to point to the 7-zip command-line tool (7z.exe)."
            }

            if (!(Test-Path -Path $Script:ArchiverPath -PathType Leaf)) {
                throw "The 7-zip command line tool is not found in " +
                    "'$Script:ArchiverPath'. " +
                    "Please define a valid path in parameter 'ArchiverPath'."
            }
        }
    }
    catch {
        throw
    }
    finally {

        WriteDebug "Exiting Validate7Zip."
    }
}

#--------------------------------------------------------------------------
# ValidateVersion
#   Validates backup version.
function ValidateVersion {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered ValidateVersion."

    if ($Script:Mode -eq $MODE_BACKUP) {
        Write-Verbose "Version validation skipped during backup."
    }
    else {
        if (!$Script:BackupVersion) {
            Write-Verbose `
                "Version validation skipped because of the missing backup version."
        }
        elseif (!$Script:PlexVersion) {
            Write-Verbose `
                "Version validation skipped because of the missing Plex Media Server version."
        }
        else {
            Write-Verbose ("Validating the backup version '$BackupVersion' " +
                "against the Plex Media Server version '$Script:PlexVersion'.")

            if ($Script:PlexVersion -ne $Script:BackupVersion) {
                Write-Verbose "Version mismatch is detected."

                if ($Script:NoVersion) {
                }
                else {
                    throw "Backup version '$Script:BackupVersion' does not match " +
                        "version '$Script:PlexVersion' of the Plex Media Server. " +
                        "To ignore version check, run the script with the " +
                        "'-NoVersion' flag."
                }
            }
        }
    }

    WriteDebug "Exiting ValidateVersion."
}

#--------------------------------------------------------------------------
# ValidateData
#   Validates required directories.
function ValidateData {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered ValidateData."

    try {
        # Make sure we have backup folder.
        if (!$Script:BackupDir) {
            throw "Path to backup data folder is not specified. " +
                "Please, make sure you set one of the following switches: " +
                "'-BackupRootDir', '-BackupDir'."
        }

        # For restore, we need the backup folder.
        if ($Script:Mode -eq $MODE_RESTORE) {
            if (!(Test-Path -Path $Script:BackupDir -PathType Container)) {
                throw "Backup data folder '$Script:BackupDir' does not exist."
            }
        }

        # We always need Plex app data folder.
        if (!$Script:PlexAppDataDir) {
            throw "Path to Plex app data folder is not specified. " +
                "It must default to '$env:LOCALAPPDATA\Plex Media Server' " +
                "but it is empty now. What have you done?"
        }

        # Plex app data folder must exist.
        if ($Script:Mode -ne $MODE_RESTORE) {
            if (!(Test-Path -Path $Script:PlexAppDataDir -PathType Container)) {
                throw "Plex app data folder '$Script:PlexAppDataDir' does not exist."
            }
        }

        # Check the important registry key.
        if ($Script:Mode -ne $MODE_RESTORE) {
            $key = $PLEX_REG_KEYS[0]

            if (!(Test-Path -Path $key)) {
                throw "Registry key '$key' does not exist."
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting ValidateData."
    }
}

#--------------------------------------------------------------------------
# ValidateSingleInstance
#   Validates that only one instance of the script is running.
function ValidateSingleInstance {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered ValidateSingleInstance."

    try {
        # Mutex for single-instance operation.
        if (!$Script:NoSingleton) {
            Write-Verbose "Making sure the script is not already running."

            if (!(Enter-SingleInstance $MUTEX_NAME)) {
                throw "The script is already running."
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting ValidateSingleInstance."
    }
}

#--------------------------------------------------------------------------
# MustSendMail
#   Returns 'true' if conditions for sending email notification about the
#   operation result are met; returns 'false' otherwise.
function MustSendMail {
    param (
        [ValidateSet($null, $true, $false)]
        [object]
        $success = $null
    )

    if ($Script:SendMail -eq $SEND_MAIL_NEVER) {
        return $false
    }

    if ($Script:SendMail -eq $SEND_MAIL_ALWAYS) {
        return $true
    }

    if ($Script:SendMail -eq $SEND_MAIL_SUCCESS) {
        if ($success -ne $false) {
            return $true
        }
        else {
            return $false
        }
    }

    if ($Script:SendMail -eq $SEND_MAIL_ERROR) {
        if ($success -ne $true) {
            return $true
        }
        else {
            return $false
        }
    }

    if ($Script:SendMail.StartsWith($SEND_MAIL_BACKUP)) {
        if ($Script:Mode -eq $MODE_RESTORE) {
            return $false
        }
        if (($Script:SendMail.EndsWith("Error")) -and ($success -eq $true)) {
            return $false
        }
        if (($Script:SendMail.EndsWith("Success")) -and ($success -eq $false)) {
            return $false
        }

        return $true
    }

    if ($Script:SendMail.StartsWith($SEND_MAIL_RESTORE)) {
        if ($Script:Mode -ne $MODE_RESTORE) {
            return $false
        }
        if (($Script:SendMail.EndsWith("Error")) -and ($success -eq $true)) {
            return $false
        }
        if (($Script:SendMail.EndsWith("Success")) -and ($success -eq $false)) {
            return $false
        }

        return $true
    }

    return $true
}

#--------------------------------------------------------------------------
# MustSendAttachment
#   Returns 'true' if conditions for sending the log file as an attachment
#   are met; returns 'false' otherwise.
function MustSendAttachment {
    [CmdletBinding()]
    param (
    )
    if ($Script:SendLogFile -eq $SEND_LOGFILE_NEVER) {
        return $false
    }

    $success = $true

    if ($Script:ErrorResult) {
        $success = $false
    }

    if (!$Script:LogFile) {
        return $false
    }

    if (!(Test-Path -Path $Script:LogFile -PathType Leaf)) {
        return $false
    }

    if ($Script:SendLogFile -eq $SEND_LOGFILE_ALWAYS) {
        return $true
    }

    if ($Script:SendLogFile -eq $SEND_LOGFILE_SUCCESS) {
        if ($success -ne $true) {
            return $false
        }
        else {
            return $true
        }
    }

    if ($Script:SendLogFile -eq $SEND_LOGFILE_ERROR) {
        if ($success -ne $false) {
            return $false
        }
        else {
            return $true
        }
    }

    return $true
}

#--------------------------------------------------------------------------
# GetPlexServerPath
#   Returns the path of the running Plex Media Server executable.
function GetPlexServerPath {
    param (
    )
    WriteDebug "Entered GetPlexServerPath."

    try {
        # Get path of the Plex Media Server executable.
        if (!$Script:PlexServerPath) {
            $Script:PlexServerPath = Get-Process |
                Where-Object {$_.Path -match $Script:PlexServerFileName + "$" } |
                    Select-Object -ExpandProperty Path
        }

        # Make sure we got the Plex Media Server executable file path.
        if (!$Script:PlexServerPath) {
            throw "Cannot determine path of the the Plex Media Server executable file " +
                "'$Script:PlexServerFileName' because it is not running."
        }

        # Verify that the Plex Media Server executable file exists.
        if (!(Test-Path -Path $Script:PlexServerPath -PathType Leaf)) {
            throw "Plex Media Server executable file '$Script:PlexServerPath' does not exist."
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting GetPlexServerPath."

    }

    return $Script:PlexServerPath
}

#--------------------------------------------------------------------------
# GetPlexVersion
#   Returns either file version of the current Plex Media Server executable.
function GetPlexVersion {
    param (
    )
    WriteDebug "Entered GetPlexVersion."

    [string]$version = $null
    [string]$path    = $null

    if ($Script:PlexServerPath) {
        $path = $Script:PlexServerPath
    }
    elseif ($DEFAULT_PLEX_SERVER_EXE_PATH) {
        $path = $DEFAULT_PLEX_SERVER_EXE_PATH
    }

    Write-Verbose "Setting Plex Media Server path for version checking to '$path'."

    try {
        if (($path) -and (Test-Path -Path $path -PathType Leaf)) {
            try {
                # Get version info from the assembly.
                Write-Verbose "Reading Plex Media Server version from '$path'."
                $version = (Get-Item $path).VersionInfo.FileVersion.Trim()
                Write-Verbose "Plex Media Server version: '$version'."
            }
            catch {
                throw (New-Object System.Exception( `
                    "Cannot get Plex Media Server version from '$path'.", `
                        $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting GetPlexVersion."
    }

    return $version
}

#--------------------------------------------------------------------------
# GetBackupVersion
#   Returns either version of the last saved backup (from the version.txt file).
function GetBackupVersion {
    param (
    )
    WriteDebug "Entered GetBackupVersion."

    [string]$version = $null

    try {
        if (($Script:VersionFilePath) -and (Test-Path -Path $Script:VersionFilePath -PathType Leaf)) {
            try {
                # Assume that this is a previous backup's version.txt file.
                Write-Verbose "Reading backup version from '$Script:VersionFilePath'."
                $version = (Get-Content -Path $Script:VersionFilePath).Trim()
                Write-Verbose "Backup version: '$version'."
            }
            catch {
                throw (New-Object System.Exception( `
                    "Cannot get backup version from '$Script:VersionFilePath'.", `
                        $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting GetBackupVersion."
    }

    return $version
}

#--------------------------------------------------------------------------
# SavePlexVersion
#   Saves current file version of the Plex Media Server executable to
#   the version.txt file.
function SavePlexVersion {
    param (
    )
    WriteDebug "Entered SavePlexVersion."


    if (!$Script:PlexVersion) {
        Write-LogWarning "Undefined Plex Media Server Version, so it will not be saved."
    }
    elseif (!$Script:VersionFilePath) {
        Write-LogWarning "Plex Media Server Version will not be saved because version file path is undefined."
    }
    else {
        if (!(Test-Path -Path $Script:VersionFilePath -PathType Leaf)) {
            Write-Verbose "Overwriting '$Script:VersionFilePath'."

            if (!$Script:Test) {
                New-Item -Path $Script:VersionFilePath -Type file -Force | Out-Null
            }
        }

        Write-LogInfo "Saving version:"
        Write-LogInfo $Script:PlexVersion -Indent 1
        Write-LogInfo "to:"
        Write-LogInfo $Script:VersionFilePath -Indent 1

        if (!$Script:Test) {
            $Script:PlexVersion | Set-Content -Path $Script:VersionFilePath
        }
    }

    WriteDebug "Exiting SavePlexVersion."
}

#--------------------------------------------------------------------------
# GetPlexServices
#   Returns the list of Plex Windows services (identified by display names).
function GetPlexServices {
    param (
    )
    WriteDebug "Entered GetPlexServices."

    $services = Get-Service |
        Where-Object {$_.DisplayName -match $PlexServiceName} |
            Where-Object {$_.status -eq 'Running'}

    if ($services) {
        Write-Verbose "$($services.Count) Plex service(s) detected running."
    }
    else {
        Write-Verbose "No Plex services detected running."

    }

    WriteDebug "Exiting GetPlexServices."
    return $services
}

#--------------------------------------------------------------------------
# StopPlexServices
#   Stops running Plex Windows services.
function StopPlexServices {
    param (
        [object[]]
        $services
    )
    WriteDebug "Entered StopPlexServices."

    # We'll keep track of every Plex service we successfully stopped.
    $stoppedPlexServices = [System.Collections.ArrayList]@()

    if ($services.Count -gt 0) {
        Write-LogInfo "Stopping Plex services:"

        foreach ($service in $services) {
            Write-LogInfo $service.DisplayName -Indent 1

            try {
                Stop-Service -Name $service.Name -Force
                ($stoppedPlexServices.Add($service)) | Out-Null
            }
            catch {
                Write-LogError "Failed to stop Windows service '$($service.DisplayName)'."
                WriteLogException $_

                $Error.Clear()
                return $false, $stoppedPlexServices
            }

        }
    }

    WriteDebug "Exiting StopPlexServices."
    return $true, $stoppedPlexServices
}

#--------------------------------------------------------------------------
# StartPlexServices
#   Starts Plex Windows services.
function StartPlexServices {
    param (
        [object[]]
        $services
    )
    WriteDebug "Entered StartPlexServices."

    if ($services -and ($services.Count -gt 0)) {
        Write-LogInfo "Starting Plex services:"

        foreach ($service in $services) {
            Write-LogInfo $service.DisplayName -Indent 1

            try {
                Start-Service -Name $service.Name
            }
            catch {
                Write-LogError "Failed to start Windows service '$($service.DisplayName)'."
                WriteLogException $_

                $Error.Clear()
                # Non-critical error; can continue.
            }
        }
    }

    WriteDebug "Exiting StartPlexServices."
}

#--------------------------------------------------------------------------
# StopPlexMediaServer
#   Stops a running instance of Plex Media Server.
function StopPlexMediaServer {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered StopPlexMediaServer."

    try {
        # If we have the path to Plex Media Server executable, see if it's running.
        if ($Script:PlexServerPath) {
            $exeFileName = Get-Process |
                Where-Object {$_.Path -eq $Script:PlexServerPath } |
                    Select-Object -ExpandProperty Name

            # Stop Plex Media Server executable (if it is running).
            if ($exeFileName) {
                Write-LogInfo "Stopping Plex Media Server process:"
                Write-LogInfo $Script:PlexServerFileName -Indent 1

                try {
                    # First, let's try to close Plex gracefully.
                    Write-Verbose "Trying to stop Plex Media Server process gracefully."
                    taskkill /im $Script:PlexServerFileName >$nul 2>&1

                    $timeoutSeconds = 60

                    # Keep checking to see if Plex is not longer running for at most 60 seconds.
                    Write-Verbose "Checking if Plex Media Server process stopped gracefully."
                    do {
                        # Sleep for a second.
                        Start-Sleep -Seconds 1
                        $timeoutSeconds--

                    } while (($timeoutSeconds -gt 0) -and
                        (Get-Process -ErrorAction SilentlyContinue |
                            Where-Object {$_.Path -match $Script:PlexServerFileName + "$" }))

                    # If Plex is still running, kill it along with all child processes forcefully.
                    if (Get-Process -ErrorAction SilentlyContinue |
                            Where-Object {$_.Path -match $Script:PlexServerFileName + "$" }) {

                        Write-Verbose "Failed to stop Plex Media Server process gracefully."
                        Write-Verbose "Killing Plex Media Server process."

                        taskkill /f /im $Script:PlexServerFileName /t >$nul 2>&1
                    }
                }
                catch {
                    throw (New-Object System.Exception( `
                        "Error stopping Plex Media Server.", $_.Exception))
                }
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting StopPlexMediaServer."
    }
}

#--------------------------------------------------------------------------
# StartPlexMediaServer
#   Launches Plex Media Server.
function StartPlexMediaServer {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered StartPlexMediaServer."

    if ($Script:PlexServerPath) {
        Write-Verbose "Checking if Plex Media Server is already running."

        # Get name of the Plex Media Server executable (just to see if it is running).
        $exeFileName = Get-Process |
            Where-Object {$_.Path -match $Script:PlexServerFileName + "$" } |
                Select-Object -ExpandProperty Name

        # Start Plex Media Server executable (if it is not running).
        if ($exeFileName) {
            Write-Verbose "Plex Media Server is already running."
        }
        else {
            Write-Verbose "Plex Media Server is not running."

            Write-LogInfo "Starting Plex Media Server:"
            Write-LogInfo $Script:PlexServerPath -Indent 1

            try {
                # Try to restart Plex not as Administrator.
                # Starting it as Administrator seems to mess up share mappings.
                # https://stackoverflow.com/questions/20218076/batch-file-drop-elevated-privileges-run-a-command-as-original-user

                # Start-Process $plexServerExePath -LoadUserProfile
                runas /trustlevel:0x20000 "$Script:PlexServerPath"
            }
            catch {
                Write-LogError "Failed to start Plex Media Server '$($service.DisplayName)'."
                WriteLogException $_

                $Error.Clear()
                # Non-critical error; can continue.
            }
        }
    }

    WriteDebug "Exiting StartPlexMediaServer."
}

#--------------------------------------------------------------------------
# FormatEmail
#   Formats HTML body for the notification email.
function FormatEmail {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered FormatEmail."

    $body = "
<!DOCTYPE html>
<head>
<title>Plex Backup Report</title>
</head>
<body>
<table style='#STYLE_PAGE#'>
<tr>
<td>
<span style='#STYLE_TEXT#'>Plex backup script</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_PATH#</span>
<span style='#STYLE_TEXT#'>completed the</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_MODE#</span>
<span style='#STYLE_TEXT#'>operation on</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_COMPUTER_NAME#</span>
<span style='#STYLE_TEXT#'>with the following result:</span>
</td>
</tr>
<tr>
<td style='#STYLE_PARA#'>
<span style='#STYLE_RESULT#'>#VALUE_RESULT#</span>
</td>
</tr>
<tr>
<td style='#STYLE_ERROR_PARA#'>
<span style='#STYLE_ERROR#'>#VALUE_ERROR_INFO#</span>
</td>
</tr>
<tr>
<td style='#STYLE_DATA_PARA#'>
<span style='#STYLE_DATA#'>The #VALUE_DATA_DIR_NAME# folder</span>
<span style='#STYLE_VAR_DATA#'>#VALUE_DATA_DIR_PATH#</span>
<span style='#STYLE_DATA#'>contains</span>
<span style='#STYLE_VAR_DATA#'>#VALUE_BACKUP_OBJECTS#</span>
<span style='#STYLE_DATA#'>objects</span>
<span style='#STYLE_DATA#'>and</span>
<span style='#STYLE_VAR_DATA#'>#VALUE_BACKUP_SIZE# GB</span>
<span style='#STYLE_DATA#'>of data.</span>
</td>
</tr>
<tr>
<td style='#STYLE_PARA#'>
<span style='#STYLE_TEXT#'>The script started at</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_START_TIME#</span>
<span style='#STYLE_TEXT#'>and ended at</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_END_TIME#</span>
<span style='#STYLE_TEXT#'>running for</span>
<span style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_DURATION#</span>
<span style='#STYLE_TEXT#'>(hr:min:sec.msec).</span>
</td>
</tr>
</table>
</body>
</html>
"
    $styleTextColor     = 'color: #444444;'
    $styleSuccessColor  = 'color: #6aa84f;'
    $styleErrorColor    = 'color: #cc2200;'

    $styleResultColor   = ''
    $resultText         = ''

    $styleErrorInfo     = 'mso-hide: all;overflow: hidden;max-height: 0;display: none;line-height: 0;visibility: hidden;'
    $styleErrorParagraph= $styleErrorInfo

    $styleDataInfo      = 'mso-hide: all;overflow: hidden;max-height: 0;display: none;line-height: 0;visibility: hidden;'
    $styleVarData       = 'mso-hide: all;overflow: hidden;max-height: 0;display: none;line-height: 0;visibility: hidden;'
    $styleDataParagraph = $styleDataInfo

    if ($Script:ErrorResult) {
        $styleResultColor  = $styleErrorColor
        $resultText = 'ERROR'
    }
    else {
        $styleResultColor = $styleSuccessColor
        $resultText  = 'SUCCESS'
    }

    $stylePage               = 'max-width: 800px;border: 0;padding: 0;'
    $styleFontFamily         = 'font-family: Arial,Helvetica,sans-serif;'
    $styleParagraph          = 'padding-top: 8px;'
    $styleTextFontSize       = 'font-size: 13px;'
    $styleResultTextFontSize = 'font-size: 18px;'
    $styleTextFont           = $styleFontFamily + $styleTextFontSize + $styleTextColor
    $styleVarTextFont        = $styleTextFont + 'font-weight: bold;'
    $styleResultTextFont     = $styleFontFamily + $styleResultTextFontSize + $styleResultColor + 'font-weight: bold;'

    $styleText               = $styleTextFont
    $styleVarText            = $styleVarTextFont
    $styleResult             = $styleResultTextFont

    [string]$backupMode     = $null
    [string]$dataDirName    = $null
    [string]$dataDirPath    = $null

    if ($Script:Type) {
        $backupMode = $Script:Mode.ToUpper() + " -" + $Type.ToUpper()
    }
    else {
        $backupMode = $Script:Mode.ToUpper()
    }

    if ($Script:Test) {
        $backupMode += " (TEST)"
    }

    if ($Script:Mode -eq $MODE_RESTORE) {
        $dataDirName = "Plex app data"
        $dataDirPath = $Script:PlexAppDataDir
    }
    else {
        $dataDirName = "backup"
        $dataDirPath = $Script:BackupDir
    }

    if ($Script:ErrorResult) {
        $styleErrorInfo      = $styleText
        $styleErrorParagraph = $styleParagraph
    }
    else {
        $styleDataInfo      = $styleText
        $styleVarData       = $styleVarText
        $styleDataParagraph = $styleParagraph
    }

    $emailTokens = @{
        STYLE_PAGE              = $stylePage
        STYLE_PARA              = $styleParagraph
        STYLE_TEXT              = $styleText
        STYLE_VAR_TEXT          = $styleVarText
        STYLE_ERROR             = $styleErrorInfo
        STYLE_ERROR_PARA        = $styleErrorParagraph
        STYLE_DATA              = $styleDataInfo
        STYLE_VAR_DATA          = $styleVarData
        STYLE_DATA_PARA         = $styleDataParagraph
        STYLE_RESULT            = $styleResult
        VALUE_BACKUP_MODE       = $backupMode
        VALUE_RESULT            = $resultText
        VALUE_COMPUTER_NAME     = $env:ComputerName
        VALUE_SCRIPT_PATH       = $PSCommandPath
        VALUE_DATA_DIR_NAME     = $dataDirName
        VALUE_DATA_DIR_PATH     = $dataDirPath
        VALUE_SCRIPT_START_TIME = $Script:StartTime
        VALUE_SCRIPT_END_TIME   = $Script:EndTime
        VALUE_SCRIPT_DURATION   = $Script:Duration
        VALUE_ERROR_INFO        = $Script:ErrorResult
        VALUE_BACKUP_OBJECTS    = $Script:ObjectCount
        VALUE_BACKUP_SIZE       = $Script:BackupSize
    }

    # $htmlEmail = Get-Content -Path TemplateLetter.txt -RAW
    foreach ($token in $emailTokens.GetEnumerator()) {
        $pattern = '#{0}#' -f $token.key
        $body = $body -replace $pattern, $token.Value
    }

    WriteDebug "Exiting FormatEmail."
    return $body
}

#--------------------------------------------------------------------------
# SendMail
#   Sends email notification with the information about the operation result.
function SendMail {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered SendMail."

    if (!$Script:From -or !$Script:To -or !$Script:SmtpServer) {
        Write-Verbose "Undefined SMTP settings (SmtpServer, To, From)."
        Write-Verbose "Email notification will not be sent."
    }
    else {
        $message = FormatEmail

        # WriteDebug $message

        [string]$subject = $null

        if ($Script:ErrorResult) {
            $subject = $SUBJECT_ERROR
        }
        else {
            $subject = $SUBJECT_SUCCESS
        }

        $params = @{}

        if ($Script:Port -gt 0) {
            $params.Add("Port", $Script:Port)
        }

        if ($Script:Credential) {
            $params.Add("Credential", $Script:Credential)
        }

        if (!($Script:NoSsl)) {
            $params.Add("UseSsl", $true)
        }

        if (MustSendAttachment) {
            $params.Add("Attachment", @( $Script:LogFile ))
        }

        Write-Verbose "Sending email notification to '$Script:To'."

        Send-MailMessage `
            @params `
            -From $Script:From `
            -To $Script:To `
            -Subject $subject `
            -Body $message `
            -BodyAsHtml `
            -SmtpServer $Script:SmtpServer
    }

    WriteDebug "Exiting SendMail."
}

#--------------------------------------------------------------------------
# RobocopyFiles
#   Copies the Plex app data folder using the Windows 'robocopy' tool.
function RobocopyFiles {
    param (
        [string]
        $source,

        [string]
        $target,

        [string[]]
        $excludeDirs,

        [string[]]
        $excludeFiles,

        [int]
        $retries,

        [int]
        $retryWaitSec
    )
    WriteDebug "Entered RobocopyFiles."

    # Build full paths to the excluded folders.
    $excludePaths = $null

    $cmdArgs = [System.Collections.ArrayList]@(
        "$source",
        "$target",
        "/MIR",
        "/R:$retries",
        "/W:$retryWaitSec",
        "/MT"
    )

    try {
        try {
            # Set directories to exclude from backup.
            if (($excludeDirs) -and ($excludeDirs.Count -gt 0)) {
                $excludePaths = [System.Collections.ArrayList]@()

                Write-LogInfo "Excluding folders:"

                # We need to use full paths.
                foreach ($excludeDir in $excludeDirs) {
                    Write-LogInfo $excludeDir -Indent 1
                    ($excludePaths.Add((Join-Path $source $excludeDir))) | Out-Null
                }

                $cmdArgs.Add("/XD") | Out-Null
                $cmdArgs.Add($excludePaths) | Out-Null
            }

            # Set file types to exclude (e.g. '*.bif').
            if (($excludeFiles) -and ($excludeFiles.Count -gt 0)) {
                Write-LogInfo "Excluding file types:"

                foreach ($excludeFile in $excludeFiles) {
                    Write-LogInfo $excludeFile -Indent 1
                }

                $cmdArgs.Add("/XF") | Out-Null
                $cmdArgs.Add($excludeFiles) | Out-Null
            }

            if (!$Script:RawOutput) {
                $sleepSec = 3
                Write-LogWarning "This operation may take a long time."
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "A really long time."
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "Like hours..."
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "Seriously!"
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "There will be no feedback unless something goes wrong."
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "If you get worried, use Task Manager to check CPU/disk usage."
                Start-Sleep -Seconds $sleepSec
                Write-LogWarning "Otherwise, take a break and come back later."
            }

            Write-LogInfo "Copying Plex app data files from:"
            Write-LogInfo $source -Indent 1
            Write-LogInfo "to:"
            Write-LogInfo $target -Indent 1
            Write-LogInfo "at:"
            Write-LogInfo (GetTimestamp) -Indent 1

            if (!$Script:Test) {
                if ($Script:Quiet -or (!$Script:RawOutput)) {
                    robocopy @cmdArgs *>&1 | Out-Null
                }
                else {
                    robocopy @cmdArgs
                }
            }
        }
        catch {
            throw (New-Object System.Exception( `
                "Error copying '$source' to '$target'. Robocopy failed.", `
                    $_.Exception))
        }

        if ($LASTEXITCODE -gt 7) {
            throw "Robocopy failed with error code $LASTEXITCODE. " +
                "To troubleshoot, execute the following command: " +
                "robocopy" +
                (((ConvertTo-Json -InputObject $cmdArgs -Compress) -replace "[\[\],]", " ") `
                    -replace "\s+"," ")
        }

        Write-LogInfo "Completed at:"
        Write-LogInfo (GetTimestamp) -Indent 1
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting RobocopyFiles."
    }
}

#--------------------------------------------------------------------------
# MoveFolder
#   Moves contents of a folder using a ROBOCOPY command.
function MoveFolder {
    param (
        [string]
        $source,

        [string]
        $target
    )
    WriteDebug "Entered MoveFolder."

    if (!(Test-Path -Path $source -PathType Container)) {
        Write-LogWarning "Folder not found:"
        Write-LogWarning $source -Indent 1
        Write-LogWarning "Skipping."

        WriteDebug "Exiting MoveFolder."
    }

    Write-LogInfo "Moving:"
    Write-LogInfo $source -Indent 1
    Write-LogInfo "to:"
    Write-LogInfo $target -Indent 1
    Write-LogInfo "at:"
    Write-LogInfo (GetTimestamp) -Indent 1

    try {
        try {
            if (!$Script:Test) {
                if ($Script:Quiet -or (!$Script:RawOutput)) {
                    robocopy "$source" "$target" *.* /e /is /it *>&1 | Out-Null
                }
                else {
                    robocopy "$source" "$target" *.* /e /is /it
                }
            }
        }
        catch {
            throw (New-Object System.Exception( `
                "Robocopy failed.", $_.Exception))
        }

        if ($LASTEXITCODE -gt 7) {
            throw "Robocopy failed with error code $LASTEXITCODE. " +
                "To troubleshoot, execute the following command: " +
                "robocopy '$source' '$target' *.* /e /is /it"
        }

        Write-LogInfo "Completed at:"
        Write-LogInfo (GetTimestamp) -Indent 1
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting MoveFolder."
    }
}

#--------------------------------------------------------------------------
# CopyFolder
#   Moves contents of a folder using a ROBOCOPY command.
function CopyFolder {
    param (
        [string]
        $source,

        [string]
        $target
    )
    WriteDebug "Entered CopyFolder."

    try {
        if (!(Test-Path -Path $source -PathType Container)) {
            Write-LogWarning "Folder not found:"
            Write-LogWarning $source -Indent 1
            Write-LogWarning "Skipping."

            return
        }

        Write-LogInfo "Copying:"
        Write-LogInfo $source -Indent 1
        Write-LogInfo "to:"
        Write-LogInfo $target -Indent 1
        Write-LogInfo "at:"
        Write-LogInfo (GetTimestamp) -Indent 1

        try {
            if (!$Script:Test) {
                if ($Script:Quiet -or (!$Script:RawOutput)) {
                    robocopy "$source" "$target" *.* /e /is /it /move *>&1 | Out-Null
                }
                else {
                    robocopy "$source" "$target" *.* /e /is /it /move
                }
            }
        }
        catch {
            throw (New-Object System.Exception( `
                "Robocopy failed.", $_.Exception))
        }

        if ($LASTEXITCODE -gt 7) {
            throw "Robocopy failed with error code $LASTEXITCODE. " +
                "To troubleshoot, execute the following command: "
                "robocopy '$source' '$target' *.* /e /is /it /move"
        }

        Write-LogInfo "Completed at:"
        Write-LogInfo (GetTimestamp) -Indent 1
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting CopyFolder."
    }
}

#--------------------------------------------------------------------------
# BackupSpecialFolders
#   Moves contents of the special Plex app data folders to special backup
#   folder to exclude them from the backup compression job, so that they
#   could be copied separately (because special directories have long names,
#   they can break archival process used by PowerShell's Compress-Archive
#   command).
function BackupSpecialFolders {
    param (
        [string[]]
        $specialDirs,

        [string]
        $plexAppDataDir,

        [string]
        $backupDirPath
    )
    WriteDebug "Entered BackupSpecialFolders."

    try {
        if (!($specialDirs) -or
            ($specialDirs.Count -eq 0)) {
            return $true
        }

        $i = 0
        foreach ($specialDir in $specialDirs) {
            $source = Join-Path $plexAppDataDir $specialDir

            if (!(Test-Path -Path $source -PathType Container)) {
                continue
            }

            $target = Join-Path $backupDirPath $specialDir

            try {
                if ($i++ -eq 0) {
                    Write-LogInfo "Backing up special folders."
                }
                MoveFolder $source $target
            }
            catch {
                throw (New-Object System.Exception(
                    "Error moving '$source' to '$tartget'.", $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting BackupSpecialFolders."
    }
}

#--------------------------------------------------------------------------
# RestoreSpecialFolders
#   Copies backed up special Plex app data folders back to their original
#   locations (see also BackupSpecialFolders).
function RestoreSpecialFolders {
    param (
        [string[]]
        $specialDirs,

        [string]
        $plexAppDataDir,

        [string]
        $backupDirPath
    )
    WriteDebug "Entered RestoreSpecialFolders."

    try {
        if ($specialDirs -and
            $specialDirs.Count -gt 0) {

            $i = 0
            foreach ($specialDir in $specialDirs) {
                $source = Join-Path $backupDirPath $specialDir

                if (!(Test-Path -Path $source -PathType Container)) {
                    continue
                }

                $target = Join-Path $plexAppDataDir $specialDir

                try {
                    if ($i++ -eq 0) {
                        Write-LogInfo "Restoring special folders."
                    }

                    CopyFolder $source $target
                }
                catch {
                    throw (New-Object System.Exception(
                        "Error copying '$source' to '$tartget'.", $_.Exception))
                }
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting RestoreSpecialFolders."
    }
}

#--------------------------------------------------------------------------
# CompressFolder
#   Backs up contents of a Plex app data subfolder to a compressed file.
function CompressFolder {
    [CmdletBinding()]
    param (
        [object]
        $sourceDir,

        [string]
        $backupDirPath
    )
    WriteDebug "Entered CompressFolder."

    try {
        $zipFileName = $sourceDir.Name + $Script:ZipFileExt
        $zipFilePath = Join-Path $backupDirPath $zipFileName

        # Skip if ZIP file already exists.
        if (Test-Path $zipFilePath -PathType Leaf) {
            Write-LogWarning "Backup file:"
            Write-LogWarning $zipFilePath -Indent 1
            Write-LogWarning "already exists."

            if ($Script:Mode -eq $MODE_BACKUP) {
                try {
                    Write-LogInfo "Deleting:"
                    Write-LogInfo $zipFilePath -Indent 1

                    if (!$Script:Test) {
                        Remove-Item $zipFilePath -Force
                    }
                }
                catch {
                    throw (New-Object System.Exception( `
                        "Cannot delete existing file '$zipFilePath'.",  `
                        $_.Exception))
                }
            }
        }

        if (!(Test-Path $zipFilePath -PathType Leaf)) {
            # If a staged temp folder is specified (instead of compressing over network)...
            if ($Script:TempDir) {
                $tempZipFileName = $BACKUP_FILENAME + (New-Guid).Guid + $Script:ZipFileExt
                $tempZipFilePath = Join-Path $Script:TempDir $tempZipFileName
            }
            else {
                # Use temp names for the final files.
                $tempZipFileName = $zipFileName
                $tempZipFilePath = $zipFilePath
            }

            Write-LogInfo "Archiving:"
            Write-LogInfo $sourceDir.FullName -Indent 1
            Write-LogInfo "to:"
            Write-LogInfo $tempZipFilePath -Indent 1
            Write-LogInfo "at:"
            Write-LogInfo (GetTimestamp) -Indent 1

            if ($Script:Type -eq $TYPE_7ZIP) {
                [Array]$cmdArgs = "a", "$tempZipFilePath", (Join-Path $sourceDir.FullName "*"), "-r", "-y"

                if ($Script:ExcludeFiles -and $Script:ExcludeFiles.Count -gt 0) {
                    Write-Verbose "Excluding file types: $excludeFiles"

                    foreach ($excludeFile in $Script:ExcludeFiles) {
                        if ($excludeFile) {
                            $cmdArgs += "-x!$excludeFile"
                        }
                    }
                }

                if ($Script:ArchiverOptionsCompress -and $Script:ArchiverOptionsCompress.Count -gt 0) {
                    Write-Verbose "Setting 7-zip switches: $($Script:ArchiverOptionsCompress)"

                    foreach ($option in $Script:ArchiverOptionsCompress) {
                        if ($option) {
                            $cmdArgs += $option
                        }
                    }
                }

                if (!$Script:Test) {
                    if ($Script:Quiet -or (!$Script:RawOutput)) {
                        & $Script:ArchiverPath @cmdArgs *>&1 | Out-Null
                    }
                    else {
                        & $Script:ArchiverPath @cmdArgs
                    }
                }

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned '$LASTEXITCODE'.")
                }
            }
            else {
                if (!$Script:Test) {
                    Compress-Archive -Path (Join-Path $sourceDir.FullName "*") `
                        -DestinationPath $tempZipFilePath -Force
                }
            }

            Write-LogInfo "Completed at:"
            Write-LogInfo (GetTimestamp) -Indent 1

            Write-LogInfo "Compressed file size:"
            Write-LogInfo (FormatFileSize $tempZipFilePath) -Indent 1

            # When using temp folder, need to copy archived file to final destination.
            if ($Script:TempDir) {
                # If the folder was empty, the ZIP file will not be created.
                if ((!$Script:Test) -and (!(Test-Path $tempZipFilePath -PathType Leaf))) {
                    Write-LogWarning "Temp archive file was not created."
                }
                else {
                    # Copy temp ZIP file from the backup folder.
                    Write-LogInfo "Copying:"
                    Write-LogInfo $tempZipFilePath -Indent 1
                    Write-LogInfo "to:"
                    Write-LogInfo $zipFilePath -Indent 1
                    Write-LogInfo "at:"
                    Write-LogInfo (GetTimestamp) -Indent 1

                    try {
                        if (!$Script:Test) {
                            Start-BitsTransfer -Source $tempZipFilePath `
                                -Destination $zipFilePath -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-LogError "Error copying:"
                        Write-LogError $tempZipFilePath -Indent 1
                        Write-LogError "to:"
                        Write-LogError $zipFilePath -Indent 1
                        WriteLogException $_

                        try {
                            if ((!$Script:Test) -and (Test-Path $tempZipFilePath -PathType Leaf)) {
                                Write-Verbose "Deleting '$tempZipFilePath'."
                                Remove-Item $tempZipFilePath -Force
                            }
                        }
                        catch {
                            Write-Verbose "Cannot delete '$tempZipFilePath'."
                            Write-Verbose (FormatError $_)
                        }

                        throw "BitTransfer operation failed."
                    }

                    Write-LogInfo "Completed at:"
                    Write-LogInfo (GetTimestamp) -Indent 1

                    # Delete temp file.
                    if (Test-Path -Path $tempZipFilePath -PathType Leaf) {
                        try {
                            if ((!$Script:Test) -and (Test-Path $tempZipFilePath -PathType Leaf)) {
                                Write-Verbose "Deleting '$tempZipFilePath'."
                                Remove-Item $tempZipFilePath -Force
                            }
                        }
                        catch {
                            Write-Verbose "Cannot delete '$tempZipFilePath'."
                            Write-Verbose (FormatError $_)

                            # Non-critical error; can continue.
                            $Error.Clear()
                        }
                    }
                }
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting CompressFolder."
    }
}

#--------------------------------------------------------------------------
# CompressFiles
#   Backs up contents of the Plex app data folder to the compressed files.
function CompressFiles {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered CompressFiles."

    try {
        # Build path to the ZIP file that will hold files from Plex app data folder.
        $zipFileName = $BACKUP_FILENAME + $Script:ZipFileExt
        $zipFileDir  = Join-Path $Script:BackupDir $SUBDIR_FILES
        $zipFilePath = Join-Path $zipFileDir $zipFileName

        # Back up files from root folder, if there are any.
        if (@(Get-ChildItem (Join-Path $Script:PlexAppDataDir "*") -File ).Count -gt 0) {

            Write-LogInfo "Backing up Plex app data files in the root folder."

            # Delete existing backup file in the BACKUP mode.
            if (Test-Path $zipFilePath -PathType Leaf) {
                Write-LogWarning "Backup file:"
                Write-LogWarning $zipFilePath -Indent 1
                Write-LogWarning "already exists."

                if ($Script:Mode -eq $MODE_BACKUP) {
                    try {
                        Write-LogInfo "Deleting:"
                        Write-LogInfo $zipFilePath -Indent 1

                        if (!$Script:Test) {
                            Remove-Item $zipFilePath -Force
                        }
                    }
                    catch {
                        throw (New-Object System.Exception( `
                            "Cannot delete existing file '$zipFilePath'.",  `
                            $_.Exception))
                    }
                }
            }

            # Only process if zip file is not there.
            if (!(Test-Path $zipFilePath -PathType Leaf)) {
                try {
                    if ($Script:Type -eq $TYPE_7ZIP) {

                        # Set default arguments for compression.
                        [Array]$cmdArgs = "a", "$zipFilePath", "-y"

                        # If we have a list of file types to exclude, set the appropriate argument.
                        if ($Script:ExcludeFiles -and $Script:ExcludeFiles.Count -gt 0) {
                            Write-Verbose "Excluding file types: $($Script:ExcludeFiles)"

                            foreach ($excludeFile in $Script:ExcludeFiles) {
                                if ($excludeFile) {
                                    $cmdArgs += "-x!$excludeFile"
                                }
                            }
                        }

                        # Also, support user-provided command-line switches.
                        if ($Script:ArchiverOptionsCompress -and $Script:ArchiverOptionsCompress.Count -gt 0) {
                            Write-Verbose "Setting 7-zip switches: $($Script:ArchiverOptionsCompress)"

                            foreach ($option in $Script:ArchiverOptionsCompress) {
                                if ($option) {
                                    $cmdArgs += $option
                                }
                            }
                        }
                        if (!$Script:Test) {
                            if ($Script:Quiet -or (!$Script:RawOutput)) {
                                & $Script:ArchiverPath @cmdArgs (Get-ChildItem (Join-Path $Script:PlexAppDataDir "*") -File) *>&1 | Out-Null
                            }
                            else {
                                & $Script:ArchiverPath @cmdArgs (Get-ChildItem (Join-Path $Script:PlexAppDataDir "*") -File)
                            }
                        }

                        if ($LASTEXITCODE -gt 0) {
                            throw "7-zip returned '$LASTEXITCODE'."
                        }
                    }
                    else {
                        # Use the default compression.
                        if (!$Script:Test) {
                            Get-ChildItem -Path $Script:PlexAppDataDir -File | `
                                Compress-Archive -DestinationPath '$zipFilePath' -Update
                        }
                    }
                }
                catch {
                    throw (New-Object System.Exception( `
                        "Error compressing files in the Plex app data root folder.", `
                        $_.Exception))
                }

                if (Test-Path $zipFilePath -PathType Leaf) {
                    Write-LogInfo "Completed at:"
                    Write-LogInfo (GetTimestamp) -Indent 1

                    Write-LogInfo "Compressed file size:"
                    Write-LogInfo (FormatFileSize $zipFilePath) -Indent 1
                }
                else {
                    Write-LogInfo "No files found in '$Script:PlexAppDataDir' (it's okay)."
                }
            }
        }

        Write-LogInfo "Backing up Plex app data folders."

        $plexAppDataSubDirs = Get-ChildItem $Script:PlexAppDataDir -Directory  |
            Where-Object { $_.Name -notin $Script:ExcludeDirs }

        foreach ($plexAppDataSubDir in $plexAppDataSubDirs) {
            try {
                CompressFolder `
                    $plexAppDataSubDir `
                    (Join-Path $Script:BackupDir $SUBDIR_FOLDERS)
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error compressing folder '$plexAppDataSubDir'.", $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting CompressFiles."
    }
}

#--------------------------------------------------------------------------
# PurgeOldBackups
#   Deletes old backup folders.
function PurgeOldBackups {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered PurgeOldBackups."

    # Delete old backup folders.
    if ($Script:Keep -gt 0) {

        # Get all folders with names from newest to oldest.
        # Do not include the backup directory if it already exists.
        $oldBackupDirs = Get-ChildItem -Path $Script:BackupRootDir -Directory |
            Where-Object {
                $_.Name -match $REGEX_BACKUPDIRNAMEFORMAT -and
                $_.Name -notmatch $Script:BackupDirName
            } | Sort-Object -Descending

        $i = 1

        # Check if we got more backups than we need to keep.
        if ($oldBackupDirs.Count -ge $Script:Keep) {
            Write-LogInfo "Deleting old backup folder(s):"
        }

        # Remove the oldest backup folders over the threshold.
        foreach ($oldBackupDir in $oldBackupDirs) {
            if ($i++ -ge $Script:Keep) {
                Write-LogInfo $oldBackupDir.Name -Indent 1

                try {
                    if (!$Script:Test) {
                        Remove-Item $oldBackupDir.FullName -Force -Recurse
                    }
                }
                catch {
                    Write-LogError "Cannot delete folder '$($oldBackupDir.FullName)."
                    WriteLogException $_

                    # Non-critical error; can continue.
                    $Error.Clear()
                }
            }
        }
    }

    WriteDebug "Exiting PurgeOldBackups."
}

#--------------------------------------------------------------------------
# SetUpBackupFolder
#   Gets the backup folder ready.
function SetUpBackupFolder {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered SetUpBackupFolder."

    try {
        # Verify that temp folder exists (if specified).
        if ($Script:Type -ne $TYPE_7ZIP) {
            if ($Script:TempDir) {
                # Make sure temp folder exists.
                if (!(Test-Path -Path $Script:TempDir -PathType Container)) {
                    try {
                        Write-LogInfo "Creating temp archive folder:"
                        Write-LogInfo $Script:TempDir -Indent 1

                        if (!$Script:Test) {
                            New-Item -Path $Script:TempDir -ItemType Directory -Force | Out-Null
                        }
                    }
                    catch {
                        throw (New-Object System.Exception(
                            "Cannot create temp archive folder '$Script:TempDir'.",
                            $_.Exception))
                    }
                }

                if (!$Script:Test) {
                    $tempFileMask = $BACKUP_FILENAME + "*$Script:ZipFileExt"

                    Write-Verbose "Purging '$tempFileMask' from '$Script:TempDir'."
                    Get-ChildItem -Path $Script:TempDir -Include $tempFileMask |
                            Remove-Item -Force | Out-Null
                }
            }
        }

        # Make sure that the backup parent folder exists.
        if (!(Test-Path $Script:BackupRootDir -PathType Container)) {
            try {
                Write-LogInfo "Creating backup root folder:"
                Write-LogInfo $Script:BackupRootDir -Indent 1

                if (!$Script:Test) {
                    New-Item -Path $Script:BackupRootDir -ItemType Directory -Force | Out-Null
                }

            }
            catch {
                throw (New-Object System.Exception( `
                    "Failed to create backup root folder '$Script:BackupRootDir'.", `
                    $_.Exception))
            }
        }

        # Verify that we got the backup root folder.
        if (!(Test-Path $Script:BackupRootDir -PathType Container)) {
            throw "Backup root folder '$Script:BackupRootDir' does not exist."
        }

        # Build backup folder path.
        Write-LogInfo "Backup will be saved in:"
        Write-LogInfo $Script:BackupDir -Indent 1

        PurgeOldBackups

        if (!(Test-Path -Path $Script:BackupDir -PathType Container)) {
            # Create new backup folder.
            try {
                    Write-LogInfo "Creating backup folder:"
                    Write-LogInfo $Script:BackupDir -Indent 1

                    if (!$Script:Test) {
                        New-Item -Path $Script:BackupDir -ItemType Directory -Force | Out-Null
                    }
            }
            catch {
                throw (New-Object System.Exception(
                    "Cannot create backup folder '$Script:BackupDir'.",
                    $_.Exception))
            }
        }

        # List of backup subfolders.
        $subDirs = @($SUBDIR_FILES, $SUBDIR_FOLDERS, $SUBDIR_REGISTRY, $SUBDIR_SPECIAL)

        # For backup mode, let's clear the contents of the subfolders, if they exist.
        if ($Script:Mode -eq $MODE_BACKUP) {
            $printMsg = $false
            foreach ($subDir in $subDirs) {
                $subDirPath = Join-Path $Script:BackupDir $subDir

                # For backup mode, let's clear the contents of the subfolder, if it exists.
                if (Test-Path -Path $subDirPath -PathType Container) {
                    if (!$printMsg) {
                        Write-LogInfo "Purging old backup files from task-specific subfolders in:"
                        Write-LogInfo $Script:BackupDir -Indent 1

                        $printMsg = $true
                    }

                    try {
                        Write-LogInfo $subDir -Indent 2

                        if (!$Script:Test) {
                            Get-ChildItem -Path $subDirPath -Include * | Remove-Item -Recurse -Force | Out-Null
                        }
                    }
                    catch {
                        throw (New-Object System.Exception(
                            "Cannot purge old backup files from folder '$subDirPath'.",
                            $_.Exception))
                    }
                }
            }
        }

        # Create subfolders, if needed.
        $printMsg = $false
        foreach ($subDir in $subDirs) {
            $subDirPath = Join-Path $Script:BackupDir $subDir

            if (!(Test-Path -Path $subDirPath -PathType Container)) {
                if (!$printMsg) {
                    Write-LogInfo "Creating task-specific subfolders in:"
                    Write-LogInfo $Script:BackupDir -Indent 1

                    $printMsg = $true
                }

                try {
                    Write-LogInfo $subDir -Indent 2

                    if (!$Script:Test) {
                        New-Item -Path $subDirPath -ItemType Directory -Force | Out-Null
                    }
                }
                catch {
                    throw (New-Object System.Exception(
                        "Cannot create folder '$subDirPath'.",
                        $_.Exception))
                }
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting SetUpBackupFolder."
    }
}

#--------------------------------------------------------------------------
# Backup
#   Creates a backup for the Plex app data folder and registry key.
function Backup {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered Backup."

    try {
        # Just in case the backup folder is on a remote share, try waking it up.
        WakeUpDir $Script:BackupRootDir

        SetUpBackupFolder

        # Save Plex version first in case we need to run in Continue mode later.
        try {
            SavePlexVersion
        }
        catch {
            throw (New-Object System.Exception("Error saving Plex Media Server version.", $_.Exception))
        }

        if ($Script:Type -eq $TYPE_ROBOCOPY) {
            RobocopyFiles `
                    $Script:PlexAppDataDir `
                    (Join-Path $Script:BackupDir $SUBDIR_FILES) `
                    $Script:ExcludeDirs `
                    $Script:ExcludeFiles `
                    $Script:Retries `
                    $Script:RetryWaitSec
        }
        else {
            try
            {
                # Temporarily move special subfolders to backup folder.
                try {
                    BackupSpecialFolders `
                        $Script:SpecialDirs `
                        $Script:PlexAppDataDir `
                        (Join-Path $Script:BackupDir $SUBDIR_SPECIAL)
                }
                catch {
                    throw (New-Object System.Exception( `
                        "Error backing up special folders.", $_.Exception))
                }

                # Compress and archive Plex app data.
                try {
                    CompressFiles
                }
                catch {
                    throw (New-Object System.Exception( `
                        "Error compressing Plex app data files.", $_.Exception))
                }
            }
            catch {
                throw
            }
            finally {
                try {
                    RestoreSpecialFolders `
                        $Script:SpecialDirs `
                        $Script:PlexAppDataDir `
                        (Join-Path $Script:BackupDir $SUBDIR_SPECIAL)
                }
                catch {
                    Write-LogError "Error restoring special folders."
                    WriteLogException $_

                    $Error.Clear()
                }
            }
        }

        # Export Plex registry keys.
        foreach ($plexRegKey in $PLEX_REG_KEYS) {
            if (!(Test-Path -Path $plexRegKey)) {
                continue
            }

            $plexRegKey = $plexRegKey.Replace(":", "")
            $plexRegKeyFilePath = ((Join-Path (Join-Path $Script:BackupDir $SUBDIR_REGISTRY) `
                ((FormatRegFilename $plexRegKey) + $regFileExt)))

            Write-LogInfo "Exporting registry key:"
            Write-LogInfo $plexRegKey -Indent 1
            Write-LogInfo "to:"
            Write-LogInfo $plexRegKeyFilePath -Indent 1

            try {
                if (!$Script:Test) {
                    reg export $plexRegKey $plexRegKeyFilePath /y *>&1 | Out-Null
                }
            }
            catch {
                WriteLogException $_

                # Non-critical error; can continue.
                $Error.Clear()
            }

            $i++
        }

        # Copy moved special subfolders back to original folders.
        if ($Script:Type -ne $TYPE_ROBOCOPY) {
            try {
                RestoreSpecialFolders `
                    $Script:SpecialDirs `
                    $Script:PlexAppDataDir `
                    (Join-Path $Script:BackupDir $SUBDIR_SPECIAL)
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error restoring special folders after a successful backup.", `
                    $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting Backup."
    }
}

#--------------------------------------------------------------------------
# DecompressFolder
#   Restores a Plex app data folder from the corresponding compressed
#   backup file.
function DecompressFolder {
    [CmdletBinding()]
    param (
        [object]
        $zipFile
    )
    WriteDebug "Entered DecompressFolder."

    try {
        $zipFilePath  = $zipFile.FullName
        $plexAppDataDirName = $zipFile.BaseName
        $plexAppDataDirPath = Join-Path $plexAppDataDir $plexAppDataDirName

        # If we have a temp folder, stage the extracting job.
        if ($Script:TempDir) {
            $tempZipFileName = $BACKUP_FILENAME + (New-Guid).Guid + $Script:ZipFileExt
            $tempZipFilePath = Join-Path $Script:TempDir $tempZipFileName

            # Copy backup archive to a temp zip file.
            Write-LogInfo "Copying:"
            Write-LogInfo $zipFilePath -Indent 1
            Write-LogInfo "to:"
            Write-LogInfo $tempZipFilePath -Indent 1
            Write-LogInfo "at:"
            Write-LogInfo (GetTimestamp) -Indent 1

            try {
                if (!$Script:Test) {
                    Start-BitsTransfer -Source $zipFilePath `
                        -Destination $tempZipFilePath -ErrorAction Stop
                }
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error copying '$zipFilePath' to '$tempZipFilePath'.", `
                    $_.Exception))
            }

            Write-LogInfo "Completed at:"
            Write-LogInfo (GetTimestamp) -Indent 1
        }
        else {
            $tempZipFilePath = $zipFilePath
        }

        Write-LogInfo "Restoring:"
        Write-LogInfo $plexAppDataDirPath -Indent 1
        Write-LogInfo "from:"
        Write-LogInfo $tempZipFilePath -Indent 1
        Write-LogInfo "at:"
        Write-LogInfo (GetTimestamp) -Indent 1

        if ($Script:Type -eq $TYPE_7ZIP) {
            [Array]$cmdArgs

            if ($Script:ArchiverOptionsExpand -and $Script:ArchiverOptionsExpand.Count -gt 0) {
                Write-Verbose "Setting 7-zip switches: $($Script:ArchiverOptionsExpand)"

                foreach ($option in $Script:ArchiverOptionsExpand) {
                    if ($option) {
                        $cmdArgs += $option
                    }
                }
            }

            if (!$Script:Test) {
                if ($Script:Quiet -or (!$Script:RawOutput)) {
                    & $Script:ArchiverPath "x" "$tempZipFilePath" "-o$plexAppDataDirPath" "-aoa" "-y" @cmdArgs *>&1 | Out-Null
                }
                else {
                    & $Script:ArchiverPath "x" "$tempZipFilePath" "-o$plexAppDataDirPath" "-aoa" "-y" @cmdArgs
                }
            }

            if ($LASTEXITCODE -gt 0) {
                throw ("7-zip returned '$LASTEXITCODE'.")
            }
        }
        else {
            if (!$Script:Test) {
                Expand-Archive -Path $tempZipFilePath `
                    -DestinationPath $plexAppDataDirPath -Force
            }
        }

        Write-LogInfo "Completed at:"
        Write-LogInfo (GetTimestamp) -Indent 1

        # Delete temp file.
        if ($Script:TempDir) {
            Write-LogInfo "Deleting:"
            Write-LogInfo $tempZipFilePath -Indent 1

            try {
                if (!$Script:Test) {
                    Remove-Item $tempZipFilePath -Force
                }
            }
            catch {
                Write-LogError "Cannot delete temp file:"
                Write-LogError $tempZipFilePath -Indent 1
                WriteLogException $_

                # Non-critical error; can continue.
                $Error.Clear()
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting DecompressFolder."
    }
}

#--------------------------------------------------------------------------
# DecompressFiles
#   Restores Plex app data folders from the compressed backup files.
function DecompressFiles {
    [CmdletBinding()]
    param (
    )
    WriteDebug "Entered DecompressFiles."

    try {
        # Build path to the ZIP file that holds files from the root Plex app data folder.
        $zipFileName = $BACKUP_FILENAME + $Script:ZipFileExt
        $zipFileDir  = Join-Path $Script:BackupDir $SUBDIR_FILES
        $zipFilePath = Join-Path $zipFileDir $zipFileName

        # Restore files in the root Plex app data folder.
        if (Test-Path -Path $zipFilePath -PathType Leaf) {
            Write-LogInfo "Restoring Plex app data files in the root folder."

            try {
                if ($Script:Type -eq $TYPE_7ZIP) {
                    [Array]$cmdArgs

                    if ($Script:ArchiverOptionsExpand -and $Script:ArchiverOptionsExpand.Count -gt 0) {
                        Write-Verbose "Setting 7-zip switches: $($Script:ArchiverOptionsExpand)"

                        foreach ($option in $Script:ArchiverOptionsExpand) {
                            if ($option) {
                                $cmdArgs += $option
                            }
                        }
                    }

                    if (!$Script:Test) {
                        if ($Script:Quiet -or (!$Script:RawOutput)) {
                            & $Script:ArchiverPath "x" "$zipFilePath" "-o$Script:PlexAppDataDir" "-y" @cmdArgs *>&1 | Out-Null
                        }
                        else {
                            & $Script:ArchiverPath "x" "$zipFilePath" "-o$Script:PlexAppDataDir" "-y" @cmdArgs
                        }
                    }

                    if ($LASTEXITCODE -gt 0) {
                        throw "7-zip returned '$LASTEXITCODE'."
                    }
                }
                else {
                    if (!$Script:Test) {
                        Expand-Archive -Path $zipFilePath -DestinationPath $Script:PlexAppDataDir -Force
                    }
                }
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error decompressing files in the Plex app data root folder.", `
                    $_.Exception))
            }
        }

        Write-LogInfo "Restoring Plex app data folders."

        $zipFiles = Get-ChildItem `
            (Join-Path $Script:BackupDir $SUBDIR_FOLDERS) -File  |
                Where-Object { $_.Extension -eq $Script:ZipFileExt }

        # Restore each Plex app data subfolder from the corresponding backup archive file.
        foreach ($zipFile in $zipFiles) {
            try {
                DecompressFolder $zipFile
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error decompressing file '$zipFile'.", $_.Exception))
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting CompressFiles."
    }
}

#--------------------------------------------------------------------------
# Restore
#   Restores Plex app data and registry key from a backup.
function Restore {
    param (
    )
    WriteDebug "Entered Restore."

    try {
        if ($Script:Type -eq $TYPE_ROBOCOPY) {
            RobocopyFiles `
                (Join-Path $Script:BackupDir $SUBDIR_FILES) `
                $Script:PlexAppDataDir `
                $null `
                $null `
                $Script:Retries `
                $Script:RetryWaitSec
        }
        else {
            # Compress and archive Plex app data.
            try {
                DecompressFiles
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error decompressing Plex app data files.", $_.Exception))
            }

            # Restore special subfolders.
            try {
                RestoreSpecialFolders `
                    $Script:SpecialDirs `
                    $Script:PlexAppDataDir `
                    (Join-Path $Script:BackupDir $subDirSpecial)
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error restoring special folders.", $_.Exception))
            }
        }

        # Import Plex registry keys.
        $backupRegKeyFiles = Get-ChildItem `
            (Join-Path $Script:BackupDir $SUBDIR_REGISTRY) -File  |
                Where-Object { $_.Extension -eq $regFileExt }

        # Restore each Plex app data subfolder from the corresponding backup archive file.
        $i = 0
        foreach ($backupRegKeyFile in $backupRegKeyFiles) {
            $backupRegKeyFilePath = $backupRegKeyFile.FullName

            if ($i++ -eq 0) {
                Write-LogInfo "Importing registry key file:"
            }
            Write-LogInfo $backupRegKeyFilePath -Indent 1

            try {
                if (!$Script:Test) {
                    # https://stackoverflow.com/questions/61483349/powershell-throws-terminating-error-on-reg-import-but-operation-completes-succes
                    $process = Start-Process reg -ArgumentList "import `"$backupRegKeyFilePath`"" -PassThru -Wait

                    if ($process.ExitCode -ne 0) {
                        throw "Process 'reg import' returned $($process.ExitCode)."
                    }
                }
            }
            catch {
                # This is a bogus error that only appears in PowerShell ISE, so ignore.
                #if (-not ($_.Exception -and $_.Exception.Message -and
                #    ($_.Exception.Message -match "^The operation completed successfully"))) {
                        throw (New-Object System.Exception( `
                            "Error importing '$backupRegKeyFilePath'.", $_.Exception))
                #}
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting Restore."
    }
}

#--------------------------------------------------------------------------
# ProcessBackup
#   Implements the backup operations.
function ProcessBackup {
    [CmdletBinding()]
    param(
    )
    WriteDebug "Entered ProcessBackup."

    try {
        Write-LogInfo "Operation mode:"
        $mode = $Script:Mode.ToUpper()
        if ($Script:Test) {
            $mode += " (TEST)"
        }
        Write-LogInfo $mode.ToUpper() -Indent 1

        Write-LogInfo "Backup type:"
        if ($Script:Type) {
            Write-LogInfo $Script:Type.ToUpper() -Indent 1
        } else {
            Write-LogInfo "DEFAULT" -Indent 1
        }

        if ($Script:PlexVersion) {
            Write-LogInfo "Plex version:"
            Write-LogInfo $Script:PlexVersion -Indent 1
        }

        if ($Script:BackupVersion) {
            Write-LogInfo "Backup version:"
            Write-LogInfo $Script:BackupVersion -Indent 1
        }

        if ($Script:LogFile) {
            Write-LogInfo "Log file:"
            Write-LogInfo $Script:LogFile -Indent 1
        }

        if ($Script:ErrorLogFile) {
            Write-LogInfo "Error log file:"
            Write-LogInfo $Script:ErrorLogFile -Indent 1
        }

        [object[]]$plexServices = $null

        $success = $false

        try {
            # Get list of all running Plex services (match by display name).
            try {
                $plexServices = GetPlexServices
            }
            catch {
                throw (New-Object System.Exception( `
                    "Error enumerating Plex Windows services.", $_.Exception))
            }

            # Stop all running Plex services and Plex process.
            $success, $plexServices = StopPlexServices $plexServices

            if (!$success) {
                throw "Error stopping Plex Windows services."
            }

            $success = $false

            StopPlexMediaServer

            if ($Script:Mode -eq $MODE_RESTORE) {
                Restore
            }
            else {
                Backup
            }

            $success = $true

            try {
                [string]$dir = $null

                if ($Script:Mode -eq $MODE_RESTORE) {
                    $dir = $Script:PlexAppDataDir
                }
                else {
                    $dir = $Script:BackupDir
                }

                $backupInfo = Get-ChildItem -Recurse -File $dir | Measure-Object -Property Length -Sum

                $Script:ObjectCount = "{0:N0}" -f $backupInfo.Count
                $Script:BackupSIze  = ([math]::round($backupInfo.Sum /1Gb, 1)).ToString()
            }
            catch {
                Write-LogError "Error calculating backup statistics."
                Write-LogException $_
                $Error.Clear()
            }

            try {
                # Log off all currently logged on users except the current user.
                if ($Script:Logoff) {

                    Write-LogInfo "Logging off all other users connected to this computer."

                    if (!$Script:Test) {
                        quser | Select-String "Disc" | ForEach-Object {logoff ($_.ToString() -split ' +')[2]}
                    }
                }
            }
            catch {
                Write-Error "Attempt to log off other users connected to this computer failed."
                WriteLogException $_

                $Error.Clear()
            }

            # Wake up a NAS share if needed.
            try {
                if ($Script:WakeUpDir) {
                    Write-LogInfo "Waking up '$Script:WakeUpDir'."
                    WakeUpDir $Script:WakeUpDir
                }
            }
            catch {
                Write-Error "Attempt to wake up '$Script:WakeUpDir' failed."
                WriteLogException $_

                $Error.Clear()
            }

            if ($Script:Mode -eq $MODE_RESTORE) {
                Write-LogInfo "Restore operation completed."
            }
            else {
                Write-LogInfo "Backup operation completed."
            }

            $success = $true
        }
        catch {
            WriteLogException $_

            $Script:ErrorResult = FormatError $_

            $Error.Clear()
        }
        finally {
            $Script:EndTime = Get-Date
            $Script:Duration = (New-TimeSpan -Start $Script:StartTime `
                -End $Script:EndTime).ToString("hh\:mm\:ss\.fff")

            # Resturn Plex unless instructed to do otherwise
            # (do not restart after failed restore).
            if ((!$Script:NoRestart) -and
                ($success -or $Script:Mode -ne $MODE_RESTORE)) {
                StartPlexServices $plexServices
                StartPlexMediaServer
            }
        }
    }
    catch {
        throw
    }
    finally {
        WriteDebug "Exiting ProcessBackup."
    }
}

#-------------------------------[ PROGRAM ]--------------------------------

# We will trap errors in the try-catch blocks.
$ErrorActionPreference = 'Stop'

# Make sure we have no pending errors.
$Error.Clear()
$LASTEXITCODE = 0

# Assume that SMTP server does not require authentication for now.
[System.Management.Automation.PSCredential]$credential = $null

WriteDebug "Entered Main."

try {
    try {
        $psVersion = GetPowerShellversion
        Write-Verbose "Microsoft PowerShell v$psVersion"

        # Add custom folder(s) to the module path.
        SetModulePath

        # Load module dependencies.
        LoadModules $MODULES
    }
    catch {
        throw (New-Object System.Exception( `
            "Error processing dependencies.", $_.Exception))
    }

    # Load settings from a config file (if any).
    $configFileName = $null

    try {
        if ($configFile) {
            $configFileName = "configuration file '$configFile'"
        }
        else {
            $configFileName = "default configuration file (if any)"
        }

        Write-Verbose "Importing settings from $configFileName."
        Import-ConfigFile -ConfigFilePath $configFile `
            -DefaultParameters $PSBoundParameters
    }
    catch {
        throw (New-Object System.Exception( `
            "Cannot import run-time settings from $configFileName.", `
                $_.Exception))
    }

    # Initialize globals.
    try {
        # Set up global variables.
        InitGlobals

        # Set up mail configuration.
        InitMail
    }
    catch {
        throw (New-Object System.Exception( `
            "Initialization error.", $_.Exception))
    }

    # Validate things that need to be validated.
    try {
        # Make sure we have all required inputs.
        ValidateData

        # For 7-zip backup type, make sure the 7-zip command-line tool is valid.
        Validate7Zip

        # Make sure the version is okay (for restore operation).
        ValidateVersion

        # Make sure script is not already running (unless we ignore single instance check).
        ValidateSingleInstance
    }
    catch {
        throw (New-Object System.Exception("Validation error.", $_.Exception))
    }

    # Initialize logging.
    try {
        StartLogging
    }
    catch {
        throw (New-Object System.Exception( `
            "Logging error.", $_.Exception))
    }

    # PRE-MAIN LOGIC.
    Prologue

    # Perform backup.
    ProcessBackup

    # POST-MAIN LOGIC.
    Epilogue

    if (!$Script:ErrorResult) {
        $Script:ExitCode = $EXITCODE_SUCCESS
    }
}
# Unhandled exception handler.
catch {
    # Set end time if needed.
    if ($Script:EndTime -eq $Script:StartTime) {
        $Script:EndTime = Get-Date
    }

    # Depending on whether logs were initialized, print error.
    if (Test-LoggingStarted) {
        # Print error to logs.
        Write-LogError $_
    }
    else {
        # Print error to screen.
        WriteException $_
    }
}
finally {
    # Close mutex enforcing single-instance operation.
    if (Get-Module -Name $MODULE_SingleInstance) {
        Exit-SingleInstance
    }
    else {
        Write-Verbose "$MODULE_SingleInstance module is not loaded."
    }

    # We may need to dispose logging resources (i.e. stream writers).
    StopLogging

    try {
        # Send email notification if needed.
        if (MustSendMail ($Script:ExitCode -eq $EXITCODE_SUCCESS)) {
            try {
                SendMail
            }
            catch {
                WriteError "Failed to send email notification."
                WriteException $_
                $Error.Clear()
            }
        }

        # Reboot only on success and not in restore mode.
        if (($Script:Reboot -or $Script:ForceReboot) -and
             $Script:ExitCode -eq $EXITCODE_SUCCESS -and
             $Script:Mode -ne $MODE_RESTORE) {

            Write-Verbose "Rebooting computer."

            if ($Script:ForceReboot) {
                # If we are still here, reboot computer immediately.
                if (!$Script:Test) {
                    Restart-Computer -Force
                }
            }
            else {
                if (!$Script:Test) {
                    Restart-Computer
                }
            }
        }
    }
    catch {
        WriteException $_
        $Error.Clear()
    }
    finally {
        WriteDebug "Exiting Main."
    }

    exit $Script:ExitCode
}

# THE END
#--------------------------------------------------------------------------
