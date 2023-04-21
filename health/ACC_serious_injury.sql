/**************************************************************************************************
Title: ACC serious injury under management
Author: Craig Wright

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
Indicator for ACC serious injury with management still open.

Intended purpose:
Identifying where people have had a serious injury where the resolution
of the injury is ongoing with ACC.

Inputs & Dependencies:
- [IDI_Clean].[acc_clean].[claims]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_ACC_serious]

Notes:
1) First medical certification type:
	- FUF = Fully unfit
	- FFSW = Fit for selected work.
	- FATAL
	 First incapacity covers the first sequential period of incapacity, across multiple medical certificates.


Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_ACC_serious]
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_ACC_serious] AS
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
FROM [IDI_Clean_YYYYMM].[acc_clean].[claims]
WHERE ([acc_cla_case_management_end_date] IS NULL OR [acc_cla_case_management_end_date] = '9999-12-31')
AND [acc_cla_serious_injury_ind] = 'Y'
AND YEAR([acc_cla_accident_date]) IN (2020,2021) -- claims between 2020 and 2021
GO  
