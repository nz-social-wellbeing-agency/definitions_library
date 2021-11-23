/**************************************************************************************************
Title: MOE Assessment and Standards towards university
Author: Joel Bancolita
Purpose: Create measures on academic and school performance towards achieving standards and advancement eligibility
Note: this is predominantly population 2 (15-23 year-olds) -specific

Reviewer: Simon Anastasiadis

Depends:	
- popdefn-stage.sql
- [$(IDIREF)].[moe_clean].[tec_it_learner]
- [$(IDIREF)].[moe_clean].[enrolment]
- [$(IDIREF)].[moe_clean].[student_standard]
- [$(IDIREF)].[moe_clean].[completion]
- [$(IDIREF)].[moe_clean].[course]
- [$(IDIREF)].[moe_clean].[student_ue]
- MOE Field Codes (saved to project data folder [pointed to by the parameter DATPATH below] as 'moe_fieldcode.dat')
- MOE Sub-field Codes (saved to project data folder [pointed to by the parameter DATPATH below] as 'moe_subfieldcode.dat')
- MOE Domain Codes (saved to project data folder [pointed to by the parameter DATPATH below] as 'moe_domaincode.dat')

History (reverse order):
2020-08-24 v3
2020-08-20 v2
2020-08-19 v1
2020-08-17 v0
**************************************************************************************************/
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
--path to data folder
:setvar DATPATH "\\prtprdsasnas01\datalab\maa\MAA2020-35\nga_tapuwae-src\data"
GO
*/
USE IDI_UserCode
GO

/* Event: Taking post-secondary, tertiary programs by broad field category
	NB: not the same as qualification_awards
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_posths_nzsced2]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_posths_nzsced2];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_posths_nzsced2]
AS
SELECT [moe].[snz_uid]
	,[moe].[start_date]
	,[moe].[end_date]
	,'Post-HS study: ' + [dct].[descriptor_text] AS [description]
	,'1' AS [value]
	,[moe].[source]
FROM (
	SELECT snz_uid
		,left(iif(isnumeric(moe_enr_prog_nzsced_code) = 1, FORMAT(cast(moe_enr_prog_nzsced_code AS INT), '000000'), moe_enr_prog_nzsced_code), 2) AS nzsced2
		,[moe_enr_prog_start_date] AS [start_date]
		,[moe_enr_prog_end_date] AS [end_date]
		,'moe tertiary enrolment' AS [source]
	FROM [$(IDIREF)].[moe_clean].[enrolment] /*tertiary*/
	
	UNION ALL
	
	SELECT snz_uid
		,left(iif(isnumeric([moe_itl_nzsced_code]) = 1, FORMAT(cast([moe_itl_nzsced_code] AS INT), '000000'), [moe_itl_nzsced_code]), 2) AS nzsced2
		,[moe_itl_start_date] AS [start_date]
		,[moe_itl_end_date] AS [end_date]
		,'moe industry training' AS [source]
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner] /*industry training */
	WHERE [moe_itl_end_date] IS NOT NULL
	) [moe]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_NZSCED_FIELD] [dct] ON [moe].[nzsced2] = [dct].[cat_code]
GO

/*meta data for fields and subjects (reference: MOE IDI Classifications)*/
/* field code */
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_field_code]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_field_code];
GO

CREATE TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_field_code] (
	[Code] [nvarchar](max) NULL
	,[Description] [nvarchar](max) NULL
	)

BULK INSERT [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_field_code]
FROM '$(DATPATH)\moe_fieldcode.dat' WITH (
		FIELDTERMINATOR = '\t'
		,FIRSTROW = 2
		,ROWTERMINATOR = '\n'
		,LASTROW = 999
		)

/* sub-field code */
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_subfield_code]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_subfield_code];
GO

CREATE TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_subfield_code] (
	[Code] [nvarchar](max) NULL
	,[Description] [nvarchar](max) NULL
	)

BULK INSERT [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_subfield_code]
FROM '$(DATPATH)\moe_subfieldcode.dat' WITH (
		FIELDTERMINATOR = '\t'
		,FIRSTROW = 2
		,ROWTERMINATOR = '\n'
		,LASTROW = 999
		)

/* sub-field code */
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_domain_code]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_domain_code];
GO

CREATE TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_domain_code] (
	[Code] [nvarchar](max) NULL
	,[Description] [nvarchar](max) NULL
	)

BULK INSERT [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_domain_code]
FROM '$(DATPATH)\moe_domaincode.dat' WITH (
		FIELDTERMINATOR = '\t'
		,FIRSTROW = 2
		,ROWTERMINATOR = '\n'
		,LASTROW = 9999
		)

/*modified subject classifications*/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification];
GO

SELECT [lu].[FieldCode]
	,[fld].[Description] AS [Field Description]
	,[lu].[SubFieldCode]
	,[sfld].[Description] AS [Sub Field Description]
	,[lu].[DomainCode]
	,[dom].[Description] AS [Domain Description]
	,cast('' AS NVARCHAR(max)) AS [NGT Class]
	,count(DISTINCT [lu].[StandardTableID]) AS [StandardCount]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_standard_lookup] [lu]
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_field_code] [fld] ON [lu].[FieldCode] = [fld].[Code]
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_subfield_code] [sfld] ON [lu].[SubFieldCode] = [sfld].[Code]
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)moe_domain_code] [dom] ON [lu].[DomainCode] = [dom].[Code]
GROUP BY [lu].[FieldCode]
	,[fld].[Description]
	,[lu].[SubFieldCode]
	,[sfld].[Description]
	,[lu].[DomainCode]
	,[dom].[Description]

/*put index*/
CREATE INDEX domidx ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification] (DomainCode);

/*reset*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = ''

/*Math / Stats : update 30-Oct-2020 */
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Math, Stats & Prob (excluding Calc)'
WHERE [FieldCode] = 'D'
	AND DomainCode NOT IN (829)
	AND [SubFieldCode] IN (
		40
		,298
		)

UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Math: Calculus'
WHERE [FieldCode] = 'D'
	AND DomainCode IN (829)
	AND [SubFieldCode] IN (
		40
		,298
		)

UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Math, Stats & Prob (excluding Calc)'
WHERE [FieldCode] = 'D'
	AND [SubFieldCode] IN (
		40
		,298
		)

/*Science: update 30-Oct-2020 */
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Science: NEC'
WHERE [FieldCode] = 'D'
	AND [SubFieldCode] NOT IN (
		40
		,298
		)

UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Science: Biology'
WHERE [FieldCode] = 'D'
	AND [DomainCode] IN (1170)
	AND [SubFieldCode] NOT IN (
		40
		,298
		)

UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Science: Chemistry'
WHERE [FieldCode] = 'D'
	AND [DomainCode] IN (1172)
	AND [SubFieldCode] NOT IN (
		40
		,298
		)

UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Science: Physics'
WHERE [FieldCode] = 'D'
	AND [DomainCode] IN (1177)
	AND [SubFieldCode] NOT IN (
		40
		,298
		)

/*Engg and Tech*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Engg & Tech'
WHERE [FieldCode] IN (
		'F'
		,'O'
		)

/*Finance, Accounting and Economics (including personal financial management) */
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Acct, Econ & Finance'
WHERE (
		[Domain Description] LIKE '%account%'
		OR [Domain Description] LIKE '%econ%'
		OR [Domain Description] LIKE '%financ%'
		)
	AND (
		[Field Description] LIKE 'Business'
		OR [Field Description] LIKE 'Social Sciences'
		)
	OR [DomainCode] = 2124

/*Business & management*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Business & management'
WHERE [NGT Class] = ''
	AND [FieldCode] = 'G'

/*English and humanities*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'English & Humanities'
WHERE [FieldCode] IN ('B')

/*Hospitality and services (excludes airport and crane operation)*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Services and hospitality'
WHERE (
		[FieldCode] = 'M'
		AND [DomainCode] NOT IN (
			SELECT DISTINCT [DomainCode]
			FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
			WHERE [Domain Description] LIKE '%Operation%'
				AND (
					[Sub Field Description] LIKE '%Aviation%'
					OR [Sub Field Description] LIKE '%Cranes%'
					)
			)
		)

/*Community & Social Services*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Community & Social Services'
WHERE [FieldCode] = 'I'
	AND [NGT Class] = ''

/*Sports*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Sport'
WHERE [Sub Field Description] LIKE '%sport%'
	AND [Sub Field Description] NOT LIKE '%Transport%'
	AND [Sub Field Description] NOT LIKE '%Turf%'

/*Agri*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Agri, forestry and fishery'
WHERE [FieldCode] = 'H'

/*Arts and Social Sciences*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Arts & Crafts'
WHERE [FieldCode] IN (
		'E'
		,'C'
		)
	AND [NGT Class] = ''

/*Maori*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Maori'
WHERE [FieldCode] = 'A'

/*Health and Education*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Health and Education'
WHERE [FieldCode] IN (
		'K'
		,'J'
		)

/*Panning, construction, aviation*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Aviation, planning and construction'
WHERE [FieldCode] = 'P'
	OR (
		[FieldCode] = 'M'
		AND [Domain Description] LIKE '%Operation%'
		AND (
			[Sub Field Description] LIKE '%Aviation%'
			OR [Sub Field Description] LIKE '%Cranes%'
			)
		)

/*Manufacturing*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Manufacturing'
WHERE [FieldCode] = 'N'

/*Law & order*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Law & Order'
WHERE [FieldCode] = 'L'

/*Core and personal devt*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Core (personal devt)'
WHERE [FieldCode] = 'Z'
	AND [NGT Class] = ''

/*undetermined*/
UPDATE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification]
SET [NGT Class] = 'Unclassified'
WHERE [FieldCode] = '9999'

/* 
Variable Ref 4
Variable Ref 4, 61; Part-Proxy for 85
Qual/Quant iteration Variable Ref (1)
EVENT: School achievements; student standards results by field/subjects
NB: retain only basic Unit/Achievement standards (see college ncea criteria, e.g. aorere.ac.nz)
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_ngt_sst_class]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_ngt_sst_class];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_ngt_sst_class]
AS
SELECT snz_uid
	,moe_sst_nzqa_comp_date AS [start_date]
	,moe_sst_nzqa_comp_date AS [end_date]
	,CASE 
		WHEN [StandardTypeCode] = 1
			THEN 'Unit level ' + [StandardLevel] + ' ' + [res_lb] /* right([res_lb],len([res_lb])-charindex(':',[res_lb],1) ) */ /*was put back after DP 092020 */
		ELSE 'Achievement level ' + [StandardLevel] + ' ' + [res_lb]
		END AS [description]
	,1 AS [value]
	,'moe student standard' AS [source]
FROM (
	SELECT [snz_uid]
		,[moe_sst_nzqa_comp_date]
		,[dom].[NGT Class]
		,CASE 
			WHEN (
					[dom].[NGT Class] LIKE 'Math%'
					OR [dom].[NGT Class] LIKE 'Science%'
					OR [dom].[NGT Class] = 'English & Humanities'
					)
				THEN Iif([moe_sst_exam_result_code] IN (
							'E'
							,'M'
							), [dom].[NGT Class] + ': Ach. w M/E', iif([moe_sst_exam_result_code] IN ('A'), [dom].[NGT Class] + ': Ach.', [dom].[NGT Class] + ': F/Not comp'))
			ELSE [dom].[NGT Class] + ': Taken'
			END AS [res_lb]
		,cast([lu].[StandardLevel] AS VARCHAR) AS [StandardLevel]
		,[lu].[StandardTypeCode]
	FROM [$(IDIREF)].[moe_clean].[student_standard] [sst]
	INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_standard_lookup] [lu] ON [sst].[moe_sst_standard_code] = [lu].[StandardTableID]
	INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)subj_classification] [dom] ON [lu].[DomainCode] = [dom].[DomainCode]
	WHERE [lu].[StandardTypeCode] IN (
			1
			,2
			) --/*basic only and standard type */
	) [dct]
GO

/* 
Variable Ref 4
Qual/Quant iteration Variable Ref (3)
EVENT: Taking standards by level before age 19 (rationale: seeing what levels of standards do person take before they reach age of university attendance)
NB: retain only basic Unit/Achievement standards (see college ncea criteria, e.g. nzqa,aorere.ac.nz)
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_standard_level]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_standard_level];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_standard_level]
AS
SELECT [pop].[snz_uid]
	,min(moe_sst_nzqa_comp_date) AS [start_date]
	,max(moe_sst_nzqa_comp_date) AS [end_date]
	,'Taking standard: Level ' + cast([lu].[StandardLevel] AS VARCHAR) AS [description]
	,1 AS [value]
	,'moe student standard' AS [source]
FROM [$(IDIREF)].[moe_clean].[student_standard] [sst]
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop] ON [pop].[snz_uid] = [sst].[snz_uid]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_standard_lookup] [lu] ON [sst].[moe_sst_standard_code] = [lu].[StandardTableID]
WHERE [lu].[StandardTypeCode] IN (
		1
		,2
		)
GROUP BY [pop].[snz_uid]
	,[lu].[StandardLevel]
GO

/* Criteria - University entrance

1. NCEA Level 3  
2. Three subjects at level 3, made up of:
	-12 credits in each of three approved subjects (applies to 2020 only. In other years, 14 credits of three approved subjects is required).
3. Literacy - 10 credits at Level 2 or above, made up of:
	- 5 credits in reading 
	- 5 credits in writing
4. Numeracy - 10 credits at Level 1 or above, made up of:
	-achievement standards - specificied achievement standards available through a range of subjects, or
	-unit standards - package of three numeracy unit standards (26623, 26626, 26627 - all three are required).

*/
/*
Criteria 1.1: cumulative credits level 3 and above
*/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred3ab]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred3ab];
GO

SELECT [snz_uid]
	,[moe_sst_nzqa_comp_date] AS [event_date]
	,[TotalCredits]
	,sum([TotalCredits]) OVER (
		PARTITION BY [pop].[snz_uid] ORDER BY [moe_sst_nzqa_comp_date]
		) AS [CumTotalCredits3ab]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred3ab]
FROM (
	SELECT [moe].[snz_uid]
		,[moe_sst_nzqa_comp_date]
		,sum([Credit]) AS [TotalCredits]
	FROM [$(IDIREF)].[moe_clean].[student_standard] [moe]
	INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop] ON [pop].[snz_uid] = [moe].[snz_uid]
	INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_standard_lookup] [lu] ON [moe].[moe_sst_standard_code] = [lu].[StandardTableID]
	WHERE [moe].[moe_sst_exam_result_code] IN (
			'A'
			,'E'
			,'M'
			)
		AND [StandardLevel] >= 3
	GROUP BY moe.[snz_uid]
		,[moe_sst_nzqa_comp_date]
	) [pop]
GO

/*
Criteria 1.2: cumulative credits level 2
*/
IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred2]', 'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred2];
GO

SELECT [snz_uid]
	,[moe_sst_nzqa_comp_date] AS [event_date]
	,[TotalCredits]
	,sum([TotalCredits]) OVER (
		PARTITION BY [pop].[snz_uid] ORDER BY [moe_sst_nzqa_comp_date]
		) AS [CumTotalCredits2]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred2]
FROM (
	SELECT [moe].[snz_uid]
		,[moe_sst_nzqa_comp_date]
		,sum([Credit]) AS [TotalCredits]
	FROM [$(IDIREF)].[moe_clean].[student_standard] [moe]
	INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop] ON [pop].[snz_uid] = [moe].[snz_uid]
	INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_standard_lookup] [lu] ON [moe].[moe_sst_standard_code] = [lu].[StandardTableID]
	WHERE [moe].[moe_sst_exam_result_code] IN (
			'A'
			,'E'
			,'M'
			)
		AND [StandardLevel] = 2
	GROUP BY moe.[snz_uid]
		,[moe_sst_nzqa_comp_date]
	) [pop]
GO

CREATE INDEX idx ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred2] ([snz_uid]);

CREATE INDEX idx ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred3ab] ([snz_uid]);

/*
Criteria 1: NCEA level 3 
Event: When they attain the requirements for NCEA eligibility
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)ncea_lvl3]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)ncea_lvl3];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)ncea_lvl3]
AS
SELECT [b].[snz_uid]
	,[b].[event_date] AS [start_date]
	,[b].[event_date] AS [end_date]
	,[b].[CumTotalCredits3ab]
	,max([a].[CumTotalCredits2]) AS [CumTotalCredits2]
	,CASE 
		WHEN [b].[CumTotalCredits3ab] >= 80
			OR (
				[b].[CumTotalCredits3ab] >= 60
				AND max([a].[CumTotalCredits2]) >= 20
				)
			THEN 'NCEA Level 3: Yes'
		ELSE 'NCEA Level 3: No'
		END AS [description]
	,CASE 
		WHEN [b].[CumTotalCredits3ab] >= 80
			OR (
				[b].[CumTotalCredits3ab] >= 60
				AND max([a].[CumTotalCredits2]) >= 20
				)
			THEN 1
		ELSE 0
		END AS [value]
	,'moe standard' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred2] a
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)sstyr_cumcred3ab] b ON a.snz_uid = b.snz_uid
	AND a.event_date <= b.event_date
GROUP BY [b].[snz_uid]
	,[b].[event_date]
	,[b].[CumTotalCredits3ab]
GO

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_ncea_lvl3]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_ncea_lvl3];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_ncea_lvl3]
AS
SELECT [b].[snz_uid]
	,[b].[start_date]
	,[b].[end_date]
	,[b].[description]
	,[b].[value]
	,[b].[source]
FROM [$(PROJSCH)].[$(TBLPREF)ncea_lvl3] b
GO

/*
Event view: University eligibility
Event/indicator: attaining university eligibility
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)uni_entrance2]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)uni_entrance2];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)uni_entrance2]
AS
SELECT [pop].[snz_uid]
	,DATEFROMPARTS([ue].[moe_sue_attained_year_nbr], 12, 31) AS [start_date]
	,DATEFROMPARTS([ue].[moe_sue_attained_year_nbr], 12, 31) AS [end_date]
	,'UE Eligible: Yes' AS [description]
	,1 AS [value]
	,'moe students' AS [source]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)popyr_tak_unorm] [pop]
INNER JOIN [$(IDIREF)].[moe_clean].[student_ue] [ue] ON [pop].[snz_uid] = [ue].[snz_uid]
GO

/*
Event: qualification completion (joined with NZSCED) 

*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_tertprog_compl]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_tertprog_compl];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_tertprog_compl]
AS
SELECT [moe].[snz_uid]
	,[moe].[start_date]
	,[moe].[end_date]
	,'Tertiary prog completed: ' + [dct].[descriptor_text] AS [description]
	,'1' AS [value]
	,[moe].[source]
FROM (
	SELECT snz_uid
		,left(iif(isnumeric([moe_com_qual_nzsced_code]) = 1, FORMAT(cast([moe_com_qual_nzsced_code] AS INT), '000000'), [moe_com_qual_nzsced_code]), 2) AS nzsced2
		,DATEFROMPARTS(moe_com_year_nbr, 12, 31) AS [start_date]
		,DATEFROMPARTS(moe_com_year_nbr, 12, 31) AS [end_date]
		,'moe tertiary completion' AS [source]
	FROM [$(IDIREF)].[moe_clean].[completion] /*tertiary*/
	) [moe]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_NZSCED_FIELD] [dct] ON [moe].[nzsced2] = [dct].[cat_code]
GO

/*
Event: course completion (joined with NZSCED) based on the following codes:

0	Still to complete - valid extension or grade not yet available (Register Levels 1-8)
1	Still to complete - course end date not yet reached (Register Levels 1-8)
2	Completed course successfully
3	Completed course unsuccessfully
4	Did not complete course
5	Practicum to complete - on job training (Register Levels 1-8)
6	Yet to complete - Register Levels 9 & 10
7	Extension granted or under moderation - Register Levels 9 & 10
8	ompleted sucessfully theses written in Te Reo Maori
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_course_compl]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_course_compl];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_course_compl]
AS
SELECT [moe].[snz_uid]
	,[moe].[start_date]
	,[moe].[end_date]
	,[dct].[descriptor_text] + ': ' + iif([moe_crs_complete_code] IN (
			2
			,8
			), 'course completed', 'course not yet completed') AS [description]
	,'1' AS [value]
	,[moe].[source]
FROM (
	SELECT snz_uid
		,[moe_crs_complete_code]
		,left(iif(isnumeric([moe_crs_course_nzsced_code]) = 1, FORMAT(cast([moe_crs_course_nzsced_code] AS INT), '000000'), [moe_crs_course_nzsced_code]), 2) AS nzsced2 /*refer to the course not qual ([moe_crs_qual_nzsced_code])*/
		,moe_crs_start_date AS [start_date]
		,moe_crs_end_date AS [end_date]
		,'moe course enrolment' AS [source]
	FROM [$(IDIREF)].[moe_clean].[course] /*course*/
	) [moe]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_NZSCED_FIELD] [dct] ON [moe].[nzsced2] = [dct].[cat_code]
GO


