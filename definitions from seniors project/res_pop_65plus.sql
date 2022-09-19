/**************************************************************************************************
Title: 2013 tax year NZ residential population aged 65 and older
Author: Verity Warn

Inputs & Dependencies:
- [IDI_Clean_202203].[data].[snz_res_pop]
- [IDI_Clean_202203].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2018-48].[defn_res_pop_65plus]

Description:
List of unique snz_uids for those aged 65 or older and are part of the Stats NZ resident population.

Notes:
- Could instead input the MSD social outcomes model, check if coverage differs to NZ residential population
- EHINZ (using a StatsNZ source) reports that there were 607,000 people aged 65+ years in 2013, we record either 616,000 or 659,000 people
	(have used 616,000 definition, requiring people were part of the residential population in 2012)

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
  Study year = 2013 tax year
   
Issues:
- Identifying residents for a given year
 
History (reverse order):
2022-06-3  VW Changed birth year to correctly capture 65+ (not 66+ whoops!!)
2022-05-17 VW Modified study year and input source
2022-05-05 VW Created definition

**************************************************************************************************/
/* Establish database for writing views */
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_res_pop_65plus];
GO

CREATE VIEW [DL-MAA2018-48].[defn_res_pop_65plus] AS
SELECT DISTINCT [snz_uid]
				,[snz_birth_year_nbr]
FROM [IDI_Clean_202203].[data].[personal_detail] AS a
WHERE EXISTS ( 
			SELECT 1
			FROM [IDI_Clean_202203].[data].[snz_res_pop] AS b
			WHERE a.snz_uid = b.snz_uid
			AND YEAR(srp_ref_date) = 2012 -- was or became resident in 2012 (start of the 2013 tax year)   
		)
AND [snz_birth_year_nbr] <= 1947 -- 65 or older in 2012 (start of tax year) means born no later than 1947
AND ([snz_deceased_year_nbr] > 2012 OR [snz_deceased_year_nbr] IS NULL) -- alive in 2012 i.e. start of 2013 tax year
GO
