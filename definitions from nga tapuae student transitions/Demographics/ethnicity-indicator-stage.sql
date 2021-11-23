/* 
Title: Ethnicity
Author: Michael Hackney
Reviewer: Simon Anastasiadis
Intended use: Identification of ethnicity

Notes:
Ethnicity drawn from personal details.
Ethnicity is assumed to be universal, hence applies to all
time periods.

History (reverse order): 
2020-
2019-04-09 AK (QA)
2018-12-05 Simon A (QA)
2018-12-03 Initiated by MH for HaBiSA
*/
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

--##############################################################################################################
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)ETHNICITY]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)ETHNICITY];
GO

CREATE VIEW [$(PROJSCH)].$( TBLPREF ) ETHNICITY AS

-- European
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = EUROPEAN' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE (snz_ethnicity_grp1_nbr = 1)

UNION ALL

-- Maori
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = MAORI' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE snz_ethnicity_grp2_nbr = 1

UNION ALL

-- Pacific Peoples
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = PACIFIC' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE (snz_ethnicity_grp3_nbr = 1)

UNION ALL

-- Asian
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = ASIAN' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE (snz_ethnicity_grp4_nbr = 1)

UNION ALL

-- MIDDLE EASTERN/LATIN AMERICAN/AFRICAN
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = MELAA' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE (snz_ethnicity_grp5_nbr = 1)

UNION ALL

-- OTHER ETHNICITY
SELECT personal_detail.snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS end_date
	,'Ethnicity = OTHER' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE (snz_ethnicity_grp6_nbr = 1);
GO


