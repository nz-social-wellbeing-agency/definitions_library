/**************************************************************************************************
Title: Spell of employment with wages or salaries
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell]

Description:
A spell where wages or salaries are reported to IRD as evidence of employment.

Intended purpose:
Creating indicators of when/whether a person was employed.
Identifying spells when a person is employed.
Counting the number of days a person spends employed.
 
Notes:
1) Employer Monthly Summaries (EMS) records provide an indication that a person was employed
   during a specific month. Where start or end dates are provided, these are used so long
   as they are close to the month of the EMS record. For all other records (the vast majority)
   the first and last day of the month is used.
2) Self employment does not appear in this definition.
3) Condensing is necessary to avoid double counting where people work multiple jobs.
   It also merges adjacent spells (e.g. 1-7 Jan and 8-14 Jan becomes 1-14 Jan).
4) Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
5) A placeholder identity exists where the encrypted IRD number [snz_ird_uid] is equal to
   zero. Checking across refreshes suggests this is people without an IRD number. We exclude
   this identity.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
  Earliest start date = '2016-01-01'
  Latest end date = '2020-12-31'
 
Issues:
- Slow. For years 2014-2020 runtime 12 minutes
 
History (reverse order):
2020-03-02 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_employed_spell_staging]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_employed_spell_staging];
GO

/* Create staging */
CREATE VIEW [DL-MAA2016-15].[defn_employed_spell_staging] AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 -- employee started in the last two months
		THEN [ir_ems_employee_start_date]
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND ([ir_ems_employee_start_date] IS NULL OR [ir_ems_employee_start_date] < [ir_ems_employee_end_date])
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 -- employee finished in the last month
		THEN [ir_ems_employee_end_date] 
		ELSE [ir_ems_return_period_date] END AS [end_date]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code]= 'W&S'
AND [snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
AND [ir_ems_return_period_date] BETWEEN '2016-01-01' AND '2020-12-31';
GO

/* Condensed spells */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell];
GO

WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[defn_employed_spell_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA2016-15].[defn_employed_spell_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[defn_employed_spell_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_UserCode].[DL-MAA2016-15].[defn_employed_spell_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_employed_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_employed_spell_staging]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_employed_spell_staging];
GO

