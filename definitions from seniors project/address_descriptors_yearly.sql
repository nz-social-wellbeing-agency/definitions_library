/**************************************************************************************************
Title: Neighbourhood descriptors
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
- [IDI_Clean].[data].[snz_res_pop]
- [IDI_Clean].[data].[address_notification]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_higher_geography_2020_V1_00]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[DepIndex2013]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly]

Description:
Summary description of a person's neighbourhood including: region,
deprivation, urban/rural, and whether a person lives in a household
with dependent children.

Intended purpose:
Identifying the region, urban/rural-ness, and other characteristics of where a person lives
at a specific point in time.

Notes:
1) Address information in the IDI is not of sufficient quality to determine who shares an
   address. We would also be cautious about claiming that a person lives at a specific
   address on a specific date. However, we are confident using address information for the
   purpose of "this location has the characteristics of the place this person lives", and
   "this person has the characteristics of the people who live in this location".
2) Despite the limitations of address, it is the best source for determining whether a person
   lives in a household with dependent children. Hence we use it for this purpose. However
   we note that this is a low quality measure.
3) The year of the meshblock codes used for the address notification could not be found in
   data documentation. A quality of range of different years/joins were tried the final
   choice represents the best join available at time of creation.
   Another cause for this join being imperfect is not every meshblock contains residential
   addresses (e.g. some CBD areas may contain hotels but not residential addresses, and
   some meshblocks are uninhabited - such as mountains or ocean areas).
   Re-assessment of which meshblock code to use for joining to address_notifications
   is recommended each refresh.
4) This version extends the previous single-date-snapshot to a yearly single-date-snapshot. For
   example to identify someones address each year from 2013-2016, this code can produce address as at
   2013-03-31, 2014-03-31, 2015-03-31, and 2016-03-31 [i.e. YYYY-03-31 format]. 
   This is achieved by 'trimming' the [ant_notification_date] (address start date) and [ant_replacement_date] 
   (address end date) to an appopriate YYYY-03-31 date. 
   
   The logic stems from the following:

	- A constructed (03/31) start date and constructed (03/31) end date pair MUST fall inside the spell:
   		1. Either YYYY-03-31 or [YYYY+1]-03-31 (the two possible trimmed start dates) should occur within the address spell.
			We go forward as it is possible that the spell starts at the end of one year (not overlapping with this year's 03-31) and spills into the 
			next year's 03-31, meaning the address should be attributed to the following year's 03-31 and a different spell will be used for this year's 03-31. 
			For example, an adddress 1 Lambton Quay starting in November 2021 and continuing to May 2022. The start date 2021-03-31 does not fall inside the spell but 
			a 2022-03-31 start date does, so the 2022-03-31 address is 1 Lambton Quay (and 2021-03-31 will be another address, whose spell overlaps with 2021-03-31).
			We don't go backward to the previous 03-31 as this would take us before the address spell, in which case a different address spell should be used for that 
			YYYY-03-31 address. 
		AND
		2. Either YYYY-03-31 or [YYYY-1]-03-31 (the two possible trimmed end dates) should occur within the address spell.
			We go backward as it is possible that the spell starts at the beginning of one year (overlapping this year's 03/31 start) and continues into the future, 
			to the start of a year, not quite reaching the next 03-31 date - so we shorten the spell to end at the last 03-31 date.
			For example, an address 2 Lambton Quay starting in February 2021 and continuing to January 2023. The end date 2023-03-31 does not fall inside the spell
			but a 2022-03-31 end date does, so the 2022-03-31 address is 2 Lambton Quay (and 2023-03-31 will be another address, whose spell overlaps with 2023-03-31).
			We don't go forward to the next 03-31 as this would take us after the address spell, in which case a different address spell should be used for that 
			YYYY-03-31 address. 
	
	- Given a constructed start and end date both fall within the address spell, the following determines which start and end dates are given:
	   - Start dates:
			If the YYYY-03-31 start date constructed from year(ant_notification_date) occurs within the address spell:
				trim_start is the YYYY-03-31 start date constructed from the year of the ant_notification_date 
			Else:
				trim_start is set to [YYYY+1]-03-31
	   - End dates:
	   		If the YYYY-03-31 end date constructed from year(ant_replacement_date) occurs within the address spell:
				trim_end is the YYYY-03-31 end date constructed from the year of the ant_replacement_date 
			Else:
				trim_end is set to [YYYY-1]-03-31
	
Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
  Current 'as-at' date = YYYY-03-31 -- can easily change to a different MM-DD by editing trim_start_end table (WITH statement)
   
Issues:

History (reverse order):
2022-06-07 VW    Add name of region code (using meshblock higher geography 2020)
2022-05-31 SA-VW Create version that enables a yearly snapshot of address (see note and comments)
2022-05-17 VW    Point to MSD seniors project (DL-MAA2018-48), update to latest refresh, add NZDep2018 for use with different years (will need to edit code below)
2022-02-18 VW    Point to HTR project, DL-MAA2021-60
2021-11-30 MR	(Update latest refresh, link latest meshblock higher geography)
2021-06-21 FL    repalce age of child with the birth year
2021-06-10 SA QA
2021-06-08 FL v3 Add age of child
2021-01-26 SA QA
2021-01-11 FL v2 (Change prefix, update the table to the latest refresh, update the date)
2020-07-15 MP QA
2020-03-03 SA v1
**************************************************************************************************/

/* Remove table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly];  -- rename 
GO

/* Create all possible start and end date options, centred around YYYY-03-31 */
WITH trim_start_end AS (
SELECT * 
		,DATEFROMPARTS(YEAR([ant_notification_date]), 03, 31) AS trim_start_0
		,DATEFROMPARTS(YEAR([ant_notification_date]) + 1, 03, 31) AS trim_start_1 
			-- add one so that if [ant_notification_date] (start date) falls after 03/31 of the ant_notification_date YEAR the date moves forward to 03/31 of the next year
		,DATEFROMPARTS(YEAR([ant_replacement_date]), 03, 31) AS trim_end_0
		,DATEFROMPARTS(YEAR([ant_replacement_date]) - 1, 03, 31) AS trim_end_1 
			-- subtract one so that if [ant_replacement_date] (end date) falls before 03/31 of the [ant_replacement_date] YEAR it is brought back to the previous year
FROM [IDI_Clean_202203].[data].[address_notification]
)

/* Trim start and end dates */ 
SELECT a.[snz_uid]
      ,a.[ant_notification_date]
      ,a.[ant_replacement_date]
      ,a.[snz_idi_address_register_uid]
	  ,CAST(a.[ant_region_code] AS INT) AS [ant_region_code]
	  ,b.[REGC2020_V1_00_NAME] -- name of region
	  ,b.[TA2020_V1_00] -- TA number
	  ,b.[TA2020_V1_00_NAME] -- TA name
	  ,b.[IUR2020_V1_00] -- urban/rural classification
      ,b.[IUR2020_V1_00_NAME]
	  ,CAST(b.[SA22020_V1_00] AS INT) AS [SA22020_V1_00] -- Statistical Area 2 (neighbourhood)
	  ,b.[SA22020_V1_00_NAME]
	  ,c.[DepIndex2013]
	  ,CAST(d.[NZDep2018] AS INT) AS [NZDep2018]
	  /* Choose which trimmed start and end dates to use */
	  ,IIF(trim_start_0 BETWEEN [ant_notification_date] AND [ant_replacement_date], trim_start_0, trim_start_1) AS trim_start
		-- if 03/31 of the ant_notification_date YEAR is within the address spell, start date is 03/31 of the ant_notification_date year, else start date is 03/31 of the next year
	  ,IIF(trim_end_0 BETWEEN [ant_notification_date] AND [ant_replacement_date], trim_end_0, trim_end_1) AS trim_end
		-- if 03/31 of the ant_replacement_date YEAR (i.e. trim_end_0) is within the address spell, end date is 03/31 of the current year, else end date is 03/31 of the previous year
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly]
FROM trim_start_end AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019] AS conc
ON conc.[MB2019_code] = a.[ant_meshblock_code]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_higher_geography_2020_V1_00] AS b
ON conc.[MB2019_code] = b.[MB2020_V1_00]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[DepIndex2013] AS c
ON conc.[MB2013_code] = c.[Meshblock2013]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[DepIndex2018_MB2018] AS d
ON conc.[MB2018_code] = d.[MB2018_code]
WHERE a.[ant_meshblock_code] IS NOT NULL
AND (trim_start_0 BETWEEN [ant_notification_date] AND [ant_replacement_date] OR trim_start_1 BETWEEN [ant_notification_date] AND [ant_replacement_date]) 
	-- 1 of the start dates must be valid (i.e. within the address spell)
AND (trim_end_0 BETWEEN [ant_notification_date] AND [ant_replacement_date] OR trim_end_1 BETWEEN [ant_notification_date] AND [ant_replacement_date]) 
	-- 1 of the end dates must be valid (i.e. within the address spell)


/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO


/* Comparing trimmed and actual spell durations */
--select top 1000 * 
--		,DATEDIFF(day, ant_notification_date, ant_replacement_date) as ant_datediff
--		,DATEDIFF(day, trim_start, trim_end) as trim_datediff
--from [IDI_Sandpit].[DL-MAA2018-48].[defn_address_descriptors_yearly]