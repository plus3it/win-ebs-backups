The "SnapMaint" utility is designed to identify and remove snapshots that are older than a given number of days. The script takes two, optional arguments
- keepdays: this argment is an integer value equating to the maximum age of snapshots from the momement of the utility's invocation. This means that if a value of '8' is specified, the utility will look for backup snapshots that are calculated to have been created 8 days prior to the invocation of this utility. Thus, if a snapshot is even one second younger than 8 days, it will be kept and if it ies even one second older than when the utility was invoked, it will be deleted. Default value is '7' unless overriden by the use of this flag
- snapgrp: this argment is a string value equating to the name of the snapshot or group of snapshots to be evaluated. In order for this tag to be meaningful, all EBS backup snapshots will need to have had the group-label, "Snapshot Group", applied in order for this selector to work. Note that this selector is used for a substring-match. While the full "Snapshot Group" string may be specified, any valid substring will suffice.

When this script is run, output produced will be similar to the following:

~~~
C:\MiscUtils\WinEBSbackups > .\SnapMaint.ps1 -keepdays 7 -snapgrp WinScriptPool
Found snapshot: snap-33ed0571 (started @ 04/30/2015 23:59:48)
Found snapshot: snap-3b912279 (started @ 05/01/2015 23:59:49)
Found snapshot: snap-d88b349a (started @ 04/30/2015 23:59:48)
Found snapshot: snap-3f9f097a (started @ 05/03/2015 00:00:03)
Found snapshot: snap-d497db91 (started @ 05/05/2015 00:00:04)
Found snapshot: snap-3be7bf7c (started @ 05/04/2015 00:00:01)
Found snapshot: snap-12a6c64b (started @ 05/06/2015 23:59:57)
Found snapshot: snap-52ef4109 (started @ 05/05/2015 00:00:04)
Found snapshot: snap-06e44e5c (started @ 05/03/2015 00:00:03)
Found snapshot: snap-26d5fc7b (started @ 05/06/2015 00:00:00)
Found snapshot: snap-54c1b908 (started @ 05/01/2015 23:59:50)
Found snapshot: snap-b64264ea (started @ 05/06/2015 23:59:57)
Found snapshot: snap-7c79c72d (started @ 05/06/2015 00:00:01)
Found snapshot: snap-49377318 (started @ 05/04/2015 00:00:00)
Found snapshot: snap-7fdbc42e (started @ 05/05/2015 00:00:05)
Found snapshot: snap-0aace35a (started @ 05/03/2015 00:00:03)
Found snapshot: snap-614c0231 (started @ 04/30/2015 23:59:47)
Found snapshot: snap-649bc834 (started @ 05/04/2015 00:00:01)
Found snapshot: snap-8afe3cd9 (started @ 05/06/2015 23:59:57)
Found snapshot: snap-d5c7b180 (started @ 05/01/2015 23:59:50)
Found snapshot: snap-d96c3a8c (started @ 05/06/2015 00:00:01)
Nothing to delete: no snapshots older than keep-horizon
~~~
or
~~~
C:\MiscUtils\WinEBSbackups > .\SnapMaint.ps1 -keepdays 6 -snapgrp WinScriptPool
Found snapshot: snap-33ed0571 (started @ 04/30/2015 23:59:48) - snap-33ed0571 is older than defined horizon (adding to delete-list)
Found snapshot: snap-3b912279 (started @ 05/01/2015 23:59:49)
Found snapshot: snap-d88b349a (started @ 04/30/2015 23:59:48) - snap-d88b349a is older than defined horizon (adding to delete-list)
Found snapshot: snap-3f9f097a (started @ 05/03/2015 00:00:03)
Found snapshot: snap-d497db91 (started @ 05/05/2015 00:00:04)
Found snapshot: snap-3be7bf7c (started @ 05/04/2015 00:00:01)
Found snapshot: snap-12a6c64b (started @ 05/06/2015 23:59:57)
Found snapshot: snap-52ef4109 (started @ 05/05/2015 00:00:04)
Found snapshot: snap-06e44e5c (started @ 05/03/2015 00:00:03)
Found snapshot: snap-26d5fc7b (started @ 05/06/2015 00:00:00)
Found snapshot: snap-54c1b908 (started @ 05/01/2015 23:59:50)
Found snapshot: snap-b64264ea (started @ 05/06/2015 23:59:57)
Found snapshot: snap-7c79c72d (started @ 05/06/2015 00:00:01)
Found snapshot: snap-49377318 (started @ 05/04/2015 00:00:00)
Found snapshot: snap-7fdbc42e (started @ 05/05/2015 00:00:05)
Found snapshot: snap-0aace35a (started @ 05/03/2015 00:00:03)
Found snapshot: snap-614c0231 (started @ 04/30/2015 23:59:47) - snap-614c0231 is older than defined horizon (adding to delete-list)
Found snapshot: snap-649bc834 (started @ 05/04/2015 00:00:01)
Found snapshot: snap-8afe3cd9 (started @ 05/06/2015 23:59:57)
Found snapshot: snap-d5c7b180 (started @ 05/01/2015 23:59:50)
Found snapshot: snap-d96c3a8c (started @ 05/06/2015 00:00:01)
Snapshot(s) to delete: snap-33ed0571 snap-d88b349a snap-614c0231
Deleting snapshot: snap-33ed0571...Success
Deleting snapshot: snap-d88b349a...Success
Deleting snapshot: snap-614c0231...Success
~~~
or
~~~
C:\MiscUtils\WinEBSbackups > .\SnapMaint.ps1 -keepdays 6 -snapgrp "Bogus Group"
Nothing to delete: no snapshots older than keep-horizon
~~~
As shown above, the utility will locate all snapshots associated with the host. Snapshots that are older than the default or specified keep-horizon will be called out in the find-list and then deleted:
- The first example shows that, if there are now matches found that are older than the specified age, nothing is deleted.
- The second examples shows a successful match for age and group-description substring.
- The ghird example shows that there were no matches found. This will normally be the result if there are no snapshots for the calling host that match the passwd snapshot groupname string.
