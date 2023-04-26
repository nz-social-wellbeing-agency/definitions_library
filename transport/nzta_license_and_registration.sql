/**************************************************************************************************
Title: Driver licensing and vehicle registration
Author: Joel Bancolita

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
Driver licensing and vehicle registration

Intended purpose:
Indication of whether a person has an NZ driver's license or has a motor vehicle registered in their name.

Inputs & Dependencies:
- [IDI_Clean].[nzta_clean].[drivers_licence_register]
- [IDI_Clean].[nzta_clean].[motor_vehicle_register]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_driver_license]
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_vehicle_registration]

Notes:
1) Recent driver's license status for regular vehicles. Special licenses (e.g. trucks, buses, etc.)
	deliberately excluded as they require a regular license.
	Not suited for identifying the time of license renewal/application.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-08-31 MP limiting only to full license and disregarding vehicle types
2020-07-20 JB cull
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Recent driver's license issue */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_driver_license];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_driver_license] AS
SELECT [snz_uid]
	,[nzta_dlr_licence_from_date] AS [start_date]
	,[nzta_dlr_licence_from_date] AS [end_date]
--	,CONCAT('dlr status ',SUBSTRING([nzta_dlr_licence_stage_text], 1, 20)) AS [description]
	, 'full or restricted license' AS [description]
FROM [IDI_Clean_YYYYMM].[nzta_clean].[drivers_licence_register]
WHERE [nzta_dlr_licence_class_text] = 'MOTOR CARS AND LIGHT MOTOR VEHICLES'
AND nzta_dlr_licence_stage_text in ('FULL', 'RESTRICTED') -- only full lincenses
GO

/* NZTA Motor vehicle registration */

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_vehicle_registration]
GO

/* Create staging */
CREATE VIEW [DL-MAA20XX-YY].[vacc_vehicle_registration] AS
SELECT snz_uid
	,nzta_mvr_reg_date AS [start_date]
	,nzta_mvr_end_date AS [end_date]
--	,'Vehicle: ' + nzta_mvr_body_type_text as [description]
	,'any vehicle' AS [description] 
	FROM [IDI_Clean_YYYYMM].[nzta_clean].[motor_vehicle_register]
	WHERE nzta_mvr_body_type_text NOT LIKE '%TRAILER%'
	AND nzta_mvr_body_type_text NOT LIKE '%UNKNOWN%'
GO
