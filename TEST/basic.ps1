$VolList = @(
   "vol-10e9f301",
   "vol-f48663e4",
   "vol-55816445",
   "vol-49816459"
)

# $JobList = @()
# 
# foreach ($VolName in $VolList) {
#    $JobId = Start-Job -Name $VolName -ScriptBlock {
#       Get-EC2Volume -VolumeId $VolName
#    } 
# 
#    $JobInfo = Get-Job -name $VolName
#    $JobList += $JobId.Id
# }
# 
# foreach ($Job in $JobList) {
#    Write-Host $Job
# }

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
         # Things to do in parallel for each item in the pipeline
         $desc = "some description"
         # New-EC2Snapshot -VolumeId $volume_id -Description $desc
         $VolInfo = Get-EC2Volume -VolumeId $volume_id
         Write-Host $VolInfo.state
      }
   }

   END {
      # Things to do after processing the pipeline
   }
}

New-EbsSnapshot
