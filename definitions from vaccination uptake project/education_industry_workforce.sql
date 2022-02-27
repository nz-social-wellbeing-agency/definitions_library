/**************************************************************************************************
Title: Education industry employees
Author: Shaan Badenhorst

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_education_workforce]

Description:
Employed by an education providing organisations

Intended purpose:
Proxy for identifying teachers, instructors, and teaching assistants.

Notes:
1) Will also capture other employees of education organisations
	(e.g. administrators, janitors, security).

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Year of employment = 2021
 
Issues:

History (reverse order):
2021-11-20 SB
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_education_workforce];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_education_workforce] AS
SELECT	snz_uid
	,[snz_employer_ird_uid]
	,[ir_ems_gross_earnings_amt]
	,[ir_ems_return_period_date]
	,[ir_ems_enterprise_nbr]
	,[ir_ems_pbn_nbr]
	,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 3) AS anzsic06_3char
	,COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]) AS anzsic06
FROM [IDI_Clean_20211020].[ir_clean].[ird_ems] 
WHERE [ir_ems_income_source_code] IN ('W&S', 'WHP')
AND [snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
AND YEAR([ir_ems_return_period_date]) = 2021 
AND (
	LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 1) = 'P'
	OR COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]) = 'Q871000'
)
GO
