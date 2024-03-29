/**************************************************************************************************
Title: Immunisations
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
Events when people get immunisations.

Intended purpose:
1. Determining who has been immunised.
2. Counting the number of immunisations.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nir_event]

Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_immunisation]
 
Notes:
1) There is no data dictionary for two of the three immunisation tables
   so we have used our best judgement.
2) People who Decline an immunisation are excluded.
   People who had the immunisation overseas are recorded as Complete.
3) Most immunisations are given to babies/children, but not all.
   [moh_nir_evt_indication_desc_text] contains these details.
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
IF OBJECT_ID('[DL-MAA20XX-YY].[defn_immunisation]','V') IS NOT NULL
DROP VIEW [DL-MAA20XX-YY].[defn_immunisation];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_immunisation] AS
SELECT [snz_uid]
      ,[moh_nir_evt_event_id_nbr]
      ,[moh_nir_evt_vaccine_date]
	  ,CAST([moh_nir_evt_vaccine_date] AS DATE) AS [event_vaccine_date]
      ,[moh_nir_evt_indication_text]
      ,[moh_nir_evt_indication_desc_text]
      ,[moh_nir_evt_status_desc_text]
FROM [IDI_Clean_YYYYMM].[moh_clean].[nir_event]
WHERE [moh_nir_evt_status_desc_text] = 'Completed'
GO