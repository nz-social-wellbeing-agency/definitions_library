/**************************************************************************************************
Title: PHO enrolment
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_pho_enrollment_2021]

Description:
Enrolment with Primary Health Organisation (PHO).

Intended purpose:
Create variable reporting pho enrolment by month of enrolment pho_enrolment =(0/1)
based on monthly enrolment

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  Snapshot month = '20210101'
 
Issues:

History (reverse order):
2021-11-25 SA tidy
2021-10-12 CW
**************************************************************************************************/

/* remove */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_pho_enrollment_2021];
GO

/* create */
SELECT b.snz_uid
	,a.[snz_moh_uid]
	,CAST([moh_nes_snapshot_month_date] AS DATE) AS enrollment_date
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_pho_enrollment_2021]
FROM [IDI_Clean_20211020].[moh_clean].[nes_enrolment] AS a
	,[IDI_Clean_20211020].[moh_clean].[pop_cohort_demographics] as b
WHERE a.snz_moh_uid = b.snz_moh_uid
AND [moh_nes_snapshot_month_date] >= '20210101'

/* index */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_pho_enrollment_2021] (snz_uid)
