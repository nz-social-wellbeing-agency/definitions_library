/**************************************************************************************************
Title: Recent OT placements
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
Indicator of recent Oranga Tamariki placements for children.

Intended purpose:
Identifying whether children have recently been in a placement arranged by Oranga Tamariki.

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_OT_placement]

Notes:

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

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_OT_placement]
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_OT_placement] AS
SELECT DISTINCT [snz_uid]
      ,[snz_msd_uid]
      ,1 as type
FROM [IDI_Clean_YYYYMM].[cyf_clean].[cyf_placements_event]
WHERE [cyf_ple_event_to_date_wid_date] >= '2021-07-01'
GO
