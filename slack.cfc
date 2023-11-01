<cfcomponent displayname="Slack" hint="CFC for sending messages to a slack webhook">
	<cffunction name="init">
		<cfargument name="slack_endpoint"> 
		<cfset variables.slack_endpoint = arguments.slack_endpint>
	</cffunction>

	<cffunction name="htmlToMarkDown">
		<cfargument name="messageDetail" hint="replaces the html tags in the message detail with markdown">
		
		<cfset var temp = arguments.messageDetail>
		<cfset temp = replace(temp, '<b>', '*', 'all')>
		<cfset temp = replace(temp, '</b>', '*', 'all')>
		<cfset temp = replace(temp, '<br>', chr(10), 'all')>
		<cfset temp = replace(temp, '<br/>', chr(10), 'all')>
		<cfset temp = replace(temp, '<br />', chr(10), 'all')>
		<cfset temp = replace(temp, '<ul>', '', 'all')>
		<cfset temp = replace(temp, '</ul>', '', 'all')>
		<cfset temp = replace(temp, '<strong>', '*', 'all')>
		<cfset temp = replace(temp, '</strong>', '*', 'all')>
		<cfset temp = replace(temp, '<em>', '_', 'all')>
		<cfset temp = replace(temp, '</em>', '_', 'all')>
		<cfset temp = replace(temp, '<li>', '- ', 'all')>
		<cfset temp = replace(temp, '</li>', '', 'all')>
		<cfset temp = replace(temp, '<hr>', '---'&chr(10), 'all')>
		<cfset temp = reReplaceNoCase(temp, '<strong style=".*?">', '*', 'all')>
		<cfset temp = replaceNoCase(temp,'<a target="_blank" href="','<','all')>
		<cfset temp = replaceNoCase(temp,'">','|','all')>
		<cfset newMessageDetail = replaceNoCase(temp,'</a>','>','all')>
		
		<cfreturn newMessageDetail>
	</cffunction>

	<cffunction name="sendMessage">
		<cfargument name="stMessage" hint="struct containing message title, detail and custom message"><!--- stMessage.title, stMessage.detail, stMessage.customMessage --->

		<cfset divider = { "type" : "divider" }>

		<cfset servername = "">
		<cftry>
			<cfset servername = server.server_name>
			<cfcatch>
				<cfset servername = "unknown due to error">
			</cfcatch>
		</cftry>

		<cfset message = {
							"blocks" : 	[
									{
										"type" : "section",
										"text" : {
											"text" : "*#arguments.stMessage.title#*",
											"type" : "mrkdwn"
										}
									},
									{
										"type" : "section",
										"text" : {
											"text" : "Server: #cgi.server_name# [#servername#]",
											"type" : "mrkdwn"
										}
									},
									{
										"type" : "section",
										"text" : {
											"text" : "#htmlToMarkDown(arguments.stMessage.detail)#",
											"type" : "mrkdwn"
										}
									}
								]
							}>
		<cfif structKeyExists(stMessage, "customMessage") and structKeyExists(stMessage.customMessage, "type") and stMessage.customMessage.type eq "section"
			and structKeyExists(stMessage.customMessage,"text")>
			<cfset arrayAppend(message["blocks"],stMessage.customMessage)>
		</cfif>

		<cfset arrayAppend(message["blocks"],divider)>

        <cfhttp method="POST" url="#variables.slack_endpoint#">
            <cfhttpparam type="HEADER" name="Content-Type" value="application/json; charset=utf-8">
            <cfhttpparam type="BODY" value="#serializeJSON(message)#">
        </cfhttp>
	</cffunction>
	
	<cffunction name="initErrorMessage">
		<cfargument name="title" required="true">
		<cfargument name="stError" required1="true">
		
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

