$server = "fbgsqlmivm1";
$url = "https://fbgsqlmisa.blob.core.windows.net/azurebackups";
$credential = "AzureBackup";
$noexec = 1;

$trustworthy = Invoke-Sqlcmd -ServerInstance fbgsqlmivm1 `
-Database master `
-Query "EXEC GenerateSetTrustworthyOn @noexec = $noexec;";

$query = "EXEC GenerateOlaUpdateStatements @url = N'$url', @credential = N'$credential', @noexec = $noexec;";

$backupjobs = Invoke-Sqlcmd -ServerInstance fbgsqlmivm1 `
-Database master `
-Query "EXEC GenerateOlaUpdateStatements @url = N'$url', @credential = N'$credential', @noexec = $noexec;";

$trustworthy.Column1 | Out-File "C:\Temp\$server`_trustworthy.sql";
$backupjobs.Column1 | Out-File  "C:\Temp\$server`_backupupdate.sql";
