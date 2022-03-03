/**************************************************************************************************
Title: Family Violence
Author: Marianna Pekar 
Reviewer:

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[pol_clean].[pre_count_offenders]
- [IDI_Clean].[pol_clean].[post_count_offenders]
- [IDI_Clean].[pol_clean].[pre_count_victimisations]
- [IDI_Clean].[pol_clean].[post_count_victimisations]
- [IDI_Clean].[acc_clean].[claims]
- [IDI_Clean].[moj_clean].[charges]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_family_violence]

Description:
Family, sexual, and intimate partner violence.

Intended purpose:
Identifying people who have been exposed to Family Violence.

Notes:
1) Based on information received from Jo Fink, Ministry of Justice, Senior Analyst, Analysis and Modelling.
	Our thanks to Jo Fink for their help.
2) Much of the information that is used operationally by the Justice sector agencies for official statistics
	are not available in the IDI (e.g. Police family harm investigations, calls for service, Police Safety Orders,
	family violence flag, Protection Order applications, referral to non-violence programmes etc.).
3) Sources used (administrative):
	- Police: victimisation from July 2014 onwards, proceedings from 2009 onwards
	- NIA links: offence information
	- Justice: charges from 1992 onwards
	- ACC: sensitive claims and injury claims based on keywords - awaiting SME review
	- Oranga Tamariki: reports of concern - currently not incorporated

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-08-31 modifying parameters, MP
2020-08-05 initiated MP
**************************************************************************************************/

/* Manual loading of offence codes of interest */
DROP Table IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping] (
	[offence_code] INT,
	[offence_description] NVARCHAR(MAX)
);


INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping] ([offence_code], [offence_description])
VALUES 
	(1541,'Male Assaults Female (Firearm)'), -- not strictly FV, but more than 90% of such offences are FV (Jo Fink)
	(1542,'Male Assaults Female (Other Weapon)'), -- not strictly FV, but more than 90% of such offences are FV (Jo Fink)
	(1543,'Male Assaults Female (Manually)'), -- not strictly FV, but more than 90% of such offences are FV (Jo Fink)
	(1544,'Male Assaults Female (Stabbing/Cutting Weapon)'), -- not strictly FV, but more than 90% of such offences are FV (Jo Fink)
	(1545,'Assault on person in family relationship'),
	(1581,'Common Assault(Domestic)Crimes Act(Firearm)'),
	(1582,'Common Assault(Domestic)Crimes Act(Other Weapon)'),
	(1583,'Common Assault(Domestic)Crimes Act(Manually)'),
	(1587,'Common Assault (Domestic) (Stabbing/Cutting Weapon)'),
	(1641,'Common Assault (Domestic) (Firearm)'),
	(1642,'Common Assault (Domestic) (Other Weapon)'),
	(1643,'Common Assault (Domestic) (Manually)'),
	(1647,'Common Assault (Domestic) (Stabbing/Cutting Weapon)'),
	(2153,'Husband Rapes Wife (With Weapon)'),
	(2154,'Husband Rapes Wife (No Weapon)'),
	(2157,'Unlawful Sexual Connection With Spouse (Weapon)'),
	(2158,'Unlawful Sexual Connection With Spouse (No Weapon)'),
	(2163,'Attempts Sexual Violation Spouse (Weapon)'),
	(2164,'Attempts Sexual Violation Spouse (No Weapon)'),
	(2167,'Assaults W Intent T Commit Sexual Violation Spouse (Weapon)'),
	(2168,'Assaults Intent Commit Sexual Violation Spouse (No Weapon)'),
	(2311,'Father Incest Daughter'),
	(2312,'Brother Incest Sister'),
	(2313,'Other Incest Other Relative'),
	(2319,'Other Incest'),
	(2654,'Husband Rapes Wife'),
	(2658,'Unlawful Sexual Connection With Spouse'),
	(2664,'Attempt To Rape Spouse'),
	(2668,'Attempted Unlawful Sexual Connection Spouse'),
	(2674,'Assault With Intent To Commit Rape Spouse'),
	(2678,'Assault Intent Commit Sex Connect-Spouse'),
	(2711,'Parent Incest Child Under 12'),
	(2712,'Parent Incest Child 12-16'),
	(2713,'Parent Incest Child Over 16'),
	(2714,'Brother Incest Sister Under 12'),
	(2715,'Brother Incest Sister 12-16'),
	(2716,'Brother Incest Sister Over 16'),
	(2719,'Other Incest'),
	(2731,'Sexual Connection Dependent Family Member'),
	(2732,'Attempt Sex Connection Dependent Family Member'),
	(2733,'Indecent Act On Dependent Family Member'),
	(3851,'Contravenes Protection Order (Firearm)'),
	(3852,'Contravenes Protection Order (No Firearm)'),
	(3853,'Fails To Comply With Conditions Of Order (Firearm)'),
	(3854,'Fails To Comply With Conditions Of Order (No Firearm)'),
	(3855,'Fails To Attend Program'),
	(3856,'Breach Publications Restrictions'),
	(3858,'Detention by Constable - Failure or Refusal to Remain'),
	(3859,'Other Breaches Of Domestic Violence Act'),
	(3871,'Contravenes Protection Order - Family Violence'),
	(3872,'Contravenes Protection Order - Unauthorised Contact'),
	(3873,'Contravenes Protection Order - Encourages a Person to Engage in Behaviour'),
	(3874,'Contravenes Protection Order - Dowry-Related Violence'),
	(3875,'Contravenes Protection Order - Breach of Special Condition'),
	(3876,'Fail to Comply w/Cond Protection Order - Fail/Refuse to Surrender Weapon'),
	(3877,'Fail to Comply w/Cond Protection Order - Fail/Ref Surrender Firearms Lic'),
	(3878,'Fail to comply with conditions of protection order - Possess Weapon'),
	(3879,'Fail to comply w/conditions of protection order - Held Firearms Licence'),
	(3881,'Contravenes Protection Order - Occupation Order'),
	(3882,'Contravenes Protection Order - Tenancy Order'),
	(3883,'Contravenes Protection Order - Ancillary Furniture Order'),
	(3884,'Contravenes Protection Order - Furniture Order'),
	(3885,'Fails to Attend Programme - Family Violence Act 2018'),
	(3886,'Breach Publication Restrictions - Family Violence Act 2018'),
	(7224,'Coerced person into marriage/civil union'), -- obsolete
	(2173, 'Induce Sexual Intercourse Pretence Of Marriage'), -- added
	(2620, 'Abduction For Marriage Or Sex'), -- added
	(2621, 'Abduction For Marriage Girl Under 12'), -- added
	(2622, 'Abduction For Marriage Girl 12-16'), --added
	(2623, 'Abduction For Marriage Female Over 16'),--added
	(2627, 'Abduction For Marriage - Male'), --added
	(2629, 'Other Abduction For Marriage Or Sex'), --added
	(2641, 'Inducing Sexual Intercourse Pretence Of Marriage'), --added
	(3723,'Breach Of Nonmolestation Order'), --DOMESTIC PROTECTION ACT 1982 SECTION 16,18. Repealed 1 July 1996 by s 129(a) Domestic Violence Act 1995
	(3741,'Offences Against Domestic Protection Act'), --Domestic Protection Act 1982 Where Not Specifically Covered Elsewhere. Repealed & Offence Obsoleted From 1 Jul, 1996
	(3749,'Other Miscellaneous Family Offences'), --Children, Young Persons, & Their Families Act 1989, Guardianship Act 1968, Matrimonial Property Act 1976, Property (Relationships) Act 1976, Domestic Violence Act 1995, Family Proceedings Act 1980, Where Not Otherwise Specified.
	(3857,'Failure To Comply With Police Safety Order (Not a criminal prosecution)'), --Domestic Violence (Enhancing Safety) Bill s 124E 1(a-i)
	(6122,'Trespass Family Proceed Act'); --Family Proceedings Act 1980 Sec 176(3). Repealed By Domestic Protection Act 1982
	--(7200, 'Births, Deaths And Marriages')
	--(7220, 'Offences Re Marriage')
	--(7222, 'Feigned Marriage')
	--(7223, 'Breaches Marriage Act')
	--(7229, 'Other Offences Re Marriage')
GO

/***************************************
combined table of family violence events
***************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_family_violence];
GO

SELECT *
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_family_violence]
FROM (

-- New Zealand Police Data
-- The Pre-Count table includes all criminal incidents within the reporting period where the offence type (ANZSOC group) is within scope. 
SELECT snz_uid
	,[pol_pro_earliest_occ_start_date] AS [start_date]
	,[pol_pro_latest_poss_occ_date] AS [end_date]
FROM  [IDI_Clean_20211020].[pol_clean].[pre_count_offenders]
WHERE pol_pro_offence_code IN (
	SELECT CAST([offence_code] AS VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND snz_uid > 0

UNION ALL

-- NZ Police data
-- The Post-count table counts a person once on each day they are proceeded against by police in the reference period, whether by court or non-court action
SELECT snz_uid
	,[pol_poo_earliest_occ_start_date] AS [start_date]
	,[pol_poo_latest_poss_occ_date] AS [end_date]
FROM  [IDI_Clean_20211020].[pol_clean].[post_count_offenders]
WHERE pol_poo_offence_code IN (
	SELECT CAST([offence_code] AS VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND snz_uid > 0

UNION ALL 

-- Pre-count victimisation
-- Recorded Crime Victims Statistics (RCVS), available from July 2014 onwards
SELECT snz_uid
	,[pol_prv_earliest_occ_start_date] AS [start_date]
	,[pol_prv_latest_poss_occ_date] AS [end_date]
FROM  [IDI_Clean_20211020].[pol_clean].[pre_count_victimisations]
WHERE pol_prv_offence_code IN (
	SELECT CAST([offence_code] as VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND snz_uid > 0

UNION ALL

-- Post-count victimisation
SELECT snz_uid
	,[pol_pov_earliest_occ_start_date] AS [start_date]
	,[pol_pov_latest_poss_occ_date] AS [end_date]
FROM  [IDI_Clean_20211020].[pol_clean].[post_count_victimisations]
WHERE pol_pov_offence_code IN (
	SELECT CAST([offence_code] AS VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND snz_uid > 0

UNION ALL

-- NIA Links 
SELECT [snz_uid]
      ,[nia_links_rec_date] AS [start_date]
	  ,[nia_links_rec_date] AS [end_date]
FROM  [IDI_Clean_20211020].[pol_clean].[nia_links]
WHERE [nia_links_latest_inc_off_code] IN (
	SELECT CAST([offence_code] AS VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND [nia_links_rec_date] IS NOT NULL
AND snz_uid > 0

UNION ALL

-- Ministry of Justice, Charges (1992 onwards)
SELECT snz_uid
	,moj_chg_offence_from_date AS [start_date] 
	,moj_chg_offence_from_date AS [end_date]
FROM  [IDI_Clean_20211020].[moj_clean].[charges] AS a
WHERE moj_chg_offence_code IN (
	SELECT CAST([offence_code] AS VARCHAR(5))
	FROM [IDI_Sandpit].[DL-MAA2021-49].[offence_codes_mapping]
)
AND snz_uid > 0

UNION ALL

-- ACC, acc_cla_read_codes indicating family member is identified as a perpetrator of maltreatment or neglect
SELECT snz_uid
	,acc_cla_accident_date AS [start_date] 
	,acc_cla_accident_date AS [end_date]
FROM   [IDI_Clean_20211020].[acc_clean].[claims]
-- where acc_cla_read_code description contains malteratment, abuse of family members. List awaiting QA
WHERE acc_cla_read_code IN ('SN563','SN564','SN57.','SN55.','SN550','SN55z','TL70.','TL7y.','TL7z.','TE401','SN553','SN552','TLx40')

) k;
GO

/* index and compress */
CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_family_violence] (snz_uid)
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_family_violence] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO


