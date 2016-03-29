<!---
	This version of the imager relies on having
	data in predictable places - that is, starting
	from scratch, rather than in the middle of a
	huge MorphBank-induced pileup.

	It's simpler and cleaner, but does require (slightly) more
	precision from users, and enough bandwidth to get everything
	pushed through in a reasonable (within a day or two)
	timeframe

	Prerequisites:

	Folders, all created and appropriately permissioned
		/Image
		/imgTemp/trash
		/imgTemp/forDNG
		/imgTemp/newDN
		/ImageLZ with folder action:


	Root's crontab:
	sh-3.2# whoami
		root
		sh-3.2# crontab -l
		# just a shortcut to make sure locate gets updated periodically
		30 23 * * * /usr/libexec/locate.updatedb
		script to create dngs from the cr2s
		15,45 * * * * /ImageScripts/dng.sh

		sh-3.2# cat /ImageScripts/dng.sh
		LDIR=/imgTemp/forDNG ## application.makeDNGPath
		DDIR=/imgTemp/newDNG ## application.newDNGPath
		DNGCNV=/Applications/dngConvert ## alias to Adobe DNG converter
		ls $LDIR | grep .cr2 | head -n 150 | while read FILE
			do
				NAME=`echo $FILE | sed -e 's/\.cr2//'`
				$DNGCNV -d $DDIR $LDIR/$FILE
				## and move the CR2 into the DNG directory
		 		mv $LDIR/$FILE $DDIR
			done
		## and fix the permissions
		chgrp -R admin $DDIR
		chown -R dusty $DDIR
		chmod -R 775 $DDIR

	one table:

	mysql> desc image;
+---------------------+--------------+------+-----+-------------------+----------------+
| Field               | Type         | Null | Key | Default           | Extra          |
+---------------------+--------------+------+-----+-------------------+----------------+
| pkey                | int(11)      | NO   | PRI | NULL              | auto_increment |
| filename            | varchar(30)  | NO   | UNI | NULL              |                |
| found_cr2           | timestamp    | NO   |     | CURRENT_TIMESTAMP |                |
| checked_arctos_date | timestamp    | YES  |     | NULL              |                |
| found_arctos_date   | timestamp    | YES  |     | NULL              |                |
| pushed_to_tacc_date | timestamp    | YES  |     | NULL              |                |
| pushed_to_dng_date  | timestamp    | YES  |     | NULL              |                |
| found_dng           | timestamp    | YES  |     | NULL              |                |
| notes               | varchar(255) | YES  |     | NULL              |                |
| error_date          | timestamp    | YES  |     | NULL              |                |
| deleted_date        | timestamp    | YES  |     | NULL              |                |
+---------------------+--------------+------+-----+-------------------+----------------+
11 rows in set (0.00 sec)




svn checkout http://arctos.googlecode.com/svn/arctos/imager .
--->


		<!--- place for "deleted" files - do actual delete manually, or w/ cron if you're brave --->
		<cfset trash="/imgTemp/trash">
		<cfset imgPath="/Image">
		<cfset pushedPath="/ImageMovedToTacc">
		<!--- directory that the create DNG cron job runs on ---->
		<cfset makeDNGPath="/imgTemp/forDNG">
		<!--- directory for newly-created DNGs ---->
		<cfset newDNGPath="/imgTemp/newDNG">
		<!--- regular expression to filter by pre-defined valid filenames --->
		<!--- remote server connection --->
		<cfset remoteusername="dustylee">
		<cfset remoteserver="corral.tacc.utexas.edu">
		<!--- ssh rsa/dsa key for application.remoteusername --->
		<cfset sshkey='/Applications/ColdFusion9/wwwroot/pw/id_rsa'>
		<!--- base remote path --->
		<cfset remoteroot="/corral-tacc/tacc/arctos/uam/es">




<cfif not isdefined("action")>
	<cfset action="">
</cfif>
<br><a href="paleoimager.cfm?action=findAllCr2">findAllCr2</a>
<br><a href="paleoimager.cfm?action=push_to_dng">push_to_dng</a>




<br><a href="paleoimager.cfm?action=findAllDng">findAllDng</a>
<br><a href="paleoimager.cfm?action=IsImgOnArctos">IsImgOnArctos</a>
<br><a href="paleoimager.cfm?action=push_to_tacc">push_to_tacc</a>
<br><a href="paleoimager.cfm?action=cleanup">cleanup</a>


<br><a href="paleoimager.cfm?action=recoverprobablyActallyTrash">recoverprobablyActallyTrash</a>




<br><a href="paleoimager.cfm?action=taccreport">taccreport</a>


<cfoutput>
	<cfif action is "taccreport">
		<cfquery name="d" datasource="p_imager">
			select
				date_format(pushed_to_tacc_date,'%Y_%m_%d') as pdate,
				count(*)
			from
				image
			group by
				date_format(pushed_to_tacc_date,'%Y_%m_%d')
			order by
				date_format(pushed_to_tacc_date,'%Y_%m_%d')
			DESC
		</cfquery>
		<cfdump var=#d#>



		,

	</cfif>


	<cfif action is "cleanup">
		<!---
			move pushed images (DNG and CR2) from #newDNGPath# to #pushedPath#


		---->
		<cfquery name="d" datasource="p_imager">
			select
				filename
			from
				image
			where
				found_arctos_date is not null and
				deleted_date is null
		</cfquery>
		<!---
		<cfdump var=#d#>
		---->
		<cfloop query="d">
			<br>#filename#
			<cftry>
				<cffile action="move" source="#newDNGPath#/#filename#.dng" destination="#trash#/#filename#.dng" nameconflict="overwrite">
				<cffile action="move" source="#newDNGPath#/#filename#.cr2" destination="#trash#/#filename#.cr2" nameconflict="overwrite">
				<cfquery name="d" datasource="p_imager">
					update image set deleted_date=current_timestamp() where filename='#filename#'
				</cfquery>
			<cfcatch>
				<br>fail@#cfcatch.message# #cfcatch.detail#
			</cfcatch>
			</cftry>
		</cfloop>
	</cfif>
<!----------------------------------------------------------->
	<cfif action is "findAllDNG">
		<cfdirectory action="list" filter="*.dng" directory="#newDNGPath#" name="d" type="file">
		<cfloop query="d">
			<cfset fileName=replace(name,".dng","","all")>
			<hr>#fileName#
			<cftry>
				<cfquery name="new" datasource="p_imager">
					update image set found_dng=current_timestamp()
					where filename='#fileName#'
				</cfquery>
				<br>woopee
				<cfcatch>
					<br>fail@#cfcatch.message#
				</cfcatch>
			</cftry>
		</cfloop>
	</cfif>
<!----------------------------------------------------------->
	<cfif action is "push_to_tacc">
		<!--- images that are
			DNG+valid name
			not on arctos, but checked for
			not on tacc
		--->
		<cfquery name="d" datasource="p_imager">
			select
				fileName
			from
				image
			where
				pushed_to_tacc_date is null and
				error_date is null and
				found_dng is not null
			limit 0,40
		</cfquery>
		<!----
		<cfdump var=#d#>
		---->
		<cfif d.recordcount gt 0>
			<cfset dailydir=dateformat(now(),"yyyy_mm_dd")>
			<!--- CF bug workaround - see http://forums.adobe.com/message/2312598 ---->
			<cftry>
				<cfset providerMethods = CreateObject('java','java.security.Security')>
				<cfset providerMethods.removeProvider('JsafeJCE')>
				<cfcatch>
					<br>fail@#cfcatch.message# #cfcatch.detail#
				</cfcatch>
			</cftry>

			.....switcherarrthingee success
			<!--- end CF bug workaround ---->
			<cfsetting requesttimeout="30000" />
			<cfftp action = "open"
				connection = "tacc"
			    key = "#sshkey#"
			    secure = "yes"
			    server = "#remoteserver#"
			    username = "#remoteusername#"
			    timeout="30000">

			<cfftp action="listDir" connection="tacc" name="dirlist" directory="#remoteroot#">

			<cfquery name="t" dbtype="query">
				select name from dirlist where name='#dailydir#'
			</cfquery>
			<cfif t.recordcount is not 1>
				<cfftp connection="tacc" action="createDir" directory="#remoteroot#/#dailydir#">
			</cfif>

			<cfftp action = "close" connection = "tacc">

			<cfset t=1>
			<cfset pList="">
			<cfloop query="d">
				<cfif not listfind(pList,filename)>
					<br>popping thread for #d.fileName#
					<cfif fileexists("#newDNGPath#/#d.filename#.dng")>
						===========foundit!
						<cfthread action="run" name="pushToTacc#t#" thisT="#t#" fn="#d.filename#">
							<cftry>
								<cfftp action = "open"
									connection = "tacc#thisT#"
								    key = "#sshkey#"
								    secure = "yes"
								    server = "#remoteserver#"
								    username = "#remoteusername#"
								    timeout="30000">
								<cfftp connection="tacc#thisT#"
									action="putfile"
									localFile="#newDNGPath#/#fn#.dng"
									remoteFile="#remoteroot#/#dailydir#/#fn#.dng">
								<cfftp action = "close" connection = "tacc#thisT#">
								<cfquery name="p" datasource="p_imager">
									update image set pushed_to_tacc_date=current_timestamp()
									where filename='#fn#'
								</cfquery>
							<cfcatch>
								<cfquery name="f" datasource="p_imager">
									update image set error_date=current_timestamp(),
									notes='FILENOTFOUND:: (tacc:ftp) )#ctcatch.message# #cfcatch.detail#'
									where filename='#fn#'
								</cfquery>
							</cfcatch>
							</cftry>
						</cfthread>
						<cfset t=t+1>
						<cfset pList=listappend(pList,filename)>
					<cfelse>
						---------notfound
						<cfquery name="f" datasource="p_imager">
							update image set error_date=current_timestamp(),
							notes='FILENOTFOUND:: (tacc:fileexists)' where filename='#d.filename#'
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
			<!--- CF bug workaround - see http://forums.adobe.com/message/2312598 ---->
			<cftry>
				<cfset providerMethods.insertProviderAt(jSafeProvider,1)>
				<cfcatch>-caught-</cfcatch>
			</cftry>
		</cfif>
	</cfif>
<!------------------------------------------------------------------------------------->
	<cfif action is "push_to_dng">
		<cfquery name="d" datasource="p_imager">
			select
				filename
			from
				image
			where
				pushed_to_dng_date is null
			limit 0,500
		</cfquery>
		#d.recordcount#
		<cfloop query="d">
				<cftry>
					<cffile action="move" source="#imgPath#/#filename#.cr2" destination="#makeDNGPath#/#filename#.cr2">
					<cfquery name="log" datasource="p_imager">
						update image set pushed_to_dng_date=current_timestamp() where
						filename='#filename#'
					</cfquery>
					<cfcatch>
						<cfset rrrr="<br>#cfcatch.message#: #cfcatch.detail#">
						<cfquery name="log" datasource="p_imager">
							update image set
							error_date=current_timestamp(),
							notes='create_dng::#cfcatch.message#: #cfcatch.detail#'
							where
							filename='#filename#'
						</cfquery>
					</cfcatch>
				</cftry>
			<cfflush>
		</cfloop>
	</cfif>
<!------------------------------------------------------------------------------------->
	<cfif action is "findAllCr2">
		<!--- run once/day late at night --->
		<cfdirectory action="list" filter="*.cr2" directory="#imgPath#" name="d" type="file">
		<cfloop query="d">
			<br>#name#
			<cfset fileName=replace(name,".cr2","","all")>
			<cftry>
				<cfquery name="new" datasource="p_imager">
					insert into image (filename) values ('#fileName#')
				</cfquery>
				<cfcatch>
					<br>fail@#cfcatch.message# #cfcatch.detail#
				</cfcatch>
			</cftry>
		</cfloop>
	</cfif>
<!------------------------------------------------------------------------------------->
	<cfif action is "findRecoverNotReallyTrash">
		<!----
			make a new folder for things that are in the trashcan but cannot be found
			mkdir /imgTemp/notReallyTrashAfterAll
			chmod 777 /imgTemp/notReallyTrashAfterAll

			mkdir /imgTemp/probablyActallyTrash
			chmod 777 /imgTemp/probablyActallyTrash

		---->

		<cfset x=0>
		<cfdirectory action="list" filter="*.dng" directory="/imgTemp/trash" name="d" type="file">
		<cfloop query="d">
			<cfif x lt 10>
				<cfset x=x+1>
				<!----
				<br>#Name#
				---->
				<cfhttp url="http://arctos.database.museum/component/DSFunctions.cfc?method=getMediaByExactFilename&filename=#Name#&returnformat=json&queryformat=column">
				</cfhttp>
				<cfif cfhttp.filecontent is not "1">
					<cffile action="move" source="#trash#/#name#" destination="/imgTemp/notReallyTrashAfterAll/#name#" nameconflict="overwrite">
					<br>recovered DNG
					<cfset crname=replace(name,".dng",".cr2")>
					<cftry>
						<cffile action="move" source="#trash#/#crname#" destination="/imgTemp/notReallyTrashAfterAll/#crname#" nameconflict="overwrite">
						<br>recovered cr2
					<cfcatch>
						<br>failed cr2
					</cfcatch>
					</cftry>
				<cfelse>
					<cffile action="move" source="#trash#/#name#" destination="/imgTemp/probablyActallyTrash/#name#" nameconflict="overwrite">
					<br>recovered DNG
					<cfset crname=replace(name,".dng",".cr2")>
					<cftry>
						<cffile action="move" source="#trash#/#crname#" destination="/imgTemp/probablyActallyTrash/#crname#" nameconflict="overwrite">
						<br>recoveredtrash cr2
					<cfcatch>
						<br>failedtrash cr2
					</cfcatch>
					</cftry>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>


<!---- now move the stuff from probablyActallyTrash to where it can be processed ---->
<cfif action is "recoverprobablyActallyTrash">
	<cfdirectory action="list" filter="*.dng" directory="/imgTemp/probablyActallyTrash" name="d" type="file">
	<cfset x=0>
	<cfloop query="d">
		<cfif x lt 100>
			<cfset fname=listfirst(name,".")>
			<br>#fname#
			<cfif fileexists("/imgTemp/probablyActallyTrash/#fname#.cr2")>
				<br>got a cr2
			<cfelse>
				<br>no cr2
			</cfif>
		</cfif>


	</cfloop>


</cfif>



<cfif action is "wtfTrash">
		<br>listing #trash#...
		<cfdirectory action="list" directory="#imgPath#" filter="*.cr2" name="d" type="file">
		<cfloop query="d">
			<cfset fName=listfirst(d.name,".")>
			<br>#fName#
			<cfhttp url="http://arctos.database.museum/component/DSFunctions.cfc?method=getMediaByFilename&filename=#fName#&returnformat=json&queryformat=column">
			</cfhttp>
			<cfif cfhttp.filecontent is 0>
				<br>=====================================Did not find #fName#
				<cfdirectory action="list" filter="#fName#.dng" directory="#newDNGPath#" name="ff" type="file">
				<cfif ff.recordcount is 1>
					<br>found in #newDNGPath#
				<cfelse>
					<cfdump var=#ff#>
				</cfif>
				<!---



				/imgTemp/notReallyTrashAfterAll
				---->
			<cfelse>
				<br>found #name#: -#cfhttp.filecontent#-
				<cffile action="move" source="#imgPath#/#name#" destination="/imgTemp/trash/#name#" nameconflict="overwrite">

			</cfif>

		</cfloop>
	</cfif>



<!------------------------------------------------------------------------------------->
	<cfif action is "wtfTrash2">
		<cfdirectory action="list" filter="*.dng" directory="/imgTemp/notReallyTrashAfterAll" name="d" type="file">
		<cfloop query="d">
		<cfset fName=replace(name,".dng","","all")>
		<cfquery name="new" datasource="p_imager">
			select * from image where filename='#fName#'
		</cfquery>
		<cfdump var=#new#>
		</cfloop>
	</cfif>
<!------------------------------------------------------------------------------------->
	<cfif action is "wtfTrash">
		<br>listing #trash#...
		<cfdirectory action="list" directory="#imgPath#" filter="*.cr2" name="d" type="file">
		<cfloop query="d">
			<cfset fName=listfirst(d.name,".")>
			<br>#fName#
			<cfhttp url="http://arctos.database.museum/component/DSFunctions.cfc?method=getMediaByFilename&filename=#fName#&returnformat=json&queryformat=column">
			</cfhttp>
			<cfif cfhttp.filecontent is 0>
				<br>=====================================Did not find #fName#
				<cfdirectory action="list" filter="#fName#.dng" directory="#newDNGPath#" name="ff" type="file">
				<cfif ff.recordcount is 1>
					<br>found in #newDNGPath#
				<cfelse>
					<cfdump var=#ff#>
				</cfif>
				<!---
								<cffile action="move" source="#trash#/#name#" destination="/imgTemp/notReallyTrashAfterAll/#name#" nameconflict="overwrite">


				/imgTemp/notReallyTrashAfterAll
				---->
			<cfelse>
				<br>found #name#: -#cfhttp.filecontent#-
				<cffile action="move" source="#imgPath#/#name#" destination="/imgTemp/trash/#name#" nameconflict="overwrite">

			</cfif>

		</cfloop>
	</cfif>
<!------------------------------------------------------------------------------------->
	<cfif action is "IsImgOnArctos">
		<!----
		select filename from image where
			found_arctos_date is null and
			pushed_to_tacc_date is not null and
			(
				checked_arctos_date is null or
				DATEDIFF(current_timestamp(),checked_arctos_date) > .01
			)
			limit 0,100
		---->
		<cfquery name="d" datasource="p_imager">
			select filename from image where
				found_arctos_date is null and
				pushed_to_tacc_date is not null
				order by checked_arctos_date asc limit 100
		</cfquery>
		<cfset t=1>
		<cfloop query="d">
			<cfset f=filename & ".dng">
			<br>#filename#
			<cfhttp url="http://arctos.database.museum/component/DSFunctions.cfc?method=getMediaByFilename&filename=#f#&returnformat=json&queryformat=column">
			</cfhttp>

				<br>filecontent=#cfhttp.fileContent#
				<cfif cfhttp.filecontent is 0>
					====notfound
					<cfquery name="u" datasource="p_imager">
						update image set
							checked_arctos_date=current_timestamp()
						where filename = '#filename#'
					</cfquery>
				<cfelseif cfhttp.filecontent gt 0>
				====================================gotone
					<cfquery name="u" datasource="p_imager">
						update image set
							checked_arctos_date=current_timestamp(),
							found_arctos_date=current_timestamp()
						where filename = '#filename#'
					</cfquery>
				</cfif>
		</cfloop>
			<!---
			<cfthread action="run" name="t#t#" f="#f#" image="#d.filename#">
				<cfhttp url="http://arctos.database.museum/component/DSFunctions.cfc?method=getMediaByFilename&filename=#f#&returnformat=json&queryformat=column">
				</cfhttp>
				<cfif cfhttp.filecontent is 0>
					<cfquery name="u" datasource="imager">
						update image set
							checked_arctos_date=current_timestamp()
						where image = '#image#'
					</cfquery>
				<cfelseif cfhttp.filecontent gt 0>
					<cfquery name="u" datasource="imager">
						update image set
							checked_arctos_date=current_timestamp(),
							found_arctos_date=current_timestamp()
						where filename = '#image#'
					</cfquery>
				</cfif>
			</cfthread>
			<cfset t=t+1>
		</cfloop>
		<cfset l=t-1>
		<cfloop from="1" to ="30" index="x">
			<br>loop #x#
			<cfset sleep(1000)>
			<cfloop from="1" to="#l#" index="i">
				<br>Thread#i#: #evaluate("t" & i & ".status")#
			</cfloop>
			<cfflush>
		</cfloop>
		--->
	</cfif>

