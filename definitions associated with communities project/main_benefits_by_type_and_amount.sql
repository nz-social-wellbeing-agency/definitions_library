/**************************************************************************************************
Title: Main benefit spell with type and amount
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_first_tier_expenditure]
- [IDI_Sandpit].[clean_read_MSD].[benefit_codes]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_main_benefit_type_and_amount]

Description:
Main benefit receipt spells where a person is the recipient, including
benefit type, daily and total amount.

Intended purpose:
Creating indicators of when/whether a person was receiving a benefit.
Identifying spells when a person is receiving a benefit.
Determining the total amount of benefit received.
Can be subsetted by type and role.
 
Notes:
1) Inspired by SAS code by Marc de Boer & the team at MSD.
   But much simplified as we ignore partnership status (earnings by each partner are separate).
2) As per the MSD data dictionary: Benefit tables in the IDI cover entitlements and
   IRD EMS records dispensing. Differences between these tables can be due to changes
   in entiltements, partial dispensing (e.g. due to automated deductions), and differences
   in timing (weekly/daily vs. monthly).
3) We have not checked for/elimintated overlaps between spells. We assume that if benefit spells
   overlap, then a person was receiving more than one benefit type. As a result, this code risks
   double-counting days if used to determine number of days on benefit.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
 
Issues:
- A very small number of records are duplicates (<0.1%). As de-duplicating is very slow
  these have not been removed.
 
History (reverse order):
2020-05-20 SA updated header
**************************************************************************************************/

USE IDI_UserCode
GO

/* drop before re-creating */
IF OBJECT_ID('[DL-MAA2016-15].[defn_main_benefit_type_and_amount]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_main_benefit_type_and_amount];
GO

/* view for main recipient spells */
CREATE VIEW [DL-MAA2016-15].[defn_main_benefit_type_and_amount] AS
SELECT k.*
	,COALESCE(code.level1, 'unknown') AS level1
	,COALESCE(code.level2, 'unknown') AS level2
	,COALESCE(code.level3, 'unknown') AS level3
	,COALESCE(code.level4, 'unknown') AS level4
	,1.0 * [msd_fte_daily_gross_amt] * DATEDIFF(DAY, [start_date], [end_date]) AS total_amount
FROM (
	SELECT [snz_uid]
		  ,COALESCE([msd_fte_servf_code], 'null') AS [msd_fte_servf_code]
		  ,[msd_fte_start_date] AS [start_date]
		  ,COALESCE([msd_fte_end_date], '9999-01-01') AS [end_date]
		  ,[msd_fte_daily_gross_amt]
	FROM [IDI_Clean_20200120].[msd_clean].[msd_first_tier_expenditure]
	WHERE [msd_fte_start_date] IS NOT NULL
	AND ([msd_fte_end_date] IS NULL
		OR [msd_fte_start_date] <= [msd_fte_end_date])
) k
LEFT JOIN IDI_Sandpit.clean_read_MSD.benefit_codes code
ON k.[msd_fte_servf_code] = code.serv
AND code.ValidFromtxt <= k.[start_date]
AND k.[start_date] <= code.ValidTotxt
GO
