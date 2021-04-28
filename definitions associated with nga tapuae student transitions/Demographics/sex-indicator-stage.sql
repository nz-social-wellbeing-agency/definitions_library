/* 
Title: Sex (biological)
Author:Marianna Pekar
Reviewer: awaiting (trivial)
Date: 24/08/2020
Intended use: Identification of biological sex as on birth certificate (as of now gender is not observable in IDI)

Notes:
Sex drawn from personal details.
For simplicity sex at birth is assumed to be universal, hence applies to all time periods.

History (reverse order): 
2020-08-24 MP initiated

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
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)SEX]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)SEX];
GO

CREATE VIEW [$(PROJSCH)].$( TBLPREF ) SEX AS

SELECT snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS "end_date"
	,'Sex = Male' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE snz_sex_code = 1

UNION ALL

SELECT snz_uid
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS "end_date"
	,'Sex = Female' AS "description"
	,1 AS value
	,'personal details' AS [source]
FROM [$(IDIREF)].[data].[personal_detail]
WHERE snz_sex_code = 2;
GO


