/**************************************************************************************************
Title: CYF Abuse findings events
Author: K Maxwell

Inputs & Dependencies:
- [IDI_Clean].[cyf_clean].[cyf_abuse_event]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_CYF_abuse_events]

Description:
Reformat and recode CYF abuse data into SIAL format

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
2016-10-01 Oranaga Tamariki: Business quality assurance complete
2016-07-22 K Maxwell: created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_CYF_abuse_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_CYF_abuse_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_CYF_abuse_events] AS
SELECT DISTINCT snz_uid
	,'MSD' AS department
	,'CYF' AS datamart
	,'ABE' AS subject_area		
	,MAX(CAST(cyf_abe_event_from_date_wid_date AS DATETIME)) AS [start_date]
	,MAX(CAST(cyf_abe_event_to_date_wid_date AS DATETIME)) AS [end_date]
	/* event_type needs to stay as this variable with 3 digit codes as it is a dependency for the MIX_selfharm_events SIAL table */
	,MAX(CASE WHEN cyf_abe_source_uk_var2_text in ('**OTHER**', 'UNK', 'XXX') THEN 'UNK' 
		WHEN cyf_abe_source_uk_var2_text = 'BRD'  THEN 'BRD'
		WHEN cyf_abe_source_uk_var2_text = 'EMO'  THEN 'EMO'
		WHEN cyf_abe_source_uk_var2_text = 'NEG'  THEN 'NEG'
		WHEN cyf_abe_source_uk_var2_text = 'PHY'  THEN 'PHY'
		WHEN cyf_abe_source_uk_var2_text = 'SEX'  THEN 'SEX'
		/* addition of not found into a separate category as it means there is not enough evidence for a finding of abuse */
		WHEN cyf_abe_source_uk_var2_text = 'NTF'  THEN 'NTF'
		WHEN cyf_abe_source_uk_var2_text in ('SHM', 'SHS', 'SUC') THEN 'SHS'
		ELSE 'Not coded' end) AS event_type
FROM [IDI_Clean_20200120].[cyf_clean].[cyf_abuse_event]
WHERE cyf_abe_event_type_wid_nbr = 12  /*This indicates an abuse finding */
GROUP BY snz_uid, snz_composite_event_uid;
GO
