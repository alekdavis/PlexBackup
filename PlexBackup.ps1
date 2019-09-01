#------------------------------[ HELP INFO ]-------------------------------

<#
.SYNOPSIS
Backs up or restores Plex application data files and registry keys on a
Windows system.

.DESCRIPTION
The script can run in four modes:

- Backup (initiates a new backup),
- Continue (continues a previous backup),
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

.PARAMETER Type
Specifies the non-default type of backup method: 7zip or Robocopy.

.PARAMETER SevenZip
Shortcut for '-Type 7zip'

.PARAMETER Robocopy
Shortcut for '-Type Robocopy'.

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

.PARAMETER Inactive
When set, allows the script to continue if Plex Media Server is not running.

.PARAMETER Forces
Forces restore to ignore version mismatch between the current version of
Plex Media Server and the version of Plex Media Server active during backup.

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

.PARAMETER ArchiverPath
Defines the path to the 7-zip command line tool (7z.exe) which is required
when running the script with the '-Type 7zip' or '-SevenZip' switch. Default:
$env:ProgramFiles\7-Zip\7z.exe.

.PARAMETER ClearScreen
Specify this command-line switch to clear console before starting script execution.

.NOTES
Version    : 1.5.10
Author     : Alek Davis
Created on : 2019-08-15
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
PlexBackup.ps1 -SevenZip
Backs up Plex application data to the default backup location using
the 7-zip command-line tool (7z.exe). 7-zip command-line tool must
be installed and the script must know its path.

.EXAMPLE
PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
Backs up Plex application data to the specified backup location on a
network share.

.EXAMPLE
PlexBackup.ps1 -Continue
Continues a previous backup process from where it left off.

.EXAMPLE
PlexBackup.ps1 -Restore
Restores Plex application data from the latest backup in the default folder.

.EXAMPLE
PlexBackup.ps1 -Restore -Robocopy
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
    $ConfigFile = $null,

    [string]
    $PlexAppDataDir = "$env:LOCALAPPDATA\Plex Media Server",

    [string]
    $BackupRootDir = $null,

    [string]
    $BackupDirPath = $null,

    [AllowEmptyString()]
    [string]
    $TempZipFileDir = $env:TEMP,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Keep = 3,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Retries = 5,

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $RetryWaitSec = 10,

    [Alias("L")]
    [switch]
    $Log,

    [switch]
    $LogAppend,

    [string]
    $LogFile,

    [switch]
    $ErrorLog,

    [switch]
    $ErrorLogAppend,

    [string]
    $ErrorLogFile,

    [Alias("Q")]
    [switch]
    $Quiet,

    [switch]
    $Inactive,

    [switch]
    $Shutdown,

    [switch]
    $Force,

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

    [ValidateRange(0,[int]::MaxValue)]
    [int]
    $Port = 0,

    [switch]
    $UseSsl,

    [string]
    $CredentialFile = $null,

    [Alias("Prompt")]
    [switch]
    $PromptForCredential,

    [switch]
    [Alias("Save")]
    $SaveCredential,

    [switch]
    $Anonymous,

    [ValidateSet("Never", "OnError", "OnSuccess", "Always")]
    [string]
    $SendLogFile = "Never",

    [switch]
    $NoLogo,

    [string]
    $ArchiverPath = "$env:ProgramFiles\7-Zip\7z.exe",

    [Alias("Cls")]
    [switch]
    $ClearScreen
)

#-----------------------------[ DECLARATIONS ]-----------------------------

# The following Plex application folders do not need to be backed up.
$ExcludePlexAppDataDirs = @(
    "Diagnostics",
    "Crash Reports",
    "Updates",
    "Logs"
)

# The following file types do not need to be backed up:
# *.bif - thumbnail previews
$ExcludePlexAppDataFiles = @(
    "*.bif"
)

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
$7ZipFileExt= ".7z"
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

$EXITCODE_SUCCESS               =  0 # success
$EXITCODE_ERROR                 =  1 # error during backup or restore operation
$EXITCODE_ERROR_CONFIG          =  2 # error processing config file
$EXITCODE_ERROR_BACKUPDIR       =  3 # problem determining or setting backup folder
$EXITCODE_ERROR_LOG             =  4 # problem with log file(s)
$EXITCODE_ERROR_GETPMSEXE       =  5 # cannot determine path to PMS executable
$EXITCODE_ERROR_GETSERVICES     =  6 # cannot read Plex Windows services
$EXITCODE_ERROR_STOPSERVICES    =  7 # cannot stop Plex Windows services
$EXITCODE_ERROR_STOPPMSEXE      =  8 # cannot stop PMS executable file
$EXITCODE_ERROR_ARCHIVERPATH    =  9 # archiver path undefined or file missing
$EXITCODE_ERROR_VERSIONMISMATCH = 10 # archiver path undefined or file missing
$EXITCODE_ERROR_MODULE          = 11 # cannot load module

#------------------------------[ FUNCTIONS ]-------------------------------

#--------------------------------------------------------------------------
# LoadModule
#   Installs (if needed) and loads a PowerShell module.
function LoadModule {
    param(
        [string]
        $ModuleName
    )

    if (!(Get-Module -Name $ModuleName)) {

        if (!(Get-Module -Listavailable -Name $ModuleName)) {
            Install-Module -Name $ModuleName -Force -Scope CurrentUser -ErrorAction Stop
        }

        Import-Module $ModuleName -ErrorAction Stop -Force
    }
}

#--------------------------------------------------------------------------
# GetPmsVersion
#   Returns either:
#   - file version of the current Plex Media Server executable, or
#   - version of the last saved backup (from the version.txt file)
function GetPmsVersion {
    param (
        [string]
        $path
    )

    if ((!$path) -or (!(Test-Path -Path $path -PathType Leaf))) {
        return $null
    }

    try {
        # For EXE file, get version info from the assembly.
        if ($path.EndsWith(".exe", [System.StringComparison]::InvariantCultureIgnoreCase)) {
            return (Get-Item $path).VersionInfo.FileVersion
        }

        # Assume that this is a previous backup's version.txt file.
        return (Get-Content -Path $path)
    }
    catch {
        LogWarning ("Cannot get Plex Media Server version info from:")
        LogWarning (Indent $path)

        LogWarning ($_.Exception.Message)

        return $null
    }
}

#--------------------------------------------------------------------------
# SavePmsVersion
#   Saves current file version of the Plex Media Server executable to
#   the version.txt file.
function SavePmsVersion {
    param (
        [string]
        $version,
        [string]
        $path
    )

    if (!$version -or !$path) {
        return
    }

    try {
        if (!(Test-Path -Path $$path -PathType Leaf)) {
            New-Item -Path $path -Type file -Force | Out-Null
        }

        $version | Set-Content -Path $path
    }
    catch {
        LogWarning ("Cannot save Plex Media Server version:")
        LogWarning (Indent $version)
        LogWarning ("to:")
        LogWarning (Indent $path)

        LogWarning ($_.Exception.Message)
    }
}

#--------------------------------------------------------------------------
# Indent
#   Adds indent(s) in front of the text string.
function Indent {
    param (
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

#--------------------------------------------------------------------------
# Log
#   Writes a message to the script's console window or a text file.
function Log {
    param (
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

#--------------------------------------------------------------------------
# LogException
#   Writes exception info to one or more of the following:
#   - active console window
#   - script's log file
#   - script's error log file
function LogException {
    param (
        [object]
        $ex,
        [bool]
        $writeToLog = $true,
        [bool]
        $writeToErrorLog = $true
    )

    # Do not write to console in the quiet mode.
    if (!$script:Quiet) {
         Write-Error $ex -ErrorAction Continue
    }

    # Write to log file if settings align.
    if ($writeToLog -and $script:Log -and $script:LogFile) {
        try {
            Out-File -FilePath $script:LogFile -Append -Encoding utf8 -InputObject $ex
        }
        catch {
            # There was a problem writing to the log file, so don't use the log
            # file from this point on.
            $script:Log     = $false
            $script:LogFile = $null

            try {
                # Log error that we failed to write to the log file.
                LogException $_ $false $writeToErrorLog
            }
            catch {
            }

            $Error.Clear()
        }
    }

    # Write to error log file if settings align.
    if ($writeToErrorLog -and $script:ErrorLog -and $script:ErrorLogFile) {
        try {
            Out-File -FilePath $script:ErrorLogFile -Append -Encoding utf8 -InputObject $ex
        }
        catch {
            # There was a problem writing to the error log file, so don't use the error log
            # file from this point on.
            $script:ErrorLog     = $false
            $script:ErrorLogFile = $null

            try {
                # Log error that we failed to write to the error log file.
                LogException $_ $writeToLog $false
            }
            catch {
            }

            $Error.Clear()
        }
    }
}

#--------------------------------------------------------------------------
# LogException
#   Writes an error message to one or more of the following:
#   - active console window
#   - script's log file
#   - script's error log file
function LogError {
    param (
        [string]
        $message = "",
        [bool]
        $writeToLog = $true,
        [bool]
        $writeToErrorLog = $true
    )

    # Send message to console (unless the script is running in the quiet mode).
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

#--------------------------------------------------------------------------
# LogWarning
#   Writes a warning message to one or more of the following:
#   - active console window
#   - script's log file
function LogWarning {
    param (
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

    if (!$writeToFile -or !$script:Log -or !$script:LogFile) {
        return
    }

    # If we failed to write to the log file, don't try again.
    if (!(Log $message $script:LogFile))
    {
        $script:Log     = $false
        $script:LogFile = $null
    }
}

#--------------------------------------------------------------------------
# LogMessage
#   Writes an informational message to one or more of the following:
#   - active console window
#   - script's log file
function LogMessage {
    param (
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

    if (!$writeToFile -or !$script:Log -or !$script:LogFile) {
        return
    }

    # If we failed to write to the log file, don't try again.
    if (!(Log $message $script:LogFile)) {
        $script:Log     = $false
        $script:LogFile = $null
    }
}

#--------------------------------------------------------------------------
# InitMode
#   Initializes script execution mode.
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

#--------------------------------------------------------------------------
# InitType
#   Initializes backup type.
function InitType {
    if (!$script:Type) {
        if ($script:Robocopy) {
            $script:Type = "Robocopy"
        }
        elseif ($script:SevenZip) {
            $script:Type = "7zip"
        }
    }

    # For 7-zip archival, change default '.zip' extension to '.7z'.
    if ($script:Type -eq "7zip") {
        $script:ZipFileExt = $script:7ZipFileExt
    }
}

#--------------------------------------------------------------------------
# InitBackupRootDir
#   Initializes the path to the backup root folder.
function InitBackupRootDir {
    # If it was specified, use as is.
    if ($script:BackupRootDir) {
        return
    }

    # If backup folder is specified, use its parent as the root.
    if ($script:BackupDirPath) {
        $script:BackupRootDir = Split-Path -Path $script:BackupDirPath -Parent
    }
    # Use script's folder as the root.
    else {
        $script:BackupRootDir = Split-Path -Path $PSCommandPath -Parent
    }
}

#--------------------------------------------------------------------------
# InitLog
#   Initializes log settings.
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

    if ($script:Log -and !$script:LogFile) {
        $logFileName = "$script:Mode.log"

        $script:LogFile = Join-Path $script:BackupDirPath $logFileName
    }

    if ($script:ErrorLog -and !$script:ErrorLogFile) {
        $errorLogFileName = "$script:Mode.err.log"

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

#--------------------------------------------------------------------------
# PrintVersion
#   Prints script version info to the console and/or the log file.
function PrintVersion {
    param (
        [bool]
        $writeToFile = $true,
        [bool]
        $writeToConsole = $true
    )

    $versionInfo = Get-ScriptVersion
    $scriptName  = (Get-Item $PSCommandPath).Basename

    LogMessage ($scriptName +
        " v" + $versionInfo["Version"] +
        " " + $versionInfo["Copyright"]) $writeToFile $writeToConsole
}

#--------------------------------------------------------------------------
# InitMailSettings
#   Initializes email settings.
function InitMailSetting {
    if (!$script:smtpServer) {
        $script:SendMail = "Never"
    }
}

#--------------------------------------------------------------------------
# InitCredentialFileName
#   Initializes SMTP credential file path.
function InitCredentialFileName {
    if (!$script:SendMail -or ($script:SendMail -eq "Never")) {
        return
    }

    if ($script:Anonymous) {
        return
    }

    if (!$script:CredentialFile) {
        $script:CredentialFile = $PSCommandPath + ".xml"
    }
}

#--------------------------------------------------------------------------
# GetCredential
#   Gets SMTP credentials from the credential file or an interactive prompt.
#   Will also store credential info in the credential file (optional).
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

#--------------------------------------------------------------------------
# MustSendAttachment
#   Returns 'true' if conditions for sending the log file as an attachment
#   are met; returns 'false' otherwise.
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

#--------------------------------------------------------------------------
# MustSendMail
#   Returns 'true' if conditions for sending email notification about the
#   operation result are met; returns 'false' otherwise.
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
        if (($when.EndsWith("Error")) -and ($success -eq $true)) {
            return $false
        }
        if (($when.EndsWith("Success")) -and ($success -eq $false)) {
            return $false
        }

        return $true
    }

    if ($when.StartsWith("OnRestore")) {
        if ($mode -ne "Restore") {
            return $false
        }
        if (($when.EndsWith("Error")) -and ($success -eq $true)) {
            return $false
        }
        if (($when.EndsWith("Success")) -and ($success -eq $false)) {
            return $false
        }

        return $true
    }

    return $true
}

#--------------------------------------------------------------------------
# SendMail
#   Sends email notification with the information about the operation result.
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

#--------------------------------------------------------------------------
# FormatEmail
#   Formats HTML body for the notification email.
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
        $success = $true,
        [string]
        $errorInfo = $null,
        [long]
        $objectCount = 0,
        [long]
        $backupSize = 0
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
<tr><td style='#STYLE_TEXT#'>The backup folder is at</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_DIR#</td></tr>
<tr><td style='#STYLE_TEXT#'>containing</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_OBJECTS# objects</td></tr>
<tr><td style='#STYLE_TEXT#'>and</td></tr>
<tr><td style='#STYLE_VAR_TEXT#'>#VALUE_BACKUP_SIZE# GB of data</td></tr>
<tr><td style='#STYLE_ERROR#'>Error info</td></tr>
<tr><td style='#STYLE_VAR_ERROR#'>#VALUE_ERROR_INFO#</td></tr>
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

    $styleErrorInfo     = 'mso-hide: all;overflow: hidden;max-height: 0;display: none;line-height: 0;visibility: hidden;'
    $styleVarErrorInfo  = $styleErrorInfo

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

    $styleText               = $styleParagraph + $styleTextFont
    $styleVarText            = $styleVarParagraph +  $styleVarTextFont
    $styleResult             = $styleResultParagraph + $styleResultTextFont

    if ($errorInfo) {
        $styleErrorInfo      = $styleText
        $styleVarErrorInfo   = $styleVarText
    }

    $emailTokens = @{
        STYLE_PAGE              = $stylePage
        STYLE_TEXT              = $styleText
        STYLE_VAR_TEXT          = $styleVarText
        STYLE_ERROR             = $styleErrorInfo
        STYLE_VAR_ERROR         = $styleVarErrorInfo
        STYLE_RESULT            = $styleResult
        VALUE_COMPUTER_NAME     = $computerName
        VALUE_SCRIPT_PATH       = $scriptPath
        VALUE_BACKUP_MODE       = $backupMode
        VALUE_BACKUP_DIR        = $backupDir
        VALUE_SCRIPT_START_TIME = $scriptStartTime
        VALUE_SCRIPT_END_TIME   = $scriptEndTime
        VALUE_SCRIPT_DURATION   = $scriptDuration
        VALUE_RESULT            = $resultText
        VALUE_ERROR_INFO        = $errorInfo
        VALUE_BACKUP_OBJECTS    = '{0:N0}' -f $objectCount
        VALUE_BACKUP_SIZE       = [math]::round($backupSize /1Gb, 1)
    }

    # $htmlEmail = Get-Content -Path TemplateLetter.txt -RAW
    foreach ($token in $emailTokens.GetEnumerator())
    {
        $pattern = '#{0}#' -f $token.key
        $body = $body -replace $pattern, $token.Value
    }

    return $body
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
        $path
    )

    if (!$path) {
        return
    }

    # Just in case path points to a remote share on a sleeping device,
    # try waking it up (a directory listing should do it).
    for ($i = 0; $i -lt 3; $i++) {
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

#--------------------------------------------------------------------------
# GetLastBackupDirPath
#   Returns the path of the most recent backup folder.
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

#--------------------------------------------------------------------------
# GetNewBackupDirName
#   Generates the new name of the backup subfolder based on the current
#   timestamp in the format: YYYYMMDDhhmmss.
function GetNewBackupDirName {
    param (
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

#--------------------------------------------------------------------------
# GetBackupDirNameAndPath
#   Returns name and path of the backup directory that will be used for the
#   running backup job (it can be an existing or a new directory depending
#   on the backup mode).
function GetBackupDirNameAndPath {
    param (
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

#--------------------------------------------------------------------------
# GetPlexMediaServerExePath
#   Returns the path of the running Plex Media Server executable.
function GetPlexMediaServerExePath {
    param (
        [string]
        $path,
        [string]
        $name,
        [bool]
        $inactive
    )

    # Get path of the Plex Media Server executable.
    if (!$path) {
        $path = Get-Process |
            Where-Object {$_.Path -match $name + "$" } |
                Select-Object -ExpandProperty Path
    }

    # Make sure we got the Plex Media Server executable file path.
    if (!$path) {
        if ($inactive) {
            LogWarning "Cannot determine path of the the Plex Media Server executable file."
            LogWarning "Plex Media Server is not running."

            return $true, $null
        }
        else {
            LogError "Cannot determine path of the the Plex Media Server executable file."
            LogError "Please make sure Plex Media Server is running."

            return $false, $null
        }
    }

    # Verify that the Plex Media Server executable file exists.
    if (!(Test-Path -Path $path -PathType Leaf)) {
        LogError "Cannot find Plex Media Server executable file:"
        LogError (Indent $path)

        return $false, $null
    }

    return $true, $path
}

#--------------------------------------------------------------------------
# GetRunningPlexServices
#   Returns the list of Plex Windows services (identified by display names).
function GetRunningPlexServices {
    param (
        [string]
        $displayNameSearchString
    )

    return Get-Service |
        Where-Object {$_.DisplayName -match $displayNameSearchString} |
            Where-Object {$_.status -eq 'Running'}
}

#--------------------------------------------------------------------------
# StopPlexServices
#   Stops running Plex Windows services.
function StopPlexServices {
    param (
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

#--------------------------------------------------------------------------
# StartPlexServices
#   Starts Plex Windows services.
function StartPlexServices {
    param (
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

#--------------------------------------------------------------------------
# StopPlexMediaServer
#   Stops a running instance of Plex Media Server.
function StopPlexMediaServer {
    param (
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

#--------------------------------------------------------------------------
# StartPlexMediaServer
#   Launches Plex Media Server.
function StartPlexMediaServer {
    param (
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
            Start-Process $plexServerExePath -LoadUserProfile
        }
        catch {
            LogException $_
        }
    }
}

#--------------------------------------------------------------------------
# CopyFolder
#   Copies contents of a folder using a ROBOCOPY command.
function CopyFolder {
    param (
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

#--------------------------------------------------------------------------
# MoveFolder
#   Moves contents of a folder using a ROBOCOPY command.
function MoveFolder {
    param (
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

#--------------------------------------------------------------------------
# BackupSpecialSubDirs
#   Moves contents of the special Plex app data folders to special backup
#   folder to exclude them from the backup compression job, so that they
#   could be copied separately (because special directories have long names,
#   they can break archival process used by PowerShell's Compress-Archive
#   command).
function BackupSpecialSubDirs {
    param (
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

#--------------------------------------------------------------------------
# RestoreSpecialSubDirs
#   Copies backed up special Plex app data folders back to their original
#   locations (see also BackupSpecialSubDirs).
function RestoreSpecialSubDirs {
    param (
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

#--------------------------------------------------------------------------
# DecompressPlexAppDataFolder
#   Restores a Plex app data folder from the corresponding compressed
#   backup file.
function DecompressPlexAppDataFolder {
    param (
        [string]
        $type,
        [object]
        $backupZipFile,
        [string]
        $backupDirPath,
        [string]
        $plexAppDataDir,
        [string]
        $tempZipFileDir,
        [string]
        $zipFileExt,
        [string]
        $archiverPath
    )
    $backupZipFilePath = $backupZipFile.FullName

    $plexAppDataDirName = $backupZipFile.BaseName
    $plexAppDataDirPath = Join-Path $plexAppDataDir $plexAppDataDirName

    $Error.Clear()

    # If we have a temp folder, stage the extracting job.
    if ($tempZipFileDir) {
        $tempZipFileName = "PlexBackup-" + (New-Guid).Guid + $zipFileExt

        $tempZipFilePath = Join-Path $tempZipFileDir $tempZipFileName

        # Copy backup archive to a temp zip file.
        LogMessage "Copying backup archive file:"
        LogMessage (Indent $backupZipFilePath)
        LogMessage "to a temp zip file:"
        LogMessage (Indent $tempZipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            Start-BitsTransfer -Source $backupZipFilePath -Destination $tempZipFilePath -ErrorAction Stop
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
            if ($type -eq "7zip") {
                & $archiverPath "x" "$tempZipFilePath" "-o$plexAppDataDirPath" "-aoa"

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned: " + $LASTEXITCODE)
                }
            }
            else {
                Expand-Archive -Path $tempZipFilePath -DestinationPath $plexAppDataDirPath -Force
            }
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
            if ($type -eq "7zip") {
                & $archiverPath "x" "$backupZipFilePath" "-o$plexAppDataDirPath" "-aoa"

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned: " + $LASTEXITCODE)
                }
            }
            else {
                Expand-Archive -Path $backupZipFilePath -DestinationPath $plexAppDataDirPath -Force
            }
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

#--------------------------------------------------------------------------
# DecompressPlexAppData
#   Restores Plex app data folders from the compressed backup files.
function DecompressPlexAppData {
    param (
        [string]
        $type,
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
        $subDirFolders,
        [string]
        $archiverPath
    )

    # Build path to the ZIP file that holds files from the root Plex app data folder.
    $zipFileName = $backupFileName + $zipFileExt
    $zipFileDir  = Join-Path $backupDirPath $subDirFiles
    $zipFilePath = Join-Path $zipFileDir $zipFileName

    # Restore files in the root Plex app data folder.
    if (Test-Path -Path $zipFilePath -PathType Leaf) {
        LogMessage "Restoring Plex app data files from:"
        LogMessage (Indent $zipFilePath)
        LogMessage "to:"
        LogMessage (Indent $plexAppDataDir)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            if ($type -eq "7zip") {
                & $archiverPath "x" "$zipFilePath" "-o$plexAppDataDir" "-aoa"

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned: " + $LASTEXITCODE)
                }
            }
            else {
                Expand-Archive -Path $zipFilePath -DestinationPath $plexAppDataDir -Force
            }
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

    # Restore each Plex app data subfolder from the corresponding backup archive file.
    foreach ($backupZipFile in $backupZipFiles) {
        if (!(DecompressPlexAppDataFolder `
                $type `
                $backupZipFile `
                (Join-Path $backupDirPath $subDirFolders) `
                $plexAppDataDir `
                $tempZipFileDir `
                $zipFileExt `
                $archiverPath)) {
            return $false
        }
    }

    return $true
}

#--------------------------------------------------------------------------
# CompressPlexAppDataFolder
#   Backs up contents of a Plex app data subfolder to a compressed file.
function CompressPlexAppDataFolder {
    param (
        [string]
        $mode,
        [string]
        $type,
        [object]
        $sourceDir,
        [string[]]
        $excludeFiles,
        [string]
        $backupDirPath,
        [string]
        $tempZipFileDir,
        [string]
        $zipFileExt,
        [string]
        $archiverPath
    )

    $backupZipFileName = $sourceDir.Name + $zipFileExt
    $backupZipFilePath = Join-Path $backupDirPath $backupZipFileName

    if ((Test-Path $backupZipFilePath -PathType Leaf)) {
        LogWarning "Backup archive already exists in:"
        LogWarning (Indent $backupZipFilePath)
        LogWarning "Skipping."

        return $true
    }

    # If a staged temp folder is specified (instead of compressing over network)...
    if ($tempZipFileDir) {
        $tempZipFileName = "PlexBackup-" + (New-Guid).Guid + $zipFileExt

        $tempZipFilePath = Join-Path $tempZipFileDir $tempZipFileName

        LogMessage "Archiving:"
        LogMessage (Indent $sourceDir.FullName)
        LogMessage "to temp file:"
        LogMessage (Indent $tempZipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        try {
            if ($type -eq "7zip") {
                [Array]$cmdArgs = "a", "$tempZipFilePath", (Join-Path $sourceDir.FullName "*"), "-r"

                foreach ($excludeFile in $excludeFiles) {
                    $cmdArgs += "-x!$excludeFile"
                }

                & $archiverPath @cmdArgs

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned: " + $LASTEXITCODE)
                }
            }
            else {
                Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $tempZipFilePath
            }
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
                Start-BitsTransfer -Source $tempZipFilePath -Destination $backupZipFilePath -ErrorAction Stop
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

        try {
            if ($type -eq "7zip") {
                [Array]$cmdArgs = "a", "$backupZipFilePath", (Join-Path $sourceDir.FullName "*"), "-r"

                foreach ($excludeFile in $excludeFiles) {
                    $cmdArgs += "-x!$excludeFile"
                }

                & $archiverPath @cmdArgs

                if ($LASTEXITCODE -gt 0) {
                    throw ("7-zip returned: " + $LASTEXITCODE)
                }
            }
            else {
                Compress-Archive -Path (Join-Path $sourceDir.FullName "*") -DestinationPath $backupZipFilePath
            }
        }
        catch {
            LogException $_

            return $false
        }

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

#--------------------------------------------------------------------------
# CompressPlexAppData
#   Backs up contents of the Plex app data folder to the compressed files.
function CompressPlexAppData {
    param (
        [string]
        $mode,
        [string]
        $type,
        [string]
        $plexAppDataDir,
        [string[]]
        $excludePlexAppDataDirs,
        [string[]]
        $excludePlexAppDataFiles,
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
        $subDirFolders,
        [string]
        $archiverPath
    )

    # Build path to the ZIP file that will hold files from Plex app data folder.
    $zipFileName = $backupFileName + $zipFileExt
    $zipFileDir  = Join-Path $backupDirPath $subDirFiles
    $zipFilePath = Join-Path $zipFileDir $zipFileName

    # Back up files from root folder, if there are any.
    if (@(Get-ChildItem (Join-Path $plexAppDataDir "*") -File ).Count -gt 0) {

        LogMessage "Backing up Plex app data files from:"
        LogMessage (Indent $plexAppDataDir)
        LogMessage "to:"
        LogMessage (Indent $zipFilePath)
        LogMessage "at:"
        LogMessage (Indent (GetTimestamp))

        # Skip if ZIP file already exists.
        if ((Test-Path $zipFilePath -PathType Leaf)) {
            LogWarning "Backup file already exists in:"
            LogWarning (Indent $zipFilePath)
            LogWarning "Skipping."
        }
        else {
            try {
                if ($type -eq "7zip") {

                    [Array]$cmdArgs = "a", "$zipFilePath"

                    foreach ($excludeFile in $excludeFiles) {
                        $cmdArgs += "-x!$excludeFile"
                    }

                    & $archiverPath @cmdArgs (Get-ChildItem (Join-Path $plexAppDataDir "*") -File)

                    if ($LASTEXITCODE -gt 0) {
                        throw ("7-zip returned: " + $LASTEXITCODE)
                    }
                }
                else {
                    Get-ChildItem -Path $plexAppDataDir -File | Compress-Archive -DestinationPath $zipFilePath -Update
                }
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
    }

    LogMessage "Backing up Plex app data folders from:"
    LogMessage (Indent $plexAppDataDir)
    LogMessage "to:"
    LogMessage (Indent (Join-Path $backupDirPath $subDirFolders))

    $plexAppDataSubDirs = Get-ChildItem $plexAppDataDir -Directory  |
        Where-Object { $_.Name -notin $excludePlexAppDataDirs }

    foreach ($plexAppDataSubDir in $plexAppDataSubDirs) {
        if (!(CompressPlexAppDataFolder `
                $mode `
                $type `
                $plexAppDataSubDir `
                $excludePlexAppDataFiles `
                (Join-Path $backupDirPath $subDirFolders) `
                $tempZipFileDir `
                $zipFileExt `
                $archiverPath)) {
            return $false
        }
    }

    return $true
}

#--------------------------------------------------------------------------
# RobocopyPlexAppData
#   Copies the Plex app data folder using the Windows 'robocopy' tool.
function RobocopyPlexAppData {
    param (
        [string]
        $source,
        [string]
        $destination,
        [string[]]
        $excludeDirs,
        [string[]]
        $excludeFiles,
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

    $cmdArgs = [System.Collections.ArrayList]@(
        "$source",
        "$destination",
        "/MIR",
        "/R:$retries",
        "/W:$retryWaitSec",
        "/MT"
    )

    try {
        # Set directories to exclude from backup.
        if (($excludeDirs) -and ($excludeDirs.Count -gt 0)) {
            $excludePaths = [System.Collections.ArrayList]@()

            # We need to use full paths.
            foreach ($excludeDir in $excludeDirs) {
                ($excludePaths.Add((Join-Path $source $excludeDir))) | Out-Null
            }

            $cmdArgs.Add("/XD")
            $cmdArgs.Add($excludePaths)
        }

        # Set file types to exclude (e.g. '*.bif').
        if (($excludeFiles) -and ($excludeFiles.Count -gt 0)) {
            $cmdArgs.Add("/XF")
            $cmdArgs.Add($excludeFiles)
        }

        robocopy @cmdArgs
    }
    catch {
        LogException $_

        return $false
    }

    if ($LASTEXITCODE -gt 7) {
        LogError "Robocopy failed with error code:"
        LogError (Indent $LASTEXITCODE)
        LogError "To troubleshoot, execute the following command:"

        LogError ("robocopy" + (((ConvertTo-Json -InputObject $cmdArgs -Compress) -replace "[\[\],]"," " ) -replace "\s+"," "))

        return $false
    }

    LogMessage "Completed at:"
    LogMessage (Indent (GetTimestamp))

    return $true
}

#--------------------------------------------------------------------------
# RestorePlexFromBackup
#   Restores Plex app data and registry key from a backup.
function RestorePlexFromBackup {
    param (
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
        [string]
        $type,
        [int]
        $retries,
        [int]
        $retryWaitSec,
        [string]
        $archiverPath
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

    if ($type -eq "Robocopy") {
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
                $type `
                $plexAppDataDir `
                $backupDirPath `
                $tempZipFileDir `
                $backupFileName `
                $zipFileExt `
                $subDirFiles `
                $subDirFolders `
                $archiverPath)) {
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

#--------------------------------------------------------------------------
# CreatePlexBackup
#   Creates a backup for the Plex app data folder and registry key.
function CreatePlexBackup {
    param (
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
        $excludePlexAppDataFiles,
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
        [string]
        $type,
        [int]
        $retries,
        [int]
        $retryWaitSec,
        [string]
        $archiverPath,
        [string]
        $pmsVersion,
        [string]
        $pmsVersionPath
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
    LogMessage "Backup will be saved in:"
    LogMessage (Indent $backupDirPath)

    # Delete old backup folders.
    if ($keep -gt 0) {

        # Get all folders with names from newest to oldest.
        # Do not include the backup directory if it already exists.
        $oldBackupDirs = Get-ChildItem -Path $backupRootDir -Directory |
            Where-Object {
                $_.Name -match $regexBackupDirNameFormat -and
                $_.Name -notmatch $backupDirName
            } | Sort-Object -Descending

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
    if ($mode -ne "Continue") {
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

    if ($type -eq "Robocopy") {
        if (!(RobocopyPlexAppData `
                $plexAppDataDir `
                (Join-Path $backupDirPath $subDirFiles) `
                $excludePlexAppDataDirs `
                $excludePlexAppDataFiles `
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
                $mode `
                $type `
                $plexAppDataDir `
                $excludePlexAppDataDirs `
                $excludePlexAppDataFiles `
                $backupDirPath `
                $tempZipFileDir `
                $backupFileName `
                $zipFileExt `
                $subDirFiles `
                $subDirFolders `
                $archiverPath)) {
            if (!(RestoreSpecialSubDirs `
                    $specialPlexAppDataSubDirs `
                    $plexAppDataDir `
                    (Join-Path $backupDirPath $subDirSpecial))) {
                return $false
            }

            return $false
        }
    }

    SavePmsVersion $pmsVersion $pmsVersionPath

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
    if ($type -ne "Robocopy") {
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

# Load modules for reading config file settings and script version info.
# https://www.powershellgallery.com/packages/ScriptVersion
# https://www.powershellgallery.com/packages/ConfigFile
$modules = @("ScriptVersion", "ConfigFile")
foreach ($module in $modules) {
    try {
        LoadModule -ModuleName $module
    }
    catch {
        LogWarning "Cannot load module $module." $false
        exit $EXITCODE_ERROR_MODULE
    }
}

# Save time for logging purposes.
$startTime = Get-Date

# Since we have not initialized log file, yet, print to console only.
if ((!$Quiet) -and (!$NoLogo)) {
    PrintVersion $false
}

LogMessage "Script started at:" $false
LogMessage (Indent $startTime) $false

# Load config settings from a config file (if any).
try {
    Import-ConfigFile -ConfigFilePath $ConfigFile -DefaultParameters $PSBoundParameters
}
catch {
    LogWarning "Cannot initialize run-time configuration settings." $false
    exit $EXITCODE_ERROR_CONFIG
}

InitMode
InitType

if ($Type -eq "7zip") {
    if (!$ArchiverPath) {
        LogError "Please set the value of parameter 'ArchiverPath' to point to the 7-zip command-line tool (7z.exe)." $false
        exit $EXITCODE_ERROR_ARCHIVERPATH
    }

    if (!(Test-Path -Path $ArchiverPath -PathType Leaf)) {
        LogError "The 7-zip command line tool is not found in:" $false
        LogError (Indent $ArchiverPath) $false
        LogError "Please define a valid path in parameter:" $false
        LogError (Indent "ArchiverPath") $false
        exit $EXITCODE_ERROR_ARCHIVERPATH
    }
}

InitBackupRootDir
InitMailSetting

# In case we are backing up to a remote system (NAS, etc), let's wake it up
# (in case it is sleeping).
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

# If the 'To' address is not specified, use the 'From' address.
if (!$To) {
    $To = $From
}

# At this point, we are ready to roll.

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
if ($Type) {
    LogMessage (Indent $Type.ToUpper())
} else {
    LogMessage (Indent "DEFAULT")
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
        $PlexServerExeFileName `
        $Inactive

# Some variables for email notification message.
$computerName   = $env:ComputerName
$scriptPath     = $PSCommandPath
$subject        = $null
$subjectError   = "Plex backup failed :-("
$subjectSuccess = "Plex backup completed :-)"
$backupMode     = $null

# This one is for the email notification.
if ($Type) {
    $backupMode = $Mode.ToUpper() + " -" + $Type.ToUpper()
}
else {
    $backupMode = $Mode.ToUpper()
}

# If we got Plex Media Server (PMS) path, check its version.
$pmsVersionPath = Join-Path $BackupDirPath "version.txt"

if ($success) {
    $pmsVersion = GetPmsVersion $PlexServerExePath

    if ($pmsVersion) {
        $pmsVersion = $pmsVersion.Trim()

        LogMessage ("Plex Media Server version (CURRENT):")
        LogMessage (Indent $pmsVersion)

        #if ($Mode -ne "Restore") {
        #    SavePmsVersion $pmsVersion $pmsVersionPath
        #}
    }

    if ($Mode -eq "Restore") {
        $pmsVersionBackup = GetPmsVersion $pmsVersionPath

        if ($pmsVersionBackup) {
            $pmsVersionBackup = $pmsVersionBackup.Trim()

            LogMessage ("Plex Media Server version (BACKUP):")
            LogMessage (Indent $pmsVersionBackup)

            if ($pmsVersion -and ($pmsVersion -ne $pmsVersionBackup)) {
                if (!$Force) {

                    LogError ("Backup version:")
                    LogError (Indent $pmsVersionBackup)
                    LogError ("does not match the current version of Plex Media Server:")
                    LogError (Indent $pmsVersion)
                    LogError ("To ignore version check, run the script with the '-Force' flag.")

                    if (MustSendMail $SendMail $Mode $success) {
                        $mailBody = FormatEmail `
                            $computerName `
                            $scriptPath `
                            $backupMode `
                            $BackupDirPath `
                            $startTime `
                            (Get-Date) `
                            $success `
                            "Backup version '$pmsVersionBackup' does not match the current version of Plex Media Server '$pmsVersion'."

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

                    exit $EXITCODE_ERROR_VERSIONMISMATCH
                }
            }
        }
    }
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
            $success `
            "Cannot determine the path of the Plex Media Server executable file."

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
            $success `
            "Cannot get the list of running Plex services."

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
            $success `
            "Cannot stop Plex services."

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
if ($PlexServerExePath) {
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
                $success `
                "Cannot stop Plex Media Server."

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
        $Type `
        $Retries `
        $RetryWaitSec `
        $ArchiverPath
}
# Back up Plex app data.
else {
    if (!$Type -and $ExcludePlexAppDataFiles -and $ExcludePlexAppDataFiles.Count -gt 0) {
        LogWarning ("Ignoring script parameter:")
        LogWarning (Indent "ExcludePlexAppDataFiles")
    }

    $success = CreatePlexBackup `
        $Mode `
        $PlexAppDataDir `
        $PlexRegKey `
        $BackupRootDir `
        $BackupDirName `
        $BackupdDirPath `
        $TempZipFileDir `
        $ExcludePlexAppDataDirs `
        $ExcludePlexAppDataFiles `
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
        $Type `
        $Retries `
        $RetryWaitSec `
        $ArchiverPath `
        $pmsVersion `
        $pmsVersionPath
}

# Start all previously running Plex services (if any).
StartPlexServices $plexServices

# Start Plex Media Server (if it's not running).
if ((!$Shutdown) -and $PlexServerExePath) {
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

$errorInfo = $null
if ($success) {
    $subject = $subjectSuccess
}
else {
    $subject   = $subjectError
    $errorInfo = "For error details, check the log file (make sure the script runs with logging turned on)."
}

$backupInfo = Get-ChildItem -Recurse $BackupDirPath | Measure-Object -Property Length -Sum

if (MustSendMail $SendMail $Mode $success) {
    $mailBody = FormatEmail `
        $computerName `
        $scriptPath `
        $backupMode `
        $BackupDirPath `
        $startTime `
        $endTime `
        $success `
        $errorInfo `
        $backupInfo.Count `
        $backupInfo.Sum

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

# THE END
#--------------------------------------------------------------------------
