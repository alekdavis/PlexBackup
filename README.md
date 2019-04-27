# PlexBackup.ps1
[PlexBackup.ps1](PlexBackup.ps1) is a [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview) script that can back up and restore [Plex](https://www.plex.tv/) application data files on a Windows system. This document explains how it works and how to use it. If you don't care about the details and just want to see the  instruction, see [Getting Started](GETTING%20STARTED.md).

## Introduction
Plex does not offer a meaningful backup feature. Yes, it can back up a Plex database, but if you need to move your Plex instance to a different system or restore it after a hard drive crash, a single database backup file will be of little use. For a meaningful backup, in addition to the Plex database, you will need a copy of the Plex Windows registry key and tens (or hundreds) of thousands of Plex application data files. Keep in mind that backing up gigabytes of data files may take a long time, especially when they are copied remotely, such as to a NAS share. And you must keep the Plex Media Server stopped while the backup job is running (otherwise, it can corrupt the data). In the other words, a meaningful Plex backup is a challenge to which I could not find a good solution, so I decided to build my own. Ladies and gentlemen, meet [PlexBackup.ps1](PlexBackup.ps1).

## Overview
[PlexBackup.ps1](PlexBackup.ps1) (or, briefly, _PlexBackup_) is a [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview) script that can back up and restore a Plex instance on a Windows system. The script backs up the Plex database, Windows registry key, and app data folders essential for the Plex operations (it ignores the non-essential files, such as logs or crash reports). And it makes sure that Plex is not running when the backup job is active (which may take hours). And it can send email to you, too.

IMPORTANT: The script will not back up media (video, audio, images) or Plex program files. You must use different backup techniques for those. For example, you can keep your media files on a [RAID 5](https://en.wikipedia.org/wiki/Standard_RAID_levels#RAID_5) disk array. And you don't really need to back up Plex program files, since you can always download them. But for everything else, PlexBackup is your guy.

### Backup types
The script can perform two types of backup: compressed (default or `7zip`) and uncompressed (`Robocopy`). 

#### Default
By default, the script compresses every essential folder under the root of the Plex application data folder (`Plex Media Server`) and saves the compressed data as separate ZIP files. For better efficiency (in case the backup folder is remote, such as on a NAS share), it first compresses the data in a temporary local file and then moves the compressed file to a backup folder (you can compress the data and save the ZIP files directly to the backup folder by setting the value of the `TempZipFileDir` parameter to null or empty string). There is a problem with PowerShell's compression routine that fails to process files and folders with paths that are longer than 260 characters. If you get this error, use the `SpecialPlexAppDataSubDirs` parameter (in code or config file) to specify the folders that are too long (or parents of the subfolders or files that are too long) and PlexBackup will copy them as-is without using compression (by default, the following application data folder is not compressed: `Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated`).

#### 7zip
Instead of the default compression, you can use the [7-zip](https://www.7-zip.org/) command-line tool (`7z.exe`). 7-zip works faster (for both compression and extraction), it produces smaller compressed files, and it allowes you to exclude specific file types using the `ExcludePlexAppDataFiles` parameter (by default, it excludes `*.bif`, i.e. thumbnail preview files). To use 7-zip encryption, [install 7-zip](https://www.7-zip.org/download.html), and set the PlexBackup script's `Type` parameter to `7zip` (i.e. `-Type 7zip`) or use the `-SevenZip` shortcut (on command line). If you install 7-zip in a non-default directory, use the `ArchiverPath` parameter to set path to the `7z.exe` file.

#### Robocopy
If you run PlexBackup with the `Robocopy` switch, instead of compression, the script will create a mirror of the Plex application data folder (minus the non-essential folders) using the [Robocopy](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy) command (executed with the `/MIR` switch). Robocopy also allows you to exclude specific file types as [described above](#7zip).

You may want to play with either option to see which one works better for you.

### Backup modes
PlexBackup can run in the following modes (specified by the `Mode` switch or a corresponding shortcut):

- `Backup`: the default mode that creates a new backup archive.
- `Continue`: resumes an incomplete backup job or, in case of the `Robocopy` backup, resyncs the backup archive.
- `Restore`: restores Plex application data from a backup.

If a previous backup does not exist, the `Continue` mode will behave just like the `Backup` mode. When running in the `Continue` mode for backup jobs that use compression, the script will skip the folders that already have the corresponding archive files. For the `Robocopy` backup, the `Continue` mode will syncronize the existing backup archive with the Plex application data files.

In all cases, before performing a backup or restore operation, PlexBackup will stop all Plex Windows services along with the Plex Media Server process. After the script completes the operation, it will restart them. You can use the `Shutdown` switch to tell the script not to restart the Plex Media Server process. The script will not run if the Plex Media Server is not active. To execute the script when Plex Media Server is not running, use the `Inactive` switch, but make sure you know what you are doing. 

### Plex Windows Registry key
To make sure PlexBackup saves and restores the right registry key, run it under the same account as Plex Media Server runs. The registry key will be backed up every time a backup job runs. If the backup folder does not contain the backup registry key file, the Plex registry key will not be imported on a restore.

### Script execution
You must launch PlexBackup _as administrator_ while being logged in under the same account your Plex Media Server runs.

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

This will allow running unsigned scripts that you write on your local computer and signed scripts downloaded from the Internet (okay, this is not a signed script, but if you copy it locally, make a non-destructive change--e.g. add a space character, remove the space character, and save the file--it should work). For additional information, see [Running Scripts](https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)) at Microsoft TechNet Library.

### Runtime parameters
The default value of the PlexBackup script's runtime parameters are defined in code, but you can override some of them via command-line arguments or config file settings.

### Config file
Config file is optional. The default config file must be named after the PlexBackup script with the `.json` extension, such as `PlexBackup.ps1.json`. If the file with this name does not exist in the backup script's folder, PlexBackup will not care. You can also specify a custom config file name (or more accurately, path) via the `ConfigFile` command-line argument ([see sample](PlexBackup.ps1.json)).

A config file must use [JSON formatting](https://www.json.org/), such as:

```JavaScript
{
    "_meta": {
        "version": "1.0",
        "strictMode": false,
        "description": "Sample configuration settings for PlexBackup.ps1."
    },
    "Mode": { "value": null },
    "Type": { "value": null },
    "PlexAppDataDir": { "value": null },
    "BackupRootDir": { "value": "\\\\MYNAS\\PlexBackup" },
    "BackupDirPath": { "value": null },
    "TempZipFileDir": { "hasValue": true, "value": null },
    "PlexRegKey": { "value": null },
    "ExcludePlexAppDataDirs": { "value": null },
    "SpecialPlexAppDataSubDirs": { "value": null },
    "PlexServiceNameMatchString": { "value": "^Plex" },
    "PlexServerExeFileName": { "value": "Plex Media Server.exe" },
    "PlexServerExePath": { "value": null },
    "RetainBackups": { "value": null },
    "Robocopy": { "value": false },
    "Retries": { "value": null },
    "RetryWaitSec": { "value": null },
    "Log": { "value": true },
    "LogAppend": { "value": null },
    "LogFile": { "value": null },
    "ErrorLog": { "value": true  },
    "ErrorLogAppend": { "value": null  },
    "ErrorLogFile": { "value": null },
    "Shutdown": { "value": null },
    "Inactive": { "value": null },
    "Force": { "value": null },
    "SendMail": { "value": false },
    "From": { "value": null },
    "To": { "value": null },
    "SmtpServer": { "value": "smtp.gmail.com" },
    "Port": { "value": 587 },
    "UseSsl": { "value": true },
    "CredentialFile": { "value": null },
    "PromptForCredential": { "value": true },
    "SaveCredential": { "value": true },
    "Anonymous": { "value": null },
    "SendLogFile": { "value": true },
    "ArchiverPath": { "value": null }
}
```
The `_meta` element describes the file and the file structure. It does not include any configuration settings. The important attributes  of the `_meta` element are:

- `version`: can be used to handle future file schema changes, and
- `strictMode`: when set to `true` every config setting that needs to be used must have the `hasValue` attribute set to `true`; if the `strictMode` element is missing or if its value is set to `false`, every config setting that gets validated by the PowerShell's `if` statement will be used.

You may notice that the provided [sample config file](PlexBackup.ps1.SAMPLE.json) looks a bit more complex than the example above. The sample adds a few metadata (`_meta`) elements to make it easier for you to pick from the supported ranges or sets of values (the `_meta` elements serve only informational purposes). The sample also includes a couple of `hasValue` flags. When set to `true`, the `hasValue` flag indicates that the corresponding setting must be used even if its values contains an empty string, null, or false (by default, these values are ignored).

Make sure you use proper JSON formatting (escape characters, etc) when defining the config values (e.g. you must escape each backslash characters with another backslash).

### Logging
Use the `Log` switch to write operation progress and informational messages to a log file. By default, the log file will be created in the backup folder. The default log file name reflects the name of the script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file path via the `LogFile` argument. By default, PlexBackup deletes an old log file (if one already exists), but if you specify the `LogAppend` switch, it will append new log messages to the existing log file.

### Error log
Use the `ErrorLog` switch to write error messages to a dedicated error log file. By default, the error log file will be created in the backup folder. The default error log file name reflects the name of the script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`. You can specify a custom error log file path via the `ErrorLogFile` argument. By default, PlexBackup deletes an old error log file (if one already exists), but if you specify the `ErrorLogAppend` switch, it will append new error messages to the existing error log file. If no errors occur, the error log file will not be created.

### Backup snapshots
Every time you run a new backup job, the script will create a backup snapshot folder. The name of the folder will reflect the timestamp of when the script started. Use the `Keep` switch to specify how many backup snapshots you want to keep: `0` (keep all previously created backups), `1` (keep the current backup snapshot only), `2` (keep the current backup snapshot and one before it), `3` (keep the current backup snapshot and two most recent snapshots), and so on. The default value is `3`.

### Backup version
When backing up data, PlexBackup records the version of Plex Media Server. If you try to restore a backup on a system with a different version of Plex Media Server, the operation will fail. To to force the operation over a version mismatch, use the `Force` parameter, but be aware that it may pose risks. Keep in mind that if you execute PlexBackup with the Plex Media Server process not running, version information will not be saved or checked during the backup or restore operations.

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
When sending email notifications, Plex backup will need to know how to connect to the SMTP server. You can specify the server via the `SmtpServer` parameter, such as: `-SmtpServer smtp.gmail.com `. If the server is using a non-default SMTP port, use the `Port` parameter to specify the port, such as; `-Port 587`. If you want your message to be sent over encrypted (SSL) channel, set the `UseSsl` switch. 

#### SMTP credentials
If your SMTP server does not require explicit authentication, use the `Anonymous` switch to tell PlexBackup to ignore explicit credentials; otherwise, you can ask the script to prompt you for credentials by setting the `PromptForCredentials` switch. If you want these credentials saved in a file (with password encrypted using the computer- and user-specific key) so you do not need to enter them every time the script runs, use the `SaveCredentials` switch. You can specify the path to the credential file via the `CredentialFile` parameters but if you don't, the script will try to use the default file named after the running script with the `.xml` extension, such as `PlexBackup.ps1.xml`. You can also generate the credential file in advance by running the following PowerShell command:

```PowerShell
Get-Credential | Export-CliXml -Path "PathToFile.xml"
```

IMPORTANT: Most public providers, such as Gmail, Yahoo, Hotmail, and so on, have special requirements that you need to meet before you can use their SMTP servers to send email. For example, to use Gmail's SMTP server, you need to do the following: 

(a) If you have two-factor authentication or, as Google calls it _two-step verification_, enabled, you cannot use your own password, so you need to generate an application password and use it along with your Gmail email address (see [Sign in using App Passwords](https://support.google.com/mail/answer/185833?hl=en)).

(b) If you are not using two-factor authentication, you can use your own password, but may need to enable less secure application access in your account settings (see [Let less secure apps access your account](https://support.google.com/accounts/answer/6010255?hl=en)).

For additional information or if you run into any issues, check support articles covering your provider.

#### Addresses
By defaul, PlexBackup will use the username provided via the SMTP credentials as both the `To` and `From` addresses, but you can set them explicitly via the `To` and `From` parameters. If the `To` parameter is not specified, the recepient's address will be the same as the sender's.

## Dependencies

PlexBackup requires on the following modules:

- [ScriptVersion](https://www.powershellgallery.com/packages/ScriptVersion)
- [ConfigFile](https://www.powershellgallery.com/packages/ConfigFile)

To verify that the modules get installed, run the script manually. You may be [prompted](https://docs.microsoft.com/en-us/powershell/gallery/how-to/getting-support/bootstrapping-nuget) to update the [NuGet](https://www.nuget.org/downloads) version (or you cab do it yourself in advance).

## See also

- [Getting started](GETTING%20STARTED.md)
- [Scheduled Plex backup](SCHEDULED%20PLEX%20BACKUP.md)
- [Frequently asked questions (FAQs)](FAQs.md)

## Syntax
```PowerShell
.\PlexBackup.ps1 `
    [[-Mode <String>] | -Backup | -Continue | -Update | -Restore] `
    [[-Type <String>] | -SevenZip | -Robocopy ] `
    [-ConfigFile <String>] `
    [-PlexAppDataDir <String>] `
    [-BackupRootDir <String>] `
    [-BackupDirPath <String>] `
    [-TempZipFileDir <String>] `
    [-Keep <Int32>] `
    [-Retries <Int32>] `
    [-RetryWaitSec <Int32>] `
    [-Log | -L] `
    [-LogAppend] `
    [-LogFile <String>] `
    [-ErrorLog] `
    [-ErrorLogAppend] `
    [-ErrorLogFile <String>] `
    [-Quiet | -Q] `
    [-Shutdown] `
    [-Inactive] `
    [-Force] `
    [-SendMail <String>] `
    [-From <String>] `
    [-To <String>] `
    [-SmtpServer <String>] `
    [-Port <Int32>] `
    [-UseSsl] `
    [-CredentialFile <String>] `
    [-PromptForCredential] `
    [-SaveCredential] `
    [-Anonymous] `
    [-SendLogFile <String>] `
    [-NoLogo] `
    [-Cls]
    [<CommonParameters>]
```
### Arguments

`-Mode`
    
Specifies the mode of operation: `Backup` (default), `Continue`, or `Restore`. Alternatively, you can specify one of the shortcut switches: `-Backup`, `-Continue`, or `-Restore`. Keep in mind that the `Mode` parameter and the shortcut switches are mutually exclusive (i.e. you can use at most one).

`-Type`
    
Specifies the the non-default backup type: `7zip` or `Robocopy`. Alternatively, you can specify a shortcut switch: `-SevenZip` or `-Robocopy`. Keep in mind that the `Type` parameter and the shortcut switches are mutually exclusive (i.e. you can use at most one). If neither the `-Type` nor any of the corresponding shortcut switches are specified, the default Windows compression will be used.

`-ConfigFile`
    
Path to the optional custom config file (default: `.\PlexBackup.ps1.json`).

`-PlexAppDataDir`

Location of the Plex Media Server application data folder (default: `%localappdata%\Plex Media Server`).

`-BackupRootDir`

Path to the root of the backup folder (backup will be created under a subfolder reflecting the timestamp of the backup job). If not specified, the script folder will be used.

`-BackupDirPath`

When running the script in the `Restore` mode, this parameter can holds the path to the backup folder (by default, the subfolder with the most recent timestamp in the name in the backup root folder identified by the `BackupRootDir` parameter will be used).

`-TempZipFileDir`

Temporary folder used to stage the archiving job (the default value is the standard Windows `TEMP` folder). To bypass the staging step, set this parameter to `null` or empty string.

`-Keep`

Number of old backup snapshots to keep: `0` (keep all previously created backups), `1` (keep the current backup snapshot only), `2` (keep the current backup snapshot and one before it), `3` (keep the current backup snapshot and two most recent snapshots), and so on. The default value is `3`.

`-Retries`

The number of retries on failed copy operations that corresponds to the Robocopy `/R` switch (default: 5). Only needed when the `Robocopy` switch is set.

`-RetryWaitSec`

Specifies the wait time between retries in seconds that corresponds to the Robocopy `/W` switch (default: 10). Only needed when the `Robocopy` switch is set.

`-Log`, `-L`

Set this switch to write informational messages to a log file (in addition to the PowerShell console). The default log file will be created in the backup folder and will be named after this script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file via the `LogFile` parameters.

`-LogFile`

Defines a custom log file path. When this parameter is set to a non-null and non-empty value, the `-Log` switch can be omitted.

`-LogAppend`

Set this switch to appended log entries to the existing log file if one already exists (by default, the old log file will be overwritten).

`-ErrorLog`

Set this switch to write error messages to an error log file (in addition to the PowerShell console). The default error log file will be created in the backup folder and will be named after this script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`. You can specify a custom log file via the `ErrorLogFile` parameters.

`-ErrorLogFile`

Defines a custom error log file path. When this parameter is set to a non-null and non-empty value, the `-ErrorLog` switch can be omitted.

`-ErrorLogAppend`

Set this switch to appended error log entries to the existing error log file if one already exists (by default, the old error log file will be overwritten).

`-Quiet`, `-Q`

Set this switch to suppress all log entries sent to the PowerShell console.

`-Shutdown`

Set this switch to not start the Plex Media Server process at the end of the operation. This could be handy for restore operations, so you can double check that all is good before launching Plex Media Server.

`-Inactive`

Set this switch to allow the script to run even when Plex Media Server process is inactive.

`-Force`

Set this switch to allow the restore operation to complete even when the script determines that there is a discrepancy between the current version of Plex Media Server and the version of Plex Media Server instance that was running when the backup was made.

`-SendMail`

Indicates in which case the script must send an email notification about the result of the operation: `Never` (default),
`Always`, `OnError` (for any operation), `OnSuccess` (for any operation), `OnBackup` (for both the `Backup` and `Continue` modes on either error or success), `OnBackupError`, `OnBackupSuccess`, `OnRestore` (on either error or success), `OnRestoreError`, and `OnRestoreSuccess`.

`-From`

Specifies the email address when email notification sender. If this value is not provided, the username from the credentials saved in the credentials file or entered at the credentials prompt will be used. If the `From` address cannot be determined, the notification will not be sent.

`-To`

Specifies the email address of the email recipient. If this value is not provided, the addressed defined in the `To` parameter will be used.

`-SmtpServer`

Defines the SMTP server host. If not specified, the notification will not be sent.

`-Port`

Specifies an alternative port on the SMTP server. Default: `0` (zero, i.e. the default port 25 will be used).

`-UseSsl`

Tells the script to use the Secure Sockets Layer (SSL) protocol when connecting to the SMTP server. By default, SSL is not used.

`-CredentialFile`

Path to the file holding username and encrypted password of the account that has permission to send mail via the SMTP server.

`-PromptForCredential`, `-Prompt`

Tells the script to prompt user for SMTP server credentials (when they are not specified in the credential file).

`-SaveCredential`, `-Save`

Tells the script to save the SMTP server credentials in the credential file.

`-Anonymous`

Tells the script to not use credentials when sending email notifications.

`-SendLogFile`

Indicates in which case the script must send an attachment along with th email
notification. Values: `Never` (default), `OnError`, `OnSuccess`, `Always`.

`-NoLogo`

Supresses the version and copyright message normally displayed in the beginning of the script run.

`-ClearScreen`, `-Cls`

Clears the console screen in the beginning of the script run.

`<CommonParameters>`
    
Common PowerShell parameters (the script is not using these explicitly).

## Returns

To check whether the backup script executed successfully or encountered an error, check the value of the `$LASTEXITCODE` variable: `0` (zero) indicates success, while any positive number indicates an error. Exit code of `1` implies that the error occurred during the backup or the restore operation. Exit codes higher than `1` indicate that a problem occurred before the script launched a backup or a restore job. You should not need this, but just in case, here is the list of currently supported exit codes:

- `0` : success
- `1` : error during backup or restore operation
- `2` : error processing config file
- `3` : problem determining or setting backup folder
- `4` : problem with log file(s)
- `5` : cannot determine path to PMS executable
- `6` : cannot read Plex Windows services
- `7` : cannot stop Plex Windows services
- `8` : cannot stop PMS executable file
- `9` : path to 7-zip command-line tool is undefined or does not exist
- `10`: version mismatch between backup and current Plex Media Server instance
- `11`: cannot install or import a module

## Examples

The following examples assume that the the default settings are used for the unspecified script arguments.

### Example 1
```PowerShell
PlexBackup.ps1
```
Backs up Plex application data to the default backup location using the default Windows compression.

### Example 2
```PowerShell
PlexBackup.ps1 -ConfigFile "C:\Scripts\PlexBackup.ps1.ROBOCOPY.json
```
Runs the script with the non-default settings specified in the custom config file.

### Example 3
```PowerShell
PlexBackup.ps1 -Log -ErrorLog -Keep 5
```
Backs up Plex application data to the default backup location using file and folder compression. Writes progress to the default log file. Writes error messages to the default error log file. Keeps current and four previous backup snapshots (total of five).

### Example 4
```PowerShell
PlexBackup.ps1 -Type Robocopy
PlexBackup.ps1 -Robocopy
```
Creates a mirror copy of the Plex application data (minus the non-essential folders) in the default backup location using the Robocopy command.

### Example 5
```PowerShell
PlexBackup.ps1 -Type 7zip
PlexBackup.ps1 -SevenZip
```
Backs up Plex application data to the default backup location using the 7-zip command-line tool.

### Example 6
```PowerShell
PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
```
Backs up Plex application data to the specified backup location on a network share using file and folder compression.

### Example 7
```PowerShell
PlexBackup.ps1 -Mode Continue
PlexBackup.ps1 -Continue
```
Continues the last backup process (using file and folder compression) where it left off.

### Example 8
```PowerShell
PlexBackup.ps1 -Continue -Robocopy
```
Reruns the last backup process using a mirror copy.

### Example 9
```PowerShell
PlexBackup.ps1 -Mode Restore
PlexBackup.ps1 -Restore
```
Restores Plex application data from the latest backup from the default folder holding compressed data.

### Example 10
```PowerShell
PlexBackup.ps1 -Restore -Robocopy
```
Restores Plex application data from the latest backup in the default folder holding a mirror copy of the Plex application data folder.

### Example 11
```PowerShell
PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MYNAS\PlexBackup\20190101183015"
```
Restores Plex application data from the specified backup folder holding compressed data on a remote share.

### Example 12
```PowerShell
PlexBackup.ps1 -SendMail Always -UseSsl -Prompt -Save -SendLogFile OnError -SmtpServer smtp.gmail.com -Port 587
```
Runs a backup job and sends an email notification over an SSL channel. If the backup operation fails, the log file will be attached to the email message. The sender's and the recipient's email addresses will determined from the username of the credential object. The credential object will be set either from the credential file or, if the file does not exist, via a user prompt (in the latter case, the credential object will be saved in the credential file with password encrypted using a user- and computer-specific key).

### Example 13
```PowerShell
Get-Help .\PlexBackup.ps1
```
Shows help information.
