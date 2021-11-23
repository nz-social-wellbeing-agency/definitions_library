/****** 

Title: Living in meshblocks with high (1-2) deprivation as in 2013
Author: Marianna Pekar 
Based on information received from Jo Fink, Ministry of Justice, Senior Analyst, Analysis and Modelling
Reviewer: awaiting review

Notes:
- deprivation index by meshblocks change in census years

Dependencies: 
[$(PROJSCH)].[$(TBLPREF)evtvw_addr_desc] - address information


History (reverse order):
2020-08-28 initiated (MP)

 ******/

/* Setting parameters */
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/

USE [IDI_UserCode]
GO

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)high_depr]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)high_depr];
GO


/* Create staging */
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)high_depr] AS
SELECT snz_uid
	,ant_notification_date AS [start_date]
	,ant_replacement_date AS [end_date]
	,'high deprivation' AS [description]
	,CASE WHEN DepIndex2013 IN (1,2) THEN 1 ELSE NULL END AS [value]
	,'DepIndex2013' AS [source]
FROM  [$(PROJSCH)].[$(TBLPREF)evtvw_addr_desc] 
WHERE DepIndex2013 IN (1,2);
GO


