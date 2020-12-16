/**************************************************************************************************
Title: Early Childhood Education (ECE) events
Author: V Benny

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_MOE].[ECEStudentParticipation2015]
- [IDI_Adhoc].[clean_read_MOH_B4SC].[moh_B4SC_2015_ECE_IND]
- [IDI_Clean].[moe_clean].[nsi]
- [IDI_Clean].moh_clean.pop_cohort_demographics
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_ECE_events]

Description:
Create ECE event table in SIAL format.
This table gives the ECE type AND the hours spent in ECE by each child enrolling for the programme.
Event_type gives the ECE type that the child attended. In CASE of students who did not enroll for ECE, 
the hours spent would be null or 0 AND the ECE event_type_2 would be 'False'. Cases with no information 
available are listed with a status of 'Unknown'. Event_type_3 would give the number of hours spent in a
particular kind of ECE.

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]

Issues:

History (reverse order):
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode Schema in the IDI 
2016-10-06 V Benny: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOE_ece_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOE_ece_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOE_ece_events] AS
SELECT snz_uid, 
	'MOE' AS department,
	'ECE' AS datamart,
	'ENR' AS subject_area,
	CAST([start_date] AS DATETIME) AS [start_date],
	CAST(end_date AS DATETIME) AS end_date,
	ece_status AS event_type,
	ECEClassificationID AS event_type_2
FROM (
	SELECT 
		COALESCE(a.snz_uid, b.snz_uid) AS snz_uid, 
		a.ECEClassificationID, 
		a.ECEDurationID,
		/* count number of months backwards from end date of ECE based on the DurationID code to get start date */
		DATEADD(MONTH, CASE a.ECEDurationID WHEN 61052 THEN -6  /* attended last 6 months*/
			WHEN 61053 THEN -12  /* attended last 1 year*/
			WHEN 61054 THEN -24	 /* attended last 2 years*/
			WHEN 61055 THEN -36  /* attended last 3 years*/
			WHEN 61056 THEN -48  /* attended last 4 years*/
			WHEN 61057 THEN -60  /* attended last 5 years*/			
			WHEN 61058 THEN 0    /* did not attend regularly*/	
			ELSE NULL END,		 
			DATEFROMPARTS(person.snz_birth_year_nbr + 5,person.snz_birth_month_nbr, 15)) AS [start_date],
		/* 5th birthday assumed as end date for ECE*/
		DATEFROMPARTS(person.snz_birth_year_nbr + 5,person.snz_birth_month_nbr, 15) AS [end_date], 	
		/* Derive ECE attend status based on information from ECE and B4SC datasets*/
		CASE
			WHEN a.ECEClassificationID = 20630 THEN 'False' /* Child did not attend ECE*/
			WHEN a.ECEClassificationID = 20637 or a.ECEClassificationID IS NULL THEN /* If ECE status is unknown, check for B4SC status*/
				CASE WHEN b.probablyattendpreschool IS NULL OR b.probablyattendpreschool='' THEN 'Unknown' /* If B4SC status is also unknown, keep status AS unknown*/
					ELSE b.probablyattendpreschool END /* Use B4SC status AS ECE status if this value is defined */
			ELSE 'True' END AS ece_status, /* Child attended ECE based on data FROM ECE*/
		a.ECEHours
	FROM (
		SELECT id.snz_uid, ecepart.ECEClassificationID, ecepart.ECEDurationID, ecepart.ECEHours
		FROM [IDI_Adhoc].[clean_read_MOE].[ECEStudentParticipation2015] ecepart
		INNER JOIN (
			SELECT DISTINCT snz_moe_uid, snz_uid
			FROM [IDI_Clean_20200120].[moe_clean].[nsi]
		) id 
		ON ecepart.snz_moe_uid = id.snz_moe_uid
		GROUP BY id.snz_uid, ecepart.ECEClassificationID, ecepart.ECEDurationID, ecepart.ECEHours
	) a
	FULL OUTER JOIN (
		SELECT id.snz_uid, b4sc_att.probablyattendpreschool
		FROM IDI_Adhoc.[clean_read_MOH_B4SC].[moh_B4SC_2015_ECE_IND] b4sc_att
		INNER JOIN [IDI_Clean_20200120].moh_clean.pop_cohort_demographics id 
		ON b4sc_att.snz_moh_uid = id.snz_moh_uid
		WHERE b4sc_att.probablyattendpreschool IS NOT NULL
		AND b4sc_att.probablyattendpreschool <> '' 
	)b
	ON a.snz_uid = b.snz_uid
	LEFT JOIN [IDI_Clean_20200120].[data].[personal_detail] person
	ON COALESCE(a.snz_uid, b.snz_uid) = person.snz_uid
)inner_query
WHERE ece_status <> 'False' /*individuals who did not attend ECE are removed from the output*/
GO