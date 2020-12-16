/**************************************************************************************************
Title: CYF client events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[cyf_clean].[cyf_identity_cluster]
- [IDI_Clean].[cyf_clean].[cyf_cec_client_event_cost]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_CYF_client_events]

Description:
Create CYF client events table in SIAL format

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
2017-05-26 V Benny: Changed the subject area to use cyf_cec_business_area_type_code
2016-12-20 K Maxwell: Using only data FROM IDI clean. Previous version used sandpit data (as all data was not available in IDI clean) 
						AND all sandpit records did not have unique ID's. Table now much more simple AND clean.
2016-09-01 Oranaga Tamariki: Business quality assurance complete
2016-07-22 V Benny: created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_CYF_client_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_CYF_client_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_CYF_client_events] AS
SELECT id.snz_uid AS snz_uid
	,cec.snz_uid AS cec_snz_uid
	,'MSD' AS department
	,'CYF' AS datamart
	,cyf_cec_business_area_type_code AS subject_area
	,CAST(cec.cyf_cec_event_start_date AS DATETIME) AS [start_date]
	,CAST(cec.cyf_cec_event_end_date AS DATETIME) AS [end_date]
	,SUM(cec.cyf_cec_direct_gross_amt) AS cost
	,SUM(cec.cyf_cec_indirect_gross_amt) AS cost_2
	,cec.cyf_cec_event_type_text AS event_type
	,cec.cyf_cec_event_type_specific_text AS event_type_2
	,cec.cyf_cec_clients_per_event_nbr AS event_type_3		
FROM [IDI_Clean_20200120].[cyf_clean].[cyf_cec_client_event_cost] cec 
LEFT JOIN (
	SELECT snz_systm_prsn_uid, snz_uid
	FROM [IDI_Clean_20200120].[cyf_clean].[cyf_identity_cluster] 
	WHERE cyf_idc_role_type_text = 'Client'
) id
ON cec.snz_systm_prsn_uid = id.snz_systm_prsn_uid
GROUP BY id.snz_uid, cec.snz_uid, cec.cyf_cec_business_area_type_code, cec.cyf_cec_event_type_text, cec.cyf_cec_event_type_specific_text,
					cec.cyf_cec_event_start_date, cec.cyf_cec_event_end_date, cec.cyf_cec_clients_per_event_nbr;
GO