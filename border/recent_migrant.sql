/**************************************************************************************************
Title: Recent migrant to New Zealand
Author: Simon Anastasiadis
Reviewer: Freya Li

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
Given a number of years within which a person is considered a recent migrant (see parameters) provides a spell during which people are considered recent migrants.

Intended purpose:
1. Identifying when people enter New Zealand for the first time.
2. Identifying whether a person is a recent migrant.

Inputs & Dependencies:
- [IDI_Clean].[data].[person_overseas_spell]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2g_recent_migrants]
 
Notes:
1) Overseas spells are stored as date-time with non-trivial time.
   For consistency with other date, we remove their time component.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = tmp_
  Project schema = [DL-MAA20XX-YY]
  Years 'recent' must be within = 2
 
Issues:
 
History (reverse order):
2020-11-20 FL QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Remove view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2g_recent_migrants];
GO

CREATE VIEW [DL-MAA20XX-YY].[d2g_recent_migrants] AS
SELECT [snz_uid]
      ,CAST([pos_ceased_date] AS DATE) AS [start_date]
	  ,IIF(YEAR([pos_ceased_date]) = 9999, CAST([pos_ceased_date] AS DATE), DATEADD(YEAR, 2, CAST([pos_ceased_date] AS DATE))) AS [end_date]
      ,[pos_first_arrival_ind]
      ,[pos_last_departure_ind]
      ,[pos_source_code]
FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell]
WHERE pos_first_arrival_ind = 'y';
GO
