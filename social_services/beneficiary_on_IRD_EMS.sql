/**************************************************************************************************
Title: Beneficiary indicator based on IRD EMS
Author:  Freya Li
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
Main benefit receipt indicator on IRD EMS.

Intended purpose:
Creating indicators of individuals who receiving benefit and identifiable on IRD EMS data.

Inputs & Dependencies:
- [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]

Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_benefit_ind]

Notes:

Parameters & Present values:
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2021-06-10 SA QA
2021-04-16 FL v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2gP2_benefit_ind];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[d2gP2_benefit_ind] AS
SELECT snz_uid
       ,[ir_ems_return_period_date]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]
WHERE ir_ems_income_source_code = 'BEN'      -- income source is benefit
--AND YEAR([ir_ems_return_period_date]) = YYYY
--AND MONTH([ir_ems_return_period_date]) = MM   -- has benefit record on specfic date  
GO
