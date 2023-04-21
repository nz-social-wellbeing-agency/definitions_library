/**************************************************************************************************
Title: T3 benefit receipt
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

Description:
Number of hardship and emergency payment received.

Intended purpose:
Number of emergency benefits received.
Frequency of receipt.

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[emergency_benefit_receipt]

Notes:
1) MSD classifies support payments into three tiers:
	- T1 includes main benefits types that provide some replacement for income from employment.
	- T2 includes supplementary benefits like accommodation supplement and winter energy payment.
	- T3 includes hardship and emergency payments.
	While both T2 and T3 are in addition of a person's main income (e.g. benefit, pension, wages)
	one of the key differences is that T2 may be ongoing, while T3 are intended to be once-off
	(e.g. food grant, car repairs, school uniforms).

Parameters & Present values:
  Current refresh = YYYYMM
  Project schema = DL-MAA20XX-YY
  Year of interest = 2020
 
Issues:

History (reverse order):
2021-10-01 SB
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[emergency_benefit_receipt];
GO

CREATE VIEW [DL-MAA20XX-YY].[emergency_benefit_receipt] AS
SELECT snz_uid
	,msd_tte_decision_date
	,msd_tte_pmt_amt AS amount_received
	/* payment type codes */
	,msd_tte_parent_svc_code
	,msd_tte_lump_sum_svc_code
	,msd_tte_pmt_rsn_type_code
FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_third_tier_expenditure]
WHERE YEAR([msd_tte_decision_date]) >= 2020
GO
