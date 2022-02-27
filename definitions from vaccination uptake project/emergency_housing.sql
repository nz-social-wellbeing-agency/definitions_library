/**************************************************************************************************
Title: Emergency housing
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_Cen2018_Occupation]

Description:
Emergency housing application

Intended purpose:
Identify the month of most recent primary applicant for emergency housing

Notes:
1) Pay reason 855 in the MSD T3 table is for Emergency Housing (EH).

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-12 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_emergeny_housing]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_emergeny_housing] AS
SELECT [snz_uid]
	,[snz_msd_uid]
	--,[msd_tte_snz_unique_nbr]
	--,[snz_swn_nbr]
	--,[msd_tte_ttp_grp_nbr]
	--,[msd_tte_tt_pmt_nbr]
	--,[msd_tte_decision_date]
	--,[msd_tte_app_date]
	--,[msd_tte_ref_date]
	--,[msd_tte_parent_svc_code]
	--,[msd_tte_lump_sum_svc_code]
	--,[msd_tte_pmt_rsn_type_code]
	--,[msd_tte_pmt_amt]
	--,[msd_tte_recoverable_ind]
	--,[msd_tte_rcmd_dist_code]
	,1 as emergency_housing
FROM [IDI_Clean_20211020].[msd_clean].[msd_third_tier_expenditure]
WHERE [msd_tte_pmt_rsn_type_code] IN ('855')
AND [msd_tte_app_date] >= '2021-03-01'
GO
