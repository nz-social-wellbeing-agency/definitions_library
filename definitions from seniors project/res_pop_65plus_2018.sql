/**************************************************************************************************
Title: 2013 tax year NZ residential population aged 65 and older
Author: Verity Warn
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[data].[snz_res_pop]
- [IDI_Clean_202203].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2018-48].[defn_res_pop_65plus_2018]

Description:
List of unique snz_uids for those aged 65 or older and are part of the Stats NZ resident population.

Notes:
EHINZ reports that there were 715,200 people aged 65 and older in 2018, this definition picks up 692,000

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
  Study year = 2018 tax year
   
Issues:
- Identifying residents for a given year
 
History (reverse order):
2022-07-06 VW Exclude those who turn 65 during study period
2022-06-16 VW Created a new version for 65+ in 2018 tax year
2022-06-03 VW Changed birth year to correctly capture 65+ (not 66+ whoops!!)
2022-05-17 VW Modified study year and input source
2022-05-05 VW Created definition

**************************************************************************************************/
/* Establish database for writing views */
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_res_pop_65plus_2018];
GO

CREATE VIEW [DL-MAA2018-48].[defn_res_pop_65plus_2018] AS
SELECT DISTINCT [snz_uid]
				,[snz_birth_year_nbr]
FROM [IDI_Clean_202203].[data].[personal_detail] AS a
WHERE EXISTS ( 
			SELECT 1
			FROM [IDI_Clean_202203].[data].[snz_res_pop] AS b
			WHERE a.snz_uid = b.snz_uid
			AND YEAR(srp_ref_date) = 2017 -- was or became resident in 2017 (start of the 2018 tax year)   
		)
AND ([snz_birth_year_nbr] < 1952 -- over 65 in 2017 (start of 2018 tax year) means born earlier than 1952
		OR ([snz_birth_year_nbr] = 1952 AND [snz_birth_month_nbr] < 4)) -- turned 65 in 2017 but before study period begins in April 
AND ([snz_deceased_year_nbr] > 2017 OR [snz_deceased_year_nbr] IS NULL) -- alive in 2017 i.e. start of 2018 tax year
GO


