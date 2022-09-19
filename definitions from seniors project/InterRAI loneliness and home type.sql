/**************************************************************************************************
Title: InterRAI loneliness & home type
Author: Penny Mok
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[moh_clean].[interrai]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_interrai_loneliness]

Description:
Loneliness indicator (0/1) for those who had InterRAI assessment in 1 Apr 2017-31 Mar 2018 (2018 tax year)
Also location indicator - whether live at home, in ARC (aged residential care) or other (hospital/PC facility). Same time period as above.

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
History (reverse order):
2022-07-15 MR QA
2022-07-13 VW Cast loneliness indicator as INT
2022-07-12 VW Formatting, Sandpit table created, change to use WITH query instead of temporary tables
2022-07-11 PM Definition creation  
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_interrai_loneliness];
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
FROM [IDI_Clean_202203].[moh_clean].[interrai]
WHERE [moh_irai_assessment_date] BETWEEN '2017-04-01' AND '2018-03-31' 
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
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_interrai_loneliness]
FROM info AS a
	,most_recent AS b
WHERE a.snz_uid = b.snz_uid
AND a.date = b.most_recent_date

