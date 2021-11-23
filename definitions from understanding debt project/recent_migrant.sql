/**************************************************************************************************
Title: Recent migrant to New Zealand
Author: Simon Anastasiadis
Reviewer: Freya Li

Inputs & Dependencies:
- [IDI_Clean].[data].[person_overseas_spell]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_recent_migrants]

Description:
Given a number of years within which a person is considered a recent migrant
(see parameters) provides a spell during which people are considered recent
migrants.

Intended purpose:
Identifying when people enter New Zealand for the first time.
Identifying whether a person is a recent migrant.
 
Notes:
1) Overseas spells are stored as date-time with non-trivial time.
   For consistency with other date, we remove their time component.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = tmp_
  Project schema = [DL-MAA2020-01]
  Years 'recent' must be within = 2
 
Issues:
 
History (reverse order):
2020-11-20 FL QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Remove view */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_recent_migrants]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_recent_migrants];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_recent_migrants] AS
SELECT [snz_uid]
      ,CAST([pos_ceased_date] AS DATE) AS [start_date]
	  ,IIF(YEAR([pos_ceased_date]) = 9999, CAST([pos_ceased_date] AS DATE), DATEADD(YEAR, 2, CAST([pos_ceased_date] AS DATE))) AS [end_date]
      ,[pos_first_arrival_ind]
      ,[pos_last_departure_ind]
      ,[pos_source_code]
FROM [IDI_Clean_20200120].[data].[person_overseas_spell]
WHERE pos_first_arrival_ind = 'y';
GO
