/**************************************************************************************************
Title: Mother's age at first birth
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[maternity_mother]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_first_birth]

Description:
Mother's age at the time of their first birth.
Excludes still births.

Intended purpose:
Identifying when a woman first became a mother.
Determining a women's age at first (live) birth.
 
Notes:
1) Only year and month of birth are available in the IDI. Day of birth is considered
   identifying. Hence all births happen on the 15th of the month.
2) Only births observed in New Zealand are recorded. Mothers who have children outside
   New Zealand (e.g. migrants) will not appear.

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
IF OBJECT_ID('[DL-MAA2016-15].[defn_first_birth]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_first_birth];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_first_birth] AS
SELECT snz_uid
	,MIN([event_date]) AS [event_date]
	,MIN(moh_matm_mother_age_nbr) AS moh_matm_mother_age_nbr
FROM (
	SELECT snz_uid
		   ,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) as [event_date]
		   ,moh_matm_mother_age_nbr
	FROM [IDI_Clean_20200120].[moh_clean].[maternity_mother]
	WHERE [moh_matm_live_births_count_nbr] IN ('1','2','3','4') --must be a live birth
) k
GROUP BY snz_uid;
GO



