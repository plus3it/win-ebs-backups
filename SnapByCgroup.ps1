# This script is designed to perform consistent backups of
# - Selected EBS volumes (referenced by "Consistency Group"
#   AWS object-tag)
# - Mounted filesystems (referenced by Windows drive-letter
#   or fully-qualified directory-path)
#
#
# Dependencies:
# - Generic: See the top-level README_dependencies.md file for
#   a full list of script dependencies
#
# License:
# - This script released under the Apache 2.0 OSS License
#
######################################################################

# Commandline arguments parsing
Param (
   [string]$congrp = $(throw "-congrp is required")
)

# Set generic variables
$DateStmp = $(get-date -format "yyyyMMddHHmm")
$LogDir = "C:/TEMP/EBSbackup"
$LogFile = "${LogDir}/backup-$DateStmp.log"
$instMetaRoot = "http://169.254.169.254/latest/"

# Make sure AWS cmdlets are available
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"


# Function to set AWS_DEFAULT_REGION
Function SetAWSregion {
   # Capture instance identy "document" data
   $docStruct = Invoke-RestMethod -Uri ${instMetaRoot}/dynamic/instance-identity/document/

   # Extract info from $docStruct
   $instRegion = $docStruct.region
   $instId = $docStruct.instanceId

   # Set AWS region fo subsequent AWS cmdlets
   Set-DefaultAWSRegion -Region $instRegion
}


# Function to run Snapshots in parallel
Function New-EbsSnapshot {
   [CmdLetBinding()]

   Param(
      # Placeholder
   )

   BEGIN {
      # Things that don't change, just do once
   }

   PROCESS {
      foreach ($volume_id in $VolList) {
         Start-Job -name $volume_id -script {
            $SnapIdStruct = New-EC2Snapshot -VolumeId $volume_id -Description ${BkupName}
            $SnapId = $SnapIdStruct.SnapshotId
            New-EC2Tag -Resource $SnapId -Tag @( @{ Key="Name"; Value="${BkupName}" }, `
               @{ Key="AltName"; Value="Test-Tage ${BkupName}" } )
            Start-Sleep -seconds 5
         }
         Write-Host $SnapId
      }
   }

   END {
      # Placeholder
   }
   
}


# Grab all volumes owned by instance and are part of selected consistency group
Function GetAttVolList {
   [cmdLetBinding()]

   $VolumeStruct = Get-EC2Volume -Filter @(
                   @{ Name="attachment.instance-id"; Values="$instId" },
                   @{ Name="tag:Consistency Group"; Values="$congrp" }
                   )

   # Extract VolumeIDs from $VolumeStruct
   $VolumeList = $VolumeStruct.VolumeId

}



GetAttVolList
New-EbsSnapshot

