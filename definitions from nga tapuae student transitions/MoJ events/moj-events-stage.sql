/*
Title: Court hearing
Author: Simon Anastasiadis
Reviewer: AK
Intended use: Identify dates of court hearing

Note:
Only the first and last hearings relating to a spcific charge are recorded.
If a charge has three or more hearings that the hearings other than the first
and last will not appear in the dataset.

History (reverse order):
2020-08-19 parameterised (MP)
2019-04-23 reviewed (AK)
2019-01-10 Initiated (SA)
*/

--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/


--##############################################################################################################

/*embedded in user code*/
USE IDI_UserCode
GO

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)court_hearing]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)court_hearing];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)court_hearing] AS
SELECT [snz_uid]
      ,[moj_chg_first_court_hearing_date] AS [start_date]
	  ,[moj_chg_first_court_hearing_date] AS [end_date]
	  ,'court hearing' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM  [$(IDIREF)].[moj_clean].[charges]
WHERE [moj_chg_first_court_hearing_date] IS NOT NULL

UNION ALL

SELECT [snz_uid]
      ,[moj_chg_last_court_hearing_date] AS [start_date]
	  ,[moj_chg_last_court_hearing_date] AS [end_date]
	  ,'court hearing' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM  [$(IDIREF)].[moj_clean].[charges]
WHERE [moj_chg_last_court_hearing_date] IS NOT NULL
AND ([moj_chg_first_court_hearing_date] IS NULL
OR [moj_chg_first_court_hearing_date] <> [moj_chg_last_court_hearing_date]);
GO

/*
Title: Court proceeding
Author: Simon Anastasiadis
Reviewer: AK
Intended use: Identify periods where an individual is under stress
due to the laying of court charges that are yet to be resolved.

Notes:
Requires dates for laid charges and outcome to be recorded. Between
these dates there is an unresolve/outstanding court charge against
the individual.

NOT FOR USE IN V1 and V2 AS INCORRECTLY FILTERED TO "TOP 1000"

History (reverse order):
2020-08-19 parameterised (MP)
2019-04-23 Reviewed (AK)
2019-01-10 Initialised (SA)
*/

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)court_proceeding]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)court_proceeding];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)court_proceeding] AS
SELECT [snz_uid]
      ,[moj_chg_charge_laid_date] AS [start_date]
      ,[moj_chg_charge_outcome_date] AS [end_date]
	  ,'court proceeding' AS [description]
	  ,1 AS [value]
	  ,'moj charges' AS [source]
FROM  [$(IDIREF)].[moj_clean].[charges]
WHERE [moj_chg_charge_laid_date] IS NOT NULL
AND [moj_chg_charge_outcome_date] IS NOT NULL;
GO