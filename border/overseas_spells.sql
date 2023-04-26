/**************************************************************************************************
Title: Overseas spells
Author: Joel Bancolita, Marianna Pekar

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

Inputs & Dependencies:
- [IDI_Clean].[data].[person_overseas_spell]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_overseas_spell]
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_currently_overseas]

Description:
Spells overseas.

Intended purpose:
1. Identifying when a person is overseas.
2. Counting days overseas.
3. Determining who has left country and is yet to return.

Notes:

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-09-01: MP revised measures and parameters, extract measures relevant to vaccine rollout analysis
2020-08-20: JB additional revised measures
2020-08-08: JB additional revised measures
2020-07-08: JB additional revised measures
2020-06-24: JB revised initial measures
2020-06-09: JB initialise
**************************************************************************************************/

USE IDI_UserCode
GO

-- Spell overseas
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_overseas];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_overseas_spell] AS
SELECT [snz_uid]
	,CAST([pos_applied_date] AS DATE) AS [start_date]
	,CAST([pos_ceased_date] AS DATE) AS [end_date]
FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell]
GO

-- Indicator of currently overseas.
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_OSSpells];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_currently_overseas] AS
SELECT [snz_uid]
	,CAST([pos_applied_date] AS DATE) AS [start_date]
	,CAST([pos_ceased_date] AS DATE) AS [end_date]
FROM [IDI_Clean_YYYYMM].[data].[person_overseas_spell]
WHERE year([pos_ceased_date]) = 9999
GO
