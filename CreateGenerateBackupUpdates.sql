
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Gill, Concurrency, Inc.
-- Create date: 2019-01-24
-- Description:	Generate statement to update the destination for Ola Hallengren's backup jobs to Azure Storage Account
-- Example: EXEC GenerateOlaUpdateStatements @url = N'https://mystorageacct.blob.core.windows.net', @credential = N'mycredential', @noexec = $noexec;
-- =============================================
ALTER PROCEDURE GenerateOlaUpdateStatements 
	@url NVARCHAR(200) = N'https://myurl.com', 
	@credential NVARCHAR(200) = N'credential',
	@noexec INT = 1
AS
BEGIN
	SET NOCOUNT ON;

	/*	Create tables and variables  */
	DROP TABLE IF EXISTS #jobs;

	CREATE TABLE #jobs
	(RowId INT IDENTITY(1,1)
	,JobName SYSNAME
	,JobId UNIQUEIDENTIFIER
	,StepId INT
	,StepName SYSNAME
	,Command NVARCHAR(MAX));

	DECLARE @parm NVARCHAR(1000),
	@directory NVARCHAR(1000),
	@cleanup NVARCHAR(1000),
	@command NVARCHAR(MAX),
	@newcommand NVARCHAR(MAX),
	@stepupdate NVARCHAR(MAX),
	@jobid UNIQUEIDENTIFIER,
	@jobname SYSNAME,
	@stepid INT,
	@loopcount INT,
	@looplimit INT;

	/*	Set URL and credential for replacement 
		Initialize @loopcount
		Set @noexc = 1 to PRINT dynamic SQL command
		Set @noexec = 0 to execute dynamic SQL command  */
	SELECT @parm = CONCAT(N'@URL = ''', @url, ''', @Credential = ''', @credential, ''', @CopyOnly = ''Y'''),
	@loopcount = 1,
	@noexec = 1;

	SELECT @parm;

	/*	Get list of backup jobs that contain an @Directory parameter
		NOTE - Change the value in the LIKE clause to return different jobs  */
	INSERT INTO #jobs
	(JobName
	,JobId
	,StepId
	,StepName
	,Command)
	SELECT j.name, j.job_id, s.step_id, s.step_name, s.command 
	FROM msdb.dbo.sysjobs j
	INNER JOIN msdb.dbo.sysjobsteps s
	ON s.job_id = j.job_id
	WHERE j.name LIKE '%backup%'
	AND PATINDEX(N'%@Directory%', Command) > 0;

	SELECT @looplimit = MAX(RowId) FROM #jobs;

	/*	Loop through each job command  */
	WHILE @loopcount <= @looplimit
	BEGIN

		/*	Return the required data for the REPLACE and sp_update_job_step execution  */
		SELECT @command = Command, 
		@directory = SUBSTRING(Command, PATINDEX(N'%@Directory%', Command), (CHARINDEX(',',Command,PATINDEX(N'%@Directory%', Command)) - PATINDEX(N'%@Directory%', Command))),
		@cleanup = SUBSTRING(Command, PATINDEX(N'%@CleanupTime%', Command), (CHARINDEX(',',Command,PATINDEX(N'%@CleanupTime%', Command)) - PATINDEX(N'%@CleanupTime%', Command))),
		@jobid = JobId,
		@jobname = JobName,
		@stepid = StepId
		FROM #jobs
		WHERE RowId = @loopcount;

		/*	Replace the @Directory value with the @url parm  */
		SELECT @newcommand = REPLACE(@command, @directory, @parm);

		/*	Remove the @CleanupTime parameter from @newcommand  */
		SELECT @newcommand = REPLACE(@newcommand, @cleanup, '');

		/*	Change single ticks to double ticks  */
		SELECT @newcommand = REPLACE(@newcommand,'''','''''');

		/*	Build the command to update the job step */
		SELECT @stepupdate = CONCAT(N'EXEC dbo.sp_update_jobstep
	@job_name = N''', @jobname, ''',	 
	@step_id = ', @stepid, ',
	@command = ''', @newcommand, ''';');
		/*  If @noexec is 1, print dynamic SQL for output in SSMS
		    SELECT dynamic SQL for output in PowerShell  */
		IF @noexec = 1
		BEGIN
		
			PRINT @stepupdate;
			SELECT @stepupdate;

		END
		/*  If @noexec is 0, execute the dynamic SQL  */
		ELSE
		BEGIN
		
			EXEC sp_executesql @stepupdate;

		END

		SELECT @loopcount += 1;

	END

END
GO
