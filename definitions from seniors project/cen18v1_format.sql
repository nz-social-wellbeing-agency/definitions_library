/**************************************************************************************************
Title: Census 2018 individual details
Author: Penny Mok
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2021-60].[defn_cen18v1]

Intended purpose:
To obtain individual characteristics from the 2018 Census:
	- owner (home ownership)
	- interact (unpaid activities)
	- alone1 (live alone)
	- cur_rltp (partnered status)

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Issues:
 
History (reverse order):
2022-07-06 MR Remove resident population join
2022-07-06 VW Remove unused parts of code in preperation for QA
2022-07-04 VW Format, use a user code table to store for use with data assembly tool 
2022-06-22 PM Definition creation for MSD seniors project
**************************************************************************************************/
/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_cen18v1];
GO

CREATE VIEW [DL-MAA2018-48].[defn_cen18v1] AS (
SELECT [snz_uid] 
      ,owner= case when [cen_ind_home_ownsp_code] =2 then 1 
	  when [cen_ind_home_ownsp_code]=1 or [cen_ind_home_ownsp_code]=3 then 0 
	  else NULL end 
	  ,interact=case when (cen_ind_unpaid_activities_code) like '%06%'then 2 --volunteer
	  when (cen_ind_unpaid_activities_code) like '%02%' or (cen_ind_unpaid_activities_code) like '%03%'or (cen_ind_unpaid_activities_code) like '%04%'or (cen_ind_unpaid_activities_code) like '%05%'then 1 --family interact
	  when substring(cen_ind_unpaid_activities_code,1,2)= 00 or substring(cen_ind_unpaid_activities_code,1,2)=01 then 0 --no interaction 
	  else NULL end
	   ,alone1=case when (cen_ind_living_arrangmnts_code) like '%0111%' then 1 --live alone
	   when substring(cen_ind_living_arrangmnts_code,1,4) between 7777 and 9999 or cen_ind_living_arrangmnts_code is null then NULL
	   else 0 end 	        
      ,cur_rltp= case when [cen_ind_social_mrit_stus_recode] between 10 and 13 then 1 --partnered
	  when [cen_ind_social_mrit_stus_recode] between 20 and 25 then 0 --not partnered
	  else NULL end
  FROM [IDI_Clean_202203].[cen_clean].[census_individual_2018]
)
GO

