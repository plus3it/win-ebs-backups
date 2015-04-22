# This script is designed to restore an EBS or EBS-group using the 
# value in the snapshots' "Name" tag:
# * If the snapshots' "Name" tags are not set, this script will fail
# * If the name-value passed to the script is not an exact-match for 
#   any snapshots' "Name" tag, this script will fail
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
#     script must have a unique "Name" tag (at least within the scope
#     of an Amazon region). Non-unique "Name" tags will result in
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
$instId = $docStruct.instanceId

# Set AWS region fo subsequent AWS cmdlets
Set-DefaultAWSRegion $instRegion

# Get list of snspshots matching "Name"
function GetSnapList {
   $SnapStruct =`Get-EC2Snapshot -Filter @(
               @{ Name="tag:Created By" ; Values="Automated Backup" }, `
               @{ Name="tag:Snapshot Group" ; Values="$snapgrp" }
             ) 

   $SnapList = $SnapStruct.SnapshotId


   if ( [string]::IsNullOrEmpty($SnapList) ) {
      throw "No matching snapshots found"
   }
   else {
      "Found snapshots: " + $SnapList
   }

}

function ComputeFreeSlots {

   # List of possible instance storage-attachment points
   $AllDiskSlots = @(
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

# Use "Get-EC2instanceAttribute -Instance $instId -Attribute blockDeviceMapping" to get instance's EBS attachment-points
#
#      TypeName: Amazon.EC2.Model.InstanceAttribute
#  
#      Name                              MemberType Definition
#      ----                              ---------- ----------
#      Equals                            Method     bool Equals(System.Object obj)
#      GetHashCode                       Method     int GetHashCode()
#      GetType                           Method     type GetType()
#      ToString                          Method     string ToString()
#      BlockDeviceMappings               Property   System.Collections.Generic.List[Amazon.EC2.Model.InstanceBlockDeviceMapping] BlockDeviceMappings {get;set;}
#      DisableApiTermination             Property   bool DisableApiTermination {get;set;}
#      EbsOptimized                      Property   bool EbsOptimized {get;set;}
#      Groups                            Property   System.Collections.Generic.List[Amazon.EC2.Model.GroupIdentifier] Groups {get;set;}
#      InstanceId                        Property   string InstanceId {get;set;}
#      InstanceInitiatedShutdownBehavior Property   string InstanceInitiatedShutdownBehavior {get;set;}
#      InstanceType                      Property   string InstanceType {get;set;}
#      KernelId                          Property   string KernelId {get;set;}
#      ProductCodes                      Property   System.Collections.Generic.List[Amazon.EC2.Model.ProductCode] ProductCodes {get;set;}
#      RamdiskId                         Property   string RamdiskId {get;set;}
#      RootDeviceName                    Property   string RootDeviceName {get;set;}
#      SourceDestCheck                   Property   bool SourceDestCheck {get;set;}
#      SriovNetSupport                   Property   string SriovNetSupport {get;set;}
#      UserData                          Property   string UserData {get;set;}

$TESTVAR = Get-EC2instanceAttribute -Instance $instId -Attribute blockDeviceMapping
write-host ( $TESTVAR.BlockDeviceMappings | Select -ExpandProperty BlockDeviceMappings)

}

ComputeFreeSlots 
