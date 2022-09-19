/*************************************************************************************
Title: Temporary additional supplement 
Author: Verity Warn

Inputs & Dependencies:
- [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure]
Output:
- [IDI_UserCode].[DL-MAA2018-48].[defn_temp_add_supp]

Description:
Temporary accomodation supplement payments

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Intended purpose:
- Identifying usage of temporary additional supplements in the 65+ population

Notes
- Latest start date is 2021-12-31

History:
2022-06-14 VW Implement SA QA - rename table, add extra TAS codes, edit join to take only current benefit type codes
2022-06-14 SA QA
2022-05-30 VW Created definition
**************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_temp_add_supp];
GO

CREATE VIEW [DL-MAA2018-48].[defn_temp_add_supp] AS
SELECT snz_uid
      ,msd_ste_start_date
	  ,msd_ste_end_date
	  ,ROUND([msd_ste_period_nbr] * [msd_ste_daily_gross_amt], 2) AS tas_gross_payment -- [msd_ste_period_nbr] equals number of days start-to-end inclusive
	  --,level4 -- confirm TAS
FROM [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure] AS k
LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] AS code
ON k.msd_ste_supp_serv_code = code.serv
AND code.ValidFromtxt <= k.msd_ste_start_date
AND k.msd_ste_start_date <= code.ValidTotxt
WHERE msd_ste_supp_serv_code IN ('450', '460', '473') -- TAS code
GO


--select top 100 * from [IDI_UserCode].[DL-MAA2018-48].[defn_temp_add_supp]

