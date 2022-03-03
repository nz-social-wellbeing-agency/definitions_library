/**************************************************************************************************
Title: Residential care
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[acc_clean].[payments]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist_202110]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Clean].[data].[snz_res_pop]
- [IDI_Clean].[data].[personal_detail]
- address_descriptors.sql --> [IDI_Sandpit].[DL-MAA2021-49].[vacc_addr_read]
- functional_disability.sql --> [IDI_Sandpit].[DL-MAA2021-49].[vacc_functional_disability]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care]
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care_and_disability]

Description:
Multi-source indicator for people who are in residential care in 2021

Intended purpose:
Identifying people who are in residential care or who provide residential care.
Includes interaction of disability and residential care

Notes:
1) Multiple sources have been combined for this definition:
	1. ACC residential care
	2. MOH SORCRATES residential services
		Financial Management Account System (FMAS) using General Ledger (GL) account codes
	3. MOH InterRAI assessment
		
2) Key variables/coding:
	residential type for disabled people
		- 0 is not disabled
		- 1 is disabled and in residential care
		- 2 is disabled and living with non-disabled adult 18+ years
		- 3 is disabled and not living with an non-disabled adult 18+ years
	sole parent
		1 adult living with a child or children
		this applies to children and the parent

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Residential population year = 2021
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

/***********************************
1. ACC
***********************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_acc]
GO

SELECT c.snz_uid
	,p.[snz_acc_claim_uid]
	,[acc_pay_gl_account_text]
	,[acc_pay_first_service_date] as care_start_date
	,[acc_pay_last_service_date] as care_end_date
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_acc]
FROM [IDI_Clean_20211020].[acc_clean].[payments] AS p
INNER JOIN [IDI_Clean_20211020].[acc_clean].[claims] AS c
ON p.[snz_acc_claim_uid] = c.[snz_acc_claim_uid]
WHERE ([acc_pay_gl_account_text] LIKE '%Res Support one%' -- residential support
	OR [acc_pay_gl_account_text] LIKE '%Res Support two%' 
	OR [acc_pay_gl_account_text] LIKE '%Res Support 3%')
AND (
	YEAR([acc_pay_last_service_date]) >= 2021 -- still ongoing / open
	OR [acc_pay_last_service_date] IS NULL
)
GO

/***********************************
2. MOH SOCRATES
***********************************/
--6640 (YPD resthome)
--6650 (YPD Hospitals)
--6645 (CRL - community residential living). This also includes YP-DAC (non-residential)
--6675 (Rehabilitation)
--YP-CICLPB is kind of residential care supporting clients in their homes but clients pay rent, food, utilities etc

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_socrates]
GO

SELECT b.snz_uid
	,a.[snz_moh_uid]
	,[StartDate_Value] as care_start_date
	,[EndDate_Value] as care_end_date
	,[FMISAccountCode_Value]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_socrates]
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist_202110] as a
INNER JOIN [IDI_Clean_20211020].[security].[concordance] as b
ON a.snz_moh_uid = b.snz_moh_uid 
WHERE [FMISAccountCode_Value] in ('6640','6650','6645','6675','YP-DAC') -- residential support
AND (
	YEAR(a.[EndDate_Value]) >=2021 -- still ongoing / open
	OR a.[EndDate_Value] IS NULL
)
GO

/***********************************
3. MOH InterRAI
***********************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_interrai]
GO

SELECT [snz_uid]
	,[snz_moh_uid]
	,[moh_irai_care_level_text]
	,[moh_irai_assessment_type_text]
	,[moh_irai_assess_version_text]
	,[moh_irai_assessment_date] AS care_start_date
	,[moh_irai_consent_text]
	,[moh_irai_location_text]
	,[moh_irai_res_status_admit_code]
	,[moh_irai_res_status_usual_code]
	,[moh_irai_prior_living_code]
	,[moh_irai_lives_someone_new_ind]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_interrai]
FROM [IDI_Clean_20211020].[moh_clean].[interrai]
WHERE [moh_irai_location_text] !='HOME' -- not living at HOME
AND (
	YEAR([moh_irai_assessment_date]) >= 2021 -- still ongoing / open
	OR [moh_irai_assessment_date] IS NULL
)
GO

/***********************************
List of people in residential care
***********************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care]
GO

SELECT DISTINCT snz_uid
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care]
FROM (
	SELECT snz_uid FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_acc]
	UNION ALL
	SELECT snz_uid FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_socrates]
	UNION ALL
	SELECT snz_uid FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_interrai]
) AS a
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care] (snz_uid)
GO

/***********************************
Disability and residential care
***********************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info]
GO

SELECT a.[snz_uid]
	,p.snz_birth_date_proxy
	,DATEDIFF(YEAR,p.snz_birth_date_proxy,'2021-11-11') AS age
	,[snz_idi_address_register_uid] AS address_uid
	,IIF(c.care_residential = 1, 1, 0) AS care_residential
	,IIF(d.any_functional_disability IN (1,2), 1, 0) AS disability
	,IIF(d.any_functional_disability IS NULL, 1, 0) AS disability_level
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info]
FROM (
	SELECT [snz_uid]
	FROM [IDI_Clean_20211020].[data].[snz_res_pop]
	WHERE srp_ref_date = '2021-06-30'
) AS a
LEFT JOIN [IDI_Clean_20211020].[data].[personal_detail] AS p
ON a.snz_uid = p.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2021-49].[vacc_addr_read] as b
ON a.snz_uid = b.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care] as c
ON a.snz_uid = c.snz_uid
LEFT JOIN [IDI_Sandpit].[DL-MAA2021-49].[vacc_functional_disability] as d
ON a.snz_uid = d.snz_uid
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info] (address_uid)
GO

-- number of peple in household by age & disability
DROP TABLE IF EXISTS #address_desc
GO

SELECT address_uid
	,COUNT(*) AS num
	,SUM(IIF(age >= 18, 1, 0)) AS adults
	,SUM(IIF(disability > 0 AND age >= 18, 1, 0)) AS disabled_adults
	,SUM(IIF(age BETWEEN 0 AND 17, 1, 0)) AS children
	,SUM(IIF(disability > 0 AND age BETWEEN 0 AND 17 , 1, 0)) AS disabled_children
INTO #address_desc
FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info]
GROUP BY address_uid
GO

CREATE NONCLUSTERED INDEX my_index ON #address_desc (address_uid)
GO

-- final table

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care_and_disability]
GO

SELECT a.*
	,b.adults
	,b.children
	,b.disabled_adults
	,b.disabled_children
	,IIF(a.address_uid IS NOT NULL
		AND b.adults = 1
		AND c.children >= 1, 1, 0) AS sole_parent
	--residential type for disabled people
	--0 is not disabled
	--1 is disabled and in residential care
	--2 is disabled and living with non-disabled adult 18+ years
	--3 is disabled and not living with an non-disabled adult 18+ years
	,CASE
		WHEN a.address_uid IS NOT NULL AND care_residential = 1 and disability = 1 THEN 1
		WHEN a.address_uid IS NOT NULL AND care_residential = 0 AND disability = 1 AND b.disabled_adults > 0 AND b.adults > d.disabled_adults then 2
		WHEN a.address_uid IS NOT NULL AND care_residential = 0 AND disability = 1 AND b.disabled_adults > 0 AND b.adults = d.disabled_adults then 3
		ELSE 0 END AS residential_type
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care_and_disability]
FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info] AS a
LEFT JOIN #address_desc AS b
ON a.address_uid = b.address_uid

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care_and_disability] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_residential_care_and_disability] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

-- tidy up
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_acc]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_socrates]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_res_care_interrai]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_combined_info]
GO
DROP TABLE IF EXISTS #address_desc
GO
