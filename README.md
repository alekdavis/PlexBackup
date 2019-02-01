# PlexBackup.ps1
This PowerShell script can back up and restore Plex application data files on a Windows system.

## Introduction
Plex does not offer a meaningful backup feature. Yes, it can back up a Plex database, but if you need to move your Plex instance to a different system or restore it after a hard drive crash, a single database backup file will be of little use. For a meaningful backup, in addition to the Plex database, you will need a copy of the Plex Windows registry key and tens (or hundreds) of thousands of Plex application data files. Keep in mind that backing up gigabytes of data files may take a long time, especially when they are copied remotely, such as to a NAS share. And you must keep the Plex Media Server stopped while the backup job is running (otherwise, it can corrupt the data). In the other words, a meaningful Plex backup is a challenge to which I could not find a good solution, so I decided to build my own. Ladies and gentlemen, meet PlexBackup.ps1.

## Overview
PlexBackup.ps1 (or, briefly, _PlexBackup_) is a PowerShell script that can back up and restore a Plex instance on a Windows system. The script backs up the Plex database, Windows registry key, and app data folders essential for the Plex operations (it ignores the non-essential files, such as logs or crash reports). And it makes sure that Plex is not running when the backup job is active (which may take hours).

The script will not back up media (video, audio, images) or Plex program files. You must use different backup techniques for those. For example, you can keep your media files on a RAID 5 disk array. And you don't really need to back up Plex program files, since you can always download them. But for everything else, PlexBackup is your guy.

### Modes of operation
PlexBackup can run in three modes (specified by the `Mode` switch):

- _Backup_: the default mode that starts a new backup job.
- _Continue_: resumes an incomplete backup job.
- _Restore_: restores Plex application data from a backup.

In all cases, before performing a backup or restore operation, PlexBackup will stop all Plex Windows services along with the Plex Media Server process. After the script completes the operation, it will restart them. You can use the `Shutdown` switch to tell the script not to restart the Plex Media Server process.

### Types of backup
The script can perform two types of backup. 

#### Compressed backup
By default, it will compress every essential folder under the root of the Plex application data folder (_Plex Media Server_) and save the compressed data as separate ZIP files. For better efficiency (in case the backup folder is remote, such as on a NAS share), it first compresses the data in a temporary local file and then copies the compressed file to the backup folder (you can compress the data and save the ZIP files directly to the backup folder by setting the value of the `TempZipFileDir` parameter to null or empty string). There is a problem with PowerShell's compression routine that fails to process files and folders with paths that are longer than 260 characters. If you get this error, use the `SpecialPlexAppDataSubDirs` parameter (in code or config file) to specify the folders that are too long (or parents of the subfolders or files that are too long) and PlexBackup will copy them as-is without using compression (by default, the following application data folder is not compressed: `Plug-in Support\Data\com.plexapp.system\DataItems\Deactivated`).

#### Mirror backup
Alternatively, PlexBackup can create a mirror of the Plex application data folder (minus the non-essential folders) using the Robocopy command. 

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

This will allow running unsigned scripts that you write on your local computer and signed scripts downloaded from the Internet (okay, this is not a signed script, but if you copy it locally, it should work). For additional information, see [Running Scripts](https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)) at Microsoft TechNet Library.

### Runtime parameters
The default value of the PlexBackup script's runtime parameters are defined in code, but you can override some of them via command-line arguments or a config file settings.

### Config file
The config file is optional. It must use JSON formatting, such as:

```JavaScript
{
    "Mode": null,
    "PlexAppDataDir": null,
    "BackupRootDir": "\\\\MYNAS\\PlexBackup",
    "BackupDirPath": null,
    "TempZipFileDir": "",
    "PlexRegKey": null,
    "ExcludePlexAppDataDirs": null,
    "SpecialPlexAppDataSubDirs": null,
    "PlexServiceNameMatchString": "^Plex",
    "PlexServerExeFileName": "Plex Media Server.exe",
    "PlexServerExePath": null,
    "RetainBackups": null,
    "Robocopy": true,
    "Retries": null,
    "RetryWaitSec": null,
    "Log": true,
    "LogAppend": null,
    "LogFile": null,
    "Shutdown": null
}
```
Keep in mind that only settings listed in the sample above can be specified in the config file. Also, the script will ignore the config file values set to `null`. 

The default config file must be named after the PlexBackup script with the `.json` extension, such as `PlexBackup.ps1.json`. If the file with this name does not exist in the backup script's folder, PlexBackup will not care. You can also specify a custom script name (or more accurately, path) via the `ConfigFile` command-line argument.

### Logging
Use the `Log` switch to write operation progress and informational messages to a log file. By default, the log file will be created in the backup folder. The default log file name reflects the name of the script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file path via the `LogFile` argument. By default, PlexBackup deletes an old log file (if one already exists), but if you specify the `LogAppend` switch, it will append log messages to the existing log file.

### Bakup snapshots
Every time you run a new backup job, the script will create a backup snapshot folder. The name of the folder will reflect the timestamp of when the script started. Use the `RetainBackups` switch to specify how many backup snapshots you want to keep: _0_ (keep all previously created backups), _1_ (keep the current backup snapshot only), _2_ (keep the current backup snapshot and one before it), _3_ (keep the current backup snapshot and two most recent snapshots), and so on. The default value is _3_.

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
    [-Quiet|-Q] `
    [-Shutdown] `
    [<CommonParameters>]
```
### Arguments

_-Mode_
    
Specifies the mode of operation: _Backup_ (default), _Continue_, or _Restore_.

_-ConfigFile_
    
Path to the optional custom config file (default: _.\PlexBackup.ps1.json_).

_-PlexAppDataDir_

Location of the Plex Media Server application data folder (default: _%appdata%\..\Local\Plex Media Server).

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

_-Quiet, -Q_

Set this switch to suppress all log entries sent to the PowerShell console.

_-Shutdown_

Set this switch to not start the Plex Media Server process at the end of the operation. This could be handy for restore operations, so you can double check that all is good before launching Plex Media Server.

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
PlexBackup.ps1 -Log -Keep 5
```
Backs up Plex application data to the default backup location using file and folder compression. Writes progress to the default log file. Keeps current and four previous backup snapshots (total of five).

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
Get-Help .\PlexBackup.ps1
```
Shows help information.
