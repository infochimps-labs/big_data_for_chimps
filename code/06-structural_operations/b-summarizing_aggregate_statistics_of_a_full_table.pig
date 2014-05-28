IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Summarizing Aggregate Statistics of a Full Table
--


bat_seasons = FOREACH bat_seasons GENERATE *, (float)HR*HR AS HRsq:float;

hr_stats = FOREACH (GROUP bat_seasons ALL) {
  hrs_distinct = DISTINCT bat_seasons.HR;
  GENERATE
    MIN(bat_seasons.HR)        AS hr_min,
    MAX(bat_seasons.HR)        AS hr_max,
    AVG(bat_seasons.HR)        AS hr_avg,
    SUM(bat_seasons.HR)        AS hr_sum,
    SQRT(VAR(bat_seasons.HR))  AS hr_stdev,
    SQRT((SUM(bat_seasons.HRsq)/COUNT(bat_seasons)) - (AVG(bat_seasons.HR)*AVG(bat_seasons.HR))) AS hr_stdev2,
    COUNT_STAR(bat_seasons)    AS n_recs,
    COUNT_STAR(bat_seasons) - COUNT(bat_seasons.HR) AS hr_n_nulls,
    COUNT(hrs_distinct) AS hr_card
    ;
  }

rmf                  $out_dir/hr_stats;
STORE hr_stats INTO '$out_dir/hr_stats';
