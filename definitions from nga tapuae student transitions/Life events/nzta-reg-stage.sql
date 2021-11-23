/**************************************************************************************************
Title: Driver licensing and vehicle registration
Author: Joel Bancolita
Intended use: Views to create dataset of individuals who have a driver's license or have NZTA Motor vehicle registration

Notes:

Dependents:

History (reverse order):
2020-07-20 JB cull

**************************************************************************************************/
/* PARAMETERS */
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/


/* Set database for writing views */
USE IDI_UserCode
GO

/*

Title: Recent driver's license issue
Author: Simon Anastasiadis
Intended use: Identifying people who have a driver's license

Notes:
Recent driver's license status for regular vehicles. Special licenses
(e.g. trucks, buses, etc.) deliberately excluded as they require a
regular license.
Not suited for identifying the time of license renewal/application.

History (reverse order): 
2019-04-23 Review (AK)
2018-12-06 Initialised (SA)
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_driver_license]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_driver_license];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_driver_license] AS
SELECT [snz_uid]
	,[nzta_dlr_licence_from_date] AS [start_date]
	,[nzta_dlr_licence_from_date] AS [end_date]
--	,CONCAT('dlr status ',SUBSTRING([nzta_dlr_licence_stage_text], 1, 20)) AS [description]
	, 'full license' AS [description]
	,1 AS [value]
	,'nzta license' AS [source]
FROM [$(IDIREF)].[nzta_clean].[drivers_licence_register]
WHERE [nzta_dlr_licence_class_text] = 'MOTOR CARS AND LIGHT MOTOR VEHICLES'
AND nzta_dlr_licence_stage_text = ('FULL') -- only full lincenses
GO




/*

Title: NZTA Motor vehicle registration
Auhor: JB
Intended use: Identifying people with NZTA Motor vehicle registration

Notes:

History (reverse order): 
2020-07-20 initialise JB 

*/

/* Clear existing view */
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_car_reg]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_car_reg];
GO

/* Create staging */
CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_car_reg] AS
SELECT snz_uid
	,nzta_mvr_reg_date AS [start_date]
	,nzta_mvr_end_date AS [end_date]
--	,'Vehicle: ' + nzta_mvr_body_type_text as [description]
	,'any vehicle' AS [description] 
	, 1 AS [value]
	, 'NZTA mvr' as [source]
	FROM [$(IDIREF)].[nzta_clean].[motor_vehicle_register]
	Where nzta_mvr_body_type_text not like '%TRAILER%'
	and nzta_mvr_body_type_text not like '%UNKNOWN%'
GO

