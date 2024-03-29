/**************************************************************************************************
Title: Mental health service use
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
Use of mental mealth and addictions services as recorded in PRIMHD.

Intended purpose:
Determining who has accessed mental health and addiction services.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[PRIMHD]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]

Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_MHA_service_use]

 
Notes:
1) While the GMS table codes both health cards as Y(es) or N(o),
   the pharmaceutical table uses a different coding of health cards:
   HUHC in (NULL, U, Z)
   CSC in (NULL, 1, 3, 4)
   Based on the proportion of the population in each category, we has assumed
   HUHC = Z and CSC = 1 or 3 are equivalent to Yes, and the others are equivalent to No.
2) Several activity types are excluded:
   T08	Care/liaison co-ordination contacts
   T32	Contact with family/whanau, consumer not present
   T33	Seclusion
   T35	Did not attend
   T37	On leave

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
IF OBJECT_ID('[DL-MAA20XX-YY].[defn_MHA_service_use]','V') IS NOT NULL
DROP VIEW [DL-MAA20XX-YY].[defn_MHA_service_use];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_MHA_service_use] AS
SELECT [snz_uid]
      ,[moh_mhd_activity_start_date]
      ,[moh_mhd_activity_end_date]
      ,[moh_mhd_activity_type_code]
      ,[moh_mhd_activity_status_code]
      ,[moh_mhd_activity_unit_type_text]
	  ,TEAM_TYPE_DESCRIPTION
FROM [IDI_Clean_YYYYMM].[moh_clean].[PRIMHD]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
ON moh_mhd_team_code = TEAM_CODE
WHERE [moh_mhd_activity_type_code] NOT IN ('T35','T32','T33','T37','T08')
GO