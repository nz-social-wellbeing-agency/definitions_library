/**************************************************************************************************
Title: Level 2 prioritised ethnicity
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[dia_clean].[births]
- [IDI_Clean].[dia_clean].[births]
- [IDI_Clean].[dia_clean].[births]
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Adhoc].[clean_read_MOH_CIR].[moh_cir_nhi20211026]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[moe_clean].[student_per]
- [IDI_Clean].[acc_clean].[clients]
- [IDI_Clean].[msd_clean].[msd_swn]
- [IDI_Clean].[sla_clean].[msd_borrowing]
- [IDI_Clean].[sofie_clean].[person_waves]
- [IDI_Clean].[sofie_clean].[hq_id]
- [IDI_Clean].[hlfs_clean].[data]
- [IDI_Clean].[hlfs_clean].[nzis]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_ethnicity_level_2]
- [IDI_UserCode].[DL-MAA2021-49].[vacc_ethnicity_level_1_and_2]

Description:
Level 2 source prioritised ethnic codes AS per personal detail table source ranking

Intended purpose:
More detailed ethnicity information for people than top 6 categories.

Notes:
1) This approach follows the same broad concept AS Stats NZ's approach for the person_details
	table: Data from all sources is collated. For each person the final value is drawn from 
	the highest quality source available for that person.
2) Multiple sources are used. The sources and their rankings are (1 is highest rank):
	1. census 2018
	2. census 2013
	3. DIA - only births data appears useful
	4. MOH NES 
	5. MOH NHI
	6. CIR ethnicity
	7. MOE 
	8. ACC
	9. MSD
	10. SLA MSD called SLM
	11. HES
	12. SOFIE AS SOF
	13. LINZ Migrant Survey - not included
	14. HLFS
	15. ACM Auckland city mission - not included AS one digit codes
	16. GSS
3) Codes for non-response or response unidentifiable are given using ranks 98 and 99.

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

/* create table of all ethnicities */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (
	snz_uid INT,
	ethnic_code VARCHAR(20),
	source_rank INT,
	record_date DATE,
);
GO

/*******************************************************************************************
append records from each source into the table
*******************************************************************************************/

/************************************
Census 2018
************************************/
--Impute rank description
--11  1  2018 Census form    
--12  1  2018 Census (missing from individual form)    
--21  2  2013 Census    
--31  97  Admin data    
--41  99  Within household donor    
--42  99  Donor's 2018 Census form    
--43  99  Donor's 2018 Census (missing from individual form)    
--44  99  Donor's response sourced from 2013 Census    
--45  99  Donor's response sourced from admin data    
--46  99  Donor's response sourced from within household    
--51  99  No information   

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,[cen_ind_eth_output_level2] AS ethnic_code
	,CASE
		--if ethnic code is 94-98 THEN set rank to 98
		WHEN SUBSTRING([cen_ind_eth_output_level2],1,2) in ('94','95','96','97','98') THEN 98 
		WHEN [cen_ind_ethgr_impt_ind] in ('11','12') THEN 1
		WHEN [cen_ind_ethgr_impt_ind] in ('21') THEN 2 
		WHEN [cen_ind_ethgr_impt_ind] in ('31') THEN 97
		WHEN [cen_ind_ethgr_impt_ind] in ('41','42','43','44','45','46','51') THEN 99
		WHEN [cen_ind_ethgr_impt_ind] is null THEN 99
		end AS source_rank
	,CAST('2018-03-05' AS record_date) AS record_date
FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2018]
WHERE snz_uid IS NOT NULL
GO

/************************************
Census 2013
************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([cen_ind_eth_rand6_grp1_code],1,2),';',
		SUBSTRING([cen_ind_eth_rand6_grp2_code],1,2),';',
		SUBSTRING([cen_ind_eth_rand6_grp3_code],1,2),';',
		SUBSTRING([cen_ind_eth_rand6_grp4_code],1,2),';',
		SUBSTRING([cen_ind_eth_rand6_grp5_code],1,2),';',
		SUBSTRING([cen_ind_eth_rand6_grp6_code],1,2)) AS ethnic_code
	,CASE
		WHEN SUBSTRING([cen_ind_eth_rand6_grp1_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([cen_ind_eth_rand6_grp1_code],1,2) in ('99') THEN 99
		else 2 END AS source_rank
	,CAST('2013-03-05' AS DATE) AS record_date
FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2013]
WHERE snz_uid IS NOT NULL
GO

/************************************
DIA births/deaths/marriages/civil unions
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([dia_bir_ethnic1_snz_code],1,2),';',
		SUBSTRING([dia_bir_ethnic2_snz_code],1,2),';',
		SUBSTRING([dia_bir_ethnic3_snz_code],1,2),';',
		SUBSTRING([dia_bir_ethnic4_snz_code],1,2),';',
		SUBSTRING([dia_bir_ethnic5_snz_code],1,2),';',
		SUBSTRING([dia_bir_ethnic6_snz_code],1,2)) AS ethnic_code
	,CASE
		WHEN SUBSTRING([dia_bir_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([dia_bir_ethnic1_snz_code],1,2) in ('99') THEN 99
		else 3 END AS source_rank
	,DATEFROMPARTS([dia_bir_birth_year_nbr],[dia_bir_birth_month_nbr],1) AS record_date
FROM [IDI_Clean_20211020].[dia_clean].[births]
WHERE [dia_bir_ethnic1_snz_code] IS NOT NULL
AND snz_uid IS NOT NULL
GO

--parent 1
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT parent1_snz_uid AS snz_uid
	,CONCAT(
		SUBSTRING([dia_bir_parent1_ethnic1_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent1_ethnic2_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent1_ethnic3_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent1_ethnic4_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent1_ethnic5_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent1_ethnic6_snz_code],1,2)) AS ethnic_code
	,CASE
		WHEN SUBSTRING([dia_bir_parent1_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([dia_bir_parent1_ethnic1_snz_code],1,2) in ('99') THEN 99
		else 3 END AS source_rank
	,datefromparts([dia_bir_birth_year_nbr],[dia_bir_birth_month_nbr],1) AS record_date
FROM [IDI_Clean_20211020].[dia_clean].[births]
WHERE [dia_bir_parent1_ethnic1_snz_code] IS NOT NULL
AND parent1_snz_uid IS NOT NULL
GO

--parent 2
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT parent2_snz_uid AS snz_uid
	,CONCAT(
		SUBSTRING([dia_bir_parent2_ethnic1_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent2_ethnic2_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent2_ethnic3_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent2_ethnic4_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent2_ethnic5_snz_code],1,2),';',
		SUBSTRING([dia_bir_parent2_ethnic6_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([dia_bir_parent2_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([dia_bir_parent2_ethnic1_snz_code],1,2) in ('99') THEN 99
		else 3 END AS source_rank
	,datefromparts([dia_bir_birth_year_nbr],[dia_bir_birth_month_nbr],1) AS record_date
FROM [IDI_Clean_20211020].[dia_clean].[births]
WHERE [dia_bir_parent2_ethnic1_snz_code] IS NOT NULL
AND parent2_snz_uid IS NOT NULL
GO

/************************************
MOH PHO
************************************/
--keep latest rank 4 ethnic record

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT b.snz_uid
	,CONCAT(
		SUBSTRING([moh_nes_ethnic1_snz_code],1,2),';',
		SUBSTRING([moh_nes_ethnic2_snz_code],1,2),';',
		SUBSTRING([moh_nes_ethnic3_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN [moh_nes_ethnic1_snz_code] in ('94','95','96','97','98') THEN 98
		WHEN [moh_nes_ethnic1_snz_code]='99' THEN 99
		else 4 END AS source_rank
	,cast([moh_nes_snapshot_month_date] AS record_date) AS record_date
FROM [IDI_Clean_20211020].[moh_clean].[nes_enrolment] AS a
INNER JOIN [IDI_Clean_20211020].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE [moh_nes_ethnic1_snz_code] IS NOT NULL
AND b.snz_uid IS NOT NULL
GO

/************************************
MOH NHI
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([moh_pop_ethnic1_snz_code],1,2),';',
		SUBSTRING([moh_pop_ethnic2_snz_code],1,2),';',
		SUBSTRING([moh_pop_ethnic3_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN [moh_pop_ethnic1_snz_code] in ('94','95','96','97','98') THEN 98
		WHEN [moh_pop_ethnic1_snz_code]='99' THEN 99
		else 5 END AS source_rank
	,[moh_pop_last_updated_date] AS record_date
FROM [IDI_Clean_20211020].[moh_clean].[pop_cohort_demographics]
WHERE snz_uid IS NOT NULL
GO

/************************************
CIR ethnicity
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT b.snz_uid
	,CONCAT(
		SUBSTRING(cast([ethnic_code_1] AS varchar),1,2),';',
		SUBSTRING(cast([ethnic_code_2] AS varchar),1,2),';',
		SUBSTRING(cast([ethnic_code_3] AS varchar),1,2)) AS ethnic_code
	,CASE 
		when cast([ethnic_code_1] AS varchar)in ('94','95','96','97','98') THEN 98
		when cast([ethnic_code_1] AS varchar)='99' THEN 99
		else 6 END AS source_rank
	,CAST('2021-10-26' AS DATE) AS record_date
FROM [IDI_Adhoc].[clean_read_MOH_CIR].[moh_cir_nhi20211026] AS a
INNER JOIN [IDI_Clean_20211020].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid
GO

/************************************
MOE
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([moe_spi_eth1_text],1,2),';',
		SUBSTRING([moe_spi_eth2_text],1,2),';',
		SUBSTRING([moe_spi_eth3_text],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([moe_spi_eth1_text],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([moe_spi_eth1_text],1,2)='99' THEN 99
		else 7 END AS source_rank
	,[moe_spi_mod_address_date] AS record_date
FROM [IDI_Clean_20211020].[moe_clean].[student_per]
WHERE [moe_spi_eth1_text] IS NOT NULL
AND snz_uid IS NOT NULL
GO

/************************************
ACC
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([acc_cli_ethnic1_snz_code],1,2),';',
		SUBSTRING([acc_cli_ethnic2_snz_code],1,2),';',
		SUBSTRING([acc_cli_ethnic3_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([acc_cli_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([acc_cli_ethnic1_snz_code],1,2)='99' THEN 99
		else 8 END AS source_rank
	,CAST('2021-03-01' AS DATE) AS record_date
FROM [IDI_Clean_20211020].[acc_clean].[clients]
WHERE snz_uid IS NOT NULL
GO

/************************************
MSD
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([msd_swn_ucvii_ethnic1_snz_code],1,2),';',
		SUBSTRING([msd_swn_ucvii_ethnic2_snz_code],1,2),';',
		SUBSTRING([msd_swn_ucvii_ethnic3_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([msd_swn_ucvii_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([msd_swn_ucvii_ethnic1_snz_code],1,2)='99' THEN 99
		else 9 END AS source_rank
	,CAST('2021-03-01' AS DATE) AS record_date
FROM [IDI_Clean_20211020].[msd_clean].[msd_swn]
WHERE snz_uid IS NOT NULL
GO

/************************************
Student Loans and Allowances MSD (SLM)
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT [snz_uid]
	,CONCAT(
		SUBSTRING([msd_sla_ethnic1_code],1,2),';',
		SUBSTRING([msd_sla_ethnic2_code],1,2),';',
		SUBSTRING([msd_sla_ethnic3_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([msd_sla_ethnic1_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([msd_sla_ethnic1_code],1,2)='99' THEN 99
		else 10 END AS source_rank
	,DATEFROMPARTS([msd_sla_year_nbr],7,1) AS record_date
FROM [IDI_Clean_20211020].[sla_clean].[msd_borrowing]
WHERE snz_uid IS NOT NULL
GO

/************************************
HES -Household Economic Survey
************************************/
--not included AS only 1-digit ethnic codes

/************************************
SOFIE
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT a.[snz_uid]
	,CONCAT(
		SUBSTRING([sofie_wav_ethnic1_snz_code],1,2),';',
		SUBSTRING([sofie_wav_ethnic2_snz_code],1,2),';',
		SUBSTRING([sofie_wav_ethnic3_snz_code],1,2),';',
		SUBSTRING([sofie_wav_ethnic4_snz_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([sofie_wav_ethnic1_snz_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([sofie_wav_ethnic1_snz_code],1,2)='99' THEN 99
		else 12 END AS source_rank
	,COALESCE(b.[sofie_id_start_intervw_period_date], b.[sofie_id_start_ann_period_date]) AS record_date
FROM [IDI_Clean_20211020].[sofie_clean].[person_waves] AS a
INNER JOIN [IDI_Clean_20211020].[sofie_clean].[hq_id] AS b
ON a.snz_uid = b.snz_uid 
AND a.sofie_wav_wave_nbr = b.sofie_id_wave_nbr
WHERE [sofie_wav_ethnic1_snz_code] IS NOT NULL
AND a.snz_uid IS NOT NULL
GO

/************************************
LINZ migrant survey
************************************/
--not included

/************************************
HLFS
************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid, ethnic_code, source_rank, record_date)
SELECT a.[snz_uid]
	,CONCAT(
		SUBSTRING([hlfs_urd_ethnic_1_code],1,2),';',
		SUBSTRING([hlfs_urd_ethnic_2_code],1,2),';',
		SUBSTRING([hlfs_urd_ethnic_3_code],1,2),';',
		SUBSTRING([hlfs_urd_ethnic_4_code],1,2),';',
		SUBSTRING([hlfs_urd_ethnic_5_code],1,2),';',
		SUBSTRING([hlfs_urd_ethnic_6_code],1,2)) AS ethnic_code
	,CASE 
		WHEN SUBSTRING([hlfs_urd_ethnic_1_code],1,2) in ('94','95','96','97','98') THEN 98
		WHEN SUBSTRING([hlfs_urd_ethnic_1_code],1,2)='99' THEN 99
		else 14 END AS source_rank
	,[nzis_is_quarter_date] AS record_date
FROM [IDI_Clean_20211020].[hlfs_clean].[data] AS a
INNER JOIN [IDI_Clean_20211020].[hlfs_clean].[nzis] AS b
ON a.snz_uid = b.snz_uid
AND a.[hlfs_urd_quarter_nbr] = b.[nzis_is_quarter_nbr]
AND a.[snz_hlfs_hhld_uid] = b.[snz_hlfs_hhld_uid]
WHERE a.snz_uid IS NOT NULL
GO

/************************************
ACM aucland city mission
************************************/
--not included as one digit codes

/************************************
GSS
************************************/
--a strange coding of ethnicity - not sure how to include

/***************************************************************************************************************
Keep best rank for each person
***************************************************************************************************************/

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list] (snz_uid)
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_ethnicity_level_2]
GO

WITH source_ranked AS (
	SELECT *
		,RANK() OVER (PARTITION BY [snz_uid] ORDER BY source_rank, record_date) AS ranked
	FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list]
)
SELECT snz_uid
	,ethnic_code
	,source_rank
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_ethnicity_level_2]
FROM source_ranked
WHERE ranked = 1
AND snz_uid IS NOT NULL
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_ethnicity_level_2] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_ethnicity_level_2] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/* remove raw list table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_ethnicity_list]
GO

/***************************************************************************************************************
Indicator view
***************************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_ethnicity_level_1_and_2]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_ethnicity_level_1_and_2] AS
SELECT snz_uid
	,ethnic_code
	,source_rank
	/* level 1 ethnicities */
	,IIF(ethnic_code like '%10%'
		OR ethnic_code like '%11%'
		OR ethnic_code like '%12%', 1, 0) AS lvl1_eth_1 -- European
	,IIF(ethnic_code like '%21%', 1, 0) AS lvl1_eth_2 -- Maori
	,IIF(ethnic_code like '%30%'
		OR ethnic_code like '%31%'
		OR ethnic_code like '%32%'
		OR ethnic_code like '%33%'
		OR ethnic_code like '%34%'
		OR ethnic_code like '%35%'
		OR ethnic_code like '%36%'
		OR ethnic_code like '%37%', 1, 0) AS lvl1_eth_3 -- Pacific
	,IIF(ethnic_code like '%40%'
		OR ethnic_code like '%41%'
		OR ethnic_code like '%42%'
		OR ethnic_code like '%43%'
		OR ethnic_code like '%44%', 1, 0) AS lvl1_eth_4 -- Asian
	,IIF(ethnic_code like '%51%'
		OR ethnic_code like '%52%'
		OR ethnic_code like '%53%', 1, 0) AS lvl1_eth_5 -- MELAA
	,IIF(ethnic_code like '%61%', 1, 0) AS lvl1_eth_6 -- other
	/* level 2 ethnicities */
	,IIF(ethnic_code LIKE '%10%', 1, 0) AS lvl2_eth_10 -- European nfd
	,IIF(ethnic_code LIKE '%11%', 1, 0) AS lvl2_eth_11 -- New Zealand European
	,IIF(ethnic_code LIKE '%12%', 1, 0) AS lvl2_eth_12 -- Other European
	,IIF(ethnic_code LIKE '%21%', 1, 0) AS lvl2_eth_21 -- Mäori
	,IIF(ethnic_code LIKE '%30%', 1, 0) AS lvl2_eth_30 -- Pacific Peoples nfd
	,IIF(ethnic_code LIKE '%31%', 1, 0) AS lvl2_eth_31 -- Samoan
	,IIF(ethnic_code LIKE '%32%', 1, 0) AS lvl2_eth_32 -- Cook Islands Maori
	,IIF(ethnic_code LIKE '%33%', 1, 0) AS lvl2_eth_33 -- Tongan
	,IIF(ethnic_code LIKE '%34%', 1, 0) AS lvl2_eth_34 -- Niuean
	,IIF(ethnic_code LIKE '%35%', 1, 0) AS lvl2_eth_35 -- Tokelauan
	,IIF(ethnic_code LIKE '%36%', 1, 0) AS lvl2_eth_36 -- Fijian
	,IIF(ethnic_code LIKE '%37%', 1, 0) AS lvl2_eth_37 -- Other Pacific Peoples
	,IIF(ethnic_code LIKE '%40%', 1, 0) AS lvl2_eth_40 -- Asian nfd
	,IIF(ethnic_code LIKE '%41%', 1, 0) AS lvl2_eth_41 -- Southeast Asian
	,IIF(ethnic_code LIKE '%42%', 1, 0) AS lvl2_eth_42 -- Chinese
	,IIF(ethnic_code LIKE '%43%', 1, 0) AS lvl2_eth_43 -- Indian
	,IIF(ethnic_code LIKE '%44%', 1, 0) AS lvl2_eth_44 -- Other Asian
	,IIF(ethnic_code LIKE '%51%', 1, 0) AS lvl2_eth_51 -- Middle Eastern
	,IIF(ethnic_code LIKE '%52%', 1, 0) AS lvl2_eth_52 -- Latin American
	,IIF(ethnic_code LIKE '%53%', 1, 0) AS lvl2_eth_53 -- African
	,IIF(ethnic_code LIKE '%61%', 1, 0) AS lvl2_eth_61 -- Other Ethnicity
	/* non-responses */
	,IIF(ethnic_code like '%94%'
		OR ethnic_code like '%95%'
		OR ethnic_code like '%97%'
		OR ethnic_code like '%98%'
		OR ethnic_code like '%99%', 1, 0) AS eth_non_response
FROM [IDI_Sandpit].[DL-MAA2016-15].[vacc_ethnicity_level_2]
GO
