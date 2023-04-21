/**************************************************************************************************
Title: Main benefit spell by type
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

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
Type of main benefit receipt spells where a person is the primary recipient or a partner.
Also includes NZ Superannuation as superannuatents interact with tier 2 and tier 3 
parts of the benefit system.

Intended purpose:
Creating indicators of benefit type(s) a person is receiving.

Inputs & Dependencies:
- main_benefits_by_type_and_partner_status.sql --> [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_abt_main_benefit_final]
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_main_benefit_types]


Notes:
1) NZ Super is distinct from main benefits. However, for the Debt to Government project
   we add it on to this definition because similar debt recovery options exist for
   people receiving Superannuation as for people receiving a main benefit.
2) This file is unnecessary in some refreshes as Benefit Dynamics Data includes Pensions
   for some refreshes. The correspondence between Pensions from MSD BDD records
   and NZSuper from the code below is very high (>95%).

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]
  earliest_year = 2014
  latest_year = 2020
 
Issues:
 
History (reverse order):
2021-04-19 SA note added regarding Pensions in some refreshes
2021-01-26 SA QA
2021-01-11 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 MP QA
2020-07-02 SA v1
**************************************************************************************************/

USE IDI_UserCode
GO

/* drop before re-creating */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2gP2_main_benefit_types];
GO

CREATE VIEW [DL-MAA20XX-YY].[d2gP2_main_benefit_types] AS

SELECT [snz_uid]
      ,[start_date]
      ,[end_date]
      ,[level4] AS [ben_type]
FROM [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_abt_main_benefit_final]
WHERE YEAR([start_date]) <= 2020
AND 2014 <= YEAR([end_date])

UNION ALL

SELECT snz_uid
       ,CASE WHEN [ir_ems_employee_start_date] IS NOT NULL
			AND [ir_ems_employee_start_date] < [ir_ems_return_period_date]
			AND DATEDIFF(DAY, [ir_ems_employee_start_date], [ir_ems_return_period_date]) < 60 -- employee started in the last two months
		THEN [ir_ems_employee_start_date]
		ELSE DATEFROMPARTS(YEAR([ir_ems_return_period_date]),MONTH([ir_ems_return_period_date]),1) END AS [start_date]
	   ,CASE WHEN [ir_ems_employee_end_date] IS NOT NULL
			AND [ir_ems_employee_end_date] < [ir_ems_return_period_date]
			AND ([ir_ems_employee_start_date] IS NULL OR [ir_ems_employee_start_date] < [ir_ems_employee_end_date])
			AND DATEDIFF(DAY, [ir_ems_employee_end_date], [ir_ems_return_period_date]) < 27 -- employee finished in the last month
		THEN [ir_ems_employee_end_date] 
		ELSE [ir_ems_return_period_date] END AS [end_date]
	   ,'NZSuper' AS [ben_type]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] IN ('PEN')
AND [snz_ird_uid] <> 0
AND YEAR([ir_ems_return_period_date]) BETWEEN 2014 AND 2020; -- exclude placeholder person without IRD number
GO

