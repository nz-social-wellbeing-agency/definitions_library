/**************************************************************************************************
Title: MSD Tier 2 events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MSD_T2_events]

Description:
Create MSD Second Tier Benefit costs events table

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]

Issues:

History (reverse order):
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2017-11-30 EW: removed working for families as that is now captured in the IRD table
2016-10-01 MSD: Business QA complete
2016-09-14 V Benny: Changed the daily costs into a lumpsum costs: lumpsum_cost = dailycost * (end_date - start_date + 1)
2016-07-22 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MSD_T2_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MSD_T2_events];
GO

/* Get the MSD tier 2 benefits per individual per supplementary benefit type */
CREATE VIEW [DL-MAA2016-15].[sial_MSD_T2_events] AS
SELECT 
	snz_uid,
	'MSD' AS department,
	'BEN' AS datamart,
	'T2' AS subject_area,
	CAST([msd_ste_start_date] AS DATETIME) AS [start_date],
	CAST([msd_ste_end_date] AS DATETIME) AS end_date, 
	[msd_ste_daily_gross_amt] * (1 + DATEDIFF(DAY, CAST([msd_ste_start_date] AS DATETIME), CAST([msd_ste_end_date] AS DATETIME)) ) AS cost,
	[msd_ste_supp_serv_code] AS event_type,
	[msd_ste_srvst_code] AS event_type_2
FROM (
	SELECT 
		[snz_uid], 
		[msd_ste_supp_serv_code], 
		[msd_ste_srvst_code],
		[msd_ste_start_date],
		[msd_ste_end_date],
		SUM([msd_ste_daily_gross_amt]) AS [msd_ste_daily_gross_amt]
	FROM [IDI_Clean_20200120].[msd_clean].[msd_second_tier_expenditure]
	WHERE msd_ste_supp_serv_code != '064'
	GROUP BY [snz_uid], 
		[msd_ste_supp_serv_code], 
		[msd_ste_srvst_code],
		[msd_ste_start_date],
		[msd_ste_end_date] 
)x
GO
