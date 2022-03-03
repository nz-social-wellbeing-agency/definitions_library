/**************************************************************************************************
Title: T3 Benefit receipt
Author: Shaan Badenhorst

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_emergency_benefit_receipt]

Description:
Tier 3 (emergency) benefit receipt.

Intended purpose:
Number of emergency benefits received.
Frequency of receipt.

Notes:
1) MSD classifies support payments into three tiers:
	- T1 includes main benefits types that provide some replacement for income from employment.
	- T2 includes supplementary benefits like accommodation supplement and winter energy payment.
	- T3 includes hardship and emergency payments.
	While both T2 and T3 are in addition of a person's main income (e.g. benefit, pension, wages)
	one of the key differences is that T2 may be ongoing, while T3 are intended to be once-off
	(e.g. food grant, car repairs, school uniforms).

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Year of interest = 2020
 
Issues:

History (reverse order):
2021-10-01 SB
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_emergency_benefit_receipt];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_emergency_benefit_receipt] AS
SELECT snz_uid
	,msd_tte_decision_date
	,msd_tte_pmt_amt AS amount_received
	/* payment type codes */
	,msd_tte_parent_svc_code
	,msd_tte_lump_sum_svc_code
	,msd_tte_pmt_rsn_type_code
FROM [IDI_Clean_20211020].[msd_clean].[msd_third_tier_expenditure]
WHERE YEAR([msd_tte_decision_date]) >= 2020
GO
