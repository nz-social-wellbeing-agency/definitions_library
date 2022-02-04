/**************************************************************************************************
Title: Receipt of sickness benefit
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- main_benefits_by_type_and_partner_status.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_abt_main_benefit_final]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell]

Description:
Sickness related main benefit receipt spells regardless of benefit type or beneficiary role.

Intended purpose:
Creating indicators of when/whether a person was receiving a sickness-type benefit.
Identifying spells when a person is receiving a sickness-type benefit.
Counting the number of days a person spends receiving sickness-type benefit.

Notes:
1) Input table already contains condensing and preparation. But when we discard the benefit
   type and beneficiary role, further condensing is necessary to avoid double counting.
2) Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
3) In the absence of health related data, this provides us with a proxy for whether a person
   has experienced poor health that prevents them working.

Parameters & Present values:
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest start date = '2012-01-01'
  Latest end date = '2020-12-31'
 
Issues:
 
History (reverse order):
2021-06-10 FL including those spells which end date is null
2021-01-26 SA QA
2021-01-11 FL v2 (Change prefix and update the table to the latest refresh)
2020-11-23 FL QA
2020-03-03 SA v1
**************************************************************************************************/
/* Wipe before recreating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell];
GO

WITH sickness_filter AS (
	SELECT [snz_uid]
		,[start_date]
		,[end_date]
		,[role]
		,[level4]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_abt_main_benefit_final]
	WHERE [role] <> 'partner'
	AND [level4] IN ('Invalids', 'Sickness')
	AND [start_date] <= [end_date]
	AND '2012-01-01' <= [end_date]
	AND [start_date] <= '2020-12-31'
),
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM sickness_filter s1
	WHERE NOT EXISTS (
		SELECT 1
		FROM sickness_filter s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM sickness_filter t1
	WHERE NOT EXISTS (
		SELECT 1 
		FROM sickness_filter t2
		WHERE t2.snz_uid = t1.snz_uid
		AND YEAR(t1.[end_date]) <> 9999
		AND  DATEADD(DAY, 1, t1.[end_date]) BETWEEN t2.[start_date] AND t2.[end_date]
		--AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_sickness_benefit_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO


