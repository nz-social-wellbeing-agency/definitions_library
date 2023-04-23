/**************************************************************************************************
Title: Has dependent children
Author: Simon Anastasiadis 
Re-edit: Freya Li

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Disclaimer:
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the 
context of a specific project. Whether or not these definitions are suitable for other projects depends on the 
context of those projects. Researchers using definitions from this library will need to determine for themselves 
to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides 
this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

Citation:
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

Description:
The time period during which a person has living children under the age of 18.
So age 0-17 is dependent.

Intended purpose:
Counting the number of dependent children that a person has at any point in time.

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_dependent_children]

Notes:
1) There is no control for whether a person lives with (their) children or is
   involved in their care. Only considers parents by birth so legal guardians
   can not be identified this way.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]
  age no longer dependent = 18

History (reverse order):
2021-06-09 SA refactor & replace age with year of birth
2021-06-08 FL add the age of child
2021-01-26 SA QA
2020-01-07 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-07-21 MP QA
2020-03-04 SA v1
  **************************************************************************************************/

USE [IDI_UserCode]
GO

/* Clear before creation */
IF OBJECT_ID('[DL-MAA20XX-YY].[d2gP2_dependent_children]','V') IS NOT NULL
DROP VIEW [DL-MAA20XX-YY].[d2gP2_dependent_children];
GO

CREATE VIEW [DL-MAA20XX-YY].[d2gP2_dependent_children] AS
WITH end_dependency AS (

	SELECT [snz_parent1_uid]
		,[snz_parent2_uid]
		,[snz_birth_date_proxy]
		/* if child dies before 18th birthday, use date of death, otherwise use 18th birthday */
		,IIF(	EOMONTH(DATEFROMPARTS([snz_birth_year_nbr] + 18, [snz_birth_month_nbr], 15)) -- [18th_birthday]
				> EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28)), -- [death_day]
				EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28)),
				EOMONTH(DATEFROMPARTS([snz_birth_year_nbr] + 18, [snz_birth_month_nbr], 15)) ) AS [end_dependency_date]
	FROM [IDI_Clean_YYYYMM].[data].[personal_detail]
	WHERE [snz_uid] IS NOT NULL
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL
	and [snz_birth_year_nbr] <>9999
)
SELECT *
FROM (
	SELECT [snz_parent1_uid] AS [snz_uid]
		,[snz_birth_date_proxy] AS [start_date]
		,[end_dependency_date] AS [end_date]
		,YEAR([snz_birth_date_proxy]) AS child_year_of_birth
	FROM end_dependency
	WHERE [snz_parent1_uid] IS NOT NULL

	UNION ALL

	SELECT [snz_parent2_uid] AS [snz_uid]
		,[snz_birth_date_proxy] AS [start_date]
		,[end_dependency_date] AS [end_date]
		,YEAR([snz_birth_date_proxy]) AS child_year_of_birth
	FROM end_dependency
	WHERE [snz_parent2_uid] IS NOT NULL
	AND [snz_parent1_uid] <> [snz_parent2_uid] -- parents are different
) k
WHERE [start_date] <= [end_date]
GO
