IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons   = load_bat_seasons();

-- === Summarizing Aggregate Statistics of a Group

-- The most common way to make big data small is to apply aggregate functions
-- that summarize the whole.

--
-- For example,  the batting season statistics into batting career statistics
--
bat_careers = FOREACH (GROUP bat_seasons BY player_id) {
  team_ids = DISTINCT bat_seasons.team_id;
  totG   = SUM(bat_seasons.G);   totPA  = SUM(bat_seasons.PA);  totAB  = SUM(bat_seasons.AB);
  totH   = SUM(bat_seasons.H);   totBB  = SUM(bat_seasons.BB);  totHBP = SUM(bat_seasons.HBP); totR   = SUM(bat_seasons.R);
  toth1B = SUM(bat_seasons.h1B); toth2B = SUM(bat_seasons.h2B); toth3B = SUM(bat_seasons.h3B); totHR  = SUM(bat_seasons.HR);
  OBP    = (totH + totBB + totHBP) / totPA;
  SLG    = (toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  GENERATE
    group                          AS player_id,
    COUNT_STAR(bat_seasons)        AS n_seasons,
    COUNT_STAR(team_ids)           AS n_distinct_teams,
    MIN(bat_seasons.year_id)	     AS beg_year,
    MAX(bat_seasons.year_id)       AS end_year,
    totG   AS G,   totPA  AS PA,  totAB  AS AB,
    totH   AS H,   totBB  AS BB,  totHBP AS HBP,
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B, totHR AS HR,
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS
    ;
};

DESCRIBE bat_seasons;
DESCRIBE bat_careers;


-- The following functions are built in to Pig:
--
-- * Count of all values: `COUNT_STAR(bag)`
-- * Count of non-Null values: `COUNT(bag)`
-- * Cardinality (i.e. the count of distinct values): combine the `DISTINCT` operation and the `COUNT_STAR` function as demonstrated below.
-- * Minimum / Maximum non-Null value: `MIN(bag)` / `MAX(bag)`
-- * Sum of non-Null values: `SUM(bag)`
-- * Average of non-Null values: `AVG(bag)`
--
-- There are a few additional summary functions that aren't native features of
-- Pig, but are offered by Linkedin's might-as-well-be-native DataFu
-- package. (The previous chapter (REF) has details on how to use UDFs.)
--
-- * Variance of non-Null values: `VAR(bag)`, using the `datafu.pig.stats.VAR` UDF
-- * Standard Deviation of non-Null values: `SQRT(VAR(bag))`
-- * Quantiles: `Quantile(bag)` or `StreamingQuantile(bag)`; we'll explain the difference shortly
-- * Median (50th Percentile Value) of a Bag: `Median(bag)` or `StreamingMedian(bag)`
--
-- (If you've forgotten/never quite learned what those functions mean, hang on
-- for just a bit and we'll demonstrate them in context. If that still doesn't
-- do it, try either http://www.amazon.com/dp/039334777X[Naked Statistics] or
-- http://www.amazon.com/Head-First-Statistics-Dawn-Griffiths/dp/0596527586[Head
-- First Statistics] Both do a good job of efficiently imparting what these
-- functions mean and how to use them, and don't assume prior expertise or
-- interest in mathematics.)
--

-- weight_summary = FOREACH (GROUP bat_seasons ALL) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)             AS avg_val,
--     SQRT(VAR(bat_seasons.weight))       AS stddev_val,
--     MIN(bat_seasons.weight)             AS min_val,
--     FLATTEN(SortedEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)             AS max_val,
--     --
--     n_recs                          AS n_recs,
--     n_recs - n_notnulls             AS n_nulls,
--     COUNT_STAR(dist)                     AS cardinality,
--     SUM(bat_seasons.weight)             AS sum_val,
--     BagToString(some, '^')          AS some_vals
--     ;
-- };
--
-- DESCRIBE     weight_summary;
-- STORE_TABLE('weight_summary', weight_summary);
-- cat $out_dir/weight_summary;
--
-- weight_yr_stats = FOREACH (GROUP bat_seasons BY year_id) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)             AS avg_val,
--     SQRT(VAR(bat_seasons.weight))       AS stddev_val,
--     MIN(bat_seasons.weight)             AS min_val,
--     FLATTEN(SortedEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)             AS max_val,
--     --
--     n_recs                          AS n_recs,
--     n_recs - n_notnulls             AS n_nulls,
--     COUNT_STAR(dist)                     AS cardinality,
--     SUM(bat_seasons.weight)             AS sum_val,
--     BagToString(some, '^')          AS some_vals
--     ;
-- };
--
-- DESCRIBE     weight_yr_stats;
-- STORE_TABLE('weight_yr_stats', weight_yr_stats);
-- cat $out_dir/weight_yr_stats;

-- stats_G   = summarize_values_by(bat_seasons, 'G',   'ALL');    STORE_TABLE('stats_G',   stats_G  );
-- stats_PA  = summarize_values_by(bat_seasons, 'PA',  'ALL');    STORE_TABLE('stats_PA',  stats_PA  );
-- stats_H   = summarize_values_by(bat_seasons, 'H',   'ALL');    STORE_TABLE('stats_H',   stats_H  );
-- stats_HR  = summarize_values_by(bat_seasons, 'HR',  'ALL');    STORE_TABLE('stats_HR',  stats_HR );
-- stats_OBP = summarize_values_by(bat_seasons, 'OBP', 'ALL');    STORE_TABLE('stats_OBP', stats_OBP);
-- stats_BAV = summarize_values_by(bat_seasons, 'BAV', 'ALL');    STORE_TABLE('stats_BAV', stats_BAV);
-- stats_SLG = summarize_values_by(bat_seasons, 'SLG', 'ALL');    STORE_TABLE('stats_SLG', stats_SLG);
-- stats_OPS = summarize_values_by(bat_seasons, 'OPS', 'ALL');    STORE_TABLE('stats_OPS', stats_OPS);
--
-- stats_wt  = summarize_values_by(bat_seasons, 'weight', 'ALL'); STORE_TABLE('stats_wt', stats_wt);
-- stats_ht  = summarize_values_by(bat_seasons, 'height', 'ALL'); STORE_TABLE('stats_ht', stats_ht);

-- pig ./06-structural_operations/c-summary_statistics.pig
-- cat /data/out/baseball/stats_*/part-r-00000 | wu-lign -- %s %s %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f

-- group   field   average  stdev     min     p01     p05     p10    p50     p90     p95     p99      max  count   nulls   cardnty    sum                  some
-- all     BAV       0.209   0.122   0.000   0.000   0.000   0.000   0.231   0.308   0.333   0.500   1.000 69127     0     11503       14415.623359973975  0.0^0.015625^0.01639344262295082^0.01694915254237288^0.017543859649122806
-- all     G        61.575  49.645   1.000   1.000   3.000   6.000  43.000 143.000 152.000 159.000 165.000 69127     0       165     4256524.000000000000  1^2^3^4^5
-- all     H        45.956  56.271   0.000   0.000   0.000   0.000  15.000 142.000 163.000 194.000 262.000 69127     0       250     3176790.000000000000  0^1^2^3^4
-- all     HR        3.751   7.213   0.000   0.000   0.000   0.000   0.000  13.000  20.000  34.000  73.000 69127     0        66      259305.000000000000  0^1^2^3^4
-- all     OBP       0.259   0.134   0.000   0.000   0.000   0.000   0.286   0.377   0.407   0.556   2.333 69127     0     14214       17872.834545988590  0.0^0.020833334^0.021276595^0.023255814^0.024390243
-- all     OPS       0.550   0.308   0.000   0.000   0.000   0.000   0.602   0.838   0.921   1.333   5.000 69127     0     45768       38051.246410079300  0.0^0.021276595^0.02631579^0.027027028^0.028571429
-- all     PA      197.398 220.678   1.000   1.000   2.000   4.000  86.000 582.000 643.000 701.000 778.000 69127     0       766    13645539.000000000000  1^2^3^4^5
-- all     SLG       0.292   0.187   0.000   0.000   0.000   0.000   0.312   0.478   0.525   0.800   4.000 69127     0     16540       20178.412007378414  0.0^0.015625^0.016393442^0.01754386^0.018518519
-- all     height  183.700   5.903 160.000 170.000 175.000 175.000 183.000 190.000 193.000 198.000 211.000 69127   113        21    12677857.000000000000  null^160^163^165^168
-- all     weight   84.435   8.763  57.000  68.000  73.000  75.000  84.000  95.000 100.000 109.000 145.000 69127   176        64     5821854.000000000000  null^57^59^60^61

-- group   field   average  stdev     min     p01     p05     p10    p50     p90     p95     p99      max  count   nulls   cardnty    sum                  some
-- all     BAV       0.265   0.036   0.122   0.181   0.207   0.220   0.265   0.309   0.323   0.353   0.424 27750   0       10841        7352.282635679735  0.12244897959183673^0.12435233160621761^0.125^0.12598425196850394^0.12878787878787878
-- all     G       114.147  31.707  32.000  46.000  58.000  68.000 118.000 153.000 156.000 161.000 165.000 27750   0       134       3167587.000000000000  32^33^34^35^36
-- all     H       103.566  47.301  16.000  28.000  36.000  42.000 101.000 168.000 182.000 206.000 262.000 27750   0       234       2873945.000000000000  16^17^18^19^20
-- all     HR        8.829   9.236   0.000   0.000   0.000   0.000   6.000  22.000  28.000  40.000  73.000 27750   0       66         245001.000000000000  0^1^2^3^4
-- all     OBP       0.329   0.042   0.156   0.233   0.261   0.276   0.328   0.383   0.399   0.436   0.609 27750   0       13270        9119.456519946456  0.15591398^0.16666667^0.16849817^0.16872428^0.16935484
-- all     OPS       0.721   0.115   0.312   0.478   0.544   0.581   0.715   0.867   0.916   1.027   1.422 27750   0       27642       20014.538630217314  0.31198335^0.31925547^0.32882884^0.33018503^0.3321846
-- all     PA      430.130 168.812 150.000 154.000 172.000 196.000 434.000 656.000 682.000 719.000 778.000 27750   0       617      11936098.000000000000  150^151^152^153^154
-- all     SLG       0.393   0.080   0.148   0.230   0.272   0.295   0.387   0.497   0.534   0.609   0.863 27750   0       15589       10895.082128539681  0.14795919^0.15151516^0.15418503^0.15492958^0.15544042
-- all     height  182.460   5.608 163.000 168.000 173.000 175.000 183.000 190.000 190.000 196.000 203.000 27750   28      17        5058166.000000000000  null^163^165^168^170
-- all     weight   83.569   8.797  57.000  68.000  71.000  73.000  82.000  95.000 100.000 109.000 132.000 27750   35      54        2316119.000000000000  null^57^59^63^64



STORE_TABLE('bat_careers', bat_careers);
