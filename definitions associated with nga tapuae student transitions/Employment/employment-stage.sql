/**************************************************************************************************
Title: Spell of employment
Author: Simon Anastasiadis
Modified for NT by JB: Notice being subjected to pop1/pop2 compared to overall view due to performance issues

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell]

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
  Prefix = $(TBLPREF)
  Project schema = $(PROJSCH)
  {Earliest start date = '2014-01-01'
  Latest end date = '2020-12-31'} -- not needed
 
Issues:
- Does not capture all self-employment. Use of annual tax year data is recommended for analyses at
  annual resolution, or where it is important to capture self-employment.
 
History (reverse order):
2020-07-15 JB parameterise
2020-07-09 JB Notice being subjected to pop1/pop2 compared to overall view due to performance issues
2020-07-01 SA expanded definition of employment to include WHP as this covers some self-employment
2020-03-02 SA v1
**************************************************************************************************/
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)employed_spell_staging]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)employed_spell_staging];
GO

/* Create staging */
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)employed_spell_staging] AS
SELECT [ir].snz_uid
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
		,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 1) AS anzsic06
FROM [$(IDIREF)].[ir_clean].[ird_ems] [ir]
inner join [$(PROJSCH)].[$(TBLPREF)child_parent_union] [pop]
on [ir].[snz_uid]=[pop].[snz_uid]
WHERE [ir_ems_income_source_code] IN ('W&S', 'WHP')
AND [snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
--AND [ir_ems_return_period_date] BETWEEN '2014-01-01' AND '2020-12-31';
GO

/*
Variable Ref 7, 80
EVENT: Industry of Employment
Revised by JB
Note: Not needed to be condensed (?) as one can have two industries in a spell
*/

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_industry]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_industry];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_industry] AS
SELECT snz_uid
,k.[start_date] AS [start_date]
,k.[end_date] AS [end_date]
,'Industry: '+ [descriptor_text] AS [description]
,1 AS [value]
,'ird ems anzsic06' AS [source]
FROM [$(PROJSCH)].[$(TBLPREF)employed_spell_staging] k
	INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_ANZSIC06] b
	ON k.anzsic06 = b.[cat_code]
	WHERE anzsic06 IS NOT NULL;
GO

/* Condensed spells */
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell];
GO

WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_UserCode].[$(PROJSCH)].[$(TBLPREF)employed_spell_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_UserCode].[$(PROJSCH)].[$(TBLPREF)employed_spell_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_UserCode].[$(PROJSCH)].[$(TBLPREF)employed_spell_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_UserCode].[$(PROJSCH)].[$(TBLPREF)employed_spell_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* DO NOT Clear staging view -- used for industry */
/*
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)employed_spell_staging]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)employed_spell_staging];
GO
*/

