<cfset jdbcDriver = CreateObject("java", "com.microsoft.sqlserver.jdbc.SQLServerDriver")>
<cfset jdbcDriverMetadata = CreateObject("java", "com.microsoft.sqlserver.jdbc.SQLServerDatabaseMetaData").init(JavaCast( "null", 0 ))>
<cfoutput>
#jdbcDriver.getMajorVersion()#.#jdbcDriver.getMinorVersion()#<br>
#jdbcDriverMetadata.getDriverVersion()#<br>
</cfoutput>