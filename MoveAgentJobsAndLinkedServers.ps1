$cred = Get-Credential;

Copy-DbaAgentJob -Source fbgsqlmivm1 -Destination "fbgsqlmi.a7cad4e18d73.database.windows.net" -DestinationSqlCredential $cred;
Copy-DbaLinkedServer -Source fbgsqlmivm1 -Destination "fbgsqlmi.a7cad4e18d73.database.windows.net" -DestinationSqlCredential $cred;

Start-DbaMigration -Source fbgsqlmivm1 -Destination "fbgsqlmi2.a7cad4e18d73.database.windows.net" -DestinationSqlCredential $cred -Exclude Databases;

