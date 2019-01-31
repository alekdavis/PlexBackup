WORK IN PROGRESS...
# PlexBackup.ps1
This PowerShell script can back up and restore Plex application data files on a Windows system.

## Introduction
Plex does not offer a meaningful backup feature. Yes, it can back up a Plex database, but if you need to move your Plex instance to a different system or restore it after a hard drive crash, a single database backup file will be of little use. For a meaningful backup, in addition to the Plex database, you will need a copy of the Plex Windows registry key and tens (or hundreds) of thousands of Plex application data files. Keep in mind that backing up gigabytes of data files may take a long time, especially when they are copied remotely, such as to a NAS share. And you must keep the Plex Media Server stopped while the backup job is running (otherwise, it can corrupt the data). In the other words, a meaningful Plex backup is a challenge to which I could not find an good solution, so I decided to build my own. Ladies and gentlement, meet PlexBackup.ps1.

## Overview
PlexBackup.ps1 (or, briefly, _PlexBackup_) is a PowerShell script that can back up and restore a Plex instance on a Windows system. The script backs up the Plex database, Windows registy key, and app data folders essential for the Plex operation (it ignores the non-essential files, such as logs or crash reports). And it makes sure that Plex is not running when the backup job is active (which may take hours).

The script will not back up media (video, audio, images) or Plex program files. You must use different backup techniques for those. For example, you can keep your media files on a RAID 5 disk array and you can always download the Plex application from the Plex website, so the latter don't really need to be backed up. But for everything else, PlexBackup is your guy.

### Modes of operation
PlexBackup can run in three modes:

- _Backup_: starts a new backup job.
- _Continue_: resumes an interrupted backup job.
- _Restore_: restores Plex application data from an existing backup.

In all case, before performing the backup or restore operation, PlexBackup will stop the Plex Windows services and the Plex Media Server process. When the script completes the operation, it will restart the Plex Windows services and server process.

### Types of backup
The script can perform two types of backup. By default, it will compress every essential folder under the root of the Plex application data folder (_Plex Media Server_) and save the compressed data as a separate ZIP file. For better efficiency (assuming that the backup folder is remote), it first compresses the data in a temporary local file and then copy it to the backup folder. You can compress the data and save the ZIP files directly to the backup folder, though. Alternatively, PlexBackup can create a mirror of the Plex application data folder (minus the non-essential folders) using the Robocopy command. You may want to play with either option to see which one works better for you.

### Script execution
You must run PlexBackup _as administrator_. And if you haven't done this before, you may need to adjust the PowerShell script execution policy to allow scripts to run. To check the execution policy, run the following command from the PowerShell prompt:

```PowerShell
Get-ExecutionPolicy
```
If the execution policy does not allow running scripts, do the following:

(1) Start Windows PowerShell with the "Run as Administrator" option. 
(2) Run the following command: 

```PowerShell
Set-ExecutionPolicy RemoteSigned
```

This will allow running unsigned scripts that you write on your local computer and signed scripts downloaded from the Internet (okay, this is not a signed script, but if you copy it locally, it should work). See also [Running Scripts](https://docs.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)) at Microsoft TechNet Library.

### Runtime parameters
The PlexBackup script's run-time parameters are defined in code, can be passed via command-line arguments, or can be specified via a config file. Command-line arguments overrride the hard-coded script defaults, and the non-null config file settings override the command-line arguments.

### Config file
A config file is optional. It must use JSON formatting, such as:

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
Keep in mind that only settings listed in the sample above can be specified in a config file. Also, the script will ignore the config file values set to `null`. 

The default config file must be named under the PlexBackup script with the `.json` extension, such as `PlexBackup.ps1.json`. If the file with this name does not exist in the backup script's folder, PlexBackup will not care. You can also specify a custom script name (or more accurately, path) via the `ConfigFile` command-line argument.

### Logging
Use the `Log` switch to log progress in a log file. By default, the log file will be created in the backup folder with the name reflecting the name of the script with the `.log` extension, such as `PlexBackup.ps1.log`. You can specify a custom log file path via the `LogFile` argument. By default, PlexBackup deletes an olog file, but if you specify the `LogAppend` switch, it will append log messages to the existing log file, if it finds one.

### 

## Syntax

```PowerShell
.\PlexBackup.ps1 [[-Mode] <String>] [[-ConfigFile] <String>] [[-PlexAppDataDir] <String>] [[-BackupRootDir] <String>] [[-BackupDirPath] <String>] [[-TempZipFileDir] <String>] [-Robocopy] [[-Retries] <Int32>] [[-RetryWaitSec] <Int32>] [-Log] [-LogAppend] [[-LogFile] <String>] [-Quiet] [-Shutdown] [<CommonParameters>]
```
### Arguments

__Mode__
Specifies the mode of operation: _Backup_ (default), _Continue_, or _Restore_.

__ConfigFile__
Path to the optional custom config file (default: _.\PlexBackup.ps1.json_).

__PlexAppDataDir__
Location of the Plex Media Server application data folder (default: _%appdata%\..\Local\Plex Media Server).

__BackupRootDir__
Path to the root of the backup folder (backup will be created under a subfolder reflecting the timestamp of the backup job).

__BackupDirPath__
When running the script in the _Restore_ mode, this parameter can holds the path to the backup folder (by default, the subfolder with the most recent timestamp in the name in the backup root folder identified by the _BackupRootDir_ parameter will be used).

__TempZipFileDir__
Temporary folder used to stage the archiving job (the default value is the standard Windows _TEMP_ folder). To bypass the staging step, set this parameter to null or empty string.

__Robocopy__
Set this switch to use a mirror copy backup (using Robocopy) instead of file and folder compression.

__Retries__
The number of retries on failed copy operations that corresponds to the Robocopy _/R_ switch (default: 2). Only needed when the _Robocopy_ switch is set.

__RetryWaitSec__
Specifies the wait time between retries in seconds that corresponds to the Robocopy _/W_ switch (default: 5). Only needed when the _Robocopy_ switch is set.

__Log__
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

## Examples
