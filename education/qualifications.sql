/**************************************************************************************************
Title: Attainment of qualification
Author: Simon Anastasiadis
Re-edit: Freya Li

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Disclaimer:
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the 
context of a specific project. Whether or not these definitions are suitable for other projects depends on the 
context of those projects. Researchers using definitions from this library will need to determine for themselves 
to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides 
this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

Citation:
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

Description:
Attainment of qualification (or our best approximation of).

Intended purpose:
1. Identifying people's highest qualification at a point in time.
2. Identifying when people have been awared qualifications (requires removal of Census data).

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[moe_clean].[student_qualification]
- [IDI_Clean].[moe_clean].[completion]
- [IDI_Clean].[moe_clean].[tec_it_learner]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_qualification_awards]

 
Notes:
1) Where only year is available assumed qualification awarded 1st December (approx, end of calendar year).

2) Code guided by Population Explorer Highest Qualification code in SNZ Population Explorer by Peter Elis
	github.com/StatisticsNZ/population-explorer/blob/master/build-db/01-int-tables/18-qualificiations.sql

3) Qualification data is collected from a range of places
	- Tertiary qualifications are reported to TEC as part of funding and oversight
	- Secondary school qualifications are reported for school leavers
	- All qualifications covered by NZQF (including secondary and tertiary) are reported to NZQA
	Hence a single qualification event can appear multiple times within our data. We have aimed for
	breadth of coverage and have not attempted to resolve duplicates.

4) Qualifications reported from Census 2013 & Census 2018 have been added, as without only qualifications
	earned recently within New Zealander are reported which results in an under count. As Census does not
	report date of award/qualification we use December in 18th year of life as proxy for award date of 
	secondary school degrees, and date of Census 2013 as proxy for aware of post-secondary school degrees.

5) School leavers qualifications are reported for the highest qualification earned prior to leaving school.
	Much more detail is available than only reporting NQF levels. These have been grouped to comparitive
	NCEA levels. For example:
		1-13 credits at level 3    -->    highest completed qualification is level 2    -->    level 2
		International Baccalaureate Year 12    -->    level 2    as level 2 is typically completed in year 12

6) Numeric values are NZQA levels:
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
	International qualifications are often classified as 11. However, where we can not identify their
	equivalent NZQA level, these have been excluded.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
Issues:

History (reverse order):
2022-10-11 SA update with school leavers
2021-01-26 SA QA
2021-01-08 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_qualification_awards];
GO

CREATE VIEW [DL-MAA20XX-YY].[defn_qualification_awards] AS

-- Census 2018 secondary school qualification
SELECT [snz_uid]
	,DATEFROMPARTS(cen_ind_birth_year_nbr + 18, 12, 1) AS [event_date]
	,[cen_ind_scdry_scl_qual_code] AS [qualification_level]
	,'cen2018' AS [source]
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2018]
WHERE [cen_ind_scdry_scl_qual_code] IN ('01', '02', '03')

UNION ALL

-- Census 2018 highest qualification
SELECT [snz_uid]
      ,'2018-03-08' AS [event_date]
      ,[cen_ind_standard_hst_qual_code] AS [qualification_level]
      ,'cen2018' AS [source]
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2018]
WHERE [cen_ind_standard_hst_qual_code] IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10')
AND [cen_ind_standard_hst_qual_code] <> [cen_ind_scdry_scl_qual_code]

UNION ALL

-- Census 2013 secondary school qualification
SELECT [snz_uid]
	,DATEFROMPARTS([cen_ind_birth_year_nbr] + 18, 12, 1) AS [event_date]
	,cen_ind_sndry_scl_qual_code AS [qualification_level]
	,'cen2013' AS [source]
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2013]
WHERE cen_ind_sndry_scl_qual_code IN ('01', '02', '03')

UNION ALL

-- Census 2013 highest qualification
SELECT [snz_uid]
	,'2013-03-05' AS [event_date]
	,cen_ind_std_highest_qual_code AS [qualification_level]
	,'cen2013' AS [source]
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2013]
WHERE cen_ind_std_highest_qual_code IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10')
AND cen_ind_std_highest_qual_code <> cen_ind_sndry_scl_qual_code

UNION ALL

-- NZQA (Covers Secondary and Tertiary)
SELECT snz_uid
		,DATEFROMPARTS(moe_sql_attained_year_nbr,12,1) AS [event_date]
		,moe_sql_nqf_level_code AS [qualification_level]
		,'nzqa' AS [source]
FROM [IDI_Clean_YYYYMM].[moe_clean].[student_qualification]
WHERE moe_sql_nqf_level_code IS NOT NULL
AND moe_sql_nqf_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF

UNION ALL

-- Secondary via school leavers
SELECT [snz_uid]
		,DATEFROMPARTS([moe_sl_leaver_year], 12, 1) AS [event_date]
      --,[moe_sl_leaver_year]
      --,[moe_sl_leaving_yr_lvl]
      --,[moe_sl_leaving_reason_code]
      --,[moe_sl_highest_attain_code]
	  ,CASE
		WHEN [moe_sl_highest_attain_code] IN (13, 14, 15, 16, 17, 20, 55, 60, 70, 80, 90) THEN 1
		WHEN [moe_sl_highest_attain_code] IN ( 4, 24, 25, 26, 27, 30, 56, 61, 71, 81, 91) THEN 2
		WHEN [moe_sl_highest_attain_code] IN (33, 34, 35, 36, 37, 40, 43, 62, 72, 82, 92) THEN 3
		ELSE NULL END AS [qualification_level]
	,'leavers' AS [source]
FROM [IDI_Clean_YYYYMM].[moe_clean].[student_leavers]
WHERE [moe_sl_eligibility_code] = 'DOMESTIC'
AND [moe_sl_leaving_yr_lvl] BETWEEN 12 AND 16
AND (
	[moe_sl_highest_attain_code] IN (13, 14, 15, 16, 17, 20, 55, 60, 70, 80, 90)
	OR [moe_sl_highest_attain_code] IN ( 4, 24, 25, 26, 27, 30, 56, 61, 71, 81, 91)
	OR [moe_sl_highest_attain_code] IN (33, 34, 35, 36, 37, 40, 43, 62, 72, 82, 92)
)

UNION ALL

-- Tertiary qualification
SELECT snz_uid
		,DATEFROMPARTS(moe_com_year_nbr,12,1) AS [event_date]
		,moe_com_qual_level_code AS [qualification_level]
		,'tertiary' AS [source]
FROM [IDI_Clean_YYYYMM].[moe_clean].[completion]
WHERE moe_com_qual_level_code IS NOT NULL
AND moe_com_qual_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF

UNION ALL

-- Industry training qualifications
SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,1 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level1_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,2 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level2_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,3 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level3_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,4 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level4_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,5 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level5_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,6 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level6_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,7 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level7_qual_awarded_nbr > 0

UNION ALL

SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,8 AS [qualification_level]
		,'industry' AS [source]
FROM [IDI_Clean_YYYYMM].moe_clean.tec_it_learner
WHERE moe_itl_end_date IS NOT NULL
AND moe_itl_level8_qual_awarded_nbr > 0;
GO

