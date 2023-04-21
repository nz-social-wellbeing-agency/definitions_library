/**************************************************************************************************
Title: Census 2018 occupation details
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

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_Cen2018_Occupation]

Description:
Occupation as reported in Census 2018.

Intended purpose:
Identifying occupation of individuals at Census 2018, or the broad type of work / skills beyond Census 2018.

Notes:

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-11-25 SA review and tidy
**************************************************************************************************/

/*embedded in user code*/
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_Cen2018_Occupation];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_Cen2018_Occupation] AS
SELECT snz_uid
	,CAST(cen_ind_occupation_code AS INTEGER) AS cen_ind_occupation_code
FROM [IDI_Clean_YYYYMM].[cen_clean].[census_individual_2018];
GO
