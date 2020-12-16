/**************************************************************************************************
Title: HNZC Registration events
Author: Wen Jhe Lee

Inputs & Dependencies:
- [IDI_Clean].[hnz_clean].[new_applications_household]
- [IDI_Clean].[hnz_clean].[new_applications]
- [IDI_Clean].[hnz_clean].[transfer_applications_household]
- [IDI_Clean].[hnz_clean].[transfer_applications]
- [IDI_Clean].[hnz_clean].[register_exit]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_HNZ_register_events]

Description:
Create the event table of new applications
AND transfers for social housing by application AND snz_uid

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) Each row is per application for each snz_uid

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]

Issues:

History (reverse order):
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2017-06-15 WL: Changed to LEFT JOIN as was excluding in registar applications
2017-05-18 CM: Minor formatting changes
2017-05-18 VB: Formatting changes, VIEW name change
2017-04-28 WL: v1
2016-04-28 Wen Jhe Lee: created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_HNZ_register_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_HNZ_register_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_HNZ_register_events] AS
WITH
/* sub-definition of new applications */
new_application AS (
	SELECT								
		CAST(newapp.hnz_na_date_of_application_date AS DATETIME) AS [start_date]
		,CAST(reg.hnz_re_exit_date AS DATETIME) AS end_date1
		,newapp_hh.snz_application_uid
		,newapp_hh.snz_legacy_application_uid
		,newapp_hh.snz_uid
		,'NEW APP' AS [type]
		,reg.hnz_re_exit_status_text AS end_status
		,newapp.hnz_na_analysis_total_score_text AS total_score
		,newapp.hnz_na_main_reason_app_text AS main_reason	
	FROM (
		SELECT DISTINCT 
			snz_application_uid,
			snz_legacy_application_uid,
			snz_uid
		FROM [IDI_Clean_20200120].[hnz_clean].[new_applications_household]
	) newapp_hh	
	INNER JOIN [IDI_Clean_20200120].[hnz_clean].[new_applications] newapp
	ON COALESCE(newapp_hh.snz_application_uid, newapp_hh.snz_legacy_application_uid) = COALESCE(newapp.snz_application_uid, newapp.snz_legacy_application_uid)
	LEFT JOIN [IDI_Clean_20200120].[hnz_clean].[register_exit] reg	
	ON COALESCE(newapp_hh.snz_application_uid, newapp_hh.snz_legacy_application_uid) = COALESCE(reg.snz_application_uid, reg.snz_legacy_application_uid)
),
/* sub-definition of transfer applications */
transfer_applications AS (
	SELECT
		CAST(tfapp.hnz_ta_application_date AS DATETIME) AS start_date
		,CAST(reg.hnz_re_exit_date AS DATETIME) AS end_date1
		,tfapp_hh.snz_application_uid
		,tfapp_hh.snz_legacy_application_uid
		,tfapp_hh.snz_uid
		,'TRANSFER' AS [type]
		,reg.hnz_re_exit_status_text AS end_status
		,tfapp.hnz_ta_analysis_total_score_text AS total_score
		,tfapp.hnz_ta_main_reason_app_text AS main_reason
	FROM (
		SELECT DISTINCT 
			snz_application_uid,
			snz_legacy_application_uid,
			snz_uid
		 FROM [IDI_Clean_20200120].[hnz_clean].[transfer_applications_household]
	) tfapp_hh
	INNER JOIN [IDI_Clean_20200120].[hnz_clean].[transfer_applications] tfapp	
	ON COALESCE(tfapp_hh.snz_application_uid, tfapp_hh.snz_legacy_application_uid) = COALESCE(tfapp.snz_application_uid, tfapp.snz_legacy_application_uid)
	LEFT JOIN [IDI_Clean_20200120].[hnz_clean].[register_exit] reg	
	ON COALESCE(tfapp_hh.snz_application_uid, tfapp_hh.snz_legacy_application_uid) = COALESCE(reg.snz_application_uid, reg.snz_legacy_application_uid)
)
/* view combines new and transfer applications */ 
SELECT snz_uid
	,snz_application_uid
	,snz_legacy_application_uid
	,'HNZ' AS department
	,'REG' AS datamart
	,'REG' AS subject_area
	,[start_date]
	,COALESCE(end_date1, CAST('9999-12-31' AS DATETIME)) AS end_date /* max end date as still in register as of Aug 2015 */
	,[type] AS event_type /* whether New Application Or Transfer */
	,COALESCE(end_status, 'IN REGISTR') AS event_type_2 /*exit status*/
	,total_score AS event_type_3 /*score during assessment*/
	,main_reason AS event_type_4 /* reason for transfer or housing application*/
FROM (
	SELECT * FROM new_application
	UNION ALL
	SELECT * FROM transfer_applications
) full_table
GO
