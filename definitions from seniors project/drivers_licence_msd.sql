/*************************************************************************************
Title: Drivers licences 
Author: MSD (see below)
Date: 30/05/2022

Inputs & Dependencies:
- [IDI_Clean_202203].[nzta_clean].[dlr_historic]
- [IDI_UserCode].[DL-MAA2018-48].[defn_res_pop_65plus_2018]
Output:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_nzta_licences]

Description:
This (MSD created) module creates a table of when individuals held a driver’s licence by vehicle class and 
stage (learners to full). This information is based on New Zealand Transport Agency (NZTA) / Waka 
Kotahi’s register of driver licences.

See more detail on the code module here:
http://prtprdgit02.stats.govt.nz/t/code-module-driver-licence-records/45

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Intended purpose:
- Net worth variable for MSD seniors project

Issues
- Nearly 600 duplicates. Selecting distinct through assembly tool will get around this issue. 

History (reverse order):
2022-07-04 VW Point to 2018 seniors population: [IDI_UserCode].[DL-MAA2018-48].[defn_res_pop_65plus_2018] 
2022-05-30 VW Obtained from data lab commons and filled in for MSD seniors project (seniors population and project schemas).
			  Also updated to latest refresh and filtered to only include those with full licenses.
2021-08	Marc de Boer (MSD) Corrected imputed licence_end_date that were returning null and high end date null end dates
2021-02 Bryan Ku (MSD) Initial draft of the module 


**************************************************************************************/

/* current output table */
--SELECT top 100 * FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_nzta_licences] 

if object_id('tempdb..#tmp_dlr0') is not null drop table #tmp_dlr0;
/* equivalent to the first data step */
select 
    a.snz_uid
    ,a.snz_nzta_uid
    ,a.nzta_hist_licence_type_text
    ,a.nzta_hist_licence_start_date
    ,a.nzta_hist_licence_class_text
    ,a.nzta_hist_full_start_date
    ,a.nzta_hist_restricted_start_date
    ,a.nzta_hist_learner_start_date
    /*,ROW_NUMBER() over(order by snz_uid,nzta_hist_licence_type_text,nzta_hist_licence_start_date,nzta_hist_licence_class_text) as licence_id*/
    /* The GLDS started in 1 Aug 1987, so the stages will not apply to licences before this date */
    ,case when a.nzta_hist_licence_start_date < '1987-08-01' then a.nzta_hist_licence_start_date 
        when a.nzta_hist_full_start_date = '1900-01-01' then null 
        else a.nzta_hist_full_start_date end as full_sd
into #tmp_dlr0
from [IDI_Clean_202203].[nzta_clean].[dlr_historic] as a
inner join [IDI_UserCode].[DL-MAA2018-48].[defn_res_pop_65plus_2018] pop
    on (a.snz_uid=pop.snz_uid 
        )
/* advised by NZTA that these are not typically used - they comprise a small proportion of all licence stages */
where a.nzta_hist_licence_type_text not in ('PSEUDO LICENCE','DIPLOMATIC'); 

if object_id('tempdb..#tmp_dlr') is not null drop table #tmp_dlr;
select snz_uid
      ,snz_nzta_uid
      ,nzta_hist_licence_type_text
      ,nzta_hist_licence_start_date
      ,nzta_hist_licence_class_text
      ,full_sd
        /* conservative approach to set learner licence date to null if contradictions detected */
        ,case when nzta_hist_learner_start_date > nzta_hist_restricted_start_date then null 
            when nzta_hist_restricted_start_date > full_sd then null
            when nzta_hist_learner_start_date > full_sd then null
            else nzta_hist_learner_start_date end as learner_sd
        /* conservative approach to set restricted licence date to null if contradictions detected */
        ,case when nzta_hist_learner_start_date > nzta_hist_restricted_start_date then null 
            when nzta_hist_restricted_start_date > full_sd then null
            when nzta_hist_learner_start_date > full_sd then null
            else nzta_hist_restricted_start_date end as restricted_sd
into #tmp_dlr
from #tmp_dlr0;

/* check for duplicates eg one person holding more than one car licence - unsure if these are true duplicates and one copy should be dropped or these arise due to matching issues */
if object_id('tempdb..#dupcheck') is not null drop table #dupcheck;
select distinct(snz_uid)
    ,nzta_hist_licence_type_text
    ,count(snz_uid) as dup_count
    ,nzta_hist_licence_class_text
into #dupcheck
from #tmp_dlr
group by snz_uid, nzta_hist_licence_type_text, nzta_hist_licence_class_text
having count(snz_uid) > 1;

if object_id('tempdb..#tmp_nodups') is not null drop table #tmp_nodups;
if object_id('tempdb..#tmp_dups') is not null drop table #tmp_dups;

/* deal with duplicates separately then combine later */
select a.*, b.snz_uid as dup_id
into #tmp_nodups
from #tmp_dlr a left join #dupcheck b
on      a.snz_uid = b.snz_uid 
    and a.nzta_hist_licence_type_text = b.nzta_hist_licence_type_text 
    and a.nzta_hist_licence_class_text = b.nzta_hist_licence_class_text
where b.snz_uid is null;

select a.* 
into #tmp_dups
from #tmp_dlr a left join #dupcheck b
on      a.snz_uid = b.snz_uid 
    and a.nzta_hist_licence_type_text = b.nzta_hist_licence_type_text 
    and a.nzta_hist_licence_class_text = b.nzta_hist_licence_class_text
where b.snz_uid is not null;

/* choose one duplicate at random */
if object_id('tempdb..#tmp_dups1') is not null drop table #tmp_dups1;
select top 1 with ties 
    snz_uid, 
    nzta_hist_licence_type_text, 
    nzta_hist_licence_class_text, 
    nzta_hist_licence_start_date, 
    full_sd, 
    learner_sd, 
    restricted_sd
into #tmp_dups1
from #tmp_dups
order by row_number() over (partition by snz_uid, nzta_hist_licence_type_text, nzta_hist_licence_class_text order by newid());

/* combine deduped records with normal records */
if object_id('tempdb..#tmp_dlr1') is not null drop table #tmp_dlr1;
select snz_uid
        ,nzta_hist_licence_type_text
        ,nzta_hist_licence_class_text
        ,learner_sd
        ,restricted_sd
        ,full_sd
into #tmp_dlr1
from #tmp_dups1
union all
select snz_uid
        ,nzta_hist_licence_type_text
        ,nzta_hist_licence_class_text
        ,learner_sd
        ,restricted_sd
        ,full_sd
from #tmp_nodups;

/* transpose the table to convert into spell-based format (one row per person-licence class-licence type */
if object_id('tempdb..#tmp_dlr2') is not null drop table #tmp_dlr2;
select *
into #tmp_dlr2
from #tmp_dlr1
unpivot(date_value for startdate in (learner_sd,restricted_sd,full_sd)) up;

/* assign numeric value to licence stages for the purposes of imputing end dates for the psuedo-spells */
if object_id('tempdb..#tmp_dlr3') is not null drop table #tmp_dlr3;
select *
    ,case when startdate = 'learner_sd' then 1
        when startdate = 'restricted_sd' then 2
        when startdate = 'full_sd' then 3
        end as stage
into #tmp_dlr3
from #tmp_dlr2
order by snz_uid, nzta_hist_licence_class_text, nzta_hist_licence_type_text, stage, date_value;

/* to confirm there are no more duplicates */
select distinct
    snz_uid
    ,count(snz_uid) as dup_count
    ,nzta_hist_licence_type_text
    ,nzta_hist_licence_class_text
    ,date_value
from #tmp_dlr3
group by snz_uid,nzta_hist_licence_type_text, nzta_hist_licence_class_text, date_value
having count(snz_uid) > 1


/* impute end date of preceding licence stage for GLDS licences */
if object_id('tempdb..#tmp_dlr4') is not null drop table #tmp_dlr4;
/* this step takes slightly under 4 minutes to run */
select *
    ,lag(date_value,1) over (partition by snz_uid
    ,nzta_hist_licence_type_text
    ,nzta_hist_licence_class_text
      order by stage desc) as next_sd
into #tmp_dlr4
from #tmp_dlr3;

/* Assign the target database to which all the components need to be created in. */
USE IDI_Sandpit;

/* Drop the final output table if it exists.*/
DROP TABLE IF EXISTS [DL-MAA2018-48].[defn_nzta_licences];

/* Create the final output table*/
select 
    snz_uid
    ,nzta_hist_licence_type_text as licence_type
    ,nzta_hist_licence_class_text as licence_class
    ,case when startdate = 'full_sd' then 'full'
            when startdate = 'restricted_sd' then 'restricted'  
            when startdate = 'learner_sd' then 'learner' 
            end as licence_stage
    ,date_value as licence_start_date
    ,case when datediff(day,date_value,next_sd) > 0 then dateadd(day,-1,next_sd) 
        else cast ('9999-12-31' as date) end as licence_end_date
    ,cast('nzta_clean.dlr_historic' as varchar(50)) as data_source
into [DL-MAA2018-48].[defn_nzta_licences]
from #tmp_dlr4
where startdate = 'full_sd' -- only interested in full licences for seniors project;

/* clear temporary tables */
drop table #tmp_dlr0;
drop table #tmp_dlr;
drop table #tmp_dlr1;
drop table #tmp_dlr2;
drop table #tmp_dlr3;
drop table #tmp_dlr4;
drop table #tmp_dups1;
drop table #tmp_dups;
drop table #tmp_nodups;