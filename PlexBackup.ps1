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

The script can send an email notification on the operation completion.

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

On success, the script will set the value of the $LASTEXITCODE variable to 0;
on error, it will be greater than zero.

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

.PARAMETER Backup
Shortcut for '-Mode Backup'.

.PARAMETER Continue
Shortcut for '-Mode Continue'.

.PARAMETER Restore
Shortcut for '-Mode Restore'.

.PARAMETER ConfigFile
Path to the optional custom config file. The default config file is named after
the script with the '.json' extension, such as 'PlexBackup.ps1.json'.

.PARAMETER PlexAppDataDir
Location of the Plex Media Server application data folder.

.PARAMETER BackupRootDir
Path to the root backup folder holding timestamped backup subfolders. If not
specified, the script folder will be used.

.PARAMETER BackupDirPath
When running the script in the Restore mode, holds path to the backup folder
(by default, the subfolder with the most recent timestamp in the name located
in the backup root folder will be used).

.PARAMETER TempZipFileDir
Temp folder used to stage the archiving job (use local drive for efficiency).
To bypass the staging step, set this parameter to null or empty string.

.PARAMETER Keep
Number of old backups to keep:
  0 - retain all previously created backups,
  1 - latest backup only,
  2 - latest and one before it,
  3 - latest and two before it,
and so on.

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

.PARAMETER ErrorLog
When set to true, error messages will be written to an error log file.
The default error log file will be created in the backup folder and will be named
after this script with the '.err.log' extension, such as 'PlexBackup.ps1.err.log'.

.PARAMETER ErrorLogFile
Use this switch to specify a custom error log file location. When this parameter
is set to a non-null and non-empty value, the '-ErrorLog' switch can be omitted.

.PARAMETER ErrorLogAppend
Set this switch to appended error log entries to the existing error log file,
if it exists (by default, the old error log file will be overwritten).

.PARAMETER Quiet
Set this switch to supress all log entries sent to a console.

.PARAMETER Shutdown
Set this switch to not start the Plex Media Server process at the end of the
operation (could be handy for restores, so you can double check that all is
good befaure launching Plex media Server).

.PARAMETER SendMail
Indicates in which case the script must send an email notification about
the result of the operation. Values (with explanations): Never (default),
Always, OnError (for any operation), OnSuccess (for any operation), OnBackup
(for both the Backup and Continue modes on either error or success),
OnBackupError, OnBackupSuccess, OnRestore (on either error or success),
OnRestoreError, and OnRestoreSuccess.

.PARAMETER From
Specifies the email address when email notification sender. If this value
is not provided, the username from the credentails saved in the credentials
file or enetered at the credentials prompt will be used. If the From address
cannot be determined, the notification will not be sent.

.PARAMETER To
Specifies the email address of the email recepient. If this value is not
provided, the addressed defined in the To parameter will be used.

.PARAMETER SmtpServer
Defines the SMTP server host. If not specified, the notification will not
be sent.

.PARAMETER Port
Specifies an alternative port on the SMTP server. Default: 0 (zero, i.e.
default port 25 will be used).

.PARAMETER UseSsl
Tells the script to use the Secure Sockets Layer (SSL) protocol when
connecting to the SMTP server. By default, SSL is not used.

.PARAMETER CredentialFile
Path to the file holding username and encrypted password of the account that
has permission to send mail via the SMTP server. You can generate the file
via the following PowerShell command:

  Get-Credential | Export-CliXml -Path "PathToFile.xml"

The default log file will be created in the backup folder and will be named
after this script with the '.xml' extension, such as 'PlexBackup.ps1.xml'.
You can also save the credentials in the file by running the script with the
PromptForCredential and SaveCredential switches turned on. If the credentials
are not specified, the send mail operation will be invoked on behalf of the
current (or anonymous) user. Please be aware that you may some public SMTP
servers, such as Gmail or Yahoo, have special requirements, i.e. you may need
to set up an application password (when using two-factor authentication -- 2FA
-- with Gmail) or modify your account settings to allow less secure applications
to connect to the SMTP server (when not using 2FA). Please check the
requirements with your SMTP provider.

.PARAMETER PromptForCredential
Tells the script to prompt user for SMTP server credentials, if they are
not specified in the credential file.

.PARAMETER SaveCredential
Tells the script to save the SMTP server credentials in the credential file.

.PARAMETER Anonymous
Tells the script to not use credentials when sending email notifications.

.PARAMETER SendLogFile
Indicates in which case the script must send an attachment along with th email
notification. Values: Never (default), OnError, OnSuccess, Always.

.PARAMETER NoLogo
Specify this command-line switch to not print version and copyright info.

.PARAMETER ClearScreen
Specify this command-line switch to clear console before starting script execution.

.NOTES
Version    : 1.3.7
Author     : Alek Davis
Created on : 2019-02-21
License    : MIT License
LicenseLink: https://github.com/alekdavis/PlexBackup/blob/master/LICENSE
Copyright  : (c) 2019 Alek Davis

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
PlexBackup.ps1 -SendMail Always -UseSsl -Prompt -Save -SendLogFile OnError -SmtpServer smtp.gmail.com -Port 587
Runs a backup job and sends an email notification over an SSL channel.
If the backup operation fails, the log file will be attached to the email
message. The sender's and the recipient's email addresses will determined
from the username of the credential object. The credential object will be
set either from the credential file or, if the file does not exist, via
a user prompt (in the latter case, the credential object will be saved in
the credential file with password encrypted using a user- and computer-
specific key).

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
# above).
[CmdletBinding(DefaultParameterSetName="ModeSet")]
param
(
    [Parameter(ParameterSetName="ModeSet")]
    [ValidateSet("", "Backup", "Continue", "Restore")]
    [string]
    $Mode = "",
    [Parameter(ParameterSetName="BackupSet")]
    [switch]
    $Backup,
    [Parameter(ParameterSetName="ContinueSet")]
    [switch]
    $Continue,
    [Parameter(ParameterSetName="RestoreSet")]
    [switch]
    $Restore,
    [string]
    $ConfigFile = $null,
    [string]
    $PlexAppDataDir = "$env:LOCALAPPDATA\Plex Media Server",
    [string]
    $BackupRootDir = $null,
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
    [Alias("L")]
    [switch]
    $Log = $false,
    [switch]
    $LogAppend = $false,
    [string]
    $LogFile,
    [switch]
    $ErrorLog = $false,
    [switch]
    $ErrorLogAppend = $false,
    [string]
    $ErrorLogFile,
    [Alias("Q")]
    [switch]
    $Quiet = $false,
    [switch]
    $Shutdown = $false,
    [ValidateSet(
        "Never", "Always", "OnError", "OnSuccess",
        "OnBackup", "OnBackupError", "OnBackupSuccess",
        "OnRestore", "OnRestoreError", "OnRestoreSuccess")]
    [string]
    $SendMail = "Never",
    [string]
    $From = $null,
    [string]
    $To,
    [string]
    $SmtpServer,
    [int]
    $Port = 0,
    [switch]
    $UseSsl = $false,
    [string]
    $CredentialFile = "",
    [Alias("Prompt")]
    [switch]
    $PromptForCredential = $false,
    [switch]
    [Alias("Save")]
    $SaveCredential = $false,
    [switch]
    $Anonymous = $false,
    [ValidateSet("Never", "OnError", "OnSuccess", "Always")]
    [string]
    $SendLogFile = "Never",
    [switch]
    $NoLogo = $false,
    [Alias("Cls")]
    [switch]
    $ClearScreen = $false
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

#------------------------------[ EXIT CODES]-------------------------------

$EXITCODE_SUCCESS            = 0 # success
$EXITCODE_ERROR              = 1 # error during backup or restore operation
$EXITCODE_ERROR_CONFIG       = 2 # error processing config file
$EXITCODE_ERROR_BACKUPDIR    = 3 # problem determining or setting backup folder
$EXITCODE_ERROR_LOG          = 4 # problem with log file(s)
$EXITCODE_ERROR_GETPMSEXE    = 5 # cannot determine path to PMS executable
$EXITCODE_ERROR_GETSERVICES  = 6 # cannot read Plex Windows services
$EXITCODE_ERROR_STOPSERVICES = 7 # cannot stop Plex Windows services
$EXITCODE_ERROR_STOPPMSEXE   = 8 # cannot stop PMS executable file

#------------------------------[ FUNCTIONS ]-------------------------------

function GetVersionInfo {
    $notes = $null
    $notes = @{}

    # Get the .NOTES section of the script header comment.
    $notesText = (Get-Help -Full $PSCommandPath).alertSet.alert.Text

    # Split the .NOTES section by lines.
    $lines = ($notesText -split '\r?\n').Trim()

    # Iterate through every line.
    foreach ($line in $lines) {
        if (!$line) {
            continue
        }

        $name  = $null
        $value = $null

        # Split line by the first colon (:) character.
        if ($line.Contains(':')) {
            $nameValue = $null
            $nameValue = @()

            $nameValue = ($line -split ':',2).Trim()

            $name = $nameValue[0]

            if ($name) {
                $value = $nameValue[1]

                if ($value) {
                    $value = $value.Trim()
                }

                if (!($notes.ContainsKey($name))) {
                    $notes.Add($name, $value)
                }
            }
        }
    }

    return $notes
}

function InitConfig {

    # If config file is specified, check if it exists.
    if ($script:ConfigFile) {

        if (!(Test-Path -Path $script:ConfigFile -PathType Leaf)) {
            LogError "Cannot find config file:" $false
            LogError (Indent $script:ConfigFile) $false

            return $false
        }
    }
    # If config file is not specified, check if the default config file exists.
    else {
        # Default config file is named after running script with .json extension.
        $script:ConfigFile = $PSCommandPath + $script:ConfigFileExt

        # Default config file is optional.
        if (!(Test-Path -Path $script:ConfigFile -PathType Leaf)) {
            return $true
        }
    }

    LogMessage "Loading runtime settings from config file:" $false
    LogMessage (Indent $script:ConfigFile) $false

    $config = @{}

    try {
        $json = Get-Content $script:ConfigFile -Raw `
            -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue

        if ($json) {
            $config = ConvertJsonStringToObject $json
        }
        else {
            LogWarning "Config file is empty."
        }
    }
    catch {
        LogException $_

        return $false
    }

    # Make sure we got at least one config value.
    if ((!$config) -or ($config.PSBase.Count -eq 0)) {
        return $true
    }

    # Assign config values to the script variables with the same names.
    foreach ($key in $config.Keys) {
        Set-Variable -Scope Script -Name $key -Value $config[$key] -Force -Visibility Private
    }

    return $true
}

function ConvertJsonStringToObject {
    param
    (
        [string]
        $json
    )

    $hash = @{}

    $jsonObject = $json | ConvertFrom-Json `
        -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue

    $version    = $jsonObject._meta.version
    $strictMode = $jsonObject._meta.strictMode

    $jsonObject.PSObject.Properties | ForEach-Object {

        # 'return' here acts as 'continue' in loops.
        if ($_.Name.StartsWith("_")) {
            return
        }

        # For version 1.0 of config file...
        if ($version -eq '1.0') {
            # ...first check if 'hasValue' property is set for the element.
            if ($_.Value.hasValue) {
                $hash.Add(($_.Name), $_.Value.value)
            }
            # If 'hasValue' is not set or is missing...
            else {
                # ...if config file is in strict mode, ignore the element;
                if ($strictMode) {
                    return
                }
                # otherwise, check if there is a non-null/non-empty/true value.
                else {
                    # Only include values that ar resolved as true.
                    if ($_.Value.value) {
                        $hash.Add(($_.Name), $_.Value.value)
                    }
                }
            }
        }
        # For version, prior to 1.0...
        else {
            # Only include values that ar resolved as true.
            if ($_.Value) {
                $hash.Add(($_.Name), $_.Value)
            }
        }
    }

    return $hash
}

function Indent {
    param
    (
        [string]
        $message,
        [int]
        $indentLevel = 1
    )

    $indents = ""

    if ($message) {
        for ($i=0; $i -lt $indentLevel; $i++) {
            $indents = $indents + "  "
        }
    }
    else {
        $message = ""
    }

    $message = $indents + $message

    return $message
}

function Log {
    param
    (
        [string]
        $message = "",
        [string]
        $path = $null,
        [System.ConsoleColor]
        $textColor = $Host.ui.RawUI.ForegroundColor
    )

    #if ($script:Log -and $script:LogFile -and $writeToFile) {
    if ($path) {
        $Error.Clear()

        try {
            $message | Out-File $path -Append -Encoding utf8
        }
        catch {
            # There was a problem writing to the file.
            LogException $_

            $Error.Clear()
            return $false
        }
    }
    else {
        if ($textColor -eq -1) {
            [System.ConsoleColor]$foregroundColor = [System.ConsoleColor]::White
        }
        else {
            [System.ConsoleColor]$foregroundColor = $textColor
        }

        if (!$script:Quiet) {
            Write-Host $message -ForegroundColor $foregroundColor
        }
    }

    return $true
}

function LogException {
    param
    (
        [object]
        $ex,
        [bool]
        $writeToLog = $true,
        [bool]
        $writeToErrorLog = $true
    )

    if (!$script:Quiet) {
         Write-Error $ex -ErrorAction Continue
    }

    if ($writeToLog -and $script:Log -and $script:LogFile) {
        try {
            Out-File -FilePath $script:LogFile -Append -Encoding utf8 -InputObject $ex
        }
        catch {
            # There was a problem writing to a file, so don't use log file.
            $script:Log     = $false
            $script:LogFile = $null

            try {
                LogException $_ $false $writeToErrorLog
            }
            catch {
            }

            $Error.Clear()
        }
    }

    if ($writeToErrorLog -and $script:ErrorLog -and $script:ErrorLogFile) {
        try {
            Out-File -FilePath $script:ErrorLogFile -Append -Encoding utf8 -InputObject $ex
        }
        catch {
            # There was a problem writing to a file, so don't use log file.
            $script:ErrorLog     = $false
            $script:ErrorLogFile = $null

            try {
                LogException $_ $writeToLog $false
            }
            catch {
            }

            $Error.Clear()
        }
    }
}

function LogError {
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToLog = $true,
        [bool]
        $writeToErrorLog = $true
    )

    # Send message to console.
    if (!$script:Quiet) {
        (Log $message $null Red) | Out-Null
    }

    # If we failed to write to the log file, don't try again.
    if ($writeToLog -and $script:Log -and $script:LogFile) {
        if (!(Log $message $script:LogFile)) {
            $script:Log     = $false
            $script:LogFile = $null
        }
    }

    # If we failed to write to the error log file, don't try again.
    if ($writeToErrorLog -and $script:ErrorLog -and $script:ErrorLogFile) {
        if (!(Log $message $script:ErrorLogFile)) {
            $script:ErrorLog     = $false
            $script:ErrorLogFile = $null
        }
    }
}

function LogWarning {
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    # Send message to console.
    if ($writeToConsole) {
        (Log $message $null Yellow) | Out-Null
    }

    if (!$writeToFile) {
        return
    }

    # If we failed to write to the log file, don't try again.
    if (!(Log $message $script:LogFile))
    {
        $script:Log     = $false
        $script:LogFile = $null
    }
}

function LogMessage {
    param
    (
        [string]
        $message = "",
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    # Send message to console.
    if ($writeToConsole) {
        (Log $message $null) | Out-Null
    }

    if (!$writeToFile) {
        return
    }

    # If we failed to write to the log file, don't try again.
    if (!(Log $message $script:LogFile)) {
        $script:Log     = $false
        $script:LogFile = $null
    }
}

function InitMode {
    if (!$script:Mode) {
        if ($script:Backup) {
            $script:Mode = "Backup"
        }
        elseif ($script:Continue) {
            $script:Mode = "Continue"
        }
        elseif ($script:Restore) {
            $script:Mode = "Restore"
        }
        else {
            $script:Mode = "Backup"
        }
    }
}

function InitBackupRootDir {
    if ($script:BackupRootDir) {
        return
    }

    if ($script:BackupDirPath) {
        $script:BackupRootDir = Split-Path -Path $script:BackupDirPath -Parent
    }
    else {
        $script:BackupRootDir = Split-Path -Path $PSCommandPath -Parent
    }
}

function InitLog {
    if ($script:LogFile) {
        $script:Log = $true
    }
    if ($script:ErrorLogFile) {
        $script:ErrorLog = $true
    }

    if ((!$script:Log) -and (!$script:ErrorLog)) {
        return $true
    }

    if (!$script:LogFile) {
        $logFileName = (Split-Path -Path $PSCommandPath -Leaf) + ".log"

        $script:LogFile = Join-Path $script:BackupDirPath $logFileName
    }

    if (!$script:ErrorLogFile) {
        $errorLogFileName = (Split-Path -Path $PSCommandpath -Leaf) + ".err.log"

        $script:ErrorLogFile = Join-Path $script:BackupDirPath $errorLogFileName
    }

    # Process both log and error log files in a similar manner.
    $logSettings = @(
        @($script:LogFile, $script:LogAppend, "log file", $false, $false),
        @($script:ErrorLogFile, $script:ErrorLogAppend, "error log file", $true, $false))

    $validatedFolders = @{}

    foreach ($logSetting in $logSettings) {

        # If there is no log file path, skip to next.
        if (!$logSetting[0]) {
            continue
        }

        $filePath       = $logSetting[0]
        $fileDir        = Split-Path -Path $filePath -Parent
        $fileAppend     = $logSetting[1]
        $fileType       = $logSetting[2]
        $writeToLog     = $logSetting[3]
        $writeToErrorLog= $logSetting[4]

        if (!$fileAppend) {
            if (Test-Path -Path $filePath -PathType Leaf) {
                try {
                    Remove-Item -Path $filePath -Force
                }
                catch {
                    LogError ("Cannot delete old " + $fileType + ":") $writeToLog $writeToErrorLog
                    LogError (Indent $filePath) $writeToLog $writeToErrorLog

                    LogException $_ $writeToLog $writeToErrorLog

                    return $false
                }
            }
        }

        # Make sure log folder exists.
        if (!($validatedFolders.ContainsKey($fileDir))) {
            LogMessage ("Validating " + $fileType + " folder:") $writeToLog
            LogMessage (Indent $fileDir) $writeToLog

            try {
                if (!(Test-Path -Path $fileDir -PathType Container)) {
                    New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
                }

                $validatedFolders[$fileDir] = $true
            }
            catch {
                LogException $_ $writeToLog $writeToErrorLog

                $Error.Clear()

                return $false;
            }
        }
    }

    return $true
}

function PrintVersion {
    param (
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    $versionInfo = GetVersionInfo
    $scriptName  = (Get-Item $PSCommandPath).Basename

    LogMessage ($scriptName +
        " v" + $versionInfo["Version"] +
        " " + $versionInfo["Copyright"]) $writeToFile $writeToConsole
}

function InitMailSetting {
    if (!$script:smtpServer) {
        $script:SendMail = $false
    }
}

function InitCredentialFileName {
    if (!$script:SendMail) {
        return
    }

    if ($script:Anonymous) {
        return
    }

    if (!$script:CredentialFile) {
        $script:CredentialFile = $PSCommandPath + ".xml"
    }
}

function GetCredential {
    param (
        [string]
        $file,
        [bool]
        $prompt,
        [bool]
        $save,
        [string]
        $smtpServer
    )

    $credential =  $null

    # If we have the credential file path (which we should in any case)...
    if ($file) {

        # ...and file exists, get credentials from the file.
        if (Test-Path -Path $file) {
            try {
                $credential = Import-CliXml -Path  $file
            }
            catch {
                LogError "Cannot import SMTP credentials from:"
                LogError (Indent $file)

                LogException $_

                $Error.Clear()
            }
        }

        if ($credential) {
            return $credential
        }

        if ((!$credential) -and (!$prompt)) {
            LogError "Cannot import SMTP credentials from:"
            LogError (Indent $file)
            LogError "The file does not seem to exist."

            return $null
        }
    }

    # Show prompt to enter credentials.
    if ($prompt) {
        try {
            $caption = "SMTP Server Authentication"
            $message = "Please enter your credentials for " + $smtpServer

            $credentialType = [System.Management.Automation.PSCredentialTypes]::Generic
            $validateOption = [System.Management.Automation.PSCredentialUIOptions]::None

            $credential = $Host.UI.PromptForCredential(
                $caption,
                $message,
                "",
                "",
                $credentialType,
                $validateOption)
        }
        catch {
            LogError "Cannot get SMTP credentials."

            LogException $_

            $Error.Clear()
        }
    }

    # Save entered credentials if needed.
    if ($credential -and $save) {
        try {
            LogMessage "Saving SMTP credentials to:"
            LogMessage (Indent $file )

            Export-CliXml -Path $file -InputObject $credential
        }
        catch {
            LogException $_

            $Error.Clear()
        }
    }

    return $credential
}

function MustSendAttachment {
    param (
        [string]
        $when,
        [bool]
        $success
    )

    if ($when -eq "Always") {
        return $true
    }

    if ($when -eq "Never") {
        return $false
    }

    if ($when -eq "OnSuccess") {
        if ($success -ne $true) {
            return $false
        }
        else {
            return $true
        }
    }

    if ($when -eq "OnError") {
        if ($success -ne $false) {
            return $false
        }
        else {
            return $true
        }
    }

    return $true
}

function MustSendMail {
    param (
        [string]
        $when,
        [string]
        $mode,
        [ValidateSet($null, $true, $false)]
        [object]
        $success = $null
    )

    if ($when -eq "Never") {
        return $false
    }

    if ($when -eq "Always") {
        return $true
    }

    if ($when -eq "OnSuccess") {
        if ($success -ne $false) {
            return $true
        }
        else {
            return $false
        }
    }

    if ($when -eq "OnError") {
        if ($success -ne $true) {
            return $true
        }
        else {
            return $false
        }
    }

    if ($when.StartsWith("OnBackup")) {
        if ($mode -eq "Restore") {
            return $false
        }
        if (($when.EndsWith("Error")) -and ($success-eq $true)) {
            return $false
        }
        if (($when.EndsWith("Success")) -and ($success-eq $false)) {
            return $false
        }

        return $true
    }

    if ($when.StartsWith("OnRestore")) {
        if ($mode -ne "Restore") {
            return $false
        }
        if (($when.EndsWith("Error")) -and ($success-eq $true)) {
            return $false
        }
        if (($when.EndsWith("Success")) -and ($success-eq $false)) {
            return $false
        }

        return $true
    }

    return $true
}

function SendMail {
    param (
        [string]
        $from,
        [string]
        $to,
        [string]
        $subject,
        [string]
        $body,
        [string[]]
        $attachment,
        [string]
        $smtpServer,
        [int]
        $port,
        [PSCredential]
        $credential,
        [bool]
        $useSsl = $true,
        [bool]
        $bodyAsHtml = $true
    )

    $params = @{}

    if (($port) -and ($port -gt 0)) {
        $params.Add("Port", $port)
    }

    if ($credential) {
        $params.Add("Credential", $credential)
    }

    if ($useSsl) {
        $params.Add("UseSsl", $true)
    }

    if ($bodyAsHtml){
        $params.Add("BodyAsHtml", $true)
    }

    if ($Attachment -and ($Attachment.Count -gt 0)) {
        $params.Add("Attachment", $attachment)
    }

    try {
        LogMessage "Sending email notification to:"
        LogMessage (Indent $to)

        Send-MailMessage `
            @params `
            -From $from `
            -To $to `
            -Subject $subject `
            -Body $body `
            -SmtpServer $smtpServer
    }
    catch {
        LogException $_
    }
}

function FormatEmail {
    param (
        [string]
        $computerName,
        [string]
        $scriptPath,
        [string]
        $backupMode,
        [string]
        $backupDir,
        [DateTime]
        $scriptStartTime,
        [DateTime]
        $scriptEndTime,
        [bool]
        $success = $true
    )

    $scriptDuration = (New-TimeSpan -Start $scriptStartTime -End $scriptEndTime).ToString("hh\:mm\:ss\.fff")

    $body = "
<!DOCTYPE html>
<head>
<title>Plex Backup Report</title>
</head>
<body>
<table style='#STYLE_PAGE#'>
<tr>
<td>
<tr><td style='#STYLE_TEXT#'>Plex backup script</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_PATH#</td></tr>
<tr><td style='#STYLE_TEXT#'>completed the</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_MODE#</td></tr>
<tr><td style='#STYLE_TEXT#'>operation on</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_COMPUTER_NAME#</td></tr>
<tr><td style='#STYLE_TEXT#'>with</td></tr>
<tr><td style='#STYLE_RESULT#'>#VALUE_RESULT#</td></tr>
<tr><td style='#STYLE_TEXT#'>The script started at</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_START_TIME#</td></tr>
<tr><td style='#STYLE_TEXT#'>and ended at</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_END_TIME#</td></tr>
<tr><td style='#STYLE_TEXT#'>running for (hr:min:sec.msec)</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_SCRIPT_DURATION#</td></tr>
<tr><td style='#STYLE_TEXT#'>The backup folder</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_DIR#</td></tr>
</td>
</tr>
</table>
</body>
</html>
"
    $styleTextColor     = 'color: #363636;'
    $styleSuccessColor  = 'color: #008800;'
    $styleErrorColor    = 'color: #cc0000;'

    $styleResultColor   = ''
    $resultText         = ''

    if ($success) {
        $styleResultColor = $styleSuccessColor
        $resultText  = 'SUCCESS'
    }
    else {
        $styleResultColor  = $styleErrorColor
        $resultText = 'ERROR'
    }

    $stylePage               = 'max-width: 800px;border: 0;'
    $styleFontFamily         = 'font-family: Verdana, Trebuchet MS, Arial;'
    $styleIndent             = 'padding-left: 24px;'
    $styleParagraph          = ''
    $styleVarParagraph       = $styleParagraph + $styleIndent
    $styleResultParagraph    = $styleVarParagraph
    $styleTextFontSize       = 'font-size: 14px;'
    $styleResultTextFontSize = 'font-size: 18px;'
    $styleTextFont           = $styleFontFamily + $styleTextFontSize + $styleTextColor
    $styleVarTextFont        = $styleTextFont + 'font-weight: bold;'
    $styleResultTextFont     = $styleFontFamily + $styleResultTextFontSize + $styleResultColor + 'font-weight: bold;'

    $emailTokens = @{
        STYLE_PAGE              = $stylePage
        STYLE_TEXT              = $styleParagraph + $styleTextFont
        STYLE_VAR_TEXT          = $styleVarParagraph +  $styleVarTextFont
        STYLE_RESULT            = $styleResultParagraph + $styleResultTextFont
        VALUE_COMPUTER_NAME     = $computerName
        VALUE_SCRIPT_PATH       = $scriptPath
        VALUE_BACKUP_MODE       = $backupMode
        VALUE_BACKUP_DIR        = $backupDir
        VALUE_SCRIPT_START_TIME = $scriptStartTime
        VALUE_SCRIPT_END_TIME   = $scriptEndTime
        VALUE_SCRIPT_DURATION   = $scriptDuration
        VALUE_RESULT            = $resultText
    }

    # $htmlEmail = Get-Content -Path TemplateLetter.txt -RAW
    foreach ($token in $emailTokens.GetEnumerator())
    {
        $pattern = '#{0}#' -f $token.key
        $body = $body -replace $pattern, $token.Value
    }

    return $body
}

function GetTimestamp {
    return $(Get-Date).ToString("yyyy/MM/dd HH:mm:ss.fff")
}

function WakeUpDir {
    param(
        [string]
        $path
    )

    if (!$path) {
        return
    }

    # Just in case path points to a remote share on a sleeping device,
    # try waking it up (a directory listing should do it).
    for ($i = 0; $i -lt 2; $i++) {
        try {
            Get-ChildItem -Path $path | Out-Null
            break
        }
        catch {
            $Error.Clear()
            Start-Sleep -Seconds 10
        }
    }
}

function GetLastBackupDirPath {
    param (
        [string]
        $backupRootDir,
        [string]
        $regexBackupDirNameFormat
    )

    $logToFile = $false

    if ($Script:LogFile) {
        $logToFile = $true
    }

    WakeUpDir $backupRootDir

    if (!(Test-Path -Path $backupRootDir -PathType Container)) {
        LogWarning "Cannot find backup root folder:" $logToFile
        LogWarning (Indent $backupRootDir) $logToFile

        return $null
    }

    # Get all folders with names from newest to oldest.
    $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory |
        Where-Object { $_.Name -match $regexBackupDirNameFormat } |
            Sort-Object -Descending

    if ($oldBackupDirs.Count -lt 1) {
        LogWarning "No folder matching the timestamp regex format:" $logToFile
        LogWarning (Indent $regexBackupDirNameFormat) $logToFile
        LogWarning "found in:" $logToFile
        LogWarning (Indent $backupRootDir) $logToFile

        return $null
    }

    return $oldBackupDirs[0].FullName
}

function GetNewBackupDirName {
    param
    (
        [string]
        $backupDirNameFormat,
        [DateTime]
        $date = (Get-Date)
    )

    if (!$date) {
        $date = Get-Date
    }

    return ($date).ToString($backupDirNameFormat)
}

function GetBackupDirNameAndPath {
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

    if ($backupDirPath) {
        WakeUpDir $backupDirPath

        return (Split-Path -Path $backupDirPath -Leaf), $backupDirPath
    }

    WakeUpDir $backupRootDir
    if ($mode -ne "Backup") {
        $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat
    }

    if ($backupDirPath) {
        return (Split-Path -Path $backupDirPath -Leaf), $backupDirPath
    }

    # If we didn't get the backup folder path in the Restore mode, we're in trouble.
    if ($mode -eq "Restore") {
        # Looks like we could not find a backup folder.
        return $null, $null
    }

    # For the Backup mode, generate a new timestamp-based folder name.
    $backupDirName = GetNewBackupDirName $backupDirNameFormat $date

    return $backupDirName, (Join-Path $backupRootDir $backupDirName)
}

function GetPlexMediaServerExePath {
    param
    (
        [string]
        $path,
        [string]
        $name
    )

    # Get path of the Plex Media Server executable.
    if (!$path) {
        $path = Get-Process |
            Where-Object {$_.Path -match $name + "$" } |
                Select-Object -ExpandProperty Path
    }

    # Make sure we got the Plex Media Server executable file path.
    if (!$path) {
        LogError "Cannot determine path of the the Plex Media Server executable file."
        LogError "Please make sure Plex Media Server is running."

        return $false, $null
    }

    # Verify that the Plex Media Server executable file exists.
    if (!(Test-Path -Path $path -PathType Leaf)) {
        LogError "Cannot find Plex Media Server executable file:"
        LogError (Indent $path)

        return $false, $null
    }

    return $true, $path
}

function GetRunningPlexServices {
    param
    (
        [string]
        $displayNameSearchString
    )

    return Get-Service |
        Where-Object {$_.DisplayName -match $displayNameSearchString} |
            Where-Object {$_.status -eq 'Running'}
}

function StopPlexServices {
    param
    (
        [object[]]
        $services
    )

    # We'll keep track of every Plex service we successfully stopped.
    $stoppedPlexServices = [System.Collections.ArrayList]@()

    if ($services.Count -gt 0) {
        LogMessage "Stopping Plex service(s):"

        foreach ($service in $services) {
            LogMessage (Indent $service.DisplayName)

            try {
                Stop-Service -Name $service.Name -Force
            }
            catch {
                LogException $_

                return $false, $stoppedPlexServices
            }


            ($stoppedPlexServices.Add($service)) | Out-Null
        }
    }

    return $true, $stoppedPlexServices
}

function StartPlexServices {
    param
    (
        [object[]]
        $services
    )

    if (!$services) {
        return
    }

    if ($services.Count -le 0) {
        return
    }

    LogMessage "Starting Plex service(s):"

    foreach ($service in $services) {
        LogMessage (Indent $service.DisplayName)

        try {
            Start-Service -Name $service.Name
        }
        catch {
            LogException $_

            # Non-critical error; can continue.
        }
    }
}

function StopPlexMediaServer {
    param
    (
        [string]
        $plexServerExeFileName,
        [string]
        $plexServerExePath
    )

    # If we have the path to Plex Media Server executable, see if it's running.
    $exeFileName = $plexServerExeFileName

    if ($plexServerExePath) {
        $exeFileName = Get-Process |
            Where-Object {$_.Path -eq $plexServerExePath } |
		        Select-Object -ExpandProperty Name
    }
    # If we do not have the path, use the file name to see if the process is running.
    else {
        $plexServerExePath = Get-Process |
            Where-Object {$_.Path -match $plexServerExeFileName + "$" } |
                Select-Object -ExpandProperty Path
    }

    # Stop Plex Media Server executable (if it is running).
    if ($exeFileName -and $plexServerExePath) {
        LogMessage "Stopping Plex Media Server process:"
        LogMessage (Indent $plexServerExeFileName)

        try {
            taskkill /f /im $plexServerExeFileName /t >$nul 2>&1
        }
        catch {
            LogException $_

            return $false
        }
    }

    return $true
}

function StartPlexMediaServer {
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
    if (!$plexServerExeFileName -and $plexServerExePath) {
        LogMessage "Starting Plex Media Server process:"
        LogMessage (Indent $plexServerExePath)

        try {
            Start-Process $plexServerExePath
        }
        catch {
            LogException $_
        }
    }
}

function CopyFolder {
    param
    (
        [string]
        $source,
        [string]
        $destination
    )

    if (!(Test-Path -Path $source -PathType Container)) {
        LogWarning "Source folder is not found:"
        LogWarning (Indent $source)
        LogWarning "Skipping."

        return $true
    }

    LogMessage "Copying folder:"
    LogMessage (Indent $source)
    LogMessage "to:"
    LogMessage (Indent $destination)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    try {
        robocopy $source $destination *.* /e /is /it *>&1 | Out-Null
    }
    catch {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7) {
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

function MoveFolder {
    param
    (
        [string]
        $source,
        [string]
        $destination
    )

    if (!(Test-Path -Path $source -PathType Container)) {
        LogWarning "Source folder is not found:"
        LogWarning (Indent $source)
        LogWarning "Skipping."

        return $true
    }

    LogMessage "Moving folder:"
    LogMessage (Indent $source)
    LogMessage "to:"
    LogMessage (Indent $destination)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    try {
        robocopy $source $destination *.* /e /is /it /move *>&1 | Out-Null
    }
    catch {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7) {
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

function BackupSpecialSubDirs {
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
         ($specialPlexAppDataSubDirs.Count -eq 0)) {
        retrun $true
    }

    LogMessage "Backing up special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs) {
        $source      = Join-Path $plexAppDataDir $specialPlexAppDataSubDir
        $destination = Join-Path $backupDirPath $specialPlexAppDataSubDir

        if (!(MoveFolder $source $destination)) {
            return $false
        }
    }

    return $true
}

function RestoreSpecialSubDirs {
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
         ($specialPlexAppDataSubDirs.Count -eq 0)) {
        retrun $true
    }

    LogMessage "Restoring special subfolders."

    foreach ($specialPlexAppDataSubDir in $specialPlexAppDataSubDirs) {
        $source      = Join-Path $backupDirPath $specialPlexAppDataSubDir
        $destination = Join-Path $plexAppDataDir $specialPlexAppDataSubDir

        if (!(CopyFolder $source $destination)) {
            return $false
        }
    }

    return $true
}

function DecompressPlexAppDataFolder {
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
    $backupZipFilePath = $backupZipFile.FullName

    $plexAppDataDirName = $backupZipFile.BaseName
    $plexAppDataDirPath = Join-Path $plexAppDataDir $plexAppDataDirName

    $Error.Clear()

    # If we have a temp folder, stage the extracting job.
    if ($tempZipFileDir) {
        $tempZipFileName= (New-Guid).Guid + $zipFileExt

        $tempZipFilePath= Join-Path $tempZipFileDir $tempZipFileName

        # Copy backup archive to a temp zip file.
        LogMessage "Copying backup archive file:"
        LogMessage (Indent $backupZipFilePath)
        LogMessage "to a temp zip file:"
        LogMessage (Indent $tempZipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Start-BitsTransfer -Source $backupZipFilePath -Destination $tempZipFilePath
        }
        catch {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))

        LogMessage "Restoring Plex app data from:"
        LogMessage (Indent $tempZipFilePath)
        LogMessage "to Plex app data folder:"
        LogMessage (Indent $plexAppDataDirPath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Expand-Archive -Path $tempZipFilePath -DestinationPath $plexAppDataDirPath -Force
        }
        catch {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))

        # Delete temp file.
        LogMessage "Deleting temp file:"
        LogMessage (Indent $tempZipFilePath)

        try {
            Remove-Item $tempZipFilePath -Force
        }
        catch {
            LogException $_

            # Non-critical error; can continue.
            $Error.Clear()
        }
    }
    # If we don't have a temp folder, restore archive in the Plex app data folder.
    else {
        LogMessage "Restoring Plex app data from:"
        LogMessage (Indent $backupZipFilePath)
        LogMessage "to Plex app data folder:"
        LogMessage (Indent $plexAppDataDirPath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Expand-Archive -Path $backupZipFilePath -DestinationPath $plexAppDataDirPath -Force
        }
        catch {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))
    }

    return $true
}

function DecompressPlexAppData {
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

    if (Test-Path -Path $zipFilePath -PathType Leaf) {
        LogMessage "Restoring Plex app data files from:"
        LogMessage (Indent $zipFilePath)
        LogMessage "to:"
        LogMessage (Indent $plexAppDataDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Expand-Archive -Path $zipFilePath -DestinationPath $plexAppDataDir -Force
        }
        catch {
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

    foreach ($backupZipFile in $backupZipFiles) {
        if (!(DecompressPlexAppDataFolder `
                $backupZipFile `
                (Join-Path $backupDirPath $subDirFolders) `
                $plexAppDataDir `
                $tempZipFileDir `
                $zipFileExt)) {
            return $false
        }
    }

    return $true
}

function CompressPlexAppDataFolder {
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

    if (Test-Path $backupZipFilePath -PathType Leaf) {
        LogWarning "Backup archive already exists in:"
        LogWarning (Indent $backupZipFilePath)
        LogWarning "Skipping."

        return $true
    }

    if ($tempZipFileDir) {
        $tempZipFileName= (New-Guid).Guid + $zipFileExt

        $tempZipFilePath= Join-Path $tempZipFileDir $tempZipFileName

        LogMessage "Archiving:"
        LogMessage (Indent $sourceDir.FullName)
        LogMessage "to temp file:"
        LogMessage (Indent $tempZipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $tempZipFilePath
        }
        catch {
            LogException $_

            return $false
        }

        LogMessage "Completed at:"
        LogMessage (Indent (GetTimestamp))

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $tempZipFilePath -PathType Leaf)) {
            LogWarning "Skipping empty subfolder."
        }
        else {
            # Copy temp ZIP file to the backup folder.
            LogMessage "Copying temp file:"
            LogMessage (Indent $tempZipFilePath)
            LogMessage "to:"
            LogMessage (Indent $backupZipFilePath)
            LogMessage "at:"
            LogMessage (Indent (GetTimestamp))

            try {
                Start-BitsTransfer -Source $tempZipFilePath -Destination $backupZipFilePath
            }
            catch {
                LogException $_

                return $false
            }

            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))

            # Delete temp file.
            LogMessage "Deleting temp file:"
            LogMessage (Indent $tempZipFilePath)

            try {
                Remove-Item $tempZipFilePath -Force
            }
            catch {
                LogException $_

                # Non-critical error; can continue.
            }
       }
    }
    # If we don't have a temp folder, create an archive in the destination folder.
    else {
        LogMessage "Archiving:"
        LogMessage (Indent $sourceDir.FullName)
        LogMessage "to:"
        LogMessage (Indent $backupZipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $backupZipFilePath

        if ($Error.Count -gt 0) {
            return $false
        }

        # If the folder was empty, the ZIP file will not be created.
        if (!(Test-Path $backupZipFilePath -PathType Leaf)) {
            LogWarning "Skipping empty subfolder."
        }
        else {
            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))
        }
    }

    return $true
}

function RobocopyPlexAppData {
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

    try {
        if (($excludeDirs) -and ($excludeDirs.Count -gt 0)) {
            $excludePaths = [System.Collections.ArrayList]@()

            foreach ($excludeDir in $excludeDirs) {
                ($excludePaths.Add((Join-Path $source $excludeDir))) | Out-Null
            }

            robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT /XD $excludePaths
        }
        else {
            robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT
        }
    }
    catch {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7) {
        LogError "Robocopy failed with error code:"
        LogError (Indent $LASTEXITCODE)
        LogError "To troubleshoot, execute the following command:"

        if (($excludePaths) -and ($excludePaths.Count -gt 0)) {
            LogError "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT /XD $excludePaths"
        }
        else {
            LogError "robocopy $source $destination /MIR /R:$retries /W:$retryWaitSec /MT"
        }

        return $false
    }

    LogMessage "Completed at:"
    LogMessage (Indent (GetTimestamp))

    return $true
}

function CompressPlexAppData {
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
    LogMessage (Indent $zipFilePath)
    LogMessage "at:"
    LogMessage (Indent (GetTimestamp))

    if (Test-Path $zipFilePath -PathType Leaf) {
        LogWarning "Backup file already exists in:"
        LogWarning (Indent $zipFilePath)
        LogWarning "Skipping."
    }
    else {
        try {
            Get-ChildItem -File "$plexAppDataDir" |
                Compress-Archive -DestinationPath $zipFilePath -Update
        }
        catch {
            LogException $_

            return $false
        }

        if (Test-Path $zipFilePath -PathType Leaf) {
            LogMessage "Completed at:"
            LogMessage (Indent (GetTimestamp))
        }
        else {
            LogWarning "Skipping empty directory."
        }
     }

    LogMessage "Backing up Plex app data folders from:"
    LogMessage (Indent $plexAppDataDir)
    LogMessage "to:"
    LogMessage (Indent (Join-Path $backupDirPath $subDirFolders))

    $plexAppDataSubDirs = Get-ChildItem $plexAppDataDir -Directory  |
        Where-Object { $_.Name -notin $excludePlexAppDataDirs }

    foreach ($plexAppDataSubDir in $plexAppDataSubDirs) {
        if (!(CompressPlexAppDataFolder `
                $plexAppDataSubDir `
                (Join-Path $backupDirPath $subDirFolders) `
                $tempZipFileDir `
                $zipFileExt)) {
            return $false
        }
    }

    return $true
}

function RestorePlexFromBackup {
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
    WakeUpDir $backupRootDir

    if (!(Test-Path $backupRootDir -PathType Container)) {
        LogError "Cannot find backup root folder:"
        LogError (Indent $backupDirPath)

        return $false
    }

    # If the backup folder is not specified, use the latest timestamped
    # folder under the backup directory defined at the top of the script.
    if (!$backupDirPath) {
        $backupDirPath = GetLastBackupDirPath $backupRootDir $regexBackupDirNameFormat

        if (!($backupDirPath)) {
            LogError "No backup folder matching timestamp format:"
            LogError (Indent $backupDirNameFormat)
            LogError "found under:"
            LogError (Indent $backupRootDir)

            return $false
        }
    }

    WakeUpDir $backupDirPath

    # Make sure the backup folder exists.
    if (!(Test-Path $backupDirPath -PathType Container)) {
        LogError "Cannot find backup folder:"
        LogError (Indent $backupDirPath)

        return $false
    }

    if ($robocopy) {
        if (!(RobocopyPlexAppData `
                (Join-Path $backupDirPath $subDirFiles) `
                $plexAppDataDir `
                $null `
                $retries `
                $retryWaitSec)) {
            return $false
        }
    }
    else {
       if (!(DecompressPlexAppData `
                $plexAppDataDir `
                $backupDirPath `
                $tempZipFileDir `
                $backupFileName `
                $zipFileExt `
                $subDirFiles `
                $subDirFolders)) {
            return $false
        }

        # Restore special subfolders.
        if (!(RestoreSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial))) {
            return $false
        }
    }

    # Import Plex registry key.
    $backupRegKeyFilePath = (Join-Path (Join-Path `
        $backupDirPath $subDirRegistry) ($backupFileName + $regFileExt))

    if (!(Test-Path $backupRegKeyFilePath -PathType Leaf)) {
        LogWarning "Cannot find Plex Windows registry key file:"
        LogWarning (Indent $backupRegKeyFilePath)
        LogWarning "Plex Windows registry key will not be restored."
    }
    else {
        LogMessage "Restoring Plex Windows registry key from:"
        LogMessage (Indent backupRegKeyFilePath)

        try {
            reg import $backupRegKeyFilePath *>&1 | Out-Null
        }
        catch {
            if ($_.Exception -and
                $_.Exception.Message -and
                ($_.Exception.Message -match "^The operation completed successfully")) {
                # This is a bogus error that only appears in PowerShell ISE, so ignore.
                return $true
            }
            else {
                LogException $_
            }

            return $false
        }
    }

    return $true
}

function CreatePlexBackup {
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

    WakeUpDir $backupRootDir

    # Make sure that the backup parent folder exists.
    if (!(Test-Path $backupRootDir -PathType Container)) {
        try {
            LogMessage "Creating backup root folder:"
            LogMessage (Indent $backupRootDir)

            New-Item -Path $backupRootDir -ItemType Directory -Force | Out-Null
        }
        catch {
            LogException $_

            return $false
        }
    }

    # Verify that we got the backup parent folder.
    if (!(Test-Path $backupRootDir -PathType Container)) {
        LogError "Cannot find or create backup root folder:"
        LogError (Indent $backupRootDir)

        return $false
    }

    # If the backup folder already exists, rename it by appending 1
    # (or next sequential number).
    if (!$backupDirPath) {
        $backupDirPath = Join-Path $backupRootDir $backupDirName
    }

    # Build backup folder path.
    LogMessage "New backup will be created in:"
    LogMessage (Indent $backupDirPath)

    # Delete old backup folders.
    if ($keep -gt 0) {
        # Get all folders with names from newest to oldest.
        $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory |
            Where-Object { $_.Name -match $regexBackupDirNameFormat } |
                Sort-Object -Descending

        $i = 1

        if ($oldBackupDirs.Count -ge $keep) {
            LogMessage "Deleting old backup folder(s):"
        }

        foreach ($oldBackupDir in $oldBackupDirs) {
            if ($i -ge $keep) {
                LogMessage (Indent $oldBackupDir.Name)

                try {
                    Remove-Item $oldBackupDir.FullName -Force -Recurse
                }
                catch {
                    LogError $_

                    # Non-critical error; can continue.
                }
            }

            $i++
        }
    }

    $Error.Clear()

    # Create new backup folder.
    if (!(Test-Path -Path $backupDirPath -PathType Container)) {
        LogMessage "Creating backup folder:"
        LogMessage (Indent $backupDirPath)

        try {
            New-Item -Path $backupDirPath -ItemType Directory -Force | Out-Null
        }
        catch {
            LogException $_

            return $false
        }
    }

    # Verify that temp folder exists (if specified).
    if ($tempZipFileDir) {
        # Make sure temp folder exists.
        if (!(Test-Path -Path $tempZipFileDir -PathType Container)) {
            try {
                # Create temp folder.
                New-Item -Path $tempZipFileDir -ItemType Directory -Force | Out-Null
            }
            catch {
                LogException $_

                LogError "Cannot find or create a temp archive folder:"
                LogError (Indent $tempZipFileDir)

                return $false
            }
        }
    }

    # Make sure that we have subfolders for files, folders, registry,
	# and special folder backups.
    $subDirs = @($subDirFiles, $subDirFolders, $subDirRegistry, $subDirSpecial)

    $printMsg = $false
    foreach ($subDir in $subDirs) {
        $subDirPath = Join-Path $backupDirPath $subDir

        if (!(Test-Path -Path $subDirPath -PathType Container)) {
            if (!$printMsg) {
                LogMessage "Creating task-specific subfolder(s) in:"
                LogMessage (Indent $backupDirPath)

                $printMsg = $true
            }

            try {
                New-Item -Path $subDirPath -ItemType Directory -Force | Out-Null
            }
            catch {
                LogError "Cannot create folder:"
                LogError (Indent $subDirPath)

                return $false
            }
        }
    }

    if ($robocopy) {
        if (!(RobocopyPlexAppData `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirFiles) `
                $excludePlexAppDataDirs `
                $retries `
                $retryWaitSec)) {
            return $false
        }
    }
    else {
        # Temporarily move special subfolders to backup folder.
        if (!(BackupSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial))) {
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
                $subDirFolders)) {
            if (!(RestoreSpecialSubDirs `
                    $specialPlexAppDataSubDirs `
                    $plexAppDataDir `
                    (Join-Path $backupDirPath $subDirSpecial))) {
                return $false
            }

            return $false
        }
    }

    # Export Plex registry key.
    $plexRegKeyFilePath = ((Join-Path (Join-Path $backupDirPath $subDirRegistry) `
        ($backupFileName + $regFileExt)))

    LogMessage "Backing up registry key:"
    LogMessage (Indent $plexRegKey)
    LogMessage "to:"
    LogMessage (Indent $plexRegKeyFilePath)

    try {
        Invoke-Command ` {reg export $plexRegKey $plexRegKeyFilePath /y *>&1 | Out-Null}
    }
    catch {
        LogException $_

        # Non-critical error; can continue.
    }

    $Error.Clear()

    # Copy moved special subfolders back to original folders.
    if (!$robocopy) {
        if (!(RestoreSpecialSubDirs `
                $specialPlexAppDataSubDirs `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirSpecial))) {
            return $false
        }
    }

    return $true
}

#---------------------------------[ MAIN ]---------------------------------

# We will trap errors in the try-catch blocks.
$ErrorActionPreference = 'Stop'

# Clear screen.
if ($ClearScreen) {
    Clear-Host
}

# Make sure we have no pending errors.
$Error.Clear()

# Save time for logging purposes.
$startTime = Get-Date

# Since we have not initialized log file, yet, print to console only.
if ((!$Quiet) -and (!$NoLogo)) {
    PrintVersion $false
}

LogMessage "Script started at:" $false
LogMessage (Indent $startTime) $false

# Load config settings from a config file (if any).
if (!(InitConfig)) {
    LogWarning "Cannot initialize run-time configuration settings." $false
    exit $EXITCODE_ERROR_CONFIG
}

InitMode
InitBackupRootDir
InitMailSetting

WakeUpDir $BackupRootDir

# Get the name and path of the backup directory.
$BackupDirName, $BackupDirPath =
    GetBackupDirNameAndPath `
        $Mode `
        $BackupRootDir `
        $BackupdDirNameFormat `
        $RegexBackupDirNameFormat `
        $BackupDirPath `
        $startTime

if ((!$BackupDirName) -or (!$BackupDirPath)) {
    LogError "Cannot determine location of the backup folder." $false
    exit $EXITCODE_ERROR_BACKUPDIR
}

# Initialize log file settings.
if (!(InitLog)) {
    exit $EXITCODE_ERROR_LOG
}

# Set the credential file name (for SMTP server).
InitCredentialFileName

# Assume that SMTP server does not require authentication for now.
$credential = $null

# Get SMTP server credentials from a file.
if (MustSendMail $SendMail $Mode) {
    if (!$Anonymous) {
        $credential = GetCredential `
            $CredentialFile `
            $PromptForCredential `
            $SaveCredential `
            $SmtpServer
    }
}

# If the From address is not speciifed, get it from credential object.
if (!$From) {
    if ($credential) {
        $From = $credential.UserName
    }
    else {
        $SendMail = "Never"
    }
}
if (!$To) {
    $To = $From
}

# Okay, at this point we are ready to roll.

# Print messages that we already sent to console to the log file.
if ((!$Quiet) -and (!$NoLogo)) {
    PrintVersion $true $false
}

LogMessage "Script started at:" $true $false
LogMessage (Indent $StartTime) $true $false

# Print command-line arguments to the log file (not needed for console).
if ($args.Count -gt 0) {
    $commandLine = ""
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i].Contains(" ")) {
            $commandLine = $commandLine + '"' + $args[$i] + '" '
        }
        else {
            $commandLine = $commandLine + $args[$i] + ' '
        }
    }

    LogMessage "Command-line arguments:" $true $false
    LogMessage (Indent $commandLine.Trim()) $true $false
}

# The rest of the log messages will be sent to console and log file
# (subject to other checks, e.g. if log file is turned off or quiet mode).

LogMessage "Operation mode:"
LogMessage (Indent $Mode.ToUpper())

LogMessage "Backup type:"
if ($Robocopy) {
    LogMessage (Indent "ROBOCOPY")
} else {
    LogMessage (Indent "COMPRESSION")
}

if ($LogFile) {
    LogMessage ("Log file:")
    LogMessage (Indent $LogFile)
}

if ($ErrorLogFile) {
    LogMessage ("Error log file:")
    LogMessage (Indent $ErrorLogFile)
}

# Check if we need to send log file as an attachment.
$attachment = $null
if ($LogFile -and (Test-Path -Path $LogFile -PathType Leaf)) {
    if (MustSendAttachment $SendLogFile $false) {
        $attachment = @($LogFile)
    }
}

# Determine path to Plex Media Server executable.
$success, $plexServerExePath =
    GetPlexMediaServerExePath `
        $PlexServerExePath `
        $PlexServerExeFileName

# Some variables for email notification message.
$computerName   = $env:ComputerName
$scriptPath     = $PSCommandPath
$subject        = $null
$subjectError   = "Plex backup failed :-("
$subjectSuccess = "Plex backup completed :-)"
$backupMode     = $null

if ($Robocopy) {
    $backupMode = $Mode.ToUpper() + " -ROBOCOPY"
}
else {
    $backupMode = $Mode.ToUpper()
}

# Check if we could determine the path to the PMS EXE.
if (!$success) {
    if (MustSendMail $SendMail $Mode $success) {
        $mailBody = FormatEmail `
            $computerName `
            $scriptPath `
            $backupMode `
            $BackupDirPath `
            $startTime `
            (Get-Date) `
            $success

        if ($mailBody) {
            SendMail `
                $From `
                $To `
                $subjectError `
                $mailBody `
                $attachment `
                $SmtpServer `
                $Port `
                $credential `
                $UseSsl
        }
    }

    exit $EXITCODE_ERROR_GETPMSEXE
}

# Get list of all running Plex services (match by display name).
try {
    $plexServices = GetRunningPlexServices $PlexServiceNameMatchString
}
catch {
    LogException $_

    if (MustSendMail $SendMail $Mode $success) {
        $mailBody = FormatEmail `
            $computerName `
            $scriptPath `
            $backupMode `
            $BackupDirPath `
            $startTime `
            (Get-Date) `
            $success

        if ($mailBody) {
            SendMail `
                $From `
                $To `
                $subjectError `
                $mailBody `
                $attachment `
                $SmtpServer `
                $Port `
                $credential `
                $UseSsl
        }
    }

    exit $EXITCODE_ERROR_GETSERVICES
}

# Stop all running Plex services.
$success, $plexServices = StopPlexServices $plexServices
if (!$success) {
    StartPlexServices $plexServices

    if (MustSendMail $SendMail $Mode $success) {
        $mailBody = FormatEmail `
            $computerName `
            $scriptPath `
            $backupMode `
            $BackupDirPath `
            $startTime `
            (Get-Date) `
            $success

        if ($mailBody) {
            SendMail `
                $From `
                $To `
                $subjectError `
                $mailBody `
                $attachment `
                $SmtpServer `
                $Port `
                $credential `
                $UseSsl
        }
    }

    exit $EXITCODE_ERROR_STOPSERVICES
}

# Stop Plex Media Server executable (if it's still running).
if (!(StopPlexMediaServer $plexServerExeFileName $PlexServerExePath)) {
    StartPlexServices $plexServices

    if (MustSendMail $SendMail $Mode $success) {
        $mailBody = FormatEmail `
            $computerName `
            $scriptPath `
            $backupMode `
            $BackupDirPath `
            $startTime `
            (Get-Date) `
            $success

        if ($mailBody) {
            SendMail `
                $From `
                $To `
                $subjectError `
                $mailBody `
                $attachment `
                $SmtpServer `
                $Port `
                $credential `
                $UseSsl
        }
    }

    exit $EXITCODE_ERROR_STOPPMSEXE
}

# Restore Plex app data from backup.
if ($Mode -eq "Restore") {
    $success = RestorePlexFromBackup `
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
else {
    $success = CreatePlexBackup `
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
StartPlexServices $plexServices

# Start Plex Media Server (if it's not running).
if (!($Shutdown)) {
    StartPlexMediaServer $plexServerExeFileName $PlexServerExePath
}

LogMessage "Script ended at:"
LogMessage (Indent (GetTimestamp))

$endTime = Get-Date

LogMessage "Script ran for (hr:min:sec.msec):"
LogMessage (Indent (New-TimeSpan -Start $startTime -End $endTime).ToString("hh\:mm\:ss\.fff"))

LogMessage "Script returned:"
if ($success) {
    LogMessage (Indent "SUCCESS")
    $subject = $subjectSuccess
}
else {
    LogMessage (Indent "ERROR")
    $subject = $subjectError
}

if ($success) {
    $subject = $subjectSuccess
}
else {
    $subject = $subjectError
}

if (MustSendMail $SendMail $Mode $success) {
    $mailBody = FormatEmail `
        $computerName `
        $scriptPath `
        $backupMode `
        $BackupDirPath `
        $startTime `
        $endTime `
        $success

    if ($mailBody) {

        if ($LogFile -and (Test-Path -Path $LogFile -PathType Leaf)) {
            if (!(MustSendAttachment $SendLogFile $success)) {
                $attachment = $null
            }
        }

        SendMail `
            $From `
            $To `
            $subject `
            $mailBody `
            $attachment `
            $SmtpServer `
            $Port `
            $credential `
            $UseSsl
    }
}

LogMessage "Done."

if ($success) {
    exit $EXITCODE_SUCCESS
}
else {
    exit $EXITCODE_ERROR
}
