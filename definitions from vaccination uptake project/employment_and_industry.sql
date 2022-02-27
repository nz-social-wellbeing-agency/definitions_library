/**************************************************************************************************
Title: Spell of employment
Author: Simon Anastasiadis

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [DL-MAA2021-49].[vacc_employed_spell]
- [DL-MAA2021-49].[vacc_employed_industry]

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
2) Employment includes receipt of Wages & Salaries (WAS or W&S), and receipt of Schedular Payments
   from which Withholding Payments are deducted (WHP). People receiving Wages & Salaries are
   employees. People receiving Schedular Payments may be contractors. Neither of these definitions
   perfectly capture self employment (sole trader, partnership, or company) some of which can 
   only be observed at a (tax) year resolution.
   However, comparing EMS to tax year summaries suggests that W&S and WHP captures at least 
   some self-employment. And that this is more likely to be observed as WHP rather than W&S.
3) Condensing is necessary to avoid double counting where people work multiple jobs.
   It also merges adjacent spells (e.g. 1-7 Jan and 8-14 Jan becomes 1-14 Jan).
4) Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
5) A placeholder identity exists where the encrypted IRD number [snz_ird_uid] is equal to
   zero. Documentation states these are people who can not be linked. We exclude this identity.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Earliest start date = '2020-01-01'
  Latest end date = '2021-12-31'
 
Issues:
- Does not capture all self-employment. Use of annual tax year data is recommended for analyses at
  annual resolution, or where it is important to capture self-employment.
 
History (reverse order):
2021-08-31 MP parameter changes, population resctrictions were removed
2020-07-15 JB parameterise
2020-07-09 JB Notice being subjected to pop1/pop2 compared to overall view due to performance issues
2020-07-01 SA expanded definition of employment to include WHP as this covers some self-employment
2020-03-02 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_employed_spell_staging];
GO

/* Create staging */
CREATE VIEW [DL-MAA2021-49].[vacc_employed_spell_staging] AS
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
		,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 3) AS anzsic06_3char
		,COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]) AS anzsic06
		,[ir_ems_pbn_nbr]
		,[ir_ems_enterprise_nbr]
FROM [IDI_Clean_20211020].[ir_clean].[ird_ems] [ir]
WHERE [ir_ems_income_source_code] IN ('W&S', 'WHP')
AND [snz_ird_uid] > 0 -- exclude placeholder person without IRD number
AND [ir_ems_return_period_date] BETWEEN '2020-01-01' AND '2021-12-31';
GO


/* Industry of Employment
Note: Not needed to be condensed as one can have two industries in a spell
*/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_industry];
GO

SELECT DISTINCT snz_uid
	,anzsic06
	,anzsic06_3char
	,[ir_ems_pbn_nbr]
	,[ir_ems_enterprise_nbr]
	,[end_date]
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_industry]
FROM [IDI_UserCode].[DL-MAA2021-49].[vacc_employed_spell_staging]
WHERE anzsic06 IS NOT NULL
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_industry] (snz_uid);
GO

/* Condense spells
Note: required for calculating days emplored as eliminates double counting from multiple jobs
*/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_spell];
GO

WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_UserCode].[DL-MAA2021-49].[vacc_employed_spell_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA2021-49].[vacc_employed_spell_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_UserCode].[DL-MAA2021-49].[vacc_employed_spell_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_UserCode].[DL-MAA2021-49].[vacc_employed_spell_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_spell_20211020]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_employed_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* tidy as finished with view */
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_employed_spell_staging];
GO
