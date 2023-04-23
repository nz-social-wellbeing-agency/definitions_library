
/**********************************************************************************
Title: Local authority housing spells
Author: Todd Nicholson, John Park, and Hubert Zal

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
This code defines spells where clients have lived in local authority (city council) housing.

Intended purpose:
It works out which addresses look reliably like local authority housing and over which date range.
This includes the individual’s unique identifier, the spell’s (tenancy) duration and the local authority property ID.
It is based on tenancy bond lodgements with MBIE. 

Inputs & Dependencies:
- [IDI_Clean].[dbh_clean].[bond_lodgement]
- [IDI_Clean].[data].[address_notification]

Outputs:
- [$(PROJSCH)].[loc_aut_housing]

Output variables:
1. snz_uid:	A global unique identifier created by Statistics NZ. There is a snz_uid for each distinct identity in the IDI.
This identifier is changed and reassigned each refresh.
2. ant_notification_date: The start date of the spell (“move-in date”). 
The year and month of an address notification entered into [IDI_Clean].[data].[address_notification]
3. ant_replacement_date: The end date of the spell (“move-out date”). 
The year and month the address notification was superseded (if the date is 9999-12 it is still current).
4. snz_idi_address_register_uid: The encrypted identifier for this address.


Notes:
The following steps are taken to derive the spells where clients have lived in local authority housing:
1.	Local authority housing is determined based on the [dbh_bond_landlord_group_code]. 
This is an indicator for whether the landlord is a private landlord, or a government entity. 
'LOC' signifies Local Authority. We start by getting all the properties that could be Local Authority Housing at some point in the past.
2.	We work out when the property appears to have a spell of being used for Local Authority Housing.
This time range will then be used to work out when an individual’s residence spell.
3.	Next the address notification of the Local Authority Houses are determined by linking to [data].[address_notification] on [snz_idi_address_register_uid].
Since the address notification data and bond lodgement date are not always consistent a buffer of 7 days was given when limiting to only the spell ranges. 
4.	Determine if less than 70% of bond lodgements for each address are considered local authority (‘LOC’).
If yes, then do not count as local authority housing.
5.	Determine the number of people per bond lodgement. If more than 12 people do not count as local authority housing.
6.	Apply the local authority housing ranges and rules to the address notification.

Additional notes:
[IDI_Clean].[dbh_clean].[bond_lodgement]: Data on bonds lodged with MBIE since January 2000.
The [dbh_bond_landlord_group_code] is an indicator for whether the landlord is a private landlord, or a government entity. 'LOC' signifies Local Authority.
The start and end dates of a tenancy are defined by [dbh_bond_tenancy_start_date] and [dbh_bond_tenancy_end_date]. If there is no end data an arbitrary date 
has been set (9999-01-01).

Ad Hoc applied based on the distribution:
1.	If there are more than 12 people per bond lodgement then do not count as local authority housing. 
2.	If less than 70% of bond lodgements are local authority then do not count as local authority housing. 
From beginning to end of bond LOC lodgement, house must remain LOC for 70% of this time.


Parameters & Present values:
  Current refresh = $(IDIREF)
  Prefix = $(TBLPREF)
  Project schema = [$(PROJSCH)]
 
Issues:
 
History (reverse order):


**********************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
--Already in master.sql; Uncomment when running individually
:setvar TBLPREF "tmp" 
:setvar IDIREF "IDI_Clean_YYYYMM" 
:setvar PROJSCH "DL-MAA20XX-YY"
GO

--##############################################################################################################
 USE IDI_Sandpit;
-- USE {targetdb};

DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_addresses];
-- DROP TABLE IF EXISTS {targetschema}.{projprefix}_moh_dis_assess_elig;
GO

-- Start be getting all the properties that could be Local Authority Housing at some point in the past.
-- If there is no end date then set the end date to 9999-01-01
SELECT snz_dbh_bond_uid
	,snz_dbh_property_uid
	,dbh_bond_bedroom_count_code
	,dbh_bond_bond_tenant_count
	,snz_idi_address_register_uid
	,dbh_bond_property_type_text
	,[dbh_bond_bond_lodged_date]
	,[dbh_bond_tenancy_start_date] AS [start_date]
	,ISNULL([dbh_bond_tenancy_end_date], '9999-01-01') AS [end_date]
	,[dbh_bond_landlord_group_code]
	,ISNULL([dbh_bond_bond_closed_date], '9999-01-01') AS [dbh_bond_bond_closed_date]
	,dbh_bond_ta_code
INTO [$(PROJSCH)].[$(TBLPREF)_loc_addresses]
FROM [$(IDIREF)].[dbh_clean].[bond_lodgement]
WHERE snz_idi_address_register_uid IN (SELECT DISTINCT snz_idi_address_register_uid FROM [$(IDIREF)].[dbh_clean].[bond_lodgement] WHERE [dbh_bond_landlord_group_code] = 'LOC')
--ORDER BY snz_idi_address_register_uid, [dbh_bond_tenancy_start_date]

-- Work out when the property appears to be used for Local Authority Housing.  This time range will be used to work out
-- when the counts should be calculated over.
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_pot_loc_range];

SELECT snz_idi_address_register_uid, MIN([start_date]) AS first_loc_date, MAX([end_date]) AS last_loc_date
INTO [$(PROJSCH)].[$(TBLPREF)_pot_loc_range]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_addresses]
WHERE [dbh_bond_landlord_group_code] = 'LOC'
GROUP BY snz_idi_address_register_uid

-- Add those dates to the original dataset
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_one];

SELECT a.*
	,b.first_loc_date
	,b.last_loc_date
INTO [$(PROJSCH)].[$(TBLPREF)_loc_add_one]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_addresses] AS a
LEFT JOIN [$(PROJSCH)].[$(TBLPREF)_pot_loc_range] AS b
ON a.snz_idi_address_register_uid = b.snz_idi_address_register_uid

-- From that dataset grab the Local Authority Housing episodes in the appropriate range
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_loc];

SELECT *
INTO [$(PROJSCH)].[$(TBLPREF)_loc_add_loc]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_add_one]
WHERE [dbh_bond_landlord_group_code] = 'LOC' AND [start_date] >= [first_loc_date] AND [end_date] <= [last_loc_date]

-- From that dataset grab the non-Local Authority Housing episodes in the appropriate range
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_excl];

SELECT *
INTO [$(PROJSCH)].[$(TBLPREF)_loc_add_excl]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_add_one]
WHERE [dbh_bond_landlord_group_code] != 'LOC' AND [start_date] >= [first_loc_date] AND [end_date] <= [last_loc_date]

-- Grab the address notifications for the Local Authority Housing
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc];

SELECT [snz_uid]
      ,[ant_notification_date]
      ,[ant_replacement_date]
      ,[snz_idi_address_register_uid]
INTO [$(PROJSCH)].[$(TBLPREF)_add_notific_loc]
FROM [$(IDIREF)].[data].[address_notification]
WHERE snz_idi_address_register_uid IN (SELECT DISTINCT snz_idi_address_register_uid FROM [$(IDIREF)].[dbh_clean].[bond_lodgement] WHERE [dbh_bond_landlord_group_code] = 'LOC')
ORDER BY snz_idi_address_register_uid, [ant_notification_date]

-- Add the time ranges to the dataset
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_1];

SELECT a.*
	,b.first_loc_date
	,b.last_loc_date
INTO [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_1]
FROM [$(PROJSCH)].[$(TBLPREF)_add_notific_loc] AS a
LEFT JOIN [$(PROJSCH)].[$(TBLPREF)_pot_loc_range] AS b
ON a.snz_idi_address_register_uid = b.snz_idi_address_register_uid

-- And limit to only that range but allow a little bit of additional range to account for timing issues 
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_lim];

SELECT *
INTO [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_lim]
FROM [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_1]
WHERE [ant_notification_date] >= DATEADD(DAY , -7, [first_loc_date]) AND [ant_notification_date] <= [last_loc_date]

-- Calculate the proportion of Local Authority Housing versus non-Local Authority Housing ones
-- count number of Local Authority Housing bonds at each address
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_counts];

SELECT snz_idi_address_register_uid,
	[first_loc_date],
	[last_loc_date],
	COUNT(snz_idi_address_register_uid) AS count_loc
INTO [$(PROJSCH)].[$(TBLPREF)_loc_counts]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_add_loc]
GROUP BY snz_idi_address_register_uid, [first_loc_date], [last_loc_date]

-- count number of non-Local Authority Housing bonds at each address
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_excl_counts];

SELECT snz_idi_address_register_uid,
	COUNT(snz_idi_address_register_uid) AS count_excl
INTO [$(PROJSCH)].[$(TBLPREF)_excl_counts]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_add_excl]
GROUP BY snz_idi_address_register_uid

-- count number of address notifications
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_not_counts]

SELECT snz_idi_address_register_uid,
	COUNT(snz_idi_address_register_uid) AS count_add_nots
INTO [$(PROJSCH)].[$(TBLPREF)_add_not_counts]
FROM [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_lim]
GROUP BY snz_idi_address_register_uid

-- Pull all the counts together
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_count_sum_1];

SELECT a.snz_idi_address_register_uid
	, a.[first_loc_date]
	, a.[last_loc_date]
	,CASE 
		WHEN a.count_loc IS NULL THEN 0
		ELSE a.count_loc
	END AS count_loc
	,CASE 
		WHEN b.count_excl IS NULL THEN 0
		ELSE b.count_excl
	END AS count_excl
INTO [$(PROJSCH)].[$(TBLPREF)_count_sum_1]
FROM [$(PROJSCH)].[$(TBLPREF)_loc_counts] AS a
LEFT JOIN [$(PROJSCH)].[$(TBLPREF)_excl_counts] AS b
ON a.snz_idi_address_register_uid = b.snz_idi_address_register_uid

/*determine if less than 70% of bond lodgments for each address are considered local authority (‘LOC’). 
If yes, then do not count as local authority housing.
Next determine the number of people per bond lodgment. If more than 12 people do not count as local authority housing.*/
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_count_sum_2];

SELECT a.*
	,CASE 
		WHEN b.count_add_nots IS NULL THEN 0
		ELSE b.count_add_nots
	END AS count_add_nots
	, CONVERT(DECIMAL(8, 2), ((count_loc*1.)/(count_loc+count_excl))) AS loc_ratio
	, CONVERT(DECIMAL(8, 2), ((count_add_nots*1.)/(count_loc+count_excl))) AS notif_ratio
 INTO [$(PROJSCH)].[$(TBLPREF)_count_sum_2]
FROM [$(PROJSCH)].[$(TBLPREF)_count_sum_1] AS a
LEFT JOIN [$(PROJSCH)].[$(TBLPREF)_add_not_counts] AS b
ON a.snz_idi_address_register_uid = b.snz_idi_address_register_uid

-- And apply business rules
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_com_houses];

SELECT snz_idi_address_register_uid,
	[first_loc_date], 
	[last_loc_date]
INTO [$(PROJSCH)].[$(TBLPREF)_com_houses]
FROM [$(PROJSCH)].[$(TBLPREF)_count_sum_2]
WHERE loc_ratio > 0.7 AND notif_ratio < 12.0

/*********************************************************************************************
Now apply those local authority housing ranges to the address notifications
*********************************************************************************************/
DROP TABLE IF EXISTS [$(PROJSCH)].[loc_aut_housing];

SELECT a.[snz_uid]
      ,a.[ant_notification_date]
      ,a.[ant_replacement_date]
      ,a.[snz_idi_address_register_uid]
	 -- ,a.[ant_ta_code]
	 -- ,b.[first_loc_date]
	 -- ,b.[last_loc_date]
INTO [$(PROJSCH)].[loc_aut_housing]
FROM [$(IDIREF)].[data].[address_notification] AS a
INNER JOIN [$(PROJSCH)].[$(TBLPREF)_com_houses] AS b
ON a.[snz_idi_address_register_uid] = b.[snz_idi_address_register_uid]
WHERE a.[ant_notification_date] >= DATEADD(DAY , 0, b.[first_loc_date]) AND a.[ant_notification_date] < DATEADD(DAY , 0, b.[last_loc_date])

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[$(PROJSCH)].[loc_aut_housing] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[$(PROJSCH)].[loc_aut_housing] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO


DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_addresses];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_pot_loc_range];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_one];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_loc];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_add_excl];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_1];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_notific_loc_lim];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_loc_counts];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_excl_counts];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_add_not_counts]
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_count_sum_1];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_count_sum_2];
DROP TABLE IF EXISTS [$(PROJSCH)].[$(TBLPREF)_com_houses];
