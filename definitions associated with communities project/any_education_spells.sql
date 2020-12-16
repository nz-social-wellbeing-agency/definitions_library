/**************************************************************************************************
Title: Spell enrolled in any education
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[student_enrol]
- [IDI_Clean].[moe_clean].[enrolment]
- [IDI_Clean].[moe_clean].[targeted_training]
- [IDI_Clean].[moe_clean].[tec_it_learner]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education]

Description:
A spell with any enrollment in education, regardless of type, level or source.

Intended purpose:
Creating indicators of when/whether a person has studied.
Identifying spells when a person is studying.
Counting the number of days a person spends studying.
Use when all types of study (university, industry training, etc.) are treated the same.

Notes:
1) Condensing is necessary to avoid double counting where different enrollments overlap.
2) Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
3) Writing a staging table (rather than a staging view) is faster as we can add an index.
4) [moe_clean].[enrolment] does not include cancellations/withdrawls. Hence it may overcount.
   Some withdrawl dates from courses can be retrieved from [moe_clean].[course] where this 
   is important. Withdrawls from industry training are not available.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
  Earliest start date = '2016-01-01'
  Latest end date = '2026-12-31'
 
Issues:
1) Industry training duration of enrollment can differ widely from expected duration of
   course. We are yet to determine how best to reconcile this difference. At present we consider
   only enrollment.
 
History (reverse order):
2020-05-26 SA corrected to include secondary school enroll
2020-03-02 SA v1
**************************************************************************************************/

/* Clear staging table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging];
GO

/* Create staging table */

/*Enrolment in secondary education*/
SELECT snz_uid
	,'secondary' AS [source]
	,[moe_esi_start_date] as [start_date]
	,COALESCE([moe_esi_end_date], DATEADD(YEAR, 5, [moe_esi_start_date])) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging]
FROM [IDI_Clean_20200120].[moe_clean].[student_enrol]
WHERE [moe_esi_start_date] <= '2026-12-31'
AND ([moe_esi_end_date] IS NULL OR '2016-01-01' <= [moe_esi_end_date])

UNION ALL

/*Enrolment in tertiary education*/
SELECT snz_uid
	,'tertiary' AS [source]
	,[moe_enr_prog_start_date] as [start_date]
	,[moe_enr_prog_end_date] as [end_date]
FROM [IDI_Clean_20200120].[moe_clean].[enrolment]
WHERE [moe_enr_prog_start_date] <= '2026-12-31'
AND '2016-01-01' <= [moe_enr_prog_end_date]

UNION ALL

/*Enrolment in targeted training*/
SELECT snz_uid
	,'targeted_training' AS [source]
	,[moe_ttr_placement_start_date] as [start_date]
	,[moe_ttr_placement_end_date] as [end_date]
FROM [IDI_Clean_20200120].[moe_clean].[targeted_training]
WHERE [moe_ttr_placement_start_date] <= '2026-12-31'
AND '2016-01-01' <= [moe_ttr_placement_end_date]

UNION ALL

/*Enrolment in industry training*/
SELECT [snz_uid]
	,'tec_it_learner' AS [source]
	,[moe_itl_start_date] as [start_date]
	,[moe_itl_end_date] as end_date
FROM [IDI_Clean_20200120].[moe_clean].[tec_it_learner]
WHERE [moe_itl_end_date] IS NOT NULL
AND [moe_itl_start_date] <= '2026-12-31'
AND '2016-01-01' <= [moe_itl_end_date];
GO

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging] (snz_uid)
GO


/* Condensed spells */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education];
GO

/* create table with condensed spells */
WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_enrolled_education_staging];
GO