/**************************************************************************************************************
Nga Tapuwae events measures

Author: Joel Bancolita
Based on version: Simon Anastasiadis, et. al. (Indicated, HaBiSA project)

Purpose: create several measures needed for Nga Tapuae based on literature

Depends:	
- popdefn-stage.sql
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[moe_clean].[student_qualification]
- [IDI_Clean].[moe_clean].[completion]
- [IDI_Clean].[moe_clean].[tec_it_learner]
- MOE Student interventions table (saved to project data folder [pointed to by the parameter DATPATH below] as 'moe_interventions.dat') with columns InterventionID, InterventionName, Comments

History:
20200820: JB additional revised measures
20200808: JB additional revised measures
20200708: JB additional revised measures
20200624: JB revised initial measures
20200609: JB initialise


**************************************************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
--path to data folder
:setvar DATPATH "\\prtprdsasnas01\datalab\maa\MAA2020-35\nga_tapuwae-src\data"
GO

--reference year and birth year
--age at reference year/s
:setvar AGE 30 
--age window 0
:setvar AGE0 15 
--age window 1
:setvar AGE1 18 
--age post (initial value  or window)
:setvar AGEPIV 15
GO
*/
--##############################################################################################################
/*embedded in user code*/
USE IDI_UserCode
GO

/* Event and roles associated with it 
Embedded for code compliance
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)event_roles]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)event_roles];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)event_roles]
AS
/* person */
SELECT [snz_uid]
	,'person' AS [role]
	,[snz_uid] AS [event_id]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop]
	/*UNION ALL*/
GO

/* events at age0 that occurred by location
base: HaBiSA
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)event_locations]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)event_locations];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)event_locations]
AS
SELECT DISTINCT [pop].[snz_uid] AS event_id
	,dateadd(year, $( AGEPIV)
	,DATEFROMPARTS(snz_birth_year_nbr, snz_birth_month_nbr, 28) ) AS event_date --parameterise 15
	,coalesce([ant].ant_notification_date, [pop].[dob_atage0]) AS address_start_date
	,coalesce([ant].ant_replacement_date, [pop].[dob_atage0]) AS address_end_date
	,[ant].snz_idi_address_register_uid AS address_atage0
	,[ta].descriptor_text AS address_atage0_local_area
	,[ant].[ant_region_code] AS address_atage0_regc
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop]
INNER JOIN [$(IDIREF)].[data].[personal_detail] [per] ON [pop].[snz_uid] = [per].[snz_uid]
LEFT JOIN [$(IDIREF)].[data].[address_notification] [ant] ON [pop].[snz_uid] = [ant].[snz_uid]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_TA13] [ta] ON [ant].[ant_ta_code] = [ta].[cat_code]
GO

/*
Title: MOE school events 
Author: C Wright, C Maccormick and V Benny
20200610: JB limited to population scope only
*/
/******************************* tidy dates and de-duplicate *******************************/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_end_date]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_end_date];
GO

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
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_end_date]
FROM (
	SELECT enr.snz_uid
		,enr.snz_moe_uid
		,enr.moe_esi_entry_year_lvl_nbr
		,enr.moe_esi_start_date
		,enr.moe_esi_end_date
		,LEAD(enr.moe_esi_start_date) OVER (
			PARTITION BY enr.snz_uid ORDER BY enr.moe_esi_start_date
			) AS next_start_date
		,enr.moe_esi_extrtn_date
		,enr.moe_esi_provider_code /* school number */
		,DATEFROMPARTS(per.snz_birth_year_nbr, per.snz_birth_month_nbr, 15) AS date_of_birth
	FROM [$(IDIREF)].[moe_clean].[student_enrol] enr
	LEFT JOIN [$(IDIREF)].[data].[personal_detail] per ON enr.snz_uid = per.snz_uid
	INNER JOIN [IDI_Usercode].[$(PROJSCH)].[$(TBLPREF)popyr_enrolhs] pop ON per.snz_uid = pop.snz_uid
	WHERE enr.moe_esi_start_date IS NOT NULL
	) k

IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates];
GO

SELECT DISTINCT snz_uid
	,snz_moe_uid
	,moe_esi_entry_year_lvl_nbr
	,moe_esi_start_date
	,improved_end_date
	,moe_esi_extrtn_date
	,moe_esi_provider_code /* school number */
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_end_date]
WHERE moe_esi_start_date < improved_end_date
	AND moe_esi_start_date < '2021-01-01'
	/* To avoid unusual spells, require that years enrolled <= 14 */
	AND DATEDIFF(DAY, moe_esi_start_date, improved_end_date) / 365.25 <= 14
	/* and enrollment age is between 4 and 24 */
	AND DATEDIFF(DAY, date_of_birth, moe_esi_start_date) / 365.25 BETWEEN 4
		AND 24

--put index
CREATE INDEX individx ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] (snz_uid);

/*
retain only population: too slow when not
*/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates_all]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates_all];
GO

--backup
SELECT *
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates_all]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates];

--remove
DELETE
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates]
WHERE [snz_uid] NOT IN (
		SELECT [snz_uid]
		FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm]
		);

/* 
Variable Ref 1
EVENT: Updated Time enrolled in education
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_EDUCATION_PERIOD]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_EDUCATION_PERIOD];
GO

CREATE VIEW [$(PROJSCH)].$( TBLPREF ) evtvw_EDUCATION_PERIOD AS

/*
Enrolment in secondary education.  Less straightforward than the rest due to null values. 
NB: records 2007- only. Scope is population to avoid unncessary processing
*/
SELECT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	--,[moe_esi_entry_year_lvl_nbr]
	,Iif([moe_esi_entry_year_lvl_nbr] BETWEEN 0
			AND 13
				,'Year ' + cast([moe_esi_entry_year_lvl_nbr] AS VARCHAR)
				,'Unclassified') AS [description]
	,1 AS value
	,'moe student enroll' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] ngt

UNION ALL

/* 
EVENT: Time enrolled in education
AUTHOR: Michael Hackney
DATE: 4/12/18
Intended use: Identify periods of education on timeline, and
to count days/time in education.

Gives period of enrolment in secondary/tertiary education,
or industry training programs, or targeted training programs.
ISCED = international code for level of study.
NZSCED = NZ code for subject of study.

REVIEWED: 2018-12-05 Simon
- industry training must have an end date
- substring used to trim long descriptions
2019-04-09 AK
*/
/*Enrolment in upper secondary or tertiary education*/
SELECT snz_uid
	,[moe_enr_prog_start_date] AS [start_date]
	,[moe_enr_prog_end_date] AS [end_date]
	,CASE 
		WHEN [moe_enr_isced_level_code] LIKE '3_'
			THEN 'Upper secondary'
		WHEN [moe_enr_isced_level_code] LIKE '4_'
			THEN 'Post-secondary, non-tertiary'
		WHEN [moe_enr_isced_level_code] LIKE '5_'
			THEN '1st stage tertiary'
		WHEN [moe_enr_isced_level_code] = '6'
			THEN '2nd stage tertiary'
		ELSE 'Enrollment = Unknown'
		END AS [description]
	,1 AS value
	,'moe enroll' AS [source]
FROM [$(IDIREF)].[moe_clean].[enrolment]

UNION ALL

/*Enrolment in targeted training*/
SELECT snz_uid
	,[moe_ttr_placement_start_date] AS [start_date]
	,[moe_ttr_placement_end_date] AS [end_date]
	,'targeted training enroll' AS [description]
	,1 AS value
	,'moe targeted training' AS [source]
FROM [$(IDIREF)].[moe_clean].[targeted_training]

UNION ALL

/*Enrolment in industry training*/
SELECT [snz_uid]
	,[moe_itl_start_date] AS [start_date]
	,[moe_itl_end_date] AS end_date
	,CONCAT (
		'indust train = '
		,SUBSTRING([moe_itl_nzsced_narrow_text], 1, 20)
		) AS [description]
	,1 AS value
	,'moe industry training' AS [source]
FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
WHERE [moe_itl_end_date] IS NOT NULL;
GO

/* 
Variable Ref 2
Author: Joel Bancolita
EVENT: student intervention received
*/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_inv_intrvtn_code]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_inv_intrvtn_code];
GO

CREATE TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_inv_intrvtn_code] (
	[InterventionID] [int] NULL
	,[InterventionName] [nvarchar](max) NULL
	,[Comments] [nvarchar](max) NULL
	,
	)

BULK INSERT [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_inv_intrvtn_code]
FROM '$(DATPATH)\moe_interventions.dat' WITH (
		FIELDTERMINATOR = '\t'
		,FIRSTROW = 2
		,ROWTERMINATOR = '\n'
		,LASTROW = 50001
		)

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_moe_student_intervention]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_moe_student_intervention];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_moe_student_intervention]
AS
SELECT DISTINCT snz_uid
	,moe_inv_start_date AS [start_date]
	,moe_inv_end_date AS [end_date]
	,'Intervention:' + [InterventionName] AS [description]
	,1 AS [value]
	,'MOE Student Intervention' AS [source]
FROM (
	SELECT snz_uid
		,moe_inv_start_date
		,moe_inv_end_date
		,moe_inv_intrvtn_code
		,b.[InterventionName]
	FROM [$(IDIREF)].[moe_clean].[student_interventions] a
	INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_inv_intrvtn_code] b ON a.moe_inv_intrvtn_code = b.[InterventionID]
	) c
GO

/*
Title: Attainment of qualification
Author: Simon Anastasiadis
2020-06-17 JB updated to not include NULL
Description: Attainment of qualification (or our best approximation of)
[see base qualifications.sql]
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_qualification_awards]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_qualification_awards];
GO

/*
00 No Qualification
01 Level 1 Certificate
02 Level 2 Certificate
03 Level 3 Certificate
04 Level 4 Certificate
05 Level 5 Diploma
06 Level 6 Diploma
07 Bachelor Degree and Level 7 Qualification
08 Post-graduate and Honours Degrees
09 Masters Degrees
10 Doctorate Degree
11 Overseas Secondary School Qualification
97 Response Unidentifiable
99 Not Specified 
*/
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_qualification_awards]
AS
SELECT DISTINCT snz_uid
	,[event_date] AS [start_date]
	,[event_date] AS [end_date]
	,'Awarded: qual level ' + cast([qualification_level] AS VARCHAR) AS [description]
	,[qualification_level] AS [value]
	,[source] AS [source]
FROM (
	SELECT [snz_uid]
		,'2018-03-08' AS [event_date]
		,[cen_ind_standard_hst_qual_code] AS [qualification_level]
		,'cen2018' AS [source]
	FROM [$(IDIREF)].[cen_clean].[census_individual_2018]
	
	UNION ALL
	
	-- Census 2013 secondary school qualification
	SELECT [snz_uid]
		,DATEFROMPARTS([cen_ind_birth_year_nbr] + 18, 12, 1) AS [event_date]
		,cen_ind_sndry_scl_qual_code AS [qualification_level]
		,'cen2013' AS [source]
	FROM [$(IDIREF)].[cen_clean].[census_individual_2013]
	WHERE cen_ind_sndry_scl_qual_code IN (
			'01'
			,'02'
			,'03'
			)
	
	UNION ALL
	
	-- Census 2013 highest qualification
	SELECT [snz_uid]
		,'2013-03-05' AS [event_date]
		,cen_ind_std_highest_qual_code AS [qualification_level]
		,'cen2013' AS [source]
	FROM [$(IDIREF)].[cen_clean].[census_individual_2013]
	WHERE cen_ind_std_highest_qual_code IN (
			'01'
			,'02'
			,'03'
			,'04'
			,'05'
			,'06'
			,'07'
			,'08'
			,'09'
			,'10'
			)
		AND cen_ind_std_highest_qual_code <> cen_ind_sndry_scl_qual_code
		AND [cen_ind_birth_year_nbr] + 18 >= 2013 -- must be at least 18 when earned post-school qualification
	
	UNION ALL
	
	-- Primary and secondary
	SELECT snz_uid
		,DATEFROMPARTS(moe_sql_attained_year_nbr, 12, 1) AS [event_date]
		,moe_sql_nqf_level_code AS [qualification_level]
		,'moe primary/secondary' AS [source]
	FROM [$(IDIREF)].[moe_clean].[student_qualification]
	WHERE moe_sql_nqf_level_code IS NOT NULL
		AND moe_sql_nqf_level_code IN (
			1
			,2
			,3
			,4
			,5
			,6
			,7
			,8
			,9
			,10
			) -- limit to 10 levels of NZQF
	
	UNION ALL
	
	-- Tertiary qualification
	SELECT snz_uid
		,DATEFROMPARTS(moe_com_year_nbr, 12, 1) AS [event_date]
		,moe_com_qual_level_code AS [qualification_level]
		,'moe tertiary' AS [source]
	FROM [$(IDIREF)].[moe_clean].[completion]
	WHERE moe_com_qual_level_code IS NOT NULL
		AND moe_com_qual_level_code IN (
			1
			,2
			,3
			,4
			,5
			,6
			,7
			,8
			,9
			,10
			) -- limit to 10 levels of NZQF
	
	UNION ALL
	
	-- Industry training qualifications
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,1 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level1_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,2 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level2_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,3 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level3_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,4 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level4_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,5 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level5_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,6 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level6_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,7 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level7_qual_awarded_nbr > 0
	
	UNION ALL
	
	SELECT snz_uid
		,moe_itl_end_date AS [event_date]
		,8 AS [qualification_level]
		,'tec industry' AS [source]
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
		AND moe_itl_level8_qual_awarded_nbr > 0
	) qual
WHERE [qualification_level] IS NOT NULL
GO

/*
Variable Ref 4
EVENT: highest qualification; regardless of whether leaver of secondary school; based on the more
encompassing view/sql as the documentation for MOE secondary school says that
"Qualifications attained by students usually from schooling education, although some students complete this at a tertiary institution.
Extracted from LearnerBDS, but originally sourced from NZQA
Tertiary qualifications are not included here unless a student has studied at an unusually high level at school."
DATE: 2020-07-08
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_hst_qual]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_hst_qual];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_hst_qual]
AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,'Highest qualification: Level ' + CASE 
		WHEN [qual].[value] = 0
			THEN '0'
		WHEN [qual].[value] BETWEEN 1
				AND 3
			THEN '1-3'
		WHEN [qual].[value] BETWEEN 4
				AND 6
			THEN '4-6'
		WHEN [qual].[value] BETWEEN 7
				AND 11
			THEN '7 and above'
		ELSE 'unclassified'
		END AS [description]
	,1 AS [value]
	,'cen, tec, moe' AS [source]
FROM (
	SELECT [moe].*
		,[pop].[dob]
		,ROW_NUMBER() OVER (
			PARTITION BY [pop].snz_uid ORDER BY [value] DESC
				,[end_date] ASC
			) [rnk]
	FROM [$(PROJSCH)].[$(TBLPREF)evtvw_qualification_awards] [moe]
	INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop] -- check whether this is the right population to join
		ON [pop].[snz_uid] = [moe].[snz_uid]
	WHERE [value] NOT IN (
			97
			,99
			)
		AND [value] IS NOT NULL
		AND datediff(year, [pop].[dob], [moe].[end_date]) < $( AGE
	) ) [qual]
WHERE [qual].[rnk] = 1
GO

/*
Variable Ref 61
EVENT: primary / secondary school location
AUTHOR: Joel Bancolita
DATE: 2020-06-10
Intended use: describe individuals movements across schools
NB: For now, region is the granularity due to possible issue on entity counts
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_location]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_location];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_location]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'School: ' + replace(Isnull([regc].[descriptor_text], 'Unclassified'), 'Region', '') AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile] [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_REGC13] [regc] ON [prv].SchoolRegion2 = [regc].[cat_code]
GO

/*
Variable Ref 3
EVENT: school decile
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school decile
NB: For now, region is the granularity due to possible issue on entity counts
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_decile]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_decile];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_decile]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'School: Decile ' + cast(Iif([prv].[simdec] = 10, '99', [prv].[simdec] + 1) AS VARCHAR) AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN (
	SELECT *
		,cast(right([decileid], 2) AS INT) AS simdec
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile]
	) [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
GO

/*
Variable Ref 3
EVENT: co-ed school 
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school gender
NB: For now, region is the granularity due to possible issue on entity counts
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_gender]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_gender];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_gender]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'Co-ed School: ' + Iif([prv].[schgend] IN (
			1
			,4
			,7
			), 'Yes', Iif([prv].[schgend] IN (
				2
				,3
				), 'No', 'Unclassified')) AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN (
	SELECT *
		,Isnull([SchoolGender2], 99) AS schgend
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile]
	) [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
GO

/*
Variable Ref 3
EVENT: school authority (state/public, private/trust, other)
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school authority 
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_auth]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_auth];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_auth]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'School Authority: ' + CASE 
		WHEN [SchoolAuthorityID] IN (
				42000
				,42001
				,42005
				,42007
				,42010
				)
			THEN 'State/public' --categorised definition/s
		WHEN [SchoolAuthorityID] IN (
				42002
				,42003
				,42006
				,42008
				,42009
				,42012
				)
			THEN 'Private/trust'
		ELSE 'Unclassified'
		END AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile] [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
GO

/*
Variable Ref 3
EVENT: Kura Kaupapa (Kura Kaupapa Maori, Sec Maori Boarding)
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school definition: Kura Kaupapa
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_maori]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_maori];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_maori]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'Kura Kaupapa Maori / Maori Boarding School: ' + CASE 
		WHEN [DefinitionCode] IN (
				17
				,19
				)
			THEN 'Yes' --categorised definition/s
		ELSE 'No'
		END AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile] [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
GO

/*
Variable Ref 3
EVENT: School for disabilities, impairment 
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school definition: disabilities/impairment
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_pwd]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_pwd];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_pwd]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'School for students with impairment: ' + CASE 
		WHEN [DefinitionCode] IN (
				6
				,7
				,8
				,10
				,11
				)
			THEN 'Yes' --Vision impaired,Deaf/hearing impairment,Physical disabilities,Intellectual impairement,Learning/social difficulties
		ELSE 'No'
		END AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile] [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
GO

/*
Variable Ref 3
EVENT: School with religious affiliation
AUTHOR: Joel Bancolita
DATE: 2020-07-06
Intended use: describe individuals attendance based on school's religious affiliation
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_school_relgn]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_relgn];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_school_relgn]
AS
SELECT DISTINCT snz_uid
	,[moe_esi_start_date] AS [start_date]
	,[improved_end_date] AS [end_date]
	,'School: ' + CASE 
		WHEN [prv_sub].[ReligiousAffiliationID] IN (16011)
			THEN 'Non-denominational'
		WHEN [prv_sub].[ReligiousAffiliationID] IN (
				16000
				,16001
				,16002
				,16003
				,16004
				,16005
				,16006
				,16007
				,16008
				,16009
				,16010
				,16012
				,16013
				,16014
				,16015
				,16016
				,16017
				,16018
				)
			THEN 'with Religious Affiliation'
		ELSE 'Religious affiliation not determined'
		END AS [description]
	,1 AS value
	,'moe student enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)evttbl_moe_tidy_dates] [spell]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_school_profile] [prv] ON [spell].[moe_esi_provider_code] = [prv].SchoolNumber
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_Provider_Profile_20190830] [prv_sub] ON [spell].[moe_esi_provider_code] = [prv_sub].[ProviderNumber ]
GO

/*
Variable Ref 74
EVENT: Being a biological parent
AUTHOR: Joel Bancolita
DATE: 2020-06-10
Intended use: describe individuals who became biological parents
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_biol_parent]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_biol_parent];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_biol_parent]
AS
SELECT [p_snz_uid] AS [snz_uid]
	,snz_birth_date_proxy AS [start_date]
	,dateadd(year, 0, [snz_birth_date_proxy]) AS [end_date]
	,'Became a parent' AS [description]
	,1 AS [value]
	,'dia' AS [source]
FROM (
	SELECT [snz_uid]
		,[parent1_snz_uid] AS p_snz_uid
	FROM [$(IDIREF)].[dia_clean].[births]
	
	UNION
	
	SELECT [snz_uid]
		,[parent2_snz_uid] AS p_snz_uid
	FROM [$(IDIREF)].[dia_clean].[births]
	) dia
INNER JOIN [$(IDIREF)].[data].[personal_detail] [per] ON [dia].[snz_uid] = [per].[snz_uid]
WHERE [p_snz_uid] IS NOT NULL
GO

/* 
Variable Ref 78 (Proxy)
Author: Joel Bancolita
EVENT: Exam, standard in Te Reo, only for those who achieved a subject/exam
TODO: Verify whether this can be used; expand qual scores
NB: MOE metadata describes that the two fields may not be very reliable as they are not mandatory

*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_moe_exam_te_reo]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_moe_exam_te_reo];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_moe_exam_te_reo]
AS
SELECT DISTINCT snz_uid
	,moe_sst_nzqa_comp_date AS [start_date]
	,moe_sst_nzqa_comp_date AS [end_date]
	,Iif(moe_sst_ans_in_te_reo_ind = 1
		OR moe_sst_trans_in_te_reo_ind = 1, 'Medium in Te Reo: Yes', 'Medium in Te Reo: No') AS [description]
	,1 AS [value]
	,'moe student standard' AS [source]
FROM [$(IDIREF)].[moe_clean].[student_standard]
WHERE [moe_sst_exam_result_code] IN (
		'A'
		,'E'
		,'M'
		) --expand this into some other qual scores
GO

/*
Variable Ref 54
EVENT: NEET
depends: neet-stage.sql
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_neet]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_neet];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_neet]
AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,'NEET' AS [description]
	,1 AS [value]
	,'ird ems; moe enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)neet_spell]
GO

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_neet]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_neet];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_neet]
AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,'NEET' AS [description]
	,1 AS [value]
	,'ird ems; moe enrol' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)neet_spell]
GO

/*
EVENT: Employment (W&S and WHP)
depends: employment-stage.sql
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_empl]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_empl];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_empl]
AS
SELECT snz_uid
	,[start_date]
	,[end_date]
	,'Employed' AS [description]
	,1 AS [value]
	,'ird ems' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_spell]

UNION ALL

SELECT snz_uid
	,[start_date]
	,[end_date]
	,'Employed (W&S)' AS [description]
	,1 AS [value]
	,'ird ems' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_ws_spell] --wages and salaries

UNION ALL

SELECT snz_uid
	,[start_date]
	,[end_date]
	,'Employed (WHP)' AS [description]
	,1 AS [value]
	,'ird ems' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)employed_whp_spell] --witholding income
GO

/*
EVENT: Overseas spells
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_overseas]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_overseas];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_overseas]
AS
SELECT [snz_uid]
	,CAST([pos_applied_date] AS DATE) AS [start_date]
	,CAST([pos_ceased_date] AS DATE) AS [end_date]
	,'Person overseas' AS [description]
	,1 AS [value]
	,'data person overseas' AS [source]
FROM [$(IDIREF)].[data].[person_overseas_spell] o
GO


