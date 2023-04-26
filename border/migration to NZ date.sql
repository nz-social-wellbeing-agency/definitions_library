/**************************************************************************************************
Title: Migration date to New Zealand
Author: Simon Anastasiadis

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
Date of migration to New Zealand based on compolation of different sources keeping highest qulaity source.

Intended purpose:
1. Creating indicators of when a person migrated to New Zealand.
2. Creating indicators of how recently a person migrated to NZ (for example, within the last 10 years).
3. Calculating age when migrated to New Zealand.

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[data].[person_overseas_spell]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_migration_date]

Notes:
1) Aim is to create a starting point for examining when people migrate to New Zealand
	Useful for understanding whether people are new migrants and at what age they migrated
	(with implications for first-generation, second-generation, etc. migrant measures).

2) We have used Census 2018 and 2013 as the highest quality sources. These sources are
	self-report. For old dates these may vary in quality (for example, people may round to
	nearest 5 years when self-reporting).

3) For Overseas spells, we examined duration of spells overseas and compared against
	self-reported values in Census 2018.
	- While people are non-resident, their overseas spells are much more likely to
		be greater than 180 days.
	- Once peole become resident, their overseas spells are much more likely to
		be less than 180 days.
	Hence, we tested "migration date = end date of last overseas spells with duration
	180+ days". This definition has strong consistency with self-reported year.

4) Note that we have no control for 'is the person resident' or 'was the person resident'.
	Some people who migrate to New Zealand will have since emmigrated from NZ.
	It is recommended that you first use the Estimated Residnetial Population (ERP) by Stats
	to determine who is resident. And where people who are resident were born overseas,
	then use this code as a starting point to determine when they arrived in NZ.


Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
Issues:
1) We do not have sufficient expertise with immigration records in IDI to use this source.
	Adding this source is the obvious and essential next step.
2) Run time 7 minutes
 
History (reverse order):
2022-10-12 SA v1
**************************************************************************************************/

/********************************************************
TABLES TO APPEND TO
********************************************************/

/* Diagnosis or treatment only indicates dysthymia */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date] (
	snz_uid	INT,
	event_date DATE,
	event_year INT,
	event_month INT,
	origin VARCHAR(12)
)

/********************************************************
Census 2018
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date] (snz_uid, event_date, event_year, event_month, origin)
SELECT [snz_uid]
	,CASE -- required as transformation applied before filtering (even if using nested queries)
		WHEN [cen_ind_arrv_in_nz_year_code] NOT IN ('7777', '9999')
		AND [cen_ind_arrv_in_nz_month_code] NOT IN ('77', '99')
		THEN DATEFROMPARTS([cen_ind_arrv_in_nz_year_code], [cen_ind_arrv_in_nz_month_code], 15)
		END AS event_date
	,CAST([cen_ind_arrv_in_nz_year_code] AS INT) AS event_year
	,CAST([cen_ind_arrv_in_nz_month_code] AS INT) AS event_month
	,'cen18' AS origin
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2018]
WHERE [cen_ind_birth_country_code] NOT IN ('1201', '9999', '0000') -- Exclude NZ and non-response
AND [cen_ind_birth_country_impt_ind] IN ('11', '21') -- Census 2018 response
AND [cen_ind_arrv_in_nz_year_code] NOT IN ('7777', '9999') -- Some year required
AND [cen_ind_arrv_in_nz_month_code] NOT IN ('77', '99') -- Some month required
GO

/********************************************************
Census 2013
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date] (snz_uid, event_date, event_year, event_month, origin)
SELECT [snz_uid]
    ,CASE
		WHEN [cen_ind_arrival_in_nz_yr_code] NOT IN ('7777', '9999')
		AND [cen_ind_arrival_in_nz_mnth_code] NOT IN ('77', '99')
		THEN DATEFROMPARTS([cen_ind_arrival_in_nz_yr_code], [cen_ind_arrival_in_nz_mnth_code], 15)
		END AS event_date
	,CAST([cen_ind_arrival_in_nz_yr_code] AS INT) AS event_year
	,CAST([cen_ind_arrival_in_nz_mnth_code] AS INT) AS event_month
	,'cen13' AS origin
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2013]
WHERE [cen_ind_birth_country_code] NOT IN ('1201', '9999', '0000') -- Exclude NZ and non-response
AND [cen_ind_arrival_in_nz_yr_code] NOT IN ('7777', '9999') -- Some year required
AND [cen_ind_arrival_in_nz_mnth_code] NOT IN ('77', '99') -- Some month required
GO

/********************************************************
Overseas spells

Find people with a first date in NZ.
Find the earliest date such that any overseas spells of length 180+ days
are all prior to this date.
********************************************************/

WITH
people_who_have_a_first_arrival AS (
	SELECT snz_uid
	FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell]
	WHERE pos_first_arrival_ind = 'y' -- people born in NZ should not have a first arrival
),
last_day_of_long_overseas_spell AS (
	SELECT [snz_uid]
		,MAX([pos_ceased_date]) AS max_ceased_date
	FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell]
	WHERE [pos_day_span_nbr] > 180
	AND pos_last_departure_ind <> 'y' -- not last departure from NZ
	GROUP BY snz_uid
)
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date] (snz_uid, event_date, event_year, event_month, origin)
SELECT snz_uid
	,max_ceased_date AS event_date
	,YEAR(max_ceased_date) AS event_year
	,MONTH(max_ceased_date) AS event_month
	,'spells' AS origin
FROM last_day_of_long_overseas_spell AS ld
WHERE max_ceased_date < GETDATE()
AND EXISTS (
	SELECT 1
	FROM people_who_have_a_first_arrival AS pw
	WHERE pw.snz_uid = ld.snz_uid
)
GO

/********************************************************
Keep highest ranked source
********************************************************/

/* index for performance */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date] (snz_uid);
GO

/* delete before creation */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_migration_date]
GO

WITH
ranked AS (
	SELECT *
		,CASE
			WHEN origin = 'cen18' THEN 1
			WHEN origin = 'cen13' THEN 2
			WHEN origin = 'spells' THEN 3
			END AS ranked
	FROM [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date]
),
source_ranked AS (
	SELECT *
		,ROW_NUMBER() OVER (PARTITION BY snz_uid ORDER BY ranked, event_date) AS source_ranked
	FROM ranked
)
SELECT snz_uid
	,event_date
	,event_year
	,event_month
	--,origin
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_migration_date]
FROM source_ranked
WHERE source_ranked = 1
GO

/********************************************************
Tidy
********************************************************/

/* index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_migration_date] (snz_uid);
GO
/* compress */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_migration_date] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
/* remove temp tables */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_migration_date]
GO
