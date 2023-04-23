/**************************************************************************************************
Title: Mother's age at first birth
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
Mother's age at the time of their first birth. Excludes still births.

Intended purpose:
Identifying when a woman first became a mother.
Determining a women's age at first (live) birth.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[maternity_mother]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_first_birth]

Notes:
1) Only year and month of birth are available in the IDI. Day of birth is considered
   identifying. Hence all births happen on the 15th of the month.
2) Only births observed in New Zealand are recorded. Mothers who have children outside
   New Zealand (e.g. migrants) will not appear.

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
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_first_birth];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_first_birth] AS
SELECT snz_uid
	,MIN([event_date]) AS [event_date]
	,MIN(moh_matm_mother_age_nbr) AS moh_matm_mother_age_nbr
FROM (
	SELECT snz_uid
		   ,DATEFROMPARTS([moh_matm_delivery_year_nbr], [moh_matm_delivery_month_nbr], 15) as [event_date]
		   ,moh_matm_mother_age_nbr
	FROM [IDI_Clean_YYYYMM].[moh_clean].[maternity_mother]
	WHERE [moh_matm_live_births_count_nbr] IN ('1','2','3','4') --must be a live birth
) k
GROUP BY snz_uid;
GO



