/**************************************************************************************************
Title: PHO enrolment
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
Enrolment with Primary Health Organisation (PHO).

Intended purpose:
Create variable reporting pho enrolment by month of enrolment pho_enrolment =(0/1)
based on monthly enrolment

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]

Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_pho_enrollment_2021]


Notes:

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
  Snapshot month = 'YYYYMMDD'
 
Issues:

History (reverse order):
2021-11-25 SA tidy
2021-10-12 CW
**************************************************************************************************/

/* remove */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_pho_enrollment_2021];
GO

/* create */
SELECT b.snz_uid
	,a.[snz_moh_uid]
	,CAST([moh_nes_snapshot_month_date] AS DATE) AS enrollment_date
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_pho_enrollment_2021]
FROM [IDI_Clean_YYYYMM].[moh_clean].[nes_enrolment] AS a
	,[IDI_Clean_YYYYMM].[moh_clean].[pop_cohort_demographics] as b
WHERE a.snz_moh_uid = b.snz_moh_uid
AND [moh_nes_snapshot_month_date] >= 'YYYYMMDD'

/* index */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_pho_enrollment_2021] (snz_uid)
