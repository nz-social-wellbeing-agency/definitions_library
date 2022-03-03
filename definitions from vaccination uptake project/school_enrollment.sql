/**************************************************************************************************
Title: MOE school events
Author: C Wright, C Maccormick and V Benny

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[student_enrol]
- [IDI_Clean].[data].[personal_detail]
- [IDI_Clean].[moe_clean].[enrolment]
- [IDI_Clean].[moe_clean].[targeted_training]
- [IDI_Clean].[moe_clean].[tec_it_learner]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates]
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_period];


Description:
Periods of enrolment in education.

Intended purpose:


Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Date of interest = '2020-12-31'
 
Issues:

History (reverse order):
2021-11-25 SA review and tidy
2021-09-03: MP limited to certain dates
2020-06-10: JB limited to population scope only
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates];
GO

WITH
initial_setup AS (

	SELECT enr.snz_uid
		,enr.snz_moe_uid
		,enr.moe_esi_entry_year_lvl_nbr
		,enr.moe_esi_start_date
		,enr.moe_esi_end_date
		,LEAD(enr.moe_esi_start_date) OVER (PARTITION BY enr.snz_uid ORDER BY enr.moe_esi_start_date) AS next_start_date
		,enr.moe_esi_extrtn_date
		,enr.moe_esi_provider_code /* school number */
		,DATEFROMPARTS(per.snz_birth_year_nbr, per.snz_birth_month_nbr, 15) AS date_of_birth
	FROM [IDI_Clean_20211020].[moe_clean].[student_enrol] enr
	LEFT JOIN [IDI_Clean_20211020].[data].[personal_detail] per
	ON enr.snz_uid = per.snz_uid

),
improve_end_date AS (

	SELECT snz_uid
		,snz_moe_uid
		,moe_esi_entry_year_lvl_nbr
		,moe_esi_start_date
		,moe_esi_end_date
		,next_start_date
		/* Improved end date:
			1. the day before next start if next start is within current spell
			2. the end date if it exists
			3. 18th birthday if within the extraction date
			4. the extraction date otherwise*/
		,CASE 
			WHEN next_start_date IS NOT NULL
				AND next_start_date < moe_esi_end_date
				THEN DATEADD(DAY, - 1, next_start_date)
			WHEN moe_esi_end_date IS NOT NULL
				THEN moe_esi_end_date
			WHEN moe_esi_end_date IS NULL
				AND DATEADD(YEAR, 19, date_of_birth) < moe_esi_extrtn_date
				THEN DATEADD(YEAR, 18, date_of_birth)
			ELSE moe_esi_extrtn_date
			END AS improved_end_date
		,moe_esi_extrtn_date
		,moe_esi_provider_code /* school number */
		,date_of_birth
	FROM initial_setup

)
SELECT DISTINCT snz_uid
	,snz_moe_uid
	,moe_esi_entry_year_lvl_nbr
	,moe_esi_start_date
	,improved_end_date
	,moe_esi_extrtn_date
	,moe_esi_provider_code /* school number */
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates]
FROM improve_end_date
/* To avoid unusual spells, require that years enrolled <= 14 */
WHERE DATEDIFF(DAY, moe_esi_start_date, improved_end_date) / 365.25 <= 14
/* and enrollment age is between 4 and 24 */
AND DATEDIFF(DAY, date_of_birth, moe_esi_start_date) / 365.25 BETWEEN 4 AND 24
/* filter to specific date */
AND '2020-12-31' BETWEEN moe_esi_start_date AND improved_end_date
OR moe_esi_start_date >= '2020-12-31'
GO

--put index
CREATE INDEX individx ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/****************************************
enrollments
****************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_period];
GO

/*
Enrolment in secondary education.  Less straightforward than the rest due to null values. 
NB: records 2007- only.
*/
SELECT *
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_period]
FROM (

SELECT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	--,[moe_esi_entry_year_lvl_nbr]
	,IIF([moe_esi_entry_year_lvl_nbr] BETWEEN 0 AND 13 ,'Year ' + cast([moe_esi_entry_year_lvl_nbr] AS VARCHAR) ,'Unclassified') AS [description]
FROM [IDI_Sandpit].[DL-MAA2021-49].[vacc_moe_tidy_dates]

UNION ALL

/*Enrolment in upper secondary or tertiary education*/
SELECT snz_uid
	,[moe_enr_prog_start_date] AS [start_date]
	,[moe_enr_prog_end_date] AS [end_date]
	,CASE 
		WHEN [moe_enr_isced_level_code] LIKE '3_' THEN 'Upper secondary'
		WHEN [moe_enr_isced_level_code] LIKE '4_' THEN 'Post-secondary, non-tertiary'
		WHEN [moe_enr_isced_level_code] LIKE '5_' THEN '1st stage tertiary'
		WHEN [moe_enr_isced_level_code] = '6' THEN '2nd stage tertiary'
		ELSE 'Enrollment = Unknown' END AS [description]
FROM [IDI_Clean_20211020].[moe_clean].[enrolment]

UNION ALL

/*Enrolment in targeted training*/
SELECT snz_uid
	,[moe_ttr_placement_start_date] AS [start_date]
	,[moe_ttr_placement_end_date] AS [end_date]
	,'targeted training enroll' AS [description]
FROM [IDI_Clean_20211020].[moe_clean].[targeted_training]

UNION ALL

/*Enrolment in industry training*/
SELECT [snz_uid]
	,[moe_itl_start_date] AS [start_date]
	,[moe_itl_end_date] AS end_date
	,CONCAT ('indust train = ',SUBSTRING([moe_itl_nzsced_narrow_text], 1, 20)) AS [description]
FROM [IDI_Clean_20211020].[moe_clean].[tec_it_learner]
WHERE [moe_itl_end_date] IS NOT NULL

);
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_period] (snz_uid)
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_education_period] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
