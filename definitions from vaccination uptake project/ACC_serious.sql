/**************************************************************************************************
Title: ACC serious injury under management
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[acc_clean].[claims]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_ACC_serious]

Description:
Indicator for ACC serious injury with management still open.

Intended purpose:
Identifying where people have had a serious injury where the resolution
of the injury is ongoing with ACC.

Notes:
1) First medical certification type:
	- FUF = Fully unfit
	- FFSW = Fit for selected work.
	- FATAL
	 First incapacity covers the first sequential period of incapacity, across multiple medical certificates.


Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_ACC_serious]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_ACC_serious] AS
SELECT [snz_uid]
	--,[snz_acc_claim_form_45_uid]
	--,[snz_acc_claim_uid]
	--,[acc_cla_accident_date]
	--,[acc_cla_case_management_end_date]
	--,[acc_cla_serious_injury_ind]
	--,year([acc_cla_accident_date]) as year
	--,[acc_cla_multiple_injury_ind]
	--,[acc_cla_read_code]
	--,[acc_cla_ICD10_code]
	--,[acc_cla_activity_prior_text]
	--,[acc_cla_external_agency_text]
	--,[acc_cla_cause_desc]
	--,[acc_cla_contact_desc]
	--,[acc_cla_primry_diagnos_grp_text]
	--,[acc_cla_primary_injury_site_text]
	--,[acc_cla_fatal_ind]
	--,[acc_cla_first_incapacity]
	--,[acc_cla_first_incapacity_type]
	--,[acc_cla_first_incapacity_days]
FROM [IDI_Clean_20211020].[acc_clean].[claims]
WHERE ([acc_cla_case_management_end_date] IS NULL OR [acc_cla_case_management_end_date] = '9999-12-31')
AND [acc_cla_serious_injury_ind] = 'Y'
AND YEAR([acc_cla_accident_date]) IN (2020,2021)
GO  
