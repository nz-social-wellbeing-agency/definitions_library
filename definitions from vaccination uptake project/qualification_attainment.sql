/**************************************************************************************************
Title: Highest qualification
Author: Joel Bancolita, Marianna Pekar

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[moe_clean].[student_qualification]
- [IDI_Clean].[moe_clean].[completion]
- [IDI_Clean].[moe_clean].[tec_it_learner]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_qualification_awards]

Description:
Qualification attainment

Intended purpose:
Identifying graduation and highest qualification.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-09-01: MP revised measures and parameters, extract measures relevant to vaccine rollout analysis
2020-08-20: JB additional revised measures
2020-08-08: JB additional revised measures
2020-07-08: JB additional revised measures
2020-06-24: JB revised initial measures
2020-06-09: JB initialise
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_qualification_awards];
GO

/*
00 No Qualification
01 Level 1 Certificate
02 Level 2 Certificate
03 Level 3 Certificate
04 Level 4 Certificate
05 Level 5 Diploma
06 Level 6 Diploma
07 Bachelor Degree and Level 7 Qualification
08 Post-graduate and Honours Degrees
09 Masters Degrees
10 Doctorate Degree
11 Overseas Secondary School Qualification
97 Response Unidentifiable
99 Not Specified 
*/
SELECT DISTINCT snz_uid
	,[event_date]
	,[qualification_level]
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_qualification_awards]
FROM (
	SELECT [snz_uid]
		,'2018-03-08' AS [event_date]
		,CAST([cen_ind_standard_hst_qual_code] AS INT) AS [qualification_level]
		--,'cen2018' AS [source]
	FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2018]
	
	UNION ALL
	
	-- Census 2013 secondary school qualification
	SELECT [snz_uid]
		,DATEFROMPARTS([cen_ind_birth_year_nbr] + 18, 12, 1) AS [event_date]
		,CAST(cen_ind_sndry_scl_qual_code AS INT) AS [qualification_level]
		--,'cen2013' AS [source]
	FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2013]
	WHERE cen_ind_sndry_scl_qual_code IN ('01','02','03')
	
	UNION ALL
	
	-- Census 2013 highest qualification
	SELECT [snz_uid]
		,'2013-03-05' AS [event_date]
		,CAST(cen_ind_std_highest_qual_code AS INT) AS [qualification_level]
		--,'cen2013' AS [source]
	FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2013]
	WHERE cen_ind_std_highest_qual_code IN ('01','02','03','04','05','06','07','08','09','10')
		AND cen_ind_std_highest_qual_code <> cen_ind_sndry_scl_qual_code
		AND [cen_ind_birth_year_nbr] + 18 >= 2013 -- must be at least 18 when earned post-school qualification
	
	UNION ALL
	
	-- Primary and secondary
	SELECT snz_uid
		,DATEFROMPARTS(moe_sql_attained_year_nbr, 12, 1) AS [event_date]
		,moe_sql_nqf_level_code AS [qualification_level]
		--,'moe primary/secondary' AS [source]
	FROM [IDI_Clean_20211020].[moe_clean].[student_qualification]
	WHERE moe_sql_nqf_level_code IS NOT NULL
	AND moe_sql_nqf_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF
	
	UNION ALL
	
	-- Tertiary qualification
	SELECT snz_uid
		,DATEFROMPARTS(moe_com_year_nbr, 12, 1) AS [event_date]
		,moe_com_qual_level_code AS [qualification_level]
		--,'moe tertiary' AS [source]
	FROM [IDI_Clean_20211020].[moe_clean].[completion]
	WHERE moe_com_qual_level_code IS NOT NULL
	AND moe_com_qual_level_code IN (1,2,3,4,5,6,7,8,9,10) -- limit to 10 levels of NZQF
	
	UNION ALL
	
	-- Industry training qualifications
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,1 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level1_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,2 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level2_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,3 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level3_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,4 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level4_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,5 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level5_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,6 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level6_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,7 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level7_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,8 AS [qualification_level]
		--,'tec industry' AS [source]
	FROM [IDI_Clean_20211020].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level8_qual_awarded_nbr > 0
) qual
WHERE [qualification_level] IS NOT NULL
AND [qualification_level] NOT IN (97, 99)
GO

/* index and compress */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_qualification_awards] (snz_uid)
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_qualification_awards] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
