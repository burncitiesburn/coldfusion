<cfcomponent output="false">

	<cffunction name="init">
		<cfreturn this />
	</cffunction> 

	<!--- 
	Extracts files from a .tar file into the directory in which the .tar file resides
	
	@param file    Absolute path to tar file. (Required)
	@return Returns the verbose log from the tar.exe executable.
	@author Angus Miller
	@version 1, January 3, 2012
	@notes
		Requires Tar for Windows in a "tar" subfolder within the executables folder:
			tar.exe
			libintl-2.dll
			libiconv-2.dll
			(refer to http://gnuwin32.sourceforge.net/packages/gtar.htm)
		Requires following subfolders within the tar subfolder
			temp_file_to_untar
			temp_untarred_files
		Requires untar.bat to exist in the base executables folder:
			cd \executables\tar
			tar.exe -xv --file=temp_file_to_untar\%1 --directory=temp_untarred_files
		The cd command must correlate with executables directory as defined by request.config["system.ExecutablesDirectory"]
	--->
	<cffunction name="untar" output="No">
		<cfargument name="file" required="Yes">
		<cfset var directory = "">
		<cfset var filename = "">
		<cfset var untar_log = "">
		<cfset var objFileUtil = createObject("component","intranet.com.hww.util.FileUtil") />
	
		<cfset filename = listLast( file, "\/" )>
		<cfset directory = reverse( replace( reverse(file), reverse(filename), "") )>
	
		<cffile action="COPY" source="#file#" destination="#request.config["system.ExecutablesDirectory"]#\tar\temp_file_to_untar\#filename#">
		
		<cfexecute name="#request.config["system.ExecutablesDirectory"]#\untar.bat" timeout="30" 
			variable="untar_log"
			arguments="#filename#"></cfexecute>
	
		<cffile action="DELETE" file="#request.config["system.ExecutablesDirectory"]#\tar\temp_file_to_untar\#filename#">
	
		<cfset objFileUtil.directoryCopy("#request.config["system.ExecutablesDirectory"]#\tar\temp_untarred_files","#directory#") />
		<cfdirectory action="DELETE" directory="#request.config["system.ExecutablesDirectory"]#\tar\temp_untarred_files" recurse="Yes">
		<cfdirectory action="CREATE" directory="#request.config["system.ExecutablesDirectory"]#\tar\temp_untarred_files">
		
		<cfreturn untar_log>
	</cffunction>

</cfcomponent>
