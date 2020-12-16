/**************************************************************************************************
Title: MOH GMS events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[gms_claims]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_gms_events]

Description:
Reformat AND recode General Medical Subsidies data into SIAL format

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
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode Schema in the IDI
2016-07-22 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_gms_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_gms_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_gms_events] AS 
SELECT snz_uid,
	'MOH' AS department,
	'GMS' AS datamart,
	'GMS' AS subject_area,	
	CAST(moh_gms_visit_date AS DATETIME) AS [start_date],
	CAST(moh_gms_visit_date AS DATETIME) AS [end_date],
	SUM(moh_gms_amount_paid_amt) AS cost,
	'GMS' AS event_type
FROM [IDI_Clean_20200120].[moh_clean].[gms_claims]
GROUP BY snz_uid, moh_gms_visit_date
GO