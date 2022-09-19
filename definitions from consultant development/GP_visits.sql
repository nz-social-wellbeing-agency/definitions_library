/**************************************************************************************************
######################
## Title: GP visits ##
######################

############################
## Inputs & Dependencies: ##
############################
- [IDI_Clean].[acc_clean].[payments]
- [IDI_Clean].[acc_clean].[claims]
- [IDI_Clean].[moh_clean].[lab_claims]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[nnpac]
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Clean].[moh_clean].[pho_enrolment]
- [IDI_Clean].[moh_clean].[gms_claims]

##############
## Outputs: ##
##############
- [IDI_Sandpit].[$(PROJSCH)].[GP_contacts]

##################
## Description: ##
##################
GP visit proxy indicator
The General Practice visits indicator is a proxy indicator of frequency of GP visits at the individual level by date of visit.

#######################
## Intended purpose: ##
#######################
Estimate primary care consults for each snz_uid by date.
This code returns an estimated number of times a patient has contacted a GP in the specified time period. 
This could be used to compare characteristics of populations that have regular contact with a GP against those that do not.

This code does not accurately identify the maximum number of times a patient has contact with a GP.
This should not be used for exact or maximum patient contact with a GP.

###################
## Key concepts: ##
###################
A GP (General Practitioner) is a family doctor that is usually the first point of contact for the patients’ new injury or illness.
Visits to GPs are partially funded by the central government and the funding history is recorded in 3 datasets –
General Medical Service (GMS), Primary Health Organization (PHO) and National Enrolment Service (NES). 

Originally, almost all healthcare user visits to general practitioners resulted in a fee-for-service GMS claim.
However since 2003, capitation payments made via Primary Health Organisations (PHOs) have progressively replaced fee-for-service claiming.
Now GMS claims are made for only a limited number of healthcare user visits of specific types.
From 2003 to 2006, GPs progressively moved to the PHO funding model.
By 2006 almost all GPs were part of a PHO so the majority of non-enrolled healthcare users were those without a regular GP.
By 2012, 96.1% of the estimated resident New Zealand population were enrolled in a PHO.
NES enrolments replaced PHO funding in the data in 2019. 
These datasets are all used to provide information about when a patient visited a GP.

PHO and NES data is stored in quarterly snapshots, so it is also not possible to see the exact date a person visited a GP,
it is only possible to tell if they had contact in the quarter.
It is possible to construct a frequency of primary care contact history at the individual level using several data sources in the IDI:
•	Primary Healthcare Organisation (PHO) – last contact date
•	Laboratory Testing Claims – provider visit date
•	General Medical Subsidy Claims – GP visit date
•	ACC claims – first payment date
•	NES – last contact date

Results are consistent with expectations that ~81% of the population have 1 or more contacts with their GP each year.
The approx. number of GP visits a year has been verified against www.rnzcpg.org.nz/gpdocs/new-website/publications/2021-GP-future-workforce-report-FINAL.pdf
They state that “GPs deliver 14 million consultations per year”.

############
## Notes: ##
############
1) The indicator relies primarily on this:
	- The PHO quarterly reporting of last date of GP contact (up to four visits a year).
	- The General Medical Subsidy (GMS) claims for all primary care contacts outside of
		when a person is enrolled GP (all visits).
	- ACC funded primary care contacts.
	It also relies on laboratory test data and the date of visit that initiated the test request.
	Approximately 20% of lab tests are requested in the secondary care setting so this is likely
	to drive a slight over count in estimates.
2) Being based on quarterly PHO contacts and GMS events we expect the indicator to be accurate for
	people having primary care outside their PHO and people visiting the GP up to four times a year.
	Inclusion of ACC and lab tests likely improves the quality for people with more than four visits
	in a year. While the indicator will be accurate for most people, a small group will have more
	visits than the indicator suggests.
3) We exclude multiple events on the same day, but for some people these are likely to exist.
4) Using Lab visits presents a challenge. ~20% of labs data is from hospitals and not GP visits.
	There is no indicator to identify this. Our approach is to drop lab visits on days where the
	snz_uid is in hospital or a non-admitted patient (NAP). This reduced lab tests by ~3.5%
	Investigation suggested that lab tests reported the day after a hospital visit behave similarly
	to lab tests during a hospital visit, hence these were also excluded. This increased the
	reduction in lab tests from ~3.5% to ~5.5%
5) Results are consistent with expectations that ~81% of the population have 1 or more contacts
	with their GP each year.
6) A small proportion of people will have multiple visits to a GP on the same day. For some datasets
	this can be observed via duplicate records. But this can not be reliably detected across datasets.
	We have not attempted to capture multiple visits on the same day.
7) Data is incomplete before 2003 and for 2021 onwards.

##################################
## Parameters & Present values: ##
##################################
1. [$(PROJSCH)] = Project schema. "DL-MAA2021-37"
2. [$(IDIREF)] = Current refresh. "IDI_Clean_202206"
3. [$(TBLPREF)] = Prefix. "tmp"

#############
## Issues: ##
#############

##############################
## History (reverse order): ##
##############################
2022-08-30 Update for SWA indicator HZ
2022-06-01 Update for SWA indicator PB
2021-11-29 SA review and tidy
2021-10-31 CW


**************************************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
--Already in master.sql; Uncomment when running individually
:setvar IDIREF "IDI_Clean_202206" 
:setvar PROJSCH "DL-MAA2021-30"
GO


/* create table of all possible contacts */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list]
GO

CREATE TABLE [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (
	snz_uid INT,
	visit_date DATE,
);
GO

/********************************************************
###################
## ACC GP visits ##
###################

• The first ACC claim payment date is used as an indicator of a GP visit.
A last payment date also exists, however the distribution of the length of claims 
has weekly spikes suggesting an influence by a billing cycle. This suggests that we cannot use the last
day as an indication of a GP visit. We do not account for multiple claims in a single day.

• This produces ~30,000,000 distinct claims.
********************************************************/

INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT b.[snz_uid]
	,[acc_pay_first_service_date] AS visit_date
FROM [$(IDIREF)].[acc_clean].[payments] AS a
INNER JOIN [$(IDIREF)].[acc_clean].[claims] AS b
ON a.[snz_acc_claim_uid] = b.[snz_acc_claim_uid]
WHERE [acc_pay_gl_account_text] = 'GENERAL PRACTITIONERS' 
AND [acc_pay_focus_group_text] = 'MEDICAL TREATMENT' 
GO

/********************************************************
##########
## Labs ##
##########

• The GP visit date is determined based on the [moh_lab_visit_date]
which is the date the healthcare user visited the referring practitioner.

• Lab claims that match or fall between the date on which a healthcare event began at a publically funded hospital
for a unique user and one day past the discharge date are excluded as these lab tests are assumed to be from the
hospital admission.

• Lab claims that match the date that the triaged patient's treatment starts by a suitable ED medical professional
or one day past this date are excluded as these lab tests are assumed to be from an ED interaction.

• Approximately 20% of lab tests are requested in the secondary care setting and this is likely
to drive a slight over count in estimates.

• Investigation suggested that lab tests reported the day after a hospital visit behave similarly
to lab tests during a hospital visit, hence these were also excluded.

• This produces ~110,000,000 distinct claims.
********************************************************/

WITH adding_hospital_indicators_to_lab_tests AS (

SELECT DISTINCT c.[snz_uid]
	,[moh_lab_visit_date] AS visit_date
	,IIF(b.snz_uid IS NOT NULL, 1, 0) AS public_hospital_discharge
	,IIF(n.snz_uid IS NOT NULL, 1, 0) AS non_admitted_patient
	,IIF(b.snz_uid IS NOT NULL OR n.snz_uid IS NOT NULL, 1, 0) AS hospital

	,IIF(c.[moh_lab_visit_date] = DATEADD(DAY, 1, b.[moh_evt_even_date]), 1, 0) AS public_hospital_discharge_extra
	,IIF(c.[moh_lab_visit_date] = DATEADD(DAY, 1, n.[moh_nnp_service_date]), 1, 0) AS non_admitted_patient_extra
FROM [$(IDIREF)].[moh_clean].[lab_claims] AS c
LEFT JOIN [$(IDIREF)].[moh_clean].[pub_fund_hosp_discharges_event] AS b 
ON c.snz_uid = b.snz_uid
AND c.[moh_lab_visit_date] BETWEEN b.[moh_evt_evst_date] AND DATEADD(DAY, 1, b.[moh_evt_even_date]) -- include one day later
LEFT JOIN [$(IDIREF)].[moh_clean].[nnpac] AS n 
ON c.snz_uid = n.snz_uid
AND c.[moh_lab_visit_date] BETWEEN n.[moh_nnp_service_date] AND DATEADD(DAY, 1, n.[moh_nnp_service_date]) -- include one day later

)

INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT snz_uid
	,visit_date
FROM adding_hospital_indicators_to_lab_tests
WHERE public_hospital_discharge = 0
AND non_admitted_patient = 0
AND hospital = 0
AND (public_hospital_discharge_extra = 0 OR public_hospital_discharge_extra IS NULL)
AND (non_admitted_patient_extra = 0 OR non_admitted_patient_extra IS NULL)
GO

/********************************************************
##################################################################
## NES - contact events for the National enrolment service data ##
##################################################################

• The NES quarterly reporting of last date of GP contact (up to four visits a year).

• The data is stored in quarterly snapshots, so it is not possible to see the exact date a person
visited a GP, it is only possible to tell if they had contact in the quarter.

• Enrolment registers are submitted on a quarterly basis before the quarter of interest begins.
The GP stops recording variables (eg last consultation date) before the quarter of interest.
Any dates submitted after the quarter of interest start date are likely to be data quality errors.

• NES data replaces PHO in 2019/2020 with a new series that is split into two tables [moh_clean].[pop_cohort_nes_address] 
and [moh_clean].[nes_enrolment].

• This produces ~42,000,000 distinct claims.
********************************************************/

INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT b.snz_uid
	,[moh_nes_last_consult_date] AS visit_date
FROM [$(IDIREF)].[moh_clean].[nes_enrolment] AS a
LEFT JOIN [$(IDIREF)].[moh_clean].[pop_cohort_demographics] AS b
ON a.snz_moh_uid = b.snz_moh_uid
GO

/********************************************************
#############################################################
## PHO - contact events for the PHO enrolment service data ##
#############################################################

• The PHO quarterly reporting of last date of GP contact (up to four visits a year).

• The data is stored in quarterly snapshots, so it is not possible to see the exact date a person
visited a GP, it is only possible to tell if they had contact in the quarter.

• Enrolment registers are submitted on a quarterly basis before the quarter of interest begins.
The GP stops recording variables (eg last consultation date) before the quarter of interest.
Any dates submitted after the quarter of interest start date are likely to be data quality errors.

• This produces ~140,000,000 distinct claims.
********************************************************/

INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT [snz_uid]
	,[moh_pho_last_consul_date] AS visit_date
FROM [$(IDIREF)].[moh_clean].[pho_enrolment]
GO

/********************************************************
#################################################################
## GMS - contact events for GP visits outside of PHO enrolment ##
#################################################################

• GMS claims provide the date of GP visits ([moh_gms_visit_date]).

• Up until 2003 most GP visits were in a GMS claim; a limited number of specific health care user 
visits are still made through GMS. 

• This produces ~30,000,000 distinct claims.
********************************************************/

INSERT INTO [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT [snz_uid] --not distinct as all discrete events
	,[moh_gms_visit_date] AS visit_date
FROM [$(IDIREF)].[moh_clean].[gms_claims]
GO

/********************************************************
###############
## Filtering ##
###############

• Filter snz_uid and visit dates that are NULL and select distinct snz_uid/visit_date pairs.

• Since the GP visit dates are compiled from several sources, it is possible that duplicates on the same day will exist and so these need to be filtered out.
This code does not accurately identify the maximum number of times a patient has contact with a GP, but instead the distinct number of events.
********************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[GP_contacts]
GO

SELECT DISTINCT snz_uid
	,visit_date
INTO [IDI_Sandpit].[$(PROJSCH)].[GP_contacts]
FROM [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list]
WHERE snz_uid IS NOT NULL
AND visit_date IS NOT NULL
AND YEAR(visit_date) >= 2003
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[$(PROJSCH)].[GP_contacts] (snz_uid)
GO
ALTER TABLE [IDI_Sandpit].[$(PROJSCH)].[GP_contacts] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/********************************************************
##########
## Tidy ##
##########
********************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[tmp_GP_contacts_list]
GO
