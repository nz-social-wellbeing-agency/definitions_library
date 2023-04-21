/**************************************************************************************************
Title: Wellbeing GSS 2016
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

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
Summary of health and wellbeing questions from GSS 2016.

Intended purpose:
Provide indicators of general/overall wellbeing, health and material wellbeing.

Inputs & Dependencies:
- [IDI_Clean].[gss_clean].[gss_person]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2g_gss2016]
  
Notes:
1) Output values for survey questions are response codes. These include non-response codes
   such as Don't Know, Refused to answer, Response Unidentifiable, and Response Out of Scope.
   Non-response codes have not been filtered out in this definition.
2) This definition is applicable to GSS 2016. Due to changes between GSS waves, care is advised
   when combining across waves that the questions are equivalent, and that the response scales
   are coded the same way.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2g_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2020-07-22 MP QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
/* GSS 2016 variables - health and financial hardship */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2g_gss2016];
GO

CREATE VIEW [DL-MAA20XX-YY].[d2g_gss2016] AS
SELECT [snz_uid]
	  ,[gss_pq_PQinterview_date] AS [event_date]
      ,CAST([gss_pq_feel_life_code] AS NUMERIC) AS [life_satisfaction]
      ,CAST([gss_pq_life_worthwhile_code] AS NUMERIC) AS [life_worthwhile]
      ,CAST([gss_pq_ment_health_code] AS NUMERIC) AS [SF12_mental_health]
      ,CAST([gss_pq_phys_health_code] AS NUMERIC) AS [SF12_physical_health]
      ,CAST([gss_pq_item_300_limit_code] AS NUMERIC) AS [gss_pq_item_300_limit_code]
      ,CAST([gss_pq_not_pay_bills_time_code] AS NUMERIC) AS [gss_pq_not_pay_bills_time_code]
      ,CAST([gss_pq_enough_inc_code] AS NUMERIC) AS [gss_pq_enough_inc_code]
      ,CAST([gss_pq_material_wellbeing_code] AS NUMERIC) AS [material_wellbeing_index]
FROM [IDI_Clean_YYYYMM].[gss_clean].[gss_person]
WHERE [gss_pq_collection_code] = 'GSS2016';
GO


