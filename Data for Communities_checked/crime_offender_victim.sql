/**************************************************************************************************
Title: Crime - offenders and victims
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[pol_clean].[post_count_offenders]
- [IDI_Clean].[pol_clean].[post_count_victimisations]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_crime_offender]
- [IDI_UserCode].[DL-MAA2016-15].[defn_crime_victim]

Description:
Offenders and victims of crime.

Intended purpose:
Determining who has been a victim of crime or an offender.
Counting the number of occurrence of offence or victimisation.
 
Notes:
1) Multiple charges can arise from a single occurrence.
   We use the post_count tables for both offender and victim.
   This means that only the most serious offence/charge from each
   occurrence is used.
2) Not every crime/offence has a person as its victim.
   E.g. drink driving.
   The offender for some victimisations is unknown.
   E.g. Burglary while victim was out.
   Hence the number of offenders and victims will not match.
3) Only captures reported crime to police.

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
IF OBJECT_ID('[DL-MAA2016-15].[defn_crime_offender]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_crime_offender];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_crime_offender] AS
SELECT [snz_uid]
      ,[pol_poo_occurrence_inv_ind]
      ,[pol_poo_offence_inv_ind]
      ,[pol_poo_proceeding_date]
      ,[pol_poo_offence_code]
      ,[pol_poo_proceeding_code]
      ,[snz_person_ind]
      ,[pol_poo_earliest_occ_start_date]
      ,[pol_poo_latest_poss_occ_date]
FROM [IDI_Clean_20200120].[pol_clean].[post_count_offenders]
WHERE [snz_person_ind] = 1 --offender is a person
AND snz_uid > 0 --meaningful snz_uid code
AND [pol_poo_occurrence_inv_ind] = 1 --occurrence was investigated
AND [pol_poo_proceeding_code] NOT IN ('300', '999') --exclude not proceeded with and unknown status
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_crime_victim]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_crime_victim];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_crime_victim] AS
SELECT [snz_uid]
      ,[pol_pov_occurrence_inv_ind]
      ,[pol_pov_offence_inv_ind]
      ,[pol_pov_reported_date]
      ,[pol_pov_offence_code]
      ,[pol_pov_rov_code]
      ,[snz_person_ind]
      ,[pol_pov_earliest_occ_start_date]
      ,[pol_pov_latest_poss_occ_date]
FROM [IDI_Clean_20200120].[pol_clean].[post_count_victimisations]
WHERE [snz_person_ind] = 1 --victim is a person
AND snz_uid > 0 --meaningful snz_uid code
AND [pol_pov_occurrence_inv_ind] = 1 --occurrence was investigated
GO