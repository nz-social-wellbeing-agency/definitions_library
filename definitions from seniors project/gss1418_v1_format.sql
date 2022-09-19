/**************************************************************************************************
Title: GSS 2014 - 2018
Author: Penny Mok
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[gss_clean].[gss_person]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_gss1418]

Description:
Indicators from GSS 2014-2018 for MSD vulnerable seniors project
 
Notes:
 - null = don't know/refused answer 
 - '-1' means bad, 0 = neutral, 1 = good
 - GSS_person refers to questions asked to a reference person in a household and contains info on wellbeing/life satisfaction 
 - Around 26,000 rows for 3 GSS years
 - Start and end dates created to match panel population year definition (tax year april - march) 

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
Issues:
- VW needs to add in documentation from Penny's data dictionary

History (reverse order):
2022-07-15 VW Update mould definition (to 0/1 - has major mould problem = 1)
2022-06-17 VW Writing documentation, formatting, creating dates, dropping unused indicators (see v1 of definition for these)
2022-05-31 PM Definition creation
**************************************************************************************************/


/* Get all relevant indicators from GSS14-18 */

DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_gss1418]
SELECT [snz_uid]
	  ,[gss_pq_collection_code] as gss_year
	  ,DATEFROMPARTS(RIGHT([gss_pq_collection_code], 4) - 1, 04, 01) AS start_date
	  ,DATEFROMPARTS(RIGHT([gss_pq_collection_code], 4), 03, 31) AS end_date
	  ,LFS = case -- labour force status
		when gss_pq_lfs_dev =1 then 1 
		when gss_pq_lfs_dev =2 or gss_pq_lfs_dev =3  then 0
		else NULL 
	   end
	/* Matching categories whose answer number coding changed between GSSs */
	  ,fam_type = case gss_pq_fam_type_code 
		when '10' then '11'
		when '40' then '41' 
		else gss_pq_fam_type_code 
	  end 
      ,ownership = case 
		when gss_pq_HH_tenure_code between 10 and 12 then 1 -- own (inc. with mortgage)
		when gss_pq_HH_tenure_code between 30 and 32 or gss_pq_HH_tenure_code between 20 and 22 then 0 -- not own (inc. family trust)
		else NULL 
	  end
	  ,rent = case 
		when gss_pq_HH_tenure_code between 20 and 21 then 1
		when gss_pq_HH_tenure_code between 10 and 11 or gss_pq_HH_tenure_code between 30 and 31 then 2 
		when gss_pq_HH_tenure_code =12 or gss_pq_HH_tenure_code= 22 or gss_pq_HH_tenure_code= 32 then 3 
		else NULL 
	  end 
	  ,mortgage_rent = case 
	  when gss_pq_HH_tenure_code IN (11, 31) then 'mortgage'
	  when gss_pq_HH_tenure_code IN (10, 12, 20, 22, 30, 32) then 'no mortgage/rent' -- own/trust and mortgage payments not made/not further defined
	  when gss_pq_HH_tenure_code = 21 then 'rent'
	  else NULL end -- use NULL for R handling later
	  ,[gss_pq_HH_comp_code] as hhcomp
      ,crowd = case 
		when gss_pq_HH_crowd_code between 1 and 2 then -1
		when gss_pq_HH_crowd_code =3 then 0
		when gss_pq_HH_crowd_code between 4 and 5 then 1 
		else NULL 
	  end
      ,life_satisf = case 
		when gss_pq_feel_life_code between 0 and 6 then -1
		when gss_pq_feel_life_code between 7 and 8 then 0
		when gss_pq_feel_life_code between 9 and 10 then 1
		else NULL 
	  end 
      ,life_worthw = case 
		when gss_pq_life_worthwhile_code between 0 and 6 then -1
		when gss_pq_life_worthwhile_code between 7 and 8  then 0
		when gss_pq_life_worthwhile_code between 9 and 10 then 1
		else NULL 
	  end 
      ,health_cond = case 
		when gss_pq_health_excel_poor_code =15 then -1
		when gss_pq_health_excel_poor_code between 13 and 14 then 0
		when gss_pq_health_excel_poor_code between 11 and 12 then 1
		else NULL 
	  end
      ,limit_act = case 
		when gss_pq_health_limits_activ_code =11 then -1
		when gss_pq_health_limits_activ_code =12 then 0
		when gss_pq_health_limits_activ_code =13 then 1
		else NULL 
	  end
	  ,limit_stair = case 
		when gss_pq_health_limits_stairs_code =11 then -1
		when gss_pq_health_limits_stairs_code =12 then 0
		when gss_pq_health_limits_stairs_code=13 then 1
		else NULL 
	  end	  
      ,depress = case 
		when gss_pq_felt_depressed_code between 11 and 12 then -1
		when gss_pq_felt_depressed_code between 13 and 14 then 0
		when gss_pq_felt_depressed_code=15 then 1
		else NULL 
	  end	  
	  ,interf_soc = case 
		when gss_pq_health_interfere_soc_code between 11 and 12 then -1
		when gss_pq_health_interfere_soc_code  between 13 and 14 then 0
		when gss_pq_health_interfere_soc_code=15 then 1
		else NULL 
	  end
	  ,menthealth = case 
		when gss_pq_ment_health_code between 0 and 36 then -1
		when gss_pq_ment_health_code between 37 and 53 then 0
		when gss_pq_ment_health_code>= 54 then 1 
		else NULL 
	  end
	  ,physhealth = case 
		when gss_pq_phys_health_code between 0 and 36 then -1
		when gss_pq_phys_health_code between 37 and 53 then 0
		when gss_pq_phys_health_code>= 54 then 1 
		else NULL 
	  end
	  ,cul_iden = case 
		when gss_pq_cult_identity_code between 11 and 12 then 1
		when gss_pq_cult_identity_code =13 then 0 
		when gss_pq_cult_identity_code between 14 and 15 then -1
		else NULL 
	  end
	  ,trust = case 
		when gss_pq_trust_most_code between 0 and 4 then -1
		when gss_pq_trust_most_code between 5 and 6 then 0
		when gss_pq_trust_most_code between 7 and 10 then 1
		else NULL 
	  end 
	  ,health_trust = case 
		when gss_pq_trust_health_code between 0 and 4 then -1
		when gss_pq_trust_health_code between 5 and 6 then 0
		when gss_pq_trust_health_code between 7 and 10 then 1
		else NULL 
	  end 
     ,eno_inc = case 
		when gss_pq_enough_inc_code=11 then -1
		when gss_pq_enough_inc_code=12 then 0
		when gss_pq_enough_inc_code between 13 and 14 then 1
		else NULL 
	 end
	 ,mwi9 = case 
		when gss_pq_material_wellbeing_code between 0 and 7 then -1
		when gss_pq_material_wellbeing_code between 8 and 17 then 0
		when gss_pq_material_wellbeing_code between 18 and 20 then 1
		else NULL 
	 end
	 ,hse_cond = case 
		when gss_pq_house_condition_code between 14 and 15 then -1
		when gss_pq_house_condition_code =13 then 0
		when gss_pq_house_condition_code between 11 and 12 then 1
		else NULL 
	 end 
	 ,mould = case --gss_pq_house_mold_code for 2014, 16 and gss_pq_cdm_house_mould_code for 2018 
		when gss_pq_house_mold_code = 13 or gss_pq_cdm_house_mould_code = 1 then 1 -- major mould problem
		when gss_pq_house_mold_code=11 or gss_pq_cdm_house_mould_code=2 or gss_pq_house_mold_code=12 then 0	-- no or minor mould problem
		else NULL 
	 end	 
	 ,disc = case 
		when gss_pq_discriminated_code=1 then -1
		when gss_pq_discriminated_code=2 then 0
		else NULL 
	 end 
	  ,lonely = case 
		when gss_pq_time_lonely_code IN (14, 15) then 1
		when gss_pq_time_lonely_code IN (11, 12, 13) then 0
		else NULL 
	  end 
	  --,gss_pq_time_lonely_code
	  ,partner= case 
		when gss_pq_mar_stat_code=1 then 1
		when gss_pq_mar_stat_code=2 then 0 --single
		else NULL 
	  end
      ,alone = case   --live alone & hh_no only 2014-2016
		when gss_pq_resp_live_alone_ind =1 then 1
		when gss_pq_resp_live_alone_ind=2 then 0
		else NULL 
	  end
	  ,hh_no = case 
		when gss_pq_people_house_nbr is not null then  gss_pq_people_house_nbr 
		else NULL 
	  end
      ,gss_pq_person_FinalWgt_nbr
      ,fam_wb = case   -- family wellbeing only 2018
		when gss_pq_fam_wellbeing_code between 0 and 6 then -1
		when gss_pq_fam_wellbeing_code between 7 and 8 then 0
		when gss_pq_fam_wellbeing_code between 9 and 10 then 1
		when gss_pq_fam_wellbeing_code=11 then 2 --no family
		else NULL 
	  end
	  ,hhcom = case when gss_pq_HH_comp_code between 11 and 12 then 'couple' 
		when gss_pq_HH_comp_code between 13 and 14 then 'couple with children' 
		when gss_pq_HH_comp_code between 15 and 16 then 'single parent' 
		when gss_pq_HH_comp_code =51 then 'single' 
		when gss_pq_HH_comp_code=61 then NULL
		else 'other'
	  end
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_gss1418]
FROM [IDI_Clean_202203].[gss_clean].[gss_person]


-- select top 100 * from [IDI_Sandpit].[DL-MAA2018-48].[defn_gss1418]
