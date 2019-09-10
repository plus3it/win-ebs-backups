# About:
#   This script is designed to find a targeted-set EBS volumes attached to 
#   the instance and request the creation of EBS snapshots.
#
#   Targeting is done by scanning all locally-attached EBS volumes and 
#   looking for a 'Consistency Group' tag. The value of this tag is then 
#   matched against the script's 'cgroup' parameter. Any volumes that have 
#   matching tags are then snapshotted. done by scanning all 
#   locally-attached EBS volumes and looking for a 'Consistency Group' tag. 
#   The value of this tag is then matched against the script's 'cgroup' 
#   parameter. Any volumes that have matching tags are then snapshotted.
#
# License:
#   This script released under the Apache 2.0 OSS License
#
###########################################################################
param (
    [Parameter(
        Mandatory=$true,
	HelpMessage="Please enter the 'Consistency Group' tag-value to target"
     )][string]$cgroup = $(throw "-cgroup is required"),
    [Parameter(
        Mandatory=$false,
        HelpMessage="Path to write log-files"
     )][string]$logDir
)

# Look for EBSes with desired tag-value applied
Function GetAttVolList {
   
   $VolumeStruct = Get-EC2Volume -Filter @(
      @{ Name="attachment.instance-id"; Values="$instanceId" },
      @{ Name="tag:Consistency Group"; Values="$cgroup" } )

   # Extract VolumeIDs from $VolumeStruct
   $global:VolumeList = $VolumeStruct.VolumeId

}

# Function to run Snapshot the targeted-volumes
Function New-EbsSnapshot {
    $SnapMap = @{}

    # Set hostname tag-value
    if ( $env:userdnsdomain ) {
        $MyHostname = "$env:computername.$env:userdnsdomain"
    } else {
        $MyHostname = "$env:computername"
    }

    # Iterate volume-list and snap
    foreach ($SrcVolId in $VolumeList) {
        $SnapIdStruct = New-EC2Snapshot -VolumeId $SrcVolId -Description ${BkupDesc}
        $SnapId = $SnapIdStruct.SnapshotId

	# Create snapshot/source mapping
	$SnapMap.Add($SnapId, $SrcVolId)

	# Tell user what we've done
        Write-Host "* Snapshot creating $SnapId from $SrcVolId..."
    }

    # Batch-tag the snapshots
    write-output "Tagging snapshots... "
    foreach ( $key in $SnapMap.keys ) {
        $attachDev = ( Get-EC2Volume -VolumeId $SnapMap.$key ).Attachments.Device
        New-EC2Tag -Resource $key -Tag @( @{ Key="Name"; Value="${BkupName}" }, `
            @{ Key="Snapshot Group"; Value="$SnapGrpName" }, `
            @{ Key="Created By"; Value="$CreateBy" }, `
	    @{ Key="Source BlockDev"; Value="$attachDev" }, `
	    @{ Key="Source Hostname"; Value="$MyHostname" }, `
	    @{ Key="Source Instance"; Value="$instanceId" }
	)
    }
    write-output "Done"

}

# Ensure necessary cmdlets are available
write-output 'Importing command-dependencies...'
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

# Set generic variables
$DateStmp = $(get-date -format "yyyyMMddHHmm")
if ( ! $logDir ) {
    $logDir = "C:/TEMP/WinEBSbackups"
}
$LogFile = "${logDir}/backup-$DateStmp.log"

# Set up search-related vars
$instanceJson = Get-Ec2InstanceMetadata -category identitydocument | ConvertFrom-Json
$awsRegion = $instanceJson.region
$instanceId = $instanceJson.instanceId

# Set basic snapshot description
$BkupDesc = "${InstanceId}-bkup-${DateStmp}"
$BkupName = "AutoBack (${InstanceId}) ${DateStmp}"
$SnapGrpName = "${DateStmp} (${InstanceId}) ${congrp}"
$CreateBy = "Automated Backup"

# Ensure log-directory exists
if ( ! ( test-path $logDir ) )
{
    write-output "Attempting to create $logDir... "
    New-Item -ItemType Directory -Force -Path $logDir
}

# Identify candidate EBSes to snap
GetAttVolList

# Take appropriate action
if ($VolumeList) {
   # Output list of snap-targets
   write-output "`nFound targeted-volumes:"
   foreach ( $volume in $VolumeList ) {
      write-output "* $volume"
   }

   write-output "`nRequesting snapshots..."

   # Request snapshots
   New-EbsSnapshot
} else {
   write-output "`nFound no tagged EBS volume(s) with 'Consistency Group' tag-value of '$cgroup'"
}
