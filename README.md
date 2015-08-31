# WinEBSbackups
This project contains a collection of scripts designed to facilitate the creation of and recovery from EBS volume snapshots for Windows-based EC2 instances. These utilities are based on the work done for the [LxEBSbackups](https://github.com/ferricoxide/LxEBSbackups) project. These utilities are implemented in Windows PowerShell. However, due to limitations with Windows-based filesystems, lack features like filesystem quiescing and implementation of consistency-bropup functionality.

When used as intended, these utilities allow for easy creation and maintenance of  - and recovery from - EBS snapshots for server instances running on AWS.  

## Backups Using EBS Snapshots
Backups are achieved by using the [SnapByCgroup.ps1] with the automated tasks scheduler. The automated tasks scheduler is used to automate the running of the SnapByCgroup tool to create EBS snapshots of hosted data at regular intervals.

Example System: 
* Windows Server 2012
* EBS Root Volume (on "C:\")
* EBS Data Volume (on "S:\")

### Pre-requisites
* Functioning Git client or web browser (git client preferred)
* Functional AWS CLI

### Procedure
1. Tag each of the EBS volumes to snap with a tag named "Consistency Group". Volumes that should be snapped as a set should be given the same "Consistency Group" value; volumes taht should be snapped separately from each other should be given differing values. 

    ~~~
key = Consistency Group #this is a required value, don't modify it
value = MyGroup01 #name this whatever you want, whatever volumes share this value will be snapped together
    ~~~

2. Retrieve the SnapByCgroup.ps1 tool. 

    ~~~
    1. Open a command shell (`powershell.exe` preferred)
    2. Navigate to where you want your tools to live
    3. Use your git client to copy down this repo (e.g., `git clone <url to git repo for WinEBSbackups>`
    ~~~

3. Test the script (from within PowerShell):

    ~~~
/PATH/TO/SnapByCgroup.ps1 MyGroup01
Snapping EBS volume: vol-55555555
Snapping EBS volume: vol-55555556
Tagging snapshot: snap-55555557
Tagging snapshot: snap-55555558
    ~~~

4. Create a automated schedulure task to create snapshots nightly at 1 AM


### Result
Looking in the AWS web console under EC2>Snapshots, you should now see a new snapshot for each EBS disk in the consistency group.  In this case:

Name | SnapshotID
---- | ----------
AutoBack (i-99999999) 2015-08-26 | snap-ffffffff
AutoBack (i-88888888) 2015-08-26 | snap-eeeeeeee

And every night a new set will be created.

But wait, these things are really going to start piling up.  Fear not, read on...

## Backup Snapshot Maintenance

The [maintenance script](README_MaintSnaps.sh.md) will comb through the snapshots for your instance and delete ones older than the number of days you specify.

But what if I have snapshots I created manually that I don't want deleted?  No problem, the script will only delete snapshots if the tags match those automatically set by the SnapByCgroup.sh script when run as a CRON job.  Your custom snapshots are safe.

### Prerequisites
* You completed the procedure above to create the backup snapshots

### Procedure

1. Set the how many days you want to retain snapshots in the [commonVars.env](README_commonVars.env.md) file.

2. Test the script

    ~~~
/root/LxEBSbackups/MaintSnaps.sh
Beginning stale snapshot cleanup (killing files older than 2015/08/19 @ 18:25)
    ~~~

4. Create a CRON job to delete old snapshots nightly at 5 AM

    ~~~
crontab -e
    ~~~
  
  Add this line:

    ~~~
0 05 * * * /root/LxEBSbackups/MaintSnaps.sh
    ~~~

### Result
IF there were any snapshots created by SnapByCgroup.sh run via CRON older than the number of days you set in step 1, then they should now be gone under EC2>Snapshots.  Every morning at 5 AM, older snaps will be deleted.

Note: This script will NOT delete snapshots created when running SnapByCgroup.sh manually from the command line.

## Restore from EBS Snapshot

Uh oh.  Something went horribly wrong and you need to recover from one of the snapshots you've been keeping.  Fundamentally, you will be creating new EBS volumes from the snapshots and mounting them in order to recover files or whole instances.  

There are many ways to "skin the cat".  You can perform recoveries manually using the AWS web console or you can use the RestoreByName.sh script we've created.  For more information, check [here](README_RestoreByName.sh.md).
