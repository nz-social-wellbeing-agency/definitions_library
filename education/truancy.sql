/**************************************************************************************************
Title: Truancy interventions
Author: Simon Anastasiadis

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
MOE truancy interventions for non-attendance and non-enrollment.

Intended purpose:
Determining who has received truancy interventions.
Counting the number of truancy interventions.

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[student_interventions]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_truancy]

Notes:
1) There are a range of MOE interventions. This definition focuses on only two:
   '9' = non-enrollment truancy with the goal to get child enrolled
   '32' = non-attendance truancy with the goal to get child attending
2) Only truancy that requires an MOE intervention is recorded here.
   Schools may handle low level truancy internally. There may be differences
   in the handling/escaling of truancy to MOE between schools.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA20XX-YY].[defn_truancy]','V') IS NOT NULL
DROP VIEW [DL-MAA20XX-YY].[defn_truancy];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_truancy] AS
SELECT [snz_uid]
      ,[moe_inv_snz_unique_nbr]
      ,[moe_inv_inst_num_code]
      ,[moe_inv_intrvtn_code]
      ,[moe_inv_start_date]
      ,[moe_inv_end_date]
      ,[moe_inv_number_of_days_nbr]
      ,[moe_inv_nets_ua_status_code]
      ,[moe_inv_nets_ua_status_date]
      ,[moe_inv_nets_outcome_type_code]
      ,[moe_inv_nets_leave_reason_code]
      ,[moe_inv_nets_ua_provider_code]
FROM [IDI_Clean_YYYYMM].[moe_clean].[student_interventions]
WHERE [moe_inv_intrvtn_code] IN ('9', '32')