/**************************************************************************************************
Title: Police offender events
Author: K Maxwell

Inputs & Dependencies:
- [IDI_Clean].[pol_clean].[pre_count_offenders]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_POL_offender_events]

Description:
Reformat AND recode Police offenders data into SIAL format

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
2017-03-03 K Maxwell: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_POL_offender_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_POL_offender_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_POL_offender_events] AS
SELECT  snz_uid, /* This is the incident occurance ID */
	'POL' AS department,
	'OFF' AS datamart,
	'OFF' AS subject_area,			
	CAST(pol_pro_proceeding_date AS DATETIME) AS [start_date],
	CAST(pol_pro_proceeding_date AS DATETIME) AS end_date,
	CASE WHEN pol_pro_offence_inv_ind = 1 THEN 'Investigated' ELSE 'Not investigated' END AS event_type,
	pol_pro_anzsoc_offence_code AS event_type_2, /*Type of offence */
	CASE WHEN pol_pro_rov_code = '2000' THEN 'Stranger' 
		WHEN pol_pro_rov_code IN ('4000', '8000', '9999') THEN 'Other/NA'
		ELSE 'Known' END AS event_type_3, /* Relationship of offender to victim */
	snz_pol_occurrence_uid AS event_type_4,
	snz_pol_offence_uid AS event_type_5 /* This is the offence occurance ID, can have multiple offences per occurrence */
FROM [IDI_Clean_20200120].[pol_clean].[pre_count_offenders]
WHERE snz_pol_occurrence_uid != 1    /* When snz_pol_occurrence_uid = 1 AND pol_pro_offence_inv_ind = 0 recoreds are incomplete, so excluding */
AND pol_pro_offence_inv_ind != 0 /* Note there are none of these records, just future proofing */
GO
