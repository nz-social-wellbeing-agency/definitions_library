/**************************************************************************************************
Title: MSD Tier 3 events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MSD_T3_events]

Description:
Create MSD Third Tier Benefit costs events table

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
2016-10-01 MSD: Business QA complete
2016-07-30 V Benny: Changed the datatype of start and end dates into datetime to be consistent across all tables written into SQL from SAS
2016-07-22 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MSD_T3_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MSD_T3_events];
GO

/* Get the MSD tier 3 benefits per individual per supplementary benefit type */
CREATE VIEW [DL-MAA2016-15].[sial_MSD_T3_events] AS
SELECT 
	snz_uid, 
	'MSD' AS department,
	'BEN' AS datamart,
	'T3' AS subject_area,
	CAST(msd_tte_decision_date AS DATETIME) AS [start_date],
	CAST(msd_tte_decision_date AS DATETIME) AS [end_date], 
	[msd_tte_pmt_amt] AS cost,
	[msd_tte_lump_sum_svc_code] AS event_type,
	[msd_tte_recoverable_ind] AS event_type_2
FROM (
	SELECT 
		snz_uid
		,msd_tte_decision_date
		,[msd_tte_lump_sum_svc_code]
		,[msd_tte_recoverable_ind]
		,SUM([msd_tte_pmt_amt]) AS [msd_tte_pmt_amt]
	FROM [IDI_Clean_20200120].msd_clean.msd_third_tier_expenditure
	GROUP BY snz_uid, 
		msd_tte_decision_date, 
		[msd_tte_lump_sum_svc_code], 
		[msd_tte_recoverable_ind]
)x
GO
