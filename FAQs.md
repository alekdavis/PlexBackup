# Frequently asked questions (FAQs)

## Does PlexBackup.ps1 support incremental backup?

The point of incremental backup is to make it work faster than normal backup. Unfortunately, to apply an incremental update to a compressed archive, an archiver tool would first need to decompress the archive, make changes, and then compress it again, which in most cases, will be slower than normal backup. So what's the point? If you are using a `Robocopy` backup, you can apply incremental changes if you run it with the `Continue` switch (keep in mind that that the `Continue` switch works differently for compressed backups).

## Can PlexBackup.ps1 use WinRAR instead of the default Windows archiver or 7-zip?

No, adding another archiving program with its own set of command-line options and behavior would complicate the code without providing much in return. So far, 7-zip is free and works really well, so there is no reason to complicate things. 
***

_Submit your questions and the answers will be posted here._
