/**************************************************************************************************
Title: Attainment of qualification
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual]
- [IDI_Clean].[moe_clean].[student_qualification]
- [IDI_Clean].[moe_clean].[completion]
- [IDI_Clean].[moe_clean].[tec_it_learner]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_qualification_awards]

Description:
Attainment of qualification (or our best approximation of).


Intended purpose:
Identifying people's highest qualification at a point in time.
Identifying when people have been awared qualifications (requires removal of Census data).
 
Notes:
1) Where only year is available assumed qualification awarded 1st December (approx, end of calendar year).
2) Code guided by Population Explorer Highest Qualification code in SNZ Population Explorer by Peter Elis
   github.com/StatisticsNZ/population-explorer/blob/master/build-db/01-int-tables/18-qualificiations.sql
3) Qualifications reported from Census 2013 have been added, as without only qualifications earned recently
   are reported which results in an under count. As Census does not report date of award/qualification
   we use December in 18th year of life as proxy for award date of secondary school degrees, and 
   date of Census 2013 as proxy for aware of post-secondary school degrees.
   The same process has been followed for Census 2018.
4) Numeric values are NZQA levels:
	1 = Certificate or NCEA level 1
	2 = Certificate or NCEA level 2
	3 = Certificate or NCEA level 3
	4 = Certificate level 4
	5 = Certificate of diploma level 5
	6 = Certificate or diploma level 6
	7 = Bachelors degree, graduate diploma or certificate level 7
	8 = Bachelors honours degree or postgraduate diploma or certificate level 8
	9 = Masters degree
	10 = Doctoral degree
5) International qualifications are often classified as 11. However, as we struggle to identify their
   equivalent NZQA level, these have been excluded.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
 
Issues:

History (reverse order):
2021_01-26 SA QA
2021-01-08 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_qualification_awards]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_qualification_awards];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_qualification_awards] AS

-- Census 2018 secondary school qualification
SELECT [snz_uid]
	,DATEFROMPARTS(cen_ind_birth_year_nbr + 18, 12, 1) AS [event_date]
	,[cen_ind_scdry_scl_qual_code] AS [qualification_level]
	,'cen2018' AS [source]
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2018]
WHERE [cen_ind_scdry_scl_qual_code] IN ('01', '02', '03')

UNION ALL

-- Census 2018 highest qualification
SELECT [snz_uid]
	  ,'2018-03-08' AS [event_date]
      ,[cen_ind_standard_hst_qual_code] AS [qualification_level]
	  ,'cen2018' AS [source]
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2018]
WHERE [cen_ind_standard_hst_qual_code] IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10')
AND [cen_ind_standard_hst_qual_code] <> [cen_ind_scdry_scl_qual_code]

UNION ALL

-- Census 2013 secondary school qualification
SELECT [snz_uid]
	,DATEFROMPARTS([cen_ind_birth_year_nbr] + 18, 12, 1) AS [event_date]
	,cen_ind_sndry_scl_qual_code AS [qualification_level]
	,'cen2013' AS [source]
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2013]
WHERE cen_ind_sndry_scl_qual_code IN ('01', '02', '03')

UNION ALL

-- Census 2013 highest qualification
SELECT [snz_uid]
	,'2013-03-05' AS [event_date]
	,cen_ind_std_highest_qual_code AS [qualification_level]
	,'cen2013' AS [source]
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2013]
WHERE cen_ind_std_highest_qual_code IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10')
AND cen_ind_std_highest_qual_code <> cen_ind_sndry_scl_qual_code

UNION ALL

-- Primary and secondary
SELECT snz_uid
		,DATEFROMPARTS(moe_sql_attained_year_nbr,12,1) AS [event_date]
		,moe_sql_nqf_level_code AS [qualification_level]
		,'second' AS [source]
FROM [IDI_Clean_20201020].[moe_clean].[student_qualification]
WHERE moe_sql_nqf_level_code IS NOT NULL
AND moe_sql_nqf_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF

UNION ALL

-- Tertiary qualification
SELECT snz_uid
		,DATEFROMPARTS(moe_com_year_nbr,12,1) AS [event_date]
		,moe_com_qual_level_code AS [qualification_level]
		,'tertiary' AS [source]
FROM [IDI_Clean_20201020].[moe_clean].[completion]
WHERE moe_com_qual_level_code IS NOT NULL
AND moe_com_qual_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF

UNION ALL

-- Industry training qualifications
SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,1 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level1_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,2 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level2_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,3 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level3_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,4 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level4_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,5 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level5_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,6 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level6_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,7 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level7_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,8 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_20201020].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level8_qual_awarded_nbr > 0;
GO

