<cfcomponent displayname="gchat" hint="CFC for sending messages to a gchat webhook">
	<cffunction name="init">
		<cfargument name="gchat_endpoint"> 
		<cfset variables.gchat_endpoint = arguments.gchat_endpoint>
	</cffunction>

	<cffunction name="formatHTML">
		<cfargument name="messageDetail" hint="replaces the html tags in the message detail with markdown">
		
		<cfset var newMessageDetail = arguments.messageDetail>
		<cfset newMessageDetail = replace(newMessageDetail, '<b>', '*', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '</b>', '*', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<br>', chr(10), 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<br/>', chr(10), 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<br />', chr(10), 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<ul>', '', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '</ul>', '', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<strong>', '*', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '</strong>', '*', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<em>', '_', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '</em>', '_', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<li>', '- ', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '</li>', '', 'all')>
		<cfset newMessageDetail = replace(newMessageDetail, '<hr>', '---'&chr(10), 'all')>
		<cfset newMessageDetail = reReplaceNoCase(newMessageDetail, '<strong style=".*?">', '*', 'all')>
		<cfset newMessageDetail = replaceNoCase(newMessageDetail,'<a target="_blank" href="','<','all')>
		<cfset newMessageDetail = replaceNoCase(newMessageDetail,'">','|','all')>
		<cfset newMessageDetail = replaceNoCase(newMessageDetail,'</a>','>','all')>
		
		<cfreturn newMessageDetail>
	</cffunction>

	<cffunction name="sendMessage">
		<cfargument name="stMessage" hint="struct containing message details">
		<cfset var servername = "">
		<cftry>
			<cfset servername = server.server_name>
			<cfcatch>
				<cfset servername = "unknown due to error">
			</cfcatch>
		</cftry>
		<cfset threadKey = createUUID>
		<cfset var message = {
							'text': arguments.stMessage.title & "#chr(10)##chr(10)#" &
									"Server: #cgi.server_name# [#servername#]#chr(10)##chr(10)#" &
									formatHTML(arguments.stMessage.detail), 
							'thread': {'threadKey': "'"&threadKey&"'" } 
						}>
		<cfif structKeyExists(arguments.stMessage, "customMessage")>
			<cfif structKeyExists(arguments.stMessage.customMessage,"text")>
				<cfset message.text &= "#chr(10)##chr(10)#"&arguments.stMessage.customMessage.text>
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="initErrorMessage">
		<cfargument name="title" required="true">
		<cfargument name="stError" required="true">
		
		<cfset var stMessage = {	title = arguments.title,
									detail = "Message: #arguments.stError.message# #chr(10)#" } >

		<cfif findNoCase(arguments.stError.detail,arguments.stError.message) eq 0>
			<cfset stMessage.detail &= "Detail: #arguments.stError.detail# #chr(10)#" >
		</cfif>
		
		<cfset stMessage.detail &= "Filepath: #stError.stack[1]["template"]# #chr(10)#" >
		<cfset stMessage.detail &= "Line No: #stError.stack[1]["line"]# #chr(10)#" >
								
		<cfif structKeyExists(arguments.stError,"DatabaseError")>
			<cfif structKeyExists(arguments.stError.DatabaseError,"QueryError")>
				<cfset stMessage.detail &= "QueryError: #arguments.stError.DatabaseError.QueryError# #chr(10)#" >
			</cfif>
		</cfif>
		
		<cfreturn stMessage >
	</cffunction>
</cfcomponent>