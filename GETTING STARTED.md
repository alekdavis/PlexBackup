# Getting started
To start your first Plex backup, follow these steps.

## Basic setup

For minimal backup functionality, do the following:

### Log in

Log on to Windows under the same account your Plex Media Server runs.

### Download files

To download the Plex backup files, either clone this repository or simply copy the following files:

- [PlexBackup.ps1](PlexBackup.ps1)
- [PlexBackup.ps1.SAMPLE.json](PlexBackup.ps1.SAMPLE.json)

If you choose to copy the files manually, make sure that your procedure does not corrupt characters (it can happen with special characters, like dashes, which may be converted to non-ASCII characters during the copy operation).

### Rename sample config file

Rename `PlexBackup.ps1.SAMPLE.json` file to `PlexBackup.ps1.json` and make sure it's located in the same folder as `PlexBackup.ps1`.

### Pick a backup folder

By default, PlexBackup.ps1 creates a backup folder in the same directory from which the script is running. Make sure you are not backing up Plex app data to the same drive (you should save backed up data on a separate local drive, if your computer has more than one, an external drive, such as a [NAS](https://en.wikipedia.org/wiki/Network-attached_storage) share, or an external USB hard drive). Make sure that the backup drive has enough space.

### Update config file settings

Open the `PlexBackup.ps1.json` file in a text editor, such as _Notepad_ and make sure the backup settings are correct. At the very least, set the location of the backup root folder (`BackupRootDir`). Remember to escape backslash characters (`\`) in the path with another backslash character, e.g. if your backup root folder points to the `\\MYNAS\Backup` share, it must be entered as `\\\\MYNAS\\Backup`. Save the config file.

### Make sure Plex Media Server is running

When performing a backup, we want to make sure that Plex installation is not corrupted (you would not want to make a backup of a non-functioning Plex instance, right?), so Plex Media Server must be running.

### Launch PowerShell

Launch PowerShell _as administrator_ (the backup script performs a few operations, such as stopping and starting services, that require elevated privileges).

### Run backup script

In the PowerShell prompt, switch to the Plex backup script folder and enter the following command:

```PowerShell
.\PlexBackup.ps1
```

If PowerShell does not allow you to launch scripts, [adjust the execution policy settings](README.md#script-execution) (you may also need to make a non-destructive change to the script to fool Windows into thinking that it is a local script and not a script downloaded from the Internet).

Once the script runs, monitor the output. If an errors occurs, try to understand the error message and correct the problem. If you get stuck, submit an [issue](../../issues).

## Advanced setup

Once you verify that Plex backup is working, you can adjust the settings to better serve your needs. You can set it up to receive [email notifications](README.md#email-notification), have it send you a log file upon completion, run it as a [scheduled task](SCHEDULED%20PLEX%20BACKUP.md), and do more.

## Restore

To restore Plex application data from a backup, make sure that you have a running Plex instance (e.g. a brand new Plex installation). Verify the config file (`PlexBackup.ps1.json`) settings (in a typical case, you do not need to make any changes to the config file since the script will pick up the latest backup snapshot from the backup root folder). Execute the following command:

```PowerShell
.\PlexBackup.ps1 -Restore
```

You may want to verify that the restore operation is successful before starting Plex Media Server, in which case, run the script with the `Shutdown` switch:

```PowerShell
.\PlexBackup.ps1 -Restore -Shutdown
```

Enjoy!
