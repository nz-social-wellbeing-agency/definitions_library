/**************************************************************************************************
Title: Has dependent children
Author: Simon Anastasiadis
Reviewer: Marianna Pekar, Joel Bancolita

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_dependent_children]

Description:
The time period during which a person has living children under the age of 16.
So age 0-15 is dependent.

Intended purpose:
Counting the number of dependent children that a person has at any point in time.
 
Notes:
1) There is no control for whether a person lives with (their) children or is
   involved in their care. Only considers parents by birth so legal guardians
   can not be identified this way.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
 
Issues:
 
History (reverse order):
2020-07-22 JB QA
2020-07-21 MP QA
2020-03-04 SA v1
**************************************************************************************************/

USE [IDI_UserCode]
GO

/* Clear before creation */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_dependent_children]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_dependent_children];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_dependent_children] AS
SELECT *
FROM (
	SELECT [snz_parent1_uid] AS [snz_uid]
		,[snz_birth_date_proxy] AS [start_date]
		/* if child dies before 16th birthday, use date of death, otherwise use 16th birthday */
		,IIF(	DATEFROMPARTS([snz_birth_year_nbr] + 16, [snz_birth_month_nbr], 15) -- [16th_birthday]
				> DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28), -- [death_day]
				DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28),
				DATEFROMPARTS([snz_birth_year_nbr] + 16, [snz_birth_month_nbr], 15) ) AS [end_date]
	FROM [IDI_Clean_20200120].[data].[personal_detail]
	WHERE [snz_parent1_uid] IS NOT NULL
	AND [snz_uid] IS NOT NULL
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL

	UNION ALL

	SELECT [snz_parent2_uid] AS [snz_uid]
		,[snz_birth_date_proxy] AS [start_date]
		/* if child dies before 16th birthday, use date of death, otherwise use 16th birthday */
		,IIF(	DATEFROMPARTS([snz_birth_year_nbr] + 16, [snz_birth_month_nbr], 15) -- [16th_birthday]
				> DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28), -- [death_day]
				DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28),
				DATEFROMPARTS([snz_birth_year_nbr] + 16, [snz_birth_month_nbr], 15) ) AS [end_date]
	FROM [IDI_Clean_20200120].[data].[personal_detail]
	WHERE [snz_parent2_uid] IS NOT NULL
	AND [snz_uid] IS NOT NULL
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL
	AND [snz_parent1_uid] <> [snz_parent2_uid] -- parents are different
) k
WHERE [start_date] <= [end_date]
GO
