/***************************************************************************************************************************
Title: Functional disability
Author: Craig Wright
Reviewer: Simon Anastasiadis

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
Multi-source indicator of functional disability

Intended purpose:
Measuring disability is a complex and still evolving issue. There is no perfect way to classify people into categories and no full agreement amongst the 
disabled community on the language to be used. However, it is important for the disabled community, researchers, and policy makers 
to have some standard way to describe varying levels of participation as citizens, clients, or consumers of services.


## Key concepts

Disability is a social construct that arises through the combination of two things:
1.	The limitations some people have in completing some activities.
2.	The barriers that exist in a person’s environment (or society in general) that limit participation.

Information about the barriers or accommodations people experience is currently not available in administrative data. However, there are some sources data 
that include functional limitations that some people have. Hence, one approach is to use functional limitations to identify groups who are more likely to be disabled.


## Practical notes

The indicator is based on the Washington Group Short Set (WGSS) questions on functioning. The WGSS is a series of six questions about difficulties people might encounter doing everyday things:
•	Walking
•	Seeing
•	Hearing
•	Remembering
•	Washing
•	Communication

However, not everyone has answered these questions, and some people might have acquired impairments after the questions were asked. We have supplemented these questions with data from some Ministry of Health collections: SOCRATES, which captures functional assessments for disability clients; and InterRAI, which captures similar information for older people. 

In collaboration with experts in the disabled community, the Ministry of Health and Office for Disability Issues, we have aligned each of these data sources, resulting in a three-level indicator for each of the six functional activities: 
•	0 = No limitation: This group does not report any limitations in undertaking everyday tasks. They are unlikely to be disabled.
•	1 = Low functional limitation: This group reports some difficulty with everyday tasks. They are somewhat likely to be disabled.
•	2 = High functional limitation: This group reports a lot of difficulty with everyday tasks or cannot do them at all. They are very likely to be disabled.

Following guidance from the Washington Group (2020), we have also produced one overall indicator for disability status. This takes the value of ‘disabled’ if the person had high functional limitation in at least one activity, and ‘not disabled’ otherwise. (This overall indicator is consistent with how many agencies, such as Stats NZ, are already using the WGSS to report on outcomes for disabled people.)


## How to use this indicator

•	Involve disabled people in your research, including when designing your approach and interpreting your results.
•	Use it to compare outcomes, not to estimate the size of groups. This indicator is not suitable for counting the disabled population. The official measure of the disabled population in New Zealand is derived from the Disability Survey undertaken by Stats NZ. Use of this definition should be constrained to comparisons between groups, rather than discussing the size of those groups.
•	Adjust for age in your analysis. There is a very strong relationship between age and functional impairment. To account for this, we recommend adjusting for age when comparing between functional groups (at minimum, reporting separately those below and above the age of 65).


## Limitations of this indicator

•	The indicator is not as accurate and comprehensive as the measure of disability in the Disability Survey. It is not a replacement for the official measure from the Disability Survey.
•	The Washington Group Short Set (WGSS) is not a fully comprehensive measure of functional limitations.
•	For children under 12, the WGSS is less sensitive at moderate levels of functional limitation. The WGSS is also not collected for children under the age of five.
•	The indicator may capture people who are disabled only temporarily. These people may have very different experiences to people who have permanent or ongoing impairments.


## Other notes

•	The indicator might be expanded in the future to use WGSS responses from the NZCVS and specific modules of the HES. However, the coverage of both sources is limited.
•	We investigated using Hospital diagnoses and ACC records. But the steering group advised against their inclusion.


## References

The Social Wellbeing Agency has published an accompanying guide. You can find it our our website: swa.govt.nz 


## Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = DL-MAA20XX-YY


## Dependencies
The code relies on eight input tables:
•	[IDI_Clean].[cen_clean].[census_individual_2018]
•	[IDI_Clean].[security].[concordance]
•	[IDI_Clean].[gss_clean].[gss_person]
•	[IDI_Clean].[security].[concordance]
•	[IDI_Clean].[moh_clean].[interrai]
•	[IDI_Adhoc].[clean_read_HLFS].[hlfs_disability]
•	[IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_support_needs_2022]
•	[IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_2022]

Linking between the two is done on snz_moh_uid.  No rows are lost via this linking.

## Outputs
Table: [IDI_Sandpit].[DL-MAA20XX-YY].[defn_functional_disability]

## Variable Descriptions

---------------------------------------------------------------------------------------------------------------------------
Column                         Description
name                       
------------------------------ --------------------------------------------------------------------------------------------
snz_uid                        The unique STATSNZ person identifier for the person

record_source                  The database from which the record originates

event_date				       The date the disability information was recorded, survey/census date for Stats NZ sources, assessment date for MoH sources.

dv_hearing				       Indicator of hearing limitations

dv_seeing				       Indicator of seeing limitations

dv_walking				       Indicator of walking limitations

dv_remembering				   Indicator of remembering limitations

dv_washing				       Indicator of washing limitations

dv_communication			   Indicator of hearing limitations

overall_dv_indication		   Indicator of any high limitation


## Version and change history

2022-09-19 SA ensure consistency with definition documentation
2022-09-19 SA check against definition description by Andrew (from consultation with DDEWG)
2021-12-02 SA review and tidy
2021-11-20 CW v1

## Code

***************************************************************************************************************************/

/* create table for all records */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list] (
	snz_uid INT,
	record_source VARCHAR(9),
	event_date DATE,
	dv_hearing INT,
	dv_seeing INT,
	dv_walking INT,
	dv_remembering INT,
	dv_washing INT,
	dv_communication INT,
);
GO

/***************************************************************************************************************
append records from each source into the table
***************************************************************************************************************/

/*********************************
1. Stats NZ surveys - Census 2018

The question in the census is:

22. This question is about difficulties you may have doing certain activities because of a health problem.

	Do you have difficulty with any of the following:

	- seeing, even if wearing glasses?   ([cen_ind_dffcl_seeing_code])
		
		Answers:
			- no difficulty          (1)
			- some difficulty        (2)
			- a lot of difficulty    (3)
			- cannot do at all       (4)

		Other answers in the dataset
			- Response unidentifiable    (7)
			- Not Stated				 (9)

	The same answers apply to these questions:
	- hearing, even if using a hearing aid?  ([cen_ind_dffcl_hearing_code])
	- walking or climbing steps?    ([cen_ind_dffcl_walking_code])
	- remembering or concentrating?   ([cen_ind_dffcl_remembering_code])
	- washing all over or dressing?   ([cen_ind_dffcl_washing_code])
	- communicating using your usual language, for example understanding or being understood by others?   ([cen_ind_dffcl_comt_code])
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_hearing, dv_seeing, dv_walking, dv_remembering, dv_washing, dv_communication)
SELECT [snz_uid]
	,'CEN2018' AS record_source
	,'2018-03-05' AS event_date
	--,[cen_ind_dsblty_ind_code] as dv_disability
	,CASE
		WHEN [cen_ind_dffcl_hearing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_hearing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_hearing_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_hearing
	,CASE 
		WHEN [cen_ind_dffcl_seeing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_seeing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_seeing_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_seeing
	,CASE 
		WHEN [cen_ind_dffcl_walking_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_walking_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_walking_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_walking
	,CASE
		WHEN [cen_ind_dffcl_remembering_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_remembering_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_remembering_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_remembering
	,CASE 
		WHEN [cen_ind_dffcl_washing_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_washing_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_washing_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_washing
	,CASE
		WHEN [cen_ind_dffcl_comt_code] = 1 THEN 0
		WHEN [cen_ind_dffcl_comt_code] = 2 THEN 1
		WHEN [cen_ind_dffcl_comt_code] IN (3,4) THEN 2
		ELSE 0 END AS dv_communication
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2018]
/* WGSS not collected for children under 5 years of age for exclude */
WHERE cen_ind_age_code NOT IN ('000', '001', '002', '003', '004')
GO

/*********************************
2. Stats NZ surveys - HLFS
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-MM].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_hearing, dv_seeing, dv_walking, dv_remembering, dv_washing, dv_communication)
SELECT b.snz_uid
	,'HLFS' AS record_source
	,[quarter_date]
	,CASE 
		WHEN [diff_hearing_code]='11' then 0
		WHEN [diff_hearing_code]='12' THEN 1
		WHEN [diff_hearing_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_hearing
	,CASE 
		WHEN [diff_seeing_code]='11' then 0
		WHEN [diff_seeing_code]='12' THEN 1
		WHEN [diff_seeing_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_seeing
	,CASE 
		WHEN [diff_walking_code]='11' then 0
		WHEN [diff_walking_code]='12' THEN 1
		WHEN [diff_walking_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_walking
	,CASE 
		WHEN [diff_memory_code]='11' then 0
		WHEN [diff_memory_code]='12' THEN 1
		WHEN [diff_memory_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_remembering
	,CASE 
		WHEN [diff_dressing_code]='11' then 0
		WHEN [diff_dressing_code]='12' THEN 1
		WHEN [diff_dressing_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_washing
	,CASE 
		WHEN [diff_communicating_code]='11' then 0
		WHEN [diff_communicating_code]='12' THEN 1
		WHEN [diff_communicating_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_communication
FROM [IDI_Adhoc].[clean_read_HLFS].[hlfs_disability] as a
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] as b
ON a.snz_hlfs_uid = b.snz_hlfs_uid
GO

/*********************************
3. Stats NZ surveys - GSS 2016 or 2018
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_hearing, dv_seeing, dv_walking, dv_remembering, dv_washing, dv_communication)
SELECT [snz_uid]
	,'GSS' AS record_source
	,[gss_pq_HQinterview_date] AS event_date
	,CASE 
		WHEN [gss_pq_disability_hear_code] ='11' THEN 0
		WHEN [gss_pq_disability_hear_code] ='12' THEN 1
		WHEN [gss_pq_disability_hear_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_hearing
	,CASE 
		WHEN [gss_pq_disability_see_code] ='11' THEN 0
		WHEN [gss_pq_disability_see_code] ='12' THEN 1
		WHEN [gss_pq_disability_see_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_seeing
	,CASE
		WHEN [gss_pq_disability_walk_code] ='11' THEN 0
		WHEN [gss_pq_disability_walk_code] ='12' THEN 1
		WHEN [gss_pq_disability_walk_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_walking
	,CASE 
		WHEN [gss_pq_disability_remem_code] ='11' THEN 0
		WHEN [gss_pq_disability_remem_code] ='12' THEN 1
		WHEN [gss_pq_disability_remem_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_remembering
	,CASE
		WHEN [gss_pq_disability_wash_code] ='11' THEN 0
		WHEN [gss_pq_disability_wash_code] ='12' THEN 1
		WHEN [gss_pq_disability_wash_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_washing
	,CASE
		WHEN [gss_pq_disability_comm_code] ='11' THEN 0
		WHEN [gss_pq_disability_comm_code] ='12' THEN 1
		WHEN [gss_pq_disability_comm_code] IN ('13','14') THEN 2
		ELSE 0 END AS dv_communication
FROM [IDI_Clean_YYYYMM].[gss_clean].[gss_person]
GO

/*********************************
4. MoH - SOCRATES

The SOCRATES data is for MoH funded disability services.
These will tend to be at the more severe end of the scale.
So we expect to see that there will be fewer people in this
data and that their measures will tend to be more severe. 

Code list:
	Hearing
	--1003	Hearing impaired
	--1004	Deaf or nearly deaf
	Seeing
	--1001	Vision impaired
	--1002	Blind or nearly blind
	Walking
	--1111	Wheelchair user (inside / outside of home)
	--1101	Moving around inside home
	--1102	Moving around outside home
	--1103	Moving around in the community
	Remembering
	--1299	Other difficulties with memory / cognition / behaviour (specify)
	--1203	Learning ability, i.e. acquiring skills of reading, writing, language, calculating, copying, etc.
	--1202	Intellectual ability, i.e. thinking, understanding
	--1208	Attention, e.g. concentration
	--1201	Memory
	Washing
	--1403	Dressing and / or undressing
	--1405	Toileting, using toilet facilities
	--1402	Bathing, showering, washing self
	--1404	Grooming and caring for body parts, e.g. feet, teeth, hair, nails, etc
	Communication
	--1803	Non verbal
	--1801	Ability to express core needs
	--1006	Mute or nearly mute
	--1005	Speech impaired
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_hearing, dv_seeing, dv_walking, dv_remembering, dv_washing, dv_communication)

SELECT [snz_uid]
	,'SOCRATES' AS record_source
	,CAST(SUBSTRING([DateAssessmentCompleted],1,7) AS DATE) AS event_date
	--hearing
	,IIF(code IN (1003, 1004), 2, 0) AS dv_hearing
	--seeing
	,IIF(code IN (1001, 1002), 2, 0) AS dv_seeing
	--walk
	,IIF(code IN (1111, 1101, 1102, 1103), 2, 0) AS dv_walking
	--memory/learning
	,IIF(code IN (1201,1202,1203,1208,1299), 2, 0) AS dv_remembering
	--wash
	,IIF(code IN (1402,1403,1404,1405), 2, 0) AS dv_washing
	--communicating
	,IIF(code IN (1005,1006,1801,1803), 2, 0) AS dv_communication
	--,s.Code
	--,s.Description
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_support_needs_2022] AS s
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] as c
ON s.snz_moh_uid = c.snz_moh_uid
INNER JOIN [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_2022] AS n
ON s.[snz_moh_uid] = n.[snz_moh_uid]
AND s.[NeedsAssessmentID] = n.[NeedsAssessmentID]
AND s.[snz_moh_soc_client_uid] = n.[snz_moh_soc_client_uid]
GO

/*********************************
5. MoH - IRAI

Excludes the CA assessment type due to absence of impairment/disability type questions
*********************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-MM].[tmp_functional_disability_list]
	(snz_uid, record_source, event_date, dv_hearing, dv_seeing, dv_walking, dv_remembering, dv_washing, dv_communication)

SELECT [snz_uid]
	,'IRAI' AS record_source
	--,[snz_moh_uid]
	--,[moh_irai_assessment_type_text]
	--,[moh_irai_assess_version_text]
	,[moh_irai_assessment_date] AS event_date
	--hearing
	,CASE
		WHEN [moh_irai_hearing_code] BETWEEN 2 AND 4 THEN 2
		WHEN [moh_irai_hearing_code] = 1 THEN 1
		ELSE 0 END AS dv_hearing
	--vision
	,CASE
		WHEN [moh_irai_vision_light_code] BETWEEN 2 AND 4 THEN 2
		WHEN [moh_irai_vision_light_code] = 1 THEN 1
		ELSE 0 END AS dv_seeing
	--walking
	,CASE
		WHEN [moh_irai_adl_walking_code] BETWEEN 2 AND 6
			OR moh_irai_stairs_perform_code BETWEEN 2 AND 6
			OR moh_irai_stairs_capacity_code BETWEEN 2 AND 6 THEN 2
		WHEN [moh_irai_adl_walking_code] = 1
			OR moh_irai_stairs_perform_code = 1
			OR moh_irai_stairs_capacity_code = 1 THEN 1
		ELSE 0 END AS dv_walking
	--memory/learning
	,CASE
		WHEN [moh_irai_short_term_mem_ind] = 1
			OR [moh_irai_procedural_mem_ind] = 1
			OR [moh_irai_situational_mem_ind] = 1
			OR [moh_irai_long_term_mem_ind] = 1
			OR [moh_irai_res_hist_intellect_ind] = 1
			OR [moh_irai_easily_distracted_code] = 2 THEN 2
		WHEN [moh_irai_easily_distracted_code] = 1 THEN 1
		ELSE 0 END AS dv_remembering
	--washing
	,CASE
		WHEN moh_irai_adl_bathing_code BETWEEN 2 AND 6 THEN 2
		WHEN moh_irai_adl_bathing_code = 1 THEN 1
		ELSE 0 END AS dv_washing
	--communication
	,CASE
		WHEN moh_irai_scale_comm_code BETWEEN 3 AND 8 THEN 2
		WHEN moh_irai_scale_comm_code BETWEEN 1 AND 2 THEN 1
		ELSE 0 END AS dv_comt
FROM [IDI_Clean_YYYYMM].[moh_clean].[interrai]
WHERE [moh_irai_assessment_type_text] !='CA'

GO

/***************************************************************************************************************
Create final table
***************************************************************************************************************/

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list] (snz_uid);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_functional_disability]
GO


WITH

/* Where multiple records per person for the same date & source, keep the highest */
single_person_source_date_record AS (
	SELECT snz_uid
		,record_source
		,event_date
		,MAX(dv_hearing) AS dv_hearing
		,MAX(dv_seeing) AS dv_seeing
		,MAX(dv_walking) AS dv_walking
		,MAX(dv_remembering) AS dv_remembering
		,MAX(dv_washing) AS dv_washing
		,MAX(dv_communication) AS dv_communication
	FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_functional_disability_list]
	GROUP BY snz_uid, record_source, event_date
),

/* Create indicator for most recent record for each person */
most_recent_date AS (
	SELECT *
		,ROW_NUMBER() OVER (PARTITION BY snz_uid ORDER BY event_date DESC, record_source) AS ranking
	FROM single_person_source_date_record
)

SELECT snz_uid
	,record_source
	,event_date
	,dv_hearing
	,dv_seeing
	,dv_walking
	,dv_remembering
	,dv_washing
	,dv_communication
	,IIF(dv_hearing = 2
		OR dv_seeing = 2
		OR dv_walking = 2
		OR dv_remembering = 2
		OR dv_washing = 2
		OR dv_communication = 2, 1, 0) AS overall_dv_indication
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_functional_disability]
FROM most_recent_date
WHERE ranking = 1
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_functional_disability] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_functional_disability] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/* remove raw list table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_functional_disability_list]
GO