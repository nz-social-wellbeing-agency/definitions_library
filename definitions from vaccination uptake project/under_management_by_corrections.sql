/**************************************************************************************************
Title: Under management by corrections
Author: Simon Anastasiadis
Reviewer: AK

Inputs & Dependencies:
- [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_corrections_any]

Description:
Any period under management by department of corrections
(including remand, parole, prison --> see [cor_mmp_mmc_code])

Intended purpose:
Identify periods and events of management within the justice system

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-01 SB Adopted for vaccination uptake work
2020-08-19 MP parameterised, simplified Correction events
2019-04-23 AK Reviewed
2019-01-10 SA Initiated
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_corrections_any];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_corrections_any] AS
SELECT [snz_uid]
	,[cor_mmp_mmc_code]
	,[cor_mmp_period_start_date]
	,[cor_mmp_period_end_date]
FROM  [IDI_Clean_20211020].[cor_clean].[ov_major_mgmt_periods]
WHERE [cor_mmp_mmc_code] NOT IN ('AGED_OUT', 'ALIVE');
GO
