/**************************************************************************************************
Title: Spell of NEET (Not in Employment, Education or Training)
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[data].[person_overseas_spell]
- education_spells.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_enrolled_education]
- employment_spells.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_employed_spell]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell]

Description:
Spells where a person is not in employment education or training (NEET).
People are NEET if they are on the spine, alive, aged between 15 and 65, 
and neither overseas, employed, or studying.

Intended purpose:
Counting the number of days a person spends NEET.
As an intermediate step for NEET classifications.

Notes:
1) There are multiple definitions for whether a person is classified as NEET
   (e.g. long term NEET, main activity NEET, youth NEET). NEET spells can be used as a
   starting point for subsequent classification.
2) Where a person has more days NEET than education/training, employment or overseas
   they can be labelled as 'NEET as a main activity'.
   David Earle recommends NEET as a main activity on page 3 of:
     School to work: what matters? Education and employment of young people born in 1991.
     Published by Ministry of Education in June 2016
3) The 15-65 age band used in our definition is not consistent with several definitions of NEET
   used elsewhere. Other definitions of NEET often focus on young people aged 15-35 (or narrower).
   Furthermore we do not account for caring for children. Hence caution is recommended when using
   this definition.
4) Speed improvements arise from pre-filtering the non-NEET spells to narrower dates of interest.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest non-NEET date = '2006-01-01'
  Latest non_NEET date = '2026-12-31'
   
Issues:
- Slow. Runtime > 10 minutes.

History (reverse order):
2021-01-26 SA QA
2021-01-11 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-03-02 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_NEET_spell_staging]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_NEET_spell_staging];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_NEET_spell_staging] AS
SELECT [snz_uid]
      ,DATEFROMPARTS([snz_birth_year_nbr] + 18, [snz_birth_month_nbr], 15) AS [earliest_start_date]
	  ,CASE WHEN ([snz_deceased_year_nbr] IS NULL OR [snz_deceased_year_nbr] - [snz_birth_year_nbr] > 65)
	   THEN EOMONTH(DATEFROMPARTS([snz_birth_year_nbr] + 65, [snz_birth_month_nbr], 28))
	   ELSE EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28)) END AS [latest_end_date]
FROM [IDI_Clean_20201020].[data].[personal_detail]
WHERE [snz_spine_ind] = 1
AND [snz_person_ind] = 1
AND [snz_birth_year_nbr] IS NOT NULL
AND [snz_birth_month_nbr] IS NOT NULL;
GO


/* Non-NEET spell data */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging];
GO

SELECT *
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging]
FROM (
	/* overseas */
	SELECT [snz_uid]
		,CAST([pos_applied_date] AS DATE) AS [start_date]
		,CAST([pos_ceased_date] AS DATE) AS [end_date]
		,'o' AS [source]
	FROM [IDI_Clean_20201020].[data].[person_overseas_spell] o

	UNION ALL

	/* enrolled */
	SELECT [snz_uid]
		,[start_date]
		,[end_date]
		,'s' AS [source]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_enrolled_education]

	UNION ALL

	/* employed */
	SELECT [snz_uid]
		,[start_date]
		,[end_date]
		,'w' AS [source]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_employed_spell]
) k
WHERE '2006-01-01' <= [end_date]
AND [start_date] <= '2026-12-31'
GO

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] (snz_uid);
GO

/* NEET spell data */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell];
GO

WITH
s AS (
	SELECT snz_uid
		,[earliest_start_date] AS [start_date]
	FROM [IDI_UserCode].[DL-MAA2020-01].[d2gP2_NEET_spell_staging] a
	WHERE NOT EXISTS(
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] b
		WHERE a.snz_uid = b.snz_uid
		AND a.[earliest_start_date] BETWEEN b.[start_date] AND b.[end_date]
	)

	UNION ALL

	SELECT [snz_uid]
		,IIF(YEAR(a.[end_date]) = 9999, a.[end_date], DATEADD(DAY, 1, a.[end_date])) AS [start_date]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] a
	WHERE NOT EXISTS(
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] b
		WHERE a.snz_uid = b.snz_uid
		AND IIF(YEAR(a.[end_date]) = 9999, a.[end_date], DATEADD(DAY, 1, a.[end_date])) BETWEEN b.[start_date] AND b.[end_date]
	)
	AND NOT EXISTS(
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA2020-01].[d2gP2_NEET_spell_staging] c
		WHERE a.snz_uid = c.snz_uid
		AND IIF(YEAR(a.[end_date]) = 9999, a.[end_date], DATEADD(DAY, 1, a.[end_date])) <= c.earliest_start_date
	)
),
e AS(
	SELECT snz_uid
		,[latest_end_date] AS [end_date]
	FROM [IDI_UserCode].[DL-MAA2020-01].[d2gP2_NEET_spell_staging] a
	WHERE NOT EXISTS(
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] b
		WHERE a.snz_uid = b.snz_uid
		AND a.[latest_end_date] BETWEEN b.[start_date] AND b.[end_date]
	)

	UNION ALL

	SELECT snz_uid
		,DATEADD(DAY, -1, a.[start_date]) AS [end_date]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] a
	WHERE NOT EXISTS(
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging] b
		WHERE a.snz_uid = b.snz_uid
		AND DATEADD(DAY, -1, a.[start_date]) BETWEEN b.[start_date] AND b.[end_date]
	)
	AND NOT EXISTS(
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA2020-01].[d2gP2_NEET_spell_staging] c
		WHERE a.snz_uid = c.snz_uid
		AND DATEADD(DAY, -1, a.[start_date]) >= c.latest_end_date
	)
)
SELECT s.snz_uid
	,s.[start_date]
	,MIN(e.[end_date]) AS [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell]
FROM s
INNER JOIN e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_neet_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging view */
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_NEET_spell_staging]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_NEET_spell_staging];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_non_neet_spell_staging];
GO

