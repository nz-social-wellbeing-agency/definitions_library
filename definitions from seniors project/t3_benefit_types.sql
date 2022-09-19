/**************************************************************************************************
Title: T3 benefit types / hardship assistance types
Author: Verity Warn
Reviewer: Penny Mok 

Inputs & Dependencies:
- [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure] 
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason] 
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_serv_codes] 
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_gss1418]

Description:
Identifying types of hardship assistance. MSD interested in Special Needs Grants - particularly for Food and Medical And Associated Costs (SNG)


Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
History (reverse order):
2022-07-19 VW Edit filters on final table (only identify SNG)
2022-07-15 VW Definition creation
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_t3_types];

/* Create temporary table with all required metadata */
WITH t3_types AS(
SELECT 
	snz_uid
	,[msd_tte_lump_sum_svc_code]
	,benefit_name
	,[msd_tte_pmt_rsn_type_code]
	,b.payment_reason_lvl2
	,b.payment_reason_lvl1
	,msd_tte_decision_date
	,msd_tte_pmt_amt
FROM  [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure] a
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason] b
ON a.[msd_tte_pmt_rsn_type_code] = b.[payrsn_code]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_serv_codes] c
ON a.[msd_tte_lump_sum_svc_code] = c.serv_code
WHERE [msd_tte_recoverable_ind] = 'N'
)

/* Create flags for special needs grant types MSD interested in */
SELECT snz_uid
	,msd_tte_decision_date
	,IIF(payment_reason_lvl2 = 'Food' AND msd_tte_pmt_amt > 0, 1, 0) AS special_needs_grant_food
	,IIF(payment_reason_lvl2 = 'Medical And Associated Costs (SNG)' AND msd_tte_pmt_amt > 0, 1, 0) AS special_needs_grant_medical
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_t3_types]
FROM t3_types
WHERE benefit_name = 'Special Needs Grant' -- therefore any snz_uid in this output table has a special needs grant


--SELECT TOP 1000 * FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_t3_types]