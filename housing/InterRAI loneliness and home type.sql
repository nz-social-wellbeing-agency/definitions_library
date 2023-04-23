/**************************************************************************************************
Title: InterRAI home type and loneliness 
Author: Penny Mok
Reviewer: Manjusha Radhakrishnan

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
Latest loneliness indicator and residencial type for a person who had InterRAI assessment between two dates.

Intended purpose:
Loneliness indicator (0/1) for those who had InterRAI assessment in 1 Apr 2017-31 Mar 2018 (2018 tax year)
Also location indicator - whether live at home, in ARC (aged residential care) or other (hospital/PC facility). Same time period as above.

Inputs & Dependencies:
- [IDI_Clean_YYYYMM].[moh_clean].[interrai]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_interrai_loneliness]


Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
History (reverse order):
2022-07-15 MR QA
2022-07-13 VW Cast loneliness indicator as INT
2022-07-12 VW Formatting, Sandpit table created, change to use WITH query instead of temporary tables
2022-07-11 PM Definition creation  
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_interrai_loneliness];
GO

WITH info AS (
select	[snz_uid]
		,[moh_irai_assessment_date] AS date
		,CAST([moh_irai_lonely_ind] AS INTEGER) AS lonely
		,[moh_irai_location_text]
		,CASE 
			WHEN [moh_irai_location_text] = 'HOME' THEN 'home' 
			WHEN [moh_irai_location_text] = 'ARC FACILITY' THEN 'ARC'
			ELSE 'other' -- other = hospital
		 END AS location		
FROM [IDI_Clean_YYYYMM].[moh_clean].[interrai]
WHERE [moh_irai_assessment_date] BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD' -- enter the start date and end date for the assessment 
AND [moh_irai_lonely_ind] IS NOT NULL
),

most_recent AS (
SELECT snz_uid
	,MAX(date) AS most_recent_date -- several duplicates for individual, get the latest date 
FROM info
GROUP BY snz_uid
)

SELECT DISTINCT b.snz_uid
	,a.lonely
	,a.date as most_recent_date
	,a.location -- home, ARC, or other
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_interrai_loneliness]
FROM info AS a
	,most_recent AS b
WHERE a.snz_uid = b.snz_uid
AND a.date = b.most_recent_date

