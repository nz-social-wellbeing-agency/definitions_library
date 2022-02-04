/**************************************************************************************************
Title: Wellbeing GSS 2018
Author: Simon Anastasiadis
Re-edite: Freya Li  
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[gss_clean].[gss_person]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_gss2018]

Description:
Summary of health and wellbeing questions from GSS 2018.

Intended purpose:
Provide indicators of general/overall wellbeing, health and material wellbeing.
  
Notes:
1) Output values for survey questions are response codes. These include non-response codes
   such as Don't Know, Refused to answer, Response Unidentifiable, and Response Out of Scope.
   Non-response codes have not been filtered out in this definition.
2) This definition is applicable to GSS 2018. Due to changes between GSS waves, care is advised
   when combining across waves that the questions are equivalent, and that the response scales
   are coded the same way.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2021-02-02 FL V3 Updated to gss 2018
2021-01-26 SA QA
2021-01-08 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 MP QA
2020-03-02 SA v1
**************************************************************************************************/
/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
/* GSS 2018 variables - health and financial hardship */
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_gss2018]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_gss2018];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_gss2018] AS
SELECT [snz_uid]
	  ,[gss_pq_PQinterview_date] AS [event_date]
      ,CAST([gss_pq_feel_life_code] AS NUMERIC) AS [life_satisfaction]
      ,CAST([gss_pq_life_worthwhile_code] AS NUMERIC) AS [life_worthwhile]
      --,CAST([gss_pq_ment_health_code] AS NUMERIC) AS [SF12_mental_health]
	  ,CAST([gss_pq_health_dvwho5_code] AS NUMERIC) AS [WHO5_mental_wellbeing]
      --,CAST([gss_pq_phys_health_code] AS NUMERIC) AS [SF12_physical_health]
      ,CAST([gss_pq_item_300_limit_code] AS NUMERIC) AS [gss_pq_item_300_limit_code]
      ,CAST([gss_pq_not_pay_bills_time_code] AS NUMERIC) AS [gss_pq_not_pay_bills_time_code]
      ,CAST([gss_pq_enough_inc_code] AS NUMERIC) AS [gss_pq_enough_inc_code]
      ,CAST([gss_pq_material_wellbeing_code] AS NUMERIC) AS [material_wellbeing_index]
	  ,CAST([gss_pq_fam_wellbeing_code] AS NUMERIC) AS [family_wellbeing]
FROM [IDI_Clean_20201020].[gss_clean].[gss_person]
WHERE [gss_pq_collection_code] = 'GSS2018';
GO




