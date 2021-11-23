/****** Nga Tapuwae CYF event measures

Title: A report of concern to CYF that meets Sec 15 criterial
Author Simon Anastasiadis, Maui Brennan
Reviewer: AK, MP
Intended use: 
- Section 15 - Identify concern for children and stress on parents
- Identifying all abuse events. 

Depends:	
- popdefn-stage.sql
- [IDI_Clean].[cyf_clean].[cyf_abuse_event]
- []

History (reverse order):
2020-08-29 reviewed, parameterised (MP) 
2020-08-19 MB adding all abuse events
2019-04-23 reviewer (AK)
2019-04-01 Initiated
*/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment when running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/
--##############################################################################################################
/*embedded in user code*/
USE IDI_UserCode
GO

--##############################################################################################################
/*
Notes:
Section 15 - Identify concern for children and stress on parents
A care and protection client intake event occurs when a person who believes a child or young person (CYP) is being (or is likely to be) harmed,
ill-treated, abused, neglected, or deprived, reports the matter to CYF or the Police. 
CYF also receive reports when there are concerns regarding a child or young person's behaviour, or insecurity of care. 
A youth justice client intake event occurs when a child or young person is alleged to have committed an offence and the matter is referred by the Police
(or other enforcement agency), Youth Court, or Family Court. Where a child or young person appears before the court, they may also be placed in the custody of CYF following arrest.
The client intake event start date is the incident date of the notification to CYF and the end date is the end date of the client role in the intake phase.
*/
-- Create a view for event
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_intakes_event]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_intakes_event];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_intakes_event]
AS
SELECT a.[snz_uid]
	,[cyf_ine_event_from_date_wid_date] AS [start_date]
	,[cyf_ine_event_from_date_wid_date] AS [end_date]
	,'SEC15' AS [description]
	,1 AS [value]
	,'cyf_intakes' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_intakes_event] a
INNER JOIN [$(IDIREF)].[cyf_clean].[cyf_intakes_details] b ON a.[snz_composite_event_uid] = b.[snz_composite_event_uid]
WHERE b.[cyf_ind_intake_type_code] = 'SEC15';
GO

-- Create a view for indicator
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_intakes_indicator]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_intakes_indicator];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_intakes_indicator]
AS
SELECT a.[snz_uid]
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS "end_date"
	,'SEC15' AS [description]
	,1 AS [value]
	,'cyf_intakes' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_intakes_event] a
INNER JOIN [$(IDIREF)].[cyf_clean].[cyf_intakes_details] b ON a.[snz_composite_event_uid] = b.[snz_composite_event_uid]
WHERE b.[cyf_ind_intake_type_code] = 'SEC15';
GO

-- Identifying all abuse events, borader definiton
/*
Notes:
An abuse finding event records the assessment that a social worker makes about whether or not a client has suffered abuse. 
There is one event for every combination of client, perpetrator, and abuse type. 
There will often be multiple abuse findings event records for a client because there may be multiple notifications for a client, each requiring an investigation. 
The same client may have more than one type of abuse within the same period (eg physically and sexually abused). 
Similarly, a client may have the same type of abuse more than once for the same notification, as a result of more than one perpetrator subjecting the client to the same abuse. 
For example, a child is neglected by both parents.
*/
-- Create a view for event
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_abuse_event]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_abuse_event];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_abuse_event]
AS
SELECT [snz_uid]
	,[cyf_abe_event_from_datetime] AS [start_date]
	,[cyf_abe_event_to_datetime] AS [end_date]
	,'Abuse Event Occurred' AS [description]
	,1 AS [value]
	,'cyf' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_abuse_event]
WHERE [cyf_abe_event_type_wid_nbr] IS NOT NULL;
GO

-- Create a view for indicator 
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_abuse_indicator]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_abuse_indicator];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_abuse_indicator]
AS
SELECT [snz_uid]
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS "end_date"
	,'Abuse Event Occurred' AS [description]
	,1 AS [value]
	,'cyf' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_abuse_event]
WHERE [cyf_abe_event_type_wid_nbr] IS NOT NULL;
GO

-- Placements
/*
Notes: A placement event occurs when a placement record is created for a client.
Some placement records for a given client may overlap. An example of this is where a placement is in force but then a respite placement
(perhaps for a few days) occurs for the same client, who then returns to the original placement after the respite placement.
*/
-- Create a view for event
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_placement_event]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_placement_event];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_placement_event]
AS
SELECT [snz_uid]
	,cyf_ple_event_from_date_wid_date AS [start_date]
	,cyf_ple_event_to_date_wid_date AS [end_date]
	,'Placement Event Occurred' AS [description]
	,1 AS [value]
	,'cyf' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_placements_event]
WHERE [cyf_ple_event_type_wid_nbr] IS NOT NULL;
GO

-- Create a view for indicator
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)cyf_placement_indicator]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)cyf_placement_indicator];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)cyf_placement_indicator]
AS
SELECT [snz_uid]
	,'1900-01-01' AS "start_date"
	,'2100-01-01' AS "end_date"
	,'Placement Event Occurred' AS [description]
	,1 AS [value]
	,'cyf' AS [source]
FROM [$(IDIREF)].[cyf_clean].[cyf_placements_event]
WHERE [cyf_ple_event_type_wid_nbr] IS NOT NULL;
GO


