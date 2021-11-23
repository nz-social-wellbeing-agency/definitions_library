/**************************************************************************************************************
Nga Tapuwae MoH events measures

Depends:	
- popdefn-stage.sql
- [IDI_Clean_20200120].[acc_clean].[claims]
- [IDI_Clean_20200120].[moh_clean].[chronic_condition]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
- [IDI_Clean_20200120].[moh_clean].[PRIMHD]
- [IDI_Clean_20200120].[moh_clean].[gms_claims]
- [IDI_Clean_20200120].[moh_clean].[pho_enrolment]
- [IDI_Clean_20200120].[moh_clean].[nnpac]
- [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_event]
- Output of Mental health Data Definition codes: [IDI_Sandpit].[DL-MAA2016-15].[moh_diagnosis] 

History:
2020-07-20: MP initialise

**************************************************************************************************************/


--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/


--##############################################################################################################

/*embedded in user code*/
USE IDI_UserCode
GO

/*
EVENT: ACC accident
AUTHOR: Michael Hackney
DATE: 4/12/18
Intended use: Identification of ACC accident events

Identification of the date of an ACC claim. Additional details
(such as location of claim) not used due to unknown quality.

REVIEWED: 2018-12-06 Simon Anastasiadis
- added substring to shorted long diagnoses
*/

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)ACC_ACCIDENT]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)ACC_ACCIDENT];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)ACC_ACCIDENT AS
SELECT snz_uid
	,claims.acc_cla_accident_date as "start_date"
	,claims.acc_cla_accident_date as end_date
	,'ACC claim' AS [description]
	,1 AS value
	,'acc claim' AS [source]
FROM  [$(IDIREF)].[acc_clean].[claims];
GO

/*
EVENT: Experience of a chronic condition
AUTHOR: Simon Anastasiadis
DATE:2018-12-04
Intended use: Identification of periods where individuals suffer from chronic conditions

Specific chronic conditions as recorded by MOH.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)chronic_conditions]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)chronic_conditions];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)chronic_conditions AS
SELECT [snz_uid]
	,[moh_chr_fir_incidnt_date] AS [start_date]
	,[moh_chr_last_incidnt_date] AS [end_date]
/*	,CASE WHEN [moh_chr_condition_text] = 'AMI' THEN 'acute myocardial infraction'
		WHEN [moh_chr_condition_text] = 'CAN' THEN 'cancer'
		WHEN [moh_chr_condition_text] = 'DIA' THEN 'diabetes'
		WHEN [moh_chr_condition_text] = 'GOUT' THEN 'gout'
		WHEN [moh_chr_condition_text] = 'STR' THEN 'stroke'
		WHEN [moh_chr_condition_text] = 'TBI' THEN 'traumatic brain injury' END AS [description]
		*/
	,'chronic health conditions' AS [description]
	,1 AS value
	,'moh chronic' AS [source]
FROM [$(IDIREF)].[moh_clean].[chronic_condition];
GO

/*
EVENT: Attendance of a drug and alcohol program
AUTHOR: Simon Anastasiadis
DATE:2018-12-07

Intended use: identification of receipt of drug & alcohol support

Gives time periods (often single days) that an individual was recorded
as at a drug and alcohol program. Reports are provided by DHBs and NGOs
on services rendered (hence we assume non-attendance is not captured).
Reporting by NGOs has been progressive from 2008 to 2014. Hence counts
over time will vary with increased reporting/connection of NGO reports
to PRIMHD.
Code of the team providing the program is given as the value. For
confidentiality we must ensure at least two team codes are used.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)alcohol_drug_team]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)alcohol_drug_team];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)alcohol_drug_team AS
SELECT [snz_uid]
	,[moh_mhd_activity_start_date] AS [start_date]
	,[moh_mhd_activity_end_date] AS [end_date]
	,'program with alcohol and drug team' AS [description]
	,[moh_mhd_team_code] AS [value]
	,'primhd' AS [source]
FROM [$(IDIREF)].[moh_clean].[PRIMHD]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
ON moh_mhd_team_code = TEAM_CODE
WHERE TEAM_TYPE_DESCRIPTION = 'Alcohol and Drug Team'
GO

/*
EVENT: Maternal mental health program attendance
AUTHOR: Simon Anastasiadis
DATE:2018-12-07
Intended use: identification of receipt of maternal mental health support service

Gives time periods (often single days) that an individual was recorded
as at a maternity mental health program. Reports are provided by DHBs and NGOs
on services rendered (hence we assume non-attendance is not captured).
Reporting by NGOs has been progressive from 2008 to 2014. Hence counts
over time will vary with increased reporting/connection of NGO reports
to PRIMHD.
Code of the team providing the program is given as the value. For
confidentiality we must ensure at least two team codes are used.

REVIEWED: awaiting review
*/

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)maternal_MH_team]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)maternal_MH_team];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)maternal_MH_team AS
SELECT [snz_uid]
	,[moh_mhd_activity_start_date] AS [start_date]
	,[moh_mhd_activity_end_date] AS [end_date]
	,'program with maternal MH team' AS [description]
	,1 AS [value]
--	,[moh_mhd_team_code] AS [value]
	,'primhd' AS [source]
FROM  [$(IDIREF)].[moh_clean].[PRIMHD]
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_primhd_team_code]
ON moh_mhd_team_code = TEAM_CODE
WHERE TEAM_TYPE_DESCRIPTION = 'Maternal Mental Health Team'
GO





/*
EVENT: Contact with Primary Health Organisation
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: Identification of primary health use

PHO enrollments contains interactions with primary health organisations for
those people who are enrolled or registered (non-citizens can only register)
with a GP as their regular practitioner.
GMS contain subsidies to GPs for visits by non-enrolled, non-registered
patients.
PHO enrollments are reported quarterly. This means that where there are multiple
visits within the same quarter, only the last visit is reported.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)primary_health]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)primary_health];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)primary_health AS
SELECT DISTINCT [snz_uid]
      ,[moh_gms_visit_date] AS [start_date]
	  ,[moh_gms_visit_date] AS [end_date]
	  ,'non-enrolled PHO contact' As [description]
	  ,1 AS [value]
	  ,'moh gms' AS [source]
FROM [$(IDIREF)].[moh_clean].[gms_claims]

UNION ALL

SELECT DISTINCT [snz_uid]
      ,[moh_pho_last_consul_date] AS [start_date]
	  ,[moh_pho_last_consul_date] AS [end_date]
	  ,'enrolled PHO contact' AS [description]
	  ,1 AS [value]
	  ,'moh pho' AS [source]
FROM [$(IDIREF)].[moh_clean].[pho_enrolment];
GO

/*
EVENT: Active registration with a Primary Health Organisation
AUTHOR: Simon Anastasiadis
DATE: 2018-12-07
Intended use: Identification of primary health use

Intervals within which an individual is making active use of the PHO
they are registered with. Interval runs from date of registration, until
the date of their last visit at the PHO (associated with their 
registration date, so a new registration creates a new interval).

REVIEWED: awaiting review
- practice id removed as contains non-numeric
- Registration may not be meaningful as deregistration requires 2-3 years
  with no contact between individual and PHO
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)pho_registration]','V') IS NOT NULL
DROP VIEW  [$(PROJSCH)].[$(TBLPREF)pho_registration];
GO

CREATE VIEW  [$(PROJSCH)].[$(TBLPREF)pho_registration] AS
SELECT [snz_uid]
	,[moh_pho_enrolment_date] AS [start_date]
	,MAX([moh_pho_last_consul_date]) AS [end_date]
	,'active PHO use' AS [description]
	,1 AS [value]
	,'moh pho' AS [source]
FROM  [$(IDIREF)].[moh_clean].[pho_enrolment]
GROUP BY [snz_uid], [moh_pho_enrolment_date], [moh_pho_practice_id];
GO

/*
EVENT: Emergency department visit
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify ED visit events

We use ED visits as recorded in out patients. As per Craig's advice:
because we are only interested in counting events, we do not need to
combine with admitted patient ED events.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)emergency_department]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)emergency_department];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)emergency_department AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'ED visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' as [source]
FROM [$(IDIREF)].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'ED'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: out-patient hospital visit
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify hospital visit events

We use hospital visits as recorded in out patients.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)out_patient]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)out_patient];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)out_patient] AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'out patient visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' AS [source]
FROM [$(IDIREF)].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'OP'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: community visit by hospital based practitioner
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify health interaction events

We use community visits by hospital staff as recorded in out patients.
Craig notes that these have only been consistently recorded recently.
Events where the person Did Not Attend (DNA) are excluded.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)community_visit]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)community_visit];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)community_visit AS
SELECT [snz_uid]
      ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
	  ,'community visit' AS [description]
	  ,1 AS [value]
	  ,'moh nnpac' AS [source]
FROM  [$(IDIREF)].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'CR'
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA';
GO

/*
EVENT: Admitted hospital visits
AUTHOR: Simon Anastasiadis
DATE: 2019-01-08
Intended use: Identify health interaction events

Likely to have some overlap with out-patient and ED events as people could be admitted
following such an event.

REVIEWED: awaiting review
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)hospital_admitted]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)hospital_admitted];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)hospital_admitted AS
SELECT [snz_uid]
      ,[moh_evt_evst_date] AS [start_date]
      ,[moh_evt_even_date] AS [end_date]
	  ,'admitted to hospital' AS [description]
	  ,1 AS [value]
	  ,'moh pfhd' AS [source]
FROM [$(IDIREF)].[moh_clean].[pub_fund_hosp_discharges_event]
WHERE [moh_evt_evst_date] IS NOT NULL
AND [moh_evt_even_date] IS NOT NULL;
GO

/*
EVENT: Mental health and adiction service use
AUTHOR: Marianna Pekar
DATE: 2020-07-27
Intended use: Standard definition of mental health and addictions (MHA) service access based on available data in IDI

Dependency: Mental health Data Definition Code, available on GitHub

REVIEWED: awaiting review


*/


-- For the swangt - younger populaton with more mental health service use - the description is detailed

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)mha]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)mha];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)mha AS
SELECT [snz_uid]
      ,[start_date]
      ,[end_date]
	  ,CASE
		WHEN event_type='Substance use' THEN event_type
		WHEN event_type in ('Mood','Citaopram','Mood anxiety') THEN 'Mood/Citaporam(Depression)/Mood anxiety'
		WHEN event_type = 'Anxiety' THEN event_type
		WHEN event_type = 'Psychotic' THEN event_type
		ELSE 'Other mental health' 
	 END AS [description]
	  ,1 AS [value]
	  ,'mha service use' as [source]
FROM [IDI_Sandpit].[DL-MAA2016-15].[moh_diagnosis] -- file created by Mental Health Data Definition Codes in the Sandpit
WHERE snz_uid <> -1;
GO



-- for the swangt30 - older populaton with less mental health service use - the event types are not further broken down 

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)mha]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)mha];
GO

CREATE VIEW [$(PROJSCH)].$(TBLPREF)mha AS
SELECT [snz_uid]
      ,[start_date]
      ,[end_date]
	  ,'mha service use' AS [description]
	  ,1 AS [value]
	  ,'mha service use' AS [source]
FROM [IDI_Sandpit].[DL-MAA2016-15].[moh_diagnosis] -- file created by Mental Health Data Definition Codes in the Sandpit
WHERE snz_uid <> -1;
GO
