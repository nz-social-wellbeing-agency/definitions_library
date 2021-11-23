/**************************************************************************************************
Title: MOE school events SIAL table
Author: C Wright, C Maccormick and V Benny

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[student_enrol] enr
- [IDI_Clean].[data].[personal_detail] per
- [IDI_Adhoc].[clean_read_MOE].[moe_school_decile_history]
- moe_school_decile_pricing.csv
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events]
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_school_events]

Description:
MOE primary and secondary school events
following the logic of the Social Investment Analytical Layer (SIAL)
Create primary and secondary schooling spells and costs in SIAL format

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) Logic orginates from SIAL, but reworked in SQL.
   Methods are not identical, so some difference should be expected.
   Correspondence between the original SIAL and revised table appears
   excellent. In a sample of 100,000 records fewer than 600
   record-comparisons produced meaningful differences. The causes of
   these differences can be roughly classified as one-third each due to:
   - minor differences in FTE scaling
   - errors in the original code
   - comparisons that could be genuine errors
   Following this, the revised table corrects several errors in the original
   code, including >75,000 duplicate records and >250,000 records with
   non-positive costs.
3) School decile changes part way through the year in some cases.
   These changes affect very few students so are ignored as not material.
4) For loading CSV file, SQL requires network path. Drive letter will fail.
   Example:
   Windows explorer shows "MAA (\\server\server_folder) (I:)"
   Becomes "\\server\server_folder\MAA\path_to_csv\file.csv"

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_sial_ & sial_
  Project schema = [DL-MAA2016-15]
  limit on future enrollment dates = '2021-01-01'
  location of csv cost file = '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL'

Issues:
1) The original SIAL table produced a row/record for every year enrolled.
   This revised table only produces a row/record for every year enrolled
   if the year appears in the decile-pricing csv file.
   This means that rows for enrollments post-2015 do not appear as the
   cost file ends in 2015.
   Solutions:
   (1) extend the cost file through to the current year;
   (2) remove the last join, so the output does not depend on the cost csv.
 
History (reverse order):
2020-05-29 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a compress to keep space used to minimum
2019-03-01 Peter Holmes: Updated for SAS-GRID migration. Dates now stored as SAS Dates on SAS Server,
                         MOE_clean adohc data now stored in IDI_Adhoc
2017-05-05 Stephanie Thomson: Adapted SIAL code ("MOE_School_Events") to include business rules for overlapping 
							  enrolment spells as per previous year MoJ code which was based on communication 
							  with MoE in 2016. 
2017-04-24 Ernestynne Walsh: updated max num years in school check to 15 based on MOE business QA
**************************************************************************************************/

/******************************* tidy dates and de-duplicate *******************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date];
GO

SELECT snz_uid
	,snz_moe_uid
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
		AND next_start_date < moe_esi_end_date THEN DATEADD(DAY, -1, next_start_date)
		WHEN moe_esi_end_date IS NOT NULL THEN moe_esi_end_date
		WHEN moe_esi_end_date IS NULL
		AND DATEADD(YEAR, 19, date_of_birth) < moe_esi_extrtn_date THEN DATEADD(YEAR, 18, date_of_birth)
		ELSE moe_esi_extrtn_date END AS improved_end_date
	,moe_esi_extrtn_date
	,moe_esi_provider_code /* school number */
	,date_of_birth
INTO [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date]
FROM (
	SELECT enr.snz_uid
		  ,enr.snz_moe_uid
		  ,enr.moe_esi_start_date
		  ,enr.moe_esi_end_date
		  ,LEAD(enr.moe_esi_start_date) OVER (PARTITION BY enr.snz_uid ORDER BY enr.moe_esi_start_date) AS next_start_date
		  ,enr.moe_esi_extrtn_date
		  ,enr.moe_esi_provider_code /* school number */
		  ,DATEFROMPARTS(per.snz_birth_year_nbr, per.snz_birth_month_nbr, 15) as date_of_birth
	FROM [IDI_Clean_20200120].[moe_clean].[student_enrol] enr
	LEFT JOIN [IDI_Clean_20200120].[data].[personal_detail] per
	ON enr.snz_uid = per.snz_uid
	WHERE enr.moe_esi_start_date IS NOT NULL
) k

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates];
GO

SELECT DISTINCT snz_uid
	,snz_moe_uid
	,moe_esi_start_date
	,improved_end_date
	,moe_esi_extrtn_date
	,moe_esi_provider_code /* school number */
INTO [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates]
FROM [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date]
WHERE moe_esi_start_date < improved_end_date
AND moe_esi_start_date < '2021-01-01'
/* To avoid unusual spells, require that years enrolled <= 14 */
AND DATEDIFF(DAY, moe_esi_start_date, improved_end_date) / 365.25 <= 14
/* and enrollment age is between 4 and 24 */
AND DATEDIFF(DAY, date_of_birth, moe_esi_start_date) / 365.25 BETWEEN 4 AND 24

/******************************* load decile pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING] (
	school_number INT,
	school_type_id INT,
	academic_year INT,
	school_decile INT,
	cost FLOAT
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\sial_MOE_SCHOOL_DECILE_PRICING.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/******************************* result table & view *******************************/
/*Calculate fraction of funding for part year*/
/*
academic_year_start = DATEFROMPARTS(c.academic_year, 2, 1) /* 'YYYY-02-01' */
academic_year_end = DATEFROMPARTS(c.academic_year, 12, 20) /* 'YYYY-12-20' */

attendance_start = MAX(moe_esi_start_date, academic_year_start) /* implement with IIF as MIN/MAX are summary functions not pairwise */
attendance_end = MIN(improved_end_date, academic_year_end)      /* implement with IIF as MIN/MAX are summary functions not pairwise */

proportion_of_year = 1.0 * (1 + DATEDIFF(DAY, attendance_start, attendance_end)) / (1 + DATEDIFF(DAY, academic_year_start, academic_year_end))
cost = fte_cost * proportion_of_year
*/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events];
GO

/* nest to calculate proportional costs */
SELECT *
	  ,1.0 * (1 + DATEDIFF(DAY, attendance_start, attendance_end)) / (1 + DATEDIFF(DAY, academic_year_start, academic_year_end)) AS proportion_of_year
	  ,1.0 * (1 + DATEDIFF(DAY, attendance_start, attendance_end)) / (1 + DATEDIFF(DAY, academic_year_start, academic_year_end)) * fte_cost AS cost
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events]
FROM (

/* nest to calculate attendance start and end dates */
SELECT *
	  ,IIF(moe_esi_start_date < academic_year_start, academic_year_start, moe_esi_start_date) AS attendance_start
	  ,IIF(improved_end_date > academic_year_end, academic_year_end, improved_end_date) AS attendance_end
FROM (

/* join student enrollment with decile, academic year, and cost informaiton */
SELECT a.[snz_uid]
	  ,a.[snz_moe_uid]
	  ,a.[moe_esi_start_date]
	  ,a.[improved_end_date]
	  ,a.[moe_esi_provider_code]
	  ,b.[DecileCode]
	  ,b.[DecileStartDate]
      ,b.[DecileEndDate]
	  ,c.academic_year
	  ,c.cost AS fte_cost
	  ,DATEFROMPARTS(c.academic_year, 2, 1) AS academic_year_start
	  ,DATEFROMPARTS(c.academic_year, 12, 20) AS academic_year_end
FROM [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates] AS a
LEFT JOIN [IDI_Adhoc].[clean_read_MOE].[moe_school_decile_history] AS b
ON a.moe_esi_provider_code = b.[InstitutionNumber] /* same organisation */
AND a.moe_esi_start_date <= b.[DecileEndDate]
AND b.[DecileStartDate] < a.improved_end_date /* periods overlap */
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING] AS c
ON b.[InstitutionNumber] = c.school_number /* same school */
AND b.[DecileCode] = c.school_decile /* same decile */
AND b.[DecileStartDate] <= DATEFROMPARTS(c.academic_year, 6, 30)
AND b.[DecileEndDate] >= DATEFROMPARTS(c.academic_year, 6, 30) /* decile year and funding year match */
AND a.[moe_esi_start_date] <= DATEFROMPARTS(c.academic_year, 12, 20)
AND a.[improved_end_date] >= DATEFROMPARTS(c.academic_year, 2, 1) /* enrolled year and funding year match */
WHERE b.[DecileCode] <> 99

) nest_to_calculate_attendance_start_and_end
) nest_to_calculate_proportional_costs

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Set database for writing views */
USE IDI_UserCode
GO
/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[sial_MOE_school_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MOE_school_events];
GO
/* Create view */
CREATE VIEW [DL-MAA2016-15].[sial_MOE_school_events] AS
SELECT snz_uid
	  ,'MOE' as department
	  ,'STU' as datamart
	  ,'ENR' as subject_area
	  ,attendance_start AS [start_date]
	  ,attendance_end AS [end_date]
	  ,cost
	  ,moe_esi_provider_code AS [entity_id] /*School number*/
	  ,[DecileCode] AS event_type_2 /*Decile*/
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_sial_MOE_school_events];
GO

/******************************* tidy temporary tables *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_end_date];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[def_tmp_sial_moe_tidy_dates];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_SCHOOL_DECILE_PRICING];
GO
