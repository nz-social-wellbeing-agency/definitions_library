/**************************************************************************************************
Title: Functional disability
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions
Shari Mason provided comments on the definition.

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_support_needs_2022]
- [IDI_Clean].[security].[concordance]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assesment_2022]
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Adhoc].[clean_read_HLFS].[hlfs_disability]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[gss_clean].[gss_person]
Outputs:
- [IDI_UserCode].[DL-MAA2018-48].[defn_functional_disability]

Description:
Multi-source indicator of functional disability

Intended purpose:
Identifying occupation of individuals at Census 2018, or the broad type of
work / skills beyond Census 2018.

Notes:
1) Multiple sources are used:
	1. Y Census 2018 WGSS
	2. Y SOCRATES assessment
	3. Y InterRAI assessment
	4. Y HLFS
	5. Y GSS

2) We still need to include the WGSS from the NZCVS and from the recent HES (2020?)
	These will make only a small difference to the results because the sample size
	of both surveys is limited.

3) We investigated using Hospital diagnoses and ACC records. But the steering
	group advised against their inclusion. Reference code is provided below
	(commented out) as reference for future researchers.

4) There are different ways of coding disability.
	- Effective Teaching and Learning (ETL) uses three levels:
		0=None, 1=High, 2=Very High
	- Washington Group Short Set (WGSS) uses 4 levels:
		1=None, 2=Low, 3=High, 4=Complete
	We combine these as follows:
		ETL=0 & WGSS=1
		ETL=1 & WGSS=2
		ETL=2 & WGSS=3 or 4

5) When working with SOCRATES code (funded_moh_disability and functional_disability):
	- Unless you want to know about all historic clients, for most purposes it will
		make sense to focus on active clients. This involves filtering for active clients
		and current search history (where start and end dates include today).
		Client status: Active = currently receiving funding,
		Client status: Inactive = no longer receiving funding or deceased.
	- SOCRATES does not map perfectly to the WGSS. The code file Principle Disability Mapping.xlsx
		contains suggested mappings for identifying principle disability type.
		People can have up to 15 diagnoses but only two principle diagnoses.
		There are mapped to six categories that do not align with WGSS.
	- Use the principal flag to filter diagnoses. Principal diagnoses are the ones
		that drive eligibility for services.

Parameters & Present values:
  Current refresh = 202203
  Prefix = vacc_
  Project schema = DL-MAA2018-48
 
Issues:
1) This definition not consistent with Stats NZ surveys and Census 2018 definitions of
	disability. In this definition people who answered the Washington Group Short Set
	with ‘some difficulty’ are categorised as disabled with a ‘high level functional
	disability’. The threshold used in Census 2018 and other Stats NZ surveys is to categorise
	people who respond with ‘a lot of difficulty’ or ‘cannot do at all’ as disabled.

2) Some of the data on needs assessment will be very old (10+ years). Needs assessments
	happen every three years, so they are not indicator of whether people are currently
	receiving services.


History (reverse order):
2022-07-21 VW Point to DL-MAA2018-38 (MSD seniors project) and relevant refresh (202203) 
           [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_202110] has been renamed to 
		   [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_2022] in latest refresh. 
		   The same is true for moh_support_needs_202110 to moh_support_needs_2022.
		   Change so that if someone has multiple records, only that with the most recent date is used.
2022-02-28 SA incorporated comments from MoH staff
2021-12-02 SA review and tidy
2021-11-20 CW v1
**************************************************************************************************/

/* create table for all records */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list] (
	snz_uid INT,
	record_source VARCHAR(9),
	event_date DATE,
	dv_comt INT,
	dv_hearing INT,
	dv_remembering INT,
	dv_seeing INT,
	dv_walking INT,
	dv_washing INT,
);
GO

/***************************************************************************************************************
append records from each source into the table
***************************************************************************************************************/

/*********************************
1. census 2018
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_comt, dv_hearing, dv_remembering, dv_seeing, dv_walking, dv_washing)
SELECT [snz_uid]
	,'CEN2018' AS record_source
	,'2018-03-05' AS event_date
	--,[cen_ind_dsblty_ind_code] as dv_disability
	,CASE
		WHEN [cen_ind_dffcl_comt_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_comt_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_comt_code] IN (3,4) THEN 2
		END AS dv_comt
	,CASE
		WHEN [cen_ind_dffcl_hearing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_hearing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_hearing_code] IN (3,4) THEN 2
		END AS dv_hearing
	,CASE
		WHEN [cen_ind_dffcl_remembering_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_remembering_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_remembering_code] IN (3,4) THEN 2
		END AS dv_remembering
	,CASE 
		WHEN [cen_ind_dffcl_seeing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_seeing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_seeing_code] IN (3,4) THEN 2
		END AS dv_seeing
	,CASE 
		WHEN [cen_ind_dffcl_walking_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_walking_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_walking_code] IN (3,4) THEN 2
		END AS dv_walking
	,CASE 
		WHEN [cen_ind_dffcl_washing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_washing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_washing_code] IN (3,4) THEN 2
		END AS dv_washing
FROM [IDI_Clean_202203].[cen_clean].[census_individual_2018]
WHERE [cen_ind_dffcl_comt_code] IN (2,3,4)
OR [cen_ind_dffcl_hearing_code] IN (2,3,4)
OR [cen_ind_dffcl_remembering_code] IN (2,3,4)
OR [cen_ind_dffcl_seeing_code] IN (2,3,4)
OR [cen_ind_dffcl_walking_code] IN (2,3,4)
OR [cen_ind_dffcl_washing_code] IN (2,3,4)
GO

/*********************************
2. SOCRATES
*********************************/

WITH extracted_codes AS (

	SELECT c.snz_uid
		,s.snz_moh_uid
		,[Code]
		,[Description]
		,CAST(SUBSTRING([DateAssessmentCompleted],1,7) AS DATE) AS event_date
		--seeing
		--1001	Vision impaired
		--1002	Blind or nearly blind
		,CASE
			WHEN code IN (1001) THEN 1
			WHEN code IN (1002) THEN 2
			ELSE 0 END AS dv_seeing
		--hearing
		--1003	Hearing impaired
		--1004	Deaf or nearly deaf
		,CASE 
			WHEN code IN (1003) THEN 1
			WHEN code IN (1004) THEN 2 
			ELSE 0 END AS dv_hearing
		--memory/learning
		--1299	Other difficulties with memory / cognition / behaviour (specify)
		--1203	Learning ability, i.e. acquiring skills of reading, writing, language, calculating, copying, etc.
		--1202	Intellectual ability, i.e. thinking, understanding
		--1208	Attention, e.g. concentration
		--1201	Memory
		,CASE 
			WHEN code IN (1201,1202,1203,1208,1299) THEN 1
			ELSE 0 END AS dv_remembering
		--communicating
		--1803	Non verbal
		--1801	Ability to express core needs
		--1006	Mute or nearly mute
		--1005	Speech impaired
		,CASE 
			WHEN code IN (1005,1006,1801,1803) THEN 1
			ELSE 0 END AS dv_comt
		--walk
		--1111	Wheelchair user (inside / outside of home)
		--1101	Moving around inside home
		--1102	Moving around outside home
		--1103	Moving around in the community
		,CASE 
			WHEN code IN (1111) THEN 2
			WHEN code IN (1101,1002,1103) THEN 1
			ELSE 0 END AS dv_walking
		--wash
		--1403	Dressing and / or undressing
		--1405	Toileting, using toilet facilities
		--1402	Bathing, showering, washing self
		--1404	Grooming and caring for body parts, e.g. feet, teeth, hair, nails, etc
		,CASE 
			WHEN code IN (1402,1403,1404,1405) THEN 1
			ELSE 0 END AS dv_washing
	FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_support_needs_2022] AS s
	INNER JOIN [IDI_Clean_202203].[security].[concordance] as c
	ON s.snz_moh_uid = c.snz_moh_uid
	LEFT JOIN [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_2022] AS n
	ON s.[snz_moh_uid] = n.[snz_moh_uid]
	AND s.[NeedsAssessmentID] = n.[NeedsAssessmentID]
	AND s.[snz_moh_soc_client_uid] = n.[snz_moh_soc_client_uid]

)
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_comt, dv_hearing, dv_remembering, dv_seeing, dv_walking, dv_washing)
SELECT snz_uid
	,'SOC' AS record_source
	,event_date
	,CASE 
		WHEN SUM(dv_comt) = 1 THEN 1 
		WHEN SUM(dv_comt) > 1 THEN 2
		ELSE 0 end as dv_comt
	,CASE
		WHEN SUM(dv_hearing) = 1 THEN 1 
		WHEN SUM(dv_hearing) > 1 THEN 2
		ELSE 0 end as dv_hearing
	,CASE 
		WHEN SUM(dv_remembering) = 1 THEN 1 
		WHEN SUM(dv_remembering) > 1 THEN 2
		ELSE 0 end as dv_remembering
	,CASE
		WHEN SUM(dv_seeing) = 1 THEN 1 
		WHEN SUM(dv_seeing) > 1 THEN 2
		ELSE 0 end as dv_seeing
	,CASE 
		WHEN SUM(dv_walking) = 1 THEN 1 
		WHEN SUM(dv_walking) > 1 THEN 2
		ELSE 0 end as dv_walking
	,CASE 
		WHEN SUM(dv_washing) = 1 THEN 1 
		WHEN SUM(dv_washing) > 1 THEN 2
		ELSE 0 END AS dv_washing
FROM extracted_codes
GROUP BY snz_uid, event_date
GO

/*********************************
3. IRAI
*********************************/
-- excludes the CA assessment ype due to absence of impairment/disability type questions
--FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_question_lookup]
--WHERE [IDI Variable Name] like '%intel%' OR [Question] like '%distract%'

--FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_answer_lookup]
--WHERE [IDI Variable Name] like '%cog%'

--dv_very_high_count = 1-7 / 1= only level 1 disability, 2=1 level 2 disability,...,7=6 level 2 disabilities
--dv_disability= 2 =any level 2 disability / 1 = no level 2 but 1 or more level 1 disabilties

WITH extracted_codes AS (

	SELECT [snz_uid]
	    ,[snz_moh_uid]
		,[moh_irai_assessment_type_text]
		,[moh_irai_assess_version_text]
		,[moh_irai_assessment_date] AS event_date
		--washing
		,IIF(moh_irai_adl_bathing_code BETWEEN 0 AND 7, moh_irai_adl_bathing_code, 0) AS dv_washing
		--walking
		,IIF([moh_irai_adl_walking_code] BETWEEN 0 AND 7, [moh_irai_adl_walking_code] , 0) walk
		,IIF(moh_irai_stairs_perform_code BETWEEN 0 AND 7, moh_irai_stairs_perform_code, 0) AS stair_1
		,IIF(moh_irai_stairs_capacity_code BETWEEN 0 AND 7, moh_irai_stairs_capacity_code, 0) AS stair_2
		--communication
		,IIF(moh_irai_scale_comm_code BETWEEN 0 AND 7, moh_irai_scale_comm_code, 0) AS dv_comt
		--memory/learning
		,CASE
			WHEN(CAST([moh_irai_short_term_mem_ind] AS INT)
				+ CAST([moh_irai_procedural_mem_ind] AS INT)
				+ CAST([moh_irai_situational_mem_ind] AS INT)
				+ CAST([moh_irai_long_term_mem_ind] AS INT)
				+ CAST([moh_irai_res_hist_intellect_ind] AS INT)
			) > [moh_irai_easily_distracted_code] 
			THEN(CAST([moh_irai_short_term_mem_ind] AS INT)
				+ CAST([moh_irai_procedural_mem_ind] AS INT)
				+ CAST([moh_irai_situational_mem_ind] AS INT)
				+ CAST([moh_irai_long_term_mem_ind] AS INT)
				+ CAST([moh_irai_res_hist_intellect_ind] AS INT)
			)
			ELSE [moh_irai_easily_distracted_code]
			END AS dv_remembering
		--hearing
		,IIF([moh_irai_hearing_code] BETWEEN 0 AND 7, [moh_irai_hearing_code], 0) AS dv_hearing
		--vision
		,IIF([moh_irai_vision_light_code] BETWEEN 0 AND 7, [moh_irai_vision_light_code], 0) AS dv_seeing
	FROM [IDI_Clean_202203].[moh_clean].[interrai]
	WHERE [moh_irai_assessment_type_text] !='CA'

)
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_comt, dv_hearing, dv_remembering, dv_seeing, dv_walking, dv_washing)

SELECT DISTINCT snz_uid
	,'IRAI' AS record_source
	,event_date
	,CASE 
		WHEN dv_comt=0 THEN 0 
		WHEN dv_comt IN (1,2) THEN 1
		WHEN dv_comt>=3 THEN 2
		END AS dv_comt
	,CASE
		WHEN dv_hearing=0 THEN 0
		WHEN dv_hearing=1 THEN 1
		WHEN dv_hearing>=2 THEN 2
		END AS dv_hearing
	,CASE 
		WHEN dv_remembering=0 THEN 0 
		WHEN dv_remembering=1 THEN 1
		WHEN dv_remembering>=2 THEN 2
		END AS dv_remembering
	,CASE 
		WHEN dv_seeing=0 THEN 0
		WHEN dv_seeing=1 THEN 1
		WHEN dv_seeing>=2 THEN 2
		END AS dv_seeing
	,CASE 
		WHEN dv_walking=0 THEN 0 
		WHEN dv_walking=1 THEN 1
		WHEN dv_walking>=2 THEN 2
		END AS dv_walking
	,CASE 
		WHEN dv_washing=0 THEN 0 
		WHEN dv_washing=1 THEN 1
		WHEN dv_washing>=2 THEN 2
		END AS dv_washing
FROM (
	SELECT [snz_uid]
		,event_date
		,dv_comt
		,dv_hearing
		,dv_remembering
		,dv_seeing
		-- keep the largest
		,CASE
			WHEN walk >=stair_1 AND walk >=stair_2 THEN walk 
			WHEN stair_1 >= walk AND stair_1 >= stair_2 THEN stair_1
			WHEN stair_2 >= walk AND stair_2 >= stair_1 THEN stair_2 END AS dv_walking
		--,walk
		--,stair_1
		--,stair_2
		,dv_washing
	FROM extracted_codes
) AS a
GO

/*********************************
4. ACC
*********************************/

--SELECT [acc_cla_seriousinjuryprofile],count(*)  as rows
--into #acc_dis
--FROM (
--SELECT [snz_uid]
--    ,[snz_acc_uid]
--    ,[snz_acc_claim_form_45_uid]
--    ,[snz_acc_claim_uid]
--    ,[acc_cla_lodgement_date]
--    ,[acc_cla_decision_date]
--    ,[acc_cla_registration_date]
--    ,[acc_cla_accident_date]
--    ,[acc_cla_serious_injury_ind]
--    ,[acc_cla_case_management_end_date]
--    ,[acc_cla_seriousinjuryprofile]

--FROM [IDI_Clean_202203].[acc_clean].[claims]
--WHERE  [acc_cla_serious_injury_ind]='Y'
--AND YEAR([acc_cla_accident_date])>=2018
--) as a
--GROUP BY [acc_cla_seriousinjuryprofile]

/*********************************
5. HLFS
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_comt, dv_hearing, dv_remembering, dv_seeing, dv_walking, dv_washing)

SELECT b.snz_uid
	,'HLFS' AS record_source
	,[quarter_date]
	,CASE 
		WHEN[diff_communicating_code]='11' then 0
		WHEN [diff_communicating_code]='12' THEN 1
		WHEN [diff_communicating_code] IN ('13','14') THEN 2
		END AS dv_comt
	,CASE 
		WHEN[diff_hearing_code]='11' then 0
		WHEN [diff_hearing_code]='12' THEN 1
		WHEN [diff_hearing_code] IN ('13','14') THEN 2
		END AS dv_hearing
	,CASE 
		WHEN[diff_memory_code]='11' then 0
		WHEN [diff_memory_code]='12' THEN 1
		WHEN [diff_memory_code] IN ('13','14') THEN 2
		END AS dv_remembering
	,CASE 
		WHEN[diff_seeing_code]='11' then 0
		WHEN [diff_seeing_code]='12' THEN 1
		WHEN [diff_seeing_code] IN ('13','14') THEN 2
		END AS dv_seeing
	,CASE 
		WHEN[diff_walking_code]='11' then 0
		WHEN [diff_walking_code]='12' THEN 1
		WHEN [diff_walking_code] IN ('13','14') THEN 2
		END AS dv_walking
	,CASE 
		WHEN[diff_dressing_code]='11' then 0
		WHEN [diff_dressing_code]='12' THEN 1
		WHEN [diff_dressing_code] IN ('13','14') THEN 2
		END AS dv_washing
FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_disability] as a
INNER JOIN [IDI_Clean_202203].[security].[concordance] as b
ON a.snz_hlfs_uid = b.snz_hlfs_uid
WHERE [diff_seeing_code] IN (12,13,14)
OR [diff_hearing_code] IN (12,13,14)
OR [diff_walking_code] IN (12,13,14)
OR [diff_memory_code] IN (12,13,14)
OR [diff_dressing_code] IN (12,13,14)
OR [diff_communicating_code]  IN (12,13,14)
GO

/*********************************
6. Hospitalisations - public & private
*********************************/
--NB need to decide on how to aggregate across dates / chronic versus acute
--Incomplete, steering group advised not to use diagnosis.

/*
WITH extracted_codes AS (

	SELECT *
		,SUBSTRING([moh_dia_clinical_code],1,3) AS clinical_code_sub3
		,SUBSTRING([moh_dia_clinical_code],1,4) AS clinical_code_sub4
	FROM [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_diag]

)
SELECT b.snz_uid
	,'PUB' AS record_source
	,b.[moh_evt_evst_date] as event_date
	--,[moh_dia_clinical_code] AS code
	,CASE 
		WHEN clinical_code_sub3 IN ('R47','F80') THEN 3 
		ELSE 0 END AS dv_comt
	,CASE 
		WHEN clinical_code_sub3 IN ('H90','H91') THEN 3 
		ELSE 0 END AS dv_hearing
	,CASE 
		WHEN clinical_code_sub3 IN ('F81') THEN 3 
		ELSE 0 END AS dv_remembering
	,CASE 
		WHEN clinical_code_sub3 = 'H54' THEN 3 
		ELSE 0 END AS dv_seeing
	,CASE 
		WHEN clinical_code_sub3 = 'R28' OR clinical_code_sub4 = 'Z440' THEN 3 
		ELSE 0 END AS dv_walking
	,CASE 
		WHEN clinical_code_sub3 IN ('F81') or clinical_code_sub4 IN ('Z441','Z742') THEN 3 
		ELSE 0 END AS dv_washing
FROM extracted_codes AS a
INNER JOIN [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_event] AS b
ON a.[moh_dia_event_id_nbr] = b.[moh_evt_event_id_nbr]
WHERE [moh_dia_clinical_sys_code] = [moh_dia_submitted_system_code]
AND (
	clinical_code_sub3 IN ('R26','H54','H90','H91','R47','F81','F80')
	OR clinical_code_sub4 IN ('Z440','Z741','Z742')
)
*/

/*********************************
7. GSS 2016 or 2018
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_comt, dv_hearing, dv_remembering, dv_seeing, dv_walking, dv_washing)

SELECT [snz_uid]
	,'GSS' AS record_source
	,[gss_pq_HQinterview_date] AS event_date
	,CASE
		WHEN[gss_pq_disability_comm_code] ='11' THEN 0
		WHEN [gss_pq_disability_comm_code] ='12' THEN 1
		WHEN [gss_pq_disability_comm_code] IN ('13','14') THEN 2 END AS dv_comt
	,CASE 
		WHEN[gss_pq_disability_hear_code] ='11' THEN 0
		WHEN [gss_pq_disability_hear_code] ='12' THEN 1
		WHEN [gss_pq_disability_hear_code] IN ('13','14') THEN 2 END AS dv_hearing
	,CASE 
		WHEN[gss_pq_disability_remem_code] ='11' THEN 0
		WHEN [gss_pq_disability_remem_code] ='12' THEN 1
		WHEN [gss_pq_disability_remem_code] IN ('13','14') THEN 2 END AS dv_remembering
	,CASE 
		WHEN[gss_pq_disability_see_code] ='11' THEN 0
		WHEN [gss_pq_disability_see_code] ='12' THEN 1
		WHEN [gss_pq_disability_see_code] IN ('13','14') THEN 2 END AS dv_seeing
	,CASE
		WHEN[gss_pq_disability_walk_code] ='11' THEN 0
		WHEN [gss_pq_disability_walk_code] ='12' THEN 1
		WHEN [gss_pq_disability_walk_code] IN ('13','14') THEN 2 END AS dv_walking
	,CASE
		WHEN[gss_pq_disability_wash_code] ='11' THEN 0
		WHEN [gss_pq_disability_wash_code] ='12' THEN 1
		WHEN [gss_pq_disability_wash_code] IN ('13','14') THEN 2 END AS dv_washing
FROM [IDI_Clean_202203].[gss_clean].[gss_person]
WHERE [gss_pq_disability_see_code] IN ('12','13','14')
OR [gss_pq_disability_hear_code] IN ('12','13','14')
OR [gss_pq_disability_walk_code] IN ('12','13','14')
OR [gss_pq_disability_remem_code] IN ('12','13','14')
OR [gss_pq_disability_wash_code] IN ('12','13','14')
OR [gss_pq_disability_comm_code] IN ('12','13','14')
GO

/***************************************************************************************************************
Keep most recent record for each person for each source
***************************************************************************************************************/

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list] (snz_uid);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_functional_disability]
GO

WITH date_ranked AS (
	-- Where a person has multiple records keep the most recent (across all sources)
	SELECT *
		,RANK() OVER (PARTITION BY snz_uid ORDER BY event_date, record_source ,dv_washing  ,dv_comt  ,dv_walking,dv_remembering  ,dv_seeing  ,dv_hearing ) AS ranking
	FROM [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
	WHERE dv_washing > 0
	OR dv_comt > 0
	OR dv_walking > 0
	OR dv_remembering > 0
	OR dv_seeing > 0
	OR dv_hearing > 0
),
full_table AS (
SELECT DISTINCT snz_uid
	,event_date
	,record_source
	,ISNULL(dv_comt, 0) AS dv_comt
	,ISNULL(dv_hearing, 0) AS dv_hearing
	,ISNULL(dv_remembering, 0) AS dv_remembering
	,ISNULL(dv_seeing, 0) AS dv_seeing
	,ISNULL(dv_walking, 0) AS dv_walking
	,ISNULL(dv_washing, 0) AS dv_washing
	,CASE
		WHEN dv_washing = 2 OR dv_comt = 2 OR dv_walking = 2 OR dv_remembering = 2 OR dv_seeing = 2 OR dv_hearing = 2 THEN 2
		WHEN dv_washing = 1 OR dv_comt = 1 OR dv_walking = 1 OR dv_remembering = 1 OR dv_seeing = 1 OR dv_hearing = 1 THEN 1
		ELSE 0 END AS any_functional_disability
	,IIF(dv_washing = 2, 1, 0)
	+ IIF(dv_comt = 2, 1, 0)
	+ IIF(dv_walking = 2, 1, 0)
	+ IIF(dv_remembering = 2, 1, 0)
	+ IIF(dv_seeing = 2, 1, 0)
	+ IIF(dv_hearing = 2, 1, 0) AS count_very_high_disability
FROM date_ranked
WHERE ranking = 1)

-- create table version for MSD seniors project - only most recent record (up to study period end date) 
SELECT a.snz_uid
	,a.event_date
	,any_functional_disability
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_functional_disability]
FROM full_table a
INNER JOIN (
	SELECT snz_uid, MAX(event_date) as event_date
	FROM full_table
	WHERE event_date <= '2018-03-31'
	GROUP BY snz_uid) b
ON a.snz_uid = b.snz_uid AND a.event_date = b.event_date
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_functional_disability] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_functional_disability] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/* remove raw list table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_functional_disability_list]
GO


