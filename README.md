# PlexBackup.ps1
This PowerShell script can back up and restore [Plex](https://www.plex.tv/) application data files on a Windows system.

## Introduction
Plex does not offer a meaningful backup feature. Yes, it can back up a Plex database, but if you need to move your Plex instance to a different system or restore it after a hard drive crash, a single database backup file will be of little use. For a meaningful backup, in addition to the Plex database, you will need a copy of the Plex Windows registry key and tens (or hundreds) of thousands of Plex application data files. Keep in mind that backing up gigabytes of data files may take a long time, especially when they are copied remotely, such as to a NAS share. And you must keep the Plex Media Server stopped while the backup job is running (otherwise, it can corrupt the data). In the other words, a meaningful Plex backup is a challenge to which I could not find a good solution, so I decided to build my own. Ladies and gentlemen, meet PlexBackup.ps1.

## Overview
PlexBackup.ps1 (or, briefly, _PlexBackup_) is a PowerShell script that can back up and restore a Plex instance on a Windows system. The script backs up the Plex database, Windows registry key, and app data folders essential for the Plex operations (it ignores the non-essential files, such as logs or crash reports). And it makes sure that Plex is not running when the backup job is active (which may take hours). And it can send mail, too.

IMPORTANT: The script will not back up media (video, audio, images) or Plex program files. You must use different backup techniques for those. For example, you can keep your media files on a RAID 5 disk array. And you don't really need to back up Plex program files, since you can always download them. But for everything else, PlexBackup is your guy.

### Modes of operation
PlexBackup can run in three modes (specified by the `Mode` switch):

- _Backup_: the default mode that starts a new backup job.
- _Continue_: resumes an incomplete backup job.
- _Restore_: restores Plex application data from a backup.

In all cases, before performing a backup or restore operation, PlexBackup will stop all Plex Windows services along with the Plex Media Server process. After the script completes the operation, it will restart them. You can use the `Shutdown` switch to tell the script not to restart the Plex Media Server process.

### Types of backup
The script can perform two types of backup:

#### Compressed
By default, the script compresses every essential folder under the root of the Plex application data folder (_Plex Media Server_) and saves the compressed data as separate ZIP files. For better efficiency (in case the backup folder is remote, such as on a NAS share), it first compresses the data in a temporary local file and then copies the compressed file to the backup folder (you can compress the data and save the ZIP files directly to the backup folder by setting the value of the `TempZipFileDir` parameter to null or empty string). There is a problem with PowerShell's compression routine that fails to process files and folders with paths that are longer than 260 characters. If you get this error, use the `SpecialPlexAppDataSubDirs` parameter (in code or config file) to specify the folders that are too long (or parents of the subfolders or files that are too long) and PlexBackup will copy them as-is without using compression (by default, the following application data folder is not compressed: `Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated`).

#### Robocopy
If you run PlexBackup with the `Robocopy` switch, instead of archiving, the script will create a mirror of the Plex application data folder (minus the non-essential folders) using the Robocopy command. 

You may want to play with either option to see which one works better for you.

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
Config file is optional. The default config file must be named after the PlexBackup script with the `.json` extension, such as `PlexBackup.ps1.json`. If the file with this name does not exist in the backup script's folder, PlexBackup will not care. You can also specify a custom config file name (or more accurately, path) via the `ConfigFile` command-line argument.

A config file must use JSON formatting, such as:

```JavaScript
{
    "_meta": {
        "version": "1.0",
        "strictMode": false,
        "description": "Sample configuration settings for PlexBackup.ps1."
    },
    "Mode": { "value": "" },
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
    "SendLogFile": { "value": true }
}
```
The `_meta` element describes the file and the file structure. It does not include any configuration settings. The important attributes  of the `_meta` element are:

- _version_: can be used to handle future file schema changes, and
- _strictMode_: when set to `true` every config setting that needs to be used must have the `hasValue` attribute set to `true`; if the _strictMode_ element is missing or if its value is set to `false`, every config setting that gets validated by the PowerShell's `if` statement will be used.

Make sure you use proper JSON formatting (escape characters, etc) when defining the config values (e.g. you must escape aeach backslash characters with another backslash).

### Logging
Use the `Log` switch to write operation progress and informational messages to a log file. By default, the log file will be created in the backup folder. The default log file name reflects the name of the script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file path via the `LogFile` argument. By default, PlexBackup deletes an old log file (if one already exists), but if you specify the `LogAppend` switch, it will append new log messages to the existing log file.

### Error log
Use the `ErrorLog` switch to write error messages to a dedicated error log file. By default, the error log file will be created in the backup folder. The default error log file name reflects the name of the script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`. You can specify a custom error log file path via the `ErrorLogFile` argument. By default, PlexBackup deletes an old error log file (if one already exists), but if you specify the `ErrorLogAppend` switch, it will append new error messages to the existing error log file. If no errors occur, the error log file will not be created.

### Backup snapshots
Every time you run a new backup job, the script will create a backup snapshot folder. The name of the folder will reflect the timestamp of when the script started. Use the `Keep` switch to specify how many backup snapshots you want to keep: _0_ (keep all previously created backups), _1_ (keep the current backup snapshot only), _2_ (keep the current backup snapshot and one before it), _3_ (keep the current backup snapshot and two most recent snapshots), and so on. The default value is _3_.

### Email notification
Use the `Sendmail` parameter to let PlexBackup know whether or when you want to receive email notifications about the backup job completion:

- _Never_: by default, email notifications will not be sent
- _Always_: notifications will be sent always
- _OnError_: receive notifications if an error occurs during any operation
- _OnSuccess_: receive notifications only if an operation was successful
- _OnBackup_: receive notifications about new and resumed backup operations on error or success
- _OnBackupError_: receive notifications about new and resumed backup operations on error only
- _OnBackupSuccess_: receive notifications about new and resumed backup operations on success only
- _OnRestore_: receive notifications about new and resumed backup operations on error or success
- _OnRestoreError_: receive notifications about failed restore operations only
- _OnRestoreSuccess_: receive notifications about failed restore operations only

To receive a copy of the log file along with the email notification, use the _SendLogFile_ parameter with one of the following values:

- _Never_: by default, the log file will not be sent as an email message attachment
- _Always_: the log file will be sent always
- _OnSuccess_: only receive the copy of the log file if an error occurs
- _OnSuccess: only receive the copy of the log file if no errors occur

#### SMTP server
When sending email notifications, Plex backup will need to know how to connect to the SMTP server. You can specify the server via the `SmtpServer` parameter, such as: `-SmtpServer smtp.gmail.com `. If the server is using a non-default SMTP port, use the ~Port` parameter to specify the port, such as; `-Port 587`. If you want your message to be sent over encrypted (SSL) channel, set the `UseSsl` switch. 

#### SMTP credentials
If your SMTP server does not require explicit authentication, use the `Anonymous` switch to tell PlexBackup to ignore explicit credentials; otherwise, you can ask the script to prompt you for credentials by setting the `PromptForCredentials` switch. If you want these credentials saved in a file (with password encrypted using the computer- and user-specific key) so you do not need to enter them every time the script runs, use the `SaveCredentials` switch. You can specify the path to the credential file via the `CredentialFile` parameters but if you don't, the script will try to use the default file named after the running script with the `.xml` extension, such as `PlexBackup.psq.xml`. You can also generate the credential file in advance by running the following PowerShell command:

```PowerShell
Get-Credential | Export-CliXml -Path "PathToFile.xml"
```

IMPORTANT: Most public providers, such as Gmail, Yahoo, Hotmail, and so on, have special requirements that you need to meet before you can use their SMTP servers to send email. For example, to use Gmail's SMTP server, you need to do the following: 

(a) If you have two-factor authentication, or, as Google calls it _two-step verification_, enabled, you cannot use your own password, so you need to generate an application password and use it along with your Gmail email address (see [Sign in using App Passwords](https://support.google.com/mail/answer/185833?hl=en)).
(b) If you are not using 2FA, you can use your own password, but may need to enable less secure application access in your account settings (see [Let less secure apps access your account](https://support.google.com/accounts/answer/6010255?hl=en)).

For additional information or if you run into any issues, check support articles covering your provider.

#### Addresses
By defaul, PlexBackup will use the username provided via the SMTP credentials as both the _To_ and _From_ addresses, but you can set them explicitly via the `To` and `From` parameters. If the `To` parameter is not specified, the recepient's address will be the same as the sender's.

## Syntax
```PowerShell
.\PlexBackup.ps1 `
    [[-Mode] <String>] `
    [[-ConfigFile] <String>] `
    [[-PlexAppDataDir] <String>] `
    [[-BackupRootDir] <String>] `
    [[-BackupDirPath] <String>] `
    [[-TempZipFileDir] <String>] `
    [[-Keep <Int32>] `
    [-Robocopy] `
    [[-Retries] <Int32>] `
    [[-RetryWaitSec] <Int32>] `
    [-Log|-L] `
    [-LogAppend] `
    [[-LogFile] <String>] `
    [-ErrorLog] `
    [-ErrorLogAppend] `
    [[-ErrorLogFile] <String>] `
    [-Quiet|-Q] `
    [-Shutdown] `
    [[-SendMail] <String>] `
    [[-From] <String>] `
    [[-To] <String>] `
    [[-SmtpServer] <String>] `
    [[-Port] <Int32>] `
    [-UseSsl] `
    [[-CredentialFile] <String>] `
    [-PromptForCredential] `
    [-SaveCredential] `
    [-Anonymous] `
    [[-SendLogFile] <String>] `
    [<CommonParameters>]
```
### Arguments

_-Mode_
    
Specifies the mode of operation: _Backup_ (default), _Continue_, or _Restore_.

_-ConfigFile_
    
Path to the optional custom config file (default: _.\PlexBackup.ps1.json_).

_-PlexAppDataDir_

Location of the Plex Media Server application data folder (default: _%localappdata%\Plex Media Server).

_-BackupRootDir_

Path to the root of the backup folder (backup will be created under a subfolder reflecting the timestamp of the backup job).

_-BackupDirPath_

When running the script in the _Restore_ mode, this parameter can holds the path to the backup folder (by default, the subfolder with the most recent timestamp in the name in the backup root folder identified by the _BackupRootDir_ parameter will be used).

_-TempZipFileDir_

Temporary folder used to stage the archiving job (the default value is the standard Windows _TEMP_ folder). To bypass the staging step, set this parameter to `null` or empty string.

_-Keep_

Number of old backup snapshots to keep: _0_ (keep all previously created backups), _1_ (keep the current backup snapshot only), _2_ (keep the current backup snapshot and one before it), _3_ (keep the current backup snapshot and two most recent snapshots), and so on. The default value is _3_.

_-Robocopy_

Set this switch to create (or restore) Plex application data (from) a mirror copy using Robocopy.

_-Retries_

The number of retries on failed copy operations that corresponds to the Robocopy `_/R_` switch (default: 5). Only needed when the _Robocopy_ switch is set.

_-RetryWaitSec_

Specifies the wait time between retries in seconds that corresponds to the Robocopy `_/W_` switch (default: 10). Only needed when the _Robocopy_ switch is set.

_-Log, -L_

Set this switch to write informational messages to a log file (in addition to the PowerShell console). The default log file will be created in the backup folder and will be named after this script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file via the _LogFile_ parameters.

_-LogFile_

Defines a custom log file path. When this parameter is set to a non-null and non-empty value, the `-Log` switch can be omitted.

_-LogAppend_

Set this switch to appended log entries to the existing log file if one already exists (by default, the old log file will be overwritten).

_-ErrorLog_

Set this switch to write error messages to an error log file (in addition to the PowerShell console). The default error log file will be created in the backup folder and will be named after this script with the `.err.log` extension, such as `PlexBackup.ps1.err.log`. You can specify a custom log file via the _ErrorLogFile_ parameters.

_-ErrorLogFile_

Defines a custom error log file path. When this parameter is set to a non-null and non-empty value, the `-ErrorLog` switch can be omitted.

_-ErrorLogAppend_

Set this switch to appended error log entries to the existing error log file if one already exists (by default, the old error log file will be overwritten).

_-Quiet, -Q_

Set this switch to suppress all log entries sent to the PowerShell console.

_-Shutdown_

Set this switch to not start the Plex Media Server process at the end of the operation. This could be handy for restore operations, so you can double check that all is good before launching Plex Media Server.

_<CommonParameters>_
    
Common PowerShell parameters (the script is not using these explicitly).

## Examples

### Example
```PowerShell
PlexBackup.ps1
```
Backs up Plex application data to the default backup location using file and folder compression.

### Example
```PowerShell
PlexBackup.ps1 -ConfigFile "C:\Scripts\PlexBackup.ps1.ROBOCOPY.json
```
Runs the script with the non-default settings specified in the custom config file.

### Example
```PowerShell
PlexBackup.ps1 -Log -ErrorLog -Keep 5
```
Backs up Plex application data to the default backup location using file and folder compression. Writes progress to the default log file. Writes error messages to the default error log file. Keeps current and four previous backup snapshots (total of five).

### Example
```PowerShell
PlexBackup.ps1 -Robocopy
```
Creates a mirror copy of the Plex application data (minus the non-essential folders) in the default backup location using the Robocopy command.

### Example
```PowerShell
PlexBackup.ps1 -BackupRootDir "\\MYNAS\Backup\Plex"
```
Backs up Plex application data to the specified backup location on a network share using file and folder compression.

### Example
```PowerShell
PlexBackup.ps1 -Mode "Continue"
```
Continues the last backup process (using file and folder compression) where it left off.

### Example
```PowerShell
PlexBackup.ps1 -Mode "Continue" -Robocopy
```
Reruns the last backup process using a mirror copy.

### Example
```PowerShell
PlexBackup.ps1 -Mode Restore
```
Restores Plex application data from the latest backup from the default folder holding compressed data.

### Example
```PowerShell
PlexBackup.ps1 -Mode Restore -Robocopy
```
Restores Plex application data from the latest backup in the default folder holding a mirror copy of the Plex application data folder.

### Example
```PowerShell
PlexBackup.ps1 -Mode Restore -BackupDirPath "\\MYNAS\PlexBackup\20190101183015"
```
Restores Plex application data from the specified backup folder holding compressed data on a remote share.

### Example
```PowerShell
PlexBackup.ps1 -SendMail Always -UseSsl -Prompt -Save -SendLogFile OnError -SmtpServer smtp.gmail.com -Port 587
```
Runs a backup job and sends an email notification over an SSL channel. If the backup operation fails, the log file will be attached to the email message. The sender's and the recipient's email addresses will determined from the username of the credential object. The credential object will be set either from the credential file or, if the file does not exist, via a user prompt (in the latter case, the credential object will be saved in the credential file with password encrypted using a user- and computer-specific key).

### Example
```PowerShell
Get-Help .\PlexBackup.ps1
```
Shows help information.
