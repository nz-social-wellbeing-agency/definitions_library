/**************************************************************************************************
Title: Schizophrenia spectrum
Author: Craig Wright
Re-work: Manjusha Radhakrishnan, Simon Anastasiadis
Reviewer:

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moh_clean].[mortality_diagnosis]
- [IDI_Clean].[moh_clean].[mortality_registrations]
- [IDI_Clean].[msd_clean].[msd_incapacity]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[lab_claims]
- [IDI_Clean].[acc_clean].[claims]
- [IDI_Clean].[acc_clean].[medical_codes]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS_CLIN_DIAG_CODES].[clinical_codes]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_question_lookup]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_answer_lookup]
- [IDI_Adhoc].[clean_read_MOH_PRIMHD].[moh_primhd_mhinc]
- [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_disability]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_referral]

Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_mha_schizophrenia]
- [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis]

Description:
All instances that point to a person having schizophrenia
For incidence and prevalence - see notes.

Notes:
1) Estimates for prevalance:
	2015 estimate of 6.7 schizophrenics per 1000

2) Incidence and prevalence
	  Incidence = development of a condition during a particular time period (new only).
	  Prevalance = affected by the condition during a particular time period (new + existing).
	Plots of incidence (from this definition) against deprivation show a non-monotinic pattern.
	Incidence increases from deprivation 1-8 but deprivation 9 and 10 show lower incidence.
	This is likely because of barriers to access (cost, transport, availability etc.).
	
	So we can not use point in time measures to accurately access prevalance.
	Instead, when using this definition, we recommend considering every person's history.
	For example, if we consider any schizophrenia indication in the last 10 years, then we observe
	a more likely relationship between schizophrenia and deprivation. This suggests that people in high
	deprivation do get some treatment, but much less frequently than those who are less deprived.
	Such an approach is reasonable, as this condition is likely to persist for at least 10 years.

3) Some treatments are used to treat this condition and other conditions. This is most common
	with pharmaceuticals. For these treatments, we do the following:
	- Gather the treatments that serve multiple purposes together separately.
	- Where a person only has records that also treat other conditions, discard those records
	- Where a person has other evidence of schizophrenia, add the treatments for multiple conditions
		to the table.
	For example, in 2010 a person is diagnosed in hospital with schizophrenia, in 2008 they received drugs
	that are used to treat schizophrenia or depression. Then we include the 2008 date as an earlier probable indicator.

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

Issues:
1) Because all our MHA tables use the same lookup/reference table, and all definitions load
	this table into the database, you can not run the definitions in parallel. Because, each
	definition will delete the reference table when it starts running and this will interfere 
	with the definitions that are already running.
	
Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
History (reverse order):
2022-09-12 SA Prep for library
2022-07-19 MR Tidy-up
2022-06-10 CW Definition creation
*************************************************************************************************************************/

/* Load diagnosis lookup table */

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] (
	diagnosis	VARCHAR(30),
	code_type	VARCHAR(30),
	code		VARCHAR(10),
	aux			VARCHAR(30),
	explanation	VARCHAR(255),
)

BULK INSERT [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis]
FROM '\\prtprdsasnas01\DataLab\MAA\MAA2021-60\Youth classification trees\Definitions\diagnosis_codes.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/********************************************************
TABLES TO APPEND TO
********************************************************/

/* Diagnosis or treatment only indicates schizophrenia */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (
	snz_uid	INT,
	event_date DATE,
)

/* Diagnosis or treatment used for schizophrenia and other conditions */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi] (
	snz_uid	INT,
	event_date DATE,
)

/********************************************************
MORTALITY

Note that people who died with this diagnosis will likely
have had bipolar for a while before death
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)

SELECT b.snz_uid
	  ,EOMONTH(DATEFROMPARTS([moh_mor_death_year_nbr],[moh_mor_death_month_nbr],1)) AS event_date
FROM [IDI_Clean_202203].[moh_clean].[mortality_diagnosis] AS a
INNER JOIN [IDI_Clean_202203].[moh_clean].[mortality_registrations] AS b
ON a.[snz_dia_death_reg_uid] = b.snz_dia_death_reg_uid
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD10'
	AND [moh_mort_diag_clinic_sys_code] >= 10
	AND [moh_mort_diag_clinic_type_code] in ('A','B','V')
)
OR EXISTS (
SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_mort_diag_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD9'
	AND [moh_mort_diag_clinic_sys_code] IN ('06','6')
	AND [moh_mort_diag_clinic_type_code] in ('A','B','V')
)
GO

/********************************************************
MSD INCAPACITATION
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT [snz_uid]
	,[msd_incp_incp_from_date] AS event_date
FROM [IDI_Clean_202203].[msd_clean].[msd_incapacity]
WHERE [msd_incp_incrsn_code] = '163'
OR [msd_incp_incrsn95_1_code] = '163'
OR [msd_incp_incrsn95_2_code] = '163'
OR [msd_incp_incrsn95_3_code] = '163'
OR [msd_incp_incrsn95_4_code] = '163'
OR [msd_incp_incapacity_code] = '163'
GO

/********************************************************
PHARMACEUTICALS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT a.[snz_uid]
		,[moh_pha_dispensed_date] AS event_date
FROM [IDI_Clean_202203].[moh_clean].[pharmaceutical] AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(CAST(CHEMICAL_ID AS VARCHAR), 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'pharm_chemical'
	AND r.aux = 'sole'
)
GO

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi] (snz_uid, event_date)
SELECT a.[snz_uid]
		,[moh_pha_dispensed_date] AS event_date
FROM [IDI_Clean_202203].[moh_clean].[pharmaceutical] AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] AS b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(CAST(CHEMICAL_ID AS VARCHAR), 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'pharm_chemical'
	AND r.aux = 'multiple'
)
GO

/********************************************************
INTERRAI
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT [snz_uid]
	,[moh_irai_assessment_date] AS event_date
FROM [IDI_Clean_202203].[moh_clean].[interrai]
WHERE moh_irai_schizophrenia_code > 0
GO

/********************************************************
PRIVATE HOSPITAL DISCHARGE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT a.[snz_uid]
	,CAST([moh_pri_evt_start_date] AS DATE) AS event_date
FROM [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_event] AS a
INNER JOIN [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_diag] AS b
ON a.[moh_pri_evt_event_id_nbr] = b.[moh_pri_diag_event_id_nbr]
AND [moh_pri_diag_sub_sys_code] = [moh_pri_diag_clinic_sys_code]
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING([moh_pri_diag_clinic_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD10'
	AND [moh_pri_diag_sub_sys_code] >= '10'
	AND [moh_pri_diag_diag_type_code] IN ('A','B','V')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING([moh_pri_diag_clinic_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD9'
	AND [moh_pri_diag_sub_sys_code] IN ('06','6')
	AND [moh_pri_diag_diag_type_code] IN ('A','B','V')
)
GO

/********************************************************
PUBLIC HOSPITAL DISCHARGE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT b.[snz_uid]
	,[moh_evt_evst_date] AS event_date
FROM [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_diag] AS a
INNER JOIN [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_event] AS b
ON [moh_dia_clinical_sys_code] = [moh_dia_submitted_system_code]
AND [moh_evt_event_id_nbr]=[moh_dia_event_id_nbr]
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD10'
	AND [moh_dia_submitted_system_code] >= '10'
	AND [moh_dia_diagnosis_type_code] IN ('A','B','V')
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[moh_dia_clinical_code], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD9'
	AND [moh_dia_submitted_system_code] IN ('06','6')
	AND [moh_dia_diagnosis_type_code] IN ('A','B','V')
)
GO

/********************************************************
PRIMHD AND MHINC
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT b.snz_uid
      ,[classification_start] AS event_date
FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[moh_primhd_mhinc] AS a
INNER JOIN [IDI_Clean_202203].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid 
WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD10'
	AND [clinical_coding_system_id] >= '10'
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'DSM'
	AND [clinical_coding_system_id] IN ('07','7')
)
GO

/********************************************************
PRIMHD DIAGNOSIS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT snz_uid
      ,DATEFROMPARTS(SUBSTRING([CLASSIFICATION_START_DATE],7,4),SUBSTRING([CLASSIFICATION_START_DATE],4,2),SUBSTRING([CLASSIFICATION_START_DATE],1,2)) AS event_date
FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses] AS a
INNER JOIN [IDI_Clean_202203].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid 

WHERE EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'ICD10'
	AND [clinical_coding_system_id] >= '10'
)
OR EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2018-48].[ref_diagnosis] AS r
	WHERE SUBSTRING(a.[CLINICAL_CODE], 1, LEN(r.code)) = r.code
	AND r.diagnosis = 'schizophrenia'
	AND r.code_type = 'DSM'
	AND [clinical_coding_system_id] IN ('07','7')
)
GO

/********************************************************
SOCRATES
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid, event_date)
SELECT b.snz_uid
	  ,COALESCE(
		CAST(SUBSTRING([FirstContactDate], 1, 7) AS DATE),
		CAST(SUBSTRING([ReferralDate],1,7) AS DATE)
		) AS event_date
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].moh_disability AS a 
INNER JOIN [IDI_Clean_202203].[security].[concordance] AS b 
ON a.snz_moh_uid = b.snz_moh_uid
INNER JOIN [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment] AS c 
ON a.snz_moh_uid = c.snz_moh_uid 
LEFT JOIN [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_referral] AS e 
ON a.snz_moh_uid = e.snz_moh_uid
WHERE a.[Code] = '1306'

/****************************************************************************************************************
FINAL TABLE CREATION
****************************************************************************************************************/

/* Add indexes */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] (snz_uid);
GO
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi] (snz_uid);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_mha_schizophrenia]
GO

WITH multi_to_add AS (
	SELECT snz_uid, event_date
	FROM [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi] AS m
	WHERE EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo] AS s
		WHERE m.snz_uid = s.snz_uid
	)
)
SELECT DISTINCT snz_uid, event_date
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_mha_schizophrenia]
FROM (
	SELECT snz_uid, event_date
	FROM [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo]

	UNION ALL

	SELECT snz_uid, event_date
	FROM multi_to_add
) AS k
GO

/********************************************************
TIDY UP
********************************************************/

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_mha_schizophrenia] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_mha_schizophrenia] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_solo]
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_schizophrenia_multi]
GO
