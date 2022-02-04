/**************************************************************************************************
Title: Census 2018 household
Author:  Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_household]

Description:
List of snz_uid, dwell_uid, and child indicator for census 2018.

Intended purpose:
Producing summary statistics for household.

Notes:
1. [cen_ind_record_type_code] records the individual record type for census night. 
	This varaible gives the information about whether the individaul is adult or child.
	3 – NZ Adult 
	4 – NZ child 
	5 – Overseas Adult
	6 – Overseas Child 
	7 – Absentee elsewhere in NZ or away < 12 months Adult 
	8 – Absentee elsewhere in NZ or away < 12 months Child 
	9 – Absentee away >= 12 months 

Issues:


Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Custom 'as-at' date = '2020-09-30'
 
History (reverse order):
2021_02-02 FL v2 Notes added, replace [cn_snz_cen_dwell_uid] to [ur_snz_cen_dwell_uid]
2021-01-26 SA QA
2021-01-21 FL v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_household]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_household];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_household] AS
SELECT snz_uid
	  ,ur_snz_cen_dwell_uid -- Dwelling ID for census night
	  ,IIF(cen_ind_record_type_code = 4 OR cen_ind_record_type_code = 6 OR cen_ind_record_type_code = 8 ,1, 0) AS child_ind_census_night -- child indicator on census night
	  -- 4 – NZ child, 6 – Overseas Child, 8 – Absentee elsewhere in NZ or away < 12 months (Child) 
	  ,IIF(DATEDIFF(MONTH, DATEFROMPARTS(cen_ind_birth_year_nbr, cen_ind_birth_month_nbr,1), '2020-09-30') <= 12*18, 1, 0) AS child_ind_custom_date -- child indicator at 2020-09-30
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2018]
WHERE ur_snz_cen_dwell_uid IS NOT NULL
GO
