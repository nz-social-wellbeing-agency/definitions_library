

/***************************************************************************************************************************

Title: Emergency housing spells
Author: Verity Warn
Reviewer: Penny Mok 
# Emergency Housing Spells Module

## Purpose of the Emergency Housing Spells Module:
The purpose of this code module are as follows - 

1. Extract MSD third tier expenditure data (i.e. adhoc payments data) in the IDI only related to emergency housing payments made to the recipients.
2. Apply basic cleaning to the MSD data.
3. Join the one-off payments data with each other to form spells with start dates and end dates.

Note that this module was tested on data from March 2019 to March 2021. Any inconsistencies and error with the MSD third tier expenditure data beyond those points have not been tested, nor any inconsistencies in the MSD third tier expenditure data through time beyond those points. In addition, the data for emergency housing goes from 11 September 2016 to 31 December 2021 for the March 2022 IDI refresh. 

The expected business key for the output dataset is one row per distinct snz_uid and start_date. In other words, one row per person (snz_uid) plus the date when they recived the adhoc payment (start_date). 

## Key Concepts
From [Work and Income]( https://workandincome.govt.nz/housing/nowhere-to-stay/emergency-housing.html )
Emergency housing is a form accommodation subsided by MSD for people that have no alternative housing options to stay for the night. If an individual meets the criteria for an emergency housing, then MSD will cover for the first 7 nights at the emergency housing as long as 
- it is the recipient's first time at an emergency housing, OR 
- enough duration has passed since the last time recipient has been in an emergency housing and there's a new reason for the recipient to need emergency housing

After 7 nights, the recipient needs to pay 25% of their income for the accommodation costs. If they have a partner, they will also need to pay 25% of their income. Income is any money coming in for the recipient, e.g., main benefit, Family Tax Credit.

From [Ministry of Housing and Urban Development's (HUD's) Quarterly Reports]( https://hud.govt.nz/asserts/News-and-Resources/Statistics-and-Research/Public-housing-reports/Quarterly-reports/Public-housing-Quarterly-Report-March-2021.pdf )
HUD further clarifies that emergency housing is a form of Special Needs Grants (SNGs) provided by MSD. 

## Practical Notes
1. [MSD MSD Benefit Dynamics Data and Income Support Expenditure Data Dictionary]( http://wprdtfs05/sites/DefaultProjectCollection/IDI/IDIwiki/UserWiki/Wiki%20Pages/02%20About%20the%20Data/IDI/Metadata/MSD/IDI%20MSD%20Benefit%20Dynamics%20Data%20and%20Income%20Support%20Expenditure%20data.aspx ) are available within the IDI. Most of these include one sentence descriptions of the IDI variables. Note that this link only works inside the IDI. Data on emergency housing is stored in the table 'IDI Adhoc Payments to Beneficiaries (Third Tier Expenditure)', which stores data on one-off payments made to beneficiaries, i.e., SNGs. 
2. As stated in the MSD benefits data dictionary, "the IDI Adhoc Payments to Beneficiaries table are extracted from SWIFTT, UCV and CURAM Replica tables."
3. Identifying the reason for the one-off payments can be located in the Metadata database in the IDI under [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason]. The reason code for a beneficiary receiving emergency housing is '855'. This was first identified by Craig Wright from Social Wellbeing Agency (SWA). Although the code '857' is emergency housing contributions, there no individuals with that specific code in the data. 
4. [HUD's Quarterly Reports]( https://hud.govt.nz/asserts/News-and-Resources/Statistics-and-Research/Public-housing-reports/Quarterly-reports/Public-housing-Quarterly-Report-March-2021.pdf ) provides an external reference for the number of people that have received Emergency Housing Special Needs Grants. The number of distinct individuals that have applied for emergency housing in the table 'IDI Adhoc Payments to Beneficiaries (Third Tier Expenditure)' gives numbers very close to the numbers reported by HUD. 

## References & Contacts
1. [Work and Income]( https://workandincome.govt.nz/housing/nowhere-to-stay/emergency-housing.html ) provides a brief overview on emergency housing.
2. [Ministry of Housing and Urban Development's (HUD's) Quarterly Reports]( https://hud.govt.nz/asserts/News-and-Resources/Statistics-and-Research/Public-housing-reports/Quarterly-reports/Public-housing-Quarterly-Report-March-2021.pdf ) provides an external point of reference for number of people on emergency housing. 
2. Craig Wright at SWA


## Module Business Rules

### Key rules
1. 'IDI Adhoc Payments to Beneficiaries (Third Tier Expenditure)' table is located in [msd_clean].[msd_third_tier_expenditure] table in the [IDI_Clean] database. 
2. The dataset contains individuals from [msd_clean].[msd_third_tier_expenditure] table with the pay reason code of '855', which corresponds to 'Emergency Housing', based on the information obtained from [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_income_support_pay_reason]. 
3. Any rows with duplicate snz_uid (STATSNZ unique identifier for individuals in the IDI), snz_msd_uid (MSD unique identifier for individuals) and msd_tte_app_date (the application date for the emergency housing) are removed. 
4. If an individual has multiple application dates close to each other, the data is merged together where the earliest application date is the 'start date' and the latest application date is the '[end_date]'. The threshold for merging the application dates is '23' days after analysing the time gaps between applications for individuals that have made multiple applications. In the analysis, Simon Anastasiadis and John Park found that a significant number of individuals that have made multiple applications have made subsequent applications 1 week, 2 weeks and 3 weeks after their first emergency housing application. The code for compacting the different rows into a single spell is derived from Vinay Benny's code from Social Investment Data Foundation (SIDF) library. 

### Parameters
The following parameters should be supplied to this module to run it in the database:

1. IDI_UserCode: The SQL database on which the spell datasets are to be created. 
2. {idicleanversion}: The IDI Clean version that the spell datasets need to be based on.
3. {targetschema}: The project schema under the target database into which the spell datasets are to be created.
4. {projprefix}: A (short) prefix that enables you to identify the spell dataset easily in the schema, and prevent overwriting any existing datasets that have the same name.

### Dependencies
	{idicleanversion}.[msd_clean].msd_third_tier_expenditure
	   	 
### Outputs
```
IDI_UserCode.{targetschema}.{projprefix}_emergency_housing
```

### Variable Descriptions
The variables that present in the Emergency Housing Spell Module are described below. 

---------------------------------------------------------------------------------------------------------------------------
Column                         Description
name                       
------------------------------ --------------------------------------------------------------------------------------------
snz_uid                        The unique STATSNZ person identifier for the individual in an emergency housing 

data_source                    A tag signifying a source dataset description (hard-coded to "MSD")

snz_msd_uid                    The unique MSD person identifier for the individual in an emergency housing

start_date                     The start date for the emergency housing, i.e., the first day that the person applied for a 
                                third tier benefit from MSD to stay at an emergency housing

end_date                       The latest date for when the person last consecutively applied for emergency housing benefit
                                from MSD for the current spell. 

----------------------------------------------------------------------------------------------------------------------------

### Module Version & Change History

-----------------------------------------------------------------------------------------------------------------------
Date                       Version Comments                       
-------------------------- --------------------------------------------------------------------------------------------
31 May 2022                Initial version of the emergency housing code.
-----------------------------------------------------------------------------------------------------------------------
15 June 2022			   VW pointed to MSD seniors project and 202203 refresh.
-----------------------------------------------------------------------------------------------------------------------

## Code

***************************************************************************************************************************/

/* Assign the target database to which all the components need to be created in. */
USE IDI_UserCode
GO

/* Delete the database object if it already exists */
DROP VIEW IF EXISTS [DL-MAA2018-48].defn_emergency_housing_spells
GO

/* Create the database object from the temporary view by merging the any close consecutive applications together */
CREATE VIEW [DL-MAA2018-48].defn_emergency_housing_spells AS
	/* Trim out the duplicate rows from the MSD data after filtering for people that have applied for emergency housing */ 
	WITH 
	emergency_housing AS (
		SELECT [snz_uid]
			,[snz_msd_uid]
			,[msd_tte_app_date] AS [start_date]
			,dateadd(day, 23, [msd_tte_app_date]) AS [end_date] /* Adds a 23 day threshold between each application so that any consecutive applications made within 23 day thresholds can be joined up together into a single spell. */
		FROM [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure]
		WHERE [msd_tte_pmt_rsn_type_code] IN ('855') /* Emergency housing code */ 
		GROUP BY snz_uid, snz_msd_uid, msd_tte_app_date
	),
	/* Exclude start dates that are within another spell */
	spell_starts AS (
		SELECT [snz_uid]
			,[snz_msd_uid]
			,[start_date]
			,[end_date] 
		FROM emergency_housing a
		WHERE NOT EXISTS (
			SELECT 1 
			FROM emergency_housing b
			WHERE a.[snz_uid] = b.[snz_uid]
				AND a.[snz_msd_uid] = b.[snz_msd_uid]
				AND a.[start_date] > b.[start_date]
				AND a.[start_date] <= b.[end_date]
		)
	), 
	/* Exclude end dates that are within another spell */
	spell_ends AS ( 
		SELECT [snz_uid]
			,[snz_msd_uid]
			,[start_date]
			,[end_date] 
		FROM emergency_housing a
		WHERE NOT EXISTS (
			SELECT 1 
			FROM emergency_housing b
			WHERE a.[snz_uid] = b.[snz_uid]
				AND a.[snz_msd_uid] = b.[snz_msd_uid]
				AND a.[end_date] >= b.[start_date]
				AND a.[end_date] < b.[end_date]
		)
	)
	/* Compact the emergency housing event dates into spells for people with multiple emergency housing applications */ 
	SELECT 
		s.snz_uid
		,'MSD' AS data_source
		,s.snz_msd_uid
		,s.[start_date] /* The first application made by the person */ 
		,dateadd(day, -23, min(e.[end_date])) AS [end_date] /* Remove the 23 days added to the application date after the joins have been made */ 
	FROM spell_starts s
	INNER JOIN spell_ends e
	ON s.[snz_uid] = e.[snz_uid]
		AND s.[snz_msd_uid] = e.[snz_msd_uid]
		AND s.[start_date] <= e.[end_date]
	GROUP BY s.[snz_uid], s.[snz_msd_uid], s.[start_date]
GO
