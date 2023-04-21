/*************************************************************************************
Title: Temporary additional supplement
Author: Verity Warn

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
Temporary accommodation supplement payments.

Intended purpose:
- Identifying usage of temporary additional supplements in the 65+ population

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Adhoc].[clean_read_MSD].[benefit_codes]
Output:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_temp_add_supp]

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]


Notes
- Latest start date is 2021-12-31

History:
2022-06-14 VW Implement SA QA - rename table, add extra TAS codes, edit join to take only current benefit type codes
2022-06-14 SA QA
2022-05-30 VW Created definition
**************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_temp_add_supp];
GO

CREATE VIEW [DL-MAA20XX-YY].[defn_temp_add_supp] AS
SELECT snz_uid
      ,msd_ste_start_date
	  ,msd_ste_end_date
	  ,ROUND([msd_ste_period_nbr] * [msd_ste_daily_gross_amt], 2) AS tas_gross_payment -- [msd_ste_period_nbr] equals number of days start-to-end inclusive
	  --,level4 -- confirm TAS
FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_second_tier_expenditure] AS k
LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] AS code
ON k.msd_ste_supp_serv_code = code.serv
AND code.ValidFromtxt <= k.msd_ste_start_date
AND k.msd_ste_start_date <= code.ValidTotxt
WHERE msd_ste_supp_serv_code IN ('450', '460', '473') -- TAS code
GO


