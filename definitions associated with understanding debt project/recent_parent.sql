/**************************************************************************************************
Title: Recent parent
Author: Simon Anastasiadis
Reviewer: Freya Li

Inputs & Dependencies:
- [IDI_Clean].[dia_clean].[births]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_recent_parent]

Description:
Given a number of years within which a person is considered a recent parent
(see parameters) provides a spell during which people are considered recent
parents.

Intended purpose:
Identifying when people become parents.
Identifying whether a person is a recent parent.
  
Notes:
1) One record per child means that twins (or triplets, etc.) result in more
   than one record for each parent.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
  Years 'recent' must be within = 2

Issues:
- Contains trivial number of duplicate records
 
History (reverse order):
2020-11-20 FL QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_recent_parent]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_recent_parent];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_recent_parent] AS
SELECT [snz_uid]
	,dob AS [start_date]
	,DATEADD(YEAR, 2, dob) AS [end_date]
	,[child_snz_uid]
FROM (

SELECT [parent1_snz_uid] AS [snz_uid]
	,[dia_bir_birth_month_nbr]
	,[dia_bir_birth_year_nbr]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS dob
	,[dia_bir_still_birth_code]
	,[snz_uid] AS [child_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[births]
WHERE [parent1_snz_uid] IS NOT NULL

UNION ALL

SELECT [parent2_snz_uid] AS [snz_uid]
	,[dia_bir_birth_month_nbr]
	,[dia_bir_birth_year_nbr]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS dob
	,[dia_bir_still_birth_code]
	,[snz_uid] AS [child_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[births]
WHERE [parent2_snz_uid] IS NOT NULL
AND ([parent1_snz_uid] IS NULL OR [parent1_snz_uid] <> [parent2_snz_uid])

) k
WHERE [dia_bir_still_birth_code] IS NULL;
GO