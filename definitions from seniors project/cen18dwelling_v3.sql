/**************************************************************************************************
Title: Census 2018 dwelling info
Author: Penny Mok
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[cen_clean].[census_dwelling_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2021-60].[defn_cen18_dwelling]

Intended purpose:
This is to get proxy for house condition for Seniors using Census 2018

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Issues:
 
History (reverse order):
2022-07-14 VW Add in household composition
2022-07-04 VW Format, use a user code table to store for use with data assembly tool, drop unsued code,
				re-work amenities definition to classify all missing >= 1/7 amenities as 0.
2022-06-23 PM Definition creation for MSD seniors project
**************************************************************************************************/
/* Set database for writing views */
USE IDI_UserCode;
GO

/* Clear existing view */
DROP VIEW [DL-MAA2018-48].[defn_cen18_dwelling];
GO

/* Create view */
CREATE VIEW [DL-MAA2018-48].[defn_cen18_dwelling] AS (
SELECT snz_uid
      ,a.[snz_cen_dwell_uid]
	  ,[snz_idi_address_register_uid]
	  ,heat= case 
	  when [cen_dwl_heating_app_code] like '%00%' then 0 --no heating
	  when [cen_dwl_heating_app_code] like '%77%' or [cen_dwl_heating_app_code] like '%88%' or [cen_dwl_heating_app_code] like '%99%' then NULL
	  else 1 end 
	  ,cen_dwl_heating_app_code
	  ,occupy= case 
	  when [cen_dwl_dwell_stus_code]=11 then 1 --occupied
	  when [cen_dwl_dwell_stus_code] between 21 and 31 then 0 --non occupant
	  else NULL end
      ,private= case 
	  when [cen_dwl_record_type_code]=1 then 1 --private
	  when [cen_dwl_record_type_code] =2 then 0 --non private
	  else NULL end
	  ,own = case
	  when [cen_dwl_tenure_code] between 10 and 12 then 1 --own (inc. with mortgage)
	  when [cen_dwl_tenure_code] between 20 and 22 or [cen_dwl_tenure_code] between 30 and 32 then 0 --not own (inc. family trust)
	  else NULL end
      ,mortgage_rent = case 
	  when [cen_dwl_tenure_code] IN (11, 31) then 'mortgage'
	  when [cen_dwl_tenure_code] IN (10, 12, 20, 22, 30, 32) then 'no mortgage/rent' -- own/trust and mortgage payments not made/not further defined
	  when [cen_dwl_tenure_code] = 21 then 'rent'
	  else NULL end -- use NULL for R handling later
      ,amenity= case 
	  when [cen_dwl_amenities_code] = '01;02;03;04;05;06;07' then 1 -- have all basic amenity e.g. shower, cooking, toilet,...
	  when [cen_dwl_amenities_code] IN ('77','99','NULL') then NULL
	  else 0 end 
	   ,miss_amen= case 
	  when [cen_dwl_amenity_cnt_code] between 0 and 6 then 1 -- missing at least 1 
	  when [cen_dwl_amenity_cnt_code] IN (77, 99) then NULL
	  else 0 end 
      ,damp= case 
	  when [cen_dwl_damp_code] between 1 and 2 then 1 --yes
	  when [cen_dwl_damp_code]=3 then 0 --no
	  else NULL end
      ,mould= case 
	  when [cen_dwl_mould_code] between 1 and 2 then 1--yes
	  when [cen_dwl_mould_code]=3 then 0 
	  else NULL end 
      ,motor= case 
	  when [cen_dwl_motor_vehicle_cnt_code]=00 then 0 --no
	  when [cen_dwl_motor_vehicle_cnt_code] between 01 and 05 then 1 --yes
	  else NULL end 
	  ,hhld_composition = case
		when [cen_hhd_composn_code] IN (111,121,122) then 'couple'
		when [cen_hhd_composn_code] IN (131,141,142) then 'couple with children'
		when [cen_hhd_composn_code] IN (151,161,162) then 'single parent'
		when [cen_hhd_composn_code] IN (511) then 'single'
		when [cen_hhd_composn_code] = 611 then NULL
		else 'other' end
		, crowding= case
		when [cen_hhd_can_crowding_code] IN (1,2) then 1 --overcrowd
		when [cen_hhd_can_crowding_code] between 3 and 5 then 0 --no
		else NULL end

FROM [IDI_Clean_202203].[cen_clean].[census_dwelling_2018] a
INNER JOIN [IDI_Clean_202203].[cen_clean].[census_household_2018] b
ON a.snz_cen_dwell_uid=b.snz_cen_dwell_uid
INNER JOIN [IDI_Clean_202203].[cen_clean].[census_individual_2018] c 
ON b.snz_cen_hhld_uid=c.snz_cen_hhld_uid
) 
GO


--select count(distinct snz_uid) from [IDI_UserCode].[DL-MAA2018-48].[defn_cen18_dwelling]



