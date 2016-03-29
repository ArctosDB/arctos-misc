<cfcomponent>
	<cfset This.name = "Imager">
	<cfset This.SessionManagement="True">
	<cfset This.ClientManagement="true">
	<cfset This.ClientStorage="Cookie">


	<cffunction name="onApplicationStart" output="false">
		<!--- server root --->
		<cfset application.webroot="/Applications/Coldfusion9/wwwroot">
		<!--- we call locate to find files - make sure it stays updated with /usr/libexec/locate.updatedb --->
		<cfset application.locate="/usr/bin/locate">
		<!--- place for "deleted" files - do actual delete manually, or w/ cron if you're brave --->
		<cfset application.trash="/imgTemp/trash">
		<cfset application.imgPath="/Image">

		<!--- directory that the create DNG cron job runs on ---->
		<cfset application.makeDNGPath="/imgTemp/forDNG">
		<!--- directory for newly-created DNGs ---->
		<cfset application.newDNGPath="/imgTemp/newDNG">
		<!--- regular expression to filter by pre-defined valid filenames --->
		<cfset application.validCR2NameRegExp="^H[0-9]{7}\.cr2$">
		<cfset application.validDNGNameRegExp="^H[0-9]{7}\.dng$">
		<!--- remote server connection --->
		<cfset application.remoteusername="dustylee">
		<cfset application.remoteserver="corral.tacc.utexas.edu">
		<!--- ssh rsa/dsa key for application.remoteusername --->
		<cfset application.sshkey='/Applications/ColdFusion9/wwwroot/pw/id_rsa'>
		<!--- base remote path --->
		<cfset application.remoteroot="/corral-tacc/tacc/arctos/uam/es">

		<cfset application.schedulerURL="127.0.0.1:8500/">
	</cffunction>
</cfcomponent>