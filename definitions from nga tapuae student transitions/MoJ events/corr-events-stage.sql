/*
Title: Under management by corrections
Author: Simon Anastasiadis
Reviewer: AK
Intended use: Identify periods and events of management within the justice system

History (reverse order):
2020-08-19 parameterised, simplified Correction events (MP)
2019-04-23 Reviewed (AK)
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

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)corrections]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)corrections];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)corrections] AS
SELECT [snz_uid]
      ,[cor_mmp_period_start_date] AS [start_date]
      ,[cor_mmp_period_end_date] AS [end_date]
	  , 'corrections experience' AS [description]
	  ,1 AS [value]
	  ,'corrections' AS [source]
FROM  [$(IDIREF)].[cor_clean].[ov_major_mgmt_periods]
WHERE [cor_mmp_mmc_code] NOT IN ('AGED_OUT', 'ALIVE');
GO
