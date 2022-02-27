/**************************************************************************************************
Title: Recent OT placements
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_OT_placement]

Description:
Indicator of recent Oranga Tamariki placements for children.

Intended purpose:
Identifying whether children have recently been in a placement
arranged by Oranga Tamariki.

Notes:

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

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_OT_placement]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_OT_placement] AS
SELECT DISTINCT [snz_uid]
      ,[snz_msd_uid]
	  ,1 as type
      --,[cyf_ple_event_type_wid_nbr]
      --,[snz_composite_event_uid]
      --,[snz_systm_prsn_uid]
      --,[cyf_ple_source_uk_var1_text]
      --,[cyf_ple_source_uk_var2_text]
      --,[cyf_ple_source_uk_var3_text]
      --,[cyf_ple_source_uk_var4_text]
      --,[cyf_ple_event_from_datetime]
      --,[cyf_ple_event_to_datetime]
      --,[cyf_ple_event_from_date_wid_date]
      --,[cyf_ple_event_to_date_wid_date]
      --,[cyf_ple_number_of_days_nbr]
      --,[cyf_ple_direct_daily_nett_amt]
      --,[cyf_ple_direct_daily_gross_amt]
      --,[cyf_ple_indirect_daily_nett_amt]
      --,[cyf_ple_indirect_daily_gross_amt]
      --,[cyf_ple_count_nbr]
      --,[cyf_ple_extracted_datetime]
FROM [IDI_Clean_20211020].[cyf_clean].[cyf_placements_event]
WHERE [cyf_ple_event_to_date_wid_date] >= '2021-07-01'
GO
