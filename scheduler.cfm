<!--- cleanup --->
<cfobject type="JAVA" action="Create" name="factory" class="coldfusion.server.ServiceFactory">
<cfset allTasks = factory.CronService.listAll()>
<cfset numberOtasks = arraylen(allTasks)>
<cfloop index="i" from="1" to="#numberOtasks#">
	<cfschedule action="delete" task="#allTasks[i].task#">
</cfloop>

<!---- find stuff in trash which should not be ---->
<!----

<cfschedule action = "update"
    task = "findRecoverNotReallyTrash"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=findRecoverNotReallyTrash"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:00 AM"
    interval = "60">
---->

<!---
	findAllCr2 grabs all the new file names from the renamed dir
--->





<cfschedule action = "update"
    task = "findAllCr2"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=findAllCr2"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:00 AM"
    interval = "daily">
<!---
	push_to_dng moves files from the renamed dir to the source dir for the cron job that
	actually makes DNG

	Runs every hour
--->
<cfschedule action = "update"
    task = "push_to_dng"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=push_to_dng"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:00 AM"
    interval = "3600">




<!---
	findAllDng uses LOCATE to find all DNG files on the disk system
	Run this after the ROOT locate.updatedb cron job has had time to finish
	and the findAllCr2 task (which is quick) has had time to finish

	30 23 * * * /usr/libexec/locate.updatedb
--->
<cfschedule action = "update"
    task = "findAllDng"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=findAllDng"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:05 AM"
    interval = "daily">

<!---
	IsImgOnArctos checks Arctos by barcode (=filename - extension) for the presense of Media
	This processes a maximum of 500 records, and should complete in 20 minutes.

--->
<cfschedule action = "update"
    task = "IsImgOnArctos"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=IsImgOnArctos"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:00 AM"
	endTime = "11:30 PM"
    interval = "60">

<!---
	push_to_tacc moves 10 DNGs to TACC
	Each move takes about 40 seconds, assuming all threads end happily

	maximum rate:
		1440 min/day
		runs every 2 minutes=720 runs/day
		10 files/run=7200 images/day

 --->
<cfschedule action = "update"
    task = "push_to_tacc"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=push_to_tacc"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "12:01 AM"
	endTime = "11:30 PM"
    interval = "60">
<!---
	cleanup moves files to the local trashcan after they've been located on Arctos


--->

<cfschedule action = "update"
    task = "cleanup"
    operation = "HTTPRequest"
    url = "#application.schedulerURL#/paleoimager.cfm?action=cleanup"
    startDate = "#dateformat(now(),'dd-mmm-yyyy')#"
    startTime = "04:00 AM"
    interval = "daily">
