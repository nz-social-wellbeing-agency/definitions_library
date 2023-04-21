/**************************************************************************************************
Title: Number of reports of concern to children
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
Counting number of reports of concern to children that meets Sec 15 criteria.

Intended purpose:
Counting number of reports of concern to children.
 
Inputs & Dependencies:
- [IDI_Clean].[cyf_clean].[cyf_intakes_event]
- [IDI_Clean].[cyf_clean].[cyf_intakes_details]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_cyf_report_of_concern]


Notes:
1) Oranga Tamariki (and CYF) have several layers of events including investigations,
   and findings of abuse. Reports of Concern are the most common types of events that
   meet a formal criteria.

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
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_cyf_report_of_concern];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_cyf_report_of_concern] AS
SELECT a.[snz_uid]
      ,[cyf_ine_event_from_date_wid_date]
	  ,b.[cyf_ind_intake_type_code]
FROM [IDI_Clean_YYYYMM].[cyf_clean].[cyf_intakes_event] a
INNER JOIN [IDI_Clean_YYYYMM].[cyf_clean].[cyf_intakes_details] b
ON a.[snz_composite_event_uid] = b.[snz_composite_event_uid]
WHERE b.[cyf_ind_intake_type_code] = 'SEC15'
GO
