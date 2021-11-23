/******************************************************************************************************************
Title: Older sibling's highest qualifications
Author: Marianna Pekar based on Simon Anastasiadis (2018-12-03, HaBiSA codes, role as sibling)
Reviewer: AK, Awaiting full review
Intended use: Biological parents' educational attainment, work status

Notes:
[$(PROJSCH)].[$(TBLPREF)older_sibling] creates snz_uids of biological full and half siblings
[$(PROJSCH)].[$(TBLPREF)highest_qual_sibling] identifies highest educational attainment


Issues:
 
History (reverse order):
2020-08-19 MP linking highest qualifications
2018-04-24 AK review
2018-12-03 SA v0


******************************************************************************************************************/

--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/


--##############################################################################################################

/*embedded in user code*/
USE IDI_UserCode
GO


-- Create view with older siblings' snz_uids

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)older_sibling]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)older_sibling];
GO

/* staging view */
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)older_sibling] AS

/* Older siblings - full */
SELECT sib.snz_uid AS sib_snz_uid
		,'full sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON (baby.parent1_snz_uid = sib.parent1_snz_uid AND baby.parent2_snz_uid = sib.parent2_snz_uid) -- same parents
WHERE 
-- baby.dia_bir_birth_year_nbr >= 1990  AND -- birth post 1990
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL
AND baby.parent2_snz_uid IS NOT NULL -- baby has 2 birth parents
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid AS sib_snz_uid
		,'full sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON (baby.parent2_snz_uid = sib.parent1_snz_uid AND baby.parent1_snz_uid = sib.parent2_snz_uid) -- same parents, reversed order
WHERE 
-- baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
--AND 
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL
AND baby.parent2_snz_uid IS NOT NULL -- baby has 2 birth parents
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

/* Siblings - half */
SELECT sib.snz_uid AS sib_snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON baby.parent1_snz_uid = sib.parent1_snz_uid -- baby and sibling have same parent1
WHERE 
--baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
--AND 
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL -- baby has birth parent1
AND (baby.parent2_snz_uid <> sib.parent2_snz_uid
	OR baby.parent2_snz_uid IS NULL
	OR sib.parent2_snz_uid IS NULL) -- baby and sibling have different parent2, or no parent2
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
	OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
		AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid AS sib_snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON baby.parent1_snz_uid = sib.parent2_snz_uid -- baby parent1 = sibling parent2
WHERE 
--baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
--AND 
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent1_snz_uid IS NOT NULL -- baby has birth parent1
AND (baby.parent2_snz_uid <> sib.parent1_snz_uid
	OR baby.parent2_snz_uid IS NULL
	OR sib.parent1_snz_uid IS NULL) -- baby and sibling other parent is different, or no other parent
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
	OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
		AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid AS sib_snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON baby.parent2_snz_uid = sib.parent2_snz_uid -- baby and sibling have same parent2
WHERE 
--baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
--AND 
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent2_snz_uid IS NOT NULL -- baby has birth parent2
AND (baby.parent1_snz_uid <> sib.parent1_snz_uid
	OR baby.parent1_snz_uid IS NULL
	OR sib.parent1_snz_uid IS NULL) -- baby and sibling have different parent1, or no parent 1
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby

UNION ALL

SELECT sib.snz_uid AS sib_snz_uid
		,'half sibling' AS [role]
		,baby.snz_uid AS snz_uid
FROM [$(IDIREF)].[dia_clean].[births] baby
INNER JOIN [$(IDIREF)].[dia_clean].[births] sib
ON baby.parent2_snz_uid = sib.parent1_snz_uid -- baby parent2 = sibling parent1
WHERE 
--baby.dia_bir_birth_year_nbr >= 1990 -- birth post 1990
--AND 
baby.[dia_bir_still_birth_code] IS NULL -- baby not still born
AND sib.[dia_bir_still_birth_code] IS NULL -- sibling not still born
AND baby.parent2_snz_uid IS NOT NULL -- baby has birth parent2
AND (baby.parent1_snz_uid <> sib.parent2_snz_uid
	OR baby.parent1_snz_uid IS NULL
	OR sib.parent2_snz_uid IS NULL) -- baby and sibling other parent is different, or no other parent
AND (sib.dia_bir_birth_year_nbr < baby.dia_bir_birth_year_nbr
OR (sib.dia_bir_birth_year_nbr = baby.dia_bir_birth_year_nbr
AND sib.dia_bir_birth_month_nbr < baby.dia_bir_birth_month_nbr)) -- sibling is born before baby
GO


/*
Title: Reward of a qualification
Author: Simon Anastasiadis
Reviewer: awaiting feedback
Intended use: Identification of highest qualification

Notes:
Where only year is available assumed qualification awarded 1st December (approx, end of calendar year)
Code guided by Population Explorer Highest Qualification code in SNZ Population Explorer by Peter Elis
github.com/StatisticsNZ/population-explorer/blob/master/build-db/01-int-tables/18-qualificiations.sql

1 = Certificate or NCEA level 1
2 = Certificate or NCEA level 2
3 = Certificate or NCEA level 3
4 = certificate level 4
5 = Certificate of diploma level 5
6 = Certificate or diploma level 6
7 = Bachelors degree, graduate diploma or certificate level 7
8 = Bachelors honours degree or postgraduate diploma or certificate level 8
9 = Masters degree
10 = Doctoral degree

History (reverse order):
2019-04-26 SA
- there are only 10 NZ qualification levels, values of 0 or 99 are assumed to be non-qualitication codes.
- Metadata gives 99 as unknown qualification level
2019-04-23 AK
- Further business info required on use of code filters for education level. There are levels like 00, 99 which have been excluded without any explanation.
2018-12-05 initiated (SA_
*/

USE IDI_UserCode
GO

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)highest_qual]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)highest_qual];
GO

/* staging view */
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)highest_qual] AS
SELECT snz_uid
		,award_date AS [start_date]
		,award_date AS [end_date]
		,'qual level awarded' AS [description]
		,qual AS [value]
		,'moe x3' AS [source]
FROM (
	-- Primary and secondary
	SELECT snz_uid
			,DATEFROMPARTS(moe_sql_attained_year_nbr,12,1) AS award_date
			,moe_sql_nqf_level_code AS qual
	FROM [$(IDIREF)].[moe_clean].[student_qualification]

	UNION ALL

	-- Tertiary qualification
	SELECT snz_uid
			,DATEFROMPARTS(moe_com_year_nbr,12,1) AS award_date
			,moe_com_qual_level_code AS qual
	FROM [$(IDIREF)].[moe_clean].[completion]
	WHERE moe_com_qual_level_code IS NOT NULL

	UNION ALL

	-- Industry traing qualifications
	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,1 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level1_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,2 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level2_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,3 AS qual
	FROM  [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level3_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,4 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level4_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,5 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level5_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,6 AS qual
	FROM [$(IDIREF)].moe_clean.tec_it_learner
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level6_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,7 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level7_qual_awarded_nbr > 0

	UNION ALL

	SELECT snz_uid
			,moe_itl_end_date AS award_date
			,8 AS qual
	FROM [$(IDIREF)].[moe_clean].[tec_it_learner]
	WHERE moe_itl_end_date IS NOT NULL
	AND moe_itl_level8_qual_awarded_nbr > 0

) all_awarded_qualitifications
WHERE qual IN (1,2,3,4,5,6,7,8,9,10); -- limit to 10 levels of NZQF
GO


/* 

Title: Sibling's highest qualification
Author: Marianna Pekar
Reviewer: awaiting feedback
Intended Identification of highest qualification amongst full and half siblings

Dependencies: 
- the preceeding two views: identification of full and half siblings and the view 

History (reverse order):
2020-08-20 initiated (MP)



*/

IF OBJECT_ID('[IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping]','U') IS NOT NULL
DROP Table [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping];
GO

--Use IDI_Sandpit;

Create table  [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping] (
	[qual_code] INT,
	[qual_description] NVARCHAR(MAX)
);
GO


INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping] ([qual_code], [qual_description])
VALUES 
(1, 'Level 1-3'),
(2, 'Level 1-3'),
(3, 'Level 1-3'),
(4, 'Level 4-6'),
(5, 'Level 4-6'),
(6, 'Level 4-6'),
(7, 'Level 7+'),
(8, 'Level 7+'),
(9, 'Level 7+'),
(10, 'Level 7+');
GO


--##############################################################################################################

/*embedded in user code*/
USE IDI_UserCode
GO


/* staging view */
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)highest_qual_sibling]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)highest_qual_sibling];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)highest_qual_sibling] AS
SELECT snz_uid	
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,[value]
	,quals.[qual_description] AS [description]
	,'older sibling highest qual' AS [source]
FROM((
	SELECT snz_uid
	--	,[qual_description] AS [description]
		,max([value]) AS [value]
	FROM ( 
		SELECT a.snz_uid
			,a.sib_snz_uid
			,b.value
			,b.source
		FROM [$(PROJSCH)].[$(TBLPREF)older_sibling] AS a
		LEFT JOIN [$(PROJSCH)].[$(TBLPREF)highest_qual] AS b
		ON a.sib_snz_uid=b.snz_uid
		WHERE b.value IS NOT NULL
		) AS c
	GROUP BY snz_uid) d	
	LEFT JOIN  [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping] AS quals
	ON d.value=quals.qual_code
	);
GO

/* Drop tables and views except the final output table*/

DROP VIEW  [$(PROJSCH)].[$(TBLPREF)older_sibling];
DROP VIEW  [$(PROJSCH)].[$(TBLPREF)highest_qual];
DROP TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)quals_mapping];

