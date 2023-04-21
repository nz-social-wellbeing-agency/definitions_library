/**************************************************************************************************
Title: Special Needs Grant - Food or Medical grants
Author: Verity Warn
Reviewer: Penny Mok 

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
Identify T3 benefit hardship assistance - Special Needs Food grants or Special Needs Medical grants. 

Intended Purpose: 
Identify Special Needs Grants - particularly for Food and Medical And Associated Costs (SNG)

Inputs & Dependencies:
- [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure] 
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason] 
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_serv_codes] 
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_gss1418]

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
History (reverse order):
2022-07-19 VW Edit filters on final table (only identify SNG)
2022-07-15 VW Definition creation
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_t3_types];

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
FROM  [IDI_Clean_YYYYMM].[msd_clean].[msd_third_tier_expenditure] a
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
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_t3_types]
FROM t3_types
WHERE benefit_name = 'Special Needs Grant' -- therefore any snz_uid in this output table has a special needs grant


