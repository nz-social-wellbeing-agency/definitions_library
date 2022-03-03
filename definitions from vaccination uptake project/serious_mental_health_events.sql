/**************************************************************************************************
Title: any indication of serious Mental Health
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions
Staff at MoH provided comments on this definition.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].priv_fund_hosp_discharges_diag
- [IDI_Clean].[moh_clean].priv_fund_hosp_discharges_event
- [IDI_Clean].[moh_clean].[PRIMHD]
- [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_disability] 
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_referral]
- [IDI_Clean].[msd_clean].[msd_incapacity]
- [IDI_Clean].[moh_clean].[nnpac]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list]
- [IDI_UserCode].[DL-MAA2021-49].[vacc_recent_serious_Mental_health]

Description:
Multi-source, any indicator of serious mental health event or diagnosis.

Intended purpose:
Has a person ever been diagnosed with a serious mental health condition.
Has a person had recent serious mental health diagnosis or event.

Notes:
1) Two types of events included:
	- any serious diagnosis - schizophrenia, Bi polar, major depressive disorder, schizoaffective disorder
	- any PRIMHD/MHINC service started in the reference period
	
2) Multiple sources included in definition:
	1. Y public hospital discharge diagnosis (ICD10) x 6 3 digit codes
	2. Y private hospital discharge diagnosis (ICD10) x 6 3 digit codes
	3. N MHINC service -- no as too early
	4.a Y PRIMHD service by referral period by date -- NB BASED ON RECENT SERVICE DATE
	4.b Y PRIMHD diagnosis codes
	5. Y InterRAI diagnosis by question x 2 questions
	6. Y SOCRATES by diagnosis x 2 codes
	7. Y MSD incapacitation

3) MoH advises that in PRIMHD, we consider a current referral to be any referral "open" within the period.
	So, the referral may have started prior or during the study period and the end date will be either during
	or 	after the end of the study period.
	
Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:
1) PRIMHD section only uses the referral start date. This means it only captures referrals that started during
	the study period. To capture all open referrals code needs to be modified to consider referral end dates.

2) Some MHA referrals go on have no activity (e.g. referral declined). Depending on the purpose of the research
	it would be more effective to consider referrals that resulted in some kind of specialist MHA service.

History (reverse order):
2022-02-28 SA incorporate comments from MoH staff
2021-12-01 SA tidy
2021-11-02 CW
**************************************************************************************************/

/* create table of all possible events */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (
	snz_uid INT,
	code VARCHAR(12),
	descript VARCHAR(25),
	record_source VARCHAR(5),
	event_date DATE,
);
GO

/********************************************************
Public hospital events
********************************************************/
--ICD10
--F33 major pressive disorder
--F30 manic
--F31 Bipolar
--F20 schizophrenia
--F21 schizotypal
--F25 schizaffective

--[IDI_Metadata].[clean_read_CLASSIFICATIONS].[acc_ICD10_Code]
--WHERE SUBSTRING ([Code],1,1)='F'

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT b.snz_uid
	,[moh_dia_clinical_code]
	,NULL AS descript
	,'PUB' as record_source
	,[moh_evt_evst_date]
	--,[moh_dia_event_id_nbr]
FROM [IDI_Clean_20211020].[moh_clean].[pub_fund_hosp_discharges_diag] as a
INNER JOIN [IDI_Clean_20211020].[moh_clean].[pub_fund_hosp_discharges_event] as b
ON a.[moh_dia_event_id_nbr] = b.[moh_evt_event_id_nbr]
WHERE SUBSTRING([moh_dia_clinical_code],1,3) in ('F30','F31','F33','F20','F21','F25') 
AND [moh_dia_clinical_sys_code]=[moh_dia_submitted_system_code]
GO

/********************************************************
Private hospital events
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT b.snz_uid
    ,moh_pri_diag_clinic_code
	,NULL AS descript
	,'PRI' as record_source
	,CAST(moh_pri_evt_start_date AS DATE) AS [date]
FROM [IDI_Clean_20211020].[moh_clean].priv_fund_hosp_discharges_diag as a
INNER JOIN [IDI_Clean_20211020].[moh_clean].priv_fund_hosp_discharges_event as b
ON a.moh_pri_diag_event_id_nbr = b.moh_pri_evt_event_id_nbr 
WHERE SUBSTRING(moh_pri_diag_clinic_code,1,3) in ('F30','F31','F33','F20','F21','F25') 
AND moh_pri_diag_clinic_sys_code = moh_pri_diag_sub_sys_code
GO

/********************************************************
PRIHMD events
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT DISTINCT [snz_uid]
	,NULL AS code
	,NULL AS descript
	,'PRM' AS record_source
    ,[moh_mhd_referral_start_date]
FROM [IDI_Clean_20211020].[moh_clean].[PRIMHD]
GO

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT b.[snz_uid]
	,[CLINICAL_CODE] AS code
	,NULL AS descript
	,'PRC' AS record_source
    ,[CLASSIFICATION_START_DATE]
FROM [IDI_Adhoc].[clean_read_MOH_PRIMHD].[primhd_diagnoses] AS a
INNER JOIN [IDI_Clean_20211020].[security].[concordance] AS b
ON a.[snz_moh_uid] = b.[snz_moh_uid] 
WHERE ([CLINICAL_CODING_SYSTEM_ID] >= 10 AND SUBSTRING([CLINICAL_CODE],1,3) in ('F30','F31','F33','F20','F21','F25'))
/* MOH staff recommend = 7 instead of >= 7 as this is the only code associated with DSM-IV */
OR ([CLINICAL_CODING_SYSTEM_ID] = 7 AND SUBSTRING([CLINICAL_CODE],1,4) in ('2960','2962','2963','2964','2965','2966','2967','2968'))
OR ([CLINICAL_CODING_SYSTEM_ID] = 7 AND SUBSTRING([CLINICAL_CODE],1,3) in ('295'))
GO

/********************************************************
INTERRAI - health of older people assessment
********************************************************/
-- [moh_irai_depression_code], [moh_irai_schizophrenia_code], [moh_irai_bipolar_code]
--0	Not present
--1	Primary diagnosis / diagnoses for current stay
--2	Diagnosis present, receiving active treatment
--3	Diagnosis present, monitored but no active treatment

--FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_question_lookup]
--WHERE [IDI Variable Name] like'%schi%'
--FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_interrai_answer_lookup]
--WHERE [IDI Variable Name] like'%bipolar%'

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT [snz_uid]
	,NULL AS code
	,NULL AS descript
	,'IRA' AS record_source
	,[moh_irai_assessment_date]
FROM [IDI_Clean_20211020].[moh_clean].[interrai]
WHERE [moh_irai_schizophrenia_code] in (1,2,3)
OR [moh_irai_bipolar_code] in (1,2,3)
GO

/********************************************************
SOCRATES funded disability
********************************************************/
--1306 schizophrenia
--1303 Bipolar

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT b.snz_uid
	,CAST([Code] AS VARCHAR) AS code
	,[Description]
	,'SOC' AS record_source
	,COALESCE([FirstContactDate], [ReferralDate]) As event_date
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_disability] AS a 
LEFT JOIN [IDI_Clean_20211020].[moh_clean].[pop_cohort_demographics] AS b
ON a.snz_moh_uid = b.snz_moh_uid 
LEFT JOIN (
	SELECT DISTINCT snz_moh_uid
		,[FirstContactDate]
		,CAST(SUBSTRING([FirstContactDate], 1, 7) AS DATE) AS event_date
	FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment]
	WHERE [FirstContactDate] IS NOT NULL
) AS c
ON a.snz_moh_uid = c.snz_moh_uid 
LEFT JOIN (
	SELECT DISTINCT snz_moh_uid
		,[ReferralDate]
		,CAST(SUBSTRING([ReferralDate], 1, 7) AS DATE) AS event_date
	FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_referral]
	WHERE [ReferralDate] IS NOT NULL
) AS e
ON a.snz_moh_uid = e.snz_moh_uid
WHERE code IN ('1306','1303')
GO

/********************************************************
MSD - medical certificates and incapacitation
********************************************************/
--161	Depression
--162	Bipolar disorder
--163	Schizophrenia

-- Look up metadata:
-- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_incapacity_reason_code_3]
-- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_incapacity_reason_code_4]
--WHERE [classification] LIKE '%mental%'

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT snz_uid
	,[msd_incp_incapacity_code] AS code
	,NULL AS descript
	,'INCP' AS record_source 
	,[msd_incp_incp_from_date]
FROM [IDI_Clean_20211020].[msd_clean].[msd_incapacity]
WHERE [msd_incp_incrsn95_1_code] IN ('162', '163')
OR [msd_incp_incrsn95_2_code] IN ('162', '163')
OR [msd_incp_incrsn95_3_code] IN ('162', '163')
OR [msd_incp_incrsn95_4_code] IN ('162', '163')
OR [msd_incp_incapacity_code] IN ('162', '163')
GO

/********************************************************
NNPAC
********************************************************/
--COOC0058  Mental Health Worker
--HOP235    AT & R (Assessment  Treatment & Rehabilitation) Inpatient - Mental Health service(s) for Elderly

-- Look up metadata:
-- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_nnpac_purchase_unit]
--WHERE [PU_DESCRIPTION] like '%mental%'

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid, code, descript, record_source, event_date)
SELECT [snz_uid]
	,[moh_nnp_purchase_unit_code] AS code
	,NULL AS descript
	,'NAP' AS record_source
    ,[moh_nnp_service_date]
FROM [IDI_Clean_20211020].[moh_clean].[nnpac]
WHERE [moh_nnp_purchase_unit_code] IN ('COOC0058','HOP235')
GO

/********************************************************
Conclude
********************************************************/

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/* View: any serious diagnosis or recent acute mental health service use */
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_recent_serious_Mental_health]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_recent_serious_Mental_health] AS 
SELECT DISTINCT snz_uid
FROM [IDI_Sandpit].[DL-MAA2021-49].[vacc_serious_Mental_health_list]
WHERE record_source IN ('PRI','PUB','SOC','IRA','PRC','INCP') 
OR (record_source = 'PRM' AND event_date >= '2019-01-01')
