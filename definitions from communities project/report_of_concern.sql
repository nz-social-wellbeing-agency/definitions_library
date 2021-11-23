/**************************************************************************************************
Title: Repords of concern
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[cyf_clean].[cyf_intakes_event]
- [IDI_Clean].[cyf_clean].[cyf_intakes_details]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_cyf_report_of_concern]

Description:
A report of concern to CYF that meets Sec 15 criteria.

Intended purpose:
Counting number of reports of concern to children.
 
Notes:
1) Oranga Tamariki (and CYF) have several layers of events including investigations,
   and findings of abuse. Reports of Concern are the most common types of events that
   meet a formal criteria.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_cyf_report_of_concern]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_cyf_report_of_concern];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_cyf_report_of_concern] AS
SELECT a.[snz_uid]
      ,[cyf_ine_event_from_date_wid_date]
	  ,b.[cyf_ind_intake_type_code]
FROM [IDI_Clean_20200120].[cyf_clean].[cyf_intakes_event] a
INNER JOIN [IDI_Clean_20200120].[cyf_clean].[cyf_intakes_details] b
ON a.[snz_composite_event_uid] = b.[snz_composite_event_uid]
WHERE b.[cyf_ind_intake_type_code] = 'SEC15'
GO
