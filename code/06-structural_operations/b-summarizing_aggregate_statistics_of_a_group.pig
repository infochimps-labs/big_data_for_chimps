IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons   = load_bat_seasons();
people        = load_people();

--
-- === Group and Aggregate
--

--
-- ==== Aggregate Statistics of a Group
--
bat_careers = FOREACH (GROUP bat_seasons BY player_id) {
  totG   = SUM(bat_seasons.G);
  totPA  = SUM(bat_seasons.PA);  totAB  = SUM(bat_seasons.AB);
  totHBP = SUM(bat_seasons.HBP); totSH  = SUM(bat_seasons.SH);
  totBB  = SUM(bat_seasons.BB);  totH   = SUM(bat_seasons.H);
  toth1B = SUM(bat_seasons.h1B); toth2B = SUM(bat_seasons.h2B);
  toth3B = SUM(bat_seasons.h3B); totHR  = SUM(bat_seasons.HR);
  totR   = SUM(bat_seasons.R);   totRBI = SUM(bat_seasons.RBI);
  OBP    = 1.0*(totH + totBB + totHBP) / totPA;
  SLG    = 1.0*(toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  team_ids = DISTINCT bat_seasons.team_id;
  GENERATE
    group                          AS player_id,
    COUNT_STAR(bat_seasons)        AS n_seasons,
    COUNT_STAR(team_ids)           AS card_teams,
    MIN(bat_seasons.year_id)	   AS beg_year,
    MAX(bat_seasons.year_id)       AS end_year,
    totG   AS G,
    totPA  AS PA,  totAB  AS AB,  totHBP AS HBP,    --  $6 -  $8
    totSH  AS SH,  totBB  AS BB,  totH   AS H,      --  $9 - $11
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B,    -- $12 - $14
    totHR AS HR,   totR   AS R,   totRBI AS RBI,    -- $15 - $17
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS      -- $18 - $20
    ;
};

--
-- ==== Completely Summarizing a Field
--
peeps = FILTER people BY (beg_date IS NOT NULL) AND (weight_lb IS NOT NULL);

weight_yr_stats = FOREACH (GROUP peeps BY SUBSTRING(beg_date,0,4)) {
  dist         = DISTINCT peeps.weight_lb;
  sorted_a     = FILTER   peeps.weight_lb BY weight_lb IS NOT NULL;
  sorted       = ORDER    sorted_a BY weight_lb;
  some         = LIMIT    dist.weight_lb 5;
  n_recs       = COUNT_STAR(peeps);
  n_notnulls   = COUNT(peeps.weight_lb);
  GENERATE
    group,
    AVG(peeps.weight_lb)           AS avg_val,
    SQRT(VAR(peeps.weight_lb))     AS stddev_val,
    MIN(peeps.weight_lb)           AS min_val,
    FLATTEN(ApproxEdgeile(sorted)) AS (p01, p05, p50, p95, p99),
    MAX(peeps.weight_lb)           AS max_val,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT_STAR(dist)               AS cardinality,
    SUM(peeps.weight_lb)           AS sum_val,
    BagToString(some, '^')         AS some_vals
    ;
};

STORE_TABLE(bat_careers, 'bat_careers');
sh cat $out_dir/bat_careers/part\* | ghead \-n 20 | wu-lign;

-- STORE_TABLE(weight_yr_stats, 'weight_yr_stats');
-- sh cat $out_dir/weight_yr_stats/part\* | wu-lign ;
