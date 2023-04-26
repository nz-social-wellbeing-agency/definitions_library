/**************************************************************************************************
Title: Evidence of people in NZ
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
Evidence of people in NZ using multi-source.

Intended purpose:
1. Constructing this population is to capture anyone and everyone who is in New Zealand at present (November 2021). 
2. Combine data from multiple sources where we have evidence a person is in the country.

Inputs & Dependencies:
- [IDI_Clean].[data].[snz_res_pop]
- [IDI_Adhoc].[clean_read_MSD].[msd_sben_202107]
- [IDI_Clean].[security].[concordance]
- population_health_service_users.sql --> [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy]
- [IDI_Clean].[data].[person_overseas_spell]
- [IDI_Adhoc].[clean_read_MOH_CIR].[moh_CIR_vaccination_activity20211123]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[data].[personal_detail]
Output
- [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_most_complete_population]


Notes:
1) This definition follows the same underlying business rules, but differs in implementation
	from the population definition used for the COVID-19 Vaccination study population.
2) Sources used include:
	1. Estimated residential population by Stats NZ
	2. MSD high frequency load data spells for benefits ending in 2021 (anyone receiving a benefit)
	3. Health Service Users (HSU)
	4. Anybody with boarder spells putting them in NZ (entered NZ without an exit recorded)
	5. COVID immunisation register (received vaccination in NZ)

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-10-29 CW
**************************************************************************************************/

/***************************************************************************************************************
Gather all identities that appear in NZ
***************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_all_identities_list]
GO

SELECT DISTINCT snz_uid 
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_all_identities_list]
FROM (
	--1. Estimated residential population
	SELECT snz_uid
	FROM [IDI_Clean_YYYYMM].[data].[snz_res_pop]
	WHERE YEAR ([srp_ref_date]) = 2021

	UNION ALL

	--2. MSD high frequecty load data spells for benefits ending in 2021
	SELECT b.snz_uid
	FROM [IDI_Adhoc].[clean_read_MSD].[msd_sben_202107] as a
	INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] as b
	ON a.[snz_msd_uid] = b.[snz_msd_uid]
	WHERE YEAR([end_date]) =2021

	UNION ALL

	--3. Health Service Users (HSU)
	SELECT DISTINCT snz_uid
		,'hsu' AS record_source
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_hsu_proxy]

	UNION ALL

	--4. Anybody with boarder spells putting them in NZ
	SELECT snz_uid
	FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell] AS a
	WHERE NOT EXISTS (
		SELECT 1
		FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell] AS b
		WHERE a.snz_uid = b.snz_uid
		AND b.pos_last_departure_ind = 'y'
	)

	UNION ALL

	--5. COVID immunisation register
	SELECT b.snz_uid
	FROM [IDI_Adhoc].[clean_read_MOH_CIR].[moh_CIR_vaccination_activity20211123] AS a
	INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] AS b
	ON a.snz_moh_uid = b.snz_moh_uid
) AS k
GO

/***************************************************************************************************************
Gather conditions for exclusion
***************************************************************************************************************/

-- deceased
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_deceased]
GO

SELECT snz_uid
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_deceased]
FROM [IDI_Clean_YYYYMM].[data].[personal_detail]
WHERE snz_uid IS NOT NULL
AND ([snz_deceased_year_nbr] IS NOT NULL OR [snz_deceased_month_nbr] IS NOT NULL)


-- left NZ
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_departed]
GO

SELECT DISTINCT snz_uid
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_departed]
FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell] 
WHERE YEAR([pos_ceased_date]) = 9999
AND snz_uid IS NOT NULL
AND pos_last_departure_ind = 'y'

-- spine
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_no_spine]
GO

SELECT snz_uid
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_no_spine]
FROM [IDI_Clean_YYYYMM].[security].[concordance]
WHERE snz_spine_uid IS NULL

/***************************************************************************************************************
Index all for comparison
***************************************************************************************************************/

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_all_identities_list] (snz_uid);
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_deceased] (snz_uid);
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_departed] (snz_uid);
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_no_spine] (snz_uid);
GO

/***************************************************************************************************************
Population table
***************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_most_complete_population]
GO

SELECT snz_uid
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_most_complete_population]
FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_all_identities_list] AS a
WHERE NOT EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_deceased] AS b
	WHERE a.snz_uid = b.snz_uid
)
AND NOT EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_departed] AS c
	WHERE a.snz_uid = c.snz_uid
)
AND NOT EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_no_spine] AS d
	WHERE a.snz_uid = d.snz_uid
)

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_most_complete_population] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_most_complete_population] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/***************************************************************************************************************
Tidy up
***************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_all_identities_list]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_deceased]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_departed]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_pop_no_spine]
GO
