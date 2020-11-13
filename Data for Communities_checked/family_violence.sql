/**************************************************************************************************
Title: Experience of family violence
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean_20200120].[pol_clean].[nia_links]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_family_violence]

Description:
An event where Police noted a person was exposed to family violence.

Intended purpose:
Identify events of exposure to family violence.
Count the number of family violence exposures for a person.
 
Notes:
1) There are multiple sources of family violence data. These include
   victims (RCVS) data from police, offenders (RCOS) data from police,
   intake records from CYF, NIA-linked data that combines emergency calls
   and police activity notes.
2) This definition only uses the NIA-linked data. This is
   certainly an under-count of incidence of family violence events.
   (Compared to ~120k call outs for the police family violence unit
   per year, this data contains contains at most one third the number of events)
3) Offence codes that correspond to family violence were identified. They are:
    1581	COM ASSLT(DOMESTIC)CR ACT(FIREARM)
    1582	COM ASSLT(DOMESTIC)CR ACT(OTH WEAP)
    1583	COM ASSLT(DOMESTIC)CR ACT(MANUALLY)
    1587	COMMON ASSAULT (DOMESTIC) (STABBING/CUTTING WEAPON)
    1641	COMMON ASSAULT (DOMESTIC) (FIREARM)
    1642	COMMON ASSAULT (DOMESTIC) (OTHER WEAPON)
    1643	COMMON ASSAULT (DOMESTIC) (MANUALLY)
    1647	COMMON ASSAULT (DOMESTIC) (STABBING/CUTTING WEAPON)
    2654	HUSBAND RAPES WIFE
    2658	UNLAWFUL SEXUAL CONNECTION WITH SPOUSE
    3711	CRUELTY TO/ILLTREAT CHILD (CRIMES ACT)
    1D	DOMESTIC DISPUTE
4) We have not distinguished between different roles with respect to family
   violence (e.g. offender, victim, witness, suspect, informant, etc.).
   Hence this is only exposure.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
 
Issues:
 
History (reverse order):
2020-02-28 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_family_violence]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_family_violence];
GO

CREATE VIEW [DL-MAA2016-15].[defn_family_violence] AS
SELECT [snz_uid]
      ,[nia_links_rec_date] AS [event_date]
      ,[nia_links_role_type_text]
FROM [IDI_Clean_20200120].[pol_clean].[nia_links]
WHERE [nia_links_latest_inc_off_code] IN ('1581', '1582', '1583', '1587', '1641', '1642', '1643', '1647', '2654', '2658', '3711', '1D')
AND [nia_links_rec_date] IS NOT NULL;
GO
