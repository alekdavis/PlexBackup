# PlexBackup.ps1
[PlexBackup.ps1](PlexBackup.ps1) is a [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview) script that can back up and restore [Plex](https://www.plex.tv/) application data files on a Windows system. This document explains how it works and how to use it. If you don't care about the details and just want to get the instruction, see [Getting Started](GETTING%20STARTED.md).

## Introduction
Plex does not offer a meaningful backup feature. Yes, it can back up a Plex database which can be handy in case of a Plex database corruption, but if you need to move your Plex instance to a different system or restore it after a hard drive crash, a single database backup will be of little use. For a meaningful backup, in addition to the Plex database, you will need a copy of the Plex Windows registry key and tens (or hundreds) of thousands of Plex application data files. Keep in mind that backing up gigabytes of data files may take a long time, especially when they are copied remotely, such as to a NAS share. And you must keep the Plex Media Server stopped while the backup job is running (otherwise, it can corrupt the data). In the other words, a meaningful Plex backup is a challenge to which I could not find a good solution, so I decided to build my own. Ladies and gentlemen, meet [PlexBackup.ps1](PlexBackup.ps1).

## Overview
[PlexBackup.ps1](PlexBackup.ps1) (or, briefly, _PlexBackup_) is a [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview) script that can back up and restore a Plex instance on a Windows system. The script backs up the Plex database, Windows registry key, and app data folders essential for the Plex operations (it ignores the non-essential files, such as logs or crash reports). And it makes sure that Plex is not running when the backup job is active (which may take hours). And it can send email to you, too.

IMPORTANT: The script will not back up media (video, audio, images) or Plex program files. You must use different backup techniques for those. For example, you can keep your media files on a [RAID 5](https://en.wikipedia.org/wiki/Standard_RAID_levels#RAID_5) disk array (for redundancy) and back them up to an alternative storage on a periodic basis. And you don't really need to back up Plex program files, since you can always download them. But for everything else, PlexBackup is your guy.

### Backup types
The script can perform two types of backup: compressed (default or `7zip`) and uncompressed (`Robocopy`).

#### Default
By default, the script compresses every essential folder under the root of the Plex application data folder (`Plex Media Server`) and saves the compressed data as separate ZIP files. For better efficiency (in case the backup folder is remote, such as on a NAS share), it first compresses the data in a temporary local file and then moves the compressed file to a backup folder (you can compress the data and save the ZIP files directly to the backup folder by setting the value of the `TempDir` parameter to null or empty string). There is a problem with PowerShell's compression routine that fails to process files and folders with paths that are longer than 260 characters. If you get this error, use the `SpecialDirs` parameter (in code or config file) to specify the folders that are too long (or parents of the subfolders or files that are too long) and PlexBackup will copy them as-is without using compression (by default, the following application data folder is not compressed: `Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated`).

#### 7zip
Instead of the default compression, you can use the [7-zip](https://www.7-zip.org/) command-line tool (`7z.exe`). 7-zip works faster (for both compression and extraction), it produces smaller compressed files, and it allowes you to exclude specific file types using the `ExcludeFiles` parameter (by default, it excludes `*.bif`, i.e. thumbnail preview files). To use 7-zip compression, [install 7-zip](https://www.7-zip.org/download.html), and set the PlexBackup script's `Type` parameter to `7zip` (i.e. `-Type 7zip`) or use the `-SevenZip` shortcut (on command line). If you install 7-zip in a non-default directory, use the `ArchiverPath` parameter to set path to the `7z.exe` file.

#### Robocopy
If you run PlexBackup with the `Robocopy` switch, instead of compression, the script will create a mirror of the Plex application data folder (minus the non-essential folders) using the [Robocopy](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy) command (executed with the `/MIR` switch). Robocopy also allows you to exclude specific file types as [described above](#7zip).

You may want to play with either option to see which one works better for you.

### Backup modes
PlexBackup can run in the following modes (specified by the `Mode` switch or a corresponding shortcut):

- `Backup`: the default mode that creates a new backup archive.
- `Continue`: resumes an incomplete backup job or, in case of the `Robocopy` backup, re-syncs the backup archive.
- `Restore`: restores Plex application data from a backup.

If a previous backup does not exist, the `Continue` mode will behave just like the `Backup` mode. When running in the `Continue` mode for backup jobs that use compression, the script will skip the folders that already have the corresponding archive files. For the `Robocopy` backup, the `Continue` mode will synchronize the existing backup archive with the Plex application data files.

In all cases, before performing a backup or restore operation, PlexBackup will stop all Plex Windows services along with the Plex Media Server process. After the script completes the operation, it will restart them. You can use the `NoRestart` switch to tell the script not to restart the Plex Media Server process. The script will not run if the Plex Media Server is not active. To execute the script when Plex Media Server is not running, use the `Inactive` switch, but make sure you know what you are doing.

### Plex Windows Registry key
To make sure PlexBackup saves and restores the right registry key, run it under the same account as Plex Media Server runs. The registry key will be backed up every time a backup job runs. If the backup folder does not contain the backup registry key file, the Plex registry key will not be imported on a restore.

### Script execution
You must launch PlexBackup _as Administrator_ while being logged in under the same account your Plex Media Server runs.

If you haven't done this already, you may need to adjust the PowerShell script execution policy to allow scripts to run. To check the current execution policy, run the following command from the PowerShell prompt:

```PowerShell
Get-ExecutionPolicy
```
If the execution policy does not allow running scripts, do the following:

- Start Windows PowerShell with the "Run as Administrator" option.
- Run the following command:

```PowerShell
Set-ExecutionPolicy RemoteSigned
```

This will allow running unsigned scripts that you write on your local computer and signed scripts downloaded from the Internet (okay, this is not a signed script, but if you copy it locally, make a non-destructive change--e.g. add a space character, remove the space character, and save the file--it should work).

Alternatively, you may want to run the script as:

```PowerShell
start powershell.exe -noprofile -executionpolicy bypass -file .\PlexBackup.ps1 -ConfigFile .\PlexBackup.ps1.json
```

For additional information, see [Running Scripts](https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)) at Microsoft TechNet Library.

### Dependencies

PlexBackup uses the following modules:

- [ScriptVersion](https://www.powershellgallery.com/packages/ScriptVersion)
- [ConfigFile](https://www.powershellgallery.com/packages/ConfigFile)
- [StreamLogging](https://www.powershellgallery.com/packages/StreamLogging)
- [SingleInstance](https://www.powershellgallery.com/packages/SingleInstance)

To verify that the modules get installed, run the script manually. You may be [prompted](https://docs.microsoft.com/en-us/powershell/gallery/how-to/getting-support/bootstrapping-nuget) to update the [NuGet](https://www.nuget.org/downloads) version (or you can do it yourself in advance).

### Runtime parameters
The default value of the PlexBackup script's runtime parameters are defined in code, but you can override some of them via command-line arguments or config file settings.

### Config file
Config file is optional. The default config file must be named after the PlexBackup script with the `.json` extension, such as `PlexBackup.ps1.json`. If the file with this name does not exist in the backup script's folder, PlexBackup will not care. You can also specify a custom config file name (or more accurately, path) via the `ConfigFile` command-line argument ([see sample](PlexBackup.ps1.SAMPLE.json)).

A config file must use [JSON formatting](https://www.json.org/), such as:

```JavaScript
{
    "_meta": {
        "version": "1.0",
        "strict": false,
        "description": "Sample run-time settings for the PlexBackup.ps1 script."
    },
    "Mode": {
        "_meta": {
            "set": "Backup,Continue,Restore",
            "default": "Backup"
        },
        "value": null
    },
    "Type": {
        "_meta": {
            "set": ",7zip,Robocopy",
            "default": ""
        },
        "value": null
    },
    "PlexAppDataDir": {
        "_meta": {
            "default": "$env:LOCALAPPDATA\\Plex Media Server"
        },
        "value": null
    },
    "BackupRootDir": {
        "_meta": {
            "default": "$PSScriptRoot"
        },
        "value": null
    },
    "BackupDir": {
        "_meta": {
            "default": null
        },
        "value": null
    },
    "TempDir": {
        "_meta": {
            "default": "$env:TEMP"
        },
        "hasValue": true,
        "value": null
    },
    "WakeUpDir": {
        "_meta": {
            "default": null
        },
        "value": null
    },
    "ArchiverPath": {
        "_meta": {
            "default": "$env:ProgramFiles\\7-Zip\\7z.exe"
        },
        "value": null
    },
    "Quiet": {
        "value": null
    },
    "LogLevel": {
        "_meta": {
            "default": "None,Error,Warning,Info,Debug"
        },
        "value": null
    },
    "Log": {
        "value": true
    },
    "LogFile": {
        "value": null
    },
    "ErrorLog": {
        "value": null
    },
    "ErrorLogFile": {
        "value": null
    },
    "Keep": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "3"
        },
        "value": null
    },
    "Retries": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "5"
        },
        "value": null
    },
    "RetryWaitSec": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "10"
        },
        "value": null
    },
    "RawOutput": {
        "value": null
    },
    "Inactive": {
        "value": null
    },
    "NoRestart": {
        "value": null
    },
    "NoSingleton": {
        "value": null
    },
    "NoVersion": {
        "value": null
    },
    "NoLogo": {
        "value": null
    },
    "Test": {
        "value": false
    },
    "SendMail": {
        "_meta": {
            "set": "Never,Always,OnError,OnSuccess,OnBackup,OnBackupError,OnBackupSuccess,OnRestore,OnRestoreError,OnRestoreSuccess",
            "default": "Never"
        },
        "value": null
    },
    "SmtpServer": {
        "value": "smtp.gmail.com"
    },
    "Port": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "0"
        },
        "value": 587
    },
    "From": {
        "value": null
    },
    "To": {
        "value": null
    },
    "NoSsl": {
        "value": null
    },
    "CredentialFile": {
        "value": null
    },
    "NoCredential": {
        "value": null
    },
    "Anonymous": {
        "value": null
    },
    "SendLogFile": {
        "_meta": {
            "set": "Never,OnError,OnSuccess,Always",
            "default": "Never"
        },
        "value": "OnError"
    },
    "Logoff": {
        "value": null
    },
    "Reboot": {
        "value": null
    },
    "ForceReboot": {
        "value": null
    },
    "ExcludeDirs": {
        "_meta": {
            "default": ["Diagnostics","Crash Reports","Updates","Logs"]
        },
        "value": null
    },
    "ExcludeFiles": {
        "_meta": {
            "default": ["*.bif"]
        },
        "value": null
    },
    "SpecialDirs": {
        "_meta": {
            "default": ["Plug-in Support\\Data\\com.plexapp.system\\DataItems\\Deactivated"]
        },
        "value": null
    },
    "PlexServiceName": {
        "_meta": {
            "default": "^Plex"
        },
        "hasValue": false,
        "value": null
    },
    "PlexServerFileName": {
        "_meta": {
            "default": "Plex Media Server.exe"
        },
        "value": null
    },
    "PlexServerPath": {
        "value": null
    },
    "ArchiverOptionsCompress": {
        "_meta": {
            "comment": "The default options will always be applied. To include additional options, define them as an array.",
            "default": ["-r","-y"]
        },
        "value": null
    },
    "ArchiverOptionsExpand": {
        "_meta": {
            "comment": "The default options will always be applied. To include additional options, define them as an array.",
            "default":  ["-aoa","-y"]
        },
        "value": null
    },
    "Machine": {
        "_meta": {
            "set": "x86,amd64",
            "default": null
        },
        "value": null
    }
}
```
The root `_meta` element describes the file and the file structure. It does not include any configuration settings. The important attributes  of the `_meta` element are:

- `version`: can be used to handle future file schema changes, and
- `strictMode`: when set to `true` every config setting that needs to be used must have the `hasValue` attribute set to `true`; if the `strictMode` element is missing or if its value is set to `false`, every config setting that gets validated by the PowerShell's `if` statement will be used.

The `_meta` elements under the configuration settings can contain anything (they are not processed at run time). In the [sample config file](PlexBackup.ps1.SAMPLE.json), they contain default values, value ranges and other helpful information, but they can be removed if not needed.

Notice that to have the script recognize a `null` or empty value from the config file, you need to set the `hasValue` flags to `true`; otherwise, it will be ignored.

Make sure you use proper JSON formatting (escape characters, etc) when defining the config values. In particular you need to escape backslash characters, so if your backup root folder is located on a NAS share, such as `\\MYNAS\Backups\Plex`, the configuration file setting must look like:

```JavaScript
    "BackupRootDir": {
        "_meta": {
            "default": "$PSScriptRoot"
        },
        "value": "\\\\MYNAS\\Backups\\Plex"
    },
```


### Logging
Use the `Log` switch to write operation progress and informational messages to a log file. By default, the log file will be created in the backup folder. The default log file name reflects the name of the script with the `.log` extension, such as `PlexBackup.ps1.log`. The default log file is created in the backup folder. You can specify a custom log file path via the `LogFile` argument.

If you set the `ErrorLog` (or the `ErrorLogFile`) switch, the script will write error messages to a dedicated error log file (in addition to the standard log file, if one is defined). By default, the error log file will be created in the backup folder. The default error log file name reflects the name of the script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`.

You can control log output sung the `LogLevel` and `Quiet` switches. The default log level is `Info`, but it can be also set to `None`, `Error`, `Warning`, and `Debug`. When the `Quiet` switch is set, no log messages will be written to the console.

You can control other log settings via the `PlexBackup.ps1.StreamLogging.json` configuration file (find out more at [StreamLogging page](https://github.com/alekdavis/StreamLogging)), but unless you know what you are doing, you should probably leave it alone.

### Debugging
In case you need to troubleshoot issues with PlexBackup, run the script with the `Verbose` flag, which will display additional information about the script processing. You can also set the `Debug` flag that will make the script print the information about the function calls. Keep in mind that the verbose and debug messages are only printed to the console and will not be saved in the log file.

### Backup snapshots
Every time you run a new backup job, the script will create a backup snapshot folder. The name of the folder will reflect the timestamp of when the script started. Use the `Keep` switch to specify how many backup snapshots you want to keep: `0` (keep all previously created backups), `1` (keep the current backup snapshot only), `2` (keep the current backup snapshot and one before it), `3` (keep the current backup snapshot and two most recent snapshots), and so on. The default value is `3`.

### Backup version
When backing up data, PlexBackup records the version of Plex Media Server. If you try to restore a backup on a system with a different version of Plex Media Server, the operation will fail. To to force the operation over a version mismatch, use the `NoVersion` parameter, but be aware that it may pose risks. Keep in mind that if you execute PlexBackup with the Plex Media Server process not running, version information will not be saved or checked during the backup or restore operations.

### Email notification
Use the `SendMail` parameter to let PlexBackup know whether or when you want to receive email notifications about the backup job completion using one of the following values:

- `Never`: email notification will not be sent (default)
- `Always`: email notification will be sent always
- `OnError`: receive a notification if an error occurs during any operation
- `OnSuccess`: receive a notification only if an operation was successful
- `OnBackup`: receive a notification about a new or resumed backup operation on error or success
- `OnBackupError`: receive notification about a new or resumed backup operations on error only
- `OnBackupSuccess`: receive a notifications about a new or resumed backup operations on success only
- `OnRestore`: receive a notification about a restore operation on error or success
- `OnRestoreError`: receive a notification about a failed restore operation only
- `OnRestoreSuccess`: receive a notifications about a failed restore operation only

To receive a copy of the log file along with the email notification, set the `SendLogFile` parameter to:

- `Never`: the log file will not be sent as an email message attachment (default)
- `Always`: the log file will be sent always
- `OnError`: only send the log file if an error occurs
- `OnSuccess`: only send the log file if no error occurs

#### SMTP server
When sending email notifications, Plex backup will need to know how to connect to the SMTP server. You can specify the server via the `SmtpServer` parameter, such as: `-SmtpServer smtp.gmail.com `. If the server is using a non-default SMTP port, use the `Port` parameter to specify the port, such as; `-Port 587`. If you do not want your message to be sent over encrypted (SSL) channel, set the `NoSsl` switch.

#### SMTP credentials
If your SMTP server does not require explicit authentication, use the `Anonymous` switch to tell PlexBackup to ignore explicit credentials; otherwise, the script will prompt you for credentials and save them in . If you want these credentials saved in a file (with password encrypted using the computer- and user-specific key) so you do not need to enter them every time the script runs, use the `SaveCredentials` switch. You can specify the path to the credential file via the `CredentialFile` parameters but if you don't, the script will try to use the default file named after the running script with the `.xml` extension, such as `PlexBackup.ps1.xml`. You can also generate the credential file in advance by running the following PowerShell command:

```PowerShell
Get-Credential | Export-CliXml -Path "PathToFile.xml"
```

IMPORTANT: Most public providers, such as Gmail, Yahoo, Hotmail, and so on, have special requirements that you need to meet before you can use their SMTP servers to send email. For example, to use Gmail's SMTP server, you need to do the following:

(a) If you have two-factor authentication or, as Google calls it _two-step verification_, enabled, you cannot use your own password, so you need to generate an application password and use it along with your Gmail email address (see [Sign in using App Passwords](https://support.google.com/mail/answer/185833?hl=en)).

(b) If you are not using two-factor authentication, you can use your own password, but may need to enable less secure application access in your account settings (see [Let less secure apps access your account](https://support.google.com/accounts/answer/6010255?hl=en)).

For additional information or if you run into any issues, check support articles covering your provider.

#### Addresses
By default, PlexBackup will use the username provided via the SMTP credentials as both the `To` and `From` addresses, but you can set them explicitly via the `To` and `From` parameters. If the `To` parameter is not specified, the recipient's address will be the same as the sender's.

## See also

- [Getting started](GETTING%20STARTED.md)
- [Scheduled Plex backup](SCHEDULED%20PLEX%20BACKUP.md)
- [Frequently asked questions (FAQs)](FAQs.md)

## Syntax
```PowerShell
.\PlexBackup.ps1 `
    [[-Mode <String>] | -Backup | -Continue | -Update | -Restore] `
    [[-Type <String>] | -SevenZip | -Robocopy ] `
    [-ModuleDir <String>] `
    [-ConfigFile <String>] `
    [-PlexAppDataDir <String>] `
    [-BackupRootDir <String>] `
    [-BackupDir <String>] `
    [-TempDir <String>] `
    [-WakeUpDir <String>] `
    [-ArchiverPath <String>] `
    [-Quiet | -Q] `
    [-LogLevel <String>] `
    [-Log | -L] `
    [-LogFile <String>] `
    [-ErrorLog] `
    [-ErrorLogFile <String>] `
    [-Keep <Int32>] `
    [-Retries <Int32>] `
    [-RetryWaitSec <Int32>] `
    [-RawOutput]`
    [-Inactive] `
    [-NoRestart] `
    [-NoSingleton] `
    [-NoVersion] `
    [-NoLogo] `
    [-Test] `
    [-SendMail <String>] `
    [-SmtpServer <String>] `
    [-Port <Int32>] `
    [-From <String>] `
    [-To <String>] `
    [-NoSsl] `
    [-CredentialFile <String>] `
    [-SaveCredential] `
    [-Anonymous] `
    [-SendLogFile <String>] `
    [-ModulePath <String>] `
    [-Logoff] `
    [-Reboot] `
    [-ForceReboot] `
    [<CommonParameters>]

```
### Arguments

`Mode`

Specifies the mode of operation:

- `Backup` (default)
- `Continue`
- `Restore`

`Backup`

Shortcut for `-Mode Backup`.

`Continue`

Shortcut for `-Mode Continue`.

`Restore`

Shortcut for `-Mode Restore`.

`Type`

Specifies the non-default type of backup method:

- `7zip`
- `Robocopy`

By default, the script will use the built-in compression.

`SevenZip`

Shortcut for `-Type 7zip`.

`Robocopy`

Shortcut for `-Type Robocopy`.

`ModuleDir`

Optional path to directory holding the modules used by this script. This can be useful if the script runs on the system with no or restricted access to the Internet. By default, the module path will point to the `Modules` folder in the script's folder.

`ConfigFile`

Path to the optional custom config file. The default config file is named after the script with the `.json` extension, such as 'PlexBackup.ps1.json'.

`PlexAppDataDir`

Location of the Plex Media Server application data folder.

`BackupRootDir`

Path to the root backup folder holding timestamped backup subfolders. If not specified, the script folder will be used.

`BackupDirPath`

When running the script in the `Restore` mode, holds path to the backup folder (by default, the subfolder with the most recent timestamp in the name located in the backup root folder will be used).

`TempDir`

Temp folder used to stage the archiving job (use local drive for efficiency). To bypass the staging step, set this parameter to null or empty string.

`WakeUpDir`

Optional path to a remote share that may need to be woken up before starting Plex Media Server.

`ArchiverPath`

Defines the path to the 7-zip command line tool (7z.exe) which is required when running the script with the `-Type 7zip` or `-SevenZip` switch. Default: `$env:ProgramFiles\7-Zip\7z.exe`.

`Quiet`

Set this switch to suppress log entries sent to a console.

`LogLevel`

Specifies the log level of the output:

- `None`
- `Error`
- `Warning`
- `Info`
- `Debug`

`Log`

When set to true, informational messages will be written to a log file. The default log file will be created in the backup folder and will be named after this script with the `.log` extension, such as `PlexBackup.ps1.log`.

`LogFile`

Use this switch to specify a custom log file location. When this parameter is set to a non-null and non-empty value, the `-Log` switch can be omitted.

`ErrorLog`

When set to true, error messages will be written to an error log file. The default error log file will be created in the backup folder and will be named after this script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`.

`ErrorLogFile`

Use this switch to specify a custom error log file location. When this parameter is set to a non-null and non-empty value, the `-ErrorLog` switch can be omitted.

`Keep`

Number of old backups to keep:
  `0` - retain all previously created backups,
  `1` - latest backup only,
  `2` - latest and one before it,
  `3` - latest and two before it,
and so on.

`Retries`

The number of retries on failed copy operations (corresponds to the Robocopy `/R` switch).

`RetryWaitSec`

Specifies the wait time between retries in seconds (corresponds to the Robocopy `/W` switch).

`RawOutput`

Set this switch to display raw output from the external commands, such as Robocopy or 7-zip.

`Inactive`

When set, allows the script to continue if Plex Media Server is not running.

`NoRestart`

Set this switch to not start the Plex Media Server process at the end of the operation (could be handy for restores, so you can double check that all is good before launching Plex media Server).

`NoSingleton`

Set this switch to ignore check for multiple script instances running concurrently.

`NoVersion`

Forces restore to ignore version mismatch between the current version of Plex Media Server and the version of Plex Media Server active during backup.

`NoLogo`

Specify this command-line switch to not print version and copyright info.

`Test`

When turned on, the script will not generate backup files or restore Plex app data from the backup files.

`SendMail`

Indicates in which case the script must send an email notification about the result of the operation:

- `Never` (default)
- `Always`
- `OnError` (for any operation)
- `OnSuccess` (for any operation)
- `OnBackup` (for both the Backup and Continue modes on either error or success)
- `OnBackupError`
- `OnBackupSuccess`
- `OnRestore` (on either error or success)
- `OnRestoreError`
- `OnRestoreSuccess`

`SmtpServer`

Defines the SMTP server host. If not specified, the notification will not be sent.

`Port`

Specifies an alternative port on the SMTP server. Default: 0 (zero, i.e. default port 25 will be used).

`From`

Specifies the email address when email notification sender. If this value is not provided, the username from the credentails saved in the credentials file or entered at the credentials prompt will be used. If the From address cannot be determined, the notification will not be sent.

`To`

Specifies the email address of the email recipient. If this value is not provided, the addressed defined in the To parameter will be used.

`NoSsl`

Tells the script not to use the Secure Sockets Layer (SSL) protocol when connecting to the SMTP server. By default, SSL is used.

`CredentialFile`

Path to the file holding username and encrypted password of the account that has permission to send mail via the SMTP server. You can generate the file via the following PowerShell command:

```PowerShell
Get-Credential | Export-CliXml -Path "PathToFile.xml"
```

The default log file will be created in the backup folder and will be named after this script with the '.xml' extension, such as 'PlexBackup.ps1.xml'.

`SaveCredential`

When set, the SMTP credentials will be saved in a file (encrypted with user- and machine-specific key) for future use.

`Anonymous`

Tells the script to not use credentials when sending email notifications.

`SendLogFile`

Indicates in which case the script must send an attachment along with th email notification:

- `Never` (default)
- `Always`
- `OnError`
- `OnSuccess`

`Logoff`

Specify this command-line switch to log off all user accounts (except the running one) before starting Plex Media Server. This may help address issues with remote drive mappings under the wrong credentials.

`Reboot`

Reboots the computer after a successful backup operation (ignored on restore).

`ForceReboot`

Forces an immediate restart of the computer after a successfull backup operation (ignored on restore).


`<CommonParameters>`

Common PowerShell parameters (the script is not using these explicitly).

## Returns

To check whether the backup script executed successfully or encountered an error, check the value of the `$LASTEXITCODE` variable:

- `0` (zero) indicates success
- `1` indicates error

## Examples

The following examples assume that the the default settings are used for the unspecified script arguments.

### Example 1
```PowerShell
.\PlexBackup.ps1
```
Backs up Plex application data to the default backup location using the default Windows compression.

### Example 2
```PowerShell
.\PlexBackup.ps1 -ConfigFile "C:\Scripts\PlexBackup.ps1.ROBOCOPY.json
```
Runs the script with the non-default settings specified in the custom config file.

### Example 3
```PowerShell
.\PlexBackup.ps1 -Log -ErrorLog -Keep 5
```
Backs up Plex application data to the default backup location using file and folder compression. Writes progress to the default log file. Writes error messages to the default error log file. Keeps current and four previous backup snapshots (total of five).

### Example 4
```PowerShell
.\PlexBackup.ps1 -Type Robocopy
.\PlexBackup.ps1 -Robocopy
```
Creates a mirror copy of the Plex application data (minus the non-essential folders) in the default backup location using the Robocopy command.

### Example 5
```PowerShell
.\PlexBackup.ps1 -Type 7zip
.\PlexBackup.ps1 -SevenZip
```
Backs up Plex application data to the default backup location using the 7-zip command-line tool.

### Example 6
```PowerShell
.\PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
```
Backs up Plex application data to the specified backup location on a network share using file and folder compression.

### Example 7
```PowerShell
.\PlexBackup.ps1 -Mode Continue
.\PlexBackup.ps1 -Continue
```
Continues the last backup process (using file and folder compression) where it left off.

### Example 8
```PowerShell
.\PlexBackup.ps1 -Continue -Robocopy
```
Reruns the last backup process using a mirror copy.

### Example 9
```PowerShell
.\PlexBackup.ps1 -Mode Restore
.\PlexBackup.ps1 -Restore
```
Restores Plex application data from the latest backup from the default folder holding compressed data.

### Example 10
```PowerShell
.\PlexBackup.ps1 -Restore -Robocopy
```
Restores Plex application data from the latest backup in the default folder holding a mirror copy of the Plex application data folder.

### Example 11
```PowerShell
.\PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MYNAS\PlexBackup\20190101183015"
```
Restores Plex application data from the specified backup folder holding compressed data on a remote share.

### Example 12
```PowerShell
.\PlexBackup.ps1 -SendMail Always -SaveCredential -SendLogFile OnError -SmtpServer smtp.gmail.com -Port 587
```
Runs a backup job and sends an email notification over an SSL channel. If the backup operation fails, the log file will be attached to the email message. The sender's and the recipient's email addresses will determined from the username of the credential object. The credential object will be set either from the credential file or, if the file does not exist, via a user prompt (in the latter case, the credential object will be saved in the credential file with password encrypted using a user- and computer-specific key).

### Example 13
```PowerShell
Get-Help .\PlexBackup.ps1
```
Shows help information.
