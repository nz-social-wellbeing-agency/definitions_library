/*************************************************************************************
Title: Accomodation supplement 
Author: Verity Warn

Inputs & Dependencies:
- [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_serv_codes]
Output:
- [IDI_UserCode].[DL-MAA2018-48].[defn_accom_supp]

Description:
Accomodation supplement and accomodation benefit payments

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Intended purpose:
- Identifying usage of accomodation supplements in the 65+ population

History
2022-06-14 VW Implement QA suggestions (rename table for reading ease, fix join to ensure benefit serv codes are relevant to period)
2022-06-14 SA QA
2022-05-26 VW Definition creation

**************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_accom_supp];
GO

CREATE VIEW [DL-MAA2018-48].[defn_accom_supp] AS
SELECT [snz_uid]
	,[msd_ste_start_date]
	,[msd_ste_end_date]
	,ROUND([msd_ste_period_nbr] * [msd_ste_daily_gross_amt], 2) AS [gross_payment] -- [msd_ste_period_nbr] equals number of days start-to-end inclusive
	--,level1 -- confirm accom supp/benefit
FROM [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure] AS k
LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] AS code
ON k.msd_ste_supp_serv_code = code.serv
AND (k.msd_ste_supp_serv_code = code.additional_service_data
	OR (code.additional_service_data IS NULL 
		AND (k.msd_ste_supp_serv_code ='null' OR k.msd_ste_supp_serv_code IS NULL)
		))
AND code.ValidFromtxt <= k.[msd_ste_start_date]
AND k.[msd_ste_start_date] <= code.ValidTotxt
WHERE msd_ste_supp_serv_code IN ('470', '471') -- accomodation support, accomodation benefit (there are others could include, check e.g. tenure allowance, income related rent subsidy HNZ)
GO


--select top 100 * FROM [DL-MAA2018-48].[defn_accom_supp]
