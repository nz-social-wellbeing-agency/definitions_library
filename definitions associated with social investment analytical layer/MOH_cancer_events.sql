/**************************************************************************************************
Title: MOH cancer events
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[cancer_registrations]
- moh_b4sc_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_cancer_events]

Description:
Create MOH cancer registration events table into SIAL format

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
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode schema in the IDI
2016-07-22 E Walsh: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_cancer_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_cancer_events];
GO

/* cancer registrations */
CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_cancer_events] AS
SELECT snz_uid, 
	'MOH' AS department,
	'CAN' AS datamart,
	'REG' AS subject_area,				
	CAST(moh_can_diagnosis_date AS DATETIME) AS [start_date], /*diagnoses are point in time events*/
	CAST(moh_can_diagnosis_date AS DATETIME) AS [end_date],
	moh_can_site_code AS event_type,
	moh_can_extent_of_disease_code AS event_type_2
FROM [IDI_Clean_20200120].moh_clean.cancer_registrations;
GO