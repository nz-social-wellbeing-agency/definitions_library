/**************************************************************************************************
Title: Census 2018 Occupation
Author: Shaan Badenhorst

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_Cen2018_Occupation]

Description:
Occupation as reported in Census 2018.

Intended purpose:
Identifying occupation of individuals at Census 2018, or the broad type of
work / skills beyond Census 2018.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Date of interest = '2021-10-13'
 
Issues:

History (reverse order):
2021-11-25 SA review and tidy
2021-08-31 SB changing dataset to Census 2018 for vaccination data analysis
**************************************************************************************************/

/*embedded in user code*/
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_Cen2018_Occupation];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_Cen2018_Occupation] AS
SELECT snz_uid
	,'2018-03-06' AS census_date
	,CAST(cen_ind_occupation_code AS INTEGER) AS cen_ind_occupation_code
FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2018];
GO
