/**************************************************************************************************
Title: Covid-19 Immunisation Register
Author: Shaan Badenhorst

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions
Steven Johnston provided comments on the definition.

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_MOH_CIR].[moh_CIR_vaccination_activity20211123]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_clean_moh_CIR_vaccination]

Description:
Immunisation Register for NZ Covid-19 vaccination programme.

Intended purpose:
Determining who has been vaccinated, how many vaccinations they have received,
and when & where their vaccinations took place.

Notes:
1) Overwhelming majority of doses are Pfizer BioNTech.
	<20 records are for NULL or other vaccine type.

2) When dose numbers checked 12/10/2021 no one had more than 2 doses recorded.

3) When link rates checked 12/10/2021:
	- 3.4 million identities linked to snz_uid values
	- 50,000 identities did not link to snz_uid
	Note that MOH are improving quality and link rates are improving over time.

4) There are multiple version of the CIR. Input table requires renaming as new versions
	are loaded. Custom naming of output table may also be advised in case of multiple
	versions.

5) The concept of vaccination status is likely to evolve over time as immunity wears off
	and boosters are introduced. Hence it is important to keep in touch with what the
	vaccination programme are doing.

6) Since the creation of this definition, Stats NZ have done addition work to improve the link
	rate for the CIR. This script only picks up links from [snz_moh_uid] to [snz_uid] but recent
	CIR tables include additional links direct to [snz_uid]. Users of the CIR are advised to
	use the improved links by Stats NZ. These come from:
	- linking of NHIs that appeared for the first time in the vaccination data,
	- finding links for NHIs in the CIR data that had not previously been linked.

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:
1) Dose numbers in the CIR data can contain errors. For example, a person might have no dose 1
	and two dose 2, or one dose 1 and one dose 3 but no dose 2. It is now recommended to ignore dose
	number and instead count the number of doses and turn this into vaccination status:
	1 dose => partially vaccinated, 2 or more doses => fully vaccinated.

History (reverse order):
2021-10-12 SB
**************************************************************************************************/

-- Pivot to create two columns for dose 1 and dose 2
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_pivot]
GO

SELECT	snz_moh_uid 
	,MIN(IIF(dose_number = 1, activity_date, NULL)) as Dose_1_date
	,MIN(IIF(dose_number = 2, activity_date, NULL)) as Dose_2_date
	,MIN(IIF(dose_number = 3, activity_date, NULL)) as Dose_3_date
	,MIN(IIF(dose_number = 1, dhbofservice, NULL)) as Dose_1_DHB
	,MIN(IIF(dose_number = 2, dhbofservice, NULL)) as Dose_2_DHB
	,MIN(IIF(dose_number = 3, dhbofservice, NULL)) as Dose_3_DHB
	,[sequence_group]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_pivot]
FROM [IDI_Adhoc].[clean_read_MOH_CIR].[moh_CIR_vaccination_activity20211123]
GROUP BY snz_moh_uid, [sequence_group]
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_pivot] (snz_moh_uid)
GO

-- Merge on snz_uids
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_join_uids]
GO

SELECT COALESCE(b.snz_uid,c.snz_uid) AS snz_uid
	,a.snz_moh_uid 
	,Dose_1_date
	,Dose_2_date
	,Dose_3_date
	,Dose_1_DHB
	,Dose_2_DHB
	,Dose_3_DHB
	,[sequence_group]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_join_uids]
FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_pivot] AS a
LEFT JOIN [IDI_Clean_20211020].[moh_clean].[pop_cohort_demographics] AS b
ON a.snz_moh_uid = b.snz_moh_uid
LEFT JOIN [IDI_Clean_20211020].[security].[concordance] AS c
ON a.snz_moh_uid = c.snz_moh_uid

-- Present as final
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_clean_moh_CIR_vaccination];
GO

SELECT snz_uid
	,snz_moh_uid 
	,Dose_1_date
	,Dose_2_date
	,Dose_3_date
	,Dose_1_DHB
	,Dose_2_DHB
	,Dose_3_DHB
	,[sequence_group]
	,CAST(DAY(Dose_1_date) AS INT) AS Dose_1_Day
	,CAST(MONTH(Dose_1_date) AS INT) AS Dose_1_Month
	,CAST(YEAR(Dose_1_date) AS INT) AS Dose_1_Year
	,CAST(DAY(Dose_2_date) AS INT) AS Dose_2_Day 
	,CAST(MONTH(Dose_2_date) AS INT) AS Dose_2_Month
	,CAST(YEAR(Dose_2_date) AS INT) AS Dose_2_Year
	,CAST(DAY(Dose_3_date) AS INT) AS Dose_3_Day 
	,CAST(MONTH(Dose_3_date) AS INT) AS Dose_3_Month
	,CAST(YEAR(Dose_3_date) AS INT) AS Dose_3_Year
	,IIF(snz_uid IS NOT NULL, 1,0) as snz_uid_chk
	,IIF(Dose_1_date IS NULL, 1,0) as Dose_1_NULL_chk
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_clean_moh_CIR_vaccination]
FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_join_uids]

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_clean_moh_CIR_vaccination] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_clean_moh_CIR_vaccination] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

-- Remove temporary tables
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_pivot]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_cir_join_uids]
GO
