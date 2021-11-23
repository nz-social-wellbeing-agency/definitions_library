/**************************************************************************************************
Title: Mixed-source mortality events
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[mortality_registrations]
- [IDI_Clean].[dia_clean].[deaths]

Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MIX_mortality_events]

Description:
Standardised SIAL events table for the MOH AND DIA based mortality dataset

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
2019-06-01 Peter Holmes: Views how have to be created in the IDI_UserCode schema in the IDI
2017-05-18 EW: rewrote to handle new MOH tables
2016-10-04 E Walsh: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MIX_mortality_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MIX_mortality_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MIX_mortality_events] AS

SELECT snz_uid,
	'MIX' AS department,
	'MOR' AS datamart,
	'MOR' AS subject_area,
	CAST(DATEFROMPARTS(moh_mor_death_year_nbr, moh_mor_death_month_nbr, 1) AS DATETIME) AS [start_date],
	CAST(DATEFROMPARTS(moh_mor_death_year_nbr, moh_mor_death_month_nbr, 1) AS DATETIME) AS [end_date],
	moh_mor_icd_d_code AS event_type,
	moh_mor_death_year_nbr - moh_mor_birth_year_nbr AS event_type_2,
	'MOH' AS event_type_3
FROM [IDI_Clean_20200120].[moh_clean].[mortality_registrations]

UNION ALL

SELECT [snz_uid],
	'MIX' AS department,
	'MOR' AS datamart,
	'MOR' AS subject_area,
	CAST(DATEFROMPARTS(dia_dth_death_year_nbr, dia_dth_death_month_nbr, 1) AS DATETIME) AS [start_date],
	CAST(DATEFROMPARTS(dia_dth_death_year_nbr, dia_dth_death_month_nbr, 1) AS DATETIME) AS [end_date],
	NULL AS event_type, 
	/* PNH we can get age at death (event_type2) FROM DIA table) */
	dia_dth_death_year_nbr - dia_dth_birth_year_nbr AS event_type_2,
	'DIA' AS event_type_3
FROM [IDI_Clean_20200120].[dia_clean].[deaths]
WHERE [dia_dth_death_year_nbr] > ( SELECT MAX(moh_mor_death_year_nbr) FROM [IDI_Clean_20200120].[moh_clean].[mortality_registrations] )
GO