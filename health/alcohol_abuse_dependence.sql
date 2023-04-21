/**************************************************************************************************
Title: Alcohol abuse or dependence
Author: Craig Wright
Re-work: Manjusha Radhakrishnan, Simon Anastasiadis
Reviewer:

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
Any indication of chronic or acute alcohol abuse or dependence
For incidence and prevalence - see notes.

Intended purpose:
Indication of chronic or acute alcohol abuse or dependence.

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moh_clean].[mortality_diagnosis]
- [IDI_Clean].[moh_clean].[mortality_registrations]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[PRIMHD]
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Clean].[msd_clean].[msd_incapacity]
- [IDI_Clean].[moj_clean].[charges]
- [IDI_Clean].[pol_clean].[nia_links]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_charge_outcome_type_code]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_offence]
- [IDI_Adhoc].[clean_read_MOH_PRIMHD].[moh_primhd_mhinc]
- [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_disability]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_referral]
- [IDI_Adhoc].[clean_read_MOJ].[moj_alcohol_drv_disq]

Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_mha_alcohol_abuse_or_dependence]
- [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis]


Notes:
1) Definition based on three factors:
	1. any diagnosis or treatment for serious alcohol abuse or depedence
	2. any information for diangosis or treatment for serious alcohol abuse or depedence
		WITH conditions including Alcohol and Other Drugs (AOD) abuse or depedence
	3. any information on acute intoxication - marks misuse of alcohol but not abuse or depedence
	Precursors data tables for creating the final table:
	1. Alternative Level of Care (ALC) = diagnosis or treatment that is specific to abuse and depedence; this is used to indicate serious alcohol problems
	2. multiple = evidence of AOD - so servies that are for a mix of alcohol and / or other drugs be not specifically identifying which.
	Includes: alcohol abuse/depedence and 100% alcohol attributable chronic conditions
	Excludes: Fetal Alcohol Syndrome (FAS) and fetus affected by maternal alcohol use

2) Incidence and prevalence
	  Incidence = development of a condition during a particular time period (new only).
	  Prevalance = affected by the condition during a particular time period (new + existing).
	Plots of incidence (from this definition) against deprivation show a non-monotinic pattern.
	Incidence increases from deprivation 1-8 but deprivation 9 and 10 show lower incidence.
	This is likely because of barriers to access (cost, transport, availability etc.).
	
	So we can not use point in time measures to accurately access prevalance.
	Instead, when using this definition, we recommend considering every person's history.
	For example, if we consider any alcohol abuse indication in the last 10 years, then we observe
	a more likely relationship between alcohol abuse and deprivation. This suggests that people in high
	deprivation do get some treatment, but much less frequently than those who are less deprived.
	Such an approach is reasonable, as this condition is likely to persist for at least 10 years.

3) Some treatments are used to treat this condition and other conditions. This is most common
	with pharmaceuticals. For these treatments, we do the following:
	- Gather the treatments that serve multiple purposes together separately.
	- Where a person only has records that also treat other conditions, discard those records
	- Where a person has other evidence of alcohol abuse, add the treatments for multiple conditions
		to the table.
	For example, in 2010 a person is diagnosed in hospital with alcohol abuse, in 2008 they received drugs
	that are used to treat alcohol abuse or depression. Then we include the 2008 date as an earlier probable indicator.

4) Certain medial events are coded using the ICD9, ICD10, or DSM codes - most commonly hospital diagnoses.
	There are mappings between the different codings in the diagnoses table. The mappings help researchers who are
	familiar with only one coding system to locate records from a different coding system.
	Most records (at least 80%) are stored in two versions/rows (the submitted code system, and an alternative they
	have been mapped to), so researchers could use either version.
	However, the mappings are imperfect. In some cases a more specific code we do want is mapped to a more general code
	that we do not want. Hence, to ensure the most robust results, we have limited ourselves to only those records where
	the diagnostic code is stored in the same system it was submitted.
	This may exclude some records from our output definition. Researchers needing the broadest possible definition are
	advised to review this constraint.

5) We have decided to exclude SOCRATES as a source. There are several conditions recorded in SOCRATES that point
	to previous alcohol abuse. However, they may develop 10+ years after such alcohol abuse. Hence, these may be of
	interest to some researchers, but are not included here.
	- 1106 Foetal alcohol syndrome (FAS)
	- 1301 Alcohol / drug related disorder (excluding Korsakov's syndrome)
	- 1403 Korsakov's syndrome / alcohol-related dementia

6) We considered, but have excluded driver disqualifications.
	The table [IDI_Adhoc].[clean_read_MOJ].[moj_alcohol_drv_disq] contains indication for conviction, whether blood or breath
	alcohol level was high or low and what was the measurement.
	However, the table has no information beyond 2013. Hence it is of limited use for most recent applications.
	
Issues:
1) Because all our MHA tables use the same lookup/reference table, and all definitions load
	this table into the database, you can not run the definitions in parallel. Because, each
	definition will delete the reference table when it starts running and this will interfere 
	with the definitions that are already running.
	
Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
History (reverse order):
2022-09-12 SA Prep for library
2022-07-19 MR Tidy-up
2022-06-10 CW Definition creation
*************************************************************************************************************************/

/* Download the diagnosis lookup table from Github folder and upload onto datalab */

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] (
	diagnosis	VARCHAR(30),
	code_type	VARCHAR(30),
	code		VARCHAR(10),
	aux			VARCHAR(30),
	explanation	VARCHAR(255),
)

BULK INSERT [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis]
FROM '\\your project folder\diagnosis_codes.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/********************************************************
TABLES TO APPEND TO
********************************************************/

/* Diagnosis or treatment only indicates bipolar */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (
	snz_uid	INT,
	event_date DATE,
)

/* Diagnosis or treatment used for bipolar and other conditions */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (
	snz_uid	INT,
	event_date DATE,
)

/********************************************************
MORTALITY

Note that people who died with this diagnosis will likely
have had bipolar for a while before death
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT b.snz_uid
	  ,EOMONTH(DATEFROMPARTS([moh_mor_death_year_nbr],[moh_mor_death_month_nbr],1)) AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[mortality_diagnosis] AS a
INNER JOIN [IDI_Clean_YYYYMM].[moh_clean].[mortality_registrations] AS b
ON a.[snz_dia_death_reg_uid] = b.snz_dia_death_reg_uid
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD10'
	AND [moh_mort_diag_clinic_sys_code] >= '10'
	AND [moh_mort_diag_clinic_type_code] IN ('A','B','V')
)
OR EXISTS (
SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD9'
	AND [moh_mort_diag_clinic_sys_code] IN ('06','6')
	AND [moh_mort_diag_clinic_type_code] IN ('A','B','V')
)
OR EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD10'
	AND [moh_mort_diag_clinic_sys_code] >= '10'
	AND [moh_mort_diag_clinic_type_code] IN ('E')
)
OR EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD9'
	AND [moh_mort_diag_clinic_sys_code] IN ('06','6')
	AND [moh_mort_diag_clinic_type_code] IN ('E')
)
GO

/********************************************************
PHARMACEUTICALS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT a.[snz_uid]
		,[moh_pha_dispensed_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[pharmaceutical] AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(CAST(CHEMICAL_ID AS VARCHAR), 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'pharm_chemical'
	AND r.aux = 'sole'
)
GO

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT a.[snz_uid]
		,[moh_pha_dispensed_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[pharmaceutical] AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(CAST(CHEMICAL_ID AS VARCHAR), 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'pharm_chemical'
	AND r.aux = 'multiple'
)
GO

/********************************************************
PRIVATE HOSPITAL DISCHARGE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT a.[snz_uid]
	,CAST([moh_pri_evt_start_date] AS DATE) AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[priv_fund_hosp_discharges_event] AS a
INNER JOIN [IDI_Clean_YYYYMM].[moh_clean].[priv_fund_hosp_discharges_diag] AS b
ON a.[moh_pri_evt_event_id_nbr] = b.[moh_pri_diag_event_id_nbr]
AND [moh_pri_diag_sub_sys_code] = [moh_pri_diag_clinic_sys_code]
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING([moh_pri_diag_clinic_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD10'
	AND [moh_pri_diag_sub_sys_code] >= '10'
	AND [moh_pri_diag_diag_type_code] IN ('A','B','V')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING([moh_pri_diag_clinic_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD9'
	AND [moh_pri_diag_sub_sys_code] IN ('06','6')
	AND [moh_pri_diag_diag_type_code] IN ('A','B','V')
)
GO

/********************************************************
PUBLIC HOSPITAL DISCHARGE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT b.[snz_uid]
	,[moh_evt_evst_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_diag] AS a
INNER JOIN [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_event] AS b
ON [moh_dia_clinical_sys_code] = [moh_dia_submitted_system_code]
AND [moh_evt_event_id_nbr]=[moh_dia_event_id_nbr]
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD10'
	AND [moh_dia_submitted_system_code] >= '10'
	AND [moh_dia_diagnosis_type_code] IN ('A','B','V')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD9'
	AND [moh_dia_submitted_system_code] IN ('06','6')
	AND [moh_dia_diagnosis_type_code] IN ('A','B','V')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD10'
	AND [moh_dia_submitted_system_code] >= '10'
	AND [moh_dia_diagnosis_type_code] IN ('E')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD9'
	AND [moh_dia_submitted_system_code] IN ('06','6')
	AND [moh_dia_diagnosis_type_code] IN ('E')
)
GO

/********************************************************
PUBLIC HOSPITAL DISCHARGE

SUBSTANCE ABUSE HEALTH SPECIALITY
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT snz_uid, [moh_evt_evst_date]  as event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_event]
WHERE moh_evt_hlth_spec_code in ('Y40','Y41','Y42','Y43','Y44','Y45','Y46','Y47','Y48','Y49')
GO

/********************************************************
PRIMHD AND MHINC
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT b.snz_uid
      ,[classification_start] AS event_date
FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[moh_primhd_mhinc] AS a
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid 
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD10'
	AND [clinical_coding_system_id] >= '10'
	AND diagnosis_type in ('A','B','V','P')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'DSM'
	AND [clinical_coding_system_id] IN ('07','7')
	AND diagnosis_type in ('A','B','V','P')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD9'
	AND [clinical_coding_system_id] IN ('06','6')
	AND diagnosis_type in ('A','B','V','P')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD10'
	AND [clinical_coding_system_id] >= '10'
	AND diagnosis_type in ('E')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_DSM'
	AND [clinical_coding_system_id] IN ('07','7')
	AND diagnosis_type in ('E')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'external_ICD9'
	AND [clinical_coding_system_id] IN ('06','6')
	AND diagnosis_type in ('E')
)
GO

/********************************************************
PRIMHD TEAM
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT [snz_uid]
      ,[moh_mhd_activity_start_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[PRIMHD]
WHERE [moh_mhd_team_type_code] = 3
OR [moh_mhd_team_code] IN (7874,14808,13481,13541,7086,7102,7114,7115,7238,7119,7122,7142,7152,7153,7077)

/********************************************************
PRIMHD DIAGNOSIS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT snz_uid
      ,DATEFROMPARTS(SUBSTRING([CLASSIFICATION_START_DATE],7,4),SUBSTRING([CLASSIFICATION_START_DATE],4,2),SUBSTRING([CLASSIFICATION_START_DATE],1,2)) AS event_date
FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses] AS a
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid 

WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'ICD10'
	AND [clinical_coding_system_id] >= '10'
	AND [DIAGNOSIS_TYPE] in ('A','B','V','P')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'DSM'
	AND [clinical_coding_system_id] IN ('07','7')
	AND [DIAGNOSIS_TYPE] in ('A','B','V','P')
)
GO

/********************************************************
INTERRAI

Alcohol- Highest number of drinks in any single sitting in LAST 14 DAYS / 5 or more
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT [snz_uid]
	,[moh_irai_assessment_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moh_clean].[interrai]
WHERE moh_irai_alcohol_one_settng_code = 3 /* 5+ drinks */
GO

/********************************************************
MSD INCAPACITATION
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid, event_date)
SELECT [snz_uid]
	,[msd_incp_incp_from_date] AS event_date
FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_incapacity]
WHERE [msd_incp_incrsn_code] IN ('007','170')
OR [msd_incp_incrsn95_1_code] IN ('007','170')
OR [msd_incp_incrsn95_2_code] IN ('007','170')
OR [msd_incp_incrsn95_3_code] IN ('007','170')
OR [msd_incp_incrsn95_4_code] IN ('007','170')
OR [msd_incp_incapacity_code] IN ('007','170')
GO

/********************************************************
DRIVING DISQUALIFICATION
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT snz_uid, [moj_chg_offence_from_date] AS event_date
FROM [IDI_Clean_YYYYMM].[moj_clean].[charges] AS a
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING(moj_chg_offence_code, 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'offences'
)
GO

/********************************************************
POLICE NIA LINKS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid, event_date)
SELECT snz_uid, [nia_links_rec_date] AS event_date
FROM [IDI_Clean_YYYYMM].[pol_clean].[nia_links] AS a
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[ref_diagnosis] AS r
	WHERE SUBSTRING([nia_links_latest_inc_off_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'alcohol_abuse'
	AND r.code_type = 'offences'
)
GO

/****************************************************************************************************************
FINAL TABLE CREATION
****************************************************************************************************************/

/* Add indexes */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] (snz_uid);
GO
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] (snz_uid);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_mha_alcohol_abuse_or_dependence]
GO

WITH multi_to_add AS (
	SELECT snz_uid, event_date
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi] AS m
	WHERE EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo] AS s
		WHERE m.snz_uid = s.snz_uid
	)
)
SELECT DISTINCT snz_uid, event_date
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_mha_alcohol_abuse_or_dependence]
FROM (
	SELECT snz_uid, event_date
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo]

	UNION ALL

	SELECT snz_uid, event_date
	FROM multi_to_add
) AS k
GO

/********************************************************
TIDY UP
********************************************************/

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_mha_alcohol_abuse_or_dependence] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_mha_alcohol_abuse_or_dependence] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_solo]
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_alcohol_multi]
GO

