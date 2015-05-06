# This script is designed to restore an EBS or EBS-group using the 
# value in the snapshots' "Snapshot Group" tag:
# * If the snapshots' "Snapshot Group" tags are not set, this script will fail
# * If the name-value passed to the script is not an exact-match for 
#   any snapshots' "Snapshot Group" tag, this script will fail
#
# Note: this script assumes that you are attaching an EBS to an
#       existing instance, either with the intention to recover 
#       individual files or to act as a full restore of a damaged 
#       or destroyed EBS. The full restore may be made available
#       on a new instance or on the instance that originally
#       generated the EBS snapshot.
#
# Dependencies:
# - Generic: See the top-level README_dependencies.md for script dependencies
# - Specific:
#   * All snapshots - or groups of snapshots - to be restored via this
#     script must have a unique "Snapshot Group" tag (at least within the scope
#     of an Amazon region). Non-unique "Snapshot Group" tags will result in
#     collisions during restores
#
# License:
# - This script released under the Apache 2.0 OSS License
#
######################################################################

# Commandline arguments parsing
Param (
   [string]$snapgrp = $(throw "-snapgrp is required")
)

# Set generic variables
$DateStmp = $(get-date -format "yyyyMMddHHmm")
$LogDir = "C:/TEMP/EBSbackup"
$LogFile = "${LogDir}/backup-$DateStmp.log"
$instMetaRoot = "http://169.254.169.254/latest/"

# Make sure AWS cmdlets are available
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"


# Capture instance identy "document" data
$docStruct = Invoke-RestMethod -Uri ${instMetaRoot}/dynamic/instance-identity/document/

# Extract info from $docStruct
$instRegion = $docStruct.region
$instAZ = $docStruct.availabilityZone
$instId = $docStruct.instanceId

# Set AWS region fo subsequent AWS cmdlets
Set-DefaultAWSRegion $instRegion


##########
# Get list of snspshots matching "Snapshot Group"
function GetSnapList {
   $SnapStruct =`Get-EC2Snapshot -Filter @(
               @{ Name="tag:Created By" ; Values="Automated Backup" }, `
               @{ Name="tag:Snapshot Group" ; Values="$snapgrp" }
             ) 

   # Set 'global' for use elsewhere
   $global:SnapList = $SnapStruct.SnapshotId


   if ( [string]::IsNullOrEmpty($SnapList) ) {
      throw "No matching snapshots found"
   }
   else {
      "Found snapshots: " + $SnapList
   }

}


##########
# Create recovery-volumes from snapshots
function SnapToEBS {
   GetSnapList

#   $EBSlist = [System.Collections.Generic.List[System.String]]()
  [System.Collections.Generic.List[System.String]]$EBSlist = ''

   # Iterate snapshot group
   foreach($SnapShot in $SnapList) {
      Write-Host "Attempting to create EBS from snapshot $SnapShot"
      $RecoveryEBSstruct = New-EC2Volume -SnapshotId $SnapShot -VolumeType standard -AvailabilityZone $instAZ
      $RecoveryEBS = $RecoveryEBSstruct.VolumeId

      # Ensure we got an EBS volume-identifier
      if ( [string]::IsNullOrEmpty($RecoveryEBS) ) {
         throw "Failed to create recovery-EBS from $SnapShot"
      }
      else {
         $EBSlist.Add("$RecoveryEBS") | out-null
         
         New-EC2Tag -Resource $RecoveryEBS -Tag @(
           @{ Key="Name" ; Value="Restore of $snapgrp" }, `
           @{ Key="Creator Instance" ; Value="$instId" }, `
           @{ Key="Created By" ; Value="Scripted Restore Utility" }
         )
      }
   }

   # Log what we did
   $EBSlist.Remove("") | Out-Null
   Write-Host "Created recovery-EBS(es): $EBSlist" 

}



##########
# Take list of Amazon-recommended attachment-points and
# remove already-used attachment-points.
function ComputeFreeSlots {

   # A list of possible instance storage-attachment points
   $AllDiskSlots = [System.Collections.Generic.List[System.String]](
      "/dev/sda1",
      "xvdf",
      "xvdg",
      "xvdh",
      "xvdi",
      "xvdj",
      "xvdk",
      "xvdl",
      "xvdm",
      "xvdn",
      "xvdo",
      "xvdp",
      "xvdq",
      "xvdr",
      "xvds",
      "xvdt",
      "xvdu",
      "xvdv",
      "xvdw",
      "xvdx",
      "xvdy",
      "xvdz"
   )

   # Get list of currently-bound EBSes
   $BoundBDevStruct = (Get-EC2Instance -Region us-west-2 -Instance $instId).Instances
   $BoundBDevList = $BoundBDevStruct.BlockDeviceMappings.DeviceName
   $BoundBDevCt = $BoundBDevList.Count

   Write-Host "Found block devs bound at: $BoundBDevList"

   # Remove currently-bound slots from "All Slots" list
   $LoopIndex = 0
   while ( $LoopIndex -lt $BoundBDevCt )
   {
      $BoundBDevVal = $BoundBDevList[$LoopIndex]
      $AllDiskSLots.Remove("$BoundBDevVal") | out-null
      $LoopIndex++
   }

   $AvailDiskSlots = $AllDiskSlots

}


##########
# Bind recovery-EBSes to available attachment-points
function EBStoSlot {
}

SnapToEBS
ComputeFreeSlots 
