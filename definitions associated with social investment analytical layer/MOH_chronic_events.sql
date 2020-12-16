/**************************************************************************************************
Title: MOH chronic events
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[chronic_condition]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_chronic_events]

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
1) Chronic condition table is not up-to-date for all conditions.

History (reverse order):
2020-10-14 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2016-08-01 WJ: Changed End Date to be either date of death Or WHEN LEFT NZ
2016-07-22 E Walsh: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_chronic_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_chronic_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_chronic_events] AS
SELECT main.snz_uid, 
	'MOH' AS department,
	'TKR' AS datamart, /* the tracker */
	'CCC' AS subject_area, /* the chronic condition code */				
	CAST(moh_chr_fir_incidnt_date AS DATETIME) AS [start_date], /*diagnoses are point in time events*/
	CASE WHEN date_resi IS NOT NULL THEN CAST(date_resi AS DATETIME)
		WHEN date_dead IS NOT NULL THEN CAST(date_dead AS DATETIME)
		ELSE CAST('9999-12-31' AS DATETIME) END AS [end_date], /*END date taken FROM either dod or LEFT nz*/
	moh_chr_condition_text AS event_type,
	moh_chr_collection_text AS event_type_2
FROM [IDI_Clean_20200120].moh_clean.chronic_condition main
LEFT JOIN (	
	SELECT DISTINCT  [snz_uid],
		CAST([pos_applied_date] AS DATETIME) AS date_resi 
	FROM [IDI_Clean_20200120].[data].[person_overseas_spell]
	WHERE pos_last_departure_ind = 'y'
) resi
ON main.snz_uid = resi.snz_uid
LEFT JOIN (
	SELECT DISTINCT [snz_uid],
		DATEFROMPARTS([dia_dth_death_year_nbr], [dia_dth_death_month_nbr], 1) AS date_dead
	FROM [IDI_Clean_20200120].[dia_clean].[deaths]
) dead
ON main.snz_uid = dead.snz_uid
GO
