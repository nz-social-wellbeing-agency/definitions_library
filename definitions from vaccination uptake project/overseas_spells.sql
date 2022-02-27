/**************************************************************************************************
Title: Overseas spells
Author: Joel Bancolita, Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[data].[person_overseas_spell]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_overseas_spell]
- [IDI_UserCode].[DL-MAA2021-49].[vacc_currently_overseas]

Description:
Spells overseas

Intended purpose:
Identifying when a person is overseas.
Counting days overseas.
Determining who has left country and is yet to return.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
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
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_overseas];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_overseas_spell] AS
SELECT [snz_uid]
	,CAST([pos_applied_date] AS DATE) AS [start_date]
	,CAST([pos_ceased_date] AS DATE) AS [end_date]
FROM [IDI_Clean_20211020].[data].[person_overseas_spell]
GO

-- Indicator of currently overseas.
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_OSSpells];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_currently_overseas] AS
SELECT [snz_uid]
	,CAST([pos_applied_date] AS DATE) AS [start_date]
	,CAST([pos_ceased_date] AS DATE) AS [end_date]
FROM [IDI_Clean_20211020].[data].[person_overseas_spell]
WHERE year([pos_ceased_date]) = 9999
GO
