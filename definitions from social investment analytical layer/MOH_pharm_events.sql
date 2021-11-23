/**************************************************************************************************
Title: MOH pharmacy events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].moh_clean.pop_cohort_demographics
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_pharm_events]

Description:
Create MOH pharmaceutical event table in SIAL format

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
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode Schema in the IDI 
2016-07-22 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_pharm_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_pharm_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_pharm_events] AS
SELECT snz_uid, 
		'MOH' AS department,
		'PHA' AS datamart,
		'PHA' AS subject_area,				
		CAST(moh_pha_dispensed_date AS DATETIME) AS [start_date],
		CAST(moh_pha_dispensed_date AS DATETIME) AS [end_date],
		SUM(moh_pha_remimburs_cost_exc_gst_amt) AS cost,
		CAST('DISPENSE' AS varchar(10)) AS event_type,
		snz_moh_provider_uid AS entity_id
FROM (
	SELECT DISTINCT *
	FROM [IDI_Clean_20200120].moh_clean.pharmaceutical
) pharm /*Remove exact row duplicates from table */
GROUP BY snz_uid, 
		snz_moh_uid, 
		moh_pha_dispensed_date,
		snz_moh_provider_uid
GO		
