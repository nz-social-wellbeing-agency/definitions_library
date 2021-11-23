/*
Title: Being included on an application for social housing
Author: Simon Anastasiadis
Reviewer: AK
Intended use: Identify social housing applications

History (reverse order):
2020-08-18 Parameterise for Nga Tapuae (Marianna Pekar)
2019-04-23 Reviewed (AK)
2019-04-01 Initiated (SA)

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


IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)hnz_apply]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)hnz_apply];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)hnz_apply] AS
SELECT snz_uid
	,[hnz_na_date_of_application_date] AS [start_date]
	,[hnz_na_date_of_application_date] AS [end_date]
	,'apply social housing' AS [description]
	,1 AS [value]
	,'HNZ' AS [source]
FROM (

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM  [$(IDIREF)].[hnz_clean].[new_applications] a
INNER JOIN  [$(IDIREF)].[hnz_clean].[new_applications_household] b
ON a.[snz_msd_application_uid] = b.[snz_msd_application_uid]

UNION ALL

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM  [$(IDIREF)].[hnz_clean].[new_applications] a
INNER JOIN  [$(IDIREF)].[hnz_clean].[new_applications_household] b
ON a.[snz_application_uid] = b.[snz_application_uid]
WHERE a.[snz_msd_application_uid] IS NULL
OR b.[snz_msd_application_uid] IS NULL

UNION ALL

SELECT b.snz_uid
	,a.[hnz_na_date_of_application_date]
FROM  [$(IDIREF)].[hnz_clean].[new_applications] a
INNER JOIN  [$(IDIREF)].[hnz_clean].[new_applications_household] b
ON a.[snz_legacy_application_uid] = b.[snz_legacy_application_uid]
WHERE (a.[snz_msd_application_uid] IS NULL
OR b.[snz_msd_application_uid] IS NULL)
AND (a.[snz_application_uid] IS NULL
OR b.[snz_application_uid] IS NULL)
) k
GO

/*
Title: Living in social housing
Author: Simon Anastasiadis
Reviewer: AK
Intended use: Identify social housing tenancy

History (reverse order):
2020-08-18 Parameterise for Nga Tapuae (Marianna Pekar)
2019-04-23 Reviewed (AK)
2019-04-01 Initiated (SA)
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)hnz_tenancy]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)hnz_tenancy];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)hnz_tenancy] AS
SELECT a.[snz_uid]
      ,a.[hnz_ths_snapshot_date] AS [start_date]
	  ,b.[hnz_ths_snapshot_date] AS [end_date]
	  ,'HNZ tenant' AS [description]
	  ,1 AS [value]
	  ,'HNZ' AS [source]
FROM  [$(IDIREF)].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN  [$(IDIREF)].[hnz_clean].[tenancy_household_snapshot] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) >= 20
AND DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) <= 40
AND (a.[snz_household_uid] = b.[snz_household_uid]
OR a.[snz_legacy_household_uid] = b.[snz_legacy_household_uid])
GO
