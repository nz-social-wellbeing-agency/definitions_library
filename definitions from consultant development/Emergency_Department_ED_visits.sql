/*
EVENT: Emergency department visit
AUTHOR: Hubert Zal
DATE: 23-06-2022
Intended use: Identify ED visit events

In New Zealand, emergency departments (EDs) provide care and treatment for patients with real or perceived, serious injuries or illness.
We use ED visits as recorded in the National Non-admitted Patient Collection (NNPAC).

-------------------------------------------------------------------------------------------------------
Inclusion Criteria

The Ministry of Health has defined an inclusion criteria which defines an emergency department visit
which is recorded with the National Non-admitted Patient Collection (NNPAC).
Inclusion criteria as described in: www.health.govt.nz/publication/emergency-department-use-2014-15
See page 34.
•	had one of the ED codes specified as the purchase unit code (ED02001-ED06001A)
•	were completed (ie, excludes events where the patient did not wait to complete)
•	do not include follow-up appointments

The following ED purchase unit codes have been included:
ED02001, ED02001A, ED03001, ED03001A,
ED04001, ED04001A, ED05001, ED05001A,
ED06001, ED06001A

As per Craig Wright's advice:
because we are only interested in counting events, we do not need to
combine with admitted patient ED events.
Events where the person Did Not Attend (DNA) and Did Not Wait (DNW) are excluded.

-------------------------------------------------------------------------------------------------------
Variable definitions

moh_nnp_purchase_unit_code: A purchase unit code is part of a classification system used to consistently measure, quantify and value a service.
The definition for each purchase unit code can be found in the Purchase unit dictionary at:
www.nsfl.health.govt.nz/purchase-units/purchase-unit-data-dictionary-202223

moh_nnp_attendence_code: Attendance code for the outpatient event. Notes: 
ATT (Attended) - An attendance is where the healthcare user is assessed by a registered medical 
practitioner or nurse practitioner. The healthcare user received treatment, therapy, advice, 
diagnostic or investigatory procedures.
DNA (Did Not Attend) - Where healthcare user did not arrive, this is classed as did not attend.
DNW (Did Not Wait) - Used for ED where the healthcare user did not wait. Also for use where healthcare
user arrives but does not wait to receive service.

moh_nnp_event_type_code: Code identifying the type of outpatient event. Notes: From 1 Jul 2008 to 31 June 2010,
the event type was determined from the submitted purchase unit code. However, from July 2010
it became mandatory to report the event type directly.

moh_nnp_service_date: The date and time that the triaged patient's treatment starts by a suitable ED medical professional
(could be the same time as the datetime of service if treatment begins immediately).


Parameters & Present values:
  Current refresh = $(IDIREF)
  Prefix = $(TBLPREF)
  Project schema = [$(PROJSCH)]
 
Issues:
 
History (reverse order):
Simon Anastasiadis: 2019-01-08

**************************************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
--Already in master.sql; Uncomment when running individually
:setvar TBLPREF "SWA_" 
:setvar IDIREF "IDI_Clean_202206" 
:setvar PROJSCH "DL-MAA2021-30"
GO

USE IDI_UserCode;

IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)emergency_department]','V') IS NOT NULL
DROP VIEW [$(PROJSCH)].[$(TBLPREF)emergency_department];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)emergency_department] AS

SELECT DISTINCT [snz_uid]
      ,[moh_nnp_service_datetime] AS [start_date]
	  ,[moh_nnp_service_datetime] AS [end_date]
	 -- ,[moh_nnp_purchase_unit_code]
	  ,'ED visit' AS [description]
	  ,'moh nnpac' as [source]
FROM [$(IDIREF)].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] = 'ED'
AND [moh_nnp_purchase_unit_code] IN ('ED02001', 'ED02001A', 'ED03001', 'ED03001A',
									 'ED04001', 'ED04001A', 'ED05001', 'ED05001A',
									 'ED06001', 'ED06001A')
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_service_type_code] <> 'FU' /*do not include "follow-up" (FU) appointments. 
--See 'inclusion criteria' on page 34 of: www.health.govt.nz/publication/emergency-department-use-2014-15*/
AND [moh_nnp_attendence_code] <> 'DNA' /*Remove cases when health care user "Did not attend"*/
AND [moh_nnp_attendence_code] <> 'DNW'; /*Remove cases when health care user arrived but "did not wait" to use service.
--See 'inclusion criteria' on page 34 of: www.health.govt.nz/publication/emergency-department-use-2014-15*/
GO
