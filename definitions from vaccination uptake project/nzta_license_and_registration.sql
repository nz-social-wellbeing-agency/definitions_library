/**************************************************************************************************
Title: Driver licensing and vehicle registration
Author: Joel Bancolita
Reviewer:

Inputs & Dependencies:
- [IDI_Clean].[nzta_clean].[drivers_licence_register]
- [IDI_Clean].[nzta_clean].[motor_vehicle_register]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_driver_license]
- [IDI_UserCode].[DL-MAA2021-49].[vacc_vehicle_registration]

Description:
Driver licensing and vehicle registration

Intended purpose:
Indication of whether a person has an NZ driver's license
or has a motor vehicle registered in their name.

Notes:
1) Recent driver's license status for regular vehicles. Special licenses (e.g. trucks, buses, etc.)
	deliberately excluded as they require a regular license.
	Not suited for identifying the time of license renewal/application.

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-08-31 MP limiting only to full license and disregarding vehicle types
2020-07-20 JB cull
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Recent driver's license issue */
DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_driver_license];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_driver_license] AS
SELECT [snz_uid]
	,[nzta_dlr_licence_from_date] AS [start_date]
	,[nzta_dlr_licence_from_date] AS [end_date]
--	,CONCAT('dlr status ',SUBSTRING([nzta_dlr_licence_stage_text], 1, 20)) AS [description]
	, 'full or restricted license' AS [description]
FROM [IDI_Clean_20211020].[nzta_clean].[drivers_licence_register]
WHERE [nzta_dlr_licence_class_text] = 'MOTOR CARS AND LIGHT MOTOR VEHICLES'
AND nzta_dlr_licence_stage_text in ('FULL', 'RESTRICTED') -- only full lincenses
GO

/* NZTA Motor vehicle registration */

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_vehicle_registration]
GO

/* Create staging */
CREATE VIEW [DL-MAA2021-49].[vacc_vehicle_registration] AS
SELECT snz_uid
	,nzta_mvr_reg_date AS [start_date]
	,nzta_mvr_end_date AS [end_date]
--	,'Vehicle: ' + nzta_mvr_body_type_text as [description]
	,'any vehicle' AS [description] 
	FROM [IDI_Clean_20211020].[nzta_clean].[motor_vehicle_register]
	WHERE nzta_mvr_body_type_text NOT LIKE '%TRAILER%'
	AND nzta_mvr_body_type_text NOT LIKE '%UNKNOWN%'
GO
