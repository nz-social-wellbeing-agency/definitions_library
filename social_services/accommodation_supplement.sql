/*************************************************************************************
Title: Accommodation supplement 
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
Accomodation supplement and accommodation benefit payments

Intended purpose:
Identify number of people receiving accommodation supplement and accomodation benefit payments.

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_serv_codes]
Output:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_accom_supp]

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

History
2022-06-14 VW Implement QA suggestions (rename table for reading ease, fix join to ensure benefit serv codes are relevant to period)
2022-06-14 SA QA
2022-05-26 VW Definition creation

**************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_accom_supp];
GO

CREATE VIEW [DL-MAA20XX-YY].[defn_accom_supp] AS
SELECT [snz_uid]
	,[msd_ste_start_date]
	,[msd_ste_end_date]
	,ROUND([msd_ste_period_nbr] * [msd_ste_daily_gross_amt], 2) AS [gross_payment] -- [msd_ste_period_nbr] equals number of days start-to-end inclusive
FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_second_tier_expenditure] AS k
LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] AS code
	ON k.msd_ste_supp_serv_code = code.serv
AND (k.msd_ste_supp_serv_code = code.additional_service_data
	OR (code.additional_service_data IS NULL 
		AND (k.msd_ste_supp_serv_code ='null' OR k.msd_ste_supp_serv_code IS NULL)
		))
AND code.ValidFromtxt <= k.[msd_ste_start_date]
AND k.[msd_ste_start_date] <= code.ValidTotxt
WHERE msd_ste_supp_serv_code IN ('470', '471') -- accommodation support, accommodation benefit (there are others could include, check e.g. tenure allowance, income related rent subsidy HNZ)
GO
