IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 


pl_yr_stats = load_bat_seasons();
pl_yr_stats = FOREACH pl_yr_stats GENERATE *, (float)HR*HR AS HRsq:float;

hr_stats = FOREACH (GROUP pl_yr_stats ALL) {
  hrs_distinct = DISTINCT pl_yr_stats.HR;
  GENERATE
    MIN(pl_yr_stats.HR)        AS hr_min,
    MAX(pl_yr_stats.HR)        AS hr_max,
    AVG(pl_yr_stats.HR)        AS hr_avg,
    SUM(pl_yr_stats.HR)        AS hr_sum,
    SQRT(VAR(pl_yr_stats.HR))  AS hr_stdev,
    SQRT((SUM(pl_yr_stats.HRsq)/COUNT(pl_yr_stats)) - (AVG(pl_yr_stats.HR)*AVG(pl_yr_stats.HR))) AS hr_stdev2,
    COUNT_STAR(pl_yr_stats)    AS n_recs,
    COUNT_STAR(pl_yr_stats) - COUNT(pl_yr_stats.HR) AS hr_n_nulls,
    COUNT(hrs_distinct) AS hr_card
    ;
  }

rmf                  $out_dir/hr_stats;
STORE hr_stats INTO '$out_dir/hr_stats';
