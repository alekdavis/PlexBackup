# Scheduled Plex backup

Here is how you can set up the Plex backup job to run on a periodic schedule with the help of [Windows Task Scheduler](https://docs.microsoft.com/en-us/windows/desktop/taskschd/task-scheduler-start-page).

## Launch Windows Task Scheduler

Enter _Task Scheduler_ in the __Windows Search__ box and launch Task Scheduler.

## Create a new task

In Task Scheduler's __Actions__ panel, click __Create Task...__. You can do this in a number of ways, but in the end, your task should look similar to this one:

![Task Scheduler](https://user-images.githubusercontent.com/2113681/52493659-e50aa880-2b80-11e9-84b2-f3a2fdbd7112.PNG)

You can set the task properties in the new task creation wizard, or modify after creating the task (double-click the task to open its properties for editing).

When setting up the Plex backup scheduled task, please make sure that it runs:

- only when use is logged on (i.e. when Plex Media Server is running, unless you have it running as a Windows service)
- as the same account as you Plex Media Server process
- with highest privileges

The task __action__ (in the __Actions__ properties) must be:

`PowerShell.exe`

The program/script __arguments__ of the task action would be similar to:

`-WindowStyle Hidden -ExecutionPolicy Bypass "C:\PathToYourBackupScript\PlexBackup.ps1"`

The following screenshots are just for your reference. You may want to adjust them to fit your needs.

## General

![General](https://user-images.githubusercontent.com/2113681/52495321-2dc46080-2b85-11e9-8f27-194950df07da.PNG)

## Triggers 

![Triggers](https://user-images.githubusercontent.com/2113681/52493677-efc53d80-2b80-11e9-9918-98643313a70e.PNG)

### Trigger properties

![Trigger properties](https://user-images.githubusercontent.com/2113681/52493684-f3f15b00-2b80-11e9-8646-5f108ce4b954.PNG)

## Actions

![Actions](https://user-images.githubusercontent.com/2113681/52493692-f9e73c00-2b80-11e9-91f8-d3f438cb5c20.PNG)

### Action properties

![Action properties](https://user-images.githubusercontent.com/2113681/52499026-53566780-2b8f-11e9-8990-38eee6525340.PNG)

The program/script __arguments__ of the task action would be something like:

`-WindowStyle Hidden -ExecutionPolicy Bypass "C:\PathToYourBackupScript\PlexBackup.ps1"`

## Conditions

![Conditions](https://user-images.githubusercontent.com/2113681/52493716-023f7700-2b81-11e9-96a5-b673da4379f6.PNG)

## Settings

![Settings](https://user-images.githubusercontent.com/2113681/52493729-066b9480-2b81-11e9-8130-6965da7de755.PNG)
