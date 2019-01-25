SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Gill, Concurrency, Inc.
-- Create date: 2019-01-24
-- Description:	Generate SET TRUSTWORTHY ON statement for all user databases in an ONLINE state
-- Sample execution: EXEC GenerateSetTrustworthyOn @noexec = 1;
-- =============================================
CREATE PROCEDURE GenerateSetTrustworthyOn 
	-- Add the parameters for the stored procedure here
	@noexec int = 1
AS
BEGIN
	SET NOCOUNT ON;

	/* Drop and create temp table */
	DROP TABLE IF EXISTS #trustworthy;

	CREATE TABLE #trustworthy
	(RowId INT IDENTITY(1,1)
	,alterdb NVARCHAR(200));

	/* Declare and initialize local variables */
	DECLARE @looplimit INT,
	@loopcount INT,
	@sqlstr NVARCHAR(2000);

	SELECT @loopcount = 1,
	@noexec = 1;

	/* Build ALTER DATABASE...SET TRUSTWORTHY ON for user databases that are online
	   To change the list of databases returned, modify the WHERE predicate */
	INSERT INTO #trustworthy
	(alterdb)
	SELECT CONCAT(N'ALTER DATABASE ', name, N' SET TRUSTWORTHY ON;')
	FROM sys.databases
	WHERE database_id > 4
	AND [state] = 0
	ORDER BY [name];

	/* Get the MAX RowId from the temp table to set the loop limit */
	SELECT @looplimit = MAX(RowId) FROM #trustworthy;

	WHILE @loopcount <= @looplimit
	BEGIN

		/* Return the ALTER DATABASE statement for each database */
		SELECT @sqlstr = alterdb
		FROM #trustworthy
		WHERE RowId = @loopcount;

		/* If @noexec is set to 1 print the ALTER DATABASE statement for execution in SSMS
		   SELECT it for generation via PowerShell */
		IF @noexec = 1
		BEGIN

			PRINT @sqlstr;
			SELECT @sqlstr;

		END
		/* If @noexec is set to 0, execute the ALTER DATABASE statement */
		ELSE
		BEGIN
		
			PRINT CONCAT ('Executing dynamic SQL ', @sqlstr, N'.');
			EXEC sp_executesql @sqlstr;

		END

		SELECT @loopcount += 1;

	END 
END
GO
