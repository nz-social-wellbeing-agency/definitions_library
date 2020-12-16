/**************************************************************************************************
Title: MOH nir events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_nir_events]

Description:
Create MOH chronic condition events table into SIAL format

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
2020-10-14 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2019-03-01 Peter Holmes: [clean_read_MOH_NIR].[moh_nir_events_dec2015] appears to have moved to [IDI_Clean_20200120] tables
2016-08-01 WJ: Added vaccine dose AND event sub status description
2016-07-22 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_nir_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_nir_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_nir_events] AS
SELECT snz_uid,
	'MOH' AS department,
	'NIR' AS datamart,
	'NIR' AS subject_area,
	CAST([moh_nir_evt_vaccine_date] AS DATETIME) AS [start_date],
	CAST([moh_nir_evt_vaccine_date] AS DATETIME) AS [end_date],
	/*	--x.snz_moh_uid, */
	/*vaccine AS event_type,
	[event_status_description] AS event_type_2,
	[vaccine_dose] AS event_type_3,
	[event_sub_status_description] AS event_type_4*/
	moh_nir_evt_vaccine_text AS event_type,
	[moh_nir_evt_status_desc_text] AS event_type_2,
	[moh_nir_evt_vaccine_dose_nbr] AS event_type_3,
	[moh_nir_evt_sub_status_desc_text] AS event_type_4
FROM (
	SELECT DISTINCT snz_uid
		,snz_moh_uid
		,moh_nir_evt_vaccine_text
		,[moh_nir_evt_vaccine_dose_nbr]
		,[moh_nir_evt_status_desc_text]
		,[moh_nir_evt_sub_status_desc_text]
		,[moh_nir_evt_vaccine_date]
		/*vaccine,
		event_status_description,
		vaccine_dose,
		event_sub_status_description,
		vacination_date*/
	FROM [IDI_Clean_20200120].[moh_clean].[nir_event]
)x
GO
