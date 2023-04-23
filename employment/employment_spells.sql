/**************************************************************************************************
Title: Spell of employment
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
A spell where wages or salaries are reported to IRD as evidence of employment.

Intended purpose:
Creating indicators of when/whether a person was employed.
Identifying spells when a person is employed.
Counting the number of days a person spends employed.

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_employed_spell]
 
Notes:
1) Employer Monthly Summaries (EMS) records provide an indication that a person was employed
   during a specific month. Where start or end dates are provided, these are used so long
   as they are close to the month of the EMS record. For all other records (the vast majority)
   the first and last day of the month is used.
2) Employment includes receipt of Wages & Salaries (WAS or W&S), and receipt of Schedular Payments
   from which Withholding Payments are deducted (WHP). People receiving Wages & Salaries are
   employees. People receiving Schedular Payments may be contractors. Neither of these definitions
   perfectly capture self employment (sole trader, partnership, or company) some of which can 
   only be observed at a (tax) year resolution.
   However, comparing EMS to tax year summaries suggests that W&S and WHP captures at least 
   some self-employment. And that this is more likely to be observed as WHP rather than W&S.
3) The EMS record includes start and end dates for employment. Where these are populated they
   may provide a more accurate indication of start and end date than the beginning and end
   of the return month (note the 'return period date' is the end of the month).
   - If the start date is provided and is within two months of the return date, then we use
     it as the best indication of start date. While employers must submit EMS monthly, an
     employee who joins once month and receivies their first pay the next month, will only
     appear in the EMS record for the second month.
   - If the end date is provided and is within the month for which the return relates,
     then we use it as the best indication of end date.
   - Inspection of the data suggests that when end dates are outside (after) the month of
     the return this is employers reporting future end dates of contracts. The employee
	 continues to have EMS records for each month of their employment. As future end dates can
	 change (be renegotiated) and their use would result in double counting of the same period
	 for the same job (different from the double counting where people work multiple jobs),
	 we only use provided end date if it is within the month of the EMS return.
4) Condensing is necessary to avoid double counting where people work multiple jobs.
   It also merges adjacent spells (e.g. 1-7 Jan and 8-14 Jan becomes 1-14 Jan).
   Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
5) A placeholder identity exists where the encrypted IRD number [snz_ird_uid] is equal to
   zero. Documentation states these are people who can not be linked. We exclude this identity.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]
  Earliest start date = '2014-01-01'
  Latest end date = '2020-12-31'
 
Issues:
- Does not capture all self-employment. Use of annual tax year data is recommended for analyses at
  annual resolution, or where it is important to capture self-employment.
- Slow. For years 2014-2020 runtime more than 2 hours
 
History (reverse order):
2021-01-26 SA QA
2021-01-11 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-07-01 SA expanded definition of employment to include WHP as this covers some self-employment
2020-03-02 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2gP2_employed_spell_staging];
GO

/* Create staging */
CREATE VIEW [DL-MAA20XX-YY].[d2gP2_employed_spell_staging] AS
SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 -- employee started in the last two months
		THEN [ir_ems_employee_start_date]
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]), MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND ([ir_ems_employee_start_date] IS NULL OR [ir_ems_employee_start_date] < [ir_ems_employee_end_date])
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 -- employee finished in the last month
		THEN [ir_ems_employee_end_date] 
		ELSE [ir_ems_return_period_date] END AS [end_date]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] IN ('W&S', 'WHP')
AND [snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
AND [ir_ems_return_period_date] BETWEEN '2014-01-01' AND '2020-12-31';
GO

/* Condensed spells */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_employed_spell];
GO

WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_employed_spell_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_employed_spell_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_employed_spell_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_employed_spell_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND YEAR(t1.[end_date]) <> 9999
		AND DATEADD(DAY, 1, t1.[end_date]) BETWEEN t2.[start_date] AND t2.[end_date]
		--AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_employed_spell]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_employed_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_employed_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2gP2_employed_spell_staging];
GO

