/**************************************************************************************************
Title: Health Service Users Population (proxy)
Author: Craig Wright

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
Proxy Health Service User (HSU) population from 2020-01-01

Intended purpose:
Proxy for population using health services.
This population is constructed by MOH for their own analysis outside the IDI.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[interrai]
- [IDI_Clean].[moh_clean].[lab_claims]
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Clean].[moh_clean].[nnpac]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[PRIMHD]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist_202110]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy]

Notes:
1) By construction this is a multi-data source method. We draw interactions from
	a wide range of MOH tables:
		1. interrai
		2. labs claims
		3. NES enrolment
		4. nnpac
		5. PHARMS
		6. PRIMHD
		7. private hospital
		8. public hospital 
		9. socrates

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
  Health events since = 'YYYY-MM-DD'
 
Issues:

History (reverse order):
2021-11-25 SA review and tidy
2021-09-30 CW
**************************************************************************************************/

/* create table of all identities */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (
	snz_uid INT,
	record_source VARCHAR(5),
);
GO

/***************************************************************************************************************
append records from each source into the table
***************************************************************************************************************/

/********************************************************
1. interrai - NONE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'IRAI' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[interrai]
WHERE [moh_irai_assessment_date] >= 'YYYY-MM-DD'
GO

/********************************************************
2. labs claims - NONE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'labs' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[lab_claims]
WHERE [moh_lab_visit_date] >= 'YYYY-MM-DD'
GO

/********************************************************
3. NES enrolment - many months
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT b.snz_uid
	,'NES' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[nes_enrolment] AS a
INNER JOIN [IDI_Clean_YYYYMM].[moh_clean].[pop_cohort_demographics] as b
ON a.snz_moh_uid=b.snz_moh_uid
WHERE CAST([moh_nes_snapshot_month_date] AS DATE) >= 'YYYY-MM-DD'
GO

/********************************************************
4. nnpac - NONE
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'nnpac' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[nnpac]
WHERE [moh_nnp_service_date] >= 'YYYY-MM-DD'
GO

/********************************************************
5. PHARMS
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'pharm' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[pharmaceutical]
WHERE [moh_pha_dispensed_date] >= 'YYYY-MM-DD'
GO

/********************************************************
6. PRIMHD
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'prim' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[PRIMHD]
WHERE [moh_mhd_referral_end_date] >= 'YYYY-MM-DD'
OR [moh_mhd_referral_end_date] IS NULL
GO

/********************************************************
7. private hospital
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'priv' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[priv_fund_hosp_discharges_event]
WHERE [moh_pri_evt_end_date] >= 'YYYY-MM-DD'
GO

/********************************************************
8. public hospital 
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT [snz_uid]
	,'pubh' AS record_source
FROM [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_event]
WHERE [moh_evt_even_date] >= 'YYYY-MM-DD'
GO

/********************************************************
9. socrates
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list] (snz_uid, record_source)
SELECT DISTINCT b.snz_uid
	,'socr' AS record_source
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist_202110] AS a
INNER JOIN [IDI_Clean_YYYYMM].[moh_clean].[pop_cohort_demographics] AS b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE [EndDate_Value] >= 'YYYY-MM-DD'
GO

/***************************************************************************************************************
combine to a single list
***************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy]
GO

SELECT DISTINCT snz_uid
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy]
FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list]

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_hsu_list]
GO
