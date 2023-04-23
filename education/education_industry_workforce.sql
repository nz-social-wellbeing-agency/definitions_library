/**************************************************************************************************
Title: Education industry employees
Author: Shaan Badenhorst

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
Employed by an education providing organisations.

Intended purpose:
Proxy for identifying teachers, instructors, and teaching assistants.

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_education_workforce]

Notes:
1) Will also capture other employees of education organisations (e.g. administrators, janitors, security).

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
  Year of employment = YYYY
 
Issues:

History (reverse order):
2021-11-20 SB
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_education_workforce];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_education_workforce] AS
SELECT	snz_uid
	,[snz_employer_ird_uid]
	,[ir_ems_gross_earnings_amt]
	,[ir_ems_return_period_date]
	,[ir_ems_enterprise_nbr]
	,[ir_ems_pbn_nbr]
	,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 3) AS anzsic06_3char
	,COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]) AS anzsic06
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems] 
WHERE [ir_ems_income_source_code] IN ('W&S', 'WHP')
AND [snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
AND YEAR([ir_ems_return_period_date]) = YYYY 
AND (
	LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 1) = 'P'
	OR COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]) = 'Q871000'
)
GO
