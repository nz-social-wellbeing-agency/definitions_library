/**************************************************************************************************
Title: Recent enrolment in study
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[moe_clean].[student_enrol] 
- [IDI_Clean].[moe_clean].[targeted_training] 
- [IDI_Clean].[moe_clean].[tec_it_learner] 
- [IDI_Clean].[moe_clean].[course]
- [IDI_Clean].[moe_clean].[student_interventions]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments]

Description:
Enrolment in study when enrolment date is post 1 July 2020

Intended purpose:
Determining who is enrolled in the most recently available data.

Notes:
1) Enrolment type
	1 = primary or secondary schooling
	2 = targeted training
	3 = tec or IT training
	4 = tertiary
	5 = interventions ORRS Ongoing and Reviewable Resourcing Scheme
	6 = interventions HHN Children that are at risk because of serious Health problems

Parameters & Present values:
Current refresh = 20211020
Prefix = vacc_
Project schema = DL-MAA2021-49
Latest enrolment = '2020-07-01'
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (
	snz_uid INT,
	snz_moe_uid INT,
	enroll_type INT,
	provider_code INT,
)
GO

/*******************************
1. Primary and secondary school
*******************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT [snz_uid]
	,snz_moe_uid
	,1 AS enroll_type
	,MAX([moe_esi_provider_code]) AS provider_code
FROM [IDI_Clean_20211020].[moe_clean].[student_enrol] 
WHERE [moe_esi_end_date] IS NULL --the spell is open and there is no leave reason
AND [moe_esi_leave_rsn_code] IS NULL
GROUP BY snz_uid, [snz_moe_uid]
GO

/*******************************
2. Targeted training
*******************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT DISTINCT [snz_uid]
	,snz_moe_uid
	,2 AS enroll_type
	,[moe_ttr_moe_prov_code] AS provider_code
FROM [IDI_Clean_20211020].[moe_clean].[targeted_training] 
WHERE [moe_ttr_placement_end_date] IS NULL
OR [moe_ttr_placement_end_date] >= '2020-07-01'
GO

/*******************************
3. TEC or industry training
*******************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT [snz_uid]
	,snz_moe_uid
	,3 AS enroll_type
	,MAX([moe_itl_edumis_2016_code]) AS provider_code
FROM [IDI_Clean_20211020].[moe_clean].[tec_it_learner] 
WHERE [moe_itl_year_nbr] = 2020
--WHERE [moe_itl_end_date] IS NULL OR [moe_itl_end_date] >= '2020-07-01'
GROUP BY snz_uid, [snz_moe_uid]
GO

/*******************************
4. Tertiary qualification enrollment
*******************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT [snz_uid]
	,[snz_moe_uid]
	,4 AS enroll_type
	,MAX([moe_crs_provider_code]) AS provider_code
	--,MAX([moe_crs_is_domestic_ind]) AS domestic_student
FROM [IDI_Clean_20211020].[moe_clean].[course]
WHERE [moe_crs_year_nbr] = 2020 
GROUP BY snz_uid, [snz_moe_uid]
GO

/*******************************
5. Student interventions
*******************************/
-- [IDI_Adhoc].[clean_read_MOE].[school_intervention_codes]
--Code	Int_Short		Int_Long														IntType
--25	ORRS			Ongoing and Reviewable Resourcing Scheme						Other
--27	High Health		Children that are at risk because of serious Health problems	SpecialEd

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT snz_uid
	,snz_moe_uid
	,5 AS enroll_type
	,NULL AS provider_code
FROM [IDI_Clean_20211020].[moe_clean].[student_interventions]
WHERE [moe_inv_intrvtn_code] = 25 -- ORRS Ongoing and Reviewable Resourcing Scheme
--AND '2020-07-01' BETWEEN moe_inv_start_date AND moe_inv_end_date
GROUP BY snz_uid, snz_moe_uid
GO

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid, snz_moe_uid, enroll_type, provider_code)
SELECT snz_uid
	,snz_moe_uid
	,6 AS enroll_type
	,NULL AS provider_code
FROM [IDI_Clean_20211020].[moe_clean].[student_interventions]
WHERE [moe_inv_intrvtn_code] = 27 -- Children that are at risk because of serious Health problems
--AND '2020-07-01' BETWEEN moe_inv_start_date AND moe_inv_end_date
GROUP BY snz_uid, snz_moe_uid
GO

/*******************************
Index and compress
*******************************/

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_enrollments] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
