/**************************************************************************************************
Title: Spell living in social housing
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
A spell for a person living in social housing provided by central government.

Intended purpose:
Creating indicators of when/whether a person has lived in social housing.
Identifying spells when a person is living in social housing.
Counting the number of days a person spends in social housing.

Inputs & Dependencies:
- [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_tenancy]


Notes:
1) The snapshot table identifies who was in a house at given points of time. Where the 
   same person appears in consecutive snapshots we infer they are in the house during the
   intervening time.
2) Condensing is used to avoid double counting where different tenancies overlap.
   If condensing is slow, pre-filtering the input tables may improve speed.
3) Latest start date is 2021-11-30

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
  Earliest start date = 'YYYY-MM-DD'
  Latest end date = 'YYYY-MM-DD'
 
Issues:
- Slow. Runtime > 17 minutes.
- Only uses occupancy snapshots. No connection to applications.
	Hence limited accurcy as to when people moved into social housing.
 
History (reverse order):
2020-06-14 FL update the referesh, table name and correct condensing step
2020-11-23 FL QA
2020-03-03 SA v1
**************************************************************************************************/

/* Condensed spells */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging];
GO

/* Create staging table */
SELECT a.[snz_uid]
      ,a.[hnz_ths_snapshot_date] AS [start_date]
	  ,b.[hnz_ths_snapshot_date] AS [end_date]
      ,a.[hnz_ths_app_relship_text]
      ,a.[hnz_ths_signatory_flg_ind]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging]
FROM [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) BETWEEN 20 AND 40 -- adjacent months
AND (a.[snz_household_uid] = b.[snz_household_uid]
OR a.[snz_legacy_household_uid] = b.[snz_legacy_household_uid])
AND a.[hnz_ths_snapshot_date] BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'
AND b.[hnz_ths_snapshot_date] BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD';
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging] (snz_uid);
GO

/* Condensed spells */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_tenancy];
GO

/* create table with condensed spells */
WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND YEAR(t1.[end_date]) <> 9999
		AND  DATEADD(DAY, 1, t1.[end_date]) BETWEEN t2.[start_date] AND t2.[end_date]
		--AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_tenancy]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_tenancy] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_tenancy] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[hnz_tenancy_staging];
GO

