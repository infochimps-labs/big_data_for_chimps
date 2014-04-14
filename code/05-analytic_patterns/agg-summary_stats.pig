IMPORT 'common_macros.pig';

bats = load_bats();
bats = FOREACH bats GENERATE *, (float)HR*HR AS HRsq:float;

bat_all  = GROUP bats ALL;
hr_stats = FOREACH bat_all {
  hrs_distinct = DISTINCT bats.HR;
  GENERATE
    MIN(bats.HR)        AS hr_min,
    MAX(bats.HR)        AS hr_max,
    AVG(bats.HR)        AS hr_avg,
    SUM(bats.HR)        AS hr_sum,
    SQRT(VAR(bats.HR))  AS hr_stdev,
    SQRT((SUM(bats.HRsq)/COUNT(bats)) - (AVG(bats.HR)*AVG(bats.HR))) AS hr_stdev2,
    COUNT_STAR(bats)    AS n_recs,
    COUNT_STAR(bats) - COUNT(bats.HR) AS hr_n_nulls,
    COUNT(hrs_distinct) AS hr_card
    ;
  }

DUMP hr_stats;



